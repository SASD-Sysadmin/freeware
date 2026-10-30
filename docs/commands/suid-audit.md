# `suid-audit` — Read-only inventory of SUID and SGID regular files

**English** · [Deutsch](suid-audit.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/suid-audit.1) · [Source](../../bin/suid-audit)

## Purpose and use

Recursively list regular files with set-user-ID (SUID) or set-group-ID (SGID) permission bits, with octal mode, numeric UID/GID and pathname. This **does not execute files, alter their permissions, or establish exploitability**.

## Behavior and checks

Requires an existing real root directory, not a root symlink. `File::Find` does not follow symbolic links; symlinks and nonregular files are excluded. The scan is not restricted to one filesystem. SUID/SGID are merely permission bits; effective kernel handling (for example on `nosuid` mounts) is not inferred. Paths in output are printed directly, not NUL-delimited.

## Usage and options

```text
suid-audit --help
```

| Option | Meaning |
| --- | --- |
| `--root DIRECTORY` | Required directory to scan recursively. |
| `--help` | Display usage without scanning. |
| `--version` | Print `suid-audit 0.1.0`. |

## Practical example

```sh
# Inventory a standard executable directory without changing it.
./bin/suid-audit --root /usr/bin
# Or limit the inspected tree.
./bin/suid-audit --root /usr/local/bin
```

Neither command executes discovered files. Use a controlled disposable fixture for tests; it is unnecessary to create an actually privileged executable.

## Output and exit status

One hit per line, e.g. `SUID mode=4755 uid=0 gid=0 /path` or `SUID+SGID ...`, then `SUMMARY: scanned=N privileged=N errors=N`.

`0` = completed inventory, **even when privileged files are present**; `2` = invalid command line or counted `stat` errors; other nonzero = invalid root or other runtime failure. Inspect `privileged=` rather than interpreting status 0 as “nothing found.”

## Limits, safety and portability

No evaluation of Linux file capabilities, `nosuid` behavior, filesystem mount flags, SELinux/AppArmor, ACLs, package provenance, ownership trust or CVEs. Concurrency and inaccessible subtrees can reduce completeness; no atomic snapshot. Compare hits with a trusted OS baseline instead of labelling all hits vulnerabilities.

## Related resources

[Security policy](../../SECURITY.md) · [Privileged safety](../PRIVILEGED-SAFETY.md) · [Automation overview](automation-tools.md)
