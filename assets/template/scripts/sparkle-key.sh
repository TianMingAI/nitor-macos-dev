#!/bin/bash
# Write Sparkle's EdDSA public key to Resources/sparkle-public-key.txt (build.sh puts it in Info.plist).
# The private key lives in the login keychain ("ed25519", shared by all your Sparkle apps) and never in the repo.
# First run on a Mac without a key creates one; back it up with:  generate_keys -x ~/Desktop/sparkle-key.txt
set -euo pipefail
cd "$(dirname "$0")/.."
swift package resolve >/dev/null 2>&1 || swift package resolve >/dev/null   # retry once: fresh checkouts can race the cache
BIN=.build/artifacts/sparkle/Sparkle/bin
KEY=$("$BIN/generate_keys" -p 2>/dev/null || true)
if [ -z "$KEY" ] || [[ "$KEY" == *ERROR* ]]; then
  "$BIN/generate_keys" >/dev/null
  KEY=$("$BIN/generate_keys" -p)
fi
echo "$KEY" > Resources/sparkle-public-key.txt
echo "Sparkle public key: $KEY"
