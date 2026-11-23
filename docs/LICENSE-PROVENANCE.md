# FR2-04 – License, copyright, and provenance review

[Deutsch](LICENSE-PROVENANCE.de.md) · [Project](../README.md) · [Release gaps](RELEASE-GAPS.md) · [Roadmap](ROADMAP.md)

**Reviewed:** 22 November 2026. **GitHub source baseline:** `SASD-Sysadmin/freeware`, `main`, commit `15e434799c7de424217c8dce7cff35af1af00e2f`. **Update 23 November 2026:** FR2-04b commit `1f6f4f04c7068603527c3867773cc1766bf50a86` added manifest-owned `LICENSE` delivery; local regressions and Ubuntu/macOS CI run `45128966544` passed. Item A04 below is a **historical finding at `15e4347`, now corrected**. **Status:** verified static findings and decision proposal, **not** legal clearance, relicensing or release approval. Source and Git metadata cannot establish all ownership and rights by themselves.

## 1. Proposed licensing model, not yet a Freeware decision

For a different SASD project (SASD Editor Toolbox), a **personal MIT development/beta repository** and a separate **SASDGMBH AGPL-3.0-only production/release repository** had been explicitly discussed. This is a viable **proposal** for SASD Freeware, not a retroactively established decision for this codebase. The existing repository is **`SASD-Sysadmin/freeware`**, not `Robin-Goerlach/freeware`.

Changing the GitHub owner does **not** change a license. What matters is the licensed **version**, the actual notices accompanying its distribution, copyright and licensing authority, and compliance. Earlier MIT recipients retain their MIT grants. A later AGPL release of identical code does not retract those rights. Future revisions also published publicly under MIT remain usable under MIT from that source. AGPL-only treatment of new original code requires avoiding simultaneous unrestricted MIT publication of the same new code.

Use the explicit SPDX identity `AGPL-3.0-only` only if that option is selected; `AGPL-3.0-or-later` differs. AGPL permits commercial uses subject to compliance, and its network-source provision is mainly significant for interactive network services, not a magic safeguard for standalone offline CLI tools. Optional proprietary/commercial dual licensing requires sufficient additional rights in all covered contributions.

## 2. Source-grounded findings

| ID | Status | Item | Evidence / impact |
| --- | --- | --- | --- |
| FR2-04-A01 | CONFIRMED | Repository license | Root `LICENSE` is MIT; `README` and `AGENTS.md` describe MIT licensing. No AGPL switch performed. |
| FR2-04-A02 | CONFIRMED | Copyright attribution | Root license says `Copyright (c) 2026 SASD-SysAdmin`. This is a repository/project identity, not proof that a particular individual or SASD GmbH legally owns the rights. |
| FR2-04-A03 | CONFIRMED | Source/test SPDX headers | **76** source and maintainer-tool files under `bin/`, `sbin/`, `lib/`, `tools/` (excluding `.gitkeep`) and **54** files under `tests/` were inspected via GitHub: **130/130 contain `SPDX-License-Identifier: MIT`; no differing SPDX license IDs found.** A header is not independent proof of authorship. |
| FR2-04-A04 | FIXED at `1f6f4f0`; historical finding | License in installed payload | The installer at historical baseline `15e4347` omitted standalone `LICENSE`. FR2-04b adds `PREFIX/LICENSE` to the owned SHA-256 manifest with no-symlink, conflict, upgrade and uninstall tests. Local tests and Ubuntu/macOS CI pass at `1f6f4f0`; wider release gates remain open. |
| FR2-04-A05 | OPEN – especially for exclusive/commercial dual licensing | Contributions | `CONTRIBUTING.md` expressly accepts contributions under **MIT**. MIT contributions may generally be included within an AGPL-covered combined work while preserving their original MIT notices, but this does not establish exclusive ownership, copyright assignment or separate proprietary dual-licensing authority. |
| FR2-04-A06 | OPEN – provenance | Third-party material | No conflicting SPDX identifier found in inspected code/tests. Full code-snippet, generator, document/manual, historical-commit, and third-party attribution clearance **not established**. |
| FR2-04-A07 | OPEN – licensing authority | SASDGMBH rights chain | Identify legal rights holder(s), contracts/assignments, contribution rights and authorized release decision-maker. GitHub organisation ownership is insufficient. |
| FR2-04-A08 | CONFIRMED – release open | Manual release checks | Earlier FR2-02 static release-gap inventory reported `PASS=288, GAP=0, MANUAL=7`. All seven manual checks and RG-09 remain open. |

“P0 for distribution” is a proposed ship-readiness priority; it does not assert a legal breach in every installation scenario. The MIT text requires preserving the copyright and license notice in copies or substantial portions.

The historical Git tree at `15e4347` contains 341 tracked files, including documentation, manpages, metadata and tests. The 130-file SPDX scan does **not** establish source attribution for every remaining file. The accompanying local `tools/fr2-04-provenance-audit.pl` provides a repeatable read-only heuristic inventory, not a legal opinion.

## 3. Sequenced closure plan

1. **Establish ownership:** legal rights holder(s), individual authors, employment/contractual arrangements, outsider contributions and authorised company release signer. Do not infer copyright from an account name.
2. **Finish provenance inventory:** review full Git history, contributors, external snippets/examples, generated code, NOTICE/license files, submodules and packaged payload. Native commands such as `openssl`, `perl`, `dig`, `postqueue`, and `docker` are runtime dependencies, not automatically redistributed code.
3. **Fix MIT notice delivery in a separate tested slice (DONE, 23 November 2026):** explicitly include `LICENSE` and required notices in the installer-owned manifest. Keep strict installer path/symlink/ownership rules. Exercise fresh/repeat/upgrade, foreign or modified files, uninstall, rollback, and failed staging in disposable `DESTDIR`, then Ubuntu/macOS CI.
4. **Make separate formal license choices:** retain MIT for the current Freeware repo unless a change is approved; consider `AGPL-3.0-only` for the future SASDGMBH release only following rights review, complete AGPL text and correct SPDX/copyright notices. Preserve inherited third-party MIT notices. Record source provenance, commit and published version.
5. **Define beta-versus-release information flow:** if the same changes remain publicly available under MIT, they can still be obtained under MIT. An AGPL-exclusive future development track requires not distributing those new changes under MIT, e.g. via a private development repo or genuinely distinct release code. This is a product decision.
6. **Optional separate commercial terms:** only after authority to license every affected contribution is documented. AGPL alone does not bar commercial use.
7. **Release authorisation:** review complete payload, licensing/NOTICE coverage, tests, platform evidence, outstanding manual gates and accountable signoff. This audit authorizes none of those actions.

## 4. Reproducible read-only audit

The companion maintainer script requires only Perl and core modules; it does not elevate privileges, install software or modify files. Its findings are heuristics and must be assessed by a human.

```bash
repo="$(git rev-parse --show-toplevel)"
perl tools/fr2-04-provenance-audit.pl --root "$repo" \
  > "$HOME/tmp/.test-logs/fr2-04-provenance.tsv"
cat "$HOME/tmp/.test-logs/fr2-04-provenance.tsv"

git log --format='%h %aN' --all  # history clue only; not copyright assignment proof
```

`REVIEW` is a review task, not an adjudicated violation. `PASS` establishes only the named static property. `SUMMARY` is **not** release clearance. Do not publish logs containing private paths or contributor identities without review.

## 5. Source references

- Current repository [`../LICENSE`](../LICENSE) (MIT copyright and permission notice).
- GNU AGPL v3, section 13: https://www.gnu.org/licenses/agpl-3.0.html
- GNU license application guidance: https://www.gnu.org/licenses/gpl-howto.html
- GitHub Open Source Guide, relicensing and retained permissive notices: https://opensource.guide/legal/
- GitHub repository licensing: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository

This technical review is not personalised legal advice. Review ownership, proposed AGPL wording and any corporate release with a suitably qualified lawyer before publication.
