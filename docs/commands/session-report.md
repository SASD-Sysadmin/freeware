# session-report – Current interactive sessions

[Deutsch](session-report.de.md) · [Project](../../README.md) · [Chapter plan](../ROADMAP.md)

`session-report` lists current interactive sessions with user, terminal and
an OS-specific, unmodified date/origin detail field. It invokes `who` without
a shell, without changing accounts or sessions. Linux and macOS format the
last field differently; this program deliberately does **not** pretend to
normalize the timestamp.

## Examples

```sh
./bin/session-report
./bin/session-report --user alice
./bin/session-report --input ./tests/fixtures/who.txt
./bin/session-report --null > sessions.bin
```

Text output contains `USER`, `TTY`, `DETAILS` and `Sessions`/`Users` totals.
`--user` selects one login name; `--null` emits three raw NUL-separated fields
per session, without headers or totals. The readable table escapes control
characters and backslashes. `--input FILE` reads a previously captured `who`
output for deterministic analysis; only regular, non-symlink files are accepted.

## Boundaries and security

- Reports **current** sessions visible to `who`, not historic logins; some
  remote/container sessions may not be represented.
- No root or sudo, no account or session modification.
- Usernames, terminals and origin hosts may be sensitive personal operational
  data; restrict access to exported reports.
- Only `/usr/bin/who` or `/bin/who` is used, not caller-controlled PATH.

## Exit status

`0` completed (including zero sessions); `1` malformed input lines skipped;
`2` invalid invocation; `3` input/backend unavailable or execution error.
Requires Perl 5 and core module `Getopt::Long`; no CPAN dependencies.
