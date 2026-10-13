# fs-report

`fs-report` reads a directory tree and reports directory, regular-file, symbolic-link and other-entry counts, the sum of the logical sizes of regular files, and the largest regular files. It does not modify the filesystem.

## Requirements

Perl 5.8 or newer with its standard `Getopt::Long`, `FindBin`, `Fcntl`, and `File::Spec` modules. The `SASD::Freeware::Walk` module supplied in `lib/` must be installed alongside the command. No external system commands or privileged account are required; directory traversal requires sufficient read and search permissions.

## Usage

```sh
fs-report /home
fs-report --top 25 --min-size 10M /srv
fs-report --one-file-system --top 0 /
```

| Option | Meaning |
| --- | --- |
| `--top N` | Show up to N largest files, `0..1000` (default 10). |
| `--min-size SIZE` | Minimum size for the largest-file list. File and byte totals still include smaller files. |
| `--one-file-system` | Do not inspect entries with a different device ID from the root. |
| `--help`, `--version` | Show help or version. |

`SIZE` means bytes, optionally followed by a **binary** `K`, `M`, `G`, or `T` suffix (`1M` means 1,048,576 bytes). Values outside the supported exact integer range are rejected. Output is line-based; control characters in names are escaped. Symbolic links are counted but never followed. A directory supplied as the root must not itself be a symbolic link.

**Size accounting:** The reported logical bytes sum `st_size` for each pathname. Multiple hard links to the same inode are counted separately. Sparse-file holes and filesystem allocation overhead are not represented. To inspect actual filesystem use, run `fs-usage`.

If a directory becomes unreadable during traversal, diagnostics go to standard error and the report includes the number of traversal errors. A partial report exits nonzero; do not treat it as a complete inventory.

## Exit status

- `0`: scan completed.
- `1`: one or more traversal failures; results may be incomplete.
- `2`: invalid options or arguments.
- `3`: requested root cannot be inspected.

## Installation

From the repository checkout run `make test`, then `make install PREFIX=/usr/freeware`. The installer copies both the command and its supporting Perl module. The command also runs directly from a complete checkout using `./bin/fs-report`.
