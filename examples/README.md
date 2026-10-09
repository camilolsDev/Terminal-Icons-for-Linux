# Demo files

## File listing preview

The sample files below exercise a range of file-name and extension icons:

![Colored ti long listing of the 20 demo files](../docs/images/ti-long-listing.png)

[`demo-files/`](./demo-files/) contains exactly 20 small sample files with
different names and extensions, organized in the top-level folder and a
`documents/` subfolder. It includes text and source files, configuration
formats, a valid one-page PDF, a small PNG, a ZIP archive, and a compressed tar
archive. The files are safe examples and are only used to demonstrate icon and
color mappings.

From the repository root, list them with:

```bash
source ./terminal-icons.sh
ti -l examples/demo-files
```

The screenshot shown in the main README was rendered from this command's actual
colored output. Its owner and group names are anonymized; other metadata comes
from the sample files and may differ if you recreate the screenshot.

## Folder icon preview

The folder theme covers 45 named mappings, as well as the default folder and
directory-symlink icons:

![Colored terminal gallery of all named folder icons](../docs/images/folder-icons.png)

`bash examples/show-folder-icons.sh` creates a temporary gallery for every
named folder icon in the theme, plus generic-folder and directory-symlink
examples, and displays them with `ti`. The temporary folders are removed when
the command exits.
