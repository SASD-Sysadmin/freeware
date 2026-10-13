# permission-audit

`permission-audit` inventories filesystem entries with the **other-write** mode bit set. It does not modify permissions. A world-writable mode is an indicator to review, not by itself proof of a security vulnerability.

## Requirements

Perl 5.8 or later, core `Getopt::Long`, `FindBin`, `Fcntl`, and the supplied `SASD::Freeware::Walk` library. No third-party executables required. The scan needs adequate directory permissions.

## Examples

```sh
permission-audit /srv
permission-audit --one-file-system /home
permission-audit --include-sticky /tmp
permission-audit --null /srv > writable.bin
```

## Output and interpretation

`TYPE`, `MODE`, `PATH` identify the type of entry, its octal permission bits and escaped pathname. World-writable symbolic links are **not reported**, as their permission bits generally do not govern target access and links are never traversed.

World-writable directories with the sticky bit, such as `/tmp` (`1777`), are excluded by default. `--include-sticky` reports them as `sticky-directory` rather than classifying them as a generic directory. Other reported types are `file`, `directory` and `special`. The scan includes the selected root directory itself. The utility does not inspect POSIX ACLs, NFSv4 ACLs or other effective-access policies. A mode audit cannot determine who can write a file in all circumstances.

`--null` emits repeated NUL-terminated triples (`TYPE`, `MODE`, `PATH`) without header or summary. `--one-file-system` does not descend into a different device. The scan never invokes `chmod`, `chown` or `rm`.

## Exit status

- `0` — full inventory, even when writable entries were found.
- `1` — filesystem traversal/metadata error, possibly incomplete output.
- `2` — invalid options.
- `3` — required bundled Perl library missing.

## Installation

`make test && make install PREFIX=/usr/freeware`. See `man -M /usr/freeware/man permission-audit`.
