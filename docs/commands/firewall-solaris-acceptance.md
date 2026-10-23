# M8.4.3 – Solaris firewall adapters: operational contract and later acceptance

## Purpose and platform boundary

The `firewall-config-audit` CLI now supports **provisional**, strictly read-only
Oracle Solaris firewall snapshots. There are no Solaris machines in CI;
all automated tests are offline fixtures on Linux/macOS. **Do not claim Solaris
native support is verified until these acceptance steps run on real systems.**

Platform history matters:

- **Solaris 10 and Solaris 11.0–11.2:** IPFilter (`ipfstat`), managed by SMF.
- **Solaris 11.3:** IPFilter and PF coexist as mutually exclusive firewall
  alternatives; check which one is actually selected before reading rules.
- **Solaris 11.4:** PF replaces IPFilter; the latter is not available.

This tool does not choose a backend automatically. Its separate eight-field
rows are observations, **not firewall-protection verdicts**. SMF `online`
means a service is online; it does **not** establish packet filtering status.
`degraded` on Solaris PF may indicate an empty/default or fallback policy;
**never translate it to ACTIVE**. These nuances are vital to accurate audits.

## Sources and fixed read-only native commands

| `--source` | Native command (SunOS only) | Meaning |
| --- | --- | --- |
| `solaris-pf-service` | `svcs -H -o state svc:/network/firewall:default` | PF service state (`service` scope) |
| `solaris-pf-rules` | `pfctl -sr` | Root PF filter rules and anchor references (`PARTIAL`) |
| `solaris-ipf-service` | `svcs -H -o state svc:/network/ipfilter:default` | IPFilter service state (`service` scope) |
| `solaris-ipf-rules4` | `ipfstat -io` | IPv4 active *in/out* rule lists (`PARTIAL`) |
| `solaris-ipf-rules6` | `ipfstat -6io` | IPv6 active *in/out* rule lists (`PARTIAL`) |

Only the above exact arguments and absolute tool paths are supported. There
is **no `sudo`, `svcadm`, `ipf -f`, `pfctl -f`, `pfctl -e`, or reload operation**.
A missing utility or restricted privilege yields exit code 3 and no output.
This includes selecting IPFilter on Solaris 11.4, where it is not provided.

The CLI never concatenates sources, parses shell command lines, or guesses
which filter is actually controlling the host. Snapshot files supplied via
`--input FILE` are supported on all test platforms.

## Examples (on the appropriate real Solaris system)

```sh
bin/firewall-config-audit --source solaris-pf-service
bin/firewall-config-audit --source solaris-pf-rules
bin/firewall-config-audit --source solaris-ipf-service
bin/firewall-config-audit --source solaris-ipf-rules4
bin/firewall-config-audit --source solaris-ipf-rules6

# Safe offline replay when no Solaris machine is available:
bin/firewall-config-audit --source solaris-pf-service --input ./svcs-state.txt
bin/firewall-config-audit --source solaris-ipf-rules4 --input ./ipfstat-ipv4.txt
```

All native inspections are read-only; some need rights to view kernel
snapshots. The IPFilter commands use `-io` and `-6io` **without uppercase
`-I`**: `-I` switches to the *inactive* staging rule list.

## Eight-field output

`ENGINE, SCOPE, STATE, FAMILY, TABLE, CHAIN, POLICY, RULES` are the same
fields used by the existing Linux and BSD adapters. They are TSV by default
and support eight NUL-terminated fields per record using `--null`.

- `pf` or `ipfilter` identifies the source engine; `service` versus `runtime`
  preserves the different observation contexts.
- SMF states are kept literally as uppercase `ONLINE`, `OFFLINE`,
  `DISABLED`, `DEGRADED`, `MAINTENANCE`, `UNINITIALIZED`, `LEGACY_RUN`.
- `PARTIAL` means counted, recognized statements in **one root/active
  snapshot only**. It is not an assurance of completeness or a filtering
  status. The PF `pfctl -sr` root dump omits child-anchor bodies; IPFilter
  analysis does not include NAT, pools, or inactive staging lists.
- No rule expressions, IP addresses, interfaces, comments, file paths or
  service names read from input reach the report.

A rule count of zero does not mean no firewall, and a non-zero count does not
prove the firewall is running. Never aggregate these counts with BSD/Linux
sources, or infer network exposure or effective security policy from them.

## Later on-system acceptance (deferred, not waived)

1. On a non-production Solaris 10/11.2 system, capture `svcs -H -o state
   svc:/network/ipfilter:default`, `ipfstat -io` and, where available,
   `ipfstat -6io`. Compare their sanitized counts to the tool output.
2. On Solaris 11.3, test IPFilter and PF in **separate, non-concurrent**
   setups. Do not enable/reload either engine just for this test.
3. On Solaris 11.4, capture `svcs -H -o state
   svc:/network/firewall:default` and `pfctl -sr`; check the `degraded`
   case in addition to `online` and `disabled`. IPFilter should be
   documented as absent, **not silently mapped to INACTIVE**.
4. Confirm privileges and actual output dialects (including empty-list
   headings and rule numbering). Correct the parser with saved, **redacted**
   fixtures and add regression tests before declaring native acceptance.
5. Ensure that `make test`, `make shellcheck`, staged install/uninstall,
   Ubuntu and macOS CI still pass after any fixture-driven update.

### Official source documentation

- [Oracle Solaris 11.4 PF administration](https://docs.oracle.com/cd/E37838_01/html/E60993/pftask-pfctl.html)
- [Oracle Solaris 11.4 PF monitoring](https://docs.oracle.com/cd/E37838_01/html/E60993/pftask-mon.html)
- [Oracle Solaris 11 end-of-feature notices](https://www.oracle.com/solaris/technologies/end-of-feature-notices-solaris11.html)
- [Oracle IPFilter active rule listing](https://docs.oracle.com/cd/E19120-01/open.solaris/819-3000/eubbd/index.html)
- [Oracle Solaris 11.3 IPFilter and IPv6](https://docs.oracle.com/cd/E53394_01/pdf/E54829.pdf)
