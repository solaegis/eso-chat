#!/bin/bash
# EsoChat - ZIP Package Validation Script (ESOUI PC compliance)

set -e

ADDON_NAME="EsoChat"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

validate_zip_exists() {
    if [ ! -f "$1" ]; then
        print_error "ZIP file not found: $1"
        exit 1
    fi
    print_success "ZIP file found: $1"
}

validate_zip_structure() {
    local zip_file="$1"
    local zip_contents
    zip_contents=$(unzip -l "$zip_file")

    if ! echo "$zip_contents" | grep -q "${ADDON_NAME}/"; then
        print_error "ZIP must contain '${ADDON_NAME}/' folder at root"
        return 1
    fi

    local bad_roots
    bad_roots=$(echo "$zip_contents" | awk '{print $4}' | grep -E '^[^/]+/$' | grep -v "^${ADDON_NAME}/$" || true)
    if [ -n "$bad_roots" ]; then
        print_error "ZIP has unexpected root folder(s) (must be exactly ${ADDON_NAME}/):"
        echo "$bad_roots" | sed 's/^/   /'
        return 1
    fi

    local off_tree
    off_tree=$(echo "$zip_contents" | awk 'NR>3 && $0 !~ /files$/ && NF>=4 {print $4}' | grep -v "^${ADDON_NAME}" | grep -v '^$' || true)
    if [ -n "$off_tree" ]; then
        print_error "ZIP contains paths outside ${ADDON_NAME}/:"
        echo "$off_tree" | head -10 | sed 's/^/   /'
        return 1
    fi
    print_success "Root folder structure correct: ${ADDON_NAME}/"

    if ! echo "$zip_contents" | grep -q "${ADDON_NAME}/${ADDON_NAME}.txt"; then
        print_error "Missing PC manifest: ${ADDON_NAME}.txt"
        return 1
    fi
    print_success "Manifest file present: ${ADDON_NAME}.txt"

    if echo "$zip_contents" | grep -q "${ADDON_NAME}/${ADDON_NAME}.addon"; then
        print_error "ZIP must not contain console manifest ${ADDON_NAME}.addon (PC addons use .txt)"
        return 1
    fi

    if ! echo "$zip_contents" | grep -q "${ADDON_NAME}/src/"; then
        print_error "Missing source directory: src/"
        return 1
    fi
    print_success "Source directory present"

    for file in src/Core.lua src/Init.lua src/Commands.lua; do
        if ! echo "$zip_contents" | grep -q "${ADDON_NAME}/${file}"; then
            print_warning "Missing critical file: ${file}"
        fi
    done

    local disallowed_extensions=(
        "\.h$" "\.hpp$" "\.c$" "\.cpp$"
        "\.py$" "\.sh$" "\.yaml$" "\.yml$" "\.toml$" "\.json$"
        "\.js$" "\.ts$" "\.css$" "\.html$"
        "\.zip$" "\.backup$" "\.bak$" "\.old$" "\.orig$"
        "\.tmp$" "\.log$" "\.exe$" "\.dll$" "\.dmg$"
    )
    local has_disallowed=0
    for ext in "${disallowed_extensions[@]}"; do
        local matches
        matches=$(echo "$zip_contents" | grep -E "$ext" | grep -v "^Archive:" | grep -v "^  Length" | grep -v "^---------" | grep -v "files$" || true)
        if [ -n "$matches" ]; then
            print_error "ZIP contains ESOUI-disallowed files matching: $ext"
            echo "$matches" | head -5 | sed 's/^/   /'
            has_disallowed=1
        fi
    done
    if [ $has_disallowed -eq 1 ]; then
        return 1
    fi
    print_success "All files use ESOUI-allowed extensions"

    local unwanted_patterns=(
        "__MACOSX"
        "\.DS_Store"
        "/\."
        "\.git/"
        "\.github/"
        "\.task/"
        "\.claude/"
        "\.cursor/"
        "node_modules/"
        "__pycache__/"
        "scripts/"
        "\.vscode/"
        "\.idea/"
        "Taskfile"
        "\.pre-commit"
        "\.stylua"
        "\.luacheckrc"
        "\.build-ignore"
        "docs/"
        "taskfiles/"
    )
    local has_unwanted=0
    for pattern in "${unwanted_patterns[@]}"; do
        if echo "$zip_contents" | grep -qE "$pattern"; then
            print_error "ZIP contains hidden/dev artifact matching: $pattern"
            has_unwanted=1
        fi
    done
    if [ $has_unwanted -eq 1 ]; then
        return 1
    fi
    print_success "No hidden or development files in ZIP"
    return 0
}

validate_manifest_content() {
    local zip_file="$1"
    local temp_dir
    temp_dir=$(mktemp -d)
    unzip -q "$zip_file" "${ADDON_NAME}/${ADDON_NAME}.txt" -d "$temp_dir"
    local manifest_file="$temp_dir/${ADDON_NAME}/${ADDON_NAME}.txt"

    for field in Title Author Version AddOnVersion APIVersion; do
        if ! grep -q "^## ${field}:" "$manifest_file"; then
            print_error "Missing required manifest field: ## ${field}:"
            rm -rf "$temp_dir"
            return 1
        fi
    done
    print_success "All required manifest fields present"

    local addon_version
    addon_version=$(grep "^## AddOnVersion:" "$manifest_file" | sed 's/^## AddOnVersion:[[:space:]]*//' | tr -d '\r')
    if ! [[ "$addon_version" =~ ^[0-9]+$ ]]; then
        print_error "AddOnVersion must be a positive integer in release ZIP; got: '${addon_version}'"
        rm -rf "$temp_dir"
        return 1
    fi
    if [ "$addon_version" -lt 1 ]; then
        print_error "AddOnVersion must be >= 1; got: ${addon_version}"
        rm -rf "$temp_dir"
        return 1
    fi
    print_success "AddOnVersion is integer: ${addon_version}"

    if ! grep -qi "not created by, affiliated with" "$manifest_file"; then
        print_error "Missing ZeniMax licensing disclosure in manifest"
        rm -rf "$temp_dir"
        return 1
    fi
    print_success "Licensing disclosure present"

    rm -rf "$temp_dir"
    return 0
}

main() {
    ZIP_FILE="${1:-}"
    if [ -z "$ZIP_FILE" ]; then
        ZIP_FILE=$(ls -t dist/${ADDON_NAME}-*.zip 2>/dev/null | head -1)
        if [ -z "$ZIP_FILE" ]; then
            print_error "No ZIP files found in dist/"
            exit 1
        fi
    fi

    echo "Validating: $ZIP_FILE"
    validate_zip_exists "$ZIP_FILE"
    validate_zip_structure "$ZIP_FILE" || exit 1
    validate_manifest_content "$ZIP_FILE" || exit 1
    print_success "All validations passed!"
}

main "$@"
