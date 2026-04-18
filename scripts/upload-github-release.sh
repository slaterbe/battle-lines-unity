#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${REPO_ROOT}/steam-deck-build"
DEFAULT_REPO="slaterbe/battle-lines-unity"

usage() {
  cat <<'EOF'
Usage:
  scripts/upload-github-release.sh <tag> [notes]

Examples:
  scripts/upload-github-release.sh v0.1.0
  scripts/upload-github-release.sh v0.1.0 "Steam Deck build"

Environment variables:
  GITHUB_REPOSITORY   Override the GitHub repo slug. Default: slaterbe/battle-lines-unity
  RELEASE_TITLE       Override the release title. Default: <tag>
  ASSET_NAME          Override the uploaded zip name. Default: battle-lines-steam-deck-<tag>.zip

Requirements:
  - GitHub CLI (`gh`) must be installed and authenticated.
  - The Steam Deck build must exist in steam-deck-build/
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: GitHub CLI 'gh' is not installed or not on PATH." >&2
  exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "Error: 'zip' is not installed or not on PATH." >&2
  exit 1
fi

if [[ ! -d "${BUILD_DIR}" ]]; then
  echo "Error: Steam Deck build folder not found at ${BUILD_DIR}" >&2
  exit 1
fi

TAG="$1"
NOTES="${2:-Steam Deck build for ${TAG}}"
REPOSITORY="${GITHUB_REPOSITORY:-$DEFAULT_REPO}"
RELEASE_TITLE="${RELEASE_TITLE:-$TAG}"
ASSET_NAME="${ASSET_NAME:-battle-lines-steam-deck-${TAG}.zip}"
TEMP_DIR="$(mktemp -d)"
ZIP_PATH="${TEMP_DIR}/${ASSET_NAME}"

cleanup() {
  rm -rf "${TEMP_DIR}"
}

trap cleanup EXIT

echo "Packaging ${BUILD_DIR} into ${ZIP_PATH}"
(
  cd "${REPO_ROOT}"
  zip -r "${ZIP_PATH}" "$(basename "${BUILD_DIR}")" >/dev/null
)

if gh release view "${TAG}" --repo "${REPOSITORY}" >/dev/null 2>&1; then
  echo "Release ${TAG} already exists in ${REPOSITORY}"
else
  echo "Creating release ${TAG} in ${REPOSITORY}"
  gh release create "${TAG}" \
    --repo "${REPOSITORY}" \
    --title "${RELEASE_TITLE}" \
    --notes "${NOTES}"
fi

echo "Uploading asset ${ASSET_NAME}"
gh release upload "${TAG}" "${ZIP_PATH}" \
  --repo "${REPOSITORY}" \
  --clobber

echo "Done. Uploaded ${ASSET_NAME} to ${REPOSITORY} release ${TAG}."
