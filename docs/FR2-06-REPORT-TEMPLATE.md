# FR2-06 – Manual release acceptance record template (English)

[Deutsch](FR2-06-REPORT-TEMPLATE.de.md) · [VM acceptance plan](FR2-06-VM-ACCEPTANCE.md) · [Evidence register](RELEASE-EVIDENCE.md)

**This is a template, not proof of testing or an approval.** Keep completed copies **outside public Git** if they contain hostnames, identities, storage paths or credentials.

## Identity and authorisation

| Field | Entry |
| --- | --- |
| Gate (`staged-upgrade`, `privileged-vm`, other) | NOT EXECUTED |
| Repository, branch, full commit SHA | NOT RECORDED |
| Candidate version/tag and MIT-beta vs AGPL-product track | NOT DECIDED |
| Date/timezone, operator, independent reviewer | NOT RECORDED |
| Debian/kernel/Perl/native tool versions | NOT RECORDED |
| Guest UUID, network, disks, mounts, backup identifier | PRIVATE RECORD ONLY |
| Previously verified complete restore? | BLOCKED |
| Separate permission for each `--apply --confirm-apply`? | NO |
| Raw log locations, SHA-256, access permissions | NOT RECORDED |

## Test matrix

| ID | Expected behavior and independent check | Actual / exit status / evidence hash | Status |
| --- | --- | --- | --- |
| ST-01 | Fresh isolated DESTDIR installation including LICENSE manifest | — | NOT RUN |
| ST-02 | Repeat install leaves content unchanged | — | NOT RUN |
| ST-03 | Unowned collision rejected; existing content preserved | — | NOT RUN |
| ST-04 | Upgrade changes scratch source only | — | NOT RUN |
| ST-05 | Modified managed file causes uninstall refusal | — | NOT RUN |
| ST-06 | Simulated transaction marker blocks operations | — | NOT RUN |
| ST-07 | Uninstall removes managed content only; lock/unowned files survive | — | NOT RUN |
| VM-01 | Isolated VM/network and complete disks/NVRAM inventory | — | BLOCKED |
| VM-02 | Independently captured guest/quota baseline | — | BLOCKED |
| VM-03 | Account preview changes nothing | — | NOT RUN |
| VM-04 | Quota preview changes nothing | — | NOT RUN |
| VM-05 | Individually approved account apply + independent check | — | BLOCKED |
| VM-06 | Individually approved quota apply on separate guest disk | — | BLOCKED |
| VM-07 | Negative cases refuse without side effects | — | NOT RUN |
| VM-08 | Full VM restore independently verified | — | BLOCKED |

Allowed states only: `PASS`, `FAIL`, `SKIP`, `BLOCKED`, `NOT RUN`. No skipped or blocked test can be silently upgraded to PASS. An empty table is not evidence. Sanitize privacy-sensitive content before publication.

## Independent evidence and deviations

| Test ID | Expected exit | Observed exit | Log location / SHA-256 | Deviation / action |
| --- | --- | --- | --- | --- |
| — | — | — | — | Not run |

## Recovery and release decision

- Expected restored state: **UNDEFINED**
- Actually restored disk/NVRAM/accounts/quotas: **NOT CHECKED**
- Independent comparison to baseline: **NOT CHECKED**
- Remaining risk/deviation/regression: **OPEN**
- Named accountable reviewer and authorisation: **NOT APPROVED**
- Gate decision: **OPEN**
- Product release status: **NOT APPROVED**

**Licensing decision already made:** current `SASD-SysAdmin/freeware` remains MIT; separate future `SASDGMBH` product uses AGPL-3.0-only, subject to rights and NOTICE clearance.
