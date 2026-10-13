# dns-query — Direct DNS protocol query

[Deutsch](dns-query.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/dns-query.1)

Uses the optional **`dig`** client to query DNS directly, bypassing `/etc/hosts` and the normal `getaddrinfo` pipeline. Compare this with `host-resolve`, which deliberately tests the **system resolver**. `--server` only accepts numeric IPv4 or IPv6 addresses. A result is successful only with status `NOERROR` **and at least one answer RR**. `NXDOMAIN`, `SERVFAIL` and empty `NOERROR` answers return status 1. It reports server output bounded to 128 KiB and escapes terminal-control bytes.

Queries can reach external DNS servers. Traditional DNS via `dig` is generally **unencrypted** and this tool **does not validate DNSSEC**. `--timeout` sets the native `dig` timeout; a separate overall safety timeout also applies. Optional `dig` may be absent on a target system or runner. Do not query third-party servers without permission or send private internal hostnames to public resolvers.

## Examples

```sh
./bin/dns-query --name example.org --type A
./bin/dns-query --name example.org --type MX --server 192.0.2.53
./bin/dns-query --name 1.0.0.127.in-addr.arpa --type PTR
```

## Limits and exit codes

A/AAAA/MX/TXT/NS/PTR/CNAME/SOA/SRV/CAA only; no AXFR or arbitrary dig arguments.

Status `0`: clean/success; `1`: structural finding, DNS/NIS failure or no answer; `2`: invalid input; `3`: file/client missing, unsupported default or unexpected backend error. Inspect the output and do **not** interpret missing clients as a healthy configuration.
