#!/usr/bin/env bash

set -euo pipefail

DEFAULT_REPO="slaterbe/battle-lines-unity"
DEFAULT_DEST_DIR="${HOME}/Downloads/battle-lines"
ASSET_PATTERN="${ASSET_PATTERN:-steam-deck}"

usage() {
  cat <<'EOF'
Usage:
  steam-deck-installer.sh [tag]

Examples:
  steam-deck-installer.sh
  steam-deck-installer.sh v0.1.0

Environment variables:
  GITHUB_REPOSITORY   Override the GitHub repo slug. Default: slaterbe/battle-lines-unity
  DEST_DIR            Override the install folder. Default: ~/Downloads/battle-lines
  ASSET_PATTERN       Match a different asset name fragment. Default: steam-deck

What it does:
  - Downloads the latest release by default, or a specific tag if provided
  - Finds a zip asset whose name contains the asset pattern
  - Extracts it into DEST_DIR/<tag>/
  - Marks any *.x86_64 files as executable
  - Starts the downloaded build automatically
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

for required_command in curl unzip python3 find chmod; do
  if ! command -v "${required_command}" >/dev/null 2>&1; then
    echo "Error: ${required_command} is required." >&2
    exit 1
  fi
done

REPOSITORY="${GITHUB_REPOSITORY:-$DEFAULT_REPO}"
DEST_DIR="${DEST_DIR:-$DEFAULT_DEST_DIR}"
TAG="${1:-}"

if [[ -z "${TAG}" ]]; then
  API_URL="https://api.github.com/repos/${REPOSITORY}/releases/latest"
else
  API_URL="https://api.github.com/repos/${REPOSITORY}/releases/tags/${TAG}"
fi

echo "Fetching release metadata from ${REPOSITORY}"
RELEASE_JSON="$(curl -fsSL -H "Accept: application/vnd.github+json" "${API_URL}")"

PARSED_RELEASE="$(
  RELEASE_JSON="${RELEASE_JSON}" ASSET_PATTERN="${ASSET_PATTERN}" python3 - <<'PY'
import json
import os
import sys

release = json.loads(os.environ["RELEASE_JSON"])
pattern = os.environ["ASSET_PATTERN"].lower()
tag = release.get("tag_name", "")

for asset in release.get("assets", []):
    name = asset.get("name", "")
    url = asset.get("browser_download_url", "")
    if name.lower().endswith(".zip") and pattern in name.lower():
        print(tag)
        print(name)
        print(url)
        sys.exit(0)

print("No matching zip asset found in the selected release.", file=sys.stderr)
sys.exit(1)
PY
)"

TAG_NAME="$(printf '%s\n' "${PARSED_RELEASE}" | sed -n '1p')"
ASSET_NAME="$(printf '%s\n' "${PARSED_RELEASE}" | sed -n '2p')"
DOWNLOAD_URL="$(printf '%s\n' "${PARSED_RELEASE}" | sed -n '3p')"

TARGET_DIR="${DEST_DIR}/${TAG_NAME}"
ZIP_PATH="${TARGET_DIR}/${ASSET_NAME}"

mkdir -p "${TARGET_DIR}"

echo "Downloading ${ASSET_NAME}"
curl -fL "${DOWNLOAD_URL}" -o "${ZIP_PATH}"

echo "Extracting into ${TARGET_DIR}"
unzip -o "${ZIP_PATH}" -d "${TARGET_DIR}" >/dev/null

echo "Setting executable permission on Linux binaries"
find "${TARGET_DIR}" -type f -name "*.x86_64" -exec chmod +x {} \;

mapfile -t EXECUTABLES < <(find "${TARGET_DIR}" -type f -name "*.x86_64" | sort)

if [[ ${#EXECUTABLES[@]} -eq 0 ]]; then
  echo "Error: no Linux executable (*.x86_64) was found in ${TARGET_DIR}." >&2
  exit 1
fi

LAUNCH_PATH=""

for executable in "${EXECUTABLES[@]}"; do
  if [[ "$(basename "${executable}")" == "steam-deck.x86_64" ]]; then
    LAUNCH_PATH="${executable}"
    break
  fi
done

if [[ -z "${LAUNCH_PATH}" ]]; then
  LAUNCH_PATH="${EXECUTABLES[0]}"
fi

echo
echo "Install complete."
echo "Files are in: ${TARGET_DIR}"
echo
echo "Starting: ${LAUNCH_PATH}"

cd "$(dirname "${LAUNCH_PATH}")"
exec "./$(basename "${LAUNCH_PATH}")"
