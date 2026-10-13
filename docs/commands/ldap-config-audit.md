# ldap-config-audit — OpenLDAP client TLS configuration review

[Deutsch](ldap-config-audit.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/ldap-config-audit.1)

Performs **static read-only checks** on a single OpenLDAP `ldap.conf` text file. Defaults are `/etc/ldap/ldap.conf` on Linux and `/etc/openldap/ldap.conf` on macOS; both can be overridden with `--file`. It flags `TLS_REQCERT never`, `allow` or `try`, duplicate/unknown `TLS_REQCERT` directives and malformed lines. A `ldap://` URI is a **note**: it may be secured separately by StartTLS, which this static check **cannot determine**.

**Values are never printed** because LDAP configuration can contain internal server names, DNs or credentials. `INCLUDE` directives are *not* followed; those files require separate review. Per-user LDAPRC, environment overrides, application-specific settings and effective TLS certificate checks are **not** evaluated. `ldap-probe` can complement this with an anonymous LDAPS server test, but neither tool verifies NSS integration.

## Examples

```sh
./bin/ldap-config-audit
./bin/ldap-config-audit --file /etc/ldap/ldap.conf
```

## Limits and exit codes

This is NOT a compliance verdict. No include expansion, NSS connection or TLS handshake.

Status `0`: clean/success; `1`: structural finding, DNS/NIS failure or no answer; `2`: invalid input; `3`: file/client missing, unsupported default or unexpected backend error. Inspect the output and do **not** interpret missing clients as a healthy configuration.
