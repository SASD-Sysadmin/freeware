# `tcp-check` — Single IPv4 TCP connectivity probe

**English** · [Deutsch](tcp-check.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/tcp-check.1) · [Source](../../bin/tcp-check)

## Purpose and use

Attempts **one TCP connection** to a specified IPv4 endpoint with Perl `IO::Socket::INET`, then closes the socket. **No** TLS handshake, certificate verification, login, application protocol exchange, port-range scan or proof of application health.

## Behavior and checks

A host may be an IPv4 address or name resolvable to IPv4. `--port` must be 1–65535, `--timeout` an integer 1–30 seconds (default 3). Measures the time taken by the connection call; DNS resolution and system behavior may not be completely bounded by the connection timeout. Only check endpoints you are authorized to probe.

## Usage and options

```text
tcp-check --help
```

| Option | Meaning |
| --- | --- |
| `--host HOST` | Required IPv4 target or resolvable hostname. |
| `--port PORT` | Required integer 1–65535. |
| `--timeout SECONDS` | Connection timeout, integer 1–30 (default 3). |
| `--nagios` | Use Nagios-style error exit statuses. |
| `--help`, `--version` | Print metadata with no socket use. |

## Practical example

```sh
# Authorized loopback check: outcome depends on an actual listener.
./bin/tcp-check --host 127.0.0.1 --port 22 --timeout 3
# Same endpoint with Nagios-compatible status codes.
./bin/tcp-check --host 127.0.0.1 --port 22 --nagios
```

If no service listens on local TCP/22, a failure is expected. No authentication data are sent.

## Output and exit status

`OK: HOST:PORT TCP connection succeeded in N.NNN s` or `CRITICAL: HOST:PORT TCP connection failed (...)`. This describes **only a TCP connection**, not service health.

Default: `0` connected, `1` failed connection, `2` bad arguments. With `--nagios`: `0` OK, `2` CRITICAL connection failure, `3` UNKNOWN for invalid invocation (when `--nagios` is recognized). There is no WARNING threshold.

## Limits, safety and portability

IPv6 is not implemented. A TCP connection does not verify TLS, HTTP, SMTP, credentials or readiness. Local firewall, DNS and resolver policy affect behavior; test natively per platform. No privileges or external CLI clients are required. This is **not** a port scanner.

## Related resources

[`host-resolve`](host-resolve.md) · [Platforms](../PLATFORMS.md) · [Automation overview](automation-tools.md)
