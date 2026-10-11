#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d "${TMPDIR:-/tmp}/terminal-icons-installer.XXXXXX")"
trap 'rm -rf -- "$TEST_HOME"' EXIT

help_output="$(bash "$PROJECT_DIR/install.sh" --help)"
[[ "$help_output" == *'Usage: bash install.sh [--uninstall]'* ]]
if bash "$PROJECT_DIR/install.sh" --invalid >/dev/null 2>&1; then
    printf 'FAIL: installer should reject unknown options\n' >&2
    exit 1
fi
if HOME="$TEST_HOME" SHELL=/bin/zsh bash "$PROJECT_DIR/install.sh" >/dev/null 2>&1; then
    printf 'FAIL: installer should reject unsupported shells\n' >&2
    exit 1
fi

INSTALL_DIR="$TEST_HOME/.local/share/terminal-icons"
mkdir -p "$INSTALL_DIR"
printf 'keep this file\n' > "$INSTALL_DIR/user-file"
printf 'export TEST_BEFORE=1\n' > "$TEST_HOME/.bashrc"

HOME="$TEST_HOME" SHELL=/bin/bash bash "$PROJECT_DIR/install.sh" >/dev/null
HOME="$TEST_HOME" SHELL=/bin/bash bash "$PROJECT_DIR/install.sh" >/dev/null

source_line="source \"$INSTALL_DIR/terminal-icons.sh\""
source_count="$(grep -Fxc "$source_line" "$TEST_HOME/.bashrc")"
[[ "$source_count" == 1 ]] || {
    printf 'FAIL: expected one Bash startup entry after repeated installs, found %s\n' "$source_count" >&2
    exit 1
}

for filename in terminal-icons.sh icon-theme-data.sh color-theme-data.sh LICENSE THIRD-PARTY-LICENSES.md README.md; do
    [[ -s "$INSTALL_DIR/$filename" ]] || {
        printf 'FAIL: installer did not install %s\n' "$filename" >&2
        exit 1
    }
done
cmp -s "$PROJECT_DIR/terminal-icons.sh" "$INSTALL_DIR/terminal-icons.sh"
cmp -s "$PROJECT_DIR/LICENSE" "$INSTALL_DIR/LICENSE"
installed_command="$(HOME="$TEST_HOME" bash --noprofile --norc -c 'source "$HOME/.local/share/terminal-icons/terminal-icons.sh" >/dev/null; type -t ti')"
[[ "$installed_command" == function ]] || {
    printf 'FAIL: installed script did not register the ti function\n' >&2
    exit 1
}

if [[ "$(id -u)" != 0 ]]; then
    readonly_home="$TEST_HOME/read-only-home"
    mkdir "$readonly_home"
    chmod 500 "$readonly_home"
    if install_error="$(HOME="$readonly_home" SHELL=/bin/bash bash "$PROJECT_DIR/install.sh" 2>&1)"; then
        chmod 700 "$readonly_home"
        printf 'FAIL: installer should fail when HOME is not writable\n' >&2
        exit 1
    fi
    chmod 700 "$readonly_home"
    [[ "$install_error" == *'Permission denied'* ]] || {
        printf 'FAIL: installer did not report the read-only HOME error\n%s\n' "$install_error" >&2
        exit 1
    }
    [[ ! -e "$readonly_home/.local/share/terminal-icons" && ! -e "$readonly_home/.bashrc" ]] || {
        printf 'FAIL: installer modified a read-only HOME\n' >&2
        exit 1
    }
fi

HOME="$TEST_HOME" SHELL=/bin/bash bash "$PROJECT_DIR/install.sh" --uninstall >/dev/null
if grep -Fq "$source_line" "$TEST_HOME/.bashrc"; then
    printf 'FAIL: uninstaller left its Bash source entry behind\n' >&2
    exit 1
fi
if grep -Fq '# Terminal-Icons - File and folder icons in terminal' "$TEST_HOME/.bashrc"; then
    printf 'FAIL: uninstaller left its Bash configuration comment behind\n' >&2
    exit 1
fi
grep -Fq 'export TEST_BEFORE=1' "$TEST_HOME/.bashrc"
for filename in terminal-icons.sh icon-theme-data.sh color-theme-data.sh LICENSE THIRD-PARTY-LICENSES.md README.md; do
    [[ ! -e "$INSTALL_DIR/$filename" ]] || {
        printf 'FAIL: uninstaller left behind %s\n' "$filename" >&2
        exit 1
    }
done
[[ -f "$INSTALL_DIR/user-file" ]] || {
    printf 'FAIL: uninstall deleted an unrelated user file\n' >&2
    exit 1
}
[[ -d "$INSTALL_DIR" ]] || {
    printf 'FAIL: uninstall removed a non-empty user directory\n' >&2
    exit 1
}

custom_home="$TEST_HOME/custom home"
custom_data_home="$TEST_HOME/custom data"
mkdir -p "$custom_home"
HOME="$custom_home" XDG_DATA_HOME="$custom_data_home" SHELL=/bin/bash \
    bash "$PROJECT_DIR/install.sh" >/dev/null
custom_install_dir="$custom_data_home/terminal-icons"
custom_source_line="source \"$custom_install_dir/terminal-icons.sh\""
grep -Fqx "$custom_source_line" "$custom_home/.bashrc" || {
    printf 'FAIL: installer did not use XDG_DATA_HOME in the Bash startup entry\n' >&2
    exit 1
}
[[ -s "$custom_install_dir/terminal-icons.sh" ]] || {
    printf 'FAIL: installer did not install files under XDG_DATA_HOME\n' >&2
    exit 1
}
HOME="$custom_home" XDG_DATA_HOME="$custom_data_home" \
    bash "$PROJECT_DIR/install.sh" --uninstall >/dev/null
[[ ! -e "$custom_install_dir/terminal-icons.sh" ]] || {
    printf 'FAIL: uninstaller did not use XDG_DATA_HOME\n' >&2
    exit 1
}
if grep -Fq "$custom_source_line" "$custom_home/.bashrc"; then
    printf 'FAIL: uninstaller left behind the custom HOME Bash source entry\n' >&2
    exit 1
fi

if HOME="$TEST_HOME/invalid-xdg-home" XDG_DATA_HOME=relative/path SHELL=/bin/bash \
    bash "$PROJECT_DIR/install.sh" >/dev/null 2>&1; then
    printf 'FAIL: installer should reject a relative XDG_DATA_HOME\n' >&2
    exit 1
fi

printf 'PASS: installer updates idempotently and uninstalls without deleting unrelated files\n'
