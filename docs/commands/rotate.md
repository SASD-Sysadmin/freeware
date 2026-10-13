# `rotate` — File snapshot rotation

[English](rotate.md) | [Deutsch](rotate.de.md) · [Project README](../../README.md) · [Manual page](../../man/man1/rotate.1)

## Summary

`rotate` creates a numbered copy of one existing regular file without modifying the source. At most ten automatically managed generations are kept beside the file: `.0` is the newest and `.9` is the oldest. Before creating a new `.0`, existing snapshots are renamed toward `.9` and the oldest one is removed. Legacy backup files with purely numeric suffixes `.10` and above are deleted. The program is written in Bash and uses standard Unix utilities.

## Synopsis and example

```text
rotate FILE
```

```sh
printf '%s\n' '127.0.0.1 localhost' > hosts
./bin/rotate hosts
# creates hosts.0; hosts remains unchanged
./bin/rotate hosts
# hosts.0 -> hosts.1, a fresh hosts.0 is created
```

The snapshot is always placed **next to the original**, not in the current directory unless the source is there. Quotes are required for shell paths with spaces. A relative path beginning with `-` is handled safely by the script.

## Versioning rules

| Item | Meaning |
| --- | --- |
| `FILE` | The unchanged source file |
| `FILE.0` | Latest snapshot of `FILE` |
| `FILE.1` | Previous snapshot |
| `FILE.9` | Oldest retained snapshot |
| `FILE.10` and greater | Obsolete numbered snapshots, removed if ordinary files or symlinks |
| `FILE.01`, `FILE.10.notes` | Not recognized as numbered snapshots; preserved |
| `FILE.rotate.lock` | Temporary directory to prevent competing rotations |

A backup cycle first copies the source into a temporary file in the same directory. If the copy fails, the old backup generations have not yet been shifted. It then deletes obsolete `.10+` snapshots and `.9`, renames `.8` to `.9` through `.0` to `.1`, and renames the temporary copy to `.0`. An interrupted rename sequence is **not** automatically rolled back.

## Supported inputs and safety

- Exactly one path is required. The input must be an existing **regular file**, not a symbolic link or directory.
- Slots `.0` through `.9` may be absent or ordinary files. Existing symbolic links, directories, or special files in those slots cause a safe refusal.
- A `FILE.rotate.lock` directory is created with restricted permissions for the duration of the run. An existing lock prevents the command from running. After `SIGKILL` or a machine crash the lock may remain: inspect it before deleting it manually.
- The parent directory must allow file creation, renaming, and removal. Protected files such as `/etc/hosts` often require elevated privileges.
- `cp -p` requests preservation of mode, timestamps, and ownership where supported and permitted. The backup contains the full plaintext contents of the original. Keep sensitive backups in a properly protected directory.
- This utility does not coordinate with processes writing the source file. The resulting copy may reflect an in-progress write. It is not a database backup or transactional snapshot system.
- Backups are not globally atomic or crash-proof. Avoid parallel invocations with another utility managing the same suffixes.

## Restore a generation

Inspect the backup before replacing your source file. For example:

```sh
ls -l -- /etc/hosts /etc/hosts.[0-9]
# After verification, as an appropriately privileged user:
cp -p -- /etc/hosts.2 /etc/hosts
```

This manual restore overwrites the source. It does **not** call `rotate` or create a new history entry; make another safety copy first if needed. If the backup is sensitive, avoid printing it to shared terminal logs.

## Installation, tests, and troubleshooting

Install from the repository with `make test && sudo make install PREFIX=/usr/freeware`, or run `./bin/rotate` directly. Read the manual page using `man -M /usr/freeware/man rotate` after installation. `make test` runs self-contained temporary-directory tests without modifying `/etc`.

Exit statuses: `0` for success, `2` for an incorrect argument count, and another nonzero code for invalid paths, occupied locks, permission failures, or failed filesystem operations. Errors go to standard error. If a lock is left behind, ensure no active rotation is running before removing `FILE.rotate.lock`. On a failed/partial rotation, inspect all `FILE.[0-9]` versions before retrying.

## Scope and compatibility

The implementation targets Bash (including the Bash 3.2 series commonly found on older macOS versions) and customary GNU/BSD command-line tools. GitHub Actions is configured for Ubuntu and macOS; actual CI results should be checked in GitHub. This is a deliberately small utility, not a replacement for `logrotate`, filesystem snapshots, or off-site backups.

Licensed under the repository's [MIT License](../../LICENSE).
