# network-interface-report (M8.1)

**Chapter 10 – Security and Network Monitoring.** Read-only network-interface and IP address inventory for Linux, macOS, and selected BSD-style snapshots.

## Purpose and architecture

`network-interface-report` produces a finite snapshot of interface names, OS indices (when available), link states, IPv4/IPv6 addresses, CIDR prefix lengths, and Ethernet MAC addresses. It does **not** configure interfaces, ping hosts, discover neighbors, inspect routing, or assert that a connection is healthy. A device may change while the native command runs.

The implementation separates three responsibilities:

1. **Backend in `bin/network-interface-report`:** selects a fixed absolute-path native executable; uses list-form Perl pipe open (not a shell); reads a bounded snapshot and checks the child process status. No native binary is required for offline fixtures.
2. **Pure parsing in `lib/SASD/Freeware/NetworkInterfaces.pm`:** validates the entire JSON or `ifconfig` snapshot, interface names, addresses, link-layer addresses, masks, and cardinality. No operating-system reads or writes occur inside this module.
3. **Presentation in the executable:** emits stable seven-column TSV or unambiguous seven-field NUL records, but **only after successful validation**.

This deliberate separation allows additional OS backends without changing the display contract. Optimization, enhanced NIC metadata, and more exhaustive BSD compatibility are deferred.

## Requirements

- Perl 5 with core `Getopt::Long`, `FindBin`, `JSON::PP`, and `Socket` (including `inet_pton`), plus the installed SASD Perl library.
- Linux native mode: executable `ip` at `/usr/sbin/ip`, `/sbin/ip`, `/usr/bin/ip`, or `/bin/ip` (in that order), invoked as `ip -j address show`.
- macOS/FreeBSD/OpenBSD/NetBSD/DragonFly native mode: `/sbin/ifconfig` or `/usr/sbin/ifconfig`, invoked as `ifconfig -a`. **Only representative macOS-like fixtures are verified by the M8.1 tests; BSD native acceptance is outstanding.**
- Any platform: `--input FILE` or `--input -` accepts an exported snapshot; `--format ip-json|ifconfig` overrides format auto-detection.

No privileged rights or network connection are needed for the offline parser. Native commands only collect local interface metadata and must never run through a shell.

## Examples

```sh
./bin/network-interface-report
./bin/network-interface-report --family inet6
./bin/network-interface-report --input ./snapshot-ip.json --format ip-json
./bin/network-interface-report --input ./snapshot-ifconfig.txt --format ifconfig
./bin/network-interface-report --input ./snapshot-ifconfig.txt --family inet --null
ip -j address show > ./snapshot-ip.json       # Linux, optional user action
ifconfig -a > ./snapshot-ifconfig.txt          # macOS/BSD, optional user action
```

A single address yields one row. Interfaces with no address in the chosen family receive a **placeholder row** with `FAMILY`, `ADDRESS`, and `PREFIX` set to `-`; thus family filtering never silently makes an interface disappear. `INDEX` is `-` for the `ifconfig` format. `MAC` is `-` for interfaces without an Ethernet MAC address. Link state is a limited normalization, not a carrier or Internet-connectivity verdict. For `ifconfig`, explicit `status: active/inactive` takes precedence over the UP flag when present.

## Output contract

TSV header:

```text
INTERFACE<TAB>INDEX<TAB>STATE<TAB>FAMILY<TAB>ADDRESS<TAB>PREFIX<TAB>MAC
```

The tokens `<TAB>` in the example represent literal tab characters, not the word `TAB`. In NUL mode there is **no header** and every row contains exactly seven NUL-terminated fields in the same order. The parser validates all fields before presenting them. A scoped IPv6 address such as `fe80::2%en0` keeps its zone because discarding it would make link-local addressing ambiguous.

## Boundaries and safety

- Maximum snapshot: **8 MiB**; at most **512 interfaces** and **4,096 IP address records**; text lines are limited to 128 KiB. No partial output is emitted if input validation or the native backend fails.
- Named inputs must be regular readable files, **not symlinks**, with a descriptor-level device/inode check after opening. For stdin, the entire stream must end before parsing.
- Unknown or unsupported `ifconfig` supplemental lines are ignored; malformed recognized `inet`/`inet6` lines and malformed interface headers are rejected. This is intentionally **not** a fully general vendor-specific `ifconfig` grammar.
- Only canonical IPv4 and IPv6 addresses are accepted. Hexadecimal and dotted IPv4 masks must be contiguous. `ip-json` source values are validated and must not be treated as trusted OS facts when supplied by an untrusted file.
- IP and MAC addresses are **intentionally part of this inventory**. Handle reports as sensitive infrastructure information; unlike the Chapter 9 auth tools, this command must expose addresses to accomplish its purpose. No raw input content or operator-supplied file paths are echoed in errors.
- No claim is made that a reported interface exists after command completion, or that the snapshot is atomic.
- A nonexistent `ip` command is a prerequisite failure; we do **not** silently fall back to an unrelated command or fabricate a successful empty report.

## Exit statuses

| Code | Meaning |
| --- | --- |
| `0` | Entire snapshot parsed successfully (including valid interfaces without addresses). |
| `2` | Invalid argument or incompatible explicit native format. |
| `3` | Missing native backend, failed native command, unreadable or unsafe input, malformed or oversized snapshot. No stdout report. |

## Tests and remaining platform acceptance

```sh
perl -c bin/network-interface-report
perl -c lib/SASD/Freeware/NetworkInterfaces.pm
prove -v tests/test_network_interface_report.t
make test
make shellcheck
```

Synthetic fixture tests cover Linux `ip -j` and macOS-style `ifconfig`, IPv4/IPv6 and scoped addresses, link-only devices, output framing, malformed metadata, symlinks, input bounds and privacy-preserving diagnostics. Ubuntu and macOS CI must also verify staged installation of the command, module, guides and manpage, followed by removal. A native smoke test on a disposable macOS machine and representative FreeBSD/OpenBSD hosts remains a separate acceptance task; CI fixture coverage alone does not establish native support.
