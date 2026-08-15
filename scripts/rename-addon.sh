#!/usr/bin/env bash
# Rebrand EsoChat tokens to a new ESO addon identity.
# Usage:
#   ./scripts/rename-addon.sh --name EsoChat --title "ESO Chat" --alias EC --slash ech --repo solaegis/eso-chat
#   ./scripts/rename-addon.sh --dry-run ...
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$REPO_ROOT"

FROM_NAME="EsoChat"
FROM_TITLE="ESO Chat"
FROM_ALIAS="EC"
FROM_SLASH="sat"
FROM_SLASH_LONG="esochat"
FROM_REPO="solaegis/eso-chat"
FROM_SETTINGS_SLASH="echsettings"

DRY_RUN=0
NEW_NAME=""
NEW_TITLE=""
NEW_ALIAS=""
NEW_SLASH=""
NEW_REPO=""
NEW_ESOUI_ID=""

usage() {
  cat <<'EOF'
Usage: scripts/rename-addon.sh --name NAME --title "Display Title" --alias ALIAS --slash SLASH --repo owner/repo [--esoui-id N] [--dry-run]

  --name       ESO folder / manifest basename (PascalCase, no spaces), e.g. EsoChat
  --title      In-game / LAM display title, e.g. "ESO Chat"
  --alias      Short Lua alias (2-4 letters), e.g. EC
  --slash      Primary slash without leading slash, e.g. ech  -> /ech
  --repo       GitHub owner/name, e.g. solaegis/eso-chat
  --esoui-id   Optional ESOUI addon id (default: leave workflow value / 0)
  --dry-run    Print planned changes without writing

Example:
  ./scripts/rename-addon.sh --name EsoChat --title "ESO Chat" --alias EC --slash ech --repo solaegis/eso-chat
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NEW_NAME="${2:-}"; shift 2 ;;
    --title) NEW_TITLE="${2:-}"; shift 2 ;;
    --alias) NEW_ALIAS="${2:-}"; shift 2 ;;
    --slash) NEW_SLASH="${2:-}"; shift 2 ;;
    --repo) NEW_REPO="${2:-}"; shift 2 ;;
    --esoui-id) NEW_ESOUI_ID="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

die() { echo "❌ $*" >&2; exit 1; }

[[ -n "$NEW_NAME" ]] || die "--name is required"
[[ -n "$NEW_TITLE" ]] || die "--title is required"
[[ -n "$NEW_ALIAS" ]] || die "--alias is required"
[[ -n "$NEW_SLASH" ]] || die "--slash is required"
[[ -n "$NEW_REPO" ]] || die "--repo is required"

# Strip accidental leading slash from slash args
NEW_SLASH="${NEW_SLASH#/}"
NEW_SLASH="$(printf '%s' "$NEW_SLASH" | tr '[:upper:]' '[:lower:]')"
NEW_SLASH_LONG="$(printf '%s' "$NEW_NAME" | tr '[:upper:]' '[:lower:]')"
NEW_SETTINGS_SLASH="${NEW_SLASH}settings"

[[ "$NEW_NAME" =~ ^[A-Za-z][A-Za-z0-9]*$ ]] || die "--name must be alphanumeric PascalCase (no spaces or /)"
[[ "$NEW_ALIAS" =~ ^[A-Za-z][A-Za-z0-9]*$ ]] || die "--alias must be alphanumeric"
[[ "$NEW_SLASH" =~ ^[a-z][a-z0-9]*$ ]] || die "--slash must be lowercase alphanumeric"
[[ "$NEW_REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die "--repo must look like owner/name"

if [[ "$NEW_NAME" == "$FROM_NAME" ]]; then
  die "--name equals current template name (${FROM_NAME}); nothing to do (or already renamed?)"
fi

# Detect already-renamed tree
if [[ ! -f "${FROM_NAME}.txt" ]]; then
  if [[ -f "${NEW_NAME}.txt" ]]; then
    die "Already renamed to ${NEW_NAME}.txt (no ${FROM_NAME}.txt). Refusing."
  fi
  # Try to find any *.txt manifest that is not README
  existing="$(find . -maxdepth 1 -name '*.txt' ! -name 'README_ESOUI.txt' -print | head -1 || true)"
  if [[ -n "$existing" ]]; then
    die "Template manifest ${FROM_NAME}.txt missing; found ${existing}. Rename may already have run."
  fi
  die "Missing ${FROM_NAME}.txt — run from a template checkout"
fi

if [[ -f "${NEW_NAME}.txt" ]]; then
  die "Target manifest ${NEW_NAME}.txt already exists"
fi

NEW_SV="${NEW_NAME}Settings"
FROM_SV="${FROM_NAME}Settings"

echo "Rebrand plan"
echo "  name:    ${FROM_NAME} -> ${NEW_NAME}"
echo "  title:   ${FROM_TITLE} -> ${NEW_TITLE}"
echo "  alias:   ${FROM_ALIAS} -> ${NEW_ALIAS}"
echo "  slash:   /${FROM_SLASH} -> /${NEW_SLASH} (long: /${NEW_SLASH_LONG})"
echo "  repo:    ${FROM_REPO} -> ${NEW_REPO}"
echo "  SV:      ${FROM_SV} -> ${NEW_SV}"
if [[ -n "$NEW_ESOUI_ID" ]]; then
  echo "  esoui:   ESOUI_ADDON_ID -> ${NEW_ESOUI_ID}"
fi
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "  mode:    DRY-RUN (no writes)"
fi
echo ""

SKIP_DIRS='.git|build|dist|book|.venv|.task|node_modules|__pycache__'

# Collect text files to rewrite (paths relative to repo root)
collect_files() {
  find . \
    \( -path './.git' -o -path './build' -o -path './dist' -o -path './book' -o -path './.venv' -o -path './.task' -o -path './node_modules' \) -prune -o \
    -type f \( \
      -name '*.lua' -o -name '*.txt' -o -name '*.md' -o -name '*.yaml' -o -name '*.yml' -o \
      -name '*.toml' -o -name '*.sh' -o -name '*.rc' -o -name '.luacheckrc' -o -name '.cursorrules' -o \
      -name '.gitignore' -o -name '.build-ignore' -o -name '.pre-commit-config.yaml' \
    \) -print
}

# Apply replacements longest-first via perl for portability
replace_in_file() {
  local file="$1"
  local tmp
  tmp="$(mktemp)"
  # Use {} delimiters so paths like owner/repo do not break s///.
  # Order: Settings before Name; settings slash before slash; long slash before short.
  FROM_SV="$FROM_SV" NEW_SV="$NEW_SV" \
  FROM_NAME="$FROM_NAME" NEW_NAME="$NEW_NAME" \
  FROM_TITLE="$FROM_TITLE" NEW_TITLE="$NEW_TITLE" \
  FROM_REPO="$FROM_REPO" NEW_REPO="$NEW_REPO" \
  FROM_SETTINGS_SLASH="$FROM_SETTINGS_SLASH" NEW_SETTINGS_SLASH="$NEW_SETTINGS_SLASH" \
  FROM_SLASH_LONG="$FROM_SLASH_LONG" NEW_SLASH_LONG="$NEW_SLASH_LONG" \
  FROM_SLASH="$FROM_SLASH" NEW_SLASH="$NEW_SLASH" \
  FROM_ALIAS="$FROM_ALIAS" NEW_ALIAS="$NEW_ALIAS" \
  perl -pe '
    s{\Q$ENV{FROM_SV}\E}{$ENV{NEW_SV}}g;
    s{\Q$ENV{FROM_NAME}\E}{$ENV{NEW_NAME}}g;
    s{\Q$ENV{FROM_TITLE}\E}{$ENV{NEW_TITLE}}g;
    s{\Q$ENV{FROM_REPO}\E}{$ENV{NEW_REPO}}g;
    s{\Q$ENV{FROM_SETTINGS_SLASH}\E}{$ENV{NEW_SETTINGS_SLASH}}g;
    s{\Q$ENV{FROM_SLASH_LONG}\E}{$ENV{NEW_SLASH_LONG}}g;
    s{/$ENV{FROM_SLASH}}{/$ENV{NEW_SLASH}}g;
    s{\Q$ENV{FROM_ALIAS}\E}{$ENV{NEW_ALIAS}}g;
  ' "$file" > "$tmp"

  if [[ -n "$NEW_ESOUI_ID" ]] && [[ "$file" == *"/release.yaml" || "$file" == "./.github/workflows/release.yaml" ]]; then
    NEW_ESOUI_ID="$NEW_ESOUI_ID" perl -pe 's{^(  ESOUI_ADDON_ID: ).*}{$1"$ENV{NEW_ESOUI_ID}"}' "$tmp" > "${tmp}.2"
    mv "${tmp}.2" "$tmp"
  fi

  if ! cmp -s "$file" "$tmp"; then
    echo "  rewrite: $file"
    if [[ "$DRY_RUN" -eq 0 ]]; then
      mv "$tmp" "$file"
    else
      rm -f "$tmp"
    fi
  else
    rm -f "$tmp"
  fi
}

echo "── Content replacements ──"
while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  # Skip this script's own FROM_ constants? Actually we WANT rename script updated
  # so product clones don't keep template names in the helper. Good.
  replace_in_file "$file"
done < <(collect_files | sort)

echo ""
echo "── File rename ──"
echo "  ${FROM_NAME}.txt -> ${NEW_NAME}.txt"
if [[ "$DRY_RUN" -eq 0 ]]; then
  mv "${FROM_NAME}.txt" "${NEW_NAME}.txt"
fi

# Cwd reminder
cwd_base="$(basename "$REPO_ROOT")"
repo_slug="${NEW_REPO##*/}"
if [[ "$cwd_base" != "$NEW_NAME" && "$cwd_base" != "$repo_slug" ]]; then
  echo ""
  echo "ℹ️  Checkout directory is '${cwd_base}'. ESO AddOns folder name comes from ADDON_NAME (${NEW_NAME}), not this path."
  echo "   Consider renaming the git folder to '${repo_slug}' for clarity (optional)."
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo ""
  echo "✅ Dry-run complete (no files written)."
  exit 0
fi

echo ""
echo "── Post-checks ──"
[[ -f "${NEW_NAME}.txt" ]] || die "Missing ${NEW_NAME}.txt after rename"

leftovers="$(grep -R --exclude-dir=.git --exclude-dir=build --exclude-dir=dist \
  -l "EsoChat\|ESO Chat\|solaegis/eso-chat\|/echsettings\|/esochat" \
  . 2>/dev/null || true)"
# Allow leftover "EC" only if alias was EC (shouldn't happen); filter false positives carefully
# Check exact template name leftovers
if echo "$leftovers" | grep -q .; then
  echo "⚠️  Some files still mention template tokens:"
  echo "$leftovers" | sed 's/^/   /'
  echo "   Review manually (docs may intentionally mention the template upstream)."
fi

# Stronger check: template manifest basename must be gone
if grep -R --exclude-dir=.git --exclude-dir=build --exclude-dir=dist -l "EsoChat" . >/dev/null 2>&1; then
  echo "⚠️  'EsoChat' still present in some files — review above."
else
  echo "✅ No remaining 'EsoChat' tokens"
fi

[[ -f "Taskfile.yaml" ]] && grep -q "ADDON_NAME: ${NEW_NAME}" Taskfile.yaml && echo "✅ Taskfile ADDON_NAME=${NEW_NAME}"

echo ""
echo "✅ Rebrand complete: ${NEW_NAME}"
echo "   Next: task lint && task validate"
echo "   Then: task install:live  # and /reloadui"
