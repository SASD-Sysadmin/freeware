# `ssh-key-audit` — Heuristic authorized_keys and permissions review

**English** · [Deutsch](ssh-key-audit.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/ssh-key-audit.1) · [Source](../../bin/ssh-key-audit)

## Purpose and use

Read-only review of OpenSSH-style `authorized_keys` text. Default is `$HOME/.ssh/authorized_keys` (or `./.ssh/authorized_keys` if HOME is unset). Does **not** change keys/permissions, contact a server, validate cryptographic key blobs or infer effective server policy.

## Behavior and checks

A symlink **at the file leaf** is rejected, and the target must be a regular file. The command examines group/world write bits on the file and its immediate containing directory; no ACL, owner or higher-parent policy is checked. Nonblank noncomment lines are matched by a limited regular expression for recognized OpenSSH key types (`ssh-ed25519`, `ssh-rsa`, `ssh-dss`, `ecdsa-sha2-*`, selected `sk-*`) and a base64-like field. Options preceding a key may contain spaces. Unknown text, repeated encoded key blobs, legacy DSA `ssh-dss`, or group/world-writable targets generate warnings.

## Usage and options

```text
ssh-key-audit --help
```

| Option | Meaning |
| --- | --- |
| `--file PATH` | Explicit `authorized_keys` path (otherwise HOME default). |
| `--help` | Print usage without opening the file. |
| `--version` | Print `ssh-key-audit 0.1.0`. |

## Practical example

```sh
# Read only an existing authorized_keys file.
./bin/ssh-key-audit --file "$HOME/.ssh/authorized_keys"
# Disposable illustration of a DSA warning (NOT a real public key).
lab="$(mktemp -d)"
printf '%s\n' 'ssh-dss AAAABBBBCCCC example' > "$lab/authorized_keys"
./bin/ssh-key-audit --file "$lab/authorized_keys"
```

The fixture deliberately uses a fake base64 field to demonstrate text matching. **Never install it as an authorized key.** A missing real file is an error, not evidence of safety.

## Output and exit status

`WARN:` findings followed by `SUMMARY: keys=N warnings=N`. Some findings include input line numbers or paths.

`0` = no warnings found; `1` = one or more warnings; `2` = invalid options; other nonzero = missing/nonregular file, symlink refusal or I/O failure.

## Limits, safety and portability

Not a complete OpenSSH parser. Does not decode/verify key blobs, reject certificates, inspect revocation, assess `sshd_config`/`StrictModes`, key ownership, full path ancestry or symlinked parents. `ssh-rsa` public key type alone does not prove the server allows legacy SHA-1 signatures. Keep key metadata and paths private. Run separate native server tests for actual policy.

## Related resources

[SSH event summary](ssh-auth-summary.md) · [Security](../../SECURITY.md) · [Automation overview](automation-tools.md)
