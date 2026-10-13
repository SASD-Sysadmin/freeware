# account-manage

[Deutsch](account-manage.de.md) · [Project](../../README.md)

`account-manage` is a deliberately narrow **local Linux** account administration wrapper. **On macOS/other non-Linux systems, even a preview is explicitly refused (exit 3)** rather than claiming that a Linux `useradd`/`groupadd` command would manage native Directory Services accounts. It is read-only by default, and mutation requires *both* `--apply` and `--confirm-apply` plus effective root privileges. **It cannot manage NIS, NIS+, LDAP, FreeIPA or Active Directory accounts.** It is not an identity reconciliation engine.

## Actions and examples

```sh
./sbin/account-manage --action user-create --name newoperator
./sbin/account-manage --action group-create --name appteam
./sbin/account-manage --action password-lock --name oldoperator

# Review first, then execute explicitly as root on a test host:
sudo ./sbin/account-manage --action group-create --name appteam --apply --confirm-apply
```

| Action | Native Linux command | Meaning |
|---|---|---|
| `user-create` | `useradd -m -- NAME` | Create a **local** account and request home-directory creation. Actual defaults (shell, UID, primary group) come from host configuration. |
| `group-create` | `groupadd -- NAME` | Create a **local** group according to host defaults. |
| `password-lock` | `usermod -L -- NAME` | Lock the user's **password**; **does not disable SSH public keys, active sessions, services or tokens**. Only for existing local, non-system users. |

Names are restricted to short, simple lowercase Linux account names. Root and system-account password locks are refused. Operations that would collide with an already resolvable NSS user or group are rejected. Local identity files containing malformed or NIS compatibility entries cause a **fail-closed refusal** for every action. This helps avoid treating a remotely managed account as a writable local account. **However, a negative NSS lookup is not proof of uniqueness across all remote identity providers.** The administrator must verify the environment before applying changes.

## Safety and prerequisites

- The initial preview does **not** locate or execute a native account command. It reads `/etc/passwd` or `/etc/group` and checks current NSS resolution; no shell execution.
- Applying is supported **only on Linux** with shadow-utils compatible `useradd`, `groupadd`, and `usermod`. Missing backend commands and unsupported OS are errors. The wrapper does not install prerequisites.
- Apply additionally checks for protected, root-owned regular `/etc/passwd` and `/etc/group` files and a trusted root-owned executable/directory chain, and invokes the native backend with list-form `system` (never via a shell). Account changes are **not transactional**; a native program might partially modify state before failing.
- `--confirm-apply` is a fixed confirmation switch, **not** a substitute for reviewing the target name and host. An operator should inspect NSS, local account files, PAM and relevant directory service policies separately. Never run unreviewed commands in production.
- Only names are supported; no direct numeric UID/GID control, password specification, password hashes, shadow-file inspection, arbitrary `userdel` or session termination in this version.
- The automated tests do **not** perform real account creation or locking. A real test must be done in an isolated, backed-up Linux VM after checking host tools and local policy.

## Exit status

`0` successful preview or native tool exit 0 (not independent state verification); `2` invalid parameters or missing apply confirmation; `3` invalid/missing prerequisites, unsafe conditions, unavailable identities, unsupported host, or native execution failure.
