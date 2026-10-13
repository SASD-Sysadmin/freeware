# quota-report

`quota-report` displays user/group filesystem quota information using the operating system's own `quota` utility, or `repquota` for an administrative overview. It does not enable quotas or change limits.

## Requirements

Perl 5.8 or newer, core modules `Getopt::Long` and `FindBin`, and the bundled `SASD::Freeware::External` library. Depending on the mode, the system must provide executable `quota` or `repquota` utilities in `PATH`. They may be distributed in a separate host package. Filesystems must support and configure quotas to return meaningful quota information; administrative reports may require extra permissions. Compatibility of command options and output depends on the Unix variant. The script does not assume any particular textual quota report format.

## Usage

```sh
quota-report                  # quota -v for the current account
quota-report --user alice     # quota -v alice
quota-report --group staff    # quota -v -g staff (if supported)
quota-report --all            # repquota -a (may require elevated privileges)
```

The command runs exactly one external program **without a shell** and copies its normal output unchanged. Its purpose is to provide consistent option checking, prerequisite diagnostics and exit statuses without incorrectly interpreting host-specific quota formats. `--user`, `--group`, and `--all` are mutually exclusive. User/group values must be simple Unix account names; other strings are rejected.

The quota utility's own output describes any soft limits, hard limits, block/inode counts and grace periods available on the host. `--group` and `--all` may be unsupported by some Unix implementations even when basic quota reporting works; the native tool's error remains visible. A successful invocation is not proof that quotas have been enabled on a filesystem.

## Exit status

- `0`: native quota program exited successfully.
- `2`: invalid arguments.
- `3`: native utility missing, failed, or terminated abnormally; inspect its diagnostic output and the additional `quota-report` message.

## Installation

`make test && make install PREFIX=/usr/freeware`. The tool does not install or configure operating-system quota software. Do not elevate privileges for ordinary user reports unless host policy requires it.

## Related commands

On Linux, `quota-status --all` displays activation status without changing it. `quota-set` previews complete limit values and changes them only after explicit confirmation. See [quota-status](quota-status.md) and [quota-set](quota-set.md).
