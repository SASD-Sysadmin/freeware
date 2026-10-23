# `firewall-config-audit` – conservative Linux firewall inventory (M8.4.1)

## Purpose

The command reads **one explicitly selected Linux firewall source**, validates
its entire snapshot and prints a deliberately narrow, read-only inventory. The
implementation separates the native acquisition layer (`bin/firewall-config-audit`)
from the pure Perl parser (`lib/SASD/Freeware/FirewallAudit.pm`). The parser can
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

# Replay safely captured data, independent of host platform.
bin/firewall-config-audit --source nft-json --input /path/to/nft-export.json
bin/firewall-config-audit --source ufw-config --input /path/to/ufw.conf
bin/firewall-config-audit --source iptables-save --input - --null
```

Only one source is inspected per invocation. Native execution is limited to
Linux; offline snapshots are portable. Use **trusted paths** for sensitive
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
4. **Presentation:** only validated structural metadata, not individual rule
   expressions, source/destination IP addresses, comments, paths or secrets.
   Output is emitted **only after** the complete snapshot was accepted.

Default TSV header (literal tab separators):

```text
ENGINE  SCOPE  STATE  FAMILY  TABLE  CHAIN  POLICY  RULES
```

- `ENGINE`: `ufw`, `nftables`, `iptables`, `ip6tables`.
- `SCOPE`: `configuration` versus `runtime`, never conflated.
- `STATE`: `ENABLED` / `DISABLED` for UFW configuration;
  `ACTIVE` / `INACTIVE` for the UFW frontend; `OBSERVED` for nft/iptables.
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
make test
make shellcheck
```

All ordinary regression fixtures are synthetic and run without root or
firewall changes. Check native output in isolated Linux laboratories before
production acceptance. CI checks packaging/install/uninstall on Ubuntu/macOS.
Future OpenBSD/FreeBSD PF, IPFW, NetBSD NPF, Solaris PF/IPFilter, HP-UX
IPFilter and IRIX `ipfilterd` should have **separate acquisition adapters and
parsers** with explicitly scoped evidence, not be mapped onto Linux grammar.
Do not claim those platforms are supported by M8.4.1.

### Source references

- [UFW manual](https://manpages.debian.org/ufw/ufw.8.en.html)
- [nftables ruleset export](https://wiki.nftables.org/wiki-nftables/index.php/Operations_at_ruleset_level)
- [iptables-save manual](https://manpages.debian.org/iptables/iptables-save.8.en.html)
