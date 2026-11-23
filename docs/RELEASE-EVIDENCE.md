# FR2-05 – Release evidence register and acceptance record (draft)

[Deutsch](RELEASE-EVIDENCE.de.md) · [Licensing decision](LICENSE-STRATEGY.md) · [Release gaps](RELEASE-GAPS.md) · [Engineering](RELEASE-ENGINEERING.md) · [Platforms](PLATFORMS.md)

**Recorded:** 23 November 2026. **Evidence baseline:** `SASD-Sysadmin/freeware` `main` commit `686a86b88317c15a6be0413a3278e32d069dbd75`. **Status:** verified technical partial evidence, **not** an authorized release, RC tag, legal clearance or privileged VM acceptance. Any subsequent commit requires its own exact-SHA CI evidence.

## 1. Evidence vocabulary

| Term | Meaning |
| --- | --- |
| `PASS (local)` | Executed successfully in the specified environment; cannot be generalized to other OSes |
| `PASS (CI)` | The named GitHub Actions run/job passed for the exact SHA |
| `PARTIAL` | A subset of the requirement is evidenced, the complete gate is open |
| `MANUAL / OPEN` | External check or approval remains; **not a PASS or FAIL** |
| `SKIP` | Test was not executed, not silently accepted |
| `NOT APPROVED` | There is no release sign-off or authorized product publication |

## 2. Source-specific technical evidence

| ID | Revision / environment | Result | Evidence and limits |
| --- | --- | --- | --- |
| E-01 – historical Perl runtime | `b1960f4`, Debian/WSL2, Perl **5.14.4** | **PASS (local)** | 18 Nov operator log: 49 Perl suites, 6,146 TAP cases including 10 SKIP, two Bash groups; 74 sources/53 CLI entry points with no syntax/metadata failures. This is **not** a universal minimum Perl version; [runtime matrix](PERL-COMPATIBILITY.md). |
| E-02 – FR2-02 documentation | `15e434799c7de424217c8dce7cff35af1af00e2f` | **PASS (CI)** | [Actions `44950599429`](https://github.com/SASD-Sysadmin/freeware/actions/runs/44950599429), successful Ubuntu and macOS jobs. |
| E-03 – FR2-04b installer LICENSE | `1f6f4f04c7068603527c3867773cc1766bf50a86` | **PASS (local and CI)** | 37 license regressions, 226 targeted TAP cases (one Darwin SKIP), `make test`, and [Actions `45128966544`](https://github.com/SASD-Sysadmin/freeware/actions/runs/45128966544). Manifest-owned SHA-256 license delivery; **not** privileged VM acceptance. |
| E-04 – FR2-04a provenance | `686a86b88317c15a6be0413a3278e32d069dbd75` | **PASS (local and CI for tested contracts)** | 18 targeted auditor tests, `make test`, and [Actions `45131942704`](https://github.com/SASD-Sysadmin/freeware/actions/runs/45131942704) green on Ubuntu and macOS. Static scan: 132/132 MIT tags; 4 manual `REVIEW` and 2 `INFO`. Not legal ownership clearance. |
| E-05 – protocol/native-client integration | `686a86b`, GitHub Actions | **PASS (CI for defined scope)** | Ubuntu: offline suite, ShellCheck, loopback DNS/LDAPS and staged install/uninstall passed. macOS: regression, documented mandatory DNS integration and staging passed; macOS LDAPS is expressly not mandatory under [testing policy](TESTING.md). Not production-service testing. |
| E-06 – static release gaps | FR2-04a local working tree, subsequently committed as `686a86b` | **PASS for static inventory** | `make release-gap-audit`: `PASS=288`, `GAP=0`, `MANUAL=7`. Seven manual rows remain outstanding; static success is not release approval. |
| E-07 – author metadata | Complete 104-commit GitHub history reviewed | **PARTIAL** | Git author names list `Robin Goerlach` and `SASD-SysAdmin`; commit identities neither establish copyright ownership nor exclude externally reused code. |
| E-08 – licensing decision | Product decision 23 Nov 2026 | **DECISION RECORDED** | Current beta **MIT**; separate future `SASDGMBH` product **AGPL-3.0-only**. Rights chain, third-party notices and release implementation remain open; [strategy](LICENSE-STRATEGY.md). |

**Important:** FR2-04a/b are technically completed development slices; rights/provenance approval (`RG-09`) is **not** thereby closed. After this document is committed, the above CI results remain evidence for their previous SHAs, **not** a claim that the documentation commit has already passed CI.

## 3. Seven manual release gates

| ID (from `make release-gap-audit`) | Priority | Evidence available | Missing acceptance / next action |
| --- | --- | --- | --- |
| `current-ci` | P0 | CI `45131942704` green for `686a86b`, Ubuntu/macOS plus configured integrations | Verify required CI on the **exact final release SHA** and attach the run links to the acceptance record |
| `privileged-vm` | P0 | Offline `account-manage` and `quota-set` fixtures | Only after separate approval, test real apply/independent state checks/snapshot restore in a disposable VM |
| `staged-upgrade` | P0 | Staged install/uninstall, conflict and fault-injection regression coverage | Approve full fresh/repeat/upgrade/conflict/uninstall recovery exercises on safe staging/VM; do not infer power-loss safety |
| `artifact-provenance` | P0 | SHA-specific code and CI evidence | Reconcile tag/version, pristine tag checkout, reproducible source archive and independent SHA-256 comparison |
| `release-approval` | P0 | Risks and gap register present | Record scoped release, licensing, platform limits, known security issues, rollback and named authorized release decision for the exact candidate |
| `native-platforms` | P1 | Ubuntu/macOS CI | Limit support claims to native evidence, or run explicit native tests for additional distros/Unix platforms |
| `live-services` | P1 | Mock clients and DNS/LDAP loopback fixtures | Test realistic Postfix/SQL/LDAP/NIS/firewall environments for claims made, or mark behaviors not natively accepted |

Documentation, green CI or `GAP=0` **do not automatically close these gates**. A future AGPL SASDGMBH publication additionally requires legal rights/third-party notice review and a separate tested license/payload.

## 4. Acceptance form for real gate closure

For each gate, record and independently review:

| Field | Required content |
| --- | --- |
| Gate / reviewer | Exact gate ID, accountable reviewer role, date |
| SHA / tag | Full commit SHA, repository, version, OS and tool versions |
| Expected behavior | Positive and negative requirements and safety limits |
| Execution | Reproducible invocation, test environment/VM, private snapshot identifiers |
| Observation | PASS / FAIL / SKIP / BLOCKED, actual cases run, deviations |
| Evidence | CI URL and sanitized local file plus SHA-256; no secrets or private host data in Git |
| Recovery | Restoration procedure and independent restored-state verification |
| Decision | Explicit approved/rejected status, date and authorized signer |

## 5. Next safe step

1. Commit this **documentation-only** FR2-05 evidence snapshot and validate CI for its new SHA.
2. Prepare separately authorized disposable snapshotted VM work for FR2-06, **not** on normal WSL or production machines.
3. Deliberately limit first release platform scope; no five-distro/BSD/Solaris certification without real native tests.
4. A separate future `SASDGMBH` release follows the [decided AGPL-3.0-only strategy](LICENSE-STRATEGY.md) only after rights/notice checks and a final release decision.
