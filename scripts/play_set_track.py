#!/usr/bin/env python3
"""Attach an already-uploaded versionCode to a Google Play track — no re-upload.

The bundle must already exist in the app (uploaded by an earlier release run).
This just makes that versionCode the active release on the given track.

Usage: play_set_track.py <service_account.json> <versionCode> <track> [name]
"""
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build

PACKAGE = "de.radiozeit.freiesradio"


def main() -> int:
    if len(sys.argv) < 4:
        print(__doc__, file=sys.stderr)
        return 2
    sa, vc, track = sys.argv[1], sys.argv[2], sys.argv[3]
    name = sys.argv[4] if len(sys.argv) > 4 else None

    creds = service_account.Credentials.from_service_account_file(
        sa, scopes=["https://www.googleapis.com/auth/androidpublisher"])
    svc = build("androidpublisher", "v3", credentials=creds, cache_discovery=False)

    edit = svc.edits().insert(packageName=PACKAGE, body={}).execute()
    eid = edit["id"]
    release = {"versionCodes": [str(vc)], "status": "completed"}
    if name:
        release["name"] = name
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
