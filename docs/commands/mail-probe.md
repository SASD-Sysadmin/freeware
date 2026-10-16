# `mail-probe` – SMTP connectivity and verified STARTTLS (M6.1)

[Deutsch](mail-probe.de.md) · [Roadmap](../ROADMAP.md) · [Return codes](../EXIT-CODES.md)

`mail-probe` is a **read-only SMTP protocol probe** (chapter 8). It checks a TCP
SMTP endpoint, validates a `220` banner, sends a fixed EHLO, checks a strictly
framed `250` multi-line response for the STARTTLS capability, issues STARTTLS,
performs a **certificate- and hostname-verified** TLS upgrade, and then repeats
EHLO **inside TLS**. The reported capabilities are from the secured session.
A bare open port, an SMTP banner or an unencrypted EHLO alone is never success.

## Usage

```sh
./bin/mail-probe --host mail.example.org
./bin/mail-probe --host mail.example.org --port 587 --timeout 5
./bin/mail-probe --host mail.example.org --null
# Local test/private CA only: explicitly trust a selected PEM certificate.
./bin/mail-probe --host localhost --port 1587 --ca-file /absolute/path/to/ca.pem
```

`--host` is mandatory; only ASCII DNS names (including IDNA A-labels) and dotted
IPv4 addresses are supported in this increment. Default port: **587**.
Timeout: **1..30** seconds (default 5), plus a finite overall deadline.
`--ca-file` requires an accessible absolute regular PEM file that is not a
symlink; without it the TLS provider uses its normal trust configuration.
Do **not** use a server certificate as a trust anchor in production unless that
is an explicit, reviewed trust policy. `--null` returns exactly four
NUL-terminated fields: host, port, `verified-starttls`, and comma-separated
advertised post-TLS capabilities. Otherwise a TSV header and row are printed.

The probe requires Perl 5 plus **IO::Socket::SSL >= 2.009**, with working
underlying OpenSSL/LibreSSL libraries and trusted CA certificates. This Perl
module is **not** part of Perl core. Install it through your OS or managed Perl
package process; the command does not download software. The offline TLS
regression suite additionally needs the `openssl` command to create disposable
certificates; the command itself does not execute `openssl`.

## Exit codes and security

| Code | Meaning |
| --- | --- |
| 0 | Complete SMTP sequence and TLS certificate/hostname verification succeeded. |
| 1 | Negative endpoint result, SMTP rejection, missing STARTTLS or failed TLS verification. |
| 2 | Invalid arguments or unsupported host representation. |
| 3 | Missing/unsafe prerequisites, timeout, truncated, malformed or oversized SMTP protocol data. |

Only fixed `EHLO sasd-probe.invalid` and `STARTTLS` commands are sent; no AUTH,
MAIL FROM, RCPT TO, DATA, client credentials, queue flushing or configuration
changes. No implicit TLS/465, fallback to plaintext, `--insecure`, opportunistic
success or public SMTP scanning features are included in M6.1. The program
limits response bytes, line length and count; control/binary characters are
rejected before output. It does not establish message deliverability, relay
policy, DKIM/SPF/DMARC validity or complete MTA health. It never claims to.

## Offline test

```sh
perl -c bin/mail-probe
prove tests/test_mail_probe.t
make test
```

Tests use local `127.0.0.1` fake SMTP servers, temporary certificates and TLS
handshakes. They never send mail or contact public SMTP hosts. IPv6, implicit
TLS/465, other MTA protocols and production integration tests remain future
work. On macOS, TLS-module availability must be checked explicitly; no implicit
assumption that it is preinstalled is made.
