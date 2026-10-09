#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/terminal-icons-tests.XXXXXX")"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

source "$PROJECT_DIR/terminal-icons.sh" >/dev/null

assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    if [[ "$expected" != "$actual" ]]; then
        printf 'FAIL: %s\nExpected: %q\nActual:   %q\n' "$message" "$expected" "$actual" >&2
        exit 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    [[ "$haystack" == *"$needle"* ]] || {
        printf 'FAIL: %s\nMissing: %q\n' "$message" "$needle" >&2
        exit 1
    }
}

hex_to_ansi() {
    local hex="${1^^}"
    printf '\e[38;2;%d;%d;%dm' \
        "$((16#${hex:0:2}))" \
        "$((16#${hex:2:2}))" \
        "$((16#${hex:4:2}))"
}

for key in "${!TI_THEME_FILE_NAME_ICONS[@]}"; do
    assert_eq "${TI_THEME_FILE_NAME_ICONS[$key]}" "$(get_icon "$key")" "file-name icon mapping: $key"
done
for key in "${!TI_THEME_FILE_EXTENSION_ICONS[@]}"; do
    assert_eq "${TI_THEME_FILE_EXTENSION_ICONS[$key]}" "$(get_icon "sample$key")" "file extension icon mapping: $key"
done
for key in "${!TI_THEME_FOLDER_ICONS[@]}"; do
    assert_eq "${TI_THEME_FOLDER_ICONS[$key]}" "$(get_folder_icon "$key")" "folder icon mapping: $key"
done
for key in "${!TI_THEME_FILE_NAME_COLORS[@]}"; do
    assert_eq "$(hex_to_ansi "${TI_THEME_FILE_NAME_COLORS[$key]}")" "$(get_path_color "$key")" "file-name color mapping: $key"
done
for key in "${!TI_THEME_FILE_EXTENSION_COLORS[@]}"; do
    assert_eq "$(hex_to_ansi "${TI_THEME_FILE_EXTENSION_COLORS[$key]}")" "$(get_path_color "sample$key")" "file extension color mapping: $key"
done
for key in "${!TI_THEME_FOLDER_COLORS[@]}"; do
    mkdir -p "$TEST_ROOT/folders/$key"
    assert_eq "$(hex_to_ansi "${TI_THEME_FOLDER_COLORS[$key]}")" "$(get_path_color "$TEST_ROOT/folders/$key")" "folder color mapping: $key"
done

TEST_DIR="$TEST_ROOT/files with spaces"
mkdir -p "$TEST_DIR/nested dir" "$TEST_DIR/.config"
touch "$TEST_DIR/README.md" "$TEST_DIR/archive.tar.gz" "$TEST_DIR/file with spaces.txt" "$TEST_DIR/.hidden"
touch "$TEST_DIR/nested dir/child.txt"
touch "$TEST_DIR/.bashrc"
truncate -s 2048 "$TEST_DIR/2 KiB.bin"
ln -s README.md "$TEST_DIR/file-link"
ln -s "nested dir" "$TEST_DIR/directory-link"
ln -s missing-target "$TEST_DIR/broken-link"

assert_eq "${TI_THEME_FILE_NAME_ICONS[readme.md]}" "$(get_icon "$TEST_DIR/README.md")" 'exact file names take precedence'
assert_eq "${TI_THEME_FILE_EXTENSION_ICONS[.sh]}" "${TI_THEME_FILE_NAME_ICONS[.bashrc]}" '.bashrc uses the shell-script icon'
assert_eq "${TI_THEME_FILE_EXTENSION_COLORS[.sh]}" "${TI_THEME_FILE_NAME_COLORS[.bashrc]}" '.bashrc uses the shell-script color'
assert_eq "${TI_THEME_FILE_NAME_ICONS[.bashrc]}" "$(get_icon "$TEST_DIR/.bashrc")" '.bashrc resolves its special filename icon'
assert_eq "$(hex_to_ansi "${TI_THEME_FILE_NAME_COLORS[.bashrc]}")" "$(get_path_color "$TEST_DIR/.bashrc")" '.bashrc resolves its special filename color'
assert_eq "${TI_THEME_FILE_EXTENSION_ICONS[.gz]}" "$(get_icon "$TEST_DIR/archive.tar.gz")" 'compound extension lookup uses the longest matching suffix'
assert_eq "$TI_THEME_FILE_SYMLINK_ICON" "$(get_icon "$TEST_DIR/file-link")" 'file symlinks use the symlink icon'
assert_eq "$TI_THEME_FOLDER_SYMLINK_ICON" "$(get_folder_icon "$TEST_DIR/directory-link")" 'directory symlinks use the symlink icon'
assert_eq "$(hex_to_ansi "$TI_THEME_FILE_SYMLINK_COLOR")" "$(get_path_color "$TEST_DIR/broken-link")" 'broken symlinks use symlink color'

plain_output="$(ti --no-color "$TEST_DIR/README.md")"
assert_contains "$plain_output" 'README.md' 'single-file listing'
if [[ "$plain_output" == *$'\e['* ]]; then
    printf 'FAIL: --no-color emitted ANSI codes\n' >&2
    exit 1
fi
auto_output="$(ti "$TEST_DIR/README.md")"
if [[ "$auto_output" == *$'\e['* ]]; then
    printf 'FAIL: automatic color mode emitted ANSI codes when output was redirected\n' >&2
    exit 1
fi

color_output="$(ti --color "$TEST_DIR/README.md")"
assert_contains "$color_output" $'\e[38;2;' '--color forces true-color output'
directory_color_output="$(ti --color "$TEST_DIR")"
assert_contains "$directory_color_output" $'\e[38;2;' '--color is applied to directory entries'
assert_contains "$directory_color_output" "$(hex_to_ansi "${TI_THEME_FILE_NAME_COLORS[.bashrc]}")" '--color uses the .bashrc theme color in directory listings'
assert_contains "$directory_color_output" $'\e[0m' 'directory entry colors are reset'
no_color_output="$(NO_COLOR=1 ti "$TEST_DIR/README.md")"
if [[ "$no_color_output" == *$'\e['* ]]; then
    printf 'FAIL: NO_COLOR did not disable automatic colors\n' >&2
    exit 1
fi

long_output="$(ti --no-color -l "$TEST_DIR/2 KiB.bin")"
assert_contains "$long_output" '2.0KiB' 'long listing uses human-readable sizes'
byte_output="$(ti --no-color --bytes "$TEST_DIR/2 KiB.bin")"
assert_contains "$byte_output" '2048' '--bytes displays exact size and implies long mode'
if ti --no-color --unknown-option >/dev/null 2>&1; then
    printf 'FAIL: unknown options should fail\n' >&2
    exit 1
fi

tree_output="$(ti --no-color --tree "$TEST_DIR")"
assert_contains "$tree_output" '├──' 'tree displays branch connectors'
assert_contains "$tree_output" '.hidden' 'tree includes hidden files'
assert_contains "$tree_output" 'nested dir/' 'tree handles spaces and directories'
assert_contains "$tree_output" 'directory-link' 'tree lists directory symlinks'
assert_eq 1 "$(grep -Fc 'child.txt' <<< "$tree_output")" 'tree does not follow directory symlinks'
if [[ "$tree_output" == *'directory-link/'* ]]; then
    printf 'FAIL: tree marked a directory symlink as a traversable directory\n' >&2
    exit 1
fi

COMP_WORDS=(ti --tr)
COMP_CWORD=1
_ti_completion
assert_eq '--tree' "${COMPREPLY[0]}" 'Bash completion suggests CLI options'
COMP_WORDS=(ti "$TEST_DIR/file w")
COMP_CWORD=1
_ti_completion
assert_eq "$TEST_DIR/file with spaces.txt" "${COMPREPLY[0]}" 'Bash completion preserves spaces in paths'
complete -p ti >/dev/null

empty_output="$(ti --no-color --tree "$TEST_DIR/nested dir")"
assert_contains "$empty_output" 'nested dir/' 'tree prints empty root directories'

printf 'PASS: %d icon/color mappings and CLI, tree, size, symlink, and completion checks\n' \
    "$(( ${#TI_THEME_FILE_NAME_ICONS[@]} + ${#TI_THEME_FILE_EXTENSION_ICONS[@]} + ${#TI_THEME_FOLDER_ICONS[@]} + ${#TI_THEME_FILE_NAME_COLORS[@]} + ${#TI_THEME_FILE_EXTENSION_COLORS[@]} + ${#TI_THEME_FOLDER_COLORS[@]} ))"
