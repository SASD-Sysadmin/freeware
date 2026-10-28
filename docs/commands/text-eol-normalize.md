# `text-eol-normalize` — Safe CRLF-to-LF normalization

[English](text-eol-normalize.md) | [Deutsch](text-eol-normalize.de.md) · [Project README](../../README.md) · [Manual page](../../man/man1/text-eol-normalize.1)

## Purpose

`text-eol-normalize` identifies DOS/Windows CRLF line endings and, **only after an explicit `--apply`**, converts them to Unix LF. Already-LF files are never rewritten. Mixed LF/CRLF files are normalized. A single file or a directory may be inspected; directory traversal requires `--recursive` to descend into nested directories.

The tool **does not determine where a document was created**. Its result describes bytes and line endings, not the operating system of origin.

## Usage

```sh
text-eol-normalize --check --recursive /srv/import
text-eol-normalize --dry-run --recursive /srv/import
text-eol-normalize --apply --recursive --min-age 120 /srv/import
```

`--check` is the default. It lists candidates as `DOS` and prints a `SUMMARY`, but does not modify files. `--dry-run` instead lists `WOULD_CONVERT`. `--apply` prints `CONVERT` for successful conversions. A nonzero exit status signals an operational error, **not** merely the presence of CRLF. `--help` and `--version` require no target path.

### Options

| Flag | Meaning |
| --- | --- |
| `--check` | Read-only inspection (default). |
| `--dry-run` | Show planned conversions without changing anything. |
| `--apply` | Explicitly authorize conversion. |
| `--recursive` | Visit subdirectories without following symbolic links. |
| `--one-file-system` | Stay on the root device during recursive traversal. |
| `--include EXT` | Allow an extension; repeat to replace the default allowlist. Accepts `txt`, `.txt`, or `*.txt`. |
| `--exclude EXT` | Exclude an extension; repeatable. |
| `--min-age SECONDS` | Skip files modified too recently; especially useful for cron. |
| `--max-bytes N` | Refuse files larger than N bytes (default 16 MiB, cap 1 GiB). |
| `--verbose` | Include skipped filenames and reasons. |

Default extensions: `txt`, `csv`, `sh`, `md`, `conf`, `cfg`, `ini`, `json`, `xml`, `yaml`, `yml`, `sql`, `py`, and `pl`. The extensions `bin`, `xls`, `xlsx`, `xlsm`, and `xlsb` remain excluded even when explicitly included. Other binary files are detected by scanning the complete bounded input for NUL and disallowed control bytes. UTF-16/UTF-32, standalone-CR text and files with unsupported control bytes are skipped conservatively.

## Cron example

```cron
*/15 * * * * /usr/bin/flock -n /var/lock/sasd-eol-import.lock /usr/freeware/bin/text-eol-normalize --apply --recursive --min-age 120 /srv/import >> /var/log/sasd-eol-import.log 2>&1
```

The cron account must be able to read, create and rename files within `/srv/import`; use a lock path writable by that account. `flock` is a Linux deployment example, not a Perl dependency. **Only process fully delivered, trusted staging files.** The minimum-age check reduces accidental overlap but cannot prove a writer has finished. An atomic uploader that renames completed files into a private input directory is preferable.

## Safety, scope and limitations

- The command is read-only unless `--apply` is specified. Existing LF files are never rewritten, and file timestamps stay unchanged for skipped files.
- Symlinks are not followed. Hardlinked files and setuid/setgid files are skipped. A candidate must be owned by the effective user to be replaced; no root is needed for normal user-owned imports.
- The file is rechecked between scanning and conversion. Conversion is written to a private temporary file in the same directory, then renamed over the source. Errors before rename leave the original intact.
- The replacement **changes inode and modification time**. Its regular permission bits and group are preserved where permitted. **ACLs, extended attributes, flags, special metadata, sparse layout, file ownership by other users and original timestamps are not preserved.** Do not run `--apply` on system configurations, security-sensitive files, or metadata-sensitive data.
- No tool can protect against a noncooperating concurrent writer in the final check/rename window. Use controlled directories and external cooperative locking. There is no crash-durability `fsync` guarantee.
- The complete file is scanned (up to `--max-bytes`) before replacement. Detected binary data, other encodings, files with standalone CR, and unknown extensions are not converted. This is deliberately conservative, not a general text transcoder.
- Paths with control bytes are escaped in logs. File contents are not printed. Do not assume even escaped paths are suitable as a machine-readable record format.

## Tests and installation

```sh
make test
make install PREFIX=/usr/freeware DESTDIR=/tmp/staging-root
```

Tests operate only on disposable temporary files and cover DOS, Unix, mixed line endings, buffer boundaries, binary inputs, excluded extensions, symbolic links, hard links, min-age, dry-run, repeated apply and path escaping. The core implementation uses Perl and standard Perl modules; there is no `dos2unix` dependency. Intended Linux/BSD/macOS portability is distinct from per-platform validation; check CI and conduct an isolated manual acceptance test before cron deployment.

Exit codes: `0` scan/application completed, `1` one or more processing errors, `2` invalid command line. The summary contains the totals `examined`, `dos`, `converted`, `skipped` and `errors`.

MIT License.
