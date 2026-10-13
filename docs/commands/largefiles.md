# largefiles

`largefiles` searches for large regular files beneath a directory. It never deletes or modifies files, does not follow symbolic links, and keeps no more than the requested number of results in memory unless output is streamed via `--all`.

## Requirements

Perl 5.8 or newer, Perl core modules `Getopt::Long`, `FindBin`, `Fcntl` and `File::Spec`, plus the shipped `SASD::Freeware::Walk` module. The caller needs sufficient permissions to traverse the selected directories.

## Usage

```sh
largefiles --min-size 500M /var
largefiles --min-size 1G --top 20 /home
largefiles --min-size 10M --one-file-system --all /srv
largefiles --min-size 100M --null /data > /tmp/largefiles.records
```

| Option | Meaning |
| --- | --- |
| `--min-size SIZE` | Inclusive minimum file size, default `100M`. |
| `--top N` | Return at most N of the largest matches, default 50; range `1..10000`. |
| `--all` | Stream all matching files in traversal order (not size-sorted). |
| `--one-file-system` | Skip entries on devices different from the starting directory. |
| `--null` | NUL-separated pairs `size\0pathname\0`, without header or summary. |
| `--help`, `--version` | Show help or version. |

Sizes use binary `K/M/G/T` suffixes. Text output escapes control characters; `--null` preserves raw pathnames for scripts, including embedded newlines. Without `--all`, results are sorted by decreasing file size (ties: pathname). The match count and total logical bytes refer to **all** matching files, not only those shown in the top-N list. Hard links are counted per pathname.

The scan may span NFS or other mounted filesystems unless `--one-file-system` is requested. Device IDs are not a complete way to distinguish every bind mount; choose a scope appropriate to the host. Permission errors produce a partial result and an exit code of 1.

## Exit status

- `0`: completed, including no matches.
- `1`: at least one traversal error; results may be incomplete.
- `2`: invalid parameters.
- `3`: start directory unavailable.

## Installation

Use `make test && make install PREFIX=/usr/freeware`. A complete source checkout can also run `./bin/largefiles` directly.
