# SASD Freeware – Second Continuation Roadmap

[Deutsch](ROADMAP-CONTINUATION-2.de.md) · [Project](../README.md) · [Agent instructions](../AGENTS.md) · [Earlier roadmap](ROADMAP.md) · [Release gaps](RELEASE-GAPS.md)

**Created:** 2026-11-07. **Status:** versioned continuation plan based on a renewed source review; neither a product release nor blanket implementation authorization for every listed feature.

## 1. Purpose, authority and baseline

This roadmap supplements the chapter-based plan and separates book coverage, missing or intentionally narrower functionality, confirmed defects/documentation contradictions, and missing operational/recovery/release evidence.

The reference is **David N. Blank-Edelman, Perl for System Administration, O'Reilly, first edition July 2000, ISBN 1-56592-609-9**. The later *Automating System Administration with Perl* was not fully reviewed and is not implicitly included in the requirements.

Keep the original [roadmap](ROADMAP.md) and its dated history. This is the newer plan for the continuation topics recorded here, without overriding existing CLI contracts, safety boundaries or release-gap definitions. `FR2-*` are new planning identifiers, not renamed M9/M10 milestones.

**Reviewed source:** `main=337b7cff34c2818921d1df023f3c5e2d386301c8`, tree `c2b953e454b80014e59322f2cd2f56840351b9ef`. Recheck HEAD and CI before future changes. This documentation changes no runtime behavior and closes no release gate.

## 2. Sources and review limits

Use current pinned source/tests/GitHub metadata, applicable guides/manpages/Makefile/CI contracts, the original publisher's contents and accessible sections, dated operator evidence, and historical roadmaps/handoffs, in that order as a working guide. Investigate contradictions explicitly; a newer statement is not automatically correct. Older operational evidence may remain useful without accepting the current release commit in full.

All 334 tracked files were retrieved and compared against their Git blob SHAs with no mismatch. Commands, modules, tests and documentation were inventoried and searched for functional counterparts. This was not a formal security proof of every line or a comparison of every original book listing. Coverage judgments use the detailed publisher contents and accessible sections; subsection requirements and intentional alternatives/exclusions require FR2-01. Absence from README alone was not treated as proof of missing functionality.

The temporary source copy was not a full Git checkout. Local Git-index checks were therefore not exercised. Bytes were verified against blob SHAs and file modes taken from the tree; this does not replace checking a real checkout.

| Evidence term | Meaning |
| --- | --- |
| Source-confirmed | Behavior or absence established from named implementation/interfaces |
| Locally reproduced | Actually executed in isolated temporary storage; record environment/method |
| CI-confirmed | Successful specific workflow for the exact SHA |
| Operator report | Human-reported execution, not necessarily independently repeated |
| Planned | Not implemented or accepted yet |
| Not demonstrated | Sufficient evidence absent from reviewed sources; not a claim no test ever occurred |
| Excluded | Versioned, justified scope decision with an accountable owner |

## 3. Inventory and checks actually executed

| Item | Reviewed baseline |
| --- | --- |
| Commands | 52 in `bin/`, 2 in `sbin/` |
| Runtime / internal installer modules | 15 in `lib/SASD/Freeware/`, 3 in `tools/lib/SASD/Freeware/` |
| Manpages | 54 |
| Offline Perl test files | 48 `tests/test_*.t`, plus two shell test files and optional integration |
| Static release audit | `PASS=288`, `GAP=0`, `MANUAL=7` |
| Full staging installation | 257 managed files |
| Main CI | [Run 42174570467](https://github.com/SASD-Sysadmin/freeware/actions/runs/42174570467), completed/success, Ubuntu and macOS |

Locally successful: `make check`, `make release-gap-audit`, a complete temporary DESTDIR installation, and:

```sh
prove tests/test_cli_contracts.t tests/test_installation.t \
  tests/test_installation_concurrency.t tests/test_installation_interruption.t \
  tests/test_installation_rollback.t tests/test_release_gap_audit.t \
  tests/test_documentation.t tests/test_m9_documentation.t
```

**Before this documentation change:** eight files, 1,664 assertions, PASS. Only those appropriate suites ran, using temporary files inside an isolated root user namespace. Starting an unprivileged UID was unavailable. **The full local `make test`, Git-index check, ShellCheck and native integration were not run in that review.** Main CI independently exercised its configured checks. Later documentation links can change assertion counts; the historical count is not a target.

macOS CI explicitly skips LDAPS: success of its combined integration step does not establish LDAP acceptance. Container/parser checks are not native kernel/firewall evidence.

## 4. Chapter coverage and substantive differences

| Chapter | Current counterparts | Missing, narrower or still requiring comparison |
| --- | --- | --- |
| 1 – Introduction | CLI/safety/development conventions | Check principles across commands; no standalone executable required for each principle |
| 2 – Filesystems | Inventories, permissions, links, quotas, usage, content integrity; additional EOL conversion | Historical platform-specific methods and quota alternatives not fully transferred; broad modern Unix/Linux coverage, original listing comparison pending |
| 3 – User accounts | Accounts/groups/homes; Linux user/group creation and password locking | No integrated account system with central data, XML, process scripts, creation/deletion and Windows management |
| 4 – User activity | Sessions, processes and Linux login history | File/network operation tracking, broader process control and complete platform adapters absent |
| 5 – Name services | Hosts lint, DNS query, NSS, resolver and limited NIS diagnosis | Hosts/DNS generation from common data, generation checks and associated version workflow absent; no NIS+/WINS management |
| 6 – Directory services | Anonymous LDAPS rootDSE and static TLS configuration audit | General authenticated search, LDIF import/changes, entry creation/deletion/rename/attribute edits absent; Finger, WHOIS and ADSI absent |
| 7 – SQL | Bounded read-only PostgreSQL/MySQL/MariaDB diagnostics, limited storage report | DBI/ODBC examples and broader administration workflows not transferred; Sybase/MS-SQL support and related login/documentation tasks absent |
| 8 – Mail | STARTTLS diagnosis, Postfix queue/configuration inspection | Administrative sending, batching/rate limiting, incoming mail/mailbox/MIME processing, spam/blacklist/support workflows absent |
| 9 – Logs | Structured counts/normalization and file snapshots with `rotate` | Stateful multi-run processing, broader database history and ring buffers absent; snapshots do not implement complete active-log rotation |
| 10 – Security/network | Content baseline, SUID/SSH, TCP, interfaces/routes/listeners/firewall snapshots | SNMP, packet capture/analysis, network-service baseline comparison and broader correlation absent |
| Appendices A–E | Some foundations in current guides | RCS/LDAP/XML/SQL/SNMP tutorials not accepted as covered; learning sections do not each need a CLI |

### 4.1 Functional equivalence and additional project ideas

Native SQL clients instead of DBI, or a custom walker instead of a particular book module, are implementation choices rather than automatic defects. Evaluate use cases, boundaries and evidence, not module-name matches.

ACL/mount reports, PostgreSQL storage, Oracle support, complete firewall evaluation and modern Linux-distribution evidence are project extensions/ideas. Do not make them original book requirements without a book source. The reviewed SQL contents name MySQL, Sybase and Microsoft SQL Server; Oracle is not established as mandatory by that source.

### 4.2 Historical technologies and scope

Windows NT/2000, classic Mac OS, ADSI, NIS+, WINS and RCS are not automatic modern product commitments. Decide separately to adopt, modernize, defer or exclude each topic, with a reason. Finger/WHOIS, packet capture, LDAP writes and personal-data processing need concrete operational/privacy boundaries. Exclusion is not successful implementation.

## 5. Confirmed findings

| ID | Finding and evidence | Required follow-up |
| --- | --- | --- |
| FR2-F01 | Sequential uninstall: deterministic failure at the second deletion left alpha absent, beta and manifest present. Retry refused `installed file changed or missing; refusing: bin/alpha`. See uninstall branch in `tools/installation.pl`. | Design and test recovery/restart semantics without blindly dropping missing manifest entries |
| FR2-F02 | README claims Perl 5.8 generally; `file-integrity` uses `//`, other commands need newer APIs/modules. | Establish tested minimum runtime/dependency versions for supported shipped scope |
| FR2-F03 | `mail-probe` has neither IPv6 nor implicit SMTPS/465 support. | Missing functionality, not merely missing acceptance; implement separately or exclude explicitly |
| FR2-F04 | Complete staging installed 257 files but no prefix `LICENSE`; installer selection omits it. | Review shipped notices; any addition must respect manifest/upgrade/uninstall ownership |
| FR2-F05 | Before this slice, repository-wide search found no explicit author/publisher/book-title attribution and no subsection mapping. | Document origin/coverage and separately verify actual copied/adapted material |
| FR2-F06 | Audit emits seven MANUAL rows unconditionally. | Do not interpret them as seven failed or demonstrably never-performed tests |
| FR2-F07 | Historical plans contain superseded counts and next steps. | Retain dated history, link current continuation clearly, do not execute stale instructions blindly |

### 5.1 Reproduction contract for FR2-F01

Only temporary source and DESTDIR were used. Source contained executable regular `bin/alpha` and `bin/beta` plus empty directories expected by the installer. After a successful install, a separate Perl process defined `CORE::GLOBAL::unlink` before loading the installer: throw for `bin/beta`, delegate other paths to `CORE::unlink`. The wrapper explicitly added `tools/lib` to the module path because of FindBin behavior.

Independently capture existence before retry: alpha absent, beta and manifest present. A normal subsequent uninstall refuses alpha during preflight. Future regression should reproduce this in an isolated test, not add a production fault-injection flag. This is neither a power-loss simulation nor actual SIGKILL/native VM acceptance.

### 5.2 Existing limits are not automatically new defects

- Installer advisory locking coordinates cooperating processes only; there is no fsync/power-loss protocol or atomic crash recovery.
- EOL conversion has bounded metadata preservation and changes inode/times; ACLs/xattrs and concurrent writers need an explicit scope.
- File integrity covers content, not complete metadata or a signed trust chain.
- Firewall summaries are source-specific and do not certify whole-host protection.
- Password locking does not revoke SSH keys or sessions.
- Network-service inventory covers listeners/UDP bindings, not PID/user/program attribution or full connection history.

## 6. Acceptance: available and missing evidence

[RELEASE-GAPS.md](RELEASE-GAPS.md) retains RG-01 through RG-10 definitions. This document closes none. The script's seven MANUAL categories do not map one-to-one to those ten IDs.

| Area | Reviewed evidence | Remaining work |
| --- | --- | --- |
| Current CI | Exact Main run and both job/step results checked | Associate every future release SHA separately; preserve macOS LDAP skip |
| Static docs | 54 manpages and individual guides; GAP=0 | Semantic correctness, versions, links/index maintenance |
| RG-01 accounts/quotas | Preview/negative/mock tests; no completed native VM acceptance in reviewed sources | Separate permission, isolated snapshot VM, actual apply, independent state verification and restore |
| RG-04 installer | Offline interruption/rollback/concurrency; operator-reported WSL evidence; F01 reproduced | Uninstall recovery, actual interruption in suitable VM, demonstrated recovery; retain partial evidence |
| RG-05 platforms | Ubuntu/macOS CI and synthetic/optional container procedures | Native evidence for claimed platform/feature combinations only |
| RG-06 services | Offline/loopback and limited documented Postfix practice | Realistic SQL/LDAP/mail/firewall tests matching release claims |
| RG-02 artifacts | No GitHub release on renewed query; complete tag inventory not verified | Clean pinned tag/commit, consistent versions, archive and independent SHA-256 repetition |
| RG-03 approval record | No completed aggregate record in reviewed sources | Scope, commit, evidence, deviations, recovery and accountable approval |
| RG-09 dependencies/notices | F02/F04/F05 confirmed | Runtime matrix, provenance and shipped notices |

**Postfix partial evidence:** [MAIL-ACCEPTANCE.md](MAIL-ACCEPTANCE.md) records Debian 12/Postfix 3.7.11 checks on 2026-10-20: empty queue, STARTTLS with a test CA and rejection of an unknown CA. A populated queue and effective master.cf overrides remain unaccepted. IPv6/465 are not implemented.

**WSL partial evidence:** The supplied operator handoff reports 39 staging PASS, 257-file installation/reinstallation, tamper refusal, digest verification and uninstall preserving an unowned file at `337b7cf`. Not independently repeated. Reported archive SHA-256: `d3c676a8ed84aa8dff7f58ae5bcd2fc581d2e700205a3ac9f42c1d4da9cf8f9e`. Archive contents/restorability were not verified. Do not publish complete private operator logs.

## 7. Ordered work packages

P0 is groundwork before the first release advertised with the corresponding scope. Later book additions are not all release blockers. No package authorizes incidental production changes.

| Package | Priority | Deliverable | Dependency and acceptance |
| --- | --- | --- | --- |
| **FR2-00** | P0 planning | This bilingual continuation, root AGENTS and navigation | Documentation checks; no runtime change or gate closure |
| **FR2-01** | P0 scope | Subsection-level book/project matrix | Decide modern equivalents/exclusions; every relevant subsection has source, status, code, tests and acceptance |
| **FR2-02** | P0 quality | Correct tested Perl/module/client minimum versions (F02) | No arbitrary version bump; test selected floor, consistent EN/DE and errors |
| **FR2-03** | P0 safety | Uninstall failure/recovery contract (F01) | Isolated regression first; protect changed/unowned files, manifest, backups and lock; recovery evidence |
| **FR2-04** | P0 provenance | Attribution, actual reuse and shipped notices (F04/F05) | Verify rights, not ownership of a book; test manifest/upgrade/conflict/uninstall if adding LICENSE |
| **FR2-05** | P0 evidence | Versioned evidence structure and source attribution | Inspect existing conventions; classify WSL as partial; explain unconditional MANUAL correctly |
| **FR2-06** | P0 acceptance | RG-01/RG-04 snapshot-VM acceptance and RG-02/RG-03 for chosen scope | Relevant 02–05 first; separate operator approvals; version exclusions; authorize release separately |
| **FR2-10** | P1 value | Hosts/DNS generation to output directory first | After 01; canonical input, deterministic output and semantic validation; no /etc writes or reload |
| **FR2-11** | P1 value | General read-only LDAP, separate later writes | After 01; bind/TLS/filter/secret contract; reads before writes; actual labs for mutations |
| **FR2-12** | P1 value | Administrative mail with limits/deduplication | After 01; separate from mail-probe; local sink and no real recipients in tests |
| **FR2-13** | P1 value | Stateful logs and service-baseline comparison | After 01; stable state formats, atomic publication, locks and explicit time/duplicate rules |
| **FR2-14** | P1 value | Read-only SNMP first | After 01; target SNMPv3 Auth/Privacy, protected secrets, timeouts and bounded OID/walk sets |
| **FR2-20** | P2 extension | Account lifecycle and optional central data | After 01 and RG-01 contract; import/plan before writes; deletion/retention decided separately |
| **FR2-21** | P2 extension | SQL scope/additional engines | Choose actual needs; separate PostgreSQL-storage/Sybase/MS-SQL slices; no module change without benefit |
| **FR2-22** | P2 extension | Incoming mail/MIME/mailbox/support workflows | Local fixtures, size/encoding/privacy limits; no unsolicited mailbox connection |
| **FR2-23** | P2 extension | IPv6 and implicit SMTPS for mail-probe | Separate protocol paths and positive/negative TLS tests, no verification downgrade |
| **FR2-24** | P2 extension | Mount/ACL/storage and modern native adapters | Establish project requirement; metadata/platform matrix, native acceptance and read-only start |
| **FR2-25** | P2 optional | File/network operation tracking and packet capture | Justified task, privileges, minimization, limits and isolated labs first |
| **FR2-30** | P3 decisions | Historical protocols/platforms and appendices | Adopt/modernize/exclude individually; no blanket book copying |

### 7.1 Suggested execution

1. FR2-01 is the next substantive documentation slice. Do not start unchecked large features alongside it.
2. Develop FR2-02/03/04 separately. They can be technically independent; this is not an instruction to delegate to agents.
3. FR2-05 organizes existing evidence; FR2-06 handles actual remaining manual gates. Continue safe independent work if no VM is available.
4. After scope decisions, consider FR2-10, read-only FR2-11 and FR2-12 first; prioritize 13/14 by concrete operational benefit.
5. P2/P3 need actual demand and separate tasks. A deliberately smaller release can precede broad book coverage; do not equate that release with book completion.

Runtime fixes require a fresh CI entry check. This roadmap sets no deadlines, creates no tags and does not commit to .deb/.rpm packaging; packaging remains a later decision.

## 8. Package contracts

### FR2-01 coverage matrix

Each row needs: ID, edition/chapter/subsection, source, use case, desired modern counterpart, existing implementation, tests, platform boundaries, side effects, status, decision and remaining evidence. States: `not assessed`, `partial`, `implemented`, `accepted`, `deferred`, `excluded`. Keep implementation separate from acceptance. No percentages without a defined denominator and no completion claims based only on represented chapter headings.

### FR2-03 recovery

Exercise failure before deletion, after at least one deletion, at manifest removal and cleanup. A transactional backup or documented resumable strategy may be appropriate; explain the chosen approach in a short ADR. Include changed/unowned files, missing files, repeat calls, concurrency and permission failures. Do not guess from incomplete installation or delete backups/locks to unblock operations. Native interruption acceptance remains separate.

### FR2-10 through FR2-14 productive features

Before code, define purpose, scope, sample output, exits, dependencies, non-goals and tests. Separate CLI, acquisition/backend, pure parser/model and presentation where useful. Version formats, keep secrets out of argv/logs, select network targets explicitly and bound runtime/output. Do not implicitly change DNS, LDAP, mail or monitoring targets.

## 9. Completion criteria

Each slice needs a focused diff, appropriate positive/negative tests, consistent EN/DE guides/manpages for CLI changes, changelog and honest evidence limits. Run `make test` per CONTRIBUTING in a suitable unprivileged checkout, then relevant additional checks. Verify Markdown Git mode `100644` and command mode `100755`.

Release only the accepted scope: close applicable RG-P0 gates or record an accountable justified exclusion. Do not relabel fixtures as native evidence. A completed modern book implementation additionally requires every relevant matrix row accepted or explicitly excluded, with exclusions visible in the completion claim.

## 10. Sources and maintenance

- [Original book and detailed contents](https://www.oreilly.com/library/view/perl-for-system/1565926099/)
- [Account system](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch03s03.html), [DNS](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch05s03.html), [LDAP](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch06s04.html), [mail](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch08.html), [security/network](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch10.html)
- [Reviewed baseline](https://github.com/SASD-Sysadmin/freeware/commit/337b7cff34c2818921d1df023f3c5e2d386301c8)
- [Release engineering](RELEASE-ENGINEERING.md), [privileged safety](PRIVILEGED-SAFETY.md), [platforms](PLATFORMS.md), [testing](TESTING.md), [development](DEVELOPMENT.md)

Maintain stable FR2 identifiers, label corrections and synchronize EN/DE. Never forward historical counts as current execution results. This is an auditable working plan, not a guarantee that one review found every defect.
