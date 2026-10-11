#!/usr/bin/env bash
#
# Terminal-Icons Linux Installer
# Install Terminal-Icons for bash on Ubuntu/Debian
#

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    printf 'Usage: bash install.sh [--uninstall]\n'
}

configure_paths() {
    if [[ -z "${HOME:-}" || "$HOME" != /* ]]; then
        printf 'Error: HOME must be set to an absolute path.\n' >&2
        return 1
    fi

    local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
    if [[ "$data_home" != /* ]]; then
        printf 'Error: XDG_DATA_HOME must be an absolute path.\n' >&2
        return 1
    fi

    SHELL_RC="$HOME/.bashrc"
    INSTALL_DIR="$data_home/terminal-icons"
}

uninstall() {
    local source_line="source \"$INSTALL_DIR/terminal-icons.sh\""
    local source_unquoted="source $INSTALL_DIR/terminal-icons.sh"
    local temp_file

    if [[ -f "$SHELL_RC" ]]; then
        temp_file=$(mktemp "$HOME/.bashrc.terminal-icons.XXXXXX") || {
            printf 'Error: could not create a temporary Bash configuration file.\n' >&2
            return 1
        }
        if ! awk -v quoted="$source_line" -v unquoted="$source_unquoted" '
            $0 == quoted || $0 == unquoted { previous = ""; next }
            previous != "" { print previous }
            { previous = $0 }
            END { if (previous != "") print previous }
        ' "$SHELL_RC" > "$temp_file"; then
            rm -f -- "$temp_file"
            printf 'Error: could not update %s.\n' "$SHELL_RC" >&2
            return 1
        fi
        if ! chmod --reference="$SHELL_RC" "$temp_file" || ! mv -- "$temp_file" "$SHELL_RC"; then
            rm -f -- "$temp_file"
            printf 'Error: could not update %s.\n' "$SHELL_RC" >&2
            return 1
        fi
    fi

    rm -f -- \
        "$INSTALL_DIR/terminal-icons.sh" \
        "$INSTALL_DIR/icon-theme-data.sh" \
        "$INSTALL_DIR/color-theme-data.sh" \
        "$INSTALL_DIR/LICENSE" \
        "$INSTALL_DIR/THIRD-PARTY-LICENSES.md" \
        "$INSTALL_DIR/README.md"
    if [[ -d "$INSTALL_DIR" ]] && ! rmdir -- "$INSTALL_DIR" 2>/dev/null; then
        printf 'Removed Terminal-Icons files; kept non-empty directory %s.\n' "$INSTALL_DIR"
    fi
    printf 'Terminal-Icons uninstalled.\n'
}

case "${1:-}" in
    --uninstall)
        (( $# == 1 )) || { usage >&2; exit 2; }
        configure_paths
        uninstall
        exit
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    "")
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

configure_paths

echo "========================================="
echo "Terminal-Icons for Linux Installer"
echo "========================================="

if [[ "${SHELL##*/}" == "zsh" ]]; then
    echo "Error: Terminal-Icons currently supports Bash only." >&2
    exit 1
fi

mkdir -p "$INSTALL_DIR"

# Copy script files
echo "Installing Terminal-Icons script..."
cp "$SCRIPT_DIR/terminal-icons.sh" "$INSTALL_DIR/terminal-icons.sh"
cp "$SCRIPT_DIR/icon-theme-data.sh" "$INSTALL_DIR/icon-theme-data.sh"
cp "$SCRIPT_DIR/color-theme-data.sh" "$INSTALL_DIR/color-theme-data.sh"
cp "$SCRIPT_DIR/LICENSE" "$INSTALL_DIR/LICENSE"
cp "$SCRIPT_DIR/THIRD-PARTY-LICENSES.md" "$INSTALL_DIR/THIRD-PARTY-LICENSES.md"
cp "$SCRIPT_DIR"/README.md "$INSTALL_DIR/README.md"

# Add sourcing to shell config
touch "$SHELL_RC"
if grep -Fq "source \"$INSTALL_DIR/terminal-icons.sh\"" "$SHELL_RC" ||
    grep -Fq "source $INSTALL_DIR/terminal-icons.sh" "$SHELL_RC"; then
    echo "Terminal-Icons already configured in $SHELL_RC"
else
    printf '\n# Terminal-Icons - File and folder icons in terminal\nsource "%s/terminal-icons.sh"\n' "$INSTALL_DIR" >> "$SHELL_RC"
    echo "Added Terminal-Icons to $SHELL_RC"
fi

echo ""
echo "========================================="
echo "Installation complete!"
echo "========================================="
echo ""
echo "To start using Terminal-Icons:"
echo "  1. Load it in this terminal:"
echo "     source \"$INSTALL_DIR/terminal-icons.sh\""
echo ""
echo "  2. Try the 'ti' command:"
echo "     ti"
echo ""
echo "  3. Requirements:"
echo "     - Install Nerd Fonts: https://github.com/ryanoasis/nerd-fonts"
echo "     - Ensure your terminal supports Nerd Fonts"
echo ""
echo "For more information, see: $INSTALL_DIR/README.md"