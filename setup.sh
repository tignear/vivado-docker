#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXTRACT_DIR=$(mktemp -d)

trap 'echo "=== Cleaning up extracted installer ==="; rm -rf "$EXTRACT_DIR"' EXIT

# Find installer .bin
installer="$(find "$SCRIPT_DIR" -maxdepth 1 -name '*.bin' -type f | head -1)"
if [ -z "$installer" ]; then
  echo "ERROR: No .bin installer found in $SCRIPT_DIR"
  echo "Download from: https://www.xilinx.com/support/download.html"
  exit 1
fi

echo "=== Extracting: $(basename "$installer") ==="
bash "$installer" --keep --noexec --target "$EXTRACT_DIR"

echo "=== Generating auth token (enter your AMD account credentials) ==="
"$EXTRACT_DIR/xsetup" -b AuthTokenGen

token="$HOME/.Xilinx/wi_authentication_key"
if [ ! -f "$token" ]; then
  echo "ERROR: Token file not found at $token"
  exit 1
fi

cp "$token" "$SCRIPT_DIR/auth_token"
echo "=== Done: auth_token created ==="
echo "Run 'docker compose build' to build the image."
