# `log-summary` — Streaming severity-word counts for plain-text logs

**English** · [Deutsch](log-summary.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/log-summary.1) · [Source](../../bin/log-summary)

## Purpose and use

Counts lines from a plain-text file or stdin. Only aggregate counters are printed; original messages are never echoed. This is a lexical heuristic, **not** syslog/JSON parsing, alert correlation or tamper detection.

## Behavior and checks

One line at a time, increment `Lines read:`. If `--match` is supplied, retain only lines containing that literal substring regardless of case; the filter is **not a regex**. Every selected line goes to exactly one class: `CRITICAL` (EMERG, EMERGENCY, ALERT, CRIT, CRITICAL, FATAL), `ERROR` (ERR, ERROR), `WARNING` (WARN, WARNING), `NOTICE`, `INFO`, `DEBUG`, `TRACE`, or `OTHER`. Tokens use word boundaries; highest-severity match wins, even when the word appears in ordinary message text.

## Usage and options

```text
log-summary --help
```

| Option | Meaning |
| --- | --- |
| `--match LITERAL` | Case-insensitive literal substring filter. |
| `LOGFILE` | Read one file. |
| `-` or omitted path | Read standard input. |
| `-h`, `--help` | Print usage. |
| `--version` | Print `log-summary 0.1.0`. |

## Practical example

```sh
printf '%s\n' 'INFO started' 'WARN retry' 'ERROR refused' | \
  ./bin/log-summary -
printf '%s\n' 'INFO sshd ready' 'WARN job delayed' 'ERROR sshd refused' | \
  ./bin/log-summary --match sshd -
```

Existing host logs can be processed as `./bin/log-summary /var/log/syslog` or `journalctl --no-pager -n 1000 | ./bin/log-summary -` when permitted. The command reads to EOF and does not follow a growing file.

## Output and exit status

`Lines read:`, `Lines matched:` plus totals `CRITICAL`, `ERROR`, `WARNING`, `NOTICE`, `INFO`, `DEBUG`, `TRACE`, `OTHER`. Excluded lines are not counted in categories.

`0` = successful read/report, **regardless of ERROR/CRITICAL totals**; `2` = invalid invocation; other nonzero = file access/close failure. Alerting wrappers must parse reported counts.

## Limits, safety and portability

No timestamp range, structured severity extraction, deduplication, rotation tracking, application-level diagnostics or secure evidence trail. Log text can be sensitive even when output contains counters only. Depends on Perl core facilities; available log paths differ by OS.

## Related resources

[`syslog-summary`](syslog-summary.md) · [`journal-summary`](journal-summary.md) · [Perl overview](perl-tools.md)
