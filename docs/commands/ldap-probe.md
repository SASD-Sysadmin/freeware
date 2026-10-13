# ldap-probe — anonymous LDAPS rootDSE probe

[Deutsch](ldap-probe.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/ldap-probe.1)

`ldap-probe` invokes an **optional, locally installed `ldapsearch` client** to read only the LDAP rootDSE. It requests the attributes `supportedLDAPVersion`, `namingContexts`, and `defaultNamingContext` with base scope and an anonymous LDAPv3 bind. No credentials are accepted, users/groups are not enumerated and nothing is modified on the directory server.

## Examples

```sh
./bin/ldap-probe --uri ldaps://directory.example.org
./bin/ldap-probe --uri ldaps://directory.example.org:636 --timeout 5
./bin/ldap-probe --uri 'ldaps://[2001:db8::10]:636'
```

**Do not run against a server without authorization.** A successful rootDSE response is evidence of a reachable service and the returned metadata, **not proof that LDAP identity lookups through NSS will work**. An anonymous rootDSE may be restricted by the server, even while authenticated LDAP works. Query traffic reaches the server.

## Security and compatibility

- Only `ldaps://HOST[:PORT]` (or bracketed numeric IPv6) is accepted. No `ldap://`, credentials, filters, base-DN overrides, URL query parameters, shell interpolation or StartTLS downgrade paths.
- The client is invoked using a Perl argument list, never the shell. The probe requests `-x`, `-s base`, `-b ''`, and `(objectClass=*)`, with a **1–10 second LDAP network timeout** (default 5). The response is limited to 1 MiB. This network timeout may not bound the entire operating-system DNS or TLS operation.
- The process forces `LDAPTLS_REQCERT=demand` for OpenLDAP clients; an invalid server certificate should cause failure. Certificate authorities and name checks remain the client's responsibility. **Do not disable certificate verification to obtain a passing probe.** Client implementations other than OpenLDAP may not understand the `-o nettimeout` option.
- The received LDIF is diagnostic data with control bytes escaped for terminal safety. An empty result is treated as a failed probe even if the client exits zero. Do not interpret returned attributes as a verified policy or distribute them without reviewing directory details.

## Requirements and exit status

Optional `ldapsearch` on an absolute component of `PATH` (for example from OpenLDAP client utilities). No Perl CPAN packages. `0` means the client query returned success; `1` means the LDAP query failed (TLS/anonymous-access/network errors are possible); `2` means invalid options/URI; `3` means the client or bundled support library is missing, or an internal error. Tool exit status **does not guarantee** identity resolution or server configuration correctness.
