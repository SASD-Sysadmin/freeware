# `linux-platform-report` – conservative Linux identity (M8.5.1)

## Purpose and contract

Read the Linux distribution identity from the `os-release(5)` data format and
report a **source-tagged, seven-column inventory**. This is the first building
block for M8.5 distribution-specific acceptance, **not** certification that a
distribution is supported or that a package manager, firewall daemon, SELinux,
AppArmor or any particular executable is available.

The implementation deliberately separates two concerns:

- `bin/linux-platform-report` acquires bounded input and formats output.
- `lib/SASD/Freeware/LinuxPlatform.pm` parses and classifies strings without
  reading files or executing any command. Tests can replay synthetic fixtures.

## Usage

```sh
bin/linux-platform-report
bin/linux-platform-report --input /tmp/os-release-copy
bin/linux-platform-report --input - < /etc/os-release
bin/linux-platform-report --null
```

Native mode requires Linux. `/etc/os-release` takes precedence over
`/usr/lib/os-release`; the latter is used **only if the former is absent**.
The two files are never combined. System-defined symlinks are legitimate;
operator-supplied `--input` filenames must be regular files, not symlinks.
Standard input is accepted as `--input -` on other operating systems for
offline tests.

`os-release` is **parsed, never sourced** by a shell. Unsupported or malformed
assignments cause a nonzero exit status without a partial report. Duplicate
keys use their last assignment, as specified by `os-release(5)`. Source content
is capped at 64 KiB; individual lines at 4096 bytes; at most 512 lines.

## Output

Default output is TSV (header + one data row):

```text
SOURCE  ID  ID_LIKE  VERSION_ID  FAMILY  EVIDENCE  VERSION_MODE
```

(`SOURCE`/fields are separated by **tabs**, shown here with spaces only for
legibility.) `--null` outputs exactly seven NUL-terminated fields and no
header. Unavailable values are `-`; unknown classifications are `unknown`.

- **SOURCE:** `ETC`, `USR_LIB`, or `INPUT`; neither a custom filepath nor an
  arbitrary vendor-supplied string is displayed.
- **ID:** authoritative vendor identity, or standard fallback `linux`.
- **ID_LIKE:** literal but syntactically vetted ancestry hints.
- **VERSION_ID:** identity's version, or `-` (Arch often omits it).
- **FAMILY:** a conservative lineage hint: `debian`, `arch`, `rhel`, `suse`,
  `alpine`, or `unknown`. Two conflicting inferred families yield `unknown`.
- **EVIDENCE:** `ID`, `ID_LIKE`, or `UNKNOWN`. Direct ID always takes precedence.
- **VERSION_MODE:** `VERSIONED` when VERSION_ID exists; `ROLLING` only when
  `ID=arch` without VERSION_ID; otherwise `UNKNOWN`. This is **not** a release
  lifecycle or support-status guarantee.

## Security, scope and failure modes

- No root rights required; no package manager, firewall, service or host
  configuration is modified; no commands are spawned to inspect the system.
- `--input` rejects symlinks, devices, FIFOs, control-byte framing, oversized
  or malformed data. `--input -` reads bounded stdin.
- Exit `0`: complete parsed snapshot; `2`: invalid arguments; `3`: host
  unavailable, unsafe input, parsing failure or I/O error.
- `ID_LIKE=fedora` does **not** prove DNF exists. `ID=rocky` does **not** prove
  SELinux/firewalld is installed or enforcing. The actual tools and services
  must be tested separately in M8.5.3 and M8.5.4.
- Native distribution acceptance is **pending**. CI tests on Ubuntu/macOS
  exercise parser fixtures and staged installation, not native coverage for
  Debian/Ubuntu/Arch/AlmaLinux/Rocky.

For the acceptance matrix, see [Linux platform acceptance](linux-platform-acceptance.md).
Specification: [os-release(5)](https://www.freedesktop.org/software/systemd/man/latest/os-release.html).
