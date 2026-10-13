# link-audit

`link-audit` scans a directory tree for symbolic links whose targets do not resolve. It does **not** change or remove links. It reports dangling targets, resolution loops, and indeterminate errors separately.

## Requirements

Perl 5.8 or newer, core modules `Getopt::Long`, `FindBin`, `Fcntl` and `Errno`, and bundled `SASD::Freeware::Walk`. No external command or network service is required. The scanning account needs permission to read each directory; it may also need permissions to resolve link targets.

## Examples

```sh
link-audit /srv/data
link-audit --one-file-system /home
link-audit --all /srv/projects
link-audit --null /srv/data > links.bin
```

## Output and behaviour

The normal report has tab-separated `STATUS`, `PATH`, `TARGET` columns and a summary. `dangling` means the target resolution failed with `ENOENT` or `ENOTDIR`; `loop` means `ELOOP`; `unresolved` means another error, for example a permission failure. By default, valid links are omitted. `--all` includes them as `valid`.

Symlinked directories are never recursively entered. Resolving a link's target for status checking can examine a pathname outside the scanned directory. `--one-file-system` prevents descent into separately mounted filesystems. The scan root must be a real directory rather than a symlink. A link could change during a scan; results are a point-in-time inventory, not a filesystem snapshot.

`--null` emits repeated NUL-terminated triples (`STATUS`, `PATH`, `TARGET`), without headers or a summary. Normal output escapes backslashes and control characters such as newlines as `\\` or `\x0A`.

## Exit status

- `0` — complete scan, including when broken links were found.
- `1` — incomplete scan or a link whose target status could not be determined; inspect stderr.
- `2` — incorrect parameters.
- `3` — required bundled Perl library missing.

## Installation

`make test && make install PREFIX=/usr/freeware`. See also `man -M /usr/freeware/man link-audit`.
