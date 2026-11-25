# SASD Freeware – Development roadmap

[Deutsch](ROADMAP.de.md) · [Project](../README.md) · [Agent instructions](../AGENTS.md) · [Release gaps](RELEASE-GAPS.md) · [Release engineering](RELEASE-ENGINEERING.md)

**Current product plan: 16 November 2026.** This is the single canonical English roadmap. It consolidates the former `ROADMAP.md` and `ROADMAP-CONTINUATION-2.md`, preserving the dated evidence and historical assessments below. The historical reference book is **not** a product requirements specification or a prerequisite for release.

**Verified entry baseline:** `main` at `606b820b67c08b757339ebcf84b3426fc5eb217d`, [successful Ubuntu/macOS CI run 43820682925](https://github.com/SASD-Sysadmin/freeware/actions/runs/43820682925). This is a dated observation, not an assertion that future commits pass. No release is authorized or announced by this document.

## 1. Product direction and decision criteria

SASD Freeware is a maintainable, MIT-licensed collection of independently usable Linux/Unix administration commands. Each tool should address a practical administrative problem, compose with Unix workflows, preserve safe defaults, and have an explicit, testable contract. Perl is preferred for substantive parsing and administration, with shell where useful. Neither a mandatory framework nor a permanently running service is a design goal.

Choose work by **operational benefit, failure risk, security, reproducible tests, and release scope**, not by coverage of book chapters. David N. Blank-Edelman's *Perl for System Administration* (2000) remains useful historical inspiration and optional research. Do not silently treat its examples or the second edition as implementation obligations. Historical `M*` and `FR2-*` IDs stay stable for traceability.

Use code and current tests to establish behavior; distinguish implemented, fixture-tested, native-tested, accepted and released. A green CI run does not establish privileged VM acceptance, cross-platform completeness or release approval. The ten RG gaps in [RELEASE-GAPS.md](RELEASE-GAPS.md) retain their definitions. When a dated historical claim below conflicts with verified current behavior or this product direction, do not promote it to an active requirement.

## 2. Current prioritized work

| Order | Existing ID | Priority | Deliverable and decision boundary |
| --- | --- | --- | --- |
| **1** | **FR2-03 / FR2-F01 / RG-04** | P0 safety | Isolated regression for partial uninstall after a failed deletion; specify safe retry/recovery and test manifest, lock, foreign/changed files, and evidence retention. Do not equate fault injection with native crash recovery. |
| **2** | **FR2-02 / FR2-F02** | P0 compatibility | Establish and test genuine minimum Perl/module/client versions; correct EN/DE documentation instead of assuming Perl 5.8 compatibility. |
| **3** | **FR2-04 / FR2-F04–F05 / RG-09** | P0 provenance | Verify installed license notices, actual third-party reuse and rights. Changing installation payload needs upgrade/uninstall/conflict tests. |
| **4** | **FR2-05 / RG-03** | P0 evidence | Record reproducible SHA-specific test, CI, staging, native and operator evidence; do not relabel `MANUAL` audit categories as failed tests. |
| **5** | **FR2-06 / RG-01–RG-04** | P0 release scope | Separately approve disposable snapshotted VM account/quota and installer recovery acceptance, plus archive provenance and a responsible release decision for the selected scope. |
| **On demand** | **FR2-10–14, FR2-20–25** | P1/P2 | Evaluate hosts/DNS generation, read-only LDAP and SNMP, administrative mail, stateful logs, SQL/storage, native adapters and other enhancements individually by real operator need; scope and test each separately. |
| **Optional research** | **FR2-01 / FR2-30** | P3 | Book subsection mapping and historical protocols only if specifically commissioned; no blocker for an independent SASD Freeware release. |

**Historical next technical slice (16 November 2026):** FR2-03, with a deterministic non-production reproduction, clear recovery architecture decision, and focused positive/negative regression tests. Do not combine it with unrelated new utilities or a release. Documentation consolidation alone resolves none of the release gaps.

**FR2-02 evidence update (21 November 2026):** The 18 November operator run on source `b1960f4` passed the complete Debian/WSL2 Perl 5.14.4 offline suite (49 Perl suites, 6,146 TAP cases with 10 SKIPs, two Bash test groups), 74 source/53 CLI audit checks, and the release-gap static inventory (`PASS=288, GAP=0, MANUAL=7`). See [Perl compatibility](PERL-COMPATIBILITY.md). This corrects the current README 5.8 claim; it does not establish a universal minimum or close other release gates. Earlier dated roadmap assessments remain historical evidence.

**FR2-04 preliminary evidence (22 November 2026):** The reviewed `15e4347` source had consistent MIT code/test SPDX identifiers; the installer then omitted the root `LICENSE`, **fixed and CI-verified in `1f6f4f0`**. See [license and provenance review](LICENSE-PROVENANCE.md). The document and auditor do not change project licensing or close RG-09. Notice-delivery regressions are now implemented and CI-verified; provenance/legal authority review and an explicit future SASDGMBH release-license decision remain required.

**FR2-04 closure / FR2-05 evidence update (23 November 2026):** Both technical FR2-04 slices are committed and successful on Ubuntu/macOS: [installer LICENSE CI `45128966544`](https://github.com/SASD-Sysadmin/freeware/actions/runs/45128966544) at `1f6f4f0`, and [provenance-doc CI `45131942704`](https://github.com/SASD-Sysadmin/freeware/actions/runs/45131942704) at `686a86b`. The **licensing choice is now decided**: personal/beta **MIT**, separate future `SASDGMBH` **AGPL-3.0-only**; see [license strategy](LICENSE-STRATEGY.md). [FR2-05 evidence register](RELEASE-EVIDENCE.md) distinguishes passes, skips and seven outstanding MANUAL release gates. Rights-chain and external-material review remain open; technical FR2-04 completion is not legal release approval.

**FR2-06a preparation (23 November 2026):** A [nonprivileged staging fixture and separately authorised Debian KVM VM-acceptance plan](FR2-06-VM-ACCEPTANCE.md) define evidence and stop conditions. This package does **not** execute privileged changes, certify restore, or close any MANUAL release gate. Baseline: `f25aa3f` with CI [45139166377](https://github.com/SASD-SysAdmin/freeware/actions/runs/45139166377).

### 2.1 Application crash diagnostics and core dump analysis (25 November 2026)

**Strategy decision:** Add focused, historically informed Unix/Linux application troubleshooting to SASD Freeware. For SASD GmbH, the goals are repeatable incident triage, legacy application support and evidence-based root cause analysis at the boundary of administration and software engineering. This is agreed planning scope, not proof of service readiness or blanket implementation authorization. Existing P0/FR2 work (including FR2-06) and manual release gates retain priority. This expansion is not a new prerequisite for the existing release scope.

**Existing baseline:** At `ac71b19`, [core-report](commands/core-report.md) inventories regular files named `core` or `core.*`, logical sizes and totals under a specified directory. It uses lstat, skips symlinks, supports filesystem boundaries and NUL-delimited output, and does not validate dump contents. Offline cases exist in `tests/test_filesystem_tools.t`. This is source inspection, not a newly executed test. Preserve the documented options, output and exit codes; do not build a duplicate finder. Inspect existing process, filesystem and log tools before adding commands.

**Architecture:** Small, independently usable Perl/shell commands and optional native tool adapters, reusing existing modules and commands. No custom debugger, mandatory framework, resident daemon, web interface or separate repository. Prefer repository-style hyphenated command names without language suffixes. Names below are working concepts, not finalized CLI contracts.

| ID | Priority | Proposed scope and acceptance boundary |
| --- | --- | --- |
| CD-01 | P1 | Baseline and classic core-file diagnostics: review core-report, identify format/architecture with bounded native tools (file, readelf where appropriate), distinguish candidates from validated core files and inspect dump settings without changing them. Specify format limits, malformed/truncated inputs and compatibility. |
| CD-02 | P1 | Offline debugger analysis and symbol matching (e.g. core-analyze, core-symbols): explicitly supplied dump/executable, build identity or uncertainty, signal, frames, threads and mapped libraries where available. GDB first on Linux. Disable unsafe auto-loading and network fetches; make missing symbols, mismatches, timeouts and debugger failures visible. |
| CD-03 | P1 | Diagnostic collection and reporting (e.g. core-collect, core-analysis-report): bounded reproducible human-readable and, where useful, structured reports with provenance, versions, observed facts, limitations, hypotheses and next steps. No unsupported root-cause claims or collision with core-report. |
| CD-04 | P2 | Operator-invoked detection, disk usage, retention inventory and archive/cleanup preview. Copying, archiving or removal require a separately authorized operation contract, private permissions and safe path/identity checks. No resident watcher; statistics and similarity grouping optional later. |
| CD-05 | P2 | Modern Linux systemd-coredump/coredumpctl adapter: read-only metadata, explicitly authorized local export if justified; handle retention, missing tools and systems without systemd. No dump reconfiguration. Native acceptance required. |
| CD-06 | P2 | Related application troubleshooting: review existing process/log tools first; bounded binary inspection (nm, objdump, readelf); separately scoped process inspection (pmap, lsof) and live tracing (strace, truss, ktrace). Profiling, leak analysis and live attach require distinct privacy and authorization boundaries. |
| CD-07 | P3 optional | Kernel crash analysis (kdump, crash, kgdb) as a separate future design/lab package. No automatic crash injection, kernel configuration or live kernel debugging. Memory forensics outside initial scope. |

Historical research candidates: adb/dbx, Solaris coreadm/mdb/pstack, AIX dbx, HP-UX adb/gdb and BSD gdb/lldb. Availability is version-dependent; none implies verified platform support. Start native acceptance on a disposable Debian Linux VM; add other Unix adapters only with actual tools, formats and environments available for testing.

**Security and privacy requirements:**

- Core files, memory-derived text, backtraces, paths, environment data and debugger output are potentially confidential and untrusted. Never commit customer dumps or sensitive raw reports, transmit them automatically, run strings over entire dumps by default or collect unnecessary memory contents. Use synthetic secret-free fixtures; redact sensitive values and identifiers before authorized sharing; redaction is not proof of anonymity.
- Default to read-only analysis of explicit authorized inputs. No default broad host scan, root escalation, live attach, sysctl/ulimit changes, crash generation, service changes, package installation, deletion or automatic upload. Explicitly requested local reports require a private directory, restrictive permissions and no overwrite of unrelated files.
- Analyze untrusted dumps, executables and symbols with patched trusted tools in isolated non-root, preferably disposable and network-disabled environments without host secrets. Disable debugger startup scripts, auto-loaded scripts and automatic symbol downloads; never execute the supplied program/inferior. Use trusted tool paths and argument vectors, not shell interpolation; validate paths and file identity, reject unsafe links/special files, bound time/resources/output and report failures honestly. Debugger flags alone are not a sandbox.
- Preserve authorized evidence: record identity/digest where appropriate, build ID or explicit unknown/mismatch, timestamps, versions, limits and chain of custody. Do not modify originals. Keep evidence private under an approved retention policy. A stack trace is not proof of root cause without corroboration.

**Acceptance and next slice:** Authorize CD-01 separately first; inspect existing contracts/tests, identify overlap and specify formats, dependencies, exit codes and a minimal change. Each later slice requires positive/negative offline tests, EN/DE command guides, applicable manpages, installer/CLI checks where affected and exact-commit evidence. Cover false candidates, malformed/truncated dumps, unusual paths, unsafe links/special files, missing debuggers/symbols, mismatched executables, hostile auto-loading, timeouts/output limits and incomplete/redacted reports as applicable. A small self-authored test program may generate synthetic crashes only in a separately authorized disposable VM without real secrets and with bounded disk usage. Distinguish mock tests, skips and unsupported platforms from native GDB/systemd evidence. Publish only sanitized example reports; distinguish verified observations, hypotheses and corroborated causes. Customer-service readiness requires separate practical cases and approval. No existing RG gate is closed by this planning update.

### 2.2 System Call Trace Analysis Toolbox (25 November 2026)

**Agreed strategy:** Build a cross-platform, offline-first system-call trace analysis toolbox within SASD Freeware, starting with Linux strace. Complement application crash diagnostics (section 2.1/CD-06) and existing process, log, filesystem and network tools; preserve their contracts. Turn large saved traces, including ordinary `strace -o trace.log` files, into short, actionable and reproducible incident reports. This is agreed planning, not implementation, platform certification or blanket authorization. Existing P0/FR2 priorities and manual release gates remain unchanged; this is not a new release prerequisite.

**Architecture:** Small independent commands in `bin/`, preferably Perl with standard modules, a shared streaming parser/aggregation library under `lib/SASD/Freeware/` and format-specific adapters with a small common event contract. Review External.pm, process-report and log-summary before adding code. Working names: trace-summary, trace-errors, trace-slowcalls, trace-files, trace-network, trace-processes, trace-io, trace-hangs, trace-report, trace-compare, trace-sanitize and trace-capture; finalize contracts before implementation. Reuse native tools where sufficient. No custom tracer, debugger, mandatory framework, database, daemon, GUI, web service or cloud/AI dependency.

| ID | Priority | Scope and acceptance boundary |
| --- | --- | --- |
| TRACE-01 | P1 | Inventory native strace options (-c/-C, -f/-ff, -tt/-ttt, -T, -yy), strace-log-merge and optional third-party analyzers such as stracepy and strace-tui. Evaluate availability, practical benefit and licensing; no automatic adoption. Specify V1 CLI, event, privacy and fixture contracts. |
| TRACE-02 | P1 | Shared Linux text parser: plain -o and selected documented variants; PID/TID, timestamps, syscall, result, errno, duration, signals, exit and unfinished/resumed records. Bound pending state and line size; report missing, unknown, malformed and unsupported records. |
| TRACE-03 | P1 | Summary and error grouping by syscall, errno, process and reliably decoded resource; ranked evidence with source-line references. Distinguish normal probes and retries from suspicious patterns. |
| TRACE-04 | P1 | Timing and blocking hints: longest completed calls, counts and totals where durations exist; incomplete calls separately. No invented timing; long poll/futex/read waits may be normal; concurrent durations are neither wall-clock nor CPU time. |
| TRACE-05 | P2 | File, network and I/O views: paths, permission failures, missing resources, endpoints, connection results and byte counts only for understood return semantics. Track descriptor reuse and process scope or mark resources unknown. |
| TRACE-06 | P2 | Process/thread relationships, fork/clone/exec, signals and exits when recorded; merge separate -ff files with explicit ordering/clock limits, no invented parentage or chronology. |
| TRACE-07 | P1 | Compact diagnostic report with top findings, provenance, versions, counts, coverage, uncertainty and read-only follow-up suggestions. Version machine-readable schemas if introduced. Initial MVP is TRACE-01–04 and TRACE-07; remaining packages are follow-ups. |
| TRACE-08 | P2 | Compare working/failing traces and regression baselines. Normalize only known volatile IDs, addresses and descriptors under documented rules; retain original evidence; disclose workload, versions, capture settings and coverage differences. |
| TRACE-09 | P2 | Local privacy/redaction preview and sanitized export; separately authorized native capture workflow. No default live attachment or execution; capture is outside offline MVP. Redaction is best effort, not proof of anonymity. |
| TRACE-10 | P2 | Native Debian validation, large-input/resource-limit tests, historical strace fixtures and operator acceptance; EN/DE guides and manpages. Distinguish historical fixture compatibility from native support. |
| TRACE-11 | P3 optional | Independently tested adapters for Solaris/AIX/FreeBSD truss, FreeBSD/OpenBSD ktrace/kdump and macOS dtruss (version/privilege dependent). Preserve platform-specific semantics and unknown fields. |

**Platform policy:** Linux strace first, Debian disposable VM for initial native acceptance. Investigate historical strace variants and Solaris truss next when documentation and environments exist. Other Unix systems are candidates, not support commitments. Decode binary ktrace formats via trusted native kdump where applicable; do not guess formats. Keep platform-specific evidence and explicit unsupported/skipped states.

**Analysis and safety requirements:**

- Stream explicit authorized local regular files or selected stdin, read-only. Validate file types and paths; no unsafe links, arbitrary host scans, evaluation of trace strings as code or execution of embedded commands or traced programs. Bound line size, pending calls, aggregation cardinality, runtime and output; disclose truncation, dropped records and unsupported constructs. Preserve originals.
- Treat arguments, buffers, paths, endpoints, environment and decoded descriptors as untrusted and potentially secret-bearing. No raw customer traces in Git, automatic uploads or network dependency. Use secret-free synthetic fixtures, minimize displayed payload, escape terminal control characters and delimiters, require private outputs and explicit local export without unrelated overwrite. Review redaction before sharing.
- Separate observations, heuristic hints, alternative explanations and corroborated root cause. ENOENT, EAGAIN, EINTR and EINPROGRESS can be expected; prioritize EACCES, EPERM, ENOSPC, ENOMEM, EIO, EMFILE, R/O filesystem and connection failures in context, not by universal severity. Maintain a small explainable diagnostic rule catalog with positive/negative tests. Suggest safe read-only checks; never automatically repair.
- Capture/attachment is a separate authorization boundary under CD-06: explicit target identity, least privilege, bounded duration/size, privacy settings and isolated lab when appropriate. Tracing can alter timing and reveal data. No default execution, production attachment, escalation, ptrace-policy changes or persistent monitoring.

**Acceptance and next slice:** Authorize TRACE-01 separately. Define formats, dependencies, exit codes and coverage before coding. Test plain untimed traces, -f/-ff, unfinished/resumed, signals/restarts, quoted delimiters and escaped paths, nonblocking operations, unknown/truncated records, hostile text, large streams and memory limits, missing values and sanitized reports. Generate native fixtures only in separately authorized isolated environments with known expected outcomes and no real secrets. Cross-check native summaries only where semantics match. Record exact commit, parser/tool versions, evidence and limitations; distinguish fixture tests, native acceptance, SKIPs and CI. EN/DE documentation, applicable manpages and existing CLI/installer contracts remain binding. No release gate closes through planning.


## 3. Verification, test logs and release evidence

Follow [CONTRIBUTING.md](../CONTRIBUTING.md), use an unprivileged checkout and disposable staging, and preserve production systems. For longer local runs, keep full output without losing the pipeline failure status:

```bash
mkdir -p .test-logs
# Add .test-logs/ to the local .git/info/exclude or the repository .gitignore.
set -o pipefail
make test 2>&1 | tee ".test-logs/make-test-$(date +%Y%m%d-%H%M%S).log"
```

Record the actual test exit status and link it to the exact commit and environment. The `.test-logs/` directory is local evidence; do not commit full logs, credentials or host-private details. Additional targeted checks are `make check`, `make release-gap-audit`, `make shellcheck`, integration tests where configured, and staged install/uninstall. A successful `make test` cannot replace real privileged or native acceptance. The CI log is independently accessible through GitHub Actions; terminal scrollback is not a durable log.

## 4. Detailed engineering review and package contracts (7 November 2026)

The following findings are retained from the second continuation review at commit `337b7cf` and should be read as **dated evidence**. Its inventory, reproductions, external-source limits and open issues remain useful. The **current order and P0/P1 meaning is the product-driven table above**, not the old book-completion sequence. FR2-01 is optional research, and new feature packages do not depend on finishing the book matrix.

**Created:** 2026-11-07. **Status:** versioned continuation plan based on a renewed source review; neither a product release nor blanket implementation authorization for every listed feature.

### 1. Purpose, authority and baseline

This roadmap supplements the chapter-based plan and separates book coverage, missing or intentionally narrower functionality, confirmed defects/documentation contradictions, and missing operational/recovery/release evidence.

The reference is **David N. Blank-Edelman, Perl for System Administration, O'Reilly, first edition July 2000, ISBN 1-56592-609-9**. The later *Automating System Administration with Perl* was not fully reviewed and is not implicitly included in the requirements.

The earlier chapter plan and its dated history are preserved in section 5 of this unified roadmap. This reviewed evidence does not override existing CLI contracts, safety boundaries or release-gap definitions. `FR2-*` are new planning identifiers, not renamed M9/M10 milestones.

**Reviewed source:** `main=337b7cff34c2818921d1df023f3c5e2d386301c8`, tree `c2b953e454b80014e59322f2cd2f56840351b9ef`. Recheck HEAD and CI before future changes. This documentation changes no runtime behavior and closes no release gate.

### 2. Sources and review limits

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

### 3. Inventory and checks actually executed

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

### 4. Chapter coverage and substantive differences

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

#### 4.1 Functional equivalence and additional project ideas

Native SQL clients instead of DBI, or a custom walker instead of a particular book module, are implementation choices rather than automatic defects. Evaluate use cases, boundaries and evidence, not module-name matches.

ACL/mount reports, PostgreSQL storage, Oracle support, complete firewall evaluation and modern Linux-distribution evidence are project extensions/ideas. Do not make them original book requirements without a book source. The reviewed SQL contents name MySQL, Sybase and Microsoft SQL Server; Oracle is not established as mandatory by that source.

#### 4.2 Historical technologies and scope

Windows NT/2000, classic Mac OS, ADSI, NIS+, WINS and RCS are not automatic modern product commitments. Decide separately to adopt, modernize, defer or exclude each topic, with a reason. Finger/WHOIS, packet capture, LDAP writes and personal-data processing need concrete operational/privacy boundaries. Exclusion is not successful implementation.

### 5. Confirmed findings

| ID | Finding and evidence | Required follow-up |
| --- | --- | --- |
| FR2-F01 | Sequential uninstall: deterministic failure at the second deletion left alpha absent, beta and manifest present. Retry refused `installed file changed or missing; refusing: bin/alpha`. See uninstall branch in `tools/installation.pl`. | Design and test recovery/restart semantics without blindly dropping missing manifest entries |
| FR2-F02 | README claims Perl 5.8 generally; `file-integrity` uses `//`, other commands need newer APIs/modules. | Establish tested minimum runtime/dependency versions for supported shipped scope |
| FR2-F03 | `mail-probe` has neither IPv6 nor implicit SMTPS/465 support. | Missing functionality, not merely missing acceptance; implement separately or exclude explicitly |
| FR2-F04 | Complete staging installed 257 files but no prefix `LICENSE`; installer selection omits it. | Review shipped notices; any addition must respect manifest/upgrade/uninstall ownership |
| FR2-F05 | Before this slice, repository-wide search found no explicit author/publisher/book-title attribution and no subsection mapping. | Document origin/coverage and separately verify actual copied/adapted material |
| FR2-F06 | Audit emits seven MANUAL rows unconditionally. | Do not interpret them as seven failed or demonstrably never-performed tests |
| FR2-F07 | Historical plans contain superseded counts and next steps. | Retain dated history, link current continuation clearly, do not execute stale instructions blindly |

#### 5.1 Reproduction contract for FR2-F01

Only temporary source and DESTDIR were used. Source contained executable regular `bin/alpha` and `bin/beta` plus empty directories expected by the installer. After a successful install, a separate Perl process defined `CORE::GLOBAL::unlink` before loading the installer: throw for `bin/beta`, delegate other paths to `CORE::unlink`. The wrapper explicitly added `tools/lib` to the module path because of FindBin behavior.

Independently capture existence before retry: alpha absent, beta and manifest present. A normal subsequent uninstall refuses alpha during preflight. Future regression should reproduce this in an isolated test, not add a production fault-injection flag. This is neither a power-loss simulation nor actual SIGKILL/native VM acceptance.

#### 5.2 Existing limits are not automatically new defects

- Installer advisory locking coordinates cooperating processes only; there is no fsync/power-loss protocol or atomic crash recovery.
- EOL conversion has bounded metadata preservation and changes inode/times; ACLs/xattrs and concurrent writers need an explicit scope.
- File integrity covers content, not complete metadata or a signed trust chain.
- Firewall summaries are source-specific and do not certify whole-host protection.
- Password locking does not revoke SSH keys or sessions.
- Network-service inventory covers listeners/UDP bindings, not PID/user/program attribution or full connection history.

### 6. Acceptance: available and missing evidence

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

### 7. Ordered work packages

P0 applies to safety and evidence needed for the selected release scope; the historical book-coverage matrix is optional research. Later book additions are not all release blockers. No package authorizes incidental production changes.

| Package | Priority | Deliverable | Dependency and acceptance |
| --- | --- | --- | --- |
| **FR2-00** | Completed planning | Consolidated bilingual roadmap, root AGENTS and navigation | Documentation checks; no runtime change or gate closure |
| **FR2-01** | P3 optional research | Subsection-level book/project matrix, only by explicit request | Decide modern equivalents/exclusions; every relevant subsection has source, status, code, tests and acceptance |
| **FR2-02** | P0 quality | Correct tested Perl/module/client minimum versions (F02) | No arbitrary version bump; test selected floor, consistent EN/DE and errors |
| **FR2-03** | P0 safety | Uninstall failure/recovery contract (F01) | Isolated regression first; protect changed/unowned files, manifest, backups and lock; recovery evidence |
| **FR2-04** | P0 provenance | Attribution, actual reuse and shipped notices (F04/F05) | Verify rights, not ownership of a book; test manifest/upgrade/conflict/uninstall if adding LICENSE |
| **FR2-05** | P0 evidence | Versioned evidence structure and source attribution | Inspect existing conventions; classify WSL as partial; explain unconditional MANUAL correctly |
| **FR2-06** | P0 acceptance | RG-01/RG-04 snapshot-VM acceptance and RG-02/RG-03 for chosen scope | Relevant 02–05 first; separate operator approvals; version exclusions; authorize release separately |
| **FR2-10** | P1 value | Hosts/DNS generation to output directory first | After a task-specific scope decision; canonical input, deterministic output and semantic validation; no /etc writes or reload |
| **FR2-11** | P1 value | General read-only LDAP, separate later writes | After a task-specific scope decision; bind/TLS/filter/secret contract; reads before writes; actual labs for mutations |
| **FR2-12** | P1 value | Administrative mail with limits/deduplication | After a task-specific scope decision; separate from mail-probe; local sink and no real recipients in tests |
| **FR2-13** | P1 value | Stateful logs and service-baseline comparison | After a task-specific scope decision; stable state formats, atomic publication, locks and explicit time/duplicate rules |
| **FR2-14** | P1 value | Read-only SNMP first | After a task-specific scope decision; target SNMPv3 Auth/Privacy, protected secrets, timeouts and bounded OID/walk sets |
| **FR2-20** | P2 extension | Account lifecycle and optional central data | After a task-specific scope decision and RG-01 contract; import/plan before writes; deletion/retention decided separately |
| **FR2-21** | P2 extension | SQL scope/additional engines | Choose actual needs; separate PostgreSQL-storage/Sybase/MS-SQL slices; no module change without benefit |
| **FR2-22** | P2 extension | Incoming mail/MIME/mailbox/support workflows | Local fixtures, size/encoding/privacy limits; no unsolicited mailbox connection |
| **FR2-23** | P2 extension | IPv6 and implicit SMTPS for mail-probe | Separate protocol paths and positive/negative TLS tests, no verification downgrade |
| **FR2-24** | P2 extension | Mount/ACL/storage and modern native adapters | Establish project requirement; metadata/platform matrix, native acceptance and read-only start |
| **FR2-25** | P2 optional | File/network operation tracking and packet capture | Justified task, privileges, minimization, limits and isolated labs first |
| **FR2-30** | P3 decisions | Historical protocols/platforms and appendices | Adopt/modernize/exclude individually; no blanket book copying |

#### 7.1 Suggested execution

1. FR2-03 is the next technical safety slice, subject to current green CI and an isolated regression. FR2-01 remains optional research rather than a prerequisite.
2. Develop FR2-02 and FR2-04 separately after the scoped FR2-03 work, unless a verified blocker changes the order. This is not an instruction to delegate to agents.
3. FR2-05 organizes existing evidence; FR2-06 handles actual remaining manual gates. Continue safe independent work if no VM is available.
4. After feature-specific scope decisions, consider FR2-10, read-only FR2-11 and FR2-12 first; prioritize 13/14 by concrete operational benefit.
5. P2/P3 need actual demand and separate tasks. A deliberately smaller release can precede broad book coverage; do not equate that release with book completion.

Runtime fixes require a fresh CI entry check. This roadmap sets no deadlines, creates no tags and does not commit to .deb/.rpm packaging; packaging remains a later decision.

### 8. Package contracts

#### FR2-01 optional book-coverage matrix

Only if the research task is separately authorized, each row needs: ID, edition/chapter/subsection, source, use case, desired modern counterpart, existing implementation, tests, platform boundaries, side effects, status, decision and remaining evidence. States: `not assessed`, `partial`, `implemented`, `accepted`, `deferred`, `excluded`. Keep implementation separate from acceptance. No percentages without a defined denominator and no completion claims based only on represented chapter headings.

#### FR2-03 recovery

Exercise failure before deletion, after at least one deletion, at manifest removal and cleanup. A transactional backup or documented resumable strategy may be appropriate; explain the chosen approach in a short ADR. Include changed/unowned files, missing files, repeat calls, concurrency and permission failures. Do not guess from incomplete installation or delete backups/locks to unblock operations. Native interruption acceptance remains separate.

#### FR2-10 through FR2-14 productive features

Before code, define purpose, scope, sample output, exits, dependencies, non-goals and tests. Separate CLI, acquisition/backend, pure parser/model and presentation where useful. Version formats, keep secrets out of argv/logs, select network targets explicitly and bound runtime/output. Do not implicitly change DNS, LDAP, mail or monitoring targets.

### 9. Completion criteria

Each slice needs a focused diff, appropriate positive/negative tests, consistent EN/DE guides/manpages for CLI changes, changelog and honest evidence limits. Run `make test` per CONTRIBUTING in a suitable unprivileged checkout, then relevant additional checks. Verify Markdown Git mode `100644` and command mode `100755`.

Release only the accepted scope: close applicable RG-P0 gates or record an accountable justified exclusion. Do not relabel fixtures as native evidence. A completed modern book implementation additionally requires every relevant matrix row accepted or explicitly excluded, with exclusions visible in the completion claim.

### 10. Sources and maintenance

- [Original book and detailed contents](https://www.oreilly.com/library/view/perl-for-system/1565926099/)
- [Account system](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch03s03.html), [DNS](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch05s03.html), [LDAP](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch06s04.html), [mail](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch08.html), [security/network](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch10.html)
- [Reviewed baseline](https://github.com/SASD-Sysadmin/freeware/commit/337b7cff34c2818921d1df023f3c5e2d386301c8)
- [Release engineering](RELEASE-ENGINEERING.md), [privileged safety](PRIVILEGED-SAFETY.md), [platforms](PLATFORMS.md), [testing](TESTING.md), [development](DEVELOPMENT.md)

Maintain stable FR2 identifiers, label corrections and synchronize EN/DE. Never forward historical counts as current execution results. This is an auditable working plan, not a guarantee that one review found every defect.

## 5. Historical chapter plan and earlier review (October 2026)

The following material was the original `ROADMAP.md`. It remains an audit/history record, **not** a current implementation mandate. Its October 2026 inventory of 30 commands and its suggested next step describe only the stated earlier commit. It must not be silently applied to the November 2026 baseline.

**M9 release-gap review (29 October 2026):** The [release-gap register](RELEASE-GAPS.md) inventories 54 commands and prioritizes release evidence, native/privileged acceptance and documentation coverage. This does not announce a release.

**M9.2 documentation coverage:** Seven existing commands now have
individual English/German operator guides and direct README links.
The static repository documentation gap is addressed; this does not
close any manual VM, native platform or live-service release gate.

### Historical chapter-based development plan (14 October 2026)

**Goal at the time (no longer the active product requirement):** Complete useful administration tools for book chapters 2–10 before
considering the first release. The old engineering assessment retained below
is historical, **not** the active milestone sequence. M3 part 1 delivered the
safer installer; release artifacts and publication are intentionally deferred.
A chapter requires scoped behavior, platform boundaries, EN/DE guides, manpages,
and positive/negative tests before it can be considered complete.

| Chapter | Available coverage | Gaps | Status |
| --- | --- | --- | --- |
| **2 – Filesystem** | Inventory, permissions, links, quotas, integrity, opt-in `text-eol-normalize` for staged text imports | Evaluate mounts, ACLs, storage diagnostics and native EOL-conversion acceptance | Substantial, incomplete |
| **3 – User Accounts** | Inventory, group/home audits, guarded writes | Privileged VM acceptance, gap audit | Substantial, incomplete |
| **4 – User Activity** | `session-report`, `process-report`; `login-audit` (Linux `last`/`lastb`) | macOS native login history, attribution and completeness review | In progress |
| **5 – TCP/IP Name Services** | Hosts, DNS, NSS, resolver | Gap review and platform completion | Substantial, incomplete |
| **6 – Directory Services** | LDAPS/NIS diagnostics, TLS configuration audit | Scope/platform gap analysis | Partial |
| **7 – SQL Administration** | `db-probe` (M5.1), `db-health` (M5.2), `db-activity` (M5.3) for PostgreSQL/MySQL/MariaDB; MariaDB/MySQL `db-storage` (M5.4) | PostgreSQL storage backend, Oracle/SQL Server, MySQL blocker graph, growth reports and live cross-engine acceptance | In progress |
| **8 – Electronic Mail** | `mail-probe` (M6.1), `mail-queue` (M6.2), `mail-config-audit` (M6.3), offline workflow (M6.4); [manual partial lab test](MAIL-ACCEPTANCE.md) on Debian 12/Postfix 3.7.11 (20 Oct 2026) | Effective overrides, populated queue, isolated VM, IPv6/465, other platforms outstanding | M6 engineering scope delivered; operational gaps remain |
| **9 – Log Files** | `log-summary` (text), `journal-summary` (M7.1 JSONL priority), `syslog-summary` (M7.2 structured syslog), `ssh-auth-summary` (M7.3 offline SSHD), `auth-event-summary` (M7.4 offline sudo/su/PAM patterns), `log-summary-normalize` (M7.5 validated JSONL source summaries) | Live adapters, other PAM services, native macOS Unified Log, real event-level correlation, cross-format completeness | In progress |
| **10 – Security and Network Monitoring** | SSH, SUID, integrity and TCP checks; `network-interface-report` (M8.1); `network-route-report` (M8.2); `network-service-report` (M8.3); `firewall-config-audit` (M8.4.1 Linux, M8.4.2 provisional BSD PF/IPFW/NPF and M8.4.3 provisional Solaris PF/IPFilter/SMF; M8.4.5 Linux firewalld zone inventories) | Native BSD/Solaris/Linux-distro acceptance and HP-UX/IRIX firewall adapters, host-wide firewall-policy evaluation, process attribution, policy routing, advanced next hops and native platform acceptance | M8 in progress |

**Historical planned order:** M4 User Activity (live snapshots, then login history),
M5 SQL, M6 Mail, M7 Logs, M8 Security/Network, M9 chapter gap closure and
platform acceptance, M10 release artifacts. These are scope goals, not
commitments about dates or production readiness.

**Chapter 2 – Text line endings:** `text-eol-normalize` adds conservative
CRLF-to-LF detection and optional replacement for completed text-file imports.
The read-only default, file-type allowlist, binary screening, hardlink/symlink
handling and same-directory staging are covered by offline tests. Filesystem
metadata (ACLs, xattrs, inode, timestamps), concurrent writers and native
cron/WSL/other-platform acceptance remain documented limitations. See
[command guide](commands/text-eol-normalize.md).

**M8.5 Linux acceptance:** M8.5.1 adds `linux-platform-report` and a parser
fixture matrix for Debian, Ubuntu, Arch, AlmaLinux and Rocky Linux. Native
package manager and firewall checks, distro-specific CI and VM acceptance
remain **pending**. See [acceptance matrix](commands/linux-platform-acceptance.md).

**M8.5.2:** `linux-distro-matrix` adds hermetic fixtures, one-host identity
evidence and optional pre-cached digest-pinned container smoke checks. Native
firewall/MAC, package-manager, distribution-specific CI and VM acceptance
remain **pending**. See [matrix protocol](commands/linux-distro-acceptance.md).

**M8.5.3:** `linux-container-acceptance` provides opt-in, pre-cached,
digest-pinned container tests for exact distro identity, toolchain, offline
tests, staged installation and selected command smoke checks. Actual image
runs, per-distro evidence and native kernel/firewall/MAC VM acceptance are
**pending**. See [container protocol](commands/linux-container-acceptance-protocol.md).

**M8.5.3a:** `linux-container-evidence-audit` validates canonical, per-target
JSONL reports and produces a five-distribution PASS/FAIL/SKIP overview.
Real image runs and native VM acceptance are still **pending**. See
[operator guide](commands/linux-container-evidence-audit.md).


**M4 part 1 contract:** `session-report` uses `who`; `process-report` uses
`ps`. Both are read-only, run without root, and accept offline test fixtures
through `--input`. They are snapshots, not exhaustive history or guaranteed
coverage of remote/container identities. Tests must not change real users.
See [session guide](commands/session-report.md) and
[process guide](commands/process-report.md).

### Historical engineering assessment (13 October 2026)

Repository: https://github.com/SASD-Sysadmin/freeware
Analyzed main commit: `f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb`
Assessment date: 2026-10-13


> **Status:** Engineering review and planning document, now versioned in the repository. Based on the repository tree, README, changelog, platform and test guides, CI, Makefile, and selected implementations. Priorities are engineering recommendations; they are not statements that every possible defect has been reproduced.

### 1. Verified inventory

- **30 executable commands:** 28 under `bin/`, two under `sbin/`.
- **30 manual pages:** 28 section-1 and two section-8 pages.
- **50 command-guide files:** 25 English and 25 German; some guides cover multiple commands.
- **Three Perl modules:** `Account.pm`, `External.pm`, and `Walk.pm`.
- **Testing:** 12 Perl regression suites, one Bash test script, and one opt-in DNS/LDAPS integration suite.
- **CI:** Mandatory Ubuntu and macOS checks pass at the reviewed merge commit. Ubuntu runs native DNS and LDAPS integration; macOS requires DNS while intentionally skipping LDAPS.
- **Status:** MIT-licensed; changelog uses `Unreleased`; no GitHub Release entries were returned at the time of review.

#### Side-effect legend

`R` locally read-only; `N` read-only probe that may access a network or name service; `W` intentionally writes in a designated mode; `P` privileged write that requires explicit confirmation. This is an operational summary, not an unconditional security guarantee.

### 2. Full command inventory

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

### 3. Coverage and remaining gaps

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

### 4. Priority work

#### P0 — Safety and truthful support statements

1. **Align CI and documentation.** `docs/TESTING.de.md` suggests optional macOS LDAPS checks can execute when clients exist, while `.github/workflows/ci.yml` explicitly sets `SASD_SKIP_LDAP_INTEGRATION=1`. Correct this mismatch, preserving mandatory TLS certificate verification.
2. **Design isolated privileged-operation testing.** `account-manage` and `quota-set` need explicit-opt-in throwaway Linux VMs with snapshots, before/after assertions, cleanup/rollback, and audit logs. Never mutate the working WSL instance or an everyday development host for this validation.
3. **Improve documented security boundaries.** Cover the two privileged tools in `SECURITY.md` and document exit code exceptions, including Nagios mode.
4. **Never silently skip required tests.** Keep required CI dependencies explicit; optional skips must remain visible.

**Done:** Accurate per-platform requirements; validated documentation references; reviewed VM test design; no unreported required-test skips; safe defaults unchanged.

#### P1 — CLI consistency, packaging, release discipline

1. Audit `--help`, `--version`, stderr, exit status, NUL/machine-readable formats. Earlier tools such as `rotate`, `file-integrity`, and `ssh-key-audit` do not follow all newer conventions; preserve compatibility deliberately.
2. Add a version-aware install manifest. The current Makefile removes files based on the present checkout, potentially leaving previously installed files that were removed upstream. Test upgrades, staged installs, and uninstall idempotence.
3. Add ShellCheck for shell sources and narrowly scoped contract/link/dependency checks, without turning optional runtime dependencies into global hard requirements.
4. Plan a reproducible source release, consistent version strings, release checklist and a possible first `v0.1.0` tag once the scope and gates are agreed.

**Done:** Regression, integration, documentation, install/uninstall, and contract checks pass; package contents and platform limits are recorded.

#### P2 — Read-only feature expansion only after the base is stable

Recommended order, **not implementation authorization**: (1) host/process inventory; (2) service-state reporting with systemd detection and honest WSL fallback; (3) mounts/filesystems; (4) network interfaces and routes; (5) structured log inspection with bounded output and privacy controls. Require a written purpose, boundary, dependency list, DE/EN guide, manpage, negative/positive tests, exit-code design and side-effect assessment for each command.

#### P3 — Later, separate commitments

FreeBSD/OpenBSD backend and CI work; package/update health; SMART/RAID monitoring; restorable and off-host backups; write-capable networking/firewall features only with an independent security model.

### 5. Proposed milestones and acceptance criteria

| Order | Milestone | Scope | Done when |
|---|---|---|---|
| M0 | Inventory | This review | 30 tools and risks mapped |
| M1 | `quality-contracts` | CLI contracts, documentation, platform matrix, CI skips | New contract tests green; EN/DE consistent |
| M2 | `privileged-safety` | VM safety test design and explicit apply regression | Snapshot/rollback documented; no production-host mutation |
| M3 | `release-engineering` | Install/version manifest, upgrade behavior, release checklist | Reproducible staged install and remove; RC feasible |
| M4 | `host-observability` | One or two targeted read-only commands | Cross-platform behavior and tests explicit |
| M5 | `bsd-platforms` | FreeBSD/OpenBSD matrix as runners/VMs allow | Supported features individually verified |

This was the recommendation in the October 2026 report and is not the current work order. The current product priorities are in section 2.

### 6. Explicit non-claims

- Green CI does **not** establish safe real-world account/quota modifications.
- The local LDAP fixture is not a full OpenLDAP server.
- FreeBSD, OpenBSD, and Solaris support remains unverified.
- `file-integrity` does not implement tamper-proof integrity attestation.
- An `Unreleased` changelog is not a versioned product release.

### 7. Immediate next action

Scope M1 into a small, reviewable `feat/quality-contracts` branch without modifying `main` before user acceptance. Maintain compatibility and keep required Ubuntu/macOS CI green before merging.

### 8. Audited sources

- [Repository tree](https://github.com/SASD-Sysadmin/freeware/tree/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb)
- [README](../README.md), [Changelog](../CHANGELOG.md), [Development](DEVELOPMENT.md), [Platforms](PLATFORMS.md), [Testing](TESTING.md), [Exit codes](EXIT-CODES.md)
- [Makefile](../Makefile), [CI](../.github/workflows/ci.yml), [Security](../SECURITY.md)
- [Verified main CI run #13](https://github.com/SASD-Sysadmin/freeware/actions/runs/38394032369)

---

**Maintenance rule:** Keep only `docs/ROADMAP.md` and `docs/ROADMAP.de.md` as canonical roadmaps; maintain substantive decisions in both languages. Preserve historical data as dated sections, not new continuation files. All release decisions still require separate evidence and authorization.
