#!/bin/bash
# Wipes the local emulators and re-seeds them.
cd "$(dirname "$0")"
curl -s -X DELETE "http://127.0.0.1:8085/emulator/v1/projects/art-platform-a2f95/databases/artdf/documents" >/dev/null
curl -s -X DELETE "http://127.0.0.1:9099/emulator/v1/projects/art-platform-a2f95/accounts" >/dev/null
node seed.mjs 2>&1 | grep -v -E "MetadataLookup|trace-warnings"
