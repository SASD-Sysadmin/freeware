# Integration testing (Linux and macOS)

[Deutsch](TESTING.de.md) · [Project](../README.md) · [Exit codes](EXIT-CODES.md)

## Test layers

1. `make test`: **fast, offline unit/regression tests**. Runs Perl syntax, Bash checks, documentation checks and mock-client tests. It must not modify system accounts, files in `/etc`, or system services.
2. `make integration-test`: **opt-in local network integration**. Starts loopback-only DNS and, when prerequisites permit, an LDAPS server fixture. Calls the real `dig` and `ldapsearch` executables through the unmodified SASD commands. Uses random unprivileged local ports; creates a short-lived self-signed TLS trust anchor; no root privileges, external endpoints, directory users or credentials are required.
3. GitHub Actions: Ubuntu installs `dnsutils` and `ldap-utils` and **requires both** integrations. macOS **requires DNS**; LDAPS is intentionally skipped in macOS CI until its native client differences are validated separately. The ordinary test suite and staged install/uninstall run on both systems.

The test servers in `tests/integration/local_servers.py` implement **minimal fixed DNS and LDAP protocol responses**, not the functionality of full production BIND/OpenLDAP servers. This tests actual UDP, TLS, LDAP client compatibility, timeout handling and exit statuses, but **does not replace end-to-end testing against a production-like server**. Do not claim deployment readiness from these tests alone.

## Running locally

Required for the integration fixtures: Python 3 and core Perl modules. To exercise DNS, install `dig`; to exercise LDAPS, install `ldapsearch` and `openssl`. Example on Debian/Ubuntu:

```sh
sudo apt-get install dnsutils ldap-utils openssl
make test
make integration-test
```

On macOS, `dig` is commonly available; `ldapsearch` availability depends on the installation. If optional programs are missing, the corresponding tests display **`SKIP`**, not a fabricated success. To fail the run on a missing prerequisite, set the enforcement flags:

```sh
SASD_REQUIRE_DNS_INTEGRATION=1 SASD_REQUIRE_LDAP_INTEGRATION=1 make integration-test
```

The integration fixture operates on `127.0.0.1` and does not require inbound Internet access. The temporary certificate contains `localhost`, `127.0.0.1`, and the current local hostname, because OpenLDAP clients may canonicalize loopback connections. The certificate/private key are deleted when the test completes. Python is a **test-only dependency** and not required for the installed Perl commands. No CPAN downloads are required.

## Tested scenarios

- A and AAAA responses from a real UDP listener, including exact answer values.
- `NXDOMAIN` and `NOERROR` with no answer (both return exit code 1).
- Invalid DNS port rejected with exit code 2, before client invocation.
- TLS connection with a temporary trusted certificate, LDAP anonymous bind and rootDSE base-scope search.
- TLS connection with a missing trust anchor rejected, even if the caller sets `LDAPTLS_REQCERT=never`.
- Plaintext LDAP URI rejected before contacting the client.

A green GitHub job should include the integration step, not just `make test`. If an integration job fails, inspect which client was installed, the tool's stderr, certificate creation and the loopback listener startup. **Never disable certificate verification to make a test green.**
