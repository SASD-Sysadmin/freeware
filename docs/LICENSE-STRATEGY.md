# SASD Freeware – Recorded licensing strategy (FR2-04 / FR2-05)

[Deutsch](LICENSE-STRATEGY.de.md) · [Provenance review](LICENSE-PROVENANCE.md) · [Release evidence](RELEASE-EVIDENCE.md) · [Project](../README.md)

**Decision recorded:** 23 November 2026, stated by the project owner in the development discussion. **Source baseline:** `SASD-Sysadmin/freeware` at `686a86b88317c15a6be0413a3278e32d069dbd75`. This records a product decision, **not** an already effective relicensing, copyright assignment or corporate release authorization.

## 1. Decided separation

| Track | License | Meaning |
| --- | --- | --- |
| Personal development and beta, currently `SASD-Sysadmin/freeware` | **MIT** | The current public source and its contributions remain under the existing MIT `LICENSE` and `CONTRIBUTING.md`. |
| Future official product publication in a **separate** GitHub organization `SASDGMBH` | **GNU AGPL-3.0-only** | The future official product is to be released under the exact AGPL 3.0 version. Its independent repository/source/release state is yet to be prepared, audited and approved. |

The chosen SPDX identifier is **`AGPL-3.0-only`**, not `AGPL-3.0-or-later`. The license *choice* is settled; legal authority, execution and acceptance are not.

The existing repository is **`SASD-Sysadmin/freeware`**, not `Robin-Goerlach/freeware`; this decision neither renames it nor moves it to `SASDGMBH`. No current AGPL release exists by virtue of this document.

## 2. Boundaries that must be preserved

1. An existing MIT grant is **not retroactively revoked** when a separate AGPL release appears.
2. Any later source revision also publicly distributed under MIT remains available under MIT from that source. For future new code to be distributed exclusively under AGPL, do not simultaneously distribute that code completely under MIT in the beta repository; plan the repository and development-track boundary.
3. Before publishing an AGPL version, verify actual rightsholders and authority, third-party reuse, preserved MIT/third-party notices, full AGPL license text and consistent SPDX, `LICENSE`, shipped files and documentation. GitHub organization membership does not prove copyright authority.
4. Receiving contributions under MIT is **not** an assignment of copyright or an automatic right to issue additional proprietary licenses. Compatible MIT material may be incorporated subject to its notice conditions; preserve those notices.
5. Changing an account is not relicensing. The future SASDGMBH repository must have its own reviewed sources, license metadata and formal decision. Do **not** mass-rewrite the existing MIT SPDX headers.
6. AGPL permits commercial use subject to its terms. Its network-source obligations are not a universal prohibition on commercial use of standalone offline CLI tools.

## 3. Implementation and authorization boundaries

- **Now:** Keep MIT unchanged in `SASD-Sysadmin/freeware`; FR2-04a/b document source notices and the tested manifest-owned MIT license delivery.
- **Before the corporate product:** Establish the actual legal entity, authorized representative and rights chain; inspect contributors and reused material, release payload and retained licenses; include full AGPL-3.0-only terms and any required MIT/NOTICE texts; audit SPDX and documentation.
- **Then:** Construct an independently auditable official product source, commit/tag and archive with reproducible SHA-256 and exact-commit CI; publish only after remaining P0 release gates and release approval.
- **Not authorized here:** No creation/push of an SASDGMBH repository, in-place relicensing of MIT beta, privileged test or public GitHub release is authorized by this document.

## 4. Decision is not legal or release clearance

| Topic | Status on 23 Nov 2026 |
| --- | --- |
| MIT for current development/beta repository | **DECIDED**; currently applied |
| AGPL-3.0-only for a distinct future SASDGMBH product | **DECIDED**; not yet published |
| Rights chain and third-party provenance for AGPL | **EVIDENCE OPEN** |
| Separate AGPL package, SPDX, license text and notices | **IMPLEMENTATION OPEN** |
| Approval of an exact official release commit | **ACCEPTANCE OPEN** |

**Primary texts:** [current MIT license](../LICENSE), [GNU AGPL v3](https://www.gnu.org/licenses/agpl-3.0.html), [SPDX AGPL-3.0-only](https://spdx.org/licenses/AGPL-3.0-only). This technical note is not a substitute for legal review of actual ownership and rights.
