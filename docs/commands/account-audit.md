# `account-audit` — Structural audit of Unix passwd files

**English** · [Deutsch](account-audit.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/account-audit.1) · [Source](../../bin/account-audit)

## Purpose and use

Read-only validation of seven-field Unix `passwd(5)` text, by default `/etc/passwd`. This is **not** a password, authentication, NSS, LDAP, PAM or shadow-database audit. The input is never modified.

## Behavior and checks

Lines that are empty or start with optional whitespace and `#` are ignored. Legacy `+`/`-` NIS compatibility entries are skipped with a warning. Each other line must contain seven colon-separated fields (`name:password:uid:gid:gecos:home:shell`). The name follows a restricted ASCII pattern; UID/GID must be decimal; the home field must start with `/`. Duplicate names, distinct names sharing a UID, an additional UID-0 account, and an empty shell generate **warnings**. The password, GECOS and shell contents are not otherwise validated; a home path is not tested for existence.

## Usage and options

```text
account-audit --help
```

| Option | Meaning |
| --- | --- |
| `--file PATH` | Input text file (default `/etc/passwd`). |
| `-h`, `--help` | Display usage without reading the target. |
| `--version` | Print `account-audit 0.1.0`. |

## Practical example

```sh
sample="$(mktemp)"
printf '%s\n' 'root:x:0:0:root:/root:/bin/sh' \
  'operator:x:1000:1000:Operator:/home/operator:/bin/sh' \
  'second:x:1000:1001:Second:/home/second:' > "$sample"
./bin/account-audit --file "$sample"
rm -- "$sample"
```

The fixture gives warnings for the shared UID and empty shell but **exit 0**, since the records are structurally valid. No real account files are changed.

## Output and exit status

Standard output prints `Accounts:`, `Distinct UIDs:`, `Warnings:`, `Errors:`. Per-line errors/warnings include the input path and line number on stderr.

`0` = no structural errors **even when warnings exist**; `1` = invalid records; `2` = invalid command line; other nonzero = file access/close failure. Monitoring must inspect `Warnings:` or stderr if warnings matter.

## Limits, safety and portability

Unix text-file snapshot only; no live directory identities, authentication outcomes, password checks or ownership of home directories. Usernames in reports may be sensitive. macOS `/etc/passwd` is not an authoritative Directory Services source; an explicit Unix-format fixture is appropriate. No special privileges are requested.

## Related resources

[Perl tools overview](perl-tools.md) · [`account-inventory`](account-inventory.md) · [Platform scope](../PLATFORMS.md)
