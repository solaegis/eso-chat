#!/bin/bash
# Replace @project-version@ placeholder with actual Git version.
# Never substitutes on ## AddOnVersion: lines (those must stay integer-only;
# use set-addon-version.sh for AddOnVersion).
# Usage: ./scripts/replace-version.sh <target_path> <version>

set -e

TARGET="$1"
VERSION="$2"

if [ -z "$TARGET" ] || [ -z "$VERSION" ]; then
  echo "Usage: $0 <target_path> <version>"
  exit 1
fi

replace_in_file() {
  local file="$1"
  if ! grep -q "@project-version@" "$file" 2>/dev/null; then
    return 0
  fi
  echo "  Replacing @project-version@ in: $file"
  # Protect ## AddOnVersion: lines from semver injection (ESO atoi requires integer).
  local tmp
  tmp=$(mktemp)
  awk -v ver="$VERSION" '
    /^## AddOnVersion:/ { print; next }
    { gsub(/@project-version@/, ver); print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

if [ -f "$TARGET" ]; then
  echo "📝 Replacing @project-version@ with ${VERSION} in file..."
  replace_in_file "$TARGET"
elif [ -d "$TARGET" ]; then
  echo "📝 Replacing @project-version@ with ${VERSION} in directory: $TARGET"
  find "$TARGET" -type f \( \
    -name "*.lua" -o \
    -name "*.md" -o \
    -name "*.txt" \
  \) | while read -r file; do
    replace_in_file "$file"
  done
else
  echo "❌ Error: $TARGET is not a file or directory"
  exit 1
fi

echo "✅ Done"
