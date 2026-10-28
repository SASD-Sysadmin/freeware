# linux-container-acceptance – M8.5.3

[Deutsch](linux-container-acceptance.de.md) · [Matrix](linux-distro-matrix.md) · [Acceptance log](linux-container-acceptance-protocol.md)

## Purpose and scope

A **read-only-source**, opt-in container acceptance runner for five exact Linux
IDs: `debian`, `ubuntu`, `arch`, `almalinux`, `rocky`. Its result is a set of
separate evidence records, never a blanket claim of operating-system support.
The default PLAN mode performs **no engine calls** and reports every stage as
`SKIP/NOT_EXECUTED`. No image is downloaded or built by this program.

## Stages and evidence

| Stage | Inside an explicitly selected container | Meaning of PASS |
| --- | --- | --- |
| `IDENTITY` | `linux-platform-report` | Exact `ID` matches target (not just `ID_LIKE`) |
| `TOOLCHAIN` | Check `perl`, `make`, `prove`, `bash`, `git`, `mktemp` | Required executables are present |
| `TEST` | `make test` | Existing repository offline tests pass in this image |
| `INSTALL` | Staged install and uninstall in `/tmp` | Manifest-based lifecycle passes in the image |
| `SMOKE` | Selected local read-only SASD commands | Commands start and return expected success |

An identity mismatch prevents all further stages. A missing toolchain marks
`TOOLCHAIN` as SKIP and dependent stages as SKIP, never PASS. `TEST`, `INSTALL`
and `SMOKE` remain separately evaluated if their prerequisites passed.
`--require-complete` exits nonzero if any check is skipped.

## Safe usage

```sh
# Zero daemon access. Returns 25 SKIP records (five stages x five targets).
bin/linux-container-acceptance

# Output compatible with versioned JSON Lines archives.
bin/linux-container-acceptance --format jsonl

# OPTIONAL, only after an operator has provisioned a local image. Replace the
# example digest with the immutable digest of your inspected local image.
bin/linux-container-acceptance --run --engine podman \
  --target debian \
  --image 'debian=docker.io/library/debian@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' \
  --require-complete --format jsonl
```

**Do not use the placeholder digest as evidence**; select and verify a real
pre-cached digest yourself. The program runs `image inspect` and `run
--pull=never`, not `pull`. Docker/Podman must already be installed. For useful
results images must provide the listed tools; image provisioning is a
**separate, explicitly authorized activity** (and may require Internet access).

Container runtime restrictions: `--network=none`, `--read-only`,
`--cap-drop=ALL`, `no-new-privileges`, UID/GID 65534, read-only source mount,
container-local tmpfs, bounded memory/PIDs and GNU `timeout`. The image
ENTRYPOINT is replaced. Command outputs from build/test/install are suppressed
to avoid disclosing sensitive paths. The runner does not use `sudo` or write
to the repository. The caller must have access to the container daemon; prefer
rootless Podman or an isolated CI runner. **Docker socket access itself is
privileged**, even when the constructed container command is restricted.

Do not share a malicious/untrusted image with a privileged Docker daemon.
After a timeout inspect your engine for lingering containers: the runner asks
for `--rm` but cannot guarantee daemon-side cleanup after an abruptly killed
client. Also, some rootless engines cannot enforce memory/PID limits without
proper cgroup delegation; that is a failed run, not grounds to drop the limit.

## Exit status / format

TSV fields: `TARGET STAGE MODE STATUS REASON`. JSONL uses
`sasd.container-acceptance.v1` and the same five fields. Status values:
`PASS`, `FAIL`, `SKIP`. Modes: `PLAN`, `CONTAINER`.

- `0`: no FAIL, and SKIP allowed (by default).
- `1`: at least one FAIL.
- `2`: invalid command line.
- `4`: SKIP present and `--require-complete` requested.

**Limits:** This does not test the host firewall, systemd, SELinux, AppArmor,
packet filtering, real package installation, full database/mail integration,
VM boot, or kernel compatibility. A green container suite is **not Linux V1.0
certification**. Native VM acceptance is tracked separately under M8.5.4.
