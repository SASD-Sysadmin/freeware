# owner-audit

`owner-audit` lists file ownership IDs that cannot currently be resolved to user or group names through the operating system's name service. It never changes ownership. This inventory is useful when checking directory trees after account migrations or name-service changes.

## Requirements

Perl 5.8 or newer, core modules `Getopt::Long` and `FindBin`, and the bundled `SASD::Freeware::Walk`. User and group lookups use Perl's `getpwuid` and `getgrgid`, normally backed by the host's configured NSS services. No parsing of `/etc/passwd` or `/etc/group` is required. Remote services such as NIS or LDAP may be consulted by the operating system.

## Examples

```sh
owner-audit /home
owner-audit --scope user /srv/archive
owner-audit --scope group --one-file-system /srv
owner-audit --null /srv/archive > owners.bin
```

## Output and limitations

`ISSUE` is `user`, `group` or `user+group`, followed by numeric `UID`, `GID` and `PATH`. By default both lookups are performed; `--scope` narrows them. User/group lookup results are cached by numeric ID for the duration of the scan. Symbolic links are not followed; their *own* ownership is inspected with `lstat`. The root must be a real directory.

**An unresolved identifier does not prove that an account has been deleted.** Name-service outages, caching or access policy may prevent a lookup. Check the host's NIS/LDAP/NSS configuration before treating an entry as orphaned. The tool never calls `chown` or `chgrp`.

`--null` emits repeated NUL-terminated quadruples (`ISSUE`, `UID`, `GID`, `PATH`); no header or summary. Normal mode escapes control characters and backslashes in paths.

## Exit status

- `0` — scan completed, whether or not unresolved IDs were found.
- `1` — directory or metadata access error; inventory may be incomplete.
- `2` — invalid arguments.
- `3` — required bundled Perl library missing.

## Installation

`make test && make install PREFIX=/usr/freeware`. See `man -M /usr/freeware/man owner-audit`.
