#!/usr/bin/env python3
"""Put an already-uploaded build in front of App Store review.

Unlike TestFlight, a store release needs its own App Store version object: the
version is created (or reused), the build is attached, the "What's New" text is
written, and the whole thing is handed to review. Nothing is built or uploaded
here — `make ios-testflight` did that.

Usage: asc_release.py <AuthKey.p8> <key_id> <issuer_id> [build]
                      [--whats-new TEXT | --whats-new-file PATH] [--locale de-DE]
                      [--release-type AFTER_APPROVAL|MANUAL] [--submit] [--dry-run]
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
# Apple has it (or it already shipped) and we must not touch it.
EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
            "METADATA_REJECTED", "INVALID_BINARY"}


def version_train(token: str, build: dict) -> str:
    """The marketing version (1.0.3) the build belongs to."""
    rel = (build.get("relationships", {}).get("preReleaseVersion", {}).get("data") or {})
    if not rel.get("id"):
        pre = call(token, "GET", f"/v1/builds/{build['id']}/preReleaseVersion")
        return pre["data"]["attributes"]["version"]
    return call(token, "GET", f"/v1/preReleaseVersions/{rel['id']}")["data"]["attributes"]["version"]


def find_version(token: str, app_id: str, version_string: str):
    versions = call(token, "GET",
                    f"/v1/apps/{app_id}/appStoreVersions?limit=20&filter[platform]=IOS")["data"]
    for v in versions:
        if v["attributes"].get("versionString") == version_string:
            return v
    return None


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


def submit_for_review(token: str, app_id: str, version_id: str) -> str:
    open_subs = call(token, "GET",
                     f"/v1/reviewSubmissions?filter[app]={app_id}&filter[state]=READY_FOR_REVIEW,"
                     f"WAITING_FOR_REVIEW,IN_REVIEW&limit=5")["data"]
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
    p.add_argument("--release-type", default="AFTER_APPROVAL",
                   choices=["AFTER_APPROVAL", "MANUAL"],
                   help="AFTER_APPROVAL goes live as soon as Apple approves; "
                        "MANUAL waits for you to press release")
    p.add_argument("--submit", action="store_true",
                   help="hand the version to App Store review (without this it is "
                        "only prepared and stays editable)")
    p.add_argument("--dry-run", action="store_true")
    a = p.parse_args()
    if a.whats_new_file:
        with open(a.whats_new_file) as fh:
            a.whats_new = fh.read().strip()

    token = make_token(a.p8, a.key_id, a.issuer_id)
    app_id = find_app(token)
    build = find_build(token, app_id, a.build)
    battrs = build["attributes"]
    train = version_train(token, build)

    print(f"build        : {train} ({battrs.get('version')})")
    print(f"processing   : {battrs.get('processingState')}  expired={battrs.get('expired')}")
    if battrs.get("processingState") != "VALID" or battrs.get("expired"):
        raise ApiError("build is not a VALID, unexpired build")

    live = [v["attributes"].get("versionString") for v in call(
        token, "GET", f"/v1/apps/{app_id}/appStoreVersions?limit=5&filter[appStoreState]=READY_FOR_SALE"
    )["data"]]
    print(f"live in store: {live[0] if live else '(none)'}")

    version = find_version(token, app_id, train)
    if version:
        state = version["attributes"].get("appStoreState")
        print(f"version {train}: exists, state {state}")
        if state not in EDITABLE:
            raise ApiError(f"version {train} is in state {state} — not editable here")
    else:
        print(f"version {train}: does not exist yet, would be created "
              f"(releaseType {a.release_type})")

    if a.dry_run:
        print("\n[dry-run] would " + ("create the version, " if not version else "")
              + f"attach build {battrs.get('version')}"
              + (f", set {a.locale} What's New" if a.whats_new else "")
              + (", and submit it to App Store review" if a.submit
                 else ", and leave it editable (no --submit)"))
        return 0

    if not version:
        version = call(token, "POST", "/v1/appStoreVersions", {
            "data": {"type": "appStoreVersions",
                     "attributes": {"platform": "IOS", "versionString": train,
                                    "releaseType": a.release_type},
                     "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}},
        })["data"]
        print(f"created version {train}")

    call(token, "PATCH", f"/v1/appStoreVersions/{version['id']}/relationships/build",
         {"data": {"type": "builds", "id": build["id"]}})
    print(f"attached build {battrs.get('version')}")

    if a.whats_new:
        print(set_release_notes(token, version["id"], a.whats_new, a.locale))

    if not a.submit:
        print("\nPrepared but NOT submitted — review it in App Store Connect, then "
              "re-run with --submit.")
        return 0

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
