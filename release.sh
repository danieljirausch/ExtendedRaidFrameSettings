#!/bin/bash
set -euo pipefail

ADDON_NAME="ExtendedRaidFrameSettings"
OUT="${ADDON_NAME}.zip"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STAGE_DIR=$(mktemp -d)
DEST="${STAGE_DIR}/${ADDON_NAME}"

mkdir -p "$DEST"

cp "$SCRIPT_DIR/${ADDON_NAME}.toc" "$DEST/"
cp "$SCRIPT_DIR/${ADDON_NAME}.xml" "$DEST/"
cp "$SCRIPT_DIR/${ADDON_NAME}.lua" "$DEST/"

(cd "$STAGE_DIR" && zip -r "${SCRIPT_DIR}/${OUT}" "$ADDON_NAME")

rm -rf "$STAGE_DIR"

echo "Created ${OUT}"
