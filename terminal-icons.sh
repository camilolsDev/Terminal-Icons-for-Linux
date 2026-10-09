#!/usr/bin/env bash
#
# Terminal-Icons for bash - A bash equivalent of the PowerShell Terminal-Icons module
# Display file and folder icons in the terminal using Nerd Fonts
#
# Requirements:
#   - Nerd Fonts installed (https://github.com/ryanoasis/nerd-fonts)
#   - Terminal that supports Nerd Fonts
#

# Color theme support (ANSI escape codes)
# These constants are available to shells that source this script.
# shellcheck disable=SC2034
COLOR_RESET=$'\e[0m'
COLOR_DEFAULT=$'\e[39m'
COLOR_BLACK=$'\e[30m'
COLOR_RED=$'\e[31m'
COLOR_GREEN=$'\e[32m'
COLOR_YELLOW=$'\e[33m'
COLOR_BLUE=$'\e[34m'
COLOR_MAGENTA=$'\e[35m'
COLOR_CYAN=$'\e[36m'
COLOR_WHITE=$'\e[37m'
COLOR_BOLD=$'\e[1m'
COLOR_DIM=$'\e[2m'

# Load the complete devblackops theme data distributed with this script.
_TERMINAL_ICONS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" || {
    printf 'Error: could not locate the Terminal-Icons installation directory.\n' >&2
    return 1 2>/dev/null || exit 1
}
if [[ ! -r "$_TERMINAL_ICONS_DIR/icon-theme-data.sh" ]]; then
    printf 'Error: missing icon theme data: %s/icon-theme-data.sh\n' "$_TERMINAL_ICONS_DIR" >&2
    return 1 2>/dev/null || exit 1
fi
if ! source "$_TERMINAL_ICONS_DIR/icon-theme-data.sh"; then
    printf 'Error: failed to load the Terminal-Icons theme data.\n' >&2
    return 1 2>/dev/null || exit 1
fi
if [[ ! -r "$_TERMINAL_ICONS_DIR/color-theme-data.sh" ]]; then
    printf 'Error: missing color theme data: %s/color-theme-data.sh\n' "$_TERMINAL_ICONS_DIR" >&2
    return 1 2>/dev/null || exit 1
fi
if ! source "$_TERMINAL_ICONS_DIR/color-theme-data.sh"; then
    printf 'Error: failed to load the Terminal-Icons color theme data.\n' >&2
    return 1 2>/dev/null || exit 1
fi
unset _TERMINAL_ICONS_DIR

# ============================================================================
# Get the appropriate icon for a file/path
# Arguments: $1 = file path or extension
# Returns: The icon glyph (or empty string if no icon found)
# ============================================================================
get_icon() {
    local path="$1"
    local name="${path%/}"
    local remaining suffix
    name="${name##*/}"
    name="${name,,}"

    if [[ -L "$path" ]]; then
        printf '%s\n' "$TI_THEME_FILE_SYMLINK_ICON"
        return 0
    fi

    if [[ -n "${TI_THEME_FILE_NAME_ICONS[$name]+set}" ]]; then
        printf '%s\n' "${TI_THEME_FILE_NAME_ICONS[$name]}"
        return 0
    fi

    remaining="$name"
    while [[ "$remaining" == *.* ]]; do
        remaining="${remaining#*.}"
        suffix=".$remaining"
        if [[ -n "${TI_THEME_FILE_EXTENSION_ICONS[$suffix]+set}" ]]; then
            printf '%s\n' "${TI_THEME_FILE_EXTENSION_ICONS[$suffix]}"
            return 0
        fi
    done

    printf '%s\n' "$TI_THEME_FILE_DEFAULT_ICON"
}

# ============================================================================
# Get the appropriate icon for a folder
# Arguments: $1 = path
# Returns: The folder icon glyph
# ============================================================================
get_folder_icon() {
    local path="$1"
    local name="${path%/}"
    name="${name##*/}"
    name="${name,,}"

    if [[ -L "$path" ]]; then
        printf '%s\n' "$TI_THEME_FOLDER_SYMLINK_ICON"
    elif [[ -n "${TI_THEME_FOLDER_ICONS[$name]+set}" ]]; then
        printf '%s\n' "${TI_THEME_FOLDER_ICONS[$name]}"
    else
        printf '%s\n' "$TI_THEME_FOLDER_DEFAULT_ICON"
    fi
}

# Return the upstream theme's foreground color for a file or directory.
get_path_color() {
    local path="$1"
    local name="${path%/}"
    local remaining suffix hex
    name="${name##*/}"
    name="${name,,}"

    if [[ -L "$path" ]]; then
        if [[ -d "$path" ]]; then
            hex="$TI_THEME_FOLDER_SYMLINK_COLOR"
        else
            hex="$TI_THEME_FILE_SYMLINK_COLOR"
        fi
    elif [[ -d "$path" ]]; then
        hex="${TI_THEME_FOLDER_COLORS[$name]-}"
    else
        hex="${TI_THEME_FILE_NAME_COLORS[$name]-}"
        if [[ -z "$hex" ]]; then
            remaining="$name"
            while [[ "$remaining" == *.* ]]; do
                remaining="${remaining#*.}"
                suffix=".$remaining"
                if [[ -n "${TI_THEME_FILE_EXTENSION_COLORS[$suffix]+set}" ]]; then
                    hex="${TI_THEME_FILE_EXTENSION_COLORS[$suffix]}"
                    break
                fi
            done
        fi
    fi

    if [[ "$hex" =~ ^[[:xdigit:]]{6}$ ]]; then
        printf '\e[38;2;%d;%d;%dm' \
            "$((16#${hex:0:2}))" \
            "$((16#${hex:2:2}))" \
            "$((16#${hex:4:2}))"
    else
        printf '%s' "$COLOR_DEFAULT"
    fi
}

format_file_size() {
    local size="$1"
    local bytes="${2:-false}"
    if [[ "$bytes" == true ]]; then
        printf '%s' "$size"
    elif command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec-i --suffix=B "$size"
    else
        printf 'Error: numfmt is required for human-readable sizes.\n' >&2
        return 1
    fi
}

_ti_list_children() {
    local destination="$1"
    local path="$2"
    # This nameref fills the caller's array.
    # shellcheck disable=SC2034
    local -n children_ref="$destination"
    local restore_nullglob=false
    local restore_dotglob=false
    shopt -q nullglob && restore_nullglob=true
    shopt -q dotglob && restore_dotglob=true
    shopt -s nullglob dotglob
    children_ref=("$path"/*)
    [[ "$restore_nullglob" == true ]] || shopt -u nullglob
    [[ "$restore_dotglob" == true ]] || shopt -u dotglob
}

# ============================================================================
# Format a file path with its icon
# Arguments: $1 = file path
# Output: Icon + filename with appropriate coloring
# ============================================================================
format_path() {
    local path="$1"
    local name
    name=$(basename "$path")
    local is_dir=false

    if [[ -d "$path" ]]; then
        is_dir=true
    fi

    local icon=""
    local color

    if $is_dir; then
        icon=$(get_folder_icon "$path")
    else
        icon=$(get_icon "$path")
    fi
    if [[ "${TI_COLOR_ENABLED:-false}" == true ]]; then
        color=$(get_path_color "$path")
    else
        color=""
    fi

    if [[ -n "$icon" ]]; then
        printf "%s%s  %s%s" "$color" "$icon" "$name" "${color:+$COLOR_RESET}"
    else
        printf "%s%s%s" "$color" "$name" "${color:+$COLOR_RESET}"
    fi
}

# Print file metadata followed by its icon and name.
format_long_path() {
    local path="$1"
    local show_bytes="${2:-false}"
    local metadata permissions owner group size modified formatted_size

    if ! metadata=$(stat --printf='%A\t%U\t%G\t%s\t%Y' -- "$path"); then
        printf "Error: could not read metadata for '%s'\n" "$path" >&2
        return 1
    fi

    IFS=$'\t' read -r permissions owner group size modified <<< "$metadata"
    if ! formatted_size=$(format_file_size "$size" "$show_bytes"); then
        return 1
    fi
    if ! modified=$(date -d "@$modified" '+%Y-%m-%d %H:%M:%S %z'); then
        printf "Error: could not format modification time for '%s'\n" "$path" >&2
        return 1
    fi
    printf "  %-10s %-10s %-10s %10s %-32s " "$permissions" "$owner" "$group" "$formatted_size" "$modified"
    format_path "$path"
    printf '\n'
}

_ti_print_tree_node() {
    local path="$1"
    local prefix="$2"
    local is_last="$3"
    local show_long="$4"
    local show_bytes="$5"
    local is_root="$6"
    local branch=""
    local child_prefix="$prefix"
    local index
    local -a children=()
    if [[ "$is_root" != true ]]; then
        if [[ "$is_last" == true ]]; then
            branch="└── "
            child_prefix+="    "
        else
            branch="├── "
            child_prefix+="│   "
        fi
    fi

    printf '%s%s' "$prefix" "$branch"
    if [[ "$show_long" == true ]]; then
        format_long_path "$path" "$show_bytes" || return 1
    else
        format_path "$path"
        [[ -d "$path" && ! -L "$path" ]] && printf '/'
        printf '\n'
    fi

    [[ -d "$path" && ! -L "$path" ]] || return 0
    _ti_list_children children "$path" || return 1

    for (( index=0; index<${#children[@]}; index++ )); do
        if (( index == ${#children[@]} - 1 )); then
            _ti_print_tree_node "${children[index]}" "$child_prefix" true "$show_long" "$show_bytes" false || return 1
        else
            _ti_print_tree_node "${children[index]}" "$child_prefix" false "$show_long" "$show_bytes" false || return 1
        fi
    done
}

# ============================================================================
# Main terminal-icons command
# Usage: ti [-l|--long] [--bytes] [--tree] [--color|--no-color] [path]
# ============================================================================
ti() {
    local long_format=false
    local tree_format=false
    local show_bytes=false
    local color_mode=auto
    local target="."
    local positional=()
    local arg
    local TI_COLOR_ENABLED=false

    while (( $# )); do
        arg="$1"
        shift
        case "$arg" in
            -l|--long) long_format=true ;;
            --bytes) long_format=true; show_bytes=true ;;
            --tree) tree_format=true ;;
            --color) color_mode=always ;;
            --no-color) color_mode=never ;;
            -h|--help)
                printf 'Usage: ti [-l|--long] [--bytes] [--tree] [--color|--no-color] [path]\n'
                printf '  -l, --long  Show permissions, owner, group, size, and modified time\n'
                printf '  --bytes     Show exact byte sizes (implies --long)\n'
                printf '  --tree      Show a recursive directory tree\n'
                printf '  --color     Force color output\n'
                printf '  --no-color  Disable color output\n'
                printf 'Colors are automatic in terminals; NO_COLOR disables them by default.\n'
                return 0
                ;;
            --)
                positional+=("$@")
                break
                ;;
            -*)
                printf "Error: unknown option '%s'\n" "$arg" >&2
                return 2
                ;;
            *) positional+=("$arg") ;;
        esac
    done

    if (( ${#positional[@]} > 1 )); then
        printf 'Usage: ti [-l|--long] [--bytes] [--tree] [--color|--no-color] [path]\n' >&2
        return 2
    fi
    if (( ${#positional[@]} == 1 )); then
        target="${positional[0]}"
    fi

    case "$color_mode" in
        always) TI_COLOR_ENABLED=true ;;
        never) TI_COLOR_ENABLED=false ;;
        auto)
            if [[ -t 1 && "${TERM:-dumb}" != dumb && -z "${NO_COLOR:-}" ]]; then
                TI_COLOR_ENABLED=true
            fi
            ;;
    esac

    if [[ ! -e "$target" && ! -L "$target" ]]; then
        echo "Error: '$target' does not exist" >&2
        return 1
    fi

    if [[ -f "$target" ]] || [[ -L "$target" ]]; then
        if $long_format; then
            format_long_path "$target" "$show_bytes"
            return $?
        fi
        format_path "$target"
        echo ""
    elif [[ -d "$target" ]]; then
        if [[ "$tree_format" == true ]]; then
            _ti_print_tree_node "$target" "" true "$long_format" "$show_bytes" true
            return $?
        fi

        local found=false
        local full_path
        local -a children=()
        _ti_list_children children "$target" || return 1

        if [[ "$long_format" == true && ${#children[@]} -gt 0 ]]; then
            if [[ "$show_bytes" == true ]]; then
                printf '  %-10s %-10s %-10s %10s %-32s %s\n' "Permissions" "Owner" "Group" "Bytes" "Modified" "Name"
            else
                printf '  %-10s %-10s %-10s %10s %-32s %s\n' "Permissions" "Owner" "Group" "Size" "Modified" "Name"
            fi
        fi

        for full_path in "${children[@]}"; do
            [[ -e "$full_path" || -L "$full_path" ]] || continue
            found=true

            if $long_format; then
                format_long_path "$full_path" "$show_bytes" || return 1
            else
                printf '  '
                format_path "$full_path"
                [[ -d "$full_path" ]] && printf '/'
                printf '\n'
            fi
        done

        if [[ "$found" == false ]]; then
            echo " (empty)"
        fi
    fi
}

_ti_completion() {
    local current="${COMP_WORDS[COMP_CWORD]}"
    local -a options=(--long --bytes --tree --color --no-color --help)

    if [[ "$current" == -* ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${options[*]}" -- "$current")
    else
        mapfile -t COMPREPLY < <(compgen -f -- "$current")
    fi
}
complete -F _ti_completion ti

# ============================================================================
# Output initialization message
echo "Terminal-Icons for bash loaded (devblackops icon theme)."
echo "Run 'ti' to show icons for a path."

# Export functions
export -f get_icon get_folder_icon get_path_color format_file_size format_path format_long_path _ti_list_children _ti_print_tree_node ti _ti_completion