#!/usr/bin/env python3
"""Distribute an already-uploaded TestFlight build to an external beta group.

The build must already be in App Store Connect (uploaded by `make ios-testflight`).
This submits it for Beta App Review when that is still pending and attaches it to
the group — no rebuild, no upload. Internal groups never need a review; external
ones do, and Apple only hands the build to those testers once it is approved.

Usage: asc_distribute.py <AuthKey.p8> <key_id> <issuer_id> [build] [group]
                         [--whats-new TEXT] [--locale de-DE] [--dry-run]
  build   build number (CFBundleVersion), or "latest" (default)
  group   external beta group name (default: External-1)
"""
import argparse
import json
import sys
import time
import urllib.error
import urllib.request

import jwt

BUNDLE_ID = "de.radiozeit.freiesradio"
API = "https://api.appstoreconnect.apple.com"
DEFAULT_GROUP = "External-1"
DEFAULT_LOCALE = "de-DE"


class ApiError(RuntimeError):
    pass


def make_token(p8_path: str, key_id: str, issuer_id: str) -> str:
    with open(p8_path) as fh:
        key = fh.read()
    now = int(time.time())
    return jwt.encode(
        {"iss": issuer_id, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
        key, algorithm="ES256", headers={"kid": key_id, "typ": "JWT"})


def call(token: str, method: str, path: str, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(API + path, data=data, method=method, headers={
        "Authorization": "Bearer " + token,
        "Content-Type": "application/json",
    })
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode()
        try:
            errors = json.loads(detail)["errors"]
            detail = "; ".join(f"{x.get('code')}: {x.get('detail') or x.get('title')}"
                               for x in errors)
        except Exception:
            pass
        raise ApiError(f"{method} {path} -> {e.code}: {detail}") from None


def find_app(token: str) -> str:
    apps = call(token, "GET", f"/v1/apps?filter[bundleId]={BUNDLE_ID}&limit=1")["data"]
    if not apps:
        raise ApiError(f"no app with bundle id {BUNDLE_ID}")
    return apps[0]["id"]


def find_build(token: str, app_id: str, wanted: str):
    if wanted == "latest":
        query = f"/v1/builds?filter[app]={app_id}&limit=1&sort=-uploadedDate"
    else:
        query = f"/v1/builds?filter[app]={app_id}&filter[version]={wanted}&limit=1"
    builds = call(token, "GET", query)["data"]
    if not builds:
        raise ApiError(f"no build {wanted!r} for app {app_id}")
    return builds[0]


def find_group(token: str, app_id: str, name: str):
    for g in call(token, "GET", f"/v1/apps/{app_id}/betaGroups?limit=50")["data"]:
        if g["attributes"].get("name") == name:
            return g
    raise ApiError(f"no beta group named {name!r}")


def check_review_info(token: str, app_id: str) -> list:
    """Apple rejects the submission if these are unset — say so before submitting."""
    missing = []
    detail = call(token, "GET", f"/v1/apps/{app_id}/betaAppReviewDetail")
    attrs = detail.get("data", {}).get("attributes", {})
    if not attrs.get("contactEmail"):
        missing.append("beta review contact (App Store Connect > TestFlight > Test Information)")
    if attrs.get("demoAccountRequired") and not attrs.get("demoAccountName"):
        missing.append("demo account (marked as required but not filled in)")
    locs = call(token, "GET", f"/v1/apps/{app_id}/betaAppLocalizations")["data"]
    if not any(x["attributes"].get("description") for x in locs):
        missing.append("beta description (at least one locale)")
    if not any(x["attributes"].get("feedbackEmail") for x in locs):
        missing.append("feedback email")
    return missing


def set_whats_new(token: str, build_id: str, text: str, locale: str) -> str:
    """Set the release notes testers see. Separate from the upload because
    fastlane can only attach them while waiting for processing, which would
    keep the macOS runner busy for another ten minutes."""
    existing = call(token, "GET", f"/v1/builds/{build_id}/betaBuildLocalizations")["data"]
    for loc in existing:
        if loc["attributes"].get("locale") == locale:
            call(token, "PATCH", f"/v1/betaBuildLocalizations/{loc['id']}", {
                "data": {"type": "betaBuildLocalizations", "id": loc["id"],
                         "attributes": {"whatsNew": text}},
            })
            return f"updated {locale} release notes"
    call(token, "POST", "/v1/betaBuildLocalizations", {
        "data": {"type": "betaBuildLocalizations",
                 "attributes": {"locale": locale, "whatsNew": text},
                 "relationships": {"build": {"data": {"type": "builds", "id": build_id}}}},
    })
    return f"added {locale} release notes"


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("p8")
    p.add_argument("key_id")
    p.add_argument("issuer_id")
    p.add_argument("build", nargs="?", default="latest")
    p.add_argument("group", nargs="?", default=DEFAULT_GROUP)
    p.add_argument("--whats-new", default=None,
                   help="release notes for this build (what testers see)")
    p.add_argument("--locale", default=DEFAULT_LOCALE)
    p.add_argument("--dry-run", action="store_true")
    a = p.parse_args()
    p8, key_id, issuer_id = a.p8, a.key_id, a.issuer_id
    wanted, group_name, dry_run = a.build, a.group, a.dry_run

    token = make_token(p8, key_id, issuer_id)
    app_id = find_app(token)
    build = find_build(token, app_id, wanted)
    bid, battrs = build["id"], build["attributes"]
    detail = call(token, "GET", f"/v1/builds/{bid}/buildBetaDetail")
    state = detail.get("data", {}).get("attributes", {}).get("externalBuildState")

    print(f"build      : {battrs.get('version')} (uploaded {battrs.get('uploadedDate')})")
    print(f"processing : {battrs.get('processingState')}  expired={battrs.get('expired')}")
    print(f"external   : {state}")

    if battrs.get("processingState") != "VALID":
        raise ApiError(f"build is {battrs.get('processingState')}, not VALID — wait for processing")
    if battrs.get("expired"):
        raise ApiError("build has expired; upload a new one")

    group = find_group(token, app_id, group_name)
    if group["attributes"].get("isInternalGroup"):
        raise ApiError(f"{group_name!r} is an internal group — it needs no review "
                       f"and already receives every build")
    print(f"group      : {group_name} ({group['id']})")

    missing = check_review_info(token, app_id)
    if missing:
        print("\nBeta App Review info is incomplete:", file=sys.stderr)
        for m in missing:
            print(f"  - {m}", file=sys.stderr)
        return 1

    needs_submission = state == "READY_FOR_BETA_SUBMISSION"
    if dry_run:
        if a.whats_new is not None:
            print(f"\n[dry-run] would set {a.locale} release notes to:\n{a.whats_new}")
        print("\n[dry-run] would " + ("submit for Beta App Review and " if needs_submission else "")
              + f"attach the build to {group_name!r}")
        return 0

    if a.whats_new is not None:
        print(set_whats_new(token, bid, a.whats_new, a.locale))

    if needs_submission:
        call(token, "POST", "/v1/betaAppReviewSubmissions", {
            "data": {"type": "betaAppReviewSubmissions",
                     "relationships": {"build": {"data": {"type": "builds", "id": bid}}}},
        })
        print("submitted for Beta App Review")
    else:
        print(f"no submission needed (state {state})")

    try:
        call(token, "POST", f"/v1/betaGroups/{group['id']}/relationships/builds",
             {"data": [{"type": "builds", "id": bid}]})
        print(f"attached to {group_name!r}")
    except ApiError as e:
        # Re-running after the build is already attached must not look like a failure.
        if "already" in str(e).lower():
            print(f"already attached to {group_name!r}")
        else:
            raise

    final = call(token, "GET", f"/v1/builds/{bid}/buildBetaDetail")
    print("external   :", final.get("data", {}).get("attributes", {}).get("externalBuildState"))
    print("\nApple reviews the build before external testers get it; they are notified "
          "automatically once it is approved.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ApiError as exc:
        sys.stdout.flush()
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1) from None
