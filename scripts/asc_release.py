#!/usr/bin/env python3
"""Put an already-uploaded build in front of App Store review.

Unlike TestFlight, a store release needs its own App Store version object: the
version is created (or reused), the build is attached, the "What's New" text is
written, and the whole thing is handed to review. Nothing is built or uploaded
here — `make ios-testflight` did that.

Usage: asc_release.py <AuthKey.p8> <key_id> <issuer_id> [build]
                      [--whats-new TEXT | --whats-new-file PATH] [--locale de-DE]
                      [--release-type MANUAL|AFTER_APPROVAL] [--phased]
                      [--submit] [--dry-run]
  build   build number (CFBundleVersion), an App Store Connect build id,
          or "latest" (default). The store version number is taken from that
          build's version train, so 1.0.3 build 21 releases as 1.0.3.

Without --submit everything is prepared but not handed to review, which leaves
the version editable in App Store Connect. --dry-run only reports.
"""
import argparse
import sys

from asc_distribute import (ApiError, call, find_app, find_build, make_token)

# A version in one of these states is still ours to edit; anything else means
# Apple has it (or it already shipped) and we must not touch it. The names are
# shared by both state vocabularies (see version_state).
EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
            "METADATA_REJECTED", "INVALID_BINARY"}
SHIPPED = {"READY_FOR_SALE", "READY_FOR_DISTRIBUTION"}


def version_state(version: dict) -> str:
    """appStoreState is deprecated in favour of appVersionState; prefer the new
    field but keep working if only the old one comes back."""
    attrs = version.get("attributes", {})
    return attrs.get("appVersionState") or attrs.get("appStoreState") or "UNKNOWN"


def version_train(token: str, build: dict) -> str:
    """The marketing version (1.0.3) the build belongs to."""
    rel = (build.get("relationships", {}).get("preReleaseVersion", {}).get("data") or {})
    if not rel.get("id"):
        pre = call(token, "GET", f"/v1/builds/{build['id']}/preReleaseVersion")
        return pre["data"]["attributes"]["version"]
    return call(token, "GET", f"/v1/preReleaseVersions/{rel['id']}")["data"]["attributes"]["version"]


def set_release_notes(token: str, version_id: str, text: str, locale: str) -> str:
    locs = call(token, "GET",
                f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")["data"]
    for loc in locs:
        if loc["attributes"].get("locale") == locale:
            call(token, "PATCH", f"/v1/appStoreVersionLocalizations/{loc['id']}", {
                "data": {"type": "appStoreVersionLocalizations", "id": loc["id"],
                         "attributes": {"whatsNew": text}},
            })
            return f"updated {locale} What's New"
    raise ApiError(
        f"no {locale} localization on this version — App Store metadata (description, "
        f"screenshots) must exist before release notes can be set. Locales present: "
        f"{[l['attributes'].get('locale') for l in locs]}")


def check_ready_for_review(token: str, version_id: str, locale: str, is_update: bool) -> list:
    """Everything Apple rejects a submission over, checked before we submit."""
    missing = []
    build = call(token, "GET", f"/v1/appStoreVersions/{version_id}/build").get("data")
    if not build:
        missing.append("no build attached to the version")

    locs = call(token, "GET",
                f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")["data"]
    if not locs:
        missing.append("no App Store localization (description, screenshots) on this version")
    for loc in locs:
        attrs = loc["attributes"]
        loc_name = attrs.get("locale")
        if not attrs.get("description"):
            missing.append(f"{loc_name}: description")
        # "What's New" is mandatory for an update, and must be absent on a first release.
        if is_update and not attrs.get("whatsNew"):
            missing.append(f"{loc_name}: What's New (required for an update)")
        sets = call(token, "GET",
                    f"/v1/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")["data"]
        if not sets:
            missing.append(f"{loc_name}: screenshots")

    detail = call(token, "GET", f"/v1/appStoreVersions/{version_id}/appStoreReviewDetail")
    dattrs = (detail.get("data") or {}).get("attributes", {})
    if not dattrs.get("contactEmail"):
        missing.append("App Review contact details (name, phone, email)")
    if dattrs.get("demoAccountRequired") and not dattrs.get("demoAccountName"):
        missing.append("demo account (marked as required but not filled in)")
    return missing


def submit_for_review(token: str, app_id: str, version_id: str) -> str:
    open_subs = call(token, "GET",
                     f"/v1/reviewSubmissions?filter[app]={app_id}&filter[state]=READY_FOR_REVIEW,"
                     f"WAITING_FOR_REVIEW,IN_REVIEW,UNRESOLVED_ISSUES&limit=5")["data"]
    if open_subs:
        states = ", ".join(s["attributes"].get("state") for s in open_subs)
        raise ApiError(f"a review submission is already open ({states}) — "
                       f"cancel it in App Store Connect first")
    sub = call(token, "POST", "/v1/reviewSubmissions", {
        "data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                 "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}},
    })["data"]
    call(token, "POST", "/v1/reviewSubmissionItems", {
        "data": {"type": "reviewSubmissionItems",
                 "relationships": {
                     "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub["id"]}},
                     "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}},
    })
    call(token, "PATCH", f"/v1/reviewSubmissions/{sub['id']}", {
        "data": {"type": "reviewSubmissions", "id": sub["id"],
                 "attributes": {"submitted": True}},
    })
    return sub["id"]


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("p8")
    p.add_argument("key_id")
    p.add_argument("issuer_id")
    p.add_argument("build", nargs="?", default="latest")
    p.add_argument("--whats-new", default=None)
    p.add_argument("--whats-new-file", default=None)
    p.add_argument("--locale", default="de-DE")
    # MANUAL matches how 1.0.2 was released and keeps the go-live moment ours:
    # AFTER_APPROVAL ships whenever Apple happens to approve, night or Friday.
    p.add_argument("--release-type", default="MANUAL",
                   choices=["AFTER_APPROVAL", "MANUAL"],
                   help="MANUAL (default) waits for you to press release; "
                        "AFTER_APPROVAL goes live as soon as Apple approves")
    p.add_argument("--phased", action="store_true",
                   help="roll the update out over 7 days instead of to everyone at once")
    p.add_argument("--submit", action="store_true",
                   help="hand the version to App Store review (without this it is "
                        "only prepared and stays editable)")
    p.add_argument("--dry-run", action="store_true")
    a = p.parse_args()
    if a.whats_new_file:
        try:
            with open(a.whats_new_file) as fh:
                a.whats_new = fh.read().strip()
        except OSError as exc:
            raise ApiError(f"cannot read notes file: {exc}") from None

    token = make_token(a.p8, a.key_id, a.issuer_id)
    app_id = find_app(token)
    build = find_build(token, app_id, a.build)
    battrs = build["attributes"]
    train = version_train(token, build)

    print(f"build        : {train} ({battrs.get('version')})")
    print(f"processing   : {battrs.get('processingState')}  expired={battrs.get('expired')}")
    if battrs.get("processingState") != "VALID" or battrs.get("expired"):
        raise ApiError("build is not a VALID, unexpired build")

    all_versions = call(
        token, "GET", f"/v1/apps/{app_id}/appStoreVersions?limit=20&filter[platform]=IOS")["data"]
    live = [v["attributes"].get("versionString") for v in all_versions
            if version_state(v) in SHIPPED]
    is_update = bool(live)
    print(f"live in store: {live[0] if live else '(none — this would be the first release)'}")

    version = next((v for v in all_versions
                    if v["attributes"].get("versionString") == train), None)
    if version:
        state = version_state(version)
        current_type = version["attributes"].get("releaseType")
        print(f"version {train}: exists, state {state}, releaseType {current_type}")
        if state not in EDITABLE:
            raise ApiError(f"version {train} is in state {state} — not editable here")
    else:
        current_type = None
        print(f"version {train}: does not exist yet, would be created "
              f"(releaseType {a.release_type})")

    retype = bool(version) and current_type != a.release_type

    if a.dry_run:
        steps = ["create the version"] if not version else []
        if retype:
            steps.append(f"change releaseType {current_type} -> {a.release_type}")
        steps.append(f"attach build {battrs.get('version')}")
        if a.phased:
            steps.append("enable phased release")
        if a.whats_new:
            steps.append(f"set {a.locale} What's New")
        steps.append("submit it to App Store review" if a.submit
                     else "leave it editable (no --submit)")
        print("\n[dry-run] would " + ", ".join(steps))
        return 0

    if not version:
        version = call(token, "POST", "/v1/appStoreVersions", {
            "data": {"type": "appStoreVersions",
                     "attributes": {"platform": "IOS", "versionString": train,
                                    "releaseType": a.release_type},
                     "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}},
        })["data"]
        print(f"created version {train}")
    elif retype:
        # Only set at creation otherwise, so a pre-existing version would silently
        # keep whatever release type it was made with.
        call(token, "PATCH", f"/v1/appStoreVersions/{version['id']}", {
            "data": {"type": "appStoreVersions", "id": version["id"],
                     "attributes": {"releaseType": a.release_type}},
        })
        print(f"releaseType {current_type} -> {a.release_type}")

    call(token, "PATCH", f"/v1/appStoreVersions/{version['id']}/relationships/build",
         {"data": {"type": "builds", "id": build["id"]}})
    print(f"attached build {battrs.get('version')}")

    if a.whats_new:
        print(set_release_notes(token, version["id"], a.whats_new, a.locale))

    if a.phased:
        try:
            call(token, "POST", "/v1/appStoreVersionPhasedReleases", {
                "data": {"type": "appStoreVersionPhasedReleases",
                         "relationships": {"appStoreVersion": {
                             "data": {"type": "appStoreVersions", "id": version["id"]}}}},
            })
            print("phased release enabled")
        except ApiError as e:
            if "already" in str(e).lower():
                print("phased release already enabled")
            else:
                raise

    if not a.submit:
        print("\nPrepared but NOT submitted — review it in App Store Connect, then "
              "re-run with --submit.")
        return 0

    missing = check_ready_for_review(token, version["id"], a.locale, is_update)
    if missing:
        print("\nNot submitting — App Store review would reject this:", file=sys.stderr)
        for m in missing:
            print(f"  - {m}", file=sys.stderr)
        return 1

    sub_id = submit_for_review(token, app_id, version["id"])
    print(f"submitted to App Store review (submission {sub_id})")
    print("Apple's review is slower than the TestFlight beta review; expect a day or more.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ApiError as exc:
        sys.stdout.flush()
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1) from None
