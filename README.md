# SASD Freeware

**English** | [Deutsch](README.de.md) · [MIT License](LICENSE) · [Contributing](CONTRIBUTING.md) · [Changelog](CHANGELOG.md) · [Roadmap](docs/ROADMAP.md) · [Platform support](docs/PLATFORMS.md) · [Privileged safety](docs/PRIVILEGED-SAFETY.md) · [Release engineering](docs/RELEASE-ENGINEERING.md)

SASD Freeware provides a collection of command-line utilities, scripts, and libraries for Linux and Unix system administration. The tools are designed for reliable operation, straightforward integration into existing environments, and long-term maintainability. Each utility includes documentation, practical usage examples, and automated tests.

## Included utilities

| Command | Location | Purpose | Documentation |
| --- | --- | --- | --- |
| `db-probe` | [`bin/db-probe`](bin/db-probe) | Verify SQL connectivity, database identity and server version (M5.1). | [Guide](docs/commands/db-probe.md) · [Deutsch](docs/commands/db-probe.de.md) · [Manpage](man/man1/db-probe.1) |
| `db-health` | [`bin/db-health`](bin/db-health) | Read-only SQL connection/activity/uptime snapshot (M5.2). | [Guide](docs/commands/db-health.md) · [Deutsch](docs/commands/db-health.de.md) · [Manpage](man/man1/db-health.1) |
| `db-activity` | [`bin/db-activity`](bin/db-activity) | Bounded read-only SQL session activity, waits and lock hints (M5.3). | [Guide](docs/commands/db-activity.md) · [Deutsch](docs/commands/db-activity.de.md) · [Manpage](man/man1/db-activity.1) |
| `db-storage` | [`bin/db-storage`](bin/db-storage) | Read-only MariaDB/MySQL database and top-table storage metadata (M5.4). | [Guide](docs/commands/db-storage.md) · [Deutsch](docs/commands/db-storage.de.md) · [Manpage](man/man1/db-storage.1) |
| `session-report` | [`bin/session-report`](bin/session-report) | Inventory interactive login sessions (Chapter 4). | [Guide](docs/commands/session-report.md) · [Deutsch](docs/commands/session-report.de.md) · [Manpage](man/man1/session-report.1) |
| `process-report` | [`bin/process-report`](bin/process-report) | Inventory processes by user and state (Chapter 4). | [Guide](docs/commands/process-report.md) · [Deutsch](docs/commands/process-report.de.md) · [Manpage](man/man1/process-report.1) |
| `login-audit` | [`bin/login-audit`](bin/login-audit) | Review Linux login and failed-login history (Chapter 4); ISO-format fixture input on other platforms. | [Guide](docs/commands/login-audit.md) · [Deutsch](docs/commands/login-audit.de.md) · [Manpage](man/man1/login-audit.1) |
| `core-report` | [`bin/core-report`](bin/core-report) | Inventory files with core-dump-style names, including logical sizes. | [Guide](docs/commands/core-report.md) · [Deutsch](docs/commands/core-report.de.md) · [Manpage](man/man1/core-report.1) |
| `path-audit` | [`bin/path-audit`](bin/path-audit) | Identify pathnames exceeding configured byte limits. | [Guide](docs/commands/path-audit.md) · [Deutsch](docs/commands/path-audit.de.md) · [Manpage](man/man1/path-audit.1) |
| `link-audit` | [`bin/link-audit`](bin/link-audit) | Inventory dangling, looping and unresolved symbolic links. | [Guide](docs/commands/link-audit.md) · [Deutsch](docs/commands/link-audit.de.md) · [Manpage](man/man1/link-audit.1) |
| `owner-audit` | [`bin/owner-audit`](bin/owner-audit) | Report file UIDs/GIDs not resolved by the host name service. | [Guide](docs/commands/owner-audit.md) · [Deutsch](docs/commands/owner-audit.de.md) · [Manpage](man/man1/owner-audit.1) |
| `permission-audit` | [`bin/permission-audit`](bin/permission-audit) | Report world-writable filesystem entries. | [Guide](docs/commands/permission-audit.md) · [Deutsch](docs/commands/permission-audit.de.md) · [Manpage](man/man1/permission-audit.1) |
| `rotate` | [`bin/rotate`](bin/rotate) | Preserve up to ten generations of a regular file (`.0` newest, `.9` oldest). | [Guide](docs/commands/rotate.md) · [Deutsch](docs/commands/rotate.de.md) · [Manpage](man/man1/rotate.1) |
| `fs-report` | [`bin/fs-report`](bin/fs-report) | Directory inventory and logical file sizes. | [Guide](docs/commands/fs-report.md) · [Deutsch](docs/commands/fs-report.de.md) · [Manpage](man/man1/fs-report.1) |
| `largefiles` | [`bin/largefiles`](bin/largefiles) | Find large regular files. | [Guide](docs/commands/largefiles.md) · [Deutsch](docs/commands/largefiles.de.md) · [Manpage](man/man1/largefiles.1) |
| `fs-usage` | [`bin/fs-usage`](bin/fs-usage) | Check mounted filesystem capacity using df. | [Guide](docs/commands/fs-usage.md) · [Deutsch](docs/commands/fs-usage.de.md) · [Manpage](man/man1/fs-usage.1) |
| `quota-report` | [`bin/quota-report`](bin/quota-report) | Query user, group, and filesystem quota reports. | [Guide](docs/commands/quota-report.md) · [Deutsch](docs/commands/quota-report.de.md) · [Manpage](man/man1/quota-report.1) |
| `quota-status` | [`bin/quota-status`](bin/quota-status) | Show Linux quota activation status using native `quotaon -p`. | [Guide](docs/commands/quota-status.md) · [Deutsch](docs/commands/quota-status.de.md) · [Manpage](man/man1/quota-status.1) |
| `quota-set` | [`sbin/quota-set`](sbin/quota-set) | Preview or explicitly apply complete Linux user/group quotas. | [Guide](docs/commands/quota-set.md) · [Deutsch](docs/commands/quota-set.de.md) · [Manpage](man/man8/quota-set.8) |
| `hosts-lint` | [`bin/hosts-lint`](bin/hosts-lint) | Validate hosts-file syntax without changes. | [Perl guide](docs/commands/perl-tools.md) · [Manpage](man/man1/hosts-lint.1) |
| `nss-lookup` | [`bin/nss-lookup`](bin/nss-lookup) | Resolve a targeted user/group through libc/NSS. | [Guide](docs/commands/nss-lookup.md) · [Deutsch](docs/commands/nss-lookup.de.md) · [Manpage](man/man1/nss-lookup.1) |
| `host-resolve` | [`bin/host-resolve`](bin/host-resolve) | Forward/reverse host resolution via the OS resolver (not DNS-specific). | [Guide](docs/commands/host-resolve.md) · [Deutsch](docs/commands/host-resolve.de.md) · [Manpage](man/man1/host-resolve.1) |
| `ldap-probe` | [`bin/ldap-probe`](bin/ldap-probe) | Anonymous LDAPS rootDSE probe via optional ldapsearch client. | [Guide](docs/commands/ldap-probe.md) · [Deutsch](docs/commands/ldap-probe.de.md) · [Manpage](man/man1/ldap-probe.1) |
| `nsswitch-audit` | [`bin/nsswitch-audit`](bin/nsswitch-audit) | Audit Linux-style NSS switch-file structure and actions. | [Guide](docs/commands/nsswitch-audit.md) · [Deutsch](docs/commands/nsswitch-audit.de.md) · [Manpage](man/man1/nsswitch-audit.1) |
| `dns-query` | [`bin/dns-query`](bin/dns-query) | Direct DNS queries via optional dig (not libc resolver). | [Guide](docs/commands/dns-query.md) · [Deutsch](docs/commands/dns-query.de.md) · [Manpage](man/man1/dns-query.1) |
| `nis-probe` | [`bin/nis-probe`](bin/nis-probe) | Check local NIS/YP server binding without reading maps. | [Guide](docs/commands/nis-probe.md) · [Deutsch](docs/commands/nis-probe.de.md) · [Manpage](man/man1/nis-probe.1) |
| `ldap-config-audit` | [`bin/ldap-config-audit`](bin/ldap-config-audit) | Audit OpenLDAP client TLS configuration without disclosing values. | [Guide](docs/commands/ldap-config-audit.md) · [Deutsch](docs/commands/ldap-config-audit.de.md) · [Manpage](man/man1/ldap-config-audit.1) |
| `account-inventory` | [`bin/account-inventory`](bin/account-inventory) | Inventory local passwd/group data or NSS-enumerated identities. | [Guide](docs/commands/account-inventory.md) · [Deutsch](docs/commands/account-inventory.de.md) · [Manpage](man/man1/account-inventory.1) |
| `group-audit` | [`bin/group-audit`](bin/group-audit) | Read-only local group-file structure and membership audit. | [Guide](docs/commands/group-audit.md) · [Deutsch](docs/commands/group-audit.de.md) · [Manpage](man/man1/group-audit.1) |
| `home-audit` | [`bin/home-audit`](bin/home-audit) | Check home directory metadata from local/NSS identities. | [Guide](docs/commands/home-audit.md) · [Deutsch](docs/commands/home-audit.de.md) · [Manpage](man/man1/home-audit.1) |
| `account-manage` | [`sbin/account-manage`](sbin/account-manage) | Guarded, preview-first local Linux account operations. | [Guide](docs/commands/account-manage.md) · [Deutsch](docs/commands/account-manage.de.md) · [Manpage](man/man8/account-manage.8) |
| `account-audit` | [`bin/account-audit`](bin/account-audit) | Structural audit of a Unix passwd file. | [Perl guide](docs/commands/perl-tools.md) · [Manpage](man/man1/account-audit.1) |
| `log-summary` | [`bin/log-summary`](bin/log-summary) | Count log entries by severity markers. | [Perl guide](docs/commands/perl-tools.md) · [Manpage](man/man1/log-summary.1) |
| `ssh-key-audit` | [`bin/ssh-key-audit`](bin/ssh-key-audit) | Read-only OpenSSH authorized_keys review. | [Automation guide](docs/commands/automation-tools.md) · [Manpage](man/man1/ssh-key-audit.1) |
| `file-integrity` | [`bin/file-integrity`](bin/file-integrity) | Explicit SHA-256 baseline creation and comparison. | [Automation guide](docs/commands/automation-tools.md) · [Manpage](man/man1/file-integrity.1) |
| `suid-audit` | [`bin/suid-audit`](bin/suid-audit) | SUID/SGID permissions inventory. | [Automation guide](docs/commands/automation-tools.md) · [Manpage](man/man1/suid-audit.1) |
| `tcp-check` | [`bin/tcp-check`](bin/tcp-check) | Single TCP endpoint test; optional Nagios exit codes. | [Automation guide](docs/commands/automation-tools.md) · [Manpage](man/man1/tcp-check.1) |

Example: `rotate /etc/hosts` creates `/etc/hosts.0` without modifying `/etc/hosts`; running it again moves the previous `.0` to `.1` and creates a new `.0`. The oldest `.9` is removed on subsequent rotations. `rotate` is a **file snapshot helper**, not a replacement for scheduled log rotation, version control, or a complete backup strategy.

## Repository layout

```text
freeware/
├── bin/               User commands (rotate and Perl tools)
├── sbin/              Administrative commands (quota-set)
├── lib/               Architecture-independent libraries
├── lib64/             64-bit libraries (reserved)
├── man/
│   ├── man1/          User-command manual pages
│   └── man8/          Administrative-command manual pages
├── tests/             Automated command tests (repository checkout)
├── .github/workflows/ CI tests (repository checkout)
├── docs/              Documentation and maintenance information
│   ├── commands/      English and German command guides
│   └── DEVELOPMENT.*   Development and maintenance guidelines
├── Makefile           Test/install/uninstall targets
├── README.md          English project documentation
└── README.de.md       German project documentation
```

Installed commands and guides use matching paths below the chosen `PREFIX`. Tests, CI files and development guidelines remain in the checkout. `lib64` is a reserved convention, not a guarantee that every platform uses a separate `lib64` directory. Git cannot track truly empty directories, so reserved ones contain `.gitkeep` files.

## Requirements

- Unix-like operating system with **Bash**, `cp`, `mv`, `rm`, `mkdir`, `rmdir`, and `mktemp` (Linux is tested locally; CI is configured for Ubuntu and macOS).
- Write permission in the directory of the file to be rotated.
- `git` for cloning; `make` and `install` for optional staged deployment.
- `rotate` needs Bash, not Perl. The Perl tools require Perl 5.8 or later and their bundled modules in `lib/`. `fs-usage` additionally requires a POSIX-compatible `df`; `quota-report` requires native `quota` or `repquota`; on Linux, `quota-status` requires `quotaon` with `-p` and applying limits with `quota-set` requires `setquota` and an active quota configuration. No CPAN downloads are required. `host-resolve` requires the Socket getaddrinfo/getnameinfo APIs (typically Perl 5.14+), and `ldap-probe` optionally requires an installed OpenLDAP `ldapsearch` client. `dns-query` requires optional `dig`, `nis-probe` optional `ypwhich`; config audits only read supplied text files. Name-service probes are read-only but can generate network traffic.

## Installation

### Recommended: clone and install only distributable files

```sh
git clone https://github.com/SASD-Sysadmin/freeware.git
cd freeware
make test
sudo make install PREFIX=/usr/freeware
```

This installs executable commands, manual pages, and user guides under `/usr/freeware/docs/commands/` (or the selected `PREFIX`). Tests and Git metadata remain in the checkout. Set `DESTDIR` for packaging or staging, for example `make install DESTDIR=/tmp/package PREFIX=/usr/freeware`.

### Alternative: use a checkout directly from /usr/freeware

A checkout can also live at `/usr/freeware`, retaining the complete repository layout. Do not use a root-owned working tree for day-to-day development or run unreviewed code as root. Manage ownership and updates in accordance with your site's policy.

Add the following to your shell startup file (for example `~/.bashrc`):

```sh
export PATH="/usr/freeware/bin:/usr/freeware/sbin:$PATH"
export MANPATH="/usr/freeware/man:${MANPATH:-}"
```

On systems that already manage manual paths, `man -M /usr/freeware/man rotate` works without changing the shell configuration. For a checkout elsewhere, invoke `./bin/rotate` directly or adapt the paths above.

## Usage

```sh
rotate ./settings.conf
rotate '/path/with spaces/hosts copy'
# Protected system files typically require elevated privileges:
sudo /usr/freeware/bin/rotate /etc/hosts
man -M /usr/freeware/man rotate
```

`rotate` requires **exactly one** argument: the path of an existing regular file (not a symbolic link). Backups are written next to the source. The command requires permission to create, rename, and delete entries in that directory, and it refuses unexpected non-file entries in `.0` through `.9`. Only matching numeric files `.10`, `.11`, etc. are removed as legacy versions; names such as `.01` or `.10.notes` are left alone.

A short-lived directory named `FILE.rotate.lock` prevents concurrent cooperating rotations. If a process is forcibly terminated, inspect the directory before deleting a stale lock. Rotations are **not transactionally atomic**: interruption during renames can leave gaps; always check critical backups. Copied file permissions and timestamps are preserved by `cp -p`, subject to OS and user privileges. Backup files may contain secrets; secure their parent directory.

For detailed command instructions, see [rotate](docs/commands/rotate.md), [core-report](docs/commands/core-report.md), [path-audit](docs/commands/path-audit.md), [filesystem and account tools](docs/commands/perl-tools.md), and [SSH, integrity and monitoring tools](docs/commands/automation-tools.md). Development and maintenance guidelines are available in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Development and verification

**Verification:** `make test` performs offline unit and regression tests. `make integration-test` adds opt-in loopback DNS and LDAPS protocol tests with native clients. GitHub Actions enforces both under Ubuntu and DNS under macOS. See [Testing](docs/TESTING.md), [Return codes](docs/EXIT-CODES.md) and the [platform matrix](docs/PLATFORMS.md). The loopback fixtures are not production DNS/LDAP servers.

```sh
make test
make integration-test  # opt-in; optional native dig/ldapsearch clients
bash -n bin/rotate
```

The automated test suites cover backup rotation, filesystem inventories, path audits, hosts, accounts, log summaries, SSH key checks, SHA-256 integrity tracking, privileged file inventory, TCP checks, and failure cases. GitHub Actions is configured to run `make test` on Ubuntu and macOS for pushes and pull requests; this does not imply a successful CI run until GitHub reports one.

## Contributing, licensing, and security

See [CONTRIBUTING.md](CONTRIBUTING.md) for file locations, contribution practices, and tests; [SECURITY.md](SECURITY.md) for security reporting; and [CHANGELOG.md](CHANGELOG.md) for project history. The repository is licensed under the [MIT License](LICENSE). Review individual tool requirements before executing commands with elevated privileges.

**Project:** [github.com/SASD-Sysadmin/freeware](https://github.com/SASD-Sysadmin/freeware)
