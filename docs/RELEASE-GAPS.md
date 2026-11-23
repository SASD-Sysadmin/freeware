# SASD Freeware – Systematic release gap analysis

[Deutsch](RELEASE-GAPS.de.md) · [Release procedure](RELEASE-ENGINEERING.md) · [Roadmap](ROADMAP.md) · [Platforms](PLATFORMS.md)

**Baseline:** 2026-10-29, `main` commit `ae1571d98fc904cdbfebd1daa2ef9471bc62174f`.
This document records the **pre-release** state. A passing CI run is evidence
of tested behavior, not release approval. Neither static source inspection nor
fixture-based tests substitute for security review, native acceptance or
human-approved privileged VM exercises.

## 1. Countable repository inventory

| Item | Evidence at the above commit | Interpretation |
| --- | --- | --- |
| Commands | 52 under `bin/`, 2 under `sbin/` | 54 independent utilities |
| Manpages | 52 under `man/man1/`, 2 under `man/man8/` | A matching page exists for every command |
| Local Perl modules | 15 under `lib/SASD/Freeware/` | Reusable implementation |
| Offline tests | 43 `tests/*.t` and 2 `tests/test_*.sh` | Broad regression coverage, not native acceptance |
| CI | Ubuntu and macOS; latest verified main run `40838884447`: success | Limited to the tested platforms and behavior |
| GitHub publication | No official GitHub release found during inspection | Not yet a published product release |
| Dedicated command guides | 47/54 commands have matching English and German guides | Seven lack individual guides; shared guides may partially cover them |

The seven commands without **individual** English/German guides are:
`account-audit`, `file-integrity`, `hosts-lint`, `log-summary`, `ssh-key-audit`,
`suid-audit`, and `tcp-check`. They may be explained in existing grouped
guides. This is a discoverability and traceability gap, not a finding that
these programs necessarily lack any documentation.

## M9.2 follow-up (documentation coverage)

The historical **47/54** guide count above describes the M9.1 baseline
and is intentionally retained. In M9.2, dedicated English/German
guides were added for all seven named commands, with direct links from
the two READMEs and a new offline documentation-contract test.
A fresh `make release-gap-audit` should therefore report `GAP=0`.
This static result is **not** a human-approved release. The seven
`MANUAL` evidence gates remain open until independently verified.

## M9.3a follow-up (simulated installer interruption)

An isolated Perl regression now exercises one reproducible interrupted-upgrade
state and the fail-closed recovery boundary. It protects the old backup,
ownership manifest and unowned files, then checks a manually reconstructed
fixture and successful retry. This improves offline RG-04 evidence but **does
not close** the staged-upgrade MANUAL gate: real interruption, partial-rollback,
snapshot recovery and independently reviewed acceptance remain outstanding.

## M9.3b follow-up (partial rollback hardening)

Rollback now retains any surviving transaction backups if file removal or
restoration fails. Deterministic offline fault-injection tests cover damaged
payloads, occupied destinations and failed cleanup. This improves RG-04
regression evidence **without closing** its manual staged recovery gate:
crash durability, native rollback and independently reviewed VM tests remain
outstanding.

## M9.3c follow-up (cooperative concurrency and crash evidence)

A stable private advisory flock now serializes cooperating install/uninstall
processes. A transaction plan published before backup moves maps each old-N
and new-N to its relative path and digest, reducing ambiguity in manual crash
inspection. Hostile external writers and power-loss durability are **not**
solved; the isolated RG-04 and all seven manual gates remain open.

## FR2-03 follow-up (reversible uninstall; offline evidence)

Uninstall first quarantines all previously verified managed files, with
pre-commit failures handled by the existing digest-checked rollback. After
the manifest is retired, backups are removed individually while their plan
and retired manifest remain until payload cleanup completes. Deterministic
`tests/test_uninstall_transaction.t` covers move failure, manifest failure,
backup tampering and cleanup failure. These offline tests **do not** prove
native crash recovery or power-loss durability. RG-04 and all manual release
gates remain open.

## FR2-02 follow-up (Perl compatibility; 18 November 2026 operator evidence)

At source commit `b1960f4d0dda11e736fe71829953cfb5e4398c63`, an isolated Debian/WSL2 Perl **5.14.4** environment passed 74 source/53 CLI syntax-help-version checks, then 49 offline Perl suites (6,146 TAP cases, including 10 SKIPs) and two Bash rotation test groups. `make release-gap-audit` reported `PASS=288 GAP=0 MANUAL=7`. An initial `Errno.pm` generation defect was fixed in the private historical Perl build, **not** the SASD code; verified SMTP/STARTTLS used private non-core TLS modules. Current README claims have been corrected, and detailed dependencies are in [PERL-COMPATIBILITY.md](PERL-COMPATIBILITY.md). This records a *demonstrated* runtime, not a universal minimum; client-version floors, exact-commit CI, native tests, external notices and release authorization remain outstanding. RG-09 is not closed by this note.

## FR2-04 preliminary provenance review (22 November 2026)

At the historical baseline `15e434799c7de424217c8dce7cff35af1af00e2f`, the root `LICENSE` was MIT and all 130 reviewed source/test files carried MIT SPDX identifiers. At that baseline the installer omitted root `LICENSE`; this was **fixed in `1f6f4f0` and confirmed in Ubuntu/macOS CI**. `CONTRIBUTING.md` grants contributions under MIT without proving separate exclusive/commercial rights. Copyright ownership, full source history and third-party provenance need human review. See [FR2-04 license and provenance](LICENSE-PROVENANCE.md). **RG-09, all seven MANUAL gates, and any AGPL licensing decision remain open.**

## FR2-05 release evidence update (23 November 2026)

At `686a86b`, [Ubuntu and macOS CI `45131942704`](https://github.com/SASD-Sysadmin/freeware/actions/runs/45131942704) passed. FR2-04a and FR2-04b are technically complete; [FR2-05 evidence](RELEASE-EVIDENCE.md) records that SHA and prior suite, staging and Perl evidence. The owner has **decided** MIT for the existing development/beta repository and `AGPL-3.0-only` for a **separate future** `SASDGMBH` release; see [license strategy](LICENSE-STRATEGY.md). This is not a current MIT relicensing or legal clearance. The static gate count stays `PASS=288`, `GAP=0`, `MANUAL=7`; final release-commit CI, native/privileged acceptance, corporate rights and approval remain outside this documentation slice.

## 2. Prioritized release gaps

Priorities assume a **deliberately scoped first release**, not full support
for every Unix system. P0 must be resolved or formally excluded with an
approved change of scope before publication. P1 may be deferred when the
limitations are explicit. P2 is additional product development.

| ID | Priority | State | Evidence needed |
| --- | --- | --- | --- |
| RG-01 | P0 | Open | Approved isolated Linux VM exercise of `account-manage` and `quota-set`, including independent verification and snapshot rollback; see `PRIVILEGED-SAFETY.md` |
| RG-02 | P0 | Open | Version/tag reconciliation, archive from pristine tag checkout, SHA-256 verification, repeatable build and provenance |
| RG-03 | P0 | Open | Signed-off release evidence covering exact commit, required CI and DNS/LDAPS integration, install/upgrade/uninstall checks, deviations and decision |
| RG-04 | P0 | Open | Disposable staged conflict, interruption and rollback test evidence; verified recovery procedure and known installer transaction limitations |
| RG-05 | P1 | Partial | Explicit support matrix and genuine native tests; Ubuntu/macOS CI is not five-distro/BSD/Solaris or privileged backend acceptance |
| RG-06 | P1 | Partial | Live service evidence for claimed SQL, Postfix, LDAP/NIS and firewall features; mocked or loopback fixtures are not production-like validation |
| RG-07 | P1 | Documentation added in M9.2; CI verification pending | Seven missing dedicated command guides or formally documented shared-guide exceptions with direct links |
| RG-08 | P1 | Corrected in this change | Eliminate the obsolete hard-coded “30 commands” figure from development guidelines |
| RG-09 | P1 | Review pending | External dependency versions, third-party licensing, security reporting and per-command access/ownership requirements |
| RG-10 | P2 | Ongoing | Additional chapter 2–10 functionality based on user value, not an arbitrary first-release blocker |

**Release decision:** A version string such as `0.1.0`, green unit tests or
an automated inventory never authorizes publication. Unknown acceptance
results remain open.

## 3. Reproducible, read-only static inventory

`tools/release-gap-audit.pl` is a **maintainer tool**, not a utility installed
on managed systems. It reads files and checks command/documentation references.
It runs no included program, service, container or build, requires no root or
network access, and does not alter the repository.

```sh
make release-gap-audit
perl tools/release-gap-audit.pl --root . > /tmp/sasd-release-gaps.tsv
perl tools/release-gap-audit.pl --strict --root .
```

The TSV fields are `status`, `priority`, `category`, `item` and `detail`.
`PASS` means a specific static artifact is present. `GAP` marks a missing,
symlinked or unindexed artifact. `MANUAL` means independent evidence remains
to be reviewed; it is **never** an implicit pass. `SUMMARY` counts the states.
Default exit 0 means the scan completed, **not** that the release was approved.
`--strict` exits 1 when any static or manual gaps remain; it cannot confer
approval by itself.

Dedicated-guide presence is a deliberately limited, machine-checkable proxy;
it does not read or certify documentation semantics. A present test file
likewise does not prove that the latest CI run passed.

## 4. Proposed engineering sequence

1. **M9.1 – Evidence register:** Record gate ID, expected check, commit and
   environment, observed result, evidence link/hash and human sign-off. Never
   publish credentials or sensitive host evidence.
2. **M9.2 – Documentation reconciliation:** Resolve dedicated-guide coverage,
   dependency/version claims and native platform boundaries.
3. **M9.3 – Isolated acceptance:** Execute existing non-destructive procedures
   on disposable VMs; real privileged applies require separate human approval.
4. **M10 – Release candidate:** Only after P0 evidence is reviewed, build and
   independently verify a reproducible source candidate and decide on release.

Optional cron examples in command guides remain usage notes. This analysis
adds no scheduler, resident process, or central orchestration system.
