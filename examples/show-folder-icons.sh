#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
GALLERY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/terminal-icons-folders.XXXXXX")"
trap 'rm -rf -- "$GALLERY_DIR"' EXIT

source "$PROJECT_DIR/icon-theme-data.sh"
for folder_name in "${!TI_THEME_FOLDER_ICONS[@]}"; do
    mkdir -- "$GALLERY_DIR/$folder_name"
done
mkdir -- "$GALLERY_DIR/misc-folder"
ln -s docs "$GALLERY_DIR/linked-folder"

source "$PROJECT_DIR/terminal-icons.sh" >/dev/null
ti --color "$GALLERY_DIR"
