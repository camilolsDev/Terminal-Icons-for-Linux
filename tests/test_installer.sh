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

mkdir -p "$TEST_HOME/terminal-icons"
printf 'keep this file\n' > "$TEST_HOME/terminal-icons/user-file"
printf 'export TEST_BEFORE=1\n' > "$TEST_HOME/.bashrc"

HOME="$TEST_HOME" SHELL=/bin/bash bash "$PROJECT_DIR/install.sh" >/dev/null
HOME="$TEST_HOME" SHELL=/bin/bash bash "$PROJECT_DIR/install.sh" >/dev/null

source_line="source \"$TEST_HOME/terminal-icons/terminal-icons.sh\""
source_count="$(grep -Fxc "$source_line" "$TEST_HOME/.bashrc")"
[[ "$source_count" == 1 ]] || {
    printf 'FAIL: expected one Bash startup entry after repeated installs, found %s\n' "$source_count" >&2
    exit 1
}

for filename in terminal-icons.sh icon-theme-data.sh color-theme-data.sh LICENSE THIRD-PARTY-LICENSES.md README.md; do
    [[ -s "$TEST_HOME/terminal-icons/$filename" ]] || {
        printf 'FAIL: installer did not install %s\n' "$filename" >&2
        exit 1
    }
done
cmp -s "$PROJECT_DIR/terminal-icons.sh" "$TEST_HOME/terminal-icons/terminal-icons.sh"
cmp -s "$PROJECT_DIR/LICENSE" "$TEST_HOME/terminal-icons/LICENSE"
installed_command="$(HOME="$TEST_HOME" bash --noprofile --norc -c 'source "$HOME/terminal-icons/terminal-icons.sh" >/dev/null; type -t ti')"
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
    [[ ! -e "$readonly_home/terminal-icons" && ! -e "$readonly_home/.bashrc" ]] || {
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
    [[ ! -e "$TEST_HOME/terminal-icons/$filename" ]] || {
        printf 'FAIL: uninstaller left behind %s\n' "$filename" >&2
        exit 1
    }
done
[[ -f "$TEST_HOME/terminal-icons/user-file" ]] || {
    printf 'FAIL: uninstall deleted an unrelated user file\n' >&2
    exit 1
}
[[ -d "$TEST_HOME/terminal-icons" ]] || {
    printf 'FAIL: uninstall removed a non-empty user directory\n' >&2
    exit 1
}

printf 'PASS: installer updates idempotently and uninstalls without deleting unrelated files\n'
