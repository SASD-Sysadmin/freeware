# process-report – Running processes by account and state

[Deutsch](process-report.de.md) · [Project](../../README.md) · [Chapter plan](../ROADMAP.md)

`process-report` takes a **read-only snapshot** of running processes via
native `ps`, requesting `pid`, `ppid`, `user`, `stat`, `etime`, and `comm`.
Linux and macOS work without `/proc`-specific assumptions.

## Examples

```sh
./bin/process-report
./bin/process-report --user alice --limit 25
./bin/process-report --state Z
./bin/process-report --input ps-snapshot.txt --null > processes.bin
```

Columns: `PID`, `PPID`, `USER`, `STATE`, `ELAPSED`, and `COMMAND`.
`--state` matches the **first letter** of `ps` state (`R`, `S`, `Z`, etc.),
while extra flags such as `+` remain visible. `--limit` allows 1..5000
(default: 200). `Matching` counts all valid matches; `Shown` counts displayed
rows. `--null` emits six NUL-terminated fields per row, without headers or
totals. `--input FILE` parses saved, **headerless** output in the above `ps`
field order; symlinked input is refused.

## Boundaries and security

- A snapshot is not process history or proof of human user activity. Entries
  may disappear at any time.
- `comm` is the OS-reported command name, not necessarily the entire command
  line or a fully qualified executable path.
- No root or sudo, no signals or process modification. Process visibility
  depends on OS policy and caller permissions.
- Process and user information may be sensitive; protect exported reports.
- Backend uses only `/bin/ps` or `/usr/bin/ps`, no shell or inherited PATH.

## Exit status

`0` completed; `1` malformed rows skipped; `2` invalid arguments;
`3` missing input/backend or execution error. Perl 5 and core `Getopt::Long`
only; no CPAN dependencies.
