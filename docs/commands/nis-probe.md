# nis-probe — Local NIS/YP binding diagnosis

[Deutsch](nis-probe.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/nis-probe.1)

Uses an optional **`ypwhich`** client to ask which NIS server the **local host** is bound to. The domain can be specified, or the host default used. **No passwd, group or other NIS maps are queried or enumerated.** It does not establish the correctness of NIS account resolution through NSS, nor validate server authorization or data integrity.

NIS is a legacy protocol lacking modern confidentiality and authentication assurances. Treat these checks as **migration/troubleshooting aids**, not an endorsement of deploying NIS. On some macOS installations `ypwhich` is absent; this results in an explicit prerequisite error rather than a fabricated negative diagnosis. The check can generate NIS traffic.

## Examples

```sh
./bin/nis-probe
./bin/nis-probe --domain legacy.example --timeout 3
```

## Limits and exit codes

Checks binding only; no map names, passwords or account records requested.

Status `0`: clean/success; `1`: structural finding, DNS/NIS failure or no answer; `2`: invalid input; `3`: file/client missing, unsupported default or unexpected backend error. Inspect the output and do **not** interpret missing clients as a healthy configuration.
