# `syslog-summary` – structure-verified syslog priorities (M7.2)

[Deutsch](syslog-summary.de.md) · [Roadmap](../ROADMAP.md) · [Manpage](../../man/man1/syslog-summary.1)

`syslog-summary` provides a **bounded, read-only, offline** priority summary
for traditional BSD/RFC3164 and RFC5424 syslog messages. It counts a severity
only when an authentic-looking numeric `<PRI>` prefix is backed by a
**structurally valid syslog envelope**. It never infers severity from words
such as `error`, `warning` or `critical` in the message body.

## Examples

```sh
# Safe synthetic example, no access to host logs:
printf '%s\n' '<34>Oct 21 08:30:04 testhost app: error in message' \
  | ./bin/syslog-summary

# Previously exported finite ordinary file:
./bin/syslog-summary --input ./test.syslog

# Strict RFC5424 selection, machine-readable output:
./bin/syslog-summary --input ./test.syslog --format rfc5424 --null
```

With no `--input` (or `--input -`), the program reads stdin. `--format`
accepts `auto` (default), `rfc3164` or `rfc5424`. The tool never invokes
`journalctl`, `logger`, `tail` or other programs, and does not enumerate
`/var/log` on its own or require superuser access.

## Priority semantics and UNKNOWN

For RFC3164, the input must start with a canonical `<PRI>` in the range
**0..191**, followed by a plausible traditional month/day/time/host/message
header. For RFC5424, only version `1` with its required header and a
well-formed structured-data field (or `-`) is supported. The numeric
severity is `PRI % 8`; the facility number is deliberately not reported.

**Ordinary local syslog files often omit `<PRI>`.** A timestamp, hostname and
message by themselves do *not* establish the original severity; these lines
become **UNKNOWN** (exit `1`). A `<3>` inside MESSAGE is likewise not a
priority. There is intentionally no facility/default-severity fallback.

| Severity | Output label |
| --- | --- |
| 0 | EMERGENCY |
| 1 | ALERT |
| 2 | CRITICAL |
| 3 | ERROR |
| 4 | WARNING |
| 5 | NOTICE |
| 6 | INFO |
| 7 | DEBUG |
| missing/invalid header or PRI | UNKNOWN |

Text output always consists of `PRIORITY`, `LEVEL`, `COUNT` TSV columns;
there are eight numbered rows and UNKNOWN/TOTAL rows. `--null` produces
the same ten records without a header, with exactly three NUL-terminated
fields per record. It shares this *output schema* with `journal-summary`
(M7.1), but not that tool's JSONL input format. The legacy `log-summary`
uses a **keyword heuristic** and is not equivalent to either tool.

## Safety and limits

- Up to **16 MiB** total, **128 KiB** per physical line, **50,000** records.
  The entire bounded input is validated before a report is printed;
  continuous `tail -f` feeds are unsupported.
- Empty input is valid. Nonempty input must end in LF (CRLF accepted).
  Blank lines and read/size/record-limit failures produce **no partial
  report** (exit `3`); invalid or missing headers remain UNKNOWN (exit `1`).
- Named inputs must be regular readable files, not symlinks. Log messages,
  timestamps, hostnames, tags, structured-data values, pathnames and secrets
  are never printed. Nevertheless, never publish raw syslog data in issues.
- A well-formed PRI is still sender-supplied and may be altered by relays:
  it is *not* a security verdict or proof of event importance.
- No compressed or rotated log handling, cross-file history, monitoring,
  native macOS Unified Log API, or live syslog transport. Offline CI on
  Ubuntu/macOS does not imply operational acceptance for every log format.

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | Complete input with recognized priorities (or empty input) |
| `1` | Complete input, at least one unverified/UNKNOWN record |
| `2` | Invalid CLI |
| `3` | Input, file, format, line or total-limit error |

## Tests

```sh
prove tests/test_syslog_summary.t
make test
make shellcheck
```

Regression fixtures are synthetic and require no live logs or privileges.
See [RFC 3164](https://www.rfc-editor.org/rfc/rfc3164) and
[RFC 5424](https://www.rfc-editor.org/rfc/rfc5424) for protocol background.
