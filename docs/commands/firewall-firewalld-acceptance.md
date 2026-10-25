# firewalld inventory – M8.4.5 Linux acceptance and limits

## Scope and safety

`firewall-config-audit` gains four **explicit** firewalld sources. This is a
read-only control-plane inventory. **Do not** infer filtering effectiveness,
Internet reachability, security posture or a one-to-one correspondence with
`nft list ruleset` or `iptables-save`.

The native adapter executes only `/usr/bin/firewall-cmd` (or another fixed,
absolute conventional system path) with literal, read-only arguments. It does
not execute `sudo`, a shell, `--reload`, `--add-*`, `--remove-*`, or
`--runtime-to-permanent`. If firewalld is missing, inaccessible or returns a
nonzero exit status, the command exits `3` without a header or partial report.
Some distribution policies may require authorization even for read operations.

| `--source` | Fixed native command | Scope / meaning |
| --- | --- | --- |
| `firewalld-state` | `firewall-cmd --state` | `daemon`, `RUNNING` is **not** an effective firewall verdict |
| `firewalld-active-zones` | `firewall-cmd --get-active-zones` | `runtime`, `BOUND` zone names only, or `NONE_BOUND`; source CIDRs / interface names are not disclosed |
| `firewalld-runtime-zones` | `firewall-cmd --list-all-zones` | `runtime`, `PARTIAL` per-zone Rich Rule count, not total rules |
| `firewalld-permanent-zones` | `firewall-cmd --permanent --list-all-zones` | `configuration`, `PARTIAL` per-zone Rich Rule count, not actual runtime |

`RULES` in the two full-zone reports counts **only explicitly displayed rich
rule entries**. It does not count services, ports, source bindings, policies,
forwarding, direct rules, nftables chains, runtime-only extensions or container
network policy. Even a zero is **not** evidence of an unfiltered host. `POLICY`
reports the displayed zone target; `PARTIAL` is deliberate. `NONE_BOUND`
means no explicit active zone bindings were displayed, **not** disabled
filtering or no default zone. A daemon state `NOT_RUNNING` can be replayed
from an offline fixture; the actual command may exit nonzero and therefore
returns a verification error rather than a claimed status.

## Examples

```sh
bin/firewall-config-audit --source firewalld-state
bin/firewall-config-audit --source firewalld-active-zones
bin/firewall-config-audit --source firewalld-runtime-zones
bin/firewall-config-audit --source firewalld-permanent-zones

# Nonprivileged, deterministic replay (never invokes firewall-cmd):
bin/firewall-config-audit --source firewalld-runtime-zones --input zones.txt
bin/firewall-config-audit --source firewalld-active-zones --input - --null
```

The CLI prints the existing eight-field tab-separated schema:

```
ENGINE  SCOPE  STATE  FAMILY  TABLE  CHAIN  POLICY  RULES
```

Source-specific examples (real TAB separators in the command output):

```
firewalld  daemon         RUNNING  -  -       -           -        -
firewalld  runtime        BOUND    -  public  bindings    -        -
firewalld  runtime        PARTIAL  -  public  rich-rules  DEFAULT  2
firewalld  configuration  PARTIAL  -  public  rich-rules  DEFAULT  0
```

## Parser design and fail-closed behavior

- `FirewallFirewalld.pm` is a **pure Perl parser**. Acquisition, full-snapshot
  validation, output formatting and native OS gating are separate layers.
- Every snapshot is bounded to 8 MiB and 16,384 lines; names and report fields
  are validated before publication. It rejects unknown zone attributes and
  unsupported output dialects rather than silently fabricating counts.
- Only zone names, a normalized target and counts reach output. Interfaces,
  CIDRs, ports, services and individual rich-rule expressions are withheld.
- A saved capture is **not** atomic with another source: permanent and runtime
  changes can happen independently. Comparing separate calls is advisory only.
- The parser recognizes a deliberately narrow subset of current firewalld
  text output. On unfamiliar versions it returns exit `3` pending review.

## Linux test matrix (native acceptance pending)

| Family | Suggested laboratory OS | What to check |
| --- | --- | --- |
| Debian / Ubuntu | Debian 12 and current Ubuntu LTS | firewalld optional; no assumption that UFW and firewalld both govern the host |
| Arch | Arch Linux | rolling-release output dialect, privileges and package paths |
| RHEL compatible | AlmaLinux 9/10 and Rocky Linux 9/10 | SELinux, D-Bus access, daemon state, runtime/permanent zones |
| Fedora | supported Fedora version | new firewalld output keys and default ruleset backend |
| openSUSE | maintained Leap / Tumbleweed | firewalld integration, command paths and zone targets |
| Alpine | maintained Alpine | optional firewalld/systemd alternatives; report unsupported rather than fabricate |

For each real-host acceptance, preserve `uname -a`, `firewall-cmd --version`,
firewalld package version, exit code and a **sanitized** native output sample.
Compare `firewall-config-audit` with the corresponding `firewall-cmd` read-only
output. Never make active network changes on a remote host just to exercise
the parser. Do not upload actual source CIDRs, interface names or rich-rule
expressions to public issues.

References: https://firewalld.org/documentation/man-pages/firewall-cmd.html
and https://firewalld.org/documentation/configuration/runtime-versus-permanent.html

**Acceptance status:** 278 synthetic tests in Linux/macOS CI; no native
firewalld/Alma/Rocky/Arch verification is claimed before recording it.
