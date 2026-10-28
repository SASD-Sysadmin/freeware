# M8.5.3 – Container acceptance evidence protocol

[Deutsch](linux-container-acceptance-protocol.de.md) · [Runner guide](linux-container-acceptance.md)

This document is a **procedure**, not a record of completed runs. As of this
milestone, no real five-distribution container or VM acceptance is claimed.

For each selected distro, record the exact Git commit, digest-pinned image
reference, Docker/Podman version, host OS/kernel and date, together with the
runner's original JSONL (not edited after generation). Verify the image's
`ID` from `os-release`, followed by toolchain availability, `make test`,
staged installation/uninstallation, and command smoke checks. A `SKIP` is
incomplete coverage and must remain visible. Save a separate issue for each
`FAIL` with host/environment conditions and a minimal reproducer.

| Target | Offline parser | Container identity/test/install/smoke | Native VM |
| --- | --- | --- | --- |
| Debian | Automated fixtures | Pending real image | Pending |
| Ubuntu | Automated fixtures | Pending real image | Pending |
| Arch Linux | Automated fixtures | Pending real image | Pending |
| AlmaLinux | Automated fixtures | Pending real image | Pending |
| Rocky Linux | Automated fixtures | Pending real image | Pending |

Image provisioning is performed by an operator outside this runner; no
registry downloads occur during the acceptance command. The runner only
operates on pre-cached images and suppresses untrusted container stdout,
except the strictly parsed identity report. Native firewall and host-security
checks must not run against production systems.
