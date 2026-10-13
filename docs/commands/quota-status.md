# quota-status

`quota-status` displays the Linux filesystem quota activation status reported by the system's `quotaon -p` command. It **does not** enable, disable or modify quotas. Output is passed through unchanged to avoid misinterpreting host-specific formats.

## Requirements

Linux, Perl 5, the core `Getopt::Long`, `FindBin`, `File::Spec`, and `Cwd` modules, the bundled `SASD::Freeware::External` module, and a native `quotaon` executable that supports **`-p` (print status)**. `quotaon` is usually supplied with the OS `quota` package. The caller may require additional permissions according to the distribution and filesystem. Unsupported `-p` implementations return an error.

## Usage

```sh
quota-status --all
quota-status --filesystem /home
```

One mode is required. `--all` executes `quotaon -p -a`; `--filesystem` executes `quotaon -p MOUNTPOINT` with a canonical absolute directory path. The options cannot be combined. The filesystem cannot be specified by a symbolic link as the last path component. No shell is invoked.

The native status output is displayed verbatim. This utility does not parse the report, verify quota limits, or set quota accounting. Use `quota-report` for user/group quota information and `quota-set` for explicitly approved changes.

## Exit status

- `0`: native `quotaon -p` exited successfully (not proof that every filesystem has quotas enabled).
- `2`: missing, conflicting or invalid options.
- `3`: unsupported OS, missing native tool, or failed/abnormal native command.

Install using `make install PREFIX=/usr/freeware`. Manpage: `man -M /usr/freeware/man 1 quota-status`.
