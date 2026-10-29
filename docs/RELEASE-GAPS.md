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
| RG-07 | P1 | Open | Seven missing dedicated command guides or formally documented shared-guide exceptions with direct links |
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
