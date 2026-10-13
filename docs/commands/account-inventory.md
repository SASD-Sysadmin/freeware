# account-inventory

[Deutsch](account-inventory.de.md) · [Project](../../README.md)

`account-inventory` inventories users and groups from an explicitly selected **local file** or the current host's **NSS enumeration**. It never changes accounts, permissions, or home directories.

## Examples

```sh
./bin/account-inventory
./bin/account-inventory --kind users
./bin/account-inventory --source nss --kind groups
./bin/account-inventory --source local --passwd-file ./passwd.sample --group-file ./group.sample
./bin/account-inventory --kind users --null > inventory.bin
```

## Sources and limitations

- **`--source local` (default on Linux/other Unix)**: parses `/etc/passwd` and `/etc/group` (or the chosen `--passwd-file` / `--group-file`). This is *only* the local text database, not all identities accepted by the host.
- **`--source nss`**: invokes Perl's native `getpwent` / `getgrent` interfaces. Returned accounts may come from `files`, NIS, LDAP, or other NSS sources, depending on host configuration. **Enumeration is not proof of completeness**: some sources support individual lookups but not complete enumeration. No direct NIS, NIS+, or LDAP protocol implementation is bundled.
- NIS compatibility entries beginning with `+` or `-` in local files are **identified and skipped**, never mistaken for real local accounts. Malformed local records cause exit 1 with a diagnostic.
- **macOS default is `--source nss`** because `/etc/passwd` and `/etc/group` are not the authoritative Open Directory identity database. Explicit file overrides imply the local source unless `--source nss` is also specified (which is rejected). On macOS, explicitly requesting default local files emits an incompleteness warning.
- `--passwd-file` and `--group-file` are available for the local source only. On Linux/other Unix, NSS requires explicit `--source nss`.

## Output

Tab-delimited columns `TYPE NAME UID GID HOME SHELL MEMBERS`. User rows leave `MEMBERS` empty, group rows leave `UID`, `HOME`, and `SHELL` empty. Special characters are escaped as `\xHH` in the human-readable output. `--null` outputs seven raw NUL-separated fields per record, including empty fields, without headers or totals; filenames are not involved. Avoid publishing inventories with internal names and home locations.

## Requirements and status

Perl 5 with core `Getopt::Long`, `FindBin` and bundled `SASD::Freeware::Account` (no CPAN dependencies). NSS mode uses the host's configured name service; its reliability depends on that service. Exit 0 for a completed local parse (NSS call completed), 1 for malformed local records, 2 for bad arguments, 3 for unavailable input/module. An NSS exit 0 **does not certify an exhaustive inventory**.
