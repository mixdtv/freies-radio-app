#!/usr/bin/env python3
"""Attach an already-uploaded versionCode to a Google Play track — no re-upload.

The bundle must already exist in the app (uploaded by an earlier release run).
This just makes that versionCode the active release on the given track.

Usage: play_set_track.py <service_account.json> <versionCode> <track> [name]
                         [--notes TEXT | --notes-file PATH] [--language de-DE]

Without --notes the release goes out without release notes: a track update
replaces the whole release object, so notes are not carried over from the
version that was on the track before.
"""
import argparse
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build

PACKAGE = "de.radiozeit.freiesradio"
DEFAULT_LANGUAGE = "de-DE"


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("service_account_json")
    p.add_argument("version_code")
    p.add_argument("track")
    p.add_argument("name", nargs="?", default=None)
    p.add_argument("--notes", default=None, help="release notes (what users see)")
    p.add_argument("--notes-file", default=None,
                   help="read the release notes from this file (for multi-line text, "
                        "e.g. fastlane/metadata/android/de-DE/changelogs/<vc>.txt)")
    p.add_argument("--language", default=DEFAULT_LANGUAGE)
    a = p.parse_args()
    if a.notes_file:
        with open(a.notes_file) as fh:
            a.notes = fh.read().strip()
    sa, vc, track, name = a.service_account_json, a.version_code, a.track, a.name

    creds = service_account.Credentials.from_service_account_file(
        sa, scopes=["https://www.googleapis.com/auth/androidpublisher"])
    svc = build("androidpublisher", "v3", credentials=creds, cache_discovery=False)

    edit = svc.edits().insert(packageName=PACKAGE, body={}).execute()
    eid = edit["id"]
    release = {"versionCodes": [str(vc)], "status": "completed"}
    if name:
        release["name"] = name
    if a.notes:
        if len(a.notes) > 500:
            print(f"release notes are {len(a.notes)} characters; Play allows 500",
                  file=sys.stderr)
            return 2
        release["releaseNotes"] = [{"language": a.language, "text": a.notes}]
    try:
        svc.edits().tracks().update(
            packageName=PACKAGE, editId=eid, track=track,
            body={"releases": [release]}).execute()
        svc.edits().commit(packageName=PACKAGE, editId=eid).execute()
        print(f"vc {vc} is now the active release on track '{track}'")
        return 0
    except Exception:
        try:
            svc.edits().delete(packageName=PACKAGE, editId=eid).execute()
        except Exception:
            pass
        raise


if __name__ == "__main__":
    raise SystemExit(main())
