# Changelog

Significant changes to this repository are documented here. Dates use ISO 8601 format.

## [Unreleased]

### Chapter 8 – Electronic Mail (M6.1, SMTP STARTTLS probe)

- Add read-only `mail-probe` for bounded SMTP banner, EHLO and post-TLS
  capability checks with mandatory certificate and server-name verification.
- Explicitly fail for missing STARTTLS, rejected or malformed SMTP replies,
  invalid certificates, unavailable TLS dependencies and timeouts.
- Add offline loopback SMTP/TLS tests, bilingual guides, a manpage and staged
  installation assertions. No AUTH, mail submission or public SMTP scanning.

### Chapter 7 – SQL Administration (M5.4, table storage metadata)

- Add read-only `db-storage` for MariaDB/MySQL selected-database and
  visible base-table size estimates with full-summary and bounded top N.
- Explicitly flag unknown NULL statistics, restrict native clients,
  enforce verified TCP TLS, and never accept arbitrary SQL or passwords.
- Add offline positive/negative regression tests, DE/EN guides,
  manpage and Ubuntu/macOS staged-installation checks.

### Chapter 7 – SQL Administration (M5.3, session activity)

- Add read-only `db-activity` snapshots of visible sessions and wait hints for
  PostgreSQL, MySQL and MariaDB, with capped rows and nonzero truncated status.
- PostgreSQL validates `pg_read_all_stats` and uses `pg_blocking_pids()` for real
  blocker counts; MySQL/MariaDB label process-list lock signals as hints only.
- Never retrieve SQL text or client addresses; add offline failure/security
  regression tests, DE/EN guides, manpage and CI installation checks.

### Chapter 7 – SQL Administration (M5.2, server health)

- Add read-only `db-health` for PostgreSQL, MySQL and MariaDB: bounded native-client
  snapshots of connections, active activity and server uptime.
- Require effective `pg_read_all_stats` for accurate PostgreSQL cluster-wide
  activity; MySQL/MariaDB use unprivileged global status counters.
- Document cross-engine semantics, minimum rights and safe credentials in
  bilingual guides/manpage; add 120 offline negative/positive checks and CI staging.

### Chapter 7 – SQL Administration (M5.1)

- Add read-only `db-probe` for PostgreSQL, MySQL and MariaDB, using fixed
  identity/version SQL and native clients without shell or password argv.
- Require verified TLS for explicit TCP targets, bound execution/output,
  private MySQL/MariaDB credential files and explicit error classification.
- Add offline mock-client regression tests, DE/EN guides, manpage and CI
  staged install/remove assertions; Oracle and SQL Server remain planned.

### Chapter 4 – User Activity (M4, login history)

- Add Linux-only read-only `login-audit` for bounded util-linux `last`/`lastb` ISO-format history review.
- Support explicit saved-text fixtures on Linux/macOS, account filters, NUL-delimited output, explicit missing-source failures, and offline regression tests.
- Document retention, permissions, completeness and native macOS limitations in EN/DE guides, manpage and chapter roadmap.

### Chapter 4 – User Activity (M4, first increment)

- Add read-only `session-report` (current login sessions) and `process-report` (process snapshot) with safe fixture inputs, filters, and NUL-record formats.
- Add 55 fixture/smoke tests, English/German command guides, manual pages, and explicit Linux/macOS limitations.
- Switch development planning to a chapter coverage matrix; login history, SQL, mail, logs, and monitoring remain open.

### Release engineering (M3 work in progress)

- Replace checkout-list-based install/uninstall with a versioned, SHA-256-verified ownership manifest.
- Protect operator-modified/unowned files, remove obsolete managed files on upgrade, and stage updates with best-effort rollback.
- Add fixture-only install, upgrade, uninstall, path-safety and manifest-tampering tests plus bilingual release procedures.
- This does not publish a `v0.1.0` release or close the outstanding privileged VM acceptance.

### Privileged safety and isolated test boundaries

- Publish `file-integrity --init` baselines through a private staging file and atomic, no-overwrite hard-link step; existing manifests stay untouched after failed attempts.
- Add fixture-only security checks for account/quota approval, integrity-manifest protection, rotate copy failures and competing rotations.
- Document remaining non-transactional rotation risks and a snapshotted, human-approved Linux VM test plan in English and German.


### CLI and repository quality contracts

- Standardized side-effect-free `--help` and `--version` across the eight older commands.
- Added tests for all executable metadata interfaces, matching manpages, Markdown whitespace, unresolved link placeholders and Git-index document modes.
- Added ShellCheck to the Ubuntu CI job and clarified the macOS LDAPS skip policy.


### Tests and quality assurance

- Added opt-in loopback DNS (UDP) and LDAPS (TLS + LDAP) integration fixtures, exercised by native dig and ldapsearch clients when available.
- CI now requires DNS integration on Ubuntu and macOS, and LDAPS integration on Ubuntu; optional client absence is explicitly reported in local runs.
- Added a shared, tested 0/1/2/3 return-code convention for read-only name-service diagnostics.
- Added `dns-query --port 1..65535` for unprivileged local DNS integration without modifying system resolver configuration.
- Added bilingual integration-test and exit-code documentation.

### Added

- `nsswitch-audit` for structural, read-only Linux-style NSS source configuration checks.
- `dns-query` for direct DNS response/status diagnostics via optional `dig`, separate from system host resolution.
- `nis-probe` for local NIS/YP binding checks without fetching directory maps.
- `ldap-config-audit` for static OpenLDAP client certificate-policy inspection without revealing configuration values.
- Bilingual command guides, manual pages and offline regression tests for these diagnostics.

### Added

- Read-only `nss-lookup` for targeted libc name-service user/group queries (without claiming complete enumeration).
- `host-resolve` for system resolver forward/reverse IPv4/IPv6 diagnosis (distinct from direct DNS protocol testing).
- `ldap-probe` for anonymous LDAPS rootDSE metadata checks using an optional native ldapsearch client with certificate verification enforcement.
- Bilingual command documentation, manpages and isolated tests that require no external name-service server.

### Changed

- macOS now defaults to NSS enumeration for `account-inventory` and `home-audit`, avoiding false completeness from `/etc/passwd`; explicit local-file fixtures remain supported.
- `home-audit` accepts `--source local|nss`, uses macOS-appropriate default UID thresholds, and documents NSS enumeration limits.
- `account-manage` rejects non-Linux platforms even for preview, with an explicit error rather than interpreting macOS passwd/group compatibility files as Linux accounts.
- Added bilingual platform-support guidance and platform-aware regression tests.


### Added

- `account-inventory`: source-explicit local or NSS account/group inventory with unambiguous NUL output and NIS compatibility handling.
- `group-audit`: structural validation of local groups, shared IDs, duplicated members, and malformed entries.
- `home-audit`: local account home-directory metadata review with configurable UID selection.
- `account-manage`: preview-first, confirm-to-apply Linux local user/group creation and password locking; no remote directory writes.
- Bundled `SASD::Freeware::Account` parser, English/German usage guides, section 1/8 manpages, and isolated tests.


### Added

- `link-audit` inventories dangling, looping and unresolved symbolic links without following directory links.
- `owner-audit` reports file UID/GID identifiers unresolved by the current system name service.
- `permission-audit` inventories world-writable entries, distinguishing sticky directories.
- English and German command guides, section 1 manual pages and isolated filesystem regression tests.


### Added

- `quota-status` for non-mutating Linux quota activation status via native `quotaon -p`.
- `quota-set` for explicit, validated Linux user/group quota limits with read-only preview, separate apply confirmation, unlimited-value acknowledgment and mountpoint checks.
- English/German command guides, section 1/8 manual pages and isolated regression tests for quota administration.

### Changed

- Consolidated command guides under `docs/commands/`; installation now places guides under `PREFIX/docs/commands/`.
- Updated documentation links and maintenance guidelines to match the new layout.
- `make check` now syntax-checks executable Perl commands from both `bin/` and `sbin/`.

### Added

- `largefiles` for bounded largest-file lists or complete streamed scans, including unambiguous NUL-delimited pathname records.
- `fs-usage` for read-only portable `df` reports and utilization thresholds.
- `quota-report` for read-only user, group and administrative quota reports via native Unix utilities.
- Shared Perl filesystem traversal and executable discovery modules installed under `lib/`.
- Complete English/German operator guides, manpages and regression tests for the new filesystem commands.

### Changed

- `fs-report` now detects traversal failures, accepts one-filesystem scans and documents hard-link and size-accounting behavior.
- Installation includes shared Perl modules and `make check` validates program and library syntax.


- `core-report` and `path-audit` filesystem inventory commands, with individual guides, manual pages and automated tests.
- General-purpose Makefile for automatically discovering command tests and installable files.
- Development and maintenance guidelines in English and German.

- Four Perl utilities for SSH, integrity checks and service monitoring: `ssh-key-audit`, `file-integrity`, `suid-audit`, `tcp-check`.
- English/German automation-tool guide, four man pages, additional automated test suite, and development roadmap.
- Expanded Makefile to install, test, and uninstall all nine commands.

- Four Perl administration commands: `fs-report`, `hosts-lint`, `account-audit`, `log-summary`.
- English and German Perl command guides, Unix manual pages, and automated tests.
- Extended Makefile for installing/testing/uninstalling all five tools.

- First utility: `bin/rotate`, keeping ten numbered file snapshots.
- English and German documentation, including a Unix manual page.
- Portable Bash tests, an installation Makefile, and Ubuntu/macOS GitHub Actions configuration.
- Repository conventions, contribution guidelines, security guidance, and cross-platform ignore rules.

### Existing

- The repository's MIT License remains unchanged.
