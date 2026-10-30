# `hosts-lint` — Syntax validation for Unix hosts files

**English** · [Deutsch](hosts-lint.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/hosts-lint.1) · [Source](../../bin/hosts-lint)

## Purpose and use

Read-only syntax checking for a hosts-file of the form `IP NAME [ALIAS ...]` (default `/etc/hosts`). The command does **not** query DNS, resolve names, or rewrite the source.

## Behavior and checks

Strip content after the first `#`, trim whitespace, skip empty lines. IPv4 requires four decimal octets 0–255 with no leading zeroes; IPv6 uses Perl `Socket::inet_pton`. Names allow letters, digits, underscores, hyphens and dots (including trailing dot). A valid IP with no hostname is an error. One case-insensitive name associated with different **textual** addresses is a **warning**; multiple mappings can be intentional.

## Usage and options

```text
hosts-lint --help
```

| Option | Meaning |
| --- | --- |
| `--file PATH` | Input file (default `/etc/hosts`). |
| `-h`, `--help` | Print usage without reading the file. |
| `--version` | Print `hosts-lint 0.1.0`. |

## Practical example

```sh
sample="$(mktemp)"
printf '%s\n' '127.0.0.1 localhost' '::1 localhost ip6-localhost' \
  '192.0.2.10 app.example.test app' > "$sample"
./bin/hosts-lint --file "$sample"
rm -- "$sample"
```

This fixture intentionally reports a conflicting mapping warning for `localhost`; warnings alone do **not** cause failure. To examine the current file, run `./bin/hosts-lint`.

## Output and exit status

Counts `Entries:`, `Unique names:`, `Warnings:`, `Errors:` on stdout; path/line diagnostics on stderr.

`0` = no syntax errors **even with warnings**; `1` = invalid IP/hostname or missing hostname; `2` = invalid options; other nonzero = file error.

## Limits, safety and portability

Not a complete vendor-specific hosts parser. No semantic IP canonicalization, resolver precedence, DNS, mDNS or cache checks. IPv6 zone identifiers and unusual name tokens may not be accepted. Underscore acceptance does not imply general DNS validity. Readable text fixtures are usable on Linux and macOS; no host-wide compatibility certification.

## Related resources

[Perl tools overview](perl-tools.md) · [`host-resolve`](host-resolve.md) · [Platforms](../PLATFORMS.md)
