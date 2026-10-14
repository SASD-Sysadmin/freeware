# Privileged operations: safety boundary and VM test plan

[Deutsch](PRIVILEGED-SAFETY.de.md) · [Testing](TESTING.md) · [Security policy](../SECURITY.md) · [Roadmap](ROADMAP.md)

## Scope and threat model

SASD Freeware distinguishes **read-only inspection**, **local writes**, and
**privileged system changes**. A command line is not authorization to alter a
host. In particular, an agent, CI job or administrator must not interpret a
successful preview as permission to run the corresponding apply operation.

| Utility | Potential write | Default/safeguard | Residual risk |
| --- | --- | --- | --- |
| `account-manage` | Linux users, groups and password locks | Preview by default; `--apply --confirm-apply`; local identity validation; root and trusted native tools | Native backend behavior, NSS changes during execution, existing sessions/SSH keys |
| `quota-set` | Linux user/group filesystem quotas | Preview by default; double confirmation; extra `--allow-unlimited` for zero values; exact mount-point and limit validation | Quota availability, filesystem-specific semantics, concurrent changes |
| `rotate` | Local numbered file snapshots | Copies source first; rejects symlink source/slots; cooperative directory lock | **Not transactional:** a later rename/removal failure can leave a partially rotated history; no off-host backup |
| `file-integrity --init` | New SHA-256 baseline manifest | Baseline outside watched tree; private staging file; atomic no-overwrite publication | Untrusted content changes during scanning, hard-link support, untrusted directories; no authenticity guarantee |

For `file-integrity`, initial publication requires a filesystem that supports
hard links within the manifest directory. Failed publication is reported, and
an existing manifest is never replaced. A forced termination (e.g. SIGKILL)
can leave a private `.sasd-integrity-*` staging file, which an operator may
inspect and remove; it is never a published baseline.

## Safe automated tests (including GitHub Actions)

Run `make test` for deterministic fixture-based tests; `make shellcheck` for
Bash static analysis on supported development systems. The security tests
cover explicit confirmation, refusal paths, fake backend non-invocation,
no-clobber integrity initialization, symlink refusal, failed snapshot copy,
and cooperative locking.

- `tests/test_privileged_safety.t` uses an isolated temporary directory and
  fake native programs. **It never supplies a fully approved account or quota
  apply invocation.** Running as root does not grant an exception.
- `tests/test_rotate_safety.sh` rotates only disposable test files, injects
  a failed copy and holds a cooperative lock using a paused fake `cp`.
- `file-integrity` tests only a disposable watched directory and a manifest
  in a separate temporary directory; `--check` never updates the baseline.

None of these tests should read or modify real `/etc` account databases,
create real accounts, enable quotas, or run a real privileged backend.
**Never add host-wide `sudo` to these suites.**

## Manual Linux VM lab — required before claiming real apply coverage

This is a controlled **test plan**, not a request to execute privileged
changes on a workstation, WSL distribution or production system.

1. Provision a disposable, isolated Linux VM with a known snapshot or backup.
   Verify that the VM can be reverted and that it contains no real identities,
   credentials or business data. Record the OS, kernel, filesystem, repository
   revision, tools, and the initial account/quota state.
2. Review the exact native commands and permissions. Select unique test-only
   account/group names and an isolated quota-enabled test filesystem. Verify
   that none are in use elsewhere. Start with default previews and record
   exit status, stdout/stderr and the proposed native command.
3. **Only inside that VM and with a human operator's separate approval**, test
   one `account-manage` action at a time, explicitly using the two approval
   flags. Verify the exact result with independent account/group inspection,
   including side effects on home directories and any existing sessions.
   Confirm password locking does **not** imply SSH-key or session revocation.
4. On the isolated quota filesystem, verify quota activation and baseline
   values independently. Perform one approved `quota-set` modification,
   check limits with independent quota tooling, and exercise invalid and zero
   values. Never run these steps against the VM's host/root filesystem.
5. Inject backend rejection or a missing prerequisite in the disposable VM,
   and record how nonzero status and diagnostics propagate. For `rotate`, test
   partial move failures separately and treat the result as a **known
   non-transactional limitation**, not a successful backup transaction.
6. Revert to the snapshot. Compare identities, `/etc` metadata, mounts, quota
   records and test files to the captured baseline. Record any residual
   changes and do not promote the release if state cannot be restored.

Record a lab report with revision, operator approval, before/after evidence,
expected/observed exit codes, deviations, and snapshot restoration result.
Passing CI alone does **not** satisfy this manual VM acceptance gate.
