# `network-service-report` — local socket inventory (M8.3)

## Purpose and architecture

This read-only command inventories **local TCP listening endpoints** and
**unconnected UDP bindings**. It does not scan a remote host, open a test
connection, change a firewall rule or determine whether a socket is reachable
across a network. An entry bound to `0.0.0.0` or `::` does not prove public
exposure: firewalls, namespaces, routing, NAT and other controls matter.

The design deliberately separates three responsibilities:

1. `bin/network-service-report`: parses CLI options, acquires bounded native
   output from fixed absolute-path executables (no shell), safely opens offline
   fixtures and serializes results.
2. `lib/SASD/Freeware/NetworkServices.pm`: **pure parser** of complete `ss` or
   BSD-style `netstat` snapshots. It checks framing, address families, numeric
   IP literals, ports, queue fields, state semantics and output safety before
   returning rows. It executes no commands and performs no network I/O.
3. `tests/test_network_service_report.t`: positive and adversarial **offline**
   contract regression tests, without touching local network configuration.

This continues the M8.1/M8.2 design without making network interface and route
reports runtime dependencies. Future optional process attribution can live in
an independent adapter. We do not invent process owners when privileges or
platform APIs do not expose them.

## Examples

```sh
bin/network-service-report
bin/network-service-report --protocol tcp
bin/network-service-report --protocol udp --family inet6
bin/network-service-report --input /tmp/ss.snapshot --format ss
bin/network-service-report --input /tmp/netstat.snapshot --format netstat --null
bin/network-service-report --input - --format ss
```

`--input` takes a **regular, readable file** (symbolic links rejected) or `-`
for standard input. Without `--input`, the command executes only a fixed
native read-only backend. `--format auto` distinguishes text by a recognized
`Active Internet connections` heading versus `ss` lines; no address-family
guesses are made. Specify `--format` for a clearly reproducible fixture.

## Native platforms and known boundaries

- **Linux:** `ss -H -n -l -t -u`, with a trusted absolute executable path.
  Headerless numeric `ss` output includes TCP `LISTEN` and UDP `UNCONN`
  entries. Connected UDP and established TCP are excluded; other socket types
  and process names are not requested. The snapshot can legitimately be empty.
- **macOS and BSD family:** `netstat -an`. The parser requires a complete
  `Active Internet connections` / `Proto Recv-Q Send-Q ...` header, and accepts
  familiar `tcp4`, `tcp6`, `udp4`, `udp6` numeric endpoint rows. TCP `LISTEN`
  and **unconnected** UDP (wildcard peer) are reported; other Internet and all
  UNIX-domain rows are ignored. Different versions of FreeBSD/OpenBSD/NetBSD/
  DragonFly may need dedicated adapters after native acceptance tests.
- No root, `sudo`, `lsof`, `netstat -p` owner lookups or `ss -p` options are
  required. PID, executable, username, inode, namespace and container identity
  are **not** available in this schema. Privileged visibility can differ from
  unprivileged visibility: absence of a row does **not** prove absence of a
  service on a host or in another namespace.
- The two native backends produce point-in-time output. It is not an atomic
  system-wide snapshot and does not identify traffic direction, firewall
  policy, service health, server authenticity or accessibility from another
  host. Use separate inspection tools for those questions.

## Offline formats

Linux `ss` format, preserving six fields per record:

```text
tcp LISTEN 0 128 127.0.0.1:22 0.0.0.0:*
tcp LISTEN 0 4096 [::1]:443 [::]:*
udp UNCONN 0 0 0.0.0.0:5353 0.0.0.0:*
udp UNCONN 0 0 [fe80::1%en0]:547 [::]:*
```

A standard `Netid State Recv-Q Send-Q Local Address:Port Peer Address:Port`
header may also be included. `ss` may represent a bound address as `*:8080`.
When both endpoints are wildcards, the address family is **`unknown`**:
filtering by `--family inet` or `inet6` excludes that row. A family is never
invented from the port or a host default.

macOS-style `netstat -an`:

```text
Active Internet connections (including servers)
Proto Recv-Q Send-Q Local Address Foreign Address (state)
tcp4       0      0 127.0.0.1.22  *.* LISTEN
tcp6       0      0 ::1.443        *.* LISTEN
udp4       0      0 *.5353         *.*
udp6       0      0 fe80::1%en0.547 *.*
```

For `netstat`, numeric port is separated by a dot even for IPv6. Its protocol
suffix `4`/`6` explicitly provides the address family; unknown families are
not emitted from valid `netstat` records. `netstat` headerless or truncated
snapshots are rejected. Offline text captures must end with a newline; an
empty `ss` file is valid because the native command can emit no records.

## Stable output contract

The default TSV header contains **seven** tab-separated columns:

```text
FAMILY  PROTOCOL  LOCAL_ADDRESS  LOCAL_PORT  STATE  PEER_ADDRESS  PEER_PORT
```

Actual separators are TABs. `FAMILY` is `inet`, `inet6` or (only with
wildcard-only `ss` rows) `unknown`. `PROTOCOL` is `tcp` or `udp`. `STATE` is
**`LISTEN` for TCP** and **`BOUND` for unconnected UDP**; it is never called
`LISTEN` for UDP. IP literals retain numeric scope identifiers such as
`fe80::1%en0`. A literal `*` is an explicit wildcard/not-present endpoint,
not evidence of an external peer. `--null` emits each of seven fields followed
by a NUL byte, without a header. Source ordering is preserved; duplicate
rows are retained because multiple socket references may be meaningful.

The entire input is validated **before any bytes reach stdout**, including
records removed by `--protocol` / `--family`. Framing controls (NUL, escape,
stray CR), invalid numeric addresses, nonnumeric or out-of-range ports,
unexpected endpoint families, and unsupported row shapes fail the report.
Limits: **8 MiB of input**, **8192 physical lines**, **65536 bytes per line**,
and **4096 reported socket rows**. These caps are safety limits, not claims of
system completeness. Diagnostic messages do not echo raw host addresses,
fixture paths or source lines.

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | Entire supported snapshot validated; no bound/listening rows is valid |
| `2` | Bad option, family, protocol, format or incompatible native backend format |
| `3` | Missing/failed backend, file/open error, malformed, incomplete or oversized snapshot |

No partial TSV/NUL inventory is printed when the exit code is `3`.

## Testing and operational acceptance

```sh
perl -c bin/network-service-report
perl -c lib/SASD/Freeware/NetworkServices.pm
prove -v tests/test_network_service_report.t
make test
make shellcheck
# On a designated host, when reviewing live socket metadata is appropriate:
bin/network-service-report --protocol tcp
```

Linux native smoke tests and the offline suite do **not** demonstrate that
macOS/BSD implementations or privileged/container visibility are complete.
Capture and sanitize native variants from supported operating systems before
claiming full platform acceptance. Future work can add explicit process-owner
attribution with separate privilege rules and tests; do not silently attach
unverified owners to these rows.
