# `firewall-config-audit` – conservative Linux and BSD firewall inventory (M8.4.1/M8.4.2)

## Purpose

The command reads **one explicitly selected Linux or BSD firewall source**, validates
its entire snapshot and prints a deliberately narrow, read-only inventory. The
implementation separates the native acquisition layer (`bin/firewall-config-audit`)
from the pure Perl parser (`lib/SASD/Freeware/FirewallAudit.pm` with a separate pure BSD adapter (`lib/SASD/Freeware/FirewallBSD.pm`). The parser can
be exercised on macOS, BSD or other platforms using stored Linux snapshots;
this does **not** make it a native firewall adapter for those platforms.

The command **does not change, enable, reload, flush, save or restore firewall
rules**. It does not run `sudo` and never selects executables from `$PATH`.
Firewall inspection may require elevated access. A permission error produces
exit code 3, *never* `INACTIVE` or a partial ruleset. No remote endpoints are
contacted intentionally.

## Explicit source and meaning

| `--source` | Native read-only acquisition | Scope and claim |
| --- | --- | --- |
| `ufw-config` | Open `/etc/ufw/ufw.conf` as a checked regular file | **configuration**: `ENABLED` or `DISABLED`, boot preference only |
| `ufw-status` | `ufw status verbose` | **runtime**: UFW management frontend `ACTIVE` / `INACTIVE`; count displayed UFW rules |
| `nft-json` | `nft --json list ruleset` | **runtime**: observed nftables tables/chains/policies/rule-object counts |
| `iptables-save` | `iptables-save` | **runtime**: IPv4 iptables chains, policies and `-A` rule counts |
| `ip6tables-save` | `ip6tables-save` | **runtime**: IPv6 iptables chains, policies and `-A` rule counts |
| `pf-info` | `pfctl -s info` (OpenBSD/FreeBSD) | **runtime**: PF reported `ACTIVE` or `INACTIVE`; **not** proof of coverage |
| `pf-rules` | `pfctl -s rules` (OpenBSD/FreeBSD) | **runtime**: `PARTIAL` main filter-rule and anchor-reference counts; anchor bodies omitted |
| `ipfw-list` | `ipfw list` (FreeBSD) | **runtime**: `PARTIAL` numbered static listing count; includes rule 65535, not dynamic states |
| `npf-show` | `npfctl show` (NetBSD) | **runtime** filtering `ACTIVE`/`INACTIVE` **and** separate **configuration** `LOADED`/`EMPTY` |

These are **different observations** and are not merged or added together.
`ufw-config ENABLED` does **not** prove that UFW is running. `ufw-status
INACTIVE` does **not** prove that no other firewall is running. An observed
nftables/iptables chain does **not** prove that a particular port is reachable,
that traffic is denied, or that a host is secure. A chain's displayed policy is
not a derived end-to-end network policy.

**iptables-nft compatibility warning:** `iptables-save` may show the same
underlying kernel data as `nft list ruleset`; iptables-save output cannot prove
whether the `legacy` or `nf_tables` compatibility backend is in use. There is
no deduplication, ruleset equivalence test or detection of a 'single active
firewall'. Other firewall managers, container namespaces, multiple netns and
VRFs are not inventoried.

## Examples

```sh
# Read the configuration only; no root is required if the file is readable.
bin/firewall-config-audit --source ufw-config

# Use explicit, read-only native backends; permissions may be required.
bin/firewall-config-audit --source ufw-status
bin/firewall-config-audit --source nft-json
bin/firewall-config-audit --source iptables-save
bin/firewall-config-audit --source ip6tables-save
# Run only on the matching BSD host (if permissions permit):
bin/firewall-config-audit --source pf-info
bin/firewall-config-audit --source pf-rules
bin/firewall-config-audit --source ipfw-list
bin/firewall-config-audit --source npf-show

# Replay safely captured data, independent of host platform.
bin/firewall-config-audit --source nft-json --input /path/to/nft-export.json
bin/firewall-config-audit --source ufw-config --input /path/to/ufw.conf
bin/firewall-config-audit --source iptables-save --input - --null
bin/firewall-config-audit --source pf-info --input /path/to/pf-info.txt
bin/firewall-config-audit --source npf-show --input /path/to/npf-show.txt
```

Only one source is inspected per invocation. Native execution is limited to
Linux for Linux sources, OpenBSD/FreeBSD for PF, FreeBSD for IPFW, and
NetBSD for NPF; offline snapshots are portable. BSD native compatibility is
**provisional until real-host acceptance**, particularly across OS versions. Use **trusted paths** for sensitive
firewall exports. `--input FILE` accepts only a readable ordinary file and
rejects symlinks (lstat + descriptor identity checks); `--input -` reads stdin.
A native backend that exits unsuccessfully invalidates the entire snapshot.

## Architecture and output contract

1. **Input acquisition:** a fixed, absolute-path native executable or safely
   opened snapshot; no shell argument interpolation, writable operations or
   escalation. `LC_ALL=C` ensures native UFW status uses stable headings.
2. **Full validation:** 8 MiB maximum; bounded lines, records and JSON depth.
   An incomplete or unsupported snapshot is rejected, not silently truncated.
3. **Source-specific pure parsers:** UFW config/status, nft JSON and
   iptables-save each use their own grammar and independently bounded counts.
   BSD parsing is isolated in `FirewallBSD.pm`; its source-specific status
   and partial-count rules do not modify the Linux parsers.
4. **Presentation:** only validated structural metadata, not individual rule
   expressions, source/destination IP addresses, comments, paths or secrets.
   Output is emitted **only after** the complete snapshot was accepted.

Default TSV header (literal tab separators):

```text
ENGINE  SCOPE  STATE  FAMILY  TABLE  CHAIN  POLICY  RULES
```

- `ENGINE`: `ufw`, `nftables`, `iptables`, `ip6tables`, `pf`, `ipfw`, `npf`.
- `SCOPE`: `configuration` versus `runtime`, never conflated.
- `STATE`: `ENABLED` / `DISABLED` for UFW configuration;
  `ACTIVE` / `INACTIVE` for the UFW frontend or PF/NPF runtime,
  `LOADED` / `EMPTY` for NPF configuration, `PARTIAL` for PF/IPFW listings,
  and `OBSERVED` for nft/iptables.
  `OBSERVED` describes a readable snapshot, **not an active firewall**.
- `FAMILY`: nftables kernel family (`ip`, `ip6`, `inet`, `bridge`, etc.) or
  `inet`/`inet6` for iptables. `-` denotes unavailable metadata.
- `TABLE`, `CHAIN`: safe structural identifiers. `-` means absent.
- `POLICY`: reported kernel chain policy, if present. No inferred policy is
  generated for regular nft or user-defined iptables chains.
- `RULES`: count of `rule` objects within an nft chain, `-A` entries in an
  iptables chain or UFW's displayed rule lines. These are **not comparable**
  across different engines. `-` means the source is not a rule inventory.

`--null` emits **eight NUL-terminated fields per row**, without a header.
The explicit placeholders and narrow tokens make downstream processing
predictable while avoiding disclosure of full filter rules.

### Accepted offline formats

UFW configuration (`/etc/ufw/ufw.conf` style):

```text
# /etc/ufw/ufw.conf
ENABLED=yes
LOGLEVEL=low
```

UFW status:

```text
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
```

nftables export (`nft --json list ruleset`):

```json
{"nftables":[
  {"metainfo":{"version":"1.0.9"}},
  {"table":{"family":"inet","name":"filter"}},
  {"chain":{"family":"inet","table":"filter","name":"input","type":"filter","hook":"input","prio":0,"policy":"drop"}},
  {"rule":{"family":"inet","table":"filter","chain":"input","expr":[]}}
]}
```

iptables-save:

```text
*filter
:INPUT DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -p tcp --dport 22 -j ACCEPT
COMMIT
```

The **final newline is mandatory** in text fixtures. `nft-json` accepts one
complete JSON object with a `nftables` array. Unsupported top-level nft
objects, duplicate tables/chains, orphan rules and malformed structures fail
closed. Known auxiliary nft objects (e.g. sets) are not counted as filter
rules. In iptables-save, all tables must be closed by `COMMIT`, and rules must
refer to declared chains. The parser intentionally does not evaluate rules.

## Exit codes and operational limitations

| Code | Meaning |
| --- | --- |
| `0` | Selected snapshot read completely and validated, even if it reports no rows |
| `2` | Invalid command line or missing/unsupported `--source` |
| `3` | Missing backend, permission error, changed input file, failed backend, excessive or malformed snapshot |

Errors never print raw paths or potentially sensitive rule contents. No
partial results are emitted. This strict, read-only V1 is deliberately **not**
a compliance scanner, policy simulator or firewall safety score. A configuration
snapshot is not necessarily synchronized with the kernel; separate captures
are not atomic. UFW formatting may vary across versions/locales; native
backend uses the C locale. An unsupported version is a validation failure,
not a reason to guess.

## Testing and future adapter policy

```sh
perl -c bin/firewall-config-audit
perl -c lib/SASD/Freeware/FirewallAudit.pm
prove -v tests/test_firewall_config_audit.t
prove -v tests/test_firewall_bsd_audit.t
perl -c lib/SASD/Freeware/FirewallBSD.pm
make test
make shellcheck
```

All ordinary regression fixtures are synthetic and run without root or
firewall changes. Check native output in isolated Linux laboratories before
production acceptance. CI checks packaging/install/uninstall on Ubuntu/macOS.
M8.4.2 adds **provisional** native OpenBSD/FreeBSD PF, FreeBSD IPFW and
NetBSD NPF acquisition; its offline parser is tested on Ubuntu/macOS but
requires actual BSD acceptance. Solaris PF/IPFilter, HP-UX IPFilter, and IRIX
`ipfilterd` remain planned. No source is a whole-host security score.

## M8.4.2 – BSD-specific interpretation and limits

* **PF status:** `pf-info` uses only the first `Status: Enabled` or
  `Status: Disabled` field in `pfctl -s info`. It does **not** count rules.
  `pf-rules` counts recognized `pass`, `block`, `match` statements and main
  ruleset anchor references separately. Both rows are `PARTIAL`, because
  anchor contents are not traversed, and NAT/rdr/tables are outside scope.
  An empty main ruleset is not interpreted as PF disabled.
* **IPFW:** `ipfw-list` counts numbered static listing lines, including
  the default rule `65535`, retaining duplicate numbers if printed.
  It does not include dynamic state (`-d`), rule-set enablement, NAT or
  module/kernel activity. The state is always `PARTIAL`, never `ACTIVE`.
* **NPF:** `npf-show` accepts both modern `# filtering:` / `# config:` and
  historical `Filtering:` / `Configuration:` headers. Two rows report
  runtime filter activity and whether a configuration is loaded independently.
  The rest of the text is **not** treated as a complete parseable rule
  language; no unsupported rule counts are invented.

Example sanitized output:

```text
ENGINE  SCOPE          STATE     FAMILY TABLE CHAIN   POLICY RULES
pf      runtime        ACTIVE    -      -     -       -      -
pf      runtime        PARTIAL   -      main  filter  -      3
pf      runtime        PARTIAL   -      main  anchors -      1
npf     runtime        INACTIVE  -      -     -       -      -
npf     configuration  LOADED    -      -     -       -      -
```

(The actual default format uses tabs.) These observations do not tell you
whether traffic will pass or drop. The parsers reject malformed, oversized,
truncated or contradictory snapshots; native command failure also exits 3.
For real-host testing use an isolated BSD VM, inspect only with listed read
commands, and compare with the OS's native tools before production use.

### Source references

- [UFW manual](https://manpages.debian.org/ufw/ufw.8.en.html)
- [nftables ruleset export](https://wiki.nftables.org/wiki-nftables/index.php/Operations_at_ruleset_level)
- [iptables-save manual](https://manpages.debian.org/iptables/iptables-save.8.en.html)

- [OpenBSD pfctl(8)](https://man.openbsd.org/pfctl)
- [FreeBSD firewall/IPFW handbook](https://docs.freebsd.org/en/books/handbook/firewalls/)
- [NetBSD npfctl(8)](https://man.netbsd.org/NetBSD-9.5/npfctl.8)
