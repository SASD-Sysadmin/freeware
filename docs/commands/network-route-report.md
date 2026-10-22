# `network-route-report` — read-only routing inventory (M8.2)

## Purpose and safety model

M8.2 inventories a **snapshot** of IPv4 and IPv6 routes. It does not create,
change or delete routes and needs no administrator privileges. It does not
query remote hosts. The report is not a reachability test, forwarding policy
assessment or proof that a route will be selected for a specific packet. The
kernel table can change between the IPv4 and IPv6 captures: atomicity is not
claimed. Routing addresses and gateway/interface associations are sensitive
infrastructure metadata; treat output accordingly.

The executable `bin/network-route-report` owns the command-line contract,
bounded file/native collection and output. The independent pure Perl module
`lib/SASD/Freeware/NetworkRoutes.pm` validates the complete snapshot and
normalizes it before **any** report is printed. Linux and BSD/macOS route
parsers have separate private functions. A future backend can reuse the row
contract without adding OS side effects to the parser. This continues the
M8.1 `network-interface-report` architecture without coupling both tools.

## Examples

```sh
bin/network-route-report
bin/network-route-report --family inet6
bin/network-route-report --input /path/to/linux-routes.json --format ip-json
bin/network-route-report --input /path/to/routes.netstat --format netstat --null
bin/network-route-report --input - --format ip-json --family inet
```

`--input` accepts only ordinary readable files (no symlinks) or explicit `-`
for standard input. `--format auto` detects the **snapshot container format**
(JSON vs. text); it never guesses an individual route's address family.
`--family all` is the default. `--null` outputs each of the eight fields with
a trailing NUL byte per field; it has no header.

## Native platform support

- **Linux:** `ip -j -4 route show table all` and
  `ip -j -6 route show table all`, using an executable selected from fixed
  absolute paths. Results are combined into the dual-family JSON envelope.
- **macOS/BSD:** `netstat -rn -f inet` and `netstat -rn -f inet6` using fixed
  absolute paths. The `Internet:` and `Internet6:` headings preserve family.
  The parser targets the familiar macOS/BSD `Destination Gateway Flags ...
  Netif` layout; different BSD releases can produce other layouts and need
  native acceptance tests before support is considered complete.
- No shell interpolation, privilege escalation, `ip route add`, `route -n add`
  or similar modifications. Backends must succeed before output is emitted.
  Linux network namespaces, VRFs and policy-rule evaluation are not explored.

## Offline input formats

For Linux **both-family** fixtures the complete JSON document must look like:

```json
{
  "inet": [
    {"dst":"default","gateway":"192.0.2.1","dev":"eth0","table":"main","metric":100},
    {"dst":"192.0.2.0/24","dev":"eth0"}
  ],
  "inet6": [
    {"dst":"default","gateway":"fe80::1%eth0","dev":"eth0"}
  ]
}
```

This deliberately explicit envelope avoids misclassifying a `default` route.
An **individual native `ip -j` array** is supported for offline replay when
`--family inet` or `--family inet6` is supplied. Full native collection
constructs this envelope itself. The parser validates both arrays, even when
only one family is selected from a dual-family fixture.

For macOS/BSD text fixtures use routing sections, for example:

```text
Routing tables
Internet:
Destination        Gateway       Flags  Netif Expire
default            192.0.2.1     UGScg  en0
192.0.2.0/24       link#4        UCS    en0
Internet6:
Destination        Gateway       Flags  Netif Expire
default            fe80::1%en0   UGcg   en0
```

The final newline is required for text snapshots; an `all`-family capture
must include both family headings even when a family has zero route rows.
BSD abbreviated IPv4 destinations such as `127`, `192.0.2`, and `10/8`
are preserved literally (not expanded to made-up CIDR blocks). Unsupported
route shapes, non-IP next hops and misleading fields are rejected. Please capture such output in an isolated
lab for future adapters rather than relaxing correctness checks blindly.

## Stable output schema

Default TSV header:

```text
FAMILY  DESTINATION  GATEWAY  INTERFACE  TABLE  METRIC  TYPE  FLAGS
```

Actual separators are TAB bytes. `FAMILY` is `inet` or `inet6`;
`DESTINATION` is `default`, an IP address or explicit CIDR; `GATEWAY` is an
IP literal (including IPv6 scope), a `link#N` interface reference or link
address; `INTERFACE` is the route device. The Linux-only `TABLE`, `METRIC`
and `TYPE` fields retain explicit route metadata. `FLAGS` preserves supported
kernel/BSD flag strings. `-` means **not available from the captured source**,
never an invented zero, missing route, or implicit reachability guarantee.
`default` with `FAMILY=inet6` is not an IPv4 default.

**Boundaries:** route JSON in arrays lacking an explicit `--family` is
rejected. Advanced Linux `nexthops`, `nhid`, `via` and encapsulation are
rejected, not flattened; this v1 schema cannot faithfully describe ECMP or
cross-family gateways. Routing policy rules, source selection, interface
flags, routing sockets and forwarding decisions are intentionally out of
scope. The 8 MiB total input limit, 8192-route limit and line-size guards
prevent unbounded parsing.

## Exit codes and diagnostics

| Status | Meaning |
| --- | --- |
| `0` | Entire selected snapshot is validated and reported; an empty complete table is valid |
| `2` | Invalid options or incompatible native format |
| `3` | Missing backend/file, failed native command, oversized, malformed or incomplete snapshot |

No partial inventory reaches stdout on status `3`. Errors do not quote raw
input, private paths or potentially sensitive route values. An invalid
individual route fails the complete report (fail-closed), rather than
silently dropping evidence.

## Test and operational acceptance

```sh
perl -c bin/network-route-report
perl -c lib/SASD/Freeware/NetworkRoutes.pm
prove -v tests/test_network_route_report.t
make test
make shellcheck
```

Synthetic offline tests include Linux/BSD IPv4+IPv6, default routes,
link-layer references, scoped IPv6, malformed records, symlink refusal,
route-size limits, NUL framing and no-partial-output guarantees. Ubuntu and
macOS CI install/uninstall assertions cover the executable, pure module,
guides and manpage. Native Linux and macOS **live** routing-format acceptance
is still a separately required lab check, not a claim made by offline tests.
