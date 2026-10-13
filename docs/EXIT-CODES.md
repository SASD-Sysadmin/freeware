# Exit-status convention for name-service diagnostics

[Deutsch](EXIT-CODES.de.md) · [Project](../README.md) · [Integration tests](TESTING.md)

The name-service commands share a **bounded diagnostic convention**. Distinguish a *negative result* from a *test that could not run*.

| Code | Meaning | Examples |
| --- | --- | --- |
| **0** | The requested operation completed successfully, with no reported findings. | A DNS answer was obtained; the configured NSS source passed a structural check. |
| **1** | The operation ran but reported a negative result or finding. | `NXDOMAIN`, `NOERROR` without a matching DNS answer, unbound NIS client, rejected LDAPS handshake. |
| **2** | Invalid or incomplete invocation. | An unsupported option, invalid UID, malformed server address, or out-of-range DNS port. |
| **3** | Missing prerequisite or unexpected execution/protocol failure. | Missing `dig`, unreadable configuration fixture, malformed native-client output, or oversized response. |

This convention applies to `nss-lookup`, `host-resolve`, `ldap-probe`, `nsswitch-audit`, `dns-query`, `nis-probe`, and `ldap-config-audit`. Other programs (especially `tcp-check --nagios`) may have different, documented exit codes. Return code **0 never means that an optional check was silently skipped** in the command itself; skipped optional **test cases** are separately labeled `SKIP` by the test harness.

## Scripts consuming these commands

Do not use `if command; then OK; else FAIL; fi` if distinguishing missing prerequisites is important. For example:

```sh
./bin/dns-query --name good.test --server 127.0.0.1 --port 1053
status=$?
case "$status" in
    0) echo "DNS lookup succeeded" ;;
    1) echo "DNS lookup failed or returned no answer" ;;
    2) echo "Invalid command invocation" ;;
    3) echo "Check not performed: dependency or protocol error" ;;
    *) echo "Unexpected status: $status" ;;
esac
```

Do not infer that the DNS server is trustworthy, authoritative or DNSSEC-valid merely because it returned an answer. A resolver query is distinct from a direct DNS query, and anonymous LDAP rootDSE visibility is not an authentication test.
