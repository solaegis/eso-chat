#!/bin/bash
# Set ## AddOnVersion: in the addon manifest (portable macOS + Linux sed)
# Usage: scripts/set-addon-version.sh <manifest.txt> [YYYYMMDD]

set -euo pipefail

MANIFEST="${1:?manifest path required}"
DATE_VERSION="${2:-$(date +'%Y%m%d')}"

if [ ! -f "$MANIFEST" ]; then
    echo "❌ Manifest not found: $MANIFEST"
    exit 1
fi

if [ "$(uname -s)" = "Darwin" ]; then
    sed -i '' "s/^## AddOnVersion: .*/## AddOnVersion: ${DATE_VERSION}/" "$MANIFEST"
else
    sed -i "s/^## AddOnVersion: .*/## AddOnVersion: ${DATE_VERSION}/" "$MANIFEST"
fi

echo "✅ Set AddOnVersion to ${DATE_VERSION} in $(basename "$MANIFEST")"
