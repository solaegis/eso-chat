#!/bin/bash
# EsoCombatLock - Pre-Build Validation Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

ALLOWED_EXTENSIONS=("lua" "xml" "txt" "md")
CHECK_DIRS=("src")
DISALLOWED_FOUND=0

echo "🔍 Pre-Build Validation: Checking for disallowed file types..."
echo ""

DISALLOWED_PATTERNS=(
    "*.h" "*.hpp" "*.c" "*.cpp" "*.py" "*.sh"
    "*.yaml" "*.yml" "*.toml" "*.json" "*.js"
)

for pattern in "${DISALLOWED_PATTERNS[@]}"; do
    found=$(find "${CHECK_DIRS[@]}" -type f -name "$pattern" 2>/dev/null | head -10)
    if [ -n "$found" ]; then
        echo -e "${RED}❌ Found disallowed files: $pattern${NC}"
        echo "$found" | sed 's/^/   /'
        DISALLOWED_FOUND=1
    fi
done

if [ -d "src" ]; then
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        ext="${file##*.}"
        ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
        allowed=0
        for allowed_ext in "${ALLOWED_EXTENSIONS[@]}"; do
            if [ "$ext_lower" = "$allowed_ext" ]; then
                allowed=1
                break
            fi
        done
        if [ $allowed -eq 0 ]; then
            echo -e "${RED}❌ Disallowed file in src/: $file${NC}"
            DISALLOWED_FOUND=1
        fi
    done < <(find src -type f ! -path "*/.*" 2>/dev/null)
fi

echo ""
if [ $DISALLOWED_FOUND -eq 1 ]; then
    echo -e "${RED}❌ PRE-BUILD VALIDATION FAILED${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Pre-build validation passed${NC}"
exit 0
