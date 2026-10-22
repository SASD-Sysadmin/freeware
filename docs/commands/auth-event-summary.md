# `auth-event-summary` – offline sudo/su/PAM message counts (M7.4)

[Deutsch](auth-event-summary.de.md) · [Roadmap](../ROADMAP.md) · [Manpage](../../man/man1/auth-event-summary.1)

`auth-event-summary` is a **read-only, bounded Perl tool** that classifies
selected `sudo`, `su` and `pam_unix` messages in **traditional RFC3164-like
syslog snapshots**, with or without a leading `<PRI>`. It never reads system
logs automatically and never contacts a service. The tool does not require
root for inputs the operator can already read.

It counts **log-message patterns**. They are *not* unique users, individual
login attempts, verified privilege escalations, executed/successful commands,
security incidents, or proof of a complete audit. Local syslog messages can be
forged, rotated, filtered, delayed or lost. In particular, a `sudo` `COMMAND=`
entry means an invocation was logged; its exit status is unknown.

## Usage

```sh
# Synthetic example only; no host-log access:
printf '%s\n' \
  'Oct 22 08:15:20 lab sudo[7]: user : TTY=pts/0 ; PWD=/tmp ; USER=root ; COMMAND=/usr/bin/id' \
  | ./bin/auth-event-summary

# A saved finite regular syslog export:
./bin/auth-event-summary --input ./auth-export.log

# Fixed-vocabulary NUL output for machine consumers:
./bin/auth-event-summary --input ./auth-export.log --null
```

`--input FILE|-` accepts one regular file (not a symlink) or stdin (`-`, the
default). There is no `--follow`, decompression, rotation scan or implicit
`/var/log` access. On macOS the synthetic offline fixtures run, but the tool
is **not** a native Unified Log adapter.

## Event classes

| Event | What the parser actually saw |
| --- | --- |
| `SUDO_COMMAND` | Supported structured `sudo` command log with TTY, PWD, USER and COMMAND fields, optionally CHROOT/GROUP/TSID. **Not command completion.** |
| `SUDO_DENIED` | Supported beginning-of-message sudoers policy denial / incorrect-password-attempt log. |
| `SU_SUCCESS` | util-linux `su` `(to TARGET) CALLER on TTY` log pattern; **not proof of an established session**. |
| `SU_FAILED` | util-linux `su` `FAILED SU (to TARGET) CALLER on TTY` pattern. |
| `PAM_AUTH_FAILURE` | `pam_unix(SERVICE:auth): authentication failure` for supported sudo/su services. |
| `PAM_SESSION_OPEN` | `pam_unix(SERVICE:session): session opened for user ...`; **not proof of successful password authentication**. |
| `PAM_SESSION_CLOSE` | Matching PAM session-closed log pattern. |
| `OTHER_AUTH` | Other/unsupported messages from `sudo`, `sudo-i`, `su` or `su-l` tags, including other PAM modules/services. |
| `OTHER_SERVICE` | Structurally valid message with a different service tag (including sshd, which M7.3 handles separately). |
| `UNKNOWN` | Invalid/unrecognized record envelope or PRI; its auth content is not interpreted. |
| `TOTAL` | Number of physical input lines processed. |

Each log line contributes to **exactly one** event row. A line that describes
a PAM authentication failure and another line about a later `su` failure may
refer to one human attempt but correctly count as *two log messages*.

The parser recognizes only RFC3164-style English month abbreviations,
plausible date/time, hostname, application tag and payload; an optional PRI
must be canonical and 0..191. Supported tags are `sudo`, `sudo-i`, `su`,
`su-l`. For PAM, the service family must match the emitter (`sudo*` with
`sudo*`, `su*` with `su*`). Other PAM services (including `sshd`) are out of
scope. Format variants, localization, unusual `sudo` field ordering, and
RFC5424/ISO timestamps are deliberately not interpreted as supported events.

Unlike `syslog-summary` (M7.2), this program does not claim to recover syslog
severity. Unlike `ssh-auth-summary` (M7.3), it does not classify SSH login
patterns. None of the three tools authenticate the log sender.

## Output and status

Human output is stable `EVENT<TAB>COUNT` TSV, with ten event rows and `TOTAL`.
With `--null`, exactly eleven rows contain two NUL-terminated fields each,
without a header. Neither representation includes source path, hostname, user,
command, remote IP, PAM parameters, PID, timestamp or raw message.

| Exit | Meaning |
| --- | --- |
| `0` | Input complete; all record envelopes recognized (may include failed or OTHER events). |
| `1` | Input complete, but at least one record has unrecognized envelope/PRI (`UNKNOWN`). |
| `2` | Invalid CLI. |
| `3` | Input/read error, unsafe framing, missing final LF, blank record, limit exceeded or non-regular/symlink file. **No partial report.** |

Limits match M7.3: **16 MiB** input bytes, **128 KiB** per physical line,
**50,000** records. Nonempty input must end with LF; CRLF is allowed. An empty
input is a valid snapshot; blank records and NUL/bare CR are rejected.
Validation completes before any results are printed. A finite live file may
change while being read; use a stable export when reliable accounting matters.
Do not post raw authentication logs in public issues.

## Offline tests

```sh
perl -c bin/auth-event-summary
prove tests/test_auth_event_summary.t
make test
make shellcheck
```

These are synthetic pattern/format regressions, not live sudo/su/PAM acceptance.
The format scope is informed by [sudoers(5)](https://man7.org/linux/man-pages/man5/sudoers.5.html)
and [util-linux `su` logging](https://github.com/util-linux/util-linux/blob/master/login-utils/su-common.c).
