# home-audit

[Deutsch](home-audit.de.md) · [Project](../../README.md)

`home-audit` checks the metadata of home directory paths listed in a **local passwd-style file**. It does not recursively read users' private files and never corrects modes, ownership, or paths.

```sh
./bin/home-audit
./bin/home-audit --file ./passwd.sample --all
./bin/home-audit --min-uid 2000 --max-uid 49999
./bin/home-audit --all --null > homes.bin
```

Default account selection is UID **1000 through 59999** (inclusive), avoiding common service and `nobody` IDs. This is a configurable policy, **not a universal Unix definition of human accounts**. Use `--all` to include every valid local passwd record, including root and service users; their home paths may intentionally be absent or nonstandard.

Findings: `missing` (no path), `symlink` (lstat sees a symlink), `not-directory`, `wrong-owner` (directory UID differs from passwd UID), and `world-writable` (directory grants write access to everyone). A missing, restricted, or shared home is not automatically an incident; examine local policy. An `lstat` failure other than missing files is an **error**, making the report incomplete. The program never follows a home symlink or changes filesystem objects. NSS-only or LDAP accounts are not included in a local file scan.

Human output: `ISSUE USER UID HOME` tab-separated with escaped controls; `--null` produces exact NUL-separated records with no header/summary. Exit 0 after a complete read (findings do not change status), 1 for malformed passwd records or access errors, 2 bad options, 3 missing file or bundled Perl library. Depends on Perl core modules and `SASD::Freeware::Account`, no CPAN downloads.
