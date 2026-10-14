# login-audit – Inspect historical Linux logins

[Deutsch](login-audit.de.md) · [Project](../../README.md) · [Roadmap](../ROADMAP.md)

`login-audit` performs a **read-only** review of existing login-history data.
On Linux it invokes `last` (wtmp, successful sessions) and `lastb` (btmp,
failed login attempts) with `--time-format iso -w`, using absolute binary
paths and no shell. It never creates a login or modifies accounts. Reading
btmp can require elevated file permissions, but the tool does not elevate.

## Examples

```sh
./bin/login-audit --kind success --user alice
./bin/login-audit --kind failed --limit 20
./bin/login-audit --kind both
./bin/login-audit --kind success --input-success saved-last.txt
./bin/login-audit --kind both --input-success saved-last.txt --input-failed saved-lastb.txt --null > audit.bin
```

`--kind` selects `success`, `failed`, or `both` (default). `--user` matches
one exact login name. `--limit` caps the **combined** displayed rows to
1–1000 (default 100). Each native backend reads at most 5000 records, so
this is a bounded sample, not a complete history. In `both` mode, success
entries precede failed entries: **there is no global chronological sort**.

Columns: `KIND`, `USER`, `TTY`, `HOST`, `LOGIN`, `DETAILS`. ISO `LOGIN` retains
the source time-zone offset. `DETAILS` preserves remaining session/end
information; it is not a normalized logout time. `--null` emits six raw
NUL-terminated fields per record, without headers or totals.

## Saved input, portability and safety

`--input-success FILE` and `--input-failed FILE` accept **text output** from
`last --time-format iso -w` and `lastb --time-format iso -w`, not binary
wtmp/btmp files. One file is required for each requested kind in fixture
mode; symlinked input files are rejected. Parsing fixtures works on Linux
and macOS. **Live collection is Linux-only.** Native macOS/BSD `last`
formats differ and are not silently reinterpreted.

Exit codes: **0** parsed sources; **1** malformed rows skipped, output
incomplete; **2** usage; **3** missing/unreadable source, backend failure,
or unsupported live platform. Partial results are withheld on source failure.
A zero-row report **does not mean** there were no login attempts. wtmp/btmp
may be rotated, disabled, unreadable, incomplete, or tampered with. This
command does not parse SSH/PAM/journald events or infer attacks. Output may
contain personal identifiers and remote hosts; safeguard reports.

Requires Perl 5 with core `Getopt::Long`, and for native Linux collection,
util-linux `last`/`lastb` supporting `--time-format iso`.
