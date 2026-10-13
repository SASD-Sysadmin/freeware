# Platform support and scope

[Deutsch](PLATFORMS.de.md) · [Project](../README.md)

SASD Freeware is tested with GitHub Actions on Ubuntu Linux and macOS. **Passing tests confirms tested behaviors, not complete operating-system coverage**. The active CI matrix is in `.github/workflows/ci.yml`.

| Area | Linux | macOS | Limitation |
| --- | --- | --- | --- |
| Read-only filesystem inventories and audits | Automated tests | Automated tests | APFS ACLs, TCC/Full Disk Access and snapshots are not audited; restricted paths may report incomplete scans. |
| `rotate`, file integrity, SSH/host syntax, TCP and logs | Automated tests | Automated tests | Review paths, permissions and the installed native utilities on the target host. |
| `fs-usage`, `quota-report` | Host-dependent native commands | Host-dependent native commands | `df`, `quota`, `repquota` syntax and availability vary. No native quota compatibility guarantee. |
| `account-inventory` | Local files default; NSS selectable | NSS default; local text explicitly selectable | NSS enumeration need not include every directory identity; direct lookups can succeed when enumeration omits entries. |
| `home-audit` | Local files default; UID >= 1000 | NSS default; UID >= 500 | UID thresholds are policies, not identities; macOS ACLs and privacy controls are out of scope. |
| `group-audit` / `account-audit` | Unix-format text files | Unix-format text files only | On macOS `/etc/passwd` and `/etc/group` are not an authoritative Open Directory inventory. |
| `account-manage` | Linux only; dry-run by default and guarded writes | Unsupported, including previews | Never administers Directory Services / LDAP / NIS directly. |
| `quota-status`, `quota-set` writes | Linux-only | Unsupported | Linux `quotaon -p`, `setquota` and `/proc` required as documented. |

## Read-only sanity checks on macOS

```sh
make test
./bin/account-inventory --kind users
./bin/account-inventory --source nss --kind groups
./bin/home-audit
./bin/link-audit "$HOME"
./bin/permission-audit "$HOME"
./sbin/account-manage --action group-create --name example_group  # exits 3: Linux-only
```

Use native macOS tools such as `dscl` and `sysadminctl` for real local account administration; this repository does not wrap them yet. Never run `--apply` with any manager until separately validated on an isolated, supported test machine. Permission or access failures must not be reinterpreted as zero findings. macOS deployment beneath `/usr/freeware` has not been verified across all System Integrity Protection configurations.
