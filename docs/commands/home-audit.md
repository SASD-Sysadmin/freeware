# home-audit

[Deutsch](home-audit.de.md) · [Project](../../README.md)

`home-audit` checks home-directory metadata for users from a **local passwd-style file** or native **NSS/Directory Services enumeration**. It never enters a user's home, follows home symlinks, or modifies a file.

```sh
./bin/home-audit
./bin/home-audit --source nss
./bin/home-audit --source local --file ./passwd.sample --all
./bin/home-audit --min-uid 2000 --max-uid 49999
./bin/home-audit --all --null > homes.bin
```

## Sources and default ranges

- **Linux/other Unix:** default source `local` (`/etc/passwd`), UID range **1000..59999**.
- **macOS:** default source `nss` (`getpwent`, backed by native system directory resolution), UID range **500..59999**, to include typical macOS user UIDs. The `/etc/passwd` text file is **not** a complete account source on macOS.
- **`--source local`:** local passwd-format file. Explicit `--file PATH` also selects local mode, unless `--source` was explicitly set otherwise.
- **`--source nss`:** host NSS enumeration; cannot be combined with `--file`. **NSS is not guaranteed to enumerate every account**, especially with external directory services. A completed scan cannot certify all LDAP/NIS/AD identities. NSS records with invalid UID/home fields are reported as errors.

The UID range is an operator policy, not proof of which accounts are human. `--all` selects every enumerated identity, including service accounts; their home paths may intentionally be absent or unconventional.

## Findings and statuses

Findings: `missing`, `symlink`, `not-directory`, `wrong-owner`, and `world-writable`. These require administrator interpretation, not automatic repair. `lstat` failures other than absent files produce a nonzero incomplete-scan result. **APFS ACLs and macOS TCC/privacy protections are not audited**; Unix mode bits alone do not represent full access control.

Human output is tab-separated `ISSUE USER UID HOME` with escaped control characters. `--null` emits four raw NUL-separated fields per finding without headers or totals. Exit 0 for completed scan (including findings), 1 for invalid identity records or access errors, 2 invalid arguments, 3 unavailable input/module. Requires Perl core modules and bundled `SASD::Freeware::Account`, no CPAN dependencies.
