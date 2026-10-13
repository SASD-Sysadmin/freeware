# fs-usage

`fs-usage` queries mounted filesystem capacity using the operating system's `df -P -k` interface, reporting total, used and available 1024-byte blocks. It is read-only and accepts one or more existing paths.

## Requirements

Perl 5.8 or newer with core modules `Getopt::Long`, `File::Spec`, and `FindBin`; the supplied `SASD::Freeware::External` and `SASD::Freeware::Walk` modules; and a `df` program in `PATH` that supports the POSIX `-P` and `-k` options. If `df` is absent, returns a failure, or produces unexpected output, `fs-usage` reports the problem and exits nonzero. The script does not call a shell or use GNU-only `df` switches.

## Usage

```sh
fs-usage / /home /var
fs-usage --warn 80 --critical 95 /srv
```

The output is tab-delimited: `STATUS`, `USE%`, `USED_KiB`, `AVAIL_KiB`, `SIZE_KiB`, `FILESYSTEM`, `MOUNT`, and `QUERY`. Special control characters in textual fields are escaped. Percentages are those reported by `df`, not recomputed from file lengths.

`--warn PERCENT` reports WARNING at or above the specified utilization; `--critical PERCENT` reports CRITICAL at or above its utilization. Both thresholds must be integers between 0 and 100. If both are given, critical must be at least warning. Absent thresholds, the status is always OK for a successful query.

`fs-usage` measures the mounted filesystem's allocation as reported by the OS, unlike `fs-report`, which totals logical file lengths within a directory tree. Quotas may impose lower per-user limits than the total space available.

## Exit status

- `0`: successful queries with no threshold violations.
- `1`: one or more warning/critical thresholds met.
- `2`: invalid arguments.
- `3`: missing `df`, unsupported output, inaccessible path, or failed query. If multiple paths were requested, valid ones may still be reported; an execution failure takes priority over a threshold warning.

## Installation

`make test && make install PREFIX=/usr/freeware` or `./bin/fs-usage /` from a checkout.
