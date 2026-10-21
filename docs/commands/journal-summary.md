# `journal-summary` – structured systemd journal priority summary (M7.1)

[Deutsch](journal-summary.de.md) · [Roadmap](../ROADMAP.md) · [Manpage](../../man/man1/journal-summary.1)

`journal-summary` counts priority categories in **previously exported**
`journalctl --output=json` entries. It never parses message text, invokes
`journalctl`, or runs another external program. The existing `log-summary`
continues to support unstructured text; the two tools are not interchangeable.

## Usage

```sh
# Administrator-controlled synthetic or exported JSON Lines file
./bin/journal-summary --input ./test-journal.jsonl

# Bounded sample from the operator's journal (shell invokes journalctl)
journalctl --no-pager -n 100 --output=json | ./bin/journal-summary

# Machine-readable: three NUL-terminated fields in each record
./bin/journal-summary --input ./test-journal.jsonl --null
```

Omit `--input` or use `--input -` to read stdin. Named inputs must be
readable regular files and cannot be symbolic links. The program is read-only
and does not itself need elevated privileges. Access to a real journal is
managed separately by the operating system and the invoking administrator.

## Input and output

`journalctl --output=json` emits one JSON object per line. The client-provided
`PRIORITY` field is ordinarily a decimal string `"0"` through `"7"`.

| Priority | Report level |
| --- | --- |
| `0` | EMERGENCY |
| `1` | ALERT |
| `2` | CRITICAL |
| `3` | ERROR |
| `4` | WARNING |
| `5` | NOTICE |
| `6` | INFO |
| `7` | DEBUG |
| missing, null, an array or invalid | UNKNOWN |

Single-digit JSON numeric priority values are also accepted. UNKNOWN
indicates a metadata quality issue; it is **not** itself a security alert.
Human output consists of `PRIORITY`, `LEVEL`, `COUNT` TSV columns, all eight
priorities, UNKNOWN and TOTAL. `--null` emits the same ten rows without the
header, with exactly three NUL-terminated fields per row.

**Privacy:** `MESSAGE`, `SYSLOG_IDENTIFIER`, hostnames, usernames, input
paths and timestamps never appear in tool output. Real exported journal data
may nevertheless contain secrets: do not share raw JSON Lines in public
issues or GitHub. Even a syntactically valid priority is supplied by a
client; priority counts do not certify system security or detect attacks.

## Limits and exit status

- **16 MiB** maximum input, **128 KiB** maximum physical JSON line,
  **50,000** entries. M7.1 holds the bounded input in memory. Continuous
  `journalctl --follow` streams are not supported.
- Every JSON line must be complete and valid. Incomplete, malformed,
  oversized or unreadable input yields **no partial success report**.
- `0`: fully parsed, all priorities valid.
- `1`: fully parsed, at least one missing/invalid priority.
- `2`: invalid command-line usage.
- `3`: missing prerequisite, malformed/truncated/oversized data or I/O failure.
- No tail-following, persistence, alerting, authentication analysis or native
  macOS Unified Logging adapter. macOS can parse exported synthetic systemd
  JSON Lines only.

Official references:
[systemd journal fields](https://www.freedesktop.org/software/systemd/man/systemd.journal-fields.html),
[journalctl](https://www.freedesktop.org/software/systemd/man/journalctl.html).
