# SASD Freeware – Repository Agent Instructions

These instructions live at the repository root and apply to the entire repository. Read any more specific `AGENTS.md` in a subtree before changing files there. Explicit user instructions and higher-priority operating constraints take precedence.

## 1. Product identity

Canonical repository: <https://github.com/SASD-Sysadmin/freeware>.

SASD Freeware is an independent, long-lived, MIT-licensed collection of focused command-line utilities, administration tools, scripts and reusable libraries for Linux and other Unix-like operating systems. Commands must be individually useful, scriptable and interoperable with ordinary Unix workflows.

This is **not** a book-reimplementation project, a mandatory framework, a monolithic application, a persistent administration daemon or a web-based management platform. Prioritize real administrative needs, correctness, security, maintainability and independently demonstrable quality over the number of features or chapters represented.

David N. Blank-Edelman's *Perl for System Administration* (2000) is historical technical background and may inspire independently designed functionality. Its chapters, listings and examples are **not** the product backlog, acceptance criteria, release requirements or mandatory implementation order. Historical book-coverage analyses are optional research records, not evidence of product readiness. Do not copy source material or examples without checking rights and appropriate attribution.

## 2. Applicable sources and precedence

For every task, inspect the affected code and tests before changing them. Consult as relevant:

- Root: `README.md`, `README.de.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`, `Makefile` and `.github/workflows/ci.yml`.
- Engineering: `docs/DEVELOPMENT.md`, `docs/TESTING.md`, `docs/EXIT-CODES.md` and `docs/PLATFORMS.md` (including their German counterparts).
- Safety/release: `docs/PRIVILEGED-SAFETY.md`, `docs/RELEASE-ENGINEERING.md` and `docs/RELEASE-GAPS.md` (including German counterparts).
- Plans: `docs/ROADMAP.md` (English) and `docs/ROADMAP.de.md` (German) are the only canonical roadmaps. Keep them synchronized; preserve dated historical reviews inside them rather than creating further continuation files. Distinguish historical analysis, proposed features, agreed scope and verified evidence.
- Relevant command guides in `docs/commands/`, manpages, tests and any subtree instructions.

Actual code and verified test results establish current behavior. Stable public CLI contracts and safety rules remain binding unless explicitly changed with a migration plan. A roadmap does **not** authorize all its tasks. Where a roadmap conflicts with the independent product identity or current evidence, document the conflict and recommend a correction rather than silently following it.

Keep existing milestone and `FR2-*` identifiers for traceability when referring to historical work. Do not turn a chapter-by-chapter inventory into a mandatory public product plan.

## 3. Entry checks and working-tree safety

Before an implementation slice:

1. Inspect the current branch, working tree, applicable instructions and unrelated local changes. Never discard uncommitted user work.
2. Check the actual `main` HEAD and relevant CI checks for that SHA where accessible; identify the exact revision you are analyzing.
3. Review existing implementations, tests, docs, published interfaces and risk boundaries.
4. Select one small, coherent, authorized work package. Avoid opportunistic unrelated features.

Treat unavailable evidence as **not verified**, not as a pass or fail. Avoid repetitive CI polling. If a source copy is not a real Git checkout, report that limitation and do not fabricate commit/index status.

## 4. Git and collaboration

Use focused, reviewable changes with clear commit messages. A feature/fix branch and pull request are preferred for risky or collaborative changes. Direct work on `main` is acceptable only when explicitly authorized and appropriate for the repository workflow; check the current head, avoid unrelated edits and run applicable checks before publishing.

Never force-push, rewrite unrelated history, remove others' changes or claim a push, merge or green CI without proof. Recheck the target if it has moved. Do not create tags, GitHub releases, distribution artifacts or production installations without a specific authorization. Do not require repeated approval for routine actions already authorized within the current slice.

## 5. Layout and implementation style

- `bin/`: general commands; `sbin/`: administration commands with operation-specific privilege rules.
- `lib/SASD/Freeware/`: installed Perl modules.
- `tools/` and `tools/lib/SASD/Freeware/`: maintainer tools and internal installer logic.
- `docs/commands/`: English and German command guides; `man/man1/` and `man/man8/`: manual pages.
- `tests/` and `tests/integration/`: offline regressions and explicit integration tests.

Prefer Perl for substantial parsing, reporting and administrative logic; POSIX shell or Bash when simpler and appropriate. Other languages require a concrete benefit and documented dependencies. Preserve good existing code rather than rewriting it for language uniformity. Avoid broad frameworks, unnecessary abstractions and hidden background services.

Use clear English identifiers and helpful comments explaining intent, failure modes, limits and trust boundaries. Communicate project findings to the user in German unless requested otherwise.

## 6. CLI and process contracts

- Preserve documented options, output formats and exit-code semantics; in particular, do not break special Nagios behavior.
- `--help` and `--version` must remain side-effect-free and succeed without elevated permissions, network access or host-data inspection.
- Document dependencies, privileges, side effects, examples, limits, errors, output and exit codes for each shipped command.
- Validate input; keep process invocation in explicit argument lists rather than interpolated shell commands. Prevent option and shell injection.
- Use bounded runtime and output for probes/parsers as appropriate; refuse ambiguous, malformed, incomplete or hostile data rather than reporting it as healthy.
- Keep secrets out of process arguments, logs, test fixtures and public evidence. Maintain TLS certificate and hostname verification.
- Establish and test the actual Perl/runtime/module version floor. Do not infer compatibility with Perl 5.8 from outdated documentation.
- FR2-02 historical operator evidence demonstrates a complete offline run on Perl 5.14.4 only in the recorded Debian/WSL2 environment; see `docs/PERL-COMPATIBILITY.md`. Never convert this into an unconditional version-floor, secure-production-runtime, native-client, CI or release claim.

### Application crash diagnostics and core dumps (25 November 2026)

The agreed CD-01–CD-07 planning scope lives in both canonical roadmaps, section 2.1. Current P0/FR2 priorities and release gates are unchanged. Implement only a separately authorized slice; start with CD-01 and review `bin/core-report`, its EN/DE guides, manpage and `tests/test_filesystem_tools.t`. Preserve its candidate-inventory contract; do not introduce a duplicate finder. Prefer small Perl/shell commands and optional native adapters, using repository naming conventions; no own debugger, daemon, framework or web interface.

- Treat dumps, binaries, symbols, debugger output and reports as untrusted and potentially secret-bearing. Use explicit authorized inputs, read-only defaults, synthetic secret-free fixtures, private outputs and bounded processing. Never commit real customer dumps or sensitive raw reports; no automatic uploads or symbol downloads.
- Use trusted patched tools in isolated non-root environments, preferably disposable and network-disabled. Disable debugger startup scripts and auto-loading; never execute the supplied inferior. Validate paths/identity, reject unsafe links/special files, use argument vectors without shell interpolation and bound time/resources/output. Flags alone are not isolation.
- No dump-setting changes, live attachment, crash generation, privilege escalation, archival/deletion or host mutation without separately approved scope. Synthetic crash generation and native testing require a separately authorized disposable VM without host secrets or production targets. Retention/cleanup preview is read-only; destructive actions require their own safety contract.
- Verify executable/symbol identity where possible; explicitly report missing/mismatched symbols, unsupported formats/platforms, partial output and failures. Distinguish facts, hypotheses and corroborated root cause; never claim native acceptance from mock tests or commercial readiness from implementation.
- Each slice needs a testable contract, EN/DE documentation, applicable manpages, regression and native evidence as appropriate. Record exact tested commits and limitations. Kernel crash analysis, live tracing/profiling and memory forensics are not implicit in initial application-core work.

## 7. Filesystem, installer and mutating operations

Inspect `tools/installation.pl` and its helper modules before any install/uninstall change. Preserve manifest-based ownership, content-digest checks, rejection of unowned/modified destinations, safe paths, symlink controls, persistent private cooperative locking, human-readable transaction mapping, verified rollback and retained recovery evidence.

Do not delete `.sasd-freeware-install.lock` or `.sasd-freeware-txn-*` data merely to remove a blockage. Never guess restoration destinations or overwrite operator changes. Advisory `flock`, `rename` and offline fixtures do not prove transaction atomicity or power-loss durability.

**Current uninstall safeguard and remaining follow-ups:** Uninstall protects verified managed files in a private transaction before retiring the ownership manifest. Pre-commit errors attempt digest-checked rollback; post-commit cleanup errors retain evidence and block automatic retries. Do not claim power-loss durability or close RG-04 without separate native acceptance. Also review shipped license notices and the Perl version/dependency claims. FR2-04 preliminary evidence in `docs/LICENSE-PROVENANCE.md` records the historical MIT LICENSE installer omission at `15e4347` and its fix at `1f6f4f0`; do not change project licensing, omit inherited notices or claim copyright assignment without documented authority. These remain investigation targets, not permission to change unrelated files.

Any operation touching users, quotas, firewall rules, services or other privileged system state requires explicit authorization. Default to read-only/preview behavior. Never run privileged integration or destructive failure injection on the user's workstation, everyday WSL distribution or production hosts. Such work requires a separately approved disposable, snapshotted VM with demonstrated restoration.

## 8. Testing and evidence

Use isolated temporary directories and disposable `DESTDIR` prefixes; never mutate actual `/etc`, system accounts, installed services or external infrastructure in normal tests. Follow `CONTRIBUTING.md` and run relevant checks in an appropriate unprivileged checkout. For long local runs, preserve complete test output with `set -o pipefail; make test 2>&1 | tee <local-log-file>` and keep logs with sensitive environment data out of Git:

```sh
make check
make test
make release-gap-audit
# Only when relevant and prerequisites are available:
make shellcheck
make integration-test
```

A documentation-only change normally calls for documentation/contract checks, not privileged tests. For fixes, include deterministic positive and negative regressions. Keep existing CI requirements: Ubuntu/macOS, mandatory DNS/LDAPS integration where configured, and the documented macOS LDAPS skip. Never relabel SKIP as PASS.

Distinguish **implemented**, **locally tested**, **CI-verified**, **native/integration tested**, **operator-observed**, **accepted** and **released**. The release-gap audit's seven unconditional `MANUAL` rows are not seven failed tests. A green CI build does not alone establish platform support, privileged safety, crash recovery or release approval.

## 9. Documentation, release and provenance

Update affected English and German guides together, plus manpages, README indexes, changelog and supported-platform statements as required. Preserve dated historical findings and add a clearly dated correction/current pointer instead of rewriting history. Verify Markdown mode `100644`, executable mode `100755`, UTF-8 and LF in a real checkout.

Document genuinely reused third-party material accurately; review applicable licenses and shipped notices. Merely drawing on historical technical ideas does not imply that the project implements the book or requires book-wide attribution. Separate optional research matrices from product-facing scope and release plans.

Before any release, resolve or explicitly scope out applicable P0 release gaps, confirm required tests and native evidence, verify a reproducible archive and its provenance, and record a responsible release decision. Never publish solely because a version string exists.

**Dated license policy (23 November 2026):** The project owner has now selected **MIT** for this development/beta source repository and **AGPL-3.0-only** for a **separate future** `SASDGMBH` product/release repository; see `docs/LICENSE-STRATEGY.md`. Do not present this as an existing relicensing or copyright assignment, do not rewrite the MIT `LICENSE` or source SPDX markers here, and do not publish a corporate AGPL repository without rights/notice checks and explicit release authorization. Use `docs/RELEASE-EVIDENCE.md` for exact-commit CI and the seven still-open manual gates.

FR2-06a test boundary: `tools/fr2-06a-staging-acceptance.sh` may only mutate a private temporary source copy and DESTDIR as a non-root operator. Never extend it to run `sudo`, real `account-manage`/`quota-set --apply`, `virsh` mutations or automatic snapshot recovery. Follow `docs/FR2-06-VM-ACCEPTANCE.md` and require explicit, separately recorded human authority before any real VM action. MANUAL gates stay open by default.

## 10. Completion and strategy handoff

At the end of an authorized slice, report: exact base/current commit, changed files, behavior, actual tests and CI evidence, compatibility/security impacts, remaining limitations, and the next small technical recommendation. Include a concise German handoff for the separate strategy discussion when appropriate.

The development chat may make routine reversible technical choices independently. Refer genuinely new product features, major interface changes, platform commitments and release-scope decisions to strategy. Avoid turning an isolated implementation issue into an unrequested product redesign.
