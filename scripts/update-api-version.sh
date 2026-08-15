#!/bin/bash
# Update ESO API Version for EsoChat
# Supports one value (single) or two (Live + PTS dual-load).
# Usage:
#   ./scripts/update-api-version.sh 101052
#   ./scripts/update-api-version.sh 101051 101050

set -euo pipefail

ADDON_NAME="EsoChat"
MANIFEST_FILE="${ADDON_NAME}.txt"

usage() {
    echo "Usage: $0 <API_VERSION> [API_VERSION_PTS]"
    echo "Example (single): $0 101052"
    echo "Example (dual Live+PTS): $0 101051 101050"
    exit 1
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    usage
fi

PRIMARY="$1"
SECONDARY="${2:-}"

if ! [[ "$PRIMARY" =~ ^[0-9]{6}$ ]]; then
    echo "❌ API version must be 6 digits (e.g., 101051)"
    exit 1
fi

if [ -n "$SECONDARY" ] && ! [[ "$SECONDARY" =~ ^[0-9]{6}$ ]]; then
    echo "❌ Second API version must be 6 digits (e.g., 101050)"
    exit 1
fi

if [ ! -f "$MANIFEST_FILE" ]; then
    echo "❌ Manifest file not found: $MANIFEST_FILE"
    exit 1
fi

CURRENT_API_VERSION=$(grep "^## APIVersion:" "$MANIFEST_FILE" | sed 's/^## APIVersion:[[:space:]]*//')
echo "📋 Current API version: $CURRENT_API_VERSION"

if [ -n "$SECONDARY" ]; then
    NEW_LINE="## APIVersion: ${PRIMARY} ${SECONDARY}"
    NEW_DISPLAY="${PRIMARY} ${SECONDARY}"
else
    NEW_LINE="## APIVersion: ${PRIMARY}"
    NEW_DISPLAY="${PRIMARY}"
fi

if [[ "$OSTYPE" == "darwin"* ]] || [ "$(uname -s)" = "Darwin" ]; then
    sed -i '' "s/^## APIVersion: .*/${NEW_LINE}/g" "$MANIFEST_FILE"
else
    sed -i "s/^## APIVersion: .*/${NEW_LINE}/g" "$MANIFEST_FILE"
fi

echo "✅ Updated API version: $CURRENT_API_VERSION → $NEW_DISPLAY"
grep "^## APIVersion:" "$MANIFEST_FILE"
