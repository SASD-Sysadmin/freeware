# Security policy

SASD Freeware provides system-administration utilities. Treat every script as code with the privileges of the account running it; inspect changes before using it with `sudo` or in automated tasks.

## Reporting a vulnerability

Please avoid disclosing an exploitable issue in a public GitHub issue. If GitHub offers **Report a vulnerability** / private vulnerability reporting for this repository, use that route. Otherwise, contact the repository maintainer privately through an established channel before publishing technical details. Do not include passwords, secrets, or real user data in a report.

A useful report includes the affected tool and revision, steps to reproduce with harmless test files, operating system and Bash version, the impact, and any known workaround. There is no guaranteed response or disclosure timeline at this early project stage.

## Operational precautions

- `rotate` places cleartext snapshots next to the input. Restrict permissions on directories containing secrets.
- It is not atomic across the entire rotation and is not a replacement for transactional or off-host backups.
- Audit a checkout before installing/updating and avoid running an unreviewed Git working tree as root.
- Use the provided tests as a check, not as a substitute for a security review.
