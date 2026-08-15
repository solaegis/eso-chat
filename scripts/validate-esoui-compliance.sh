#!/bin/bash
# EsoChat - ESOUI packaging / listing / SavedVariables compliance
# Usage:
#   scripts/validate-esoui-compliance.sh           # static + dist ZIP if present
#   scripts/validate-esoui-compliance.sh --static  # repo layout, Init.lua, README only

set -euo pipefail

ADDON_NAME="EsoChat"
MANIFEST_FILE="${ADDON_NAME}.txt"
INIT_FILE="src/Init.lua"
CORE_FILE="src/Core.lua"
README_ESOUI="README_ESOUI.txt"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

STATIC_ONLY=0
for arg in "$@"; do
    case "$arg" in
        --static) STATIC_ONLY=1 ;;
        --with-fixtures)
            echo "Fixtures are optional advanced; use --static or default ZIP check."
            echo "Ignoring --with-fixtures (no fixture suite in this template)."
            ;;
        -h|--help)
            echo "Usage: $0 [--static]"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
PASSED=0
FAILED=0

ok() { echo -e "${GREEN}✅ $1${NC}"; PASSED=$((PASSED + 1)); }
fail() { echo -e "${RED}❌ $1${NC}"; FAILED=$((FAILED + 1)); }

validate_repo_layout() {
    echo ""
    echo "── Repo layout ──"
    if [ -f "$MANIFEST_FILE" ]; then
        ok "Manifest present: $MANIFEST_FILE"
    else
        fail "Missing PC manifest: $MANIFEST_FILE"
    fi
    if [ -f "${ADDON_NAME}.addon" ]; then
        fail "Console manifest ${ADDON_NAME}.addon must not exist for PC-only addon"
    else
        ok "No ${ADDON_NAME}.addon (PC uses .txt)"
    fi
}

validate_manifest_technical() {
    echo ""
    echo "── Manifest technical (Section 1) ──"
    if [ ! -f "$MANIFEST_FILE" ]; then
        fail "Missing $MANIFEST_FILE"
        return
    fi

    local runner=""
    if command -v lua >/dev/null 2>&1; then
        runner=lua
    elif command -v luajit >/dev/null 2>&1; then
        runner=luajit
    fi

    if [ -n "$runner" ]; then
        if $runner "$SCRIPT_DIR/validate-manifest.lua" "$MANIFEST_FILE"; then
            ok "validate-manifest.lua passed on source manifest"
        else
            fail "validate-manifest.lua failed on $MANIFEST_FILE"
        fi
    else
        if head -c 3 "$MANIFEST_FILE" | grep -q $'\xEF\xBB\xBF'; then
            fail "Manifest has UTF-8 BOM"
        else
            ok "No UTF-8 BOM"
        fi
        local long
        long=$(awk 'length($0) > 301 { print NR": "length($0); exit 1 }' "$MANIFEST_FILE" || true)
        if [ -n "$long" ]; then
            fail "Manifest line over 301 bytes: $long"
        else
            ok "No manifest line over 301 bytes"
        fi
        if grep -qi "not created by, affiliated with" "$MANIFEST_FILE"; then
            ok "Licensing disclosure present"
        else
            fail "Missing ZeniMax licensing disclosure"
        fi
        local aov
        aov=$(grep "^## AddOnVersion:" "$MANIFEST_FILE" | sed 's/^## AddOnVersion:[[:space:]]*//' | tr -d '\r')
        if [[ "$aov" =~ ^[0-9]+$ ]] || [ "$aov" = "@addon-build-version@" ] || [ "$aov" = "@project-version@" ]; then
            ok "AddOnVersion is integer or allowed placeholder (${aov})"
        else
            fail "AddOnVersion invalid: ${aov}"
        fi
    fi
}

validate_saved_variables() {
    echo ""
    echo "── SavedVariables (static) ──"
    if [ ! -f "$INIT_FILE" ]; then
        fail "Missing $INIT_FILE"
        return
    fi
    if [ ! -f "$CORE_FILE" ]; then
        fail "Missing $CORE_FILE"
        return
    fi

    if grep -qE 'NewAccountWide\([^)]*nil,' "$INIT_FILE"; then
        fail "Init.lua still uses nil namespace in NewAccountWide (must use GetWorldName())"
    else
        ok "No nil-namespace NewAccountWide pattern"
    fi

    if grep -q 'ZO_SavedVars:NewAccountWide' "$INIT_FILE" \
        && grep -q 'GetWorldName()' "$INIT_FILE"; then
        if grep -qE 'NewAccountWide\([^)]*GetWorldName\(\)' "$INIT_FILE"; then
            ok "NewAccountWide uses GetWorldName()"
        else
            fail "NewAccountWide must pass GetWorldName() as namespace (3rd arg)"
        fi
    else
        fail "Init.lua must call ZO_SavedVars:NewAccountWide with GetWorldName()"
    fi

    local sv_version
    sv_version=$(grep -E '^\s*[A-Za-z_][A-Za-z0-9_]*\.SV_VERSION\s*=' "$CORE_FILE" | head -1 | grep -oE '[0-9]+' || true)
    if [ -n "$sv_version" ] && [ "$sv_version" -ge 1 ]; then
        ok "SV_VERSION is ${sv_version}"
    else
        fail "Core.lua must define Alias.SV_VERSION as a positive integer (found: ${sv_version:-missing})"
    fi
}

validate_esoui_listing() {
    echo ""
    echo "── ESOUI listing (README_ESOUI.txt) ──"
    if [ ! -f "$README_ESOUI" ]; then
        fail "Missing $README_ESOUI"
        return
    fi

    if grep -q 'AI assistance' "$README_ESOUI"; then
        ok "AI disclosure present"
    else
        fail "README_ESOUI.txt must contain AI disclosure ('AI assistance')"
    fi

    if grep -q 'LibAddonMenu' "$README_ESOUI"; then
        ok "LibAddonMenu credit/dependency present"
    else
        fail "README_ESOUI.txt must mention LibAddonMenu"
    fi

    if LC_ALL=C grep -n '[^[:print:][:space:]]' "$README_ESOUI" >/dev/null 2>&1; then
        fail "README_ESOUI.txt contains non-ASCII characters"
        LC_ALL=C grep -n '[^[:print:][:space:]]' "$README_ESOUI" | head -5 | sed 's/^/   /' || true
    else
        if command -v perl >/dev/null 2>&1; then
            if perl -ne 'exit 1 if /[^\x00-\x7F]/' "$README_ESOUI"; then
                ok "README_ESOUI.txt is ASCII-only"
            else
                fail "README_ESOUI.txt contains non-ASCII bytes"
            fi
        else
            ok "README_ESOUI.txt printable ASCII check passed"
        fi
    fi
}

validate_dist_zip() {
    echo ""
    echo "── Release ZIP ──"
    local zip_file
    zip_file=$(ls -t dist/${ADDON_NAME}-*.zip 2>/dev/null | head -1 || true)
    if [ -z "$zip_file" ] || [ ! -f "$zip_file" ]; then
        echo "   (no dist/${ADDON_NAME}-*.zip — skip artifact check)"
        return 0
    fi
    if bash "$SCRIPT_DIR/validate-zip.sh" "$zip_file"; then
        ok "Artifact ZIP valid: $(basename "$zip_file")"
    else
        fail "Artifact ZIP failed validation: $zip_file"
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " EsoChat — ESOUI compliance"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

validate_repo_layout
validate_manifest_technical
validate_saved_variables
validate_esoui_listing

if [ "$STATIC_ONLY" -eq 0 ]; then
    validate_dist_zip
fi

echo ""
echo "Passed: $PASSED | Failed: $FAILED"
if [ "$FAILED" -ne 0 ]; then
    echo -e "${RED}❌ ESOUI compliance failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ ESOUI compliance passed${NC}"
exit 0
