#!/bin/bash
# EsoChat - Pre-Release Validation Script

set -e

ADDON_NAME="EsoChat"
MANIFEST_FILE="${ADDON_NAME}.txt"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

print_success() { echo -e "${GREEN}✅ $1${NC}"; PASSED=$((PASSED + 1)); }
print_error() { echo -e "${RED}❌ $1${NC}"; FAILED=$((FAILED + 1)); }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; WARNINGS=$((WARNINGS + 1)); }
print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

validate_lint() {
    print_section "1. Code Linting"
    if task lint >/dev/null 2>&1; then
        print_success "Lint check passed"
    else
        print_error "Lint check failed — run 'task lint'"
        return 1
    fi
}

validate_syntax() {
    print_section "2. Lua Syntax Validation"
    if task dev:validate:syntax >/dev/null 2>&1; then
        print_success "Syntax validation passed"
    else
        print_error "Syntax validation failed"
        return 1
    fi
}

validate_manifest() {
    print_section "3. Manifest Validation"
    if [ ! -f "$MANIFEST_FILE" ]; then
        print_error "Manifest not found: $MANIFEST_FILE"
        return 1
    fi
    if command_exists lua || command_exists luajit; then
        local runner=lua
        command_exists luajit && runner=luajit
        if $runner scripts/validate-manifest.lua "$MANIFEST_FILE" >/dev/null 2>&1; then
            print_success "Manifest validation passed"
        else
            print_error "Manifest validation failed"
            return 1
        fi
    else
        print_warning "lua/luajit not found — skipped manifest script"
    fi
}

validate_changelog() {
    print_section "4. CHANGELOG Validation"
    if [ ! -f CHANGELOG.md ]; then
        print_error "CHANGELOG.md not found"
        return 1
    fi
    if grep -q "^## \[.*\]" CHANGELOG.md; then
        print_success "CHANGELOG.md has version entries"
    else
        print_error "CHANGELOG.md has no version entries"
        return 1
    fi
}

validate_build() {
    print_section "5. Build Validation"
    rm -rf dist/*.zip 2>/dev/null || true
    if task build:fast >/dev/null 2>&1; then
        print_success "Build completed"
        ZIP_FILE=$(ls -t dist/${ADDON_NAME}-*.zip 2>/dev/null | head -1)
        if [ -n "$ZIP_FILE" ] && [ -f "$ZIP_FILE" ]; then
            print_success "Release ZIP created: $(basename "$ZIP_FILE")"
            if scripts/validate-zip.sh "$ZIP_FILE"; then
                print_success "ZIP validation passed"
            else
                print_error "ZIP validation failed"
                return 1
            fi
        else
            print_error "Release ZIP not found after build"
            return 1
        fi
    else
        print_error "Build failed — run 'task build:fast'"
        return 1
    fi
}

validate_git_state() {
    print_section "6. Git State"
    if ! command_exists git || ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_warning "Not a git repository"
        return 0
    fi
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "Uncommitted changes detected"
    else
        print_success "Working directory is clean"
    fi
}

validate_esoui_compliance() {
    print_section "7. ESOUI Compliance"
    chmod +x scripts/validate-esoui-compliance.sh
    if bash scripts/validate-esoui-compliance.sh; then
        print_success "ESOUI compliance passed"
    else
        print_error "ESOUI compliance failed"
        return 1
    fi
}

main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " EsoChat — Pre-Release Validation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local failed=0
    validate_lint || failed=1
    validate_syntax || failed=1
    validate_manifest || failed=1
    validate_changelog || failed=1
    validate_build || failed=1
    validate_git_state || true
    validate_esoui_compliance || failed=1

    echo ""
    echo "Passed: $PASSED | Failed: $FAILED | Warnings: $WARNINGS"
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}✅ All critical validations passed!${NC}"
        exit 0
    fi
    echo -e "${RED}❌ Fix errors before releasing.${NC}"
    exit 1
}

main "$@"
