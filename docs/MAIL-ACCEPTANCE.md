# M6.4 – Electronic Mail: integration and acceptance

[Deutsch](MAIL-ACCEPTANCE.de.md) · [Roadmap](ROADMAP.md) · [Mail tools](../README.md)

## Goal and evidence boundaries

M6.4 tests the **interoperability and limitations** of three separately
invoked diagnostic tools. It is not a combined MTA security scanner or a
security certification.

| Tool | Offline contract | Live acceptance |
| --- | --- | --- |
| `mail-config-audit` | Static main.cf/master.cf findings and notes, without exposing configuration values | Real readable Postfix files; inspect effective defaults and overrides separately |
| `mail-queue` | JSONL queue aggregate, negative inputs, no addresses/queue IDs | Native Postfix **3.1+** `postqueue -j` with normal permissions |
| `mail-probe` | Reproducible local SMTP/TLS fixtures in `test_mail_probe.t` | Controlled STARTTLS service with matching valid server certificate |

All standard tests are **offline**. They do not require Postfix, root access,
real users or Internet mail servers. The extra `tests/test_mail_workflow.t`
checks consistent exit-code categories, privacy, TSV/NUL output and the
limits of security conclusions. The existing TLS fixture suite needs
`IO::Socket::SSL` and `openssl`; if dependencies are unavailable it may
explicitly `SKIP`. **SKIP is not proof of successful native TLS acceptance.**

```sh
make test
prove -v tests/test_mail_workflow.t
prove -v tests/test_mail_probe.t
make shellcheck
```

## Live acceptance – controlled lab only

A **separate Postfix VM** (for example Debian) is useful for final operational
validation but is **not required** for building or running M6.4 offline tests.
Avoid testing live customer messages or altering production configurations.
Never send messages, flush queues or modify Postfix as part of this audit.

1. **Record the environment:** OS/version, Perl version, Postfix version
   (`postconf -h mail_version`), SSL/OpenSSL availability and tested SASD
   commit. Do not record passwords or identifying message metadata.
2. **Static text inspection**, with ordinary read permissions:

   ```sh
   ./bin/mail-config-audit --main /etc/postfix/main.cf --master /etc/postfix/master.cf
   ```

   `ISSUE` needs review, `NOTE` represents limited evidence. Exit codes
   `0`, `1`, `2`, `3` distinguish no definite issue, finding, usage error
   and missing prerequisites/invalid input.
3. **Review effective configuration separately**, locally and without
   publishing raw output: `postconf -n`, `postconf -M`, `postconf -P`.
   These read commands may reveal private configuration or access data.
   Inspect service overrides, `mynetworks`, relay control, AUTH and TLS.
   The SASD static parser does **not** resolve defaults, substitutions or
   lookup tables.
4. **Queue observation**, only on an administrator-controlled Postfix 3.1+
   system:

   ```sh
   ./bin/mail-queue --timeout 10
   ```

   `postqueue -j` is not an atomic snapshot. `deferred`, `hold` and unknown
   queues produce exit 1 but are not automatically security incidents.
   Never paste raw `postqueue -j` output in issues or public fixtures.
5. **Verified TLS**, only against a controlled STARTTLS test endpoint using
   a certificate matching the requested hostname:

   ```sh
   ./bin/mail-probe --host localhost --port 1587 --ca-file /ABSOLUTE/PATH/ca.pem
   ```

   This is an **example**, not a provisioned server. No SMTP AUTH or mail
   content is transmitted. Invalid certificates must fail; no downgrade.
6. **Capture sanitized evidence:** Platform, version, success/failure status,
   exit code, limitations and manual reviewer decision. Do not collect
   addresses, queue IDs, private keys or raw sensitive configurations.

## Acceptance matrix

| Evidence | Ubuntu CI | macOS CI | Native Postfix lab |
| --- | --- | --- | --- |
| Perl, CLI contract and offline fixtures | required | required | optional |
| Offline cross-command workflow | required | required | optional |
| Verified SMTP TLS loopback fixture | required with available dependencies | may explicitly SKIP without TLS dependencies | separate live test |
| Real Postfix `postqueue -j` | not in CI | not in CI | **pending** |
| Real effective main.cf/master.cf + overrides | synthetic | synthetic | **pending** |
| IPv6 and implicit SMTPS/465 | **unsupported** | **unsupported** | not enabled by M6.4 |

**M6.4 offline integration is complete** only after mandatory Ubuntu/macOS
CI passes and documentation agrees with actual behavior. **Production-like
mail acceptance remains pending** until native Postfix/TLS checks are
performed and recorded. Offline tests alone must not be presented as full
operational certification of Chapter 8.

## Recorded live test on 20 October 2026

The operator performed the following **manual** tests on `dev102`
(Debian 12, Postfix 3.7.11; **not** an isolated VM) using the M6.4
implementation on `main` (`6ff3ab3`). Postfix listened only on
`127.0.0.1:25` and was stopped after the tests.

| Evidence | Observation | Result |
| --- | --- | --- |
| Static `main.cf`/`master.cf` review | 0 ISSUEs, 3 NOTEs | exit `0` |
| Real `postqueue -j` snapshot | empty queue, TOTAL 0/0/0 | exit `0` |
| SMTP STARTTLS with valid private test CA | `verified-starttls`, `localhost:25` | exit `0` |
| SMTP STARTTLS without trusting test CA | certificate validation failed; no downgrade | exit `1` |
| Post-test state | no listener on TCP/25 | stopped |

This is evidence for these specific **paths**, not proof of handling a
populated live Postfix queue or certifying effective relay/TLS security.
The three static notes included a `master.cf` service override that has not
been documented as manually evaluated using `postconf -n`, `-M` and `-P`.
The negative TLS test covered an unknown CA, not every certificate fault.
IPv6, implicit SMTPS/465 and other operating systems were not live-tested.

**Host change:** The laboratory installation replaced Exim4 with Postfix on
`dev102`. The SMTP daemon was stopped, but a permanent MTA/autostart decision
is still pending. Any final operational acceptance should use an isolated VM
with no real mail and should never commit lab keys or raw certificates.

## Official references

- [postqueue(1) – `-j` and non-atomic queue listings](https://www.postfix.org/postqueue.1.html)
- [postconf(1) – read-only queries, `-M`, `-P`](https://www.postfix.org/postconf.1.html)
- [master(5) – service definitions and overrides](https://www.postfix.org/master.5.html)
- [Postfix SMTPD access controls](https://www.postfix.org/SMTPD_ACCESS_README.html)
