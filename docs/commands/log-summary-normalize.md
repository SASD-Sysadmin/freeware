# log-summary-normalize — bounded M7.5 aggregate normalization

`log-summary-normalize` converts the **complete aggregate output** of one of
four existing SASD tools into a common, versioned JSON Lines representation.
It is read-only and designed for deterministic downstream automation without
releasing log messages, hostnames, accounts, addresses or command strings.

**Scope:** M7.5 establishes a *common summary format*, **not event-level
normalization or correlation**. The four upstream tools count different
attributes and may cover the **same underlying syslog record**. The JSONL
output therefore keeps `source` and `scope=source_summary` on every row. Never
add totals across different sources and call the result a count of distinct
records, login attempts, commands or incidents. No timestamp or unique event
ID is inferred from aggregate data. Event-level correlation is deferred to a
future independently designed milestone.

## CLI

```sh
# Read an existing TSV report (the default output of journal-summary).
./bin/journal-summary --input ./journal.jsonl > ./journal.tsv
./bin/log-summary-normalize \
    --source journal-summary --input ./journal.tsv > ./journal-summary.jsonl

# Use the null-delimited report form without guessing field boundaries.
./bin/ssh-auth-summary --input ./auth.log --null > ./ssh.counts
./bin/log-summary-normalize \
    --source ssh-auth-summary --format null --input ./ssh.counts

# Stdin also works (the normalizer itself never accesses a live log).
./bin/auth-event-summary --input ./auth.log |
    ./bin/log-summary-normalize --source auth-event-summary
```

`--source` is **mandatory** and limited to `journal-summary`,
`syslog-summary`, `ssh-auth-summary`, and `auth-event-summary`. `--input FILE|-`
defaults to stdin; `--format tsv|null` defaults to `tsv`. `--help` and
`--version` follow the repository's standard CLI conventions. File paths are
never printed in diagnostics. The input is a **summary report**, not a raw
syslog file, journal export, or concatenation of reports.

The source program's exit code **1** indicates UNKNOWN entries even when its
report is well formed. In a `set -o pipefail` pipeline, this can propagate
while the normalizer still produces valid JSON Lines. Handle this explicitly
rather than accidentally discarding the original finding status.

## `sasd.log-summary.v1` contract

Every JSONL line is a complete object with these exact keys:

| Key | Meaning |
| --- | --- |
| `schema` | Constant `sasd.log-summary.v1` |
| `scope` | Constant `source_summary` (not an event stream) |
| `source` | One fixed upstream tool name |
| `type` | `category` or `total` |
| `category` | Fixed source-specific event/severity name or `TOTAL` |
| `priority` | Integer `0..7` only for known journal/syslog severity classes; JSON `null` otherwise |
| `count` | Nonnegative integer at most 50000 |

For example, one line may look like:

```json
{"category":"ERROR","count":2,"priority":3,"schema":"sasd.log-summary.v1","scope":"source_summary","source":"syslog-summary","type":"category"}
```

Rows are emitted in the source CLI's documented order, including zero-count
categories and **one separately typed TOTAL row**. This is intentionally a
strict input contract: wrong headers, wrong field order, duplicate/missing
rows, unexpected categories, noncanonical decimals, extra fields or
`TOTAL != sum(categories)` abort with **no stdout**. Thus the normalizer
cannot silently accept a changed or truncated upstream output contract.

Journal and syslog use `PRIORITY`, `LEVEL`, `COUNT` TSV triples (and corresponding
NUL triples). SSH and sudo/su/PAM tools use `EVENT`, `COUNT` TSV pairs (and NUL
pairs). The normalizer does not guess severity from authentication events.

## Safety, limits, and exit status

- Reads one finite report from stdin or a local regular file; named symlinks,
  non-files and input replacement between `lstat` and `fstat` are rejected.
- Up to 8192 input bytes and 16 rows. All fields must match enumerated schema
  labels. Counts are bounded to the upstream 50000-record limit.
- Entire input and reconciled totals are validated **before emitting output**.
  Malformed framing, extra data, bytes or fields are fatal, never ignored.
- Does not spawn or modify another program; no network, privileged access,
  journalctl, syslog API, PAM operation or service configuration is touched.
- Exit `0`: valid complete report without UNKNOWN; `1`: valid report with
  UNKNOWN count above zero (a finding, not an execution failure); `2`: invalid
  CLI; `3`: unreadable, malformed, incomplete or excessive input, or missing
  JSON::PP. Fatal errors emit no partial JSONL output.

## Validation

```sh
perl -c bin/log-summary-normalize
prove -v tests/test_log_summary_normalize.t
make test
make shellcheck
```

Test coverage includes every source and input framing, zero and unknown
counts, canonical JSON, cross-source rejection, truncation, extra rows,
malicious controls, impossible totals, count overflow and symlink rejection.
The tests are offline and use synthetic aggregate reports. Native-platform
integration, event-level correlation, de-duplication and cross-format
completeness are still open.
