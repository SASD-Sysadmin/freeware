# mail-config-audit — static Postfix configuration review (M6.3)

[Deutsch](mail-config-audit.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/mail-config-audit.1)

`mail-config-audit` performs a **read-only, text-based security review** of
Postfix `main.cf` and optionally `master.cf`. No daemon is started, no
`postconf` is executed, and neither files nor mail messages are modified.
This is an **explicit-settings audit, not a test of the effective Postfix
configuration**. Postfix defaults, parameter expansion, lookup maps, and
service-level overrides may change actual behavior. A clean exit code is
**not** proof that a host cannot relay mail or expose authentication.

## Example usage

```sh
./bin/mail-config-audit --main /etc/postfix/main.cf --master /etc/postfix/master.cf
./bin/mail-config-audit --main /absolute/path/to/offline-main.cf
./bin/mail-config-audit --main /absolute/path/to/offline-main.cf --null
```

`--main` defaults to `/etc/postfix/main.cf`; `--master` is optional.
Paths must be absolute, regular readable files, not symlinks. The tool does
not require root if those files are readable. `--null` returns four
NUL-terminated fields per finding, plus one summary record.

The human-readable report is tab-separated:

```text
LEVEL  SOURCE  LINE  CODE
ISSUE  main    4     mynetworks-matches-all-addresses
NOTE   master  0     master-cf-not-inspected
Issues: 1
Notes: 2
```

The displayed example is illustrative, not an actual host scan. `SOURCE`
is only `main` or `master`; paths, configuration values, credentials,
server names, mail addresses and raw native-client messages are **never
printed**. A zero line number denotes a file-wide limitation.

## Checks performed

| Classification | Condition | Interpretation |
| --- | --- | --- |
| ISSUE | `mynetworks` explicitly contains `0.0.0.0/0`, `0/0`, or `::/0` | The configured trusted scope is extremely broad. |
| ISSUE | Unconditional `permit` precedes `reject_unauth_destination` or `defer_unauth_destination` in an explicit, literal relay policy | The configured ordering defeats the later relay boundary in that literal list; full deployment still needs review. |
| ISSUE | `smtpd_sasl_auth_enable=yes` without explicit TLS-only AUTH or mandatory global SMTPD TLS | The main.cf settings may permit plaintext authentication, unless a service override protects it. |
| ISSUE | Malformed main.cf assignment, orphan continuation or duplicate key | The static configuration deserves correction or deliberate review. |
| NOTE | Empty or implicit relay policy, variables, access maps, other conditional `permit_*` rules | Unable to prove the actual relay restriction chain from this text alone. |
| NOTE | `mynetworks_style=subnet`, explicit TLS `none`, VRFY enabled | Security review recommended; the setting is not automatically a vulnerability. |
| NOTE | Absent `master.cf`, service `-o` overrides, unrecognized master syntax | Effective service behavior remains unverified. |

The program follows Postfix's basic `name = value` form and continuation
lines in `main.cf`. It does not implement the full Postfix grammar for
`master.cf`. It **reports detected `-o` overrides only as review items**.
In particular, a submission service may intentionally override global SASL
and TLS parameters. `main.cf` findings about SASL/TLS are possible-risk
signals, not assertions that an exposed service exists.

**Do not require `smtpd_tls_security_level=encrypt` on ordinary Internet
port 25 as a blanket hardening rule.** Opportunistic TLS is normal for MX
interoperability; use per-service policy and your organization requirements.
Relay enforcement in Postfix 2.10+ normally uses `smtpd_relay_restrictions`;
older installations and explicit empty policies require checking
`smtpd_recipient_restrictions` as well.

## Limits and status

- Each input file: maximum 2 MiB, 10,000 lines, 16 KiB per physical line.
  Input errors produce **no partial findings**.
- Final symlinks, relative paths, control characters and suspicious dot
  components are refused. Files are read without invoking shell commands.
- `0`: scan completed and no definite static ISSUE found; **NOT** an
  all-clear for running Postfix.
- `1`: one or more static ISSUEs found.
- `2`: incorrect options or positional arguments.
- `3`: missing/unreadable/oversized/malformed input or runtime error.
- The absence of `--master`, unknown defaults, TLS certificate validity,
  access-map results, transport maps, included configuration and active
  services are **not verified**. The tool does not claim to detect every
  form of open relay.

Documentation: [Postfix relay controls](https://www.postfix.org/SMTPD_ACCESS_README.html),
[postconf(5)](https://www.postfix.org/postconf.5.html),
[postconf(1)](https://www.postfix.org/postconf.1.html),
[SASL](https://www.postfix.org/SASL_README.html).
