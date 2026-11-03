# SASD Freeware – Installation, upgrades and release acceptance

## Status and scope

This guide describes the **source installer** introduced in M3. A CLI string
such as `0.1.0` does not mean that an official `v0.1.0` release already exists.
Linux/macOS CI is not a substitute for the separately approved privileged VM
exercise.

## Staged installation

```sh
make test
make shellcheck               # Ubuntu, or where ShellCheck is installed
staging=$(mktemp -d)
make install DESTDIR="$staging" PREFIX=/usr/freeware
cat "$staging/usr/freeware/.sasd-freeware-install.tsv"
make uninstall DESTDIR="$staging" PREFIX=/usr/freeware
```

Host installation omits `DESTDIR` and requires appropriate filesystem rights.
`PREFIX` must be absolute and cannot be `/`; `DESTDIR`, when used, must be
absolute. Dot components and arbitrary symlinks along the destination path are
refused. Only the verified native macOS aliases `/var`, `/tmp` and `/etc`
resolving to `/private/...` are accepted; operator-created symlinks remain
forbidden.

## Manifest ownership

`PREFIX/.sasd-freeware-install.tsv` lists installed relative paths and their
SHA-256 content digests. It is published **last**. Upgrades can replace only
verified, previously managed files and remove obsolete managed files. An
existing unowned destination, modified managed file, symlink, corrupted
manifest, or unsafe path blocks the operation before any managed files are
changed.

`make uninstall` requires a valid manifest and removes only the unchanged
files it owns, leaving unrelated operator content in place. Deliberately
modified managed files require human review; no automatic force override is
provided.

Older source-based installations without a manifest are **not automatically
adopted**. Back up and inventory any existing installation, plan a controlled
migration, and only then switch to the manifest-based workflow. Do not run
an old source-list uninstall blindly against a production prefix.

## Interruption and recovery

The installer stages the new payload under the target prefix. On ordinary
reported errors, it attempts to restore backed-up managed files. This is **not
an entirely atomic transaction**: a crash, SIGKILL, exhaustion of storage or
concurrent external modifications can require manual restoration. A leftover
`.sasd-freeware-txn-*` directory signals a potentially interrupted update;
inspect it before removal as it may contain previous installed files. Recover
from a VM/filesystem snapshot where appropriate.

### M9.3a: simulated interrupted upgrade (offline regression)

`tests/test_installation_interruption.t` models a disposable interrupted
upgrade after a previous managed file has been moved into a transaction backup.
It verifies that **both** install and uninstall refuse to proceed while the
`.sasd-freeware-txn-*` directory exists, without consuming backups, modifying
the ownership manifest, or touching unowned operator files. The test then
models independently reviewed restoration before retrying an upgrade.

This is a deterministic **simulation of one interruption point**. It does
not kill a live process, prove power-loss durability, or certify every rollback
path. RG-04 and the manual staged-upgrade gate remain open.

For an actual interrupted installation, stop automated retries; secure and
inventory the affected prefix and transaction directory; compare the installed
manifest with the actual paths and checksums; and prefer restoring a verified
filesystem/VM snapshot. The `old-N` backup filenames do **not** encode their
original destinations. Do not guess mappings, delete backups, or run
`make uninstall` as a recovery shortcut. Document independent verification
of the recovered state before removing the transaction marker.

## Release checklist

Use the [systematic release-gap register](RELEASE-GAPS.md) and `make release-gap-audit` to inventory *static* source gaps. Its PASS records do not establish native or privileged release acceptance. MANUAL records remain open until reviewed evidence exists; never promote a release from this scanner alone.

1. Start from a clean reproducible commit/tag; reconcile CLI versions and the
   changelog.
2. Confirm `make test`, `make shellcheck`, mandatory DNS/LDAPS integration and
   Linux/macOS CI.
3. Exercise fresh install, repeat install, renaming/removing a managed program,
   uninstall, and conflict detection in disposable staging.
4. Complete the separately approved Linux VM checks in
   [PRIVILEGED-SAFETY.md](PRIVILEGED-SAFETY.md).
5. Produce and verify release archive plus SHA-256 checksum against a pristine
   tag checkout.
6. Only then publish a GitHub release with platform scope, limitations,
   known risks and a tested rollback path.
