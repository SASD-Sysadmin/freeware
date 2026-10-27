# `linux-distro-matrix` – Linux distribution acceptance evidence (M8.5.2)

## What it proves (and what it does not)

This **read-only**, opt-in acceptance runner builds on the M8.5.1
`linux-platform-report` interface. It reports the same five targets in a
stable order: Debian, Ubuntu, Arch Linux, AlmaLinux and Rocky Linux.

**The three execution modes have fundamentally different evidentiary value:**

| Mode | Actual observation | What PASS means |
| --- | --- | --- |
| `offline` (default) | Static, synthetic `os-release` strings | Only that the parser handles this fixture |
| `host` | The *one* current host, through the existing `linux-platform-report` CLI | This host reports the selected distribution ID |
| `container` | `linux-platform-report` inside an explicit, pre-cached digest-pinned container image | That container can run the Perl report and reports the selected distribution ID |

**None of these is a native firewall, SELinux/AppArmor, systemd, package-manager,
production-readiness, performance or entire-distribution certification.**
For those checks see [the acceptance protocol](linux-distro-acceptance.md).

## Commands

From the repository root:

```sh
bin/linux-distro-matrix
bin/linux-distro-matrix --format jsonl
bin/linux-distro-matrix --mode host
bin/linux-distro-matrix --mode host --target debian --require-complete
bin/linux-distro-matrix --mode offline --target rocky
```

Native host mode is read-only and never asks for elevated privileges. On
non-Linux hosts all five targets are `SKIP`. On a Linux host, different
requested IDs are `SKIP/NOT_THIS_HOST`, not failures and not successes.
If acquisition fails on Linux, the selected tests are `FAIL/HOST_UNAVAILABLE`.

### Container mode (optional, explicit only)

You must obtain, inspect and cache an appropriate image **separately**. The
runner does not pull images or install Perl. The image must already contain
`/bin/sh` and `perl` on PATH. Specify the actual digest; tags are rejected.
For example, replace the placeholder with your locally cached image digest:

```sh
bin/linux-distro-matrix --mode container --engine podman \
  --target debian \
  --image "debian=docker.io/library/debian@sha256:YOUR_64_HEX_DIGEST" \
  --require-complete --format jsonl
```

`YOUR_64_HEX_DIGEST` is a placeholder, **not** a usable image reference.
Record the image digest, architecture, host kernel, container-engine version
and date in the separate operator acceptance record. Different images may
lack Perl: `MISSING_PERL` is a SKIP (or nonzero with `--require-complete`).

The runner uses only allowed absolute `docker` / `podman` and `timeout`
paths. The container is configured with `--pull=never`, `--network=none`,
`--read-only`, `--cap-drop=ALL`, `--security-opt=no-new-privileges`,
`--pids-limit=128`, `--memory=512m`, UID/GID 65534, and a **read-only** mount
of the checked-out project at `/workspace`. Execution has a timeout. No
shell interpolates the supplied image reference or filesystem path.

Containers can still pose host risk through the container engine and kernel.
Review image provenance and daemon privileges, and use a dedicated test VM
when evaluating untrusted images. On SELinux enforcing systems, a read-only
mount may be denied; **do not disable SELinux or relabel the source tree**
to force the check to pass. Docker and Podman versions differ in support for
runtime flags; unsupported or missing images are reported as failures.

## Machine-readable output

TSV (default) contains exactly seven tab-delimited fields:

`TARGET MODE STATUS OBSERVED_ID FAMILY EVIDENCE REASON`

JSONL (`--format jsonl`) provides one canonical object per target with
`schema=sasd.distro-matrix.v1` and the same seven data fields. Only vetted
identifiers and a fixed reason vocabulary are emitted; arbitrary pretty
names, source network settings and container stderr are suppressed.

- `PASS`: the **exact observed `ID`** equals the target (mode remains visible).
- `FAIL`: the attempted check failed or the observed ID disagreed.
- `SKIP`: the image was not configured, the host was not that target, or a
  declared prerequisite was absent. **SKIP is not PASS**.

Exit codes: `0` no FAIL (may include SKIP); `1` at least one FAIL;
`2` invalid arguments; `4` SKIP with `--require-complete`. When using the
runner as a release gate, always supply `--require-complete` and check its
exit code **and** the per-target mode.

## Boundaries and risks

The offline fixtures are intentionally built into `LinuxDistroMatrix.pm` and
use the same **pure parser** from `LinuxPlatform.pm`. They are synthetic
examples, not independently collected native platform snapshots.

No credentials, package-manager changes, root operations, firewall rules or
network connections are required by the code. The runner never invokes
`sudo`, starts services, or claims `ID_LIKE` proves a distribution identity.

For tests run `prove tests/test_linux_distro_matrix.t`; this test never runs
Docker/Podman and is safe in Ubuntu/macOS CI.

Reference: [os-release specification](https://www.freedesktop.org/software/systemd/man/latest/os-release.html),
[Docker run reference](https://docs.docker.com/reference/cli/docker/container/run/).
