#!/bin/bash
# EsoChat - Whitelist-Based Build Copy Script
# ESOUI PC addons: *.lua, *.xml, *.txt, *.md only (no .addon — that is console)

set -e

SOURCE_DIR="$1"
DEST_DIR="$2"
ADDON_NAME="EsoChat"

if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
    echo "Usage: $0 <source_dir> <dest_dir>"
    exit 1
fi

ALLOWED_EXTENSIONS=("lua" "xml" "txt" "md")
mkdir -p "$DEST_DIR"

if [ -f "$SOURCE_DIR/${ADDON_NAME}.txt" ]; then
    cp "$SOURCE_DIR/${ADDON_NAME}.txt" "$DEST_DIR/"
    echo "  ✓ Copied manifest: ${ADDON_NAME}.txt"
elif [ -f "$SOURCE_DIR/${ADDON_NAME}.addon" ]; then
    echo "❌ Error: found ${ADDON_NAME}.addon — PC addons must use ${ADDON_NAME}.txt"
    exit 1
else
    echo "❌ Error: missing manifest ${ADDON_NAME}.txt"
    exit 1
fi

if [ -f "$SOURCE_DIR/README_ESOUI.txt" ]; then
    cp "$SOURCE_DIR/README_ESOUI.txt" "$DEST_DIR/"
    echo "  ✓ Copied README_ESOUI.txt"
fi

if [ -d "$SOURCE_DIR/src" ]; then
    mkdir -p "$DEST_DIR/src"
    for ext in "${ALLOWED_EXTENSIONS[@]}"; do
        find "$SOURCE_DIR/src" -type f -name "*.${ext}" \
            ! -path "*/test/*" \
            ! -path "*/tests/*" \
            | while read -r file; do
            rel_path="${file#$SOURCE_DIR/src/}"
            dest_file="$DEST_DIR/src/$rel_path"
            mkdir -p "$(dirname "$dest_file")"
            cp "$file" "$dest_file"
        done
    done
    echo "  ✓ Copied src/ directory"
fi

if [ -d "$SOURCE_DIR/textures" ]; then
    mkdir -p "$DEST_DIR/textures"
    find "$SOURCE_DIR/textures" -type f -name "*.dds" | while read -r file; do
        cp "$file" "$DEST_DIR/textures/$(basename "$file")"
    done
    echo "  ✓ Copied textures/ directory"
fi

if find "$DEST_DIR" \( -name '.*' -o -name '__MACOSX' \) 2>/dev/null | grep -q .; then
    echo "❌ Error: hidden or __MACOSX files found in build output"
    find "$DEST_DIR" \( -name '.*' -o -name '__MACOSX' \)
    exit 1
fi

echo "✅ Whitelist-based copy complete"
