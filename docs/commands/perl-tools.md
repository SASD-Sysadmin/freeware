# Perl administration utilities

[English](perl-tools.md) | [Deutsch](perl-tools.de.md) · [Project](../../README.md)

## Summary

Four Perl 5 command-line utilities provide read-only reports for directory contents, hosts-file syntax, account records and log messages. The tools use standard Perl modules and do not change input data.

## `fs-report` — filesystem summary

```sh
./bin/fs-report --top 15 --min-size 1M /var/log
./bin/fs-report --top 0 "$HOME"
```

Walks a directory without following symbolic links. Reports counts of directories, regular files, and symbolic links, the **sum of logical file sizes** in bytes, and up to N of the largest regular files over the configured minimum size. `--top` defaults to 10 and must be between 0 and 1000. `--min-size` accepts a byte count or the binary suffixes `K`, `M`, `G`, `T` (1024-based). `--one-file-system` skips entries on other devices. See the standalone [fs-report guide](fs-report.md) for complete operation and exit statuses. Results are sorted by descending size, then path. Paths containing newlines, tabs, backslashes, or carriage returns are escaped in file listings.

Logical sizes are **not** filesystem allocation (`du`) and may double-count multiply linked files; sparse files are measured by their apparent size. Filesystem access may be limited by permissions. Do not treat this as a complete space accounting tool.

## `hosts-lint` — validate a hosts file

```sh
./bin/hosts-lint
./bin/hosts-lint --file ./my-hosts
```

Checks whitespace-separated `IP HOSTNAME [ALIAS ...]` entries, allowing IPv4 and IPv6. Ignores blank lines and trailing `#` comments. Detects missing names, obviously invalid IP addresses, and invalid DNS-style hostname tokens. When the same name occurs with differing addresses, reports a **warning** (multiple mappings may be intentional). Input is never changed. The default file is `/etc/hosts`.

The tool is a syntax-oriented lint, not a DNS resolver or a full parser for every vendor-specific hosts-file extension. IPv6 zone identifiers and unusual non-DNS host tokens may not be accepted.

## `account-audit` — check passwd structure

```sh
./bin/account-audit
./bin/account-audit --file ./passwd.sample
```

Reads a Unix-style, seven-field `/etc/passwd` file and checks basic record structure: account name, numeric UID/GID, and absolute home directory. Warns about duplicate names, shared UIDs, non-`root` UID 0 accounts, and empty shells. `+` or `-` NIS entries are skipped with a warning. Defaults to `/etc/passwd`.

**This is not an authentication audit:** it does not read `/etc/shadow`, validate password strength, resolve directory-service identities, inspect PAM, or modify accounts. UID-sharing and unusual shells may be legitimate, so manually evaluate warnings. Usernames in diagnostics may be sensitive; protect audit output as appropriate.

## `log-summary` — count severity markers

```sh
./bin/log-summary /var/log/syslog
./bin/log-summary --match sshd /var/log/auth.log
journalctl --no-pager -n 1000 | ./bin/log-summary -
```

Reads a text log one line at a time, including standard input (`-`), and counts lines containing severity tokens: `CRITICAL`, `ERROR`, `WARNING`, `NOTICE`, `INFO`, `DEBUG`, or `TRACE`. Messages without recognized tokens are counted as `OTHER`. Where multiple markers appear, the more severe category takes precedence. `--match TEXT` selects lines containing that **literal**, case-insensitive substring; it is not a regex. Displays only counts, not the original log contents.

This is a simple lexical heuristic, not a format-aware syslog/journald/JSON parser. Words occurring in normal message text may affect classification. Unlike `tail -f`, it reads to EOF then exits.

## Installation and local checks

```sh
make test
sudo make install PREFIX=/usr/freeware
/usr/freeware/bin/hosts-lint
man -M /usr/freeware/man hosts-lint
```

`make test` uses temporary fixtures rather than real `/etc` or live services. `DESTDIR` supports staging:

```sh
make install PREFIX=/usr/freeware DESTDIR=/tmp/sasd-stage
```

To use the installed commands without full paths, add `/usr/freeware/bin` to `PATH` and `/usr/freeware/man` to `MANPATH`, or use `man -M`.

## Exit statuses and safety

For `hosts-lint` and `account-audit`: status **0** if there are no syntactic errors (warnings alone do not fail), **1** if input records contain errors, **2** for argument usage errors. Missing/unreadable inputs also fail nonzero. `fs-report` exits nonzero on stat errors, and 2 for bad options. `log-summary` exits 0 after successfully reading its input and nonzero on errors.

These tools are **read-only** and do not require or elevate privileges themselves. They do not provide transactional system auditing or evidence of a system's security state. Tests currently run on Linux; macOS CI can verify portability after the repository workflow is pushed.
