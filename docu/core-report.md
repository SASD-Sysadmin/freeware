# core-report — Core dump candidate inventory

[Deutsch](core-report.de.md) · [Manual page](../man/man1/core-report.1)

## Summary

`core-report` inventories regular files named `core` or beginning with `core.` under one directory. It reports apparent core dump candidates, their logical size in bytes, and totals. It neither verifies that a file is an actual crash dump nor modifies or removes files.

## Requirements

Perl 5 with `Getopt::Long`, `File::Spec`, and `Fcntl` (standard Perl modules). The target directory must be readable. Tested on Linux; other Unix-family systems require their own validation. Root privileges are not required unless directory permissions prohibit reading.

## Usage

```sh
core-report /var/tmp
core-report --min-size 1048576 /home
core-report --one-file-system /srv
core-report --null /var/tmp > /tmp/core-inventory.dat
```

## Options

| Option | Meaning |
| --- | --- |
| `--min-size BYTES` | Include only candidates with a logical size of at least this value; default `0` |
| `--one-file-system` | Skip entries with a device ID different from the scan root |
| `--null` | Emit `BYTES\0PATH\0` fields per record, with no header or summary |
| `--help`, `-h` | Show help |
| `--version` | Show program version |

Standard output begins with `BYTES<TAB>PATH`, followed by one line per candidate. Backslashes, tabs, carriage returns and newlines are escaped in displayed pathnames. The final lines give candidate count, logical byte total and error count. In `--null` mode, record fields use NUL delimiters to preserve pathname bytes, including line breaks and tabs.

## File selection and limitations

- The names `core` and `core.*` are selected regardless of content. Non-crash files can match. Files with other names may be actual core dumps but are not selected.
- Symbolic links are not followed, including links to directories. Other filesystems can be excluded with `--one-file-system`.
- The scan is read-only. It does not reclaim space or validate core dump contents.
- Directories changing during the scan may cause incomplete results or errors; the program does not create a filesystem snapshot.
- File sizes are logical bytes from `lstat`, not allocated blocks.

## Exit status and troubleshooting

`0`: scan completed; `1`: invalid or inaccessible root, traversal/stat error; `2`: invalid arguments. Diagnostics go to standard error. Use `--null` if file names may contain control characters and downstream tools need lossless records.

## Installation

Install with `make install PREFIX=/usr/freeware` from a verified repository checkout, or run `perl bin/core-report DIRECTORY` directly. The manual page installs to `/usr/freeware/man/man1/core-report.1` by default.
