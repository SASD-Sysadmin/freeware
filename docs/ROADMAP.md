# SASD Freeware – Technical inventory and prioritized roadmap

## Current chapter-based development plan (14 October 2026)

**Goal:** Complete useful administration tools for book chapters 2–10 before
considering the first release. The old engineering assessment retained below
is historical, **not** the active milestone sequence. M3 part 1 delivered the
safer installer; release artifacts and publication are intentionally deferred.
A chapter requires scoped behavior, platform boundaries, EN/DE guides, manpages,
and positive/negative tests before it can be considered complete.

| Chapter | Available coverage | Gaps | Status |
| --- | --- | --- | --- |
| **2 – Filesystem** | Inventory, permissions, links, quotas, integrity | Evaluate mounts, ACLs and storage diagnostics | Substantial, incomplete |
| **3 – User Accounts** | Inventory, group/home audits, guarded writes | Privileged VM acceptance, gap audit | Substantial, incomplete |
| **4 – User Activity** | `session-report`, `process-report`; `login-audit` (Linux `last`/`lastb`) | macOS native login history, attribution and completeness review | In progress |
| **5 – TCP/IP Name Services** | Hosts, DNS, NSS, resolver | Gap review and platform completion | Substantial, incomplete |
| **6 – Directory Services** | LDAPS/NIS diagnostics, TLS configuration audit | Scope/platform gap analysis | Partial |
| **7 – SQL Administration** | `db-probe` (M5.1), `db-health` (M5.2), `db-activity` (M5.3) for PostgreSQL/MySQL/MariaDB; MariaDB/MySQL `db-storage` (M5.4) | PostgreSQL storage backend, Oracle/SQL Server, MySQL blocker graph, growth reports and live cross-engine acceptance | In progress |
| **8 – Electronic Mail** | `mail-probe` (M6.1), `mail-queue` (M6.2), `mail-config-audit` (M6.3), offline workflow (M6.4); [manual partial lab test](MAIL-ACCEPTANCE.md) on Debian 12/Postfix 3.7.11 (20 Oct 2026) | Effective overrides, populated queue, isolated VM, IPv6/465, other platforms outstanding | M6 engineering scope delivered; operational gaps remain |
| **9 – Log Files** | `log-summary` (text), `journal-summary` (M7.1 JSONL priority), `syslog-summary` (M7.2 structured syslog), `ssh-auth-summary` (M7.3 offline SSHD), `auth-event-summary` (M7.4 offline sudo/su/PAM patterns) | Live adapters, other PAM services, native macOS Unified Log, cross-format completeness | In progress |
| **10 – Security and Network Monitoring** | SSH, SUID, integrity and TCP checks | Network, service and firewall inventory | Partial |

**Planned order:** M4 User Activity (live snapshots, then login history),
M5 SQL, M6 Mail, M7 Logs, M8 Security/Network, M9 chapter gap closure and
platform acceptance, M10 release artifacts. These are scope goals, not
commitments about dates or production readiness.

**M4 part 1 contract:** `session-report` uses `who`; `process-report` uses
`ps`. Both are read-only, run without root, and accept offline test fixtures
through `--input`. They are snapshots, not exhaustive history or guaranteed
coverage of remote/container identities. Tests must not change real users.
See [session guide](commands/session-report.md) and
[process guide](commands/process-report.md).

## Historical engineering assessment (13 October 2026)

Repository: https://github.com/SASD-Sysadmin/freeware
Analyzed main commit: `f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb`
Assessment date: 2026-10-13


> **Status:** Engineering review and planning document, now versioned in the repository. Based on the repository tree, README, changelog, platform and test guides, CI, Makefile, and selected implementations. Priorities are engineering recommendations; they are not statements that every possible defect has been reproduced.

## 1. Verified inventory

- **30 executable commands:** 28 under `bin/`, two under `sbin/`.
- **30 manual pages:** 28 section-1 and two section-8 pages.
- **50 command-guide files:** 25 English and 25 German; some guides cover multiple commands.
- **Three Perl modules:** `Account.pm`, `External.pm`, and `Walk.pm`.
- **Testing:** 12 Perl regression suites, one Bash test script, and one opt-in DNS/LDAPS integration suite.
- **CI:** Mandatory Ubuntu and macOS checks pass at the reviewed merge commit. Ubuntu runs native DNS and LDAPS integration; macOS requires DNS while intentionally skipping LDAPS.
- **Status:** MIT-licensed; changelog uses `Unreleased`; no GitHub Release entries were returned at the time of review.

### Side-effect legend

`R` locally read-only; `N` read-only probe that may access a network or name service; `W` intentionally writes in a designated mode; `P` privileged write that requires explicit confirmation. This is an operational summary, not an unconditional security guarantee.

## 2. Full command inventory

| Area | Command | Current purpose | Mode |
|---|---|---|---|
| Filesystem | [`core-report`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/core-report) | Core-dump-like filenames and sizes | `R` |
| Filesystem | [`path-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/path-audit) | Audit path lengths | `R` |
| Filesystem | [`link-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/link-audit) | Broken/cyclic symlinks | `R` |
| Filesystem | [`owner-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/owner-audit) | Unresolved UID/GID ownership | `R` |
| Filesystem | [`permission-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/permission-audit) | Find world-writable entries | `R` |
| Filesystem | [`fs-report`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/fs-report) | Inventory directories and logical sizes | `R` |
| Filesystem | [`largefiles`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/largefiles) | Discover large files | `R` |
| Filesystem | [`fs-usage`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/fs-usage) | Filesystem utilization and thresholds | `R` |
| Filesystem | [`suid-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/suid-audit) | Inventory SUID/SGID files | `R` |
| Filesystem | [`file-integrity`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/file-integrity) | Create/check SHA-256 baseline | `W*` |
| Identity | [`account-inventory`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/account-inventory) | Inventory local/NSS identities | `R` |
| Identity | [`group-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/group-audit) | Validate group records | `R` |
| Identity | [`home-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/home-audit) | Audit home directory metadata | `R` |
| Identity | [`account-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/account-audit) | Audit account-file structure | `R` |
| Identity | [`account-manage`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/sbin/account-manage) | Linux user/group creation, password locking | `P` |
| Network | [`hosts-lint`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/hosts-lint) | Check hosts-file structure | `R` |
| Network | [`nss-lookup`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/nss-lookup) | Targeted NSS identity lookups | `R` |
| Network | [`host-resolve`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/host-resolve) | OS resolver forward/reverse queries | `N` |
| Network | [`ldap-probe`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/ldap-probe) | Anonymous LDAPS rootDSE query | `N` |
| Network | [`nsswitch-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/nsswitch-audit) | Check NSS switch syntax | `R` |
| Network | [`dns-query`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/dns-query) | Direct DNS query via dig | `N` |
| Network | [`nis-probe`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/nis-probe) | Check local NIS/YP binding | `N` |
| Network | [`ldap-config-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/ldap-config-audit) | Static OpenLDAP TLS client-config audit | `R` |
| Network | [`tcp-check`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/tcp-check) | Test TCP reachability | `N` |
| Quotas | [`quota-report`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/quota-report) | Quota reporting | `R` |
| Quotas | [`quota-status`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/quota-status) | Read Linux quota state | `R` |
| Quotas | [`quota-set`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/sbin/quota-set) | Set Linux quota limits | `P` |
| Logs/SSH | [`log-summary`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/log-summary) | Summarize logs by severity | `R` |
| Logs/SSH | [`ssh-key-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/ssh-key-audit) | Audit OpenSSH authorized_keys | `R` |
| Backup | [`rotate`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/rotate) | Rotate 10 file snapshots | `W` |

`file-integrity` reads when checking and creates a baseline only with `--init`. `rotate` writes snapshots. `account-manage` and `quota-set` have explicit apply/confirmation controls and must receive additional privileged-operation validation.

## 3. Coverage and remaining gaps

| Area | Current coverage | Gap | Priority |
|---|---|---|---|
| Filesystems | Rich read-only inspection, quotas, SHA-256 manifests | Mounts, ACLs, disk health, tamper-resistant baselines | P2 |
| Accounts | Local and NSS inventories; scoped Linux writes | No recurring realistic privileged integration test | P0 |
| Networking | DNS, NSS, LDAP, NIS, TCP | Interface/route/firewall reporting, native macOS LDAPS CI | P1/P2 |
| Processes and services | TCP probe | No process/service inventories | P2 |
| Logs | Severity counts | No structured journal/syslog adapters or history | P2 |
| Software lifecycle | Not covered | Package/update status | P3 |
| Backup | Ten single-file rotation snapshots | No end-to-end backup/restore system; nontransactional rotation | P1/P3 |
| OS portability | Ubuntu and macOS CI, local Debian/WSL testing | No verified FreeBSD/OpenBSD or true privileged quota/user-management lab | P0/P3 |

## 4. Priority work

### P0 — Safety and truthful support statements

1. **Align CI and documentation.** `docs/TESTING.de.md` suggests optional macOS LDAPS checks can execute when clients exist, while `.github/workflows/ci.yml` explicitly sets `SASD_SKIP_LDAP_INTEGRATION=1`. Correct this mismatch, preserving mandatory TLS certificate verification.
2. **Design isolated privileged-operation testing.** `account-manage` and `quota-set` need explicit-opt-in throwaway Linux VMs with snapshots, before/after assertions, cleanup/rollback, and audit logs. Never mutate the working WSL instance or an everyday development host for this validation.
3. **Improve documented security boundaries.** Cover the two privileged tools in `SECURITY.md` and document exit code exceptions, including Nagios mode.
4. **Never silently skip required tests.** Keep required CI dependencies explicit; optional skips must remain visible.

**Done:** Accurate per-platform requirements; validated documentation references; reviewed VM test design; no unreported required-test skips; safe defaults unchanged.

### P1 — CLI consistency, packaging, release discipline

1. Audit `--help`, `--version`, stderr, exit status, NUL/machine-readable formats. Earlier tools such as `rotate`, `file-integrity`, and `ssh-key-audit` do not follow all newer conventions; preserve compatibility deliberately.
2. Add a version-aware install manifest. The current Makefile removes files based on the present checkout, potentially leaving previously installed files that were removed upstream. Test upgrades, staged installs, and uninstall idempotence.
3. Add ShellCheck for shell sources and narrowly scoped contract/link/dependency checks, without turning optional runtime dependencies into global hard requirements.
4. Plan a reproducible source release, consistent version strings, release checklist and a possible first `v0.1.0` tag once the scope and gates are agreed.

**Done:** Regression, integration, documentation, install/uninstall, and contract checks pass; package contents and platform limits are recorded.

### P2 — Read-only feature expansion only after the base is stable

Recommended order, **not implementation authorization**: (1) host/process inventory; (2) service-state reporting with systemd detection and honest WSL fallback; (3) mounts/filesystems; (4) network interfaces and routes; (5) structured log inspection with bounded output and privacy controls. Require a written purpose, boundary, dependency list, DE/EN guide, manpage, negative/positive tests, exit-code design and side-effect assessment for each command.

### P3 — Later, separate commitments

FreeBSD/OpenBSD backend and CI work; package/update health; SMART/RAID monitoring; restorable and off-host backups; write-capable networking/firewall features only with an independent security model.

## 5. Proposed milestones and acceptance criteria

| Order | Milestone | Scope | Done when |
|---|---|---|---|
| M0 | Inventory | This review | 30 tools and risks mapped |
| M1 | `quality-contracts` | CLI contracts, documentation, platform matrix, CI skips | New contract tests green; EN/DE consistent |
| M2 | `privileged-safety` | VM safety test design and explicit apply regression | Snapshot/rollback documented; no production-host mutation |
| M3 | `release-engineering` | Install/version manifest, upgrade behavior, release checklist | Reproducible staged install and remove; RC feasible |
| M4 | `host-observability` | One or two targeted read-only commands | Cross-platform behavior and tests explicit |
| M5 | `bsd-platforms` | FreeBSD/OpenBSD matrix as runners/VMs allow | Supported features individually verified |

This sequence is risk-driven rather than calendar-based. M0 is complete with this report. M1 is the recommended next coding milestone.

## 6. Explicit non-claims

- Green CI does **not** establish safe real-world account/quota modifications.
- The local LDAP fixture is not a full OpenLDAP server.
- FreeBSD, OpenBSD, and Solaris support remains unverified.
- `file-integrity` does not implement tamper-proof integrity attestation.
- An `Unreleased` changelog is not a versioned product release.

## 7. Immediate next action

Scope M1 into a small, reviewable `feat/quality-contracts` branch without modifying `main` before user acceptance. Maintain compatibility and keep required Ubuntu/macOS CI green before merging.

## 8. Audited sources

- [Repository tree](https://github.com/SASD-Sysadmin/freeware/tree/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb)
- [README](../README.md), [Changelog](../CHANGELOG.md), [Development](DEVELOPMENT.md), [Platforms](PLATFORMS.md), [Testing](TESTING.md), [Exit codes](EXIT-CODES.md)
- [Makefile](../Makefile), [CI](../.github/workflows/ci.yml), [Security](../SECURITY.md)
- [Verified main CI run #13](https://github.com/SASD-Sysadmin/freeware/actions/runs/38394032369)
