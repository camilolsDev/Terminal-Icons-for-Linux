# Terminal-Icons for Linux

A Bash equivalent of the [devblackops/terminal-icons](https://github.com/devblackops/terminal-icons)
PowerShell module, Terminal-Icons for Linux displays file and folder icons
using [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts). It installs its
scripts and icon and color theme data in `~/terminal-icons/`, adds the loader
to `~/.bashrc`, and provides the `ti` command for long listings (`-l`) and
tree views (`--tree`), with color controls.

## Installation

```bash
# From the project directory:
bash install.sh
# Run it again at any time to update the installed files.

# Load it in the current terminal (new Bash terminals load it automatically):
source ~/terminal-icons/terminal-icons.sh

# Remove Terminal-Icons and its Bash startup entry:
bash install.sh --uninstall
```

Terminal-Icons currently supports Bash. The installer copies the script and
the complete icon and color theme data to `~/terminal-icons/`, then adds it
to `~/.bashrc`. This startup file is read by interactive Bash shells; users
whose terminal starts a login Bash that does not read `~/.bashrc` can add
`source "$HOME/terminal-icons/terminal-icons.sh"` to the startup file used by
their terminal.

### Install a specific release

Replace `vX.Y.Z` with the version you want from the project's GitHub Releases:

```bash
git clone --depth 1 --branch vX.Y.Z \
  https://github.com/camilolsDev/Terminal-Icons-for-Linux.git
cd Terminal-Icons-for-Linux
bash install.sh
```

To update this clone to a newer release and install it, run:

```bash
git fetch --depth 1 origin tag vX.Y.Z
git checkout --detach vX.Y.Z
bash install.sh
```

To uninstall, run `bash install.sh --uninstall` from any clone of the project.

## Usage

```bash
# Show icons for current directory
ti

# Show icons for a specific path
ti /home/user/docs

# Show permissions, owner, group, size, and modified time
ti --long
ti -l /home/user/docs

# Show exact sizes in bytes
ti --bytes /home/user/docs

# Show a recursive directory tree
ti --tree
ti --tree /home/user/docs

# Control color output (automatic by default in interactive terminals)
ti --color
ti --no-color
```

By default, colors are enabled only for interactive terminals. Set `NO_COLOR=1`
to disable automatic colors; `--color` explicitly forces color, while
`--no-color` disables it for that invocation. Long listings use human-readable
binary units (for example, `2.0KiB`); `--bytes` shows exact byte counts.

## Optional `ls` and `ll` aliases

`ti` does not replace `ls` automatically. To make `ls` show icons and `ll`
show the detailed listing, add these aliases to `~/.bashrc` after the
Terminal-Icons `source` line:

```bash
alias ls='ti --color'
alias ll='ti --color -l'
```

Apply the changes to the current terminal with:

```bash
source ~/.bashrc
```

These aliases force the Terminal-Icons theme colors and route commands to
`ti`; they do not preserve all GNU `ls` options. `ll` runs the colored `ti -l`
format. To restore the normal `ls` command for the current terminal, run
`unalias ls ll`.

## Requirements

- Bash 4.3 or newer
- GNU coreutils (`stat`, `date`, and `numfmt`)
- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) installed
- Terminal supporting Nerd Fonts (Alacritty, Kitty, foot, GNOME Terminal with patched font, etc.)

## Features

- **File type icons** - Maps common extensions to Nerd Font glyphs
- **Folder mappings** - Special folders, including `.git`, `.config`, `.cache`, and `node_modules`
- **Color coding** - Uses the upstream devblackops RGB color theme in terminals with true-color support
- **Bash configuration files** - `.bashrc` uses the same shell icon and color as `.sh` files
- **`ti` command** - Show icons for any path
- **Detailed listing** - `ti -l` displays permissions, owner, group, human-readable size, and modified time
- **Tree view** - `ti --tree` recursively lists directories, including hidden entries, without following symlinks
- **Color controls** - Honors `NO_COLOR`, supports `--color` and `--no-color`, and avoids color by default when output is piped
- **Bash completion** - Completes options and filesystem paths
- **Safe lifecycle** - Re-running `bash install.sh` updates the installation without duplicating the Bash startup line; `bash install.sh --uninstall` removes only Terminal-Icons files and its own startup line
- **Complete devblackops theme** - Includes all file-name, extension, and folder mappings from the upstream theme

The icon mappings are adapted from the MIT-licensed
[devblackops/Terminal-Icons](https://github.com/devblackops/Terminal-Icons)
project and use Nerd Fonts glyphs. Icon and color mappings and their license
attributions are included in [THIRD-PARTY-LICENSES.md](./THIRD-PARTY-LICENSES.md).
Linux does not have Windows junctions, so the upstream junction-specific rules
are not applicable.

## Development and releases

Run the test suite locally with:

```bash
bash -n install.sh terminal-icons.sh icon-theme-data.sh color-theme-data.sh \
  tests/test_installer.sh tests/test_terminal_icons.sh
bash tests/test_terminal_icons.sh
bash tests/test_installer.sh
```

GitHub Actions runs these checks, ShellCheck, and tests with both the minimum
supported Bash 4.3 and the runner's current Bash. Pushing a semantic-version
tag such as `v1.0.0` runs the checks and then publishes a GitHub Release with
generated release notes.
