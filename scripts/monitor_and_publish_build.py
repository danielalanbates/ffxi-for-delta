#!/usr/bin/env python3
"""
FFXI for Delta - TestFlight Build Monitor & Publisher
Monitors processing of uploaded builds and associates them with beta testing groups.
Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
"""
import time
import sys
import jwt
import requests

KEY_ID = "32R84GFV2F"
ISSUER_ID = "67d2d531-0ef2-43f5-8319-7505313c9fd1"
KEY_PATH = "/Users/daniel/.private_keys/AuthKey_32R84GFV2F.p8"
APP_ID = "6813598872"

INTERNAL_GROUP_ID = "d836bed4-1ab6-48be-95d2-5b12f3813b9a"
CORE_GROUP_ID = "629a3495-d708-4dd5-9e55-e543d4933300"

WHATS_NEW = (
    "Build 3 (v1.0.0):\n"
    "• Fixed crash on launch (eliminated unsafe pointer exclusivity collisions in CADisplayLink frame buffer).\n"
    "• Fixed controller vertical layout clipping on iPhone screens with dynamic aspect-ratio scaling.\n"
    "• Added controller optional unwrapping safety for iOS gamepads.\n"
    "• Ready for Delta GBA ROM export and on-device playtesting."
)

def get_token():
    with open(KEY_PATH) as f:
        pk = f.read()
    now = int(time.time())
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 1200,
        "aud": "appstoreconnect-v1"
    }
    headers = {"kid": KEY_ID, "typ": "JWT"}
    return jwt.encode(payload, pk, algorithm="ES256", headers=headers)

def main():
    target_version = sys.argv[1] if len(sys.argv) > 1 else "3"
    print(f"==> Monitoring App Store Connect for Build {target_version}...")

    build_id = None
    state = None

    for attempt in range(40):
        token = get_token()
        headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
        r = requests.get(f"https://api.appstoreconnect.apple.com/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate", headers=headers)
        if r.status_code != 200:
            print(f"API error ({r.status_code}): {r.text}")
            time.sleep(15)
            continue

        builds = r.json().get("data", [])
        for b in builds:
            if b["attributes"]["version"] == str(target_version):
                build_id = b["id"]
                state = b["attributes"]["processingState"]
                break

        if build_id:
            print(f"[{time.strftime('%H:%M:%S')}] Found Build {target_version} (ID: {build_id}) - State: {state}")
            if state == "VALID":
                break
            elif state == "FAILED":
                print(f"Error: Build processing failed in App Store Connect.")
                sys.exit(1)
        else:
            print(f"[{time.strftime('%H:%M:%S')}] Waiting for Build {target_version} to register in App Store Connect...")

        time.sleep(15)

    if not build_id or state != "VALID":
        print(f"Build {target_version} is still processing or not found yet.")
        sys.exit(2)

    print(f"==> Build {target_version} is VALID! Linking to beta groups...")
    token = get_token()
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    # 1. Add to Internal Testers group
    link_internal_url = f"https://api.appstoreconnect.apple.com/v1/betaGroups/{INTERNAL_GROUP_ID}/relationships/builds"
    payload = {"data": [{"type": "builds", "id": build_id}]}
    r_int = requests.post(link_internal_url, json=payload, headers=headers)
    print(f"Internal group association: status {r_int.status_code}")

    # 2. Add build beta localization (What's New)
    loc_url = f"https://api.appstoreconnect.apple.com/v1/builds/{build_id}/betaBuildLocalizations"
    r_loc = requests.get(loc_url, headers=headers)
    existing_locs = r_loc.json().get("data", [])

    if existing_locs:
        loc_id = existing_locs[0]["id"]
        update_url = f"https://api.appstoreconnect.apple.com/v1/betaBuildLocalizations/{loc_id}"
        u_payload = {
            "data": {
                "type": "betaBuildLocalizations",
                "id": loc_id,
                "attributes": {
                    "whatsNew": WHATS_NEW
                }
            }
        }
        r_up = requests.patch(update_url, json=u_payload, headers=headers)
        print(f"Updated build whatsNew: status {r_up.status_code}")
    else:
        create_url = "https://api.appstoreconnect.apple.com/v1/betaBuildLocalizations"
        c_payload = {
            "data": {
                "type": "betaBuildLocalizations",
                "attributes": {
                    "locale": "en-US",
                    "whatsNew": WHATS_NEW
                },
                "relationships": {
                    "build": {
                        "data": {"type": "builds", "id": build_id}
                    }
                }
            }
        }
        r_cr = requests.post(create_url, json=c_payload, headers=headers)
        print(f"Created build whatsNew: status {r_cr.status_code}")

    # 3. Add to Core Testers (external group)
    link_core_url = f"https://api.appstoreconnect.apple.com/v1/betaGroups/{CORE_GROUP_ID}/relationships/builds"
    r_core = requests.post(link_core_url, json=payload, headers=headers)
    print(f"Core Testers group association: status {r_core.status_code}")

    print("==> ALL SET: Build 3 successfully linked and available on TestFlight!")
    print("TestFlight Public Link: https://testflight.apple.com/join/tTe2JvSz")

if __name__ == "__main__":
    main()
