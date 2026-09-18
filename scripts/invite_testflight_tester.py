#!/usr/bin/env python3
"""
FFXI for Delta - TestFlight Tester Invitation Script
Adds danielalanbates@gmail.com to the TestFlight beta testers for FFXI Delta.
Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
"""
import time
import json
import jwt
import requests

KEY_ID = "32R84GFV2F"
ISSUER_ID = "67d2d531-0ef2-43f5-8319-7505313c9fd1"
KEY_PATH = "/Users/daniel/.private_keys/AuthKey_32R84GFV2F.p8"
EMAIL = "danielalanbates@gmail.com"
FIRST_NAME = "Daniel"
LAST_NAME = "Bates"
BUNDLE_ID = "org.batesai.ffxi"

def get_token():
    with open(KEY_PATH, "r") as f:
        private_key = f.read()
    now = int(time.time())
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 1200,
        "aud": "appstoreconnect-v1"
    }
    headers = {"kid": KEY_ID, "typ": "JWT"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers=headers)

def main():
    token = get_token()
    auth_headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    print("==> Checking App Store Connect for FFXI Delta...")
    r = requests.get(f"https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={BUNDLE_ID}", headers=auth_headers)
    apps = r.json().get("data", [])
    if not apps:
        print(f"Error: App with bundle ID '{BUNDLE_ID}' not yet found in App Store Connect.")
        print("Please create the app record once at: https://appstoreconnect.apple.com/apps")
        print("Fields: Name='FFXI Delta', Bundle ID='org.batesai.ffxi', SKU='org.batesai.ffxi'")
        return

    app = apps[0]
    app_id = app["id"]
    app_name = app["attributes"]["name"]
    print(f"==> Found App: {app_name} (ID: {app_id})")

    # Look for Beta Groups
    print(f"==> Fetching beta groups for {app_name}...")
    r = requests.get(f"https://api.appstoreconnect.apple.com/v1/apps/{app_id}/betaGroups", headers=auth_headers)
    groups = r.json().get("data", [])
    group_id = None
    if groups:
        group_id = groups[0]["id"]
        print(f"==> Using beta group: {groups[0]['attributes']['name']} (ID: {group_id})")
    else:
        # Create a beta group
        print("==> Creating internal beta group...")
        bg_payload = {
            "data": {
                "type": "betaGroups",
                "attributes": {
                    "name": "Core Testers",
                    "isInternalGroup": False,
                    "publicLinkEnabled": True
                },
                "relationships": {
                    "app": {
                        "data": {"type": "apps", "id": app_id}
                    }
                }
            }
        }
        r = requests.post("https://api.appstoreconnect.apple.com/v1/betaGroups", json=bg_payload, headers=auth_headers)
        if r.status_code in [200, 201]:
            group_id = r.json()["data"]["id"]
            print(f"==> Created beta group: {group_id}")

    # Add tester
    print(f"==> Adding {EMAIL} ({FIRST_NAME} {LAST_NAME}) to TestFlight...")
    tester_payload = {
        "data": {
            "type": "betaTesters",
            "attributes": {
                "email": EMAIL,
                "firstName": FIRST_NAME,
                "lastName": LAST_NAME
            },
            "relationships": {
                "betaGroups": {
                    "data": [{"type": "betaGroups", "id": group_id}] if group_id else []
                }
            }
        }
    }
    r = requests.post("https://api.appstoreconnect.apple.com/v1/betaTesters", json=tester_payload, headers=auth_headers)
    if r.status_code in [200, 201]:
        print(f"==> SUCCESS: Invited {EMAIL} to TestFlight! Apple has dispatched the invitation email.")
    else:
        print(f"==> Tester response ({r.status_code}):", r.text)

if __name__ == "__main__":
    main()
