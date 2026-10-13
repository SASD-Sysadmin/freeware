# SSH, Integrity and Monitoring Utilities

[Deutsch](automation-tools.de.md) | **English** · [Project README](../README.md) · [Previous Perl tools](perl-tools.md)

## Summary

Four Perl 5 commands provide SSH key file inspection, SHA-256 file integrity tracking, SUID/SGID inventories and IPv4 TCP reachability checks. Each command has its own documented options, permission requirements and exit statuses.

## `ssh-key-audit` — basic authorized_keys review

```sh
./bin/ssh-key-audit --file "$HOME/.ssh/authorized_keys"
```

Checks the specified `authorized_keys` file without modifying it. The default location is `$HOME/.ssh/authorized_keys`. Reports likely malformed or unsupported key lines, duplicate key blobs, legacy `ssh-dss`/DSA keys, and group/world-writable file or containing directory. Blank lines and comments are ignored. Output ends in `SUMMARY: keys=N warnings=N`.

**Limitations:** This is a best-effort textual check, **not an authoritative OpenSSH `authorized_keys` parser or cryptographic key validator**. It does not evaluate all possible key options, certificates, key revocations, home-directory ownership, or effective SSH server policy. `ssh-rsa` key material by itself does not establish whether deprecated SHA-1 signatures are permitted by the server. Exit `0` for no findings, `1` for findings; other nonzero codes for I/O/argument failures. Fix server policy only after testing and reviewing actual OpenSSH configuration.

## `file-integrity` — explicit SHA-256 baseline

```sh
mkdir -p "$HOME/integrity-baselines"
./bin/file-integrity --root /etc/ssh --manifest "$HOME/integrity-baselines/ssh.json" --init
./bin/file-integrity --root /etc/ssh --manifest "$HOME/integrity-baselines/ssh.json" --check
```

During `--init`, records SHA-256 checksums of regular files recursively into a new JSON baseline. **Never overwrites** an existing manifest, and requires the manifest **outside** the monitored root. The implicit mode is `--check`: it reports `ADDED`, `CHANGED`, or `MISSING` paths, then totals. Exit `0` means no differences; exit `1` means differences; errors fail nonzero. The baseline contains **absolute root path** and is intended for checks on the same filesystem path. Files and directories reached through symbolic links are **not followed**; nonregular files are excluded. Contents only are hashed, not file modes, ownership, ACLs, xattrs or SELinux labels.

**Security limitations:** A baseline made after compromise is not trustworthy. Keep manifests on a protected and preferably separate system; an attacker who can change both source and manifest can evade detection. Reading all files requires access privileges. Changes during scanning can produce inconsistent reports, and scans are not transactionally atomic. Audit the output; do not use this alone to conclude a system is clean. Initialize deliberately, not in a daily scheduled job.

## `suid-audit` — SUID/SGID inventory

```sh
./bin/suid-audit --root /usr/local/bin
./bin/suid-audit --root /usr/bin
```

Recursively lists regular files with set-user-ID (SUID) or set-group-ID (SGID) permission bits, including their mode, numeric UID/GID, and pathname. Ignores symlinks and makes **no changes**. Findings are inventory data and **not necessarily vulnerabilities**; exit `0` for successful inventory even when privileged files are present, nonzero for errors.

This does not determine whether a binary is exploitable or whether the filesystem honors SUID/SGID. Access restrictions may prevent complete scans. Compare results against an approved baseline for your distribution.

## `tcp-check` — single TCP service check

```sh
./bin/tcp-check --host 127.0.0.1 --port 22 --timeout 3
./bin/tcp-check --host web.internal --port 443 --nagios
```

Attempts exactly **one IPv4 TCP connection** with a configurable timeout (1–30 seconds; default 3). Reports `OK` or `CRITICAL` for connection-level reachability. Default exit statuses: `0` connected, `1` failed, `2` invalid arguments. With `--nagios`: `0` connected, `2` failed (CRITICAL), `3` invalid arguments (UNKNOWN). This can be used as a small Nagios-compatible check command.

An open socket **does not** prove a valid TLS certificate, working website, authenticated service, or application health. This is not a port scanner, does not handle IPv6, and must be used only against systems you are authorized to test.

## Installation, verification, and maintenance

```sh
make test
sudo make install PREFIX=/usr/freeware
man -M /usr/freeware/man file-integrity
```

The tests use temporary fixtures, a local loopback TCP listener, and no system configuration changes. `make install DESTDIR=/tmp/stage PREFIX=/usr/freeware` supports safe installation staging. These commands should be re-tested on macOS through the provided GitHub Actions workflow after it has been uploaded and enabled.
