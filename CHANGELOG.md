# Changelog

Significant changes to this repository are documented here. Dates use ISO 8601 format.

## [Unreleased]

### Chapter 10 – Security and Network Monitoring (M8.4.2, BSD firewall inventory)

- Add independently testable PF status/main filter, FreeBSD IPFW static listing
  and NetBSD NPF status/configuration parsers in `FirewallBSD.pm`.
- Use fixed read-only native commands only on supported BSD platform families;
  retain portable offline `--input` replay and the eight-field output schema.
- Explicitly mark incomplete PF/IPFW listings PARTIAL, keep NPF filtering
  separate from loaded configuration, and avoid leaking individual rules.
- Add 225 hostile-input/offline tests, bilingual guide updates and CI staging
  coverage for the new library module; native BSD acceptance remains open.

### Chapter 10 – Security and Network Monitoring (M8.4.1, Linux firewall inventory)

- Add `firewall-config-audit` with pure, bounded, source-specific UFW status/config,
  nftables JSON and IPv4/IPv6 iptables-save parsers.
- Keep management configuration, UFW runtime status and kernel rulesets separate;
  never infer whole-host firewall protection or count overlapping backends.
- Redact individual rules, reject incomplete snapshots before output, add
  DE/EN guides, manpage, hostile-input tests and staged CI installation checks.

### Chapter 10 – Security and Network Monitoring (M8.3, local sockets)

- Add read-only `network-service-report` for local TCP LISTEN sockets and
  unconnected UDP BOUND endpoints; do not claim external reachability.
- Separate fixed-path Linux ss/macOS-BSD netstat acquisition from a pure,
  bounded Perl parser with strict address, port, family and state validation.
- Preserve unknown family on ambiguous wildcard-only ss rows; never invent
  process ownership, connection state or destination exposure.
- Add DE/EN guides, manpage, synthetic security regression tests and
  staged Ubuntu/macOS installation checks; native BSD acceptance is pending.

### Chapter 10 – Security and Network Monitoring (M8.2, route inventory)

- Add read-only `network-route-report` with a standalone pure network-route
  parser and separate Linux iproute2 JSON and macOS/BSD netstat decoding.
- Preserve IPv4/IPv6 provenance for default routes, gateways, devices,
  routing-table/metric metadata, and validated text/NUL output.
- Reject ambiguous multi-next-hop and incomplete snapshots rather than
  silently manufacturing reachability or route-completeness claims.
- Add DE/EN guides, manpage, synthetic negative/positive regression tests
  and Ubuntu/macOS staged installation assertions; native acceptance pending.

### Chapter 10 – Security and Network Monitoring (M8.1, network interfaces)

- Add read-only `network-interface-report` with a distinct pure parser module for
  bounded Linux iproute2 JSON and macOS-style ifconfig snapshots.
- Report validated IPv4/IPv6 addresses, CIDR prefixes, Ethernet MACs and
  interface state via TSV/NUL, including addressless interfaces.
- Add DE/EN command guides, manpage, synthetic positive/negative tests and
  Ubuntu/macOS staged installation checks. Native BSD acceptance remains open.

### Chapter 9 – Log Files (M7.5, normalized summary contract)

- Add read-only `log-summary-normalize` for exact TSV/NUL ingestion of
  M7.1–M7.4 reports with stable, source-tagged `sasd.log-summary.v1` JSONL.
- Reconcile every category against TOTAL before output; reject malformed,
  truncated and inconsistent reports without partial disclosure.
- Record that source summaries can overlap: no deduplication, timestamps,
  event-level correlation or distinct-incident totals are claimed.
- Add DE/EN guides, manpage, offline regression/compatibility tests and
  Ubuntu/macOS staged installation checks.

### Chapter 9 – Log Files (M7.4, offline sudo/su/PAM patterns)

- Add read-only `auth-event-summary` for bounded offline sudo, su and selected
  pam_unix message-pattern counts in traditional syslog exports.
- Keep command logs, explicit su authentication messages, PAM sessions,
  unrecognized authentication messages and unsupported envelopes distinct.
- Add DE/EN docs, manpage, negative/positive offline tests and staged
  Ubuntu/macOS installation checks; native host-log acceptance is pending.

### Chapter 9 – Log Files (M7.3, offline SSHD authentication patterns)

- Add read-only `ssh-auth-summary` for bounded, privacy-preserving
  aggregation of OpenSSH sshd message patterns in RFC3164-like local logs.
- Keep recognized SSHD patterns, other-service lines and unsupported
  envelopes distinct; no claim of unique logins or verified incidents.
- Add DE/EN guides, a manpage, offline negative/positive tests and
  Ubuntu/macOS staging checks. Native host-log acceptance remains open.

### Chapter 9 – Log Files (M7.2, offline structured syslog summary)

- Add read-only `syslog-summary` for bounded RFC3164/RFC5424 priority
  aggregation without MESSAGE-based severity guessing or data disclosure.
- Count absent or unverifiable PRI as UNKNOWN; reject incomplete and
  oversized inputs without partial output.
- Add synthetic negative/positive tests, bilingual guides, manpage and
  Ubuntu/macOS staged installation/uninstallation checks.

### Chapter 9 – Log Files (M7.1, offline systemd journal summary)

- Add `journal-summary`: bounded structured `journalctl --output=json`
  priority aggregation in Perl. No native journal access or message disclosure.
- Add offline positive/negative regression tests, bilingual guides, a
  manpage and Ubuntu/macOS staged installation checks.
- Document limits and remaining Linux/macOS live journal integration gaps.

### Chapter 8 – Electronic Mail (M6, limited native Postfix evidence)

- Record operator-observed Debian 12/Postfix 3.7.11 live checks from
  2026-10-20: empty queue, static audit, positive and negative STARTTLS.
- Do not claim effective master.cf override review, populated queue,
  isolated lab VM or 465/IPv6 acceptance; record MTA replacement caveat.

### Chapter 8 – Electronic Mail (M6.4, offline acceptance foundation)

- Add a cross-tool mail workflow regression suite for safe and negative
  synthetic Postfix/SMTP inputs, exit codes, privacy and NUL formats.
- Add bilingual manual acceptance guides for native Postfix and verified
  STARTTLS, with a clear distinction between offline CI and live checks.
- Integrate the new guides into installation and Ubuntu/macOS CI.
  Real Postfix acceptance and implicit TLS/IPv6 are still open.

### Chapter 8 – Electronic Mail (M6.3, static Postfix config audit)

- Add read-only `mail-config-audit` for bounded static main.cf checks
  with optional master.cf override discovery and no value disclosure.
- Review relay boundaries, broad `mynetworks` trust, SASL/TLS
  exposure risks and structural errors without claiming live certainty.
- Add offline positive/negative fixtures, DE/EN guides, a manpage
  and staged installation tests on Ubuntu/macOS. Real Postfix
  validation and effective service/default analysis remain open.

### Chapter 8 – Electronic Mail (M6.2, Postfix queue snapshot)

- Add read-only `mail-queue` using only `postqueue -j` (Postfix 3.1+),
  with aggregate message/byte/recipient totals and no address disclosure.
- Bound runtime, output and record counts; classify deferred/hold/unknown
  queues, incomplete JSON, and native failures with explicit exit codes.
- Add 122+ offline positive/negative tests, bilingual guides, a manpage
  and Ubuntu/macOS CI staged-installation assertions. Live Postfix
  acceptance remains an explicit follow-up.

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
