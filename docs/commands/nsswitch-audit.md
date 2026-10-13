# nsswitch-audit — Structural NSS switch-file diagnosis

[Deutsch](nsswitch-audit.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/nsswitch-audit.1)

Checks the **text syntax** of an explicit Linux-style `nsswitch.conf`. On Linux, the default is `/etc/nsswitch.conf`. On macOS, **an explicit `--file` is required**: this file is not the authoritative Directory Services configuration. No NSS module is loaded and no user/group lookup takes place.

It reports duplicate database declarations, duplicate sources, malformed service lists and bracket actions, empty rules and control characters. `NOTE` identifies legacy `nis`, `nisplus` or `compat` sources and common databases absent from the file. Notes do not automatically cause failure. **It does not confirm that NSS modules are installed, safe, or functioning**, and does not evaluate the semantic effect of action clauses.

## Examples

```sh
./bin/nsswitch-audit
./bin/nsswitch-audit --file /tmp/nsswitch.conf
```

## Limits and exit codes

Syntax only; parse errors exit 1, unreadable file/unsupported default exit 3.

Status `0`: clean/success; `1`: structural finding, DNS/NIS failure or no answer; `2`: invalid input; `3`: file/client missing, unsupported default or unexpected backend error. Inspect the output and do **not** interpret missing clients as a healthy configuration.
