# linux-container-evidence-audit – M8.5.3a

[Deutsch](linux-container-evidence-audit.de.md) · [Container runner](linux-container-acceptance.md) · [Acceptance protocol](linux-container-acceptance-protocol.md)

## Purpose

`linux-container-evidence-audit` is a **purely local, read-only** checker of
JSON Lines reports produced by `linux-container-acceptance --format jsonl`.
It combines evidence from **Debian, Ubuntu, Arch Linux, AlmaLinux and Rocky Linux**
into a stable, five-target overview. It neither calls a container engine nor
fetches any image. The five reports must be collected by a human operator.

An individual target is `PASS` only if its report is from an actual
`CONTAINER` run and **all five** stages (`IDENTITY`, `TOOLCHAIN`, `TEST`,
`INSTALL`, `SMOKE`) are `PASS`. An absent target is `SKIP/NO_REPORT`, not
silently omitted. Any failed stage makes the target `FAIL`.

## Usage

```sh
# Safe empty summary: five visible SKIP/NO_REPORT results.
bin/linux-container-evidence-audit

# Collect a single target's report with the existing runner. An operator must
# provide an appropriate locally cached, digest-pinned image; this example is
# schematic and deliberately does not invent a valid registry digest.
bin/linux-container-acceptance --run --engine podman \
  --target debian --image 'debian=registry.example/debian@sha256:REPLACE_WITH_64_HEX' \
  --format jsonl > /tmp/sasd-debian.jsonl

# After collecting *all five* actual per-target JSONL files:
bin/linux-container-evidence-audit \
  --input /tmp/sasd-debian.jsonl \
  --input /tmp/sasd-ubuntu.jsonl \
  --input /tmp/sasd-arch.jsonl \
  --input /tmp/sasd-almalinux.jsonl \
  --input /tmp/sasd-rocky.jsonl \
  --require-complete --format jsonl
```

**Important:** The schematic digest above is not a working image reference;
replace it with the actual digest verified by the operator. Container images
must have the required tools installed *before* the no-network acceptance
run. Do not install packages in the acceptance runner or disable its isolation.

`--input FILE` accepts up to five regular, non-symlink files of at most 32 KiB.
Each file must contain **exactly five** canonical JSON Lines (the format
produced by the existing runner), one per stage, with a single target and mode.
The checker rejects duplicates, missing stages, contradictory stage gates,
extra fields, malformed JSON and noncanonical serialization. File names and
untrusted content are never echoed into the summary.

## Output and exit codes

Default output uses TSV columns:

`TARGET MODE STATUS PASS FAIL SKIP REASON`

JSONL (`--format jsonl`) uses schema `sasd.container-evidence.v1`. Possible
summary reasons: `ALL_STAGES_PASS`, `STAGE_FAILED`, `INCOMPLETE`, `NO_REPORT`.

- `0`: valid reports and no target `FAIL`. Without `--require-complete`,
  missing or skipped targets can still appear as `SKIP` in the output.
- `1`: at least one target failed an actual stage.
- `4`: `--require-complete` and at least one target is incomplete or absent.
- Other nonzero exit: invalid arguments or malformed/contradictory evidence.

## Important limits

A JSONL document is **not a signed attestation**. This checker validates report
structure and logical consistency, but cannot independently prove which
container image, Git commit, engine, kernel or host produced it. Retain the
source commit, pinned image references, engine details and original report
files in a separate operator-controlled acceptance record. A five-target PASS
is *only* evidence for these container-level checks; it is not proof of native
systemd, firewall, SELinux, AppArmor, kernel or VM compatibility.
