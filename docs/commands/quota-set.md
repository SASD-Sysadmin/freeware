# quota-set

`quota-set` prepares or applies a **complete Linux user or group disk-quota record** using the system's `setquota` utility. It never enables quota accounting, mounts filesystems, creates accounts, or changes grace periods. The default mode displays the requested values without executing the quota backend.

## Requirements

- Linux with Perl 5 and its core `Getopt::Long`, `FindBin`, `File::Spec`, and `Cwd` modules, plus the bundled `SASD::Freeware::External` module.
- For `--apply`: the Linux quota utilities including `setquota` (usually supplied by the operating system's `quota` package), a filesystem mounted **with applicable quotas enabled**, a known account/group resolvable by the system name service, and administrative privileges normally required by `setquota`.
- The mountpoint must appear as an exact mounted directory in `/proc/self/mounts`. The wrapper rejects a symbolic link as its final path component. It does not detect every quota format or verify that accounting is active; backend failures are reported without conversion to success.
- `setquota` must be reachable through `PATH` using an absolute directory. A privileged (effective UID 0) invocation rejects executable paths whose owner or directory chain is not root-owned and protected against group/other writing.

## Invocation

```sh
quota-set --user alice --filesystem /home \
  --block-soft 100000 --block-hard 120000 \
  --inode-soft 20000 --inode-hard 25000

# Review the values and confirm the target before applying:
sudo /usr/freeware/sbin/quota-set --user alice --filesystem /home \
  --block-soft 100000 --block-hard 120000 \
  --inode-soft 20000 --inode-hard 25000 \
  --apply --confirm-apply

# Set a group quota instead:
quota-set --group engineers --filesystem /srv/projects \
  --block-soft 800000 --block-hard 900000 \
  --inode-soft 15000 --inode-hard 17000
```

`--dry-run` is an explicit alternative to the default preview. `--apply` and `--dry-run` are mutually exclusive. `--confirm-apply` is mandatory with `--apply` and invalid otherwise. The command requires **all four** values even when only one limit needs changing: obtain and preserve the current values of any unchanged fields first. This prevents an omitted field from silently clearing a limit.

Block limits use **1024-byte units (KiB)**, as accepted by Linux `setquota`; inode limits are file counts. Supply unsigned decimal integers only (no K/M/G suffix); the accepted maximum is 9223372036854775807. A nonzero soft limit cannot exceed a nonzero hard limit. A zero limit means **unlimited**, *not* zero allowed space; applying any zero value additionally requires `--allow-unlimited`. The preview warns about zeros.

The native operation is equivalent to:

```sh
setquota -u alice 100000 120000 20000 25000 /home
```

The group form uses `-g` instead of `-u`. No shell is invoked to execute the backend. The filesystem path and account are passed as separate arguments; numeric user and group IDs are not accepted because the selected name must resolve through the host's name service. `setquota` handles the actual quota update; its successful exit status is **not** a verified read-back. Run `quota-report` afterward to examine the effective quotas.

## Operational precautions

Check the applicable filesystem, user/group identity, block unit, active quota configuration, and current limits before applying. Soft limits can involve grace periods controlled separately by the OS. This command does **not** provide a transaction, automatic rollback, or cross-platform quota emulation. If the backend reports an error, inspect the filesystem and current quotas before retrying; do not assume the operation was atomic. For production changes, keep a record of the prior limits so they can be restored through your change process.

The `--apply` backend is supported on **Linux**; the preview can be displayed on other Unix variants, but it must not be interpreted as a promise that `setquota` is available there. Native quota implementations vary.

## Exit status

- `0`: preview generated, or the native `setquota` call exited successfully.
- `2`: missing/conflicting options, invalid identity or limits, unsafe filesystem argument, or missing explicit confirmation.
- `3`: prerequisite or name-service failure, unsupported system, missing/untrusted `setquota`, invalid mountpoint, or native execution failure.

## Installation and related commands

`make test && sudo make install PREFIX=/usr/freeware`. The command is installed under `sbin/` and has a section 8 manual page (`man -M /usr/freeware/man 8 quota-set`). Use `quota-status` to view Linux quota activation and `quota-report` to query current limits. Installing this utility does not install the OS quota package or configure filesystems.
