# Changelog

Significant changes to this repository are documented here. Dates use ISO 8601 format.

## [Unreleased]

### Added

- `quota-status` for non-mutating Linux quota activation status via native `quotaon -p`.
- `quota-set` for explicit, validated Linux user/group quota limits with read-only preview, separate apply confirmation, unlimited-value acknowledgment and mountpoint checks.
- English/German command guides, section 1/8 manual pages and isolated regression tests for quota administration.

### Changed

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
