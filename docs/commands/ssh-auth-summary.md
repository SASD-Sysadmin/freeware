# `ssh-auth-summary` – offline SSH server log patterns (M7.3)

[Deutsch](ssh-auth-summary.de.md) · [Roadmap](../ROADMAP.md) · [Manpage](../../man/man1/ssh-auth-summary.1)

`ssh-auth-summary` is a bounded, read-only, offline report of **OpenSSH sshd
message patterns** within conventional RFC3164-like local syslog text. It is
**not** a general authentication audit, incident detector, real-time monitor,
or source of authoritative login history. A log sender can forge a message;
rotation, policy and permissions can hide genuine events.

## Examples

```sh
# Synthetic data only; does not read host logs.
printf '%s\n' \
  'Oct 21 08:30:04 lab sshd[100]: Failed password for guest from 192.0.2.10 port 2222 ssh2' \
  | ./bin/ssh-auth-summary

# Read a previously exported, finite text file explicitly:
./bin/ssh-auth-summary --input ./ssh-fixture.log

# Two NUL-terminated fields per result, without a header:
./bin/ssh-auth-summary --input ./ssh-fixture.log --null
```

Default input is stdin; `--input -` explicitly selects stdin. A named file
must be a readable regular file, not a symlink. No SSH, logging or account
service is started or queried; no privileges are elevated and no files are
changed. Native macOS Unified Logs and systemd journal JSON are **not** input
formats. Other tools are `journal-summary` (JSONL priority) and
`syslog-summary` (structural syslog PRIORITY, not authentication patterns).

## Input contract

- Each record must be a nonempty physical line terminated by LF; CRLF is
  accepted. Empty input is a valid zero-record report.
- Recognizes a **RFC3164-like** `Mon DD HH:MM:SS HOST TAG[PID]: MESSAGE`
  envelope, with optional canonical leading `<PRI>` between 0 and 191. The
  traditional timestamp has **no year and no timezone**; Feb 29 is allowed.
  The presence of PRI is optional because ordinary local `/var/log/auth.log`
  and `/var/log/secure` commonly omit it. PRI is **never** used as proof of an
  authentication outcome.
- Only a tag whose application name is exactly `sshd` is classified as SSHD.
  A trusted-looking word `Accepted` or `Failed` in some other service's text
  does not count as SSH authentication.
- The implemented recognizable prefixes are `Accepted METHOD for USER from
  ADDRESS port N ssh2`, `Failed METHOD for [invalid user] USER from ADDRESS
  port N ssh2`, and `Invalid user USER from ADDRESS port N`. Accepted/failed
  methods are `password`, `publickey`, `keyboard-interactive/pam` and
  `gssapi-with-mic`; IPv4-/IPv6-like address tokens and numeric ports 1..65535
  are required. These tokens are **not independently authenticated**. SSHD
  versions and distributions use additional wordings which remain OTHER_SSHD.
- `--input` neither scans a directory nor follows rotating logs, and the
  parser does not support RFC5424 records. Such unsupported records are
  UNKNOWN unless their framing is invalid, in which case processing fails.

## Output and interpretation

Output has TSV columns `EVENT` and `COUNT`, followed by these seven records:

| Event | Meaning |
| --- | --- |
| `ACCEPTED` | Recognized `sshd` *accepted-authentication message* pattern |
| `FAILED` | Recognized `sshd` *failed-authentication message* pattern |
| `INVALID_USER` | Recognized `sshd` *invalid-user message* pattern |
| `OTHER_SSHD` | Structurally recognized `sshd` envelope, other message pattern |
| `OTHER_SERVICE` | Structurally recognized syslog envelope, non-`sshd` tag |
| `UNKNOWN` | Unsupported, incomplete or unrecognized syslog *envelope* |
| `TOTAL` | Total validated physical input records |

In `--null` mode, **exactly 14 NUL-terminated fields** represent the same
seven event/count pairs without a header. All outputs contain exclusively
fixed labels and counts: usernames, addresses, key fingerprints, hostnames,
timestamps, message bodies, paths, and control sequences are never printed.

**These are message counts, not unique users, sessions or authentication
attempts.** One attempt may generate multiple entries (e.g. INVALID_USER
and FAILED), some entries may be missing, and a forged entry may look valid.
A status 0 does not establish that the system is secure or fully observed.

## Limits, errors and supported platforms

- At most **16 MiB** of input, **128 KiB** per physical line, and **50,000**
  physical records. Input is fully buffered and checked before any report;
  continuous feeds such as `tail -f` are not supported.
- Blank lines, incomplete final lines, embedded NUL or bare carriage return,
  unreadable/nonregular input, and size/count violations result in **exit 3
  with no partial output**. Validly framed but unsupported lines contribute
  to UNKNOWN with exit 1, not silently to a specific authentication category.
- The program is portable Perl 5 and is tested with synthetic fixtures on
  Linux/macOS CI. It makes **no claim** about native macOS Unified Logging,
  provenance of a log file, or completeness of any live host source.

| Exit | Meaning |
| --- | --- |
| `0` | All input lines structurally recognized (including OTHER_SSHD/OTHER_SERVICE), or empty |
| `1` | Input fully read; at least one UNKNOWN envelope |
| `2` | Invalid command-line invocation |
| `3` | Unavailable or invalid source/framing, missing LF, or exceeded limit |

## Testing

```sh
perl -c bin/ssh-auth-summary
prove -v tests/test_ssh_auth_summary.t
make test
make shellcheck
```

Tests use only synthetic fixtures and never contact a real SSH server.
