#!/usr/bin/env bash
# Symlink this repo into the live ESO AddOns folder for /reloadui iteration.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADDON_NAME="EsoChat"
ESO_ADDONS="${ESO_LIVE_ADDONS:-$HOME/Documents/Elder Scrolls Online/live/AddOns}"
TARGET="${ESO_ADDONS}/${ADDON_NAME}"

mkdir -p "${ESO_ADDONS}"

if [[ -L "${TARGET}" ]]; then
  rm "${TARGET}"
elif [[ -e "${TARGET}" ]]; then
  echo "Refusing to overwrite non-symlink path: ${TARGET}" >&2
  exit 1
fi

ln -s "${REPO_ROOT}" "${TARGET}"
echo "Linked ${TARGET} -> ${REPO_ROOT}"
echo "Enable '${ADDON_NAME}' in the in-game Addons menu, then /reloadui"
