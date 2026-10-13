# host-resolve — system resolver diagnosis

[Deutsch](host-resolve.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/host-resolve.1)

`host-resolve` uses Perl's `Socket::getaddrinfo` and `Socket::getnameinfo` to request forward and reverse host resolution through the **operating system resolver**. This can use `/etc/hosts`, local caches, mDNS, DNS, or other mechanisms. It is **not a direct DNS protocol tester** and does not identify the upstream DNS server that answered. Nothing is changed.

## Examples

```sh
./bin/host-resolve --name localhost
./bin/host-resolve --name example.org --family ipv4
./bin/host-resolve --name example.org --family ipv6
./bin/host-resolve --address 127.0.0.1
./bin/host-resolve --address ::1
./bin/host-resolve --name localhost --null > addresses.bin
```

Use exactly one `--name HOST` or `--address IP` option. Forward resolution supports `--family any|ipv4|ipv6` (default `any`). Reverse resolution accepts **only a numeric IPv4/IPv6 address** and requests a name (`NI_NAMEREQD`); a numeric fallback is not misreported as a successful reverse lookup. `--family` does not apply to reverse queries. Duplicate addresses are removed. Inputs cannot contain whitespace/control characters and are limited to 253 bytes. Queries can cause outbound name-service traffic and can be subject to DNS policies and network timeouts.

## Output and exit codes

Columns are `DIRECTION FAMILY ADDRESS NAME`, with tab-separated rows and escaped unsafe bytes. `--null` outputs four raw NUL-separated fields per row and no summary. IPv4 and IPv6 results depend on the host's network and resolver policy.

- `0`: at least one resolution result; `1`: lookup failed or reverse name missing; `2`: invalid arguments; `3`: internal address-conversion failure.

Perl with Socket's `getaddrinfo`/`getnameinfo` APIs is required (typically Perl **5.14+**). No CPAN modules, `dig`, or `nslookup` are needed. Not all Unix platforms ship a sufficiently new Socket module; `--help` and `--version` are available only when Socket loads successfully.
