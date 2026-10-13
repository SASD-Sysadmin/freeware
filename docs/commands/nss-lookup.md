# nss-lookup — targeted system identity resolution

[Deutsch](nss-lookup.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/nss-lookup.1)

`nss-lookup` performs **one specific libc name-service lookup** for a user or group. It uses Perl's `getpwnam`, `getpwuid`, `getgrnam`, or `getgrgid`. It does not modify accounts and requires no administrative privileges.

## Examples

```sh
./bin/nss-lookup --user root
./bin/nss-lookup --uid 501                  # common macOS local UID
./bin/nss-lookup --uid 1000                 # common Linux local UID
./bin/nss-lookup --group staff
./bin/nss-lookup --gid 0
./bin/nss-lookup --user root --null > root-account.bin
```

Exactly one of `--user NAME`, `--uid N`, `--group NAME`, `--gid N` is required. Names may be 1–255 bytes without control characters; numeric IDs must be unsigned decimal integers in `0..4294967295`. This tool does not use a shell to process names.

## Data sources and trust boundaries

The host's libc/NSS (including macOS Directory Services integration, if configured) decides where a name is looked up: local files, LDAP, NIS, caching services or other sources. **One successful lookup does not establish that all names can be enumerated**, nor does it identify which backend answered. To compare local files with visible NSS records, use `account-inventory` instead. The result is specific to the invoking host and its current name-service configuration.

## Output and exit codes

Human output is tab-separated: `TYPE NAME UID GID HOME SHELL MEMBERS`; control characters and backslashes are escaped as `\xHH`. `--null` produces **exactly seven raw NUL-separated fields** per match, without headers. A group has empty `UID`, `HOME` and `SHELL` fields. The `MEMBERS` field comes from NSS group data and is not a complete account membership listing.

- `0`: identity found; `1`: identity not found; `2`: invalid arguments. NSS backends can transiently fail; libc lookups may not distinguish a missing account from a backend error.

Requires Perl 5 with its standard modules, no external utilities or CPAN dependencies. On a platform where libc does not support a configured NSS backend, this tool cannot supply it.
