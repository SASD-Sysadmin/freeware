# path-audit — Path length audit

[Deutsch](path-audit.de.md) · [Manual page](../man/man1/path-audit.1)

## Summary

`path-audit` inventories directory entries whose pathname component or full pathname exceeds configurable byte thresholds. It is useful when checking whether a directory tree fits the naming conventions of another application, archive format, backup process or target filesystem.

## Requirements

Perl 5 with `Getopt::Long`, `File::Spec`, `File::Basename`, and `Fcntl` (core modules). Read access is required. Tested on Linux; compatibility with additional Unix systems should be verified on each system.

## Usage

```sh
path-audit /srv/data
path-audit --component-limit 200 --path-limit 900 /home
path-audit --one-file-system /export
path-audit --null /srv/data > /tmp/path-inventory.dat
```

## Options and output

| Option | Meaning |
| --- | --- |
| `--component-limit N` | Maximum accepted basename length in bytes; default `240` |
| `--path-limit N` | Maximum accepted full path length in bytes; default `1024` |
| `--one-file-system` | Skip entries on a different device from the root |
| `--null` | NUL-separated `REASON`, `COMPONENT_BYTES`, `PATH_BYTES`, `PATH` fields |
| `--help`, `-h`; `--version` | Help; version |

The default report is tab-separated with a header and summary; `REASON` is `component`, `path`, or `both`. Paths are displayed with escaped control characters. `--null` mode has no header or summary and separates **all four fields** with NUL bytes. Byte lengths are measured on pathnames supplied by the operating system (not Unicode character counts).

The thresholds are administrator-chosen audit policies, **not** claims about any particular operating system's `NAME_MAX` or `PATH_MAX`. The full path measurement includes the argument used to invoke the command: absolute and relative paths may produce different results. Symlinks are reported when their own names exceed a threshold, but never traversed. The scan does not rename, remove or change files.

## Exit status

`0`: scan completed; `1`: invalid/inaccessible directory or read/stat failure; `2`: incorrect arguments. Diagnostics go to standard error. Paths may change while scanning; run on a quiescent tree for consistent inventories.

## Installation

Run `make install PREFIX=/usr/freeware` from the repository or invoke `perl bin/path-audit DIRECTORY`. Consult `man -M /usr/freeware/man path-audit` after installation.
