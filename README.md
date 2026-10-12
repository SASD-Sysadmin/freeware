# SASD Freeware

**English** | [Deutsch](README.de.md) · [MIT License](LICENSE) · [Contributing](CONTRIBUTING.md) · [Changelog](CHANGELOG.md)

Small, practical command-line utilities and system-administration tools maintained by **SASD-SysAdmin**. The repository is organized to be deployable under `/usr/freeware` without mixing its files with distribution-managed `/usr/bin` and `/usr/lib` paths. It is intended to grow into a collection of Bash, Perl, Python, (t)csh, and other Unix-like system tools.

> **Status:** Early-stage project. `rotate` is the first included utility. Empty directories reserve space for future components; they are not promises of available functionality.

## Included utility

| Command | Location | Purpose | Documentation |
| --- | --- | --- | --- |
| `rotate` | [`bin/rotate`](bin/rotate) | Preserve up to ten generations of a regular file (`.0` newest, `.9` oldest). | [Guide](docu/rotate.md) · [Deutsch](docu/rotate.de.md) · [Manpage](man/man1/rotate.1) |

Example: `rotate /etc/hosts` creates `/etc/hosts.0` without modifying `/etc/hosts`; running it again moves the previous `.0` to `.1` and creates a new `.0`. The oldest `.9` is removed on subsequent rotations. `rotate` is a **file snapshot helper**, not a replacement for scheduled log rotation, version control, or a complete backup strategy.

## Planned directory layout

```text
/usr/freeware/
├── bin/               User commands (rotate)
├── sbin/              Administrative commands (reserved)
├── lib/               Architecture-independent libraries (reserved)
├── lib64/             64-bit libraries (reserved)
├── man/
│   └── man1/          Manual pages (rotate.1)
├── docu/              Detailed English and German guides
├── tests/             Automated command tests (repository checkout)
├── .github/workflows/ CI tests (repository checkout)
├── Makefile           Simple test/install/uninstall targets
├── README.md          English project documentation
└── README.de.md       German project documentation
```

The top-level directory names intentionally follow the planned `/usr/freeware` installation tree. `lib64` is a reserved convention, not a guarantee that every platform uses a separate `lib64` directory. Git cannot track truly empty directories, so reserved ones contain `.gitkeep` files.

## Requirements

- Unix-like operating system with **Bash**, `cp`, `mv`, `rm`, `mkdir`, `rmdir`, and `mktemp` (Linux is tested locally; CI is configured for Ubuntu and macOS).
- Write permission in the directory of the file to be rotated.
- `git` for cloning; `make` and `install` for optional staged deployment.
- No Python, Perl, or third-party packages are needed for `rotate`.

## Installation

### Recommended: clone and install only distributable files

```sh
git clone https://github.com/SASD-Sysadmin/freeware.git
cd freeware
make test
sudo make install PREFIX=/usr/freeware
```

This installs **only** `bin/rotate` and `man/man1/rotate.1`, leaving the checkout and development files outside the system installation. Set `DESTDIR` for packaging or staging, for example `make install DESTDIR=/tmp/package PREFIX=/usr/freeware`.

### Alternative: use a checkout directly from /usr/freeware

A checkout can also live at `/usr/freeware`, retaining the complete repository layout. Do not use a root-owned working tree for day-to-day development or run unreviewed code as root. Manage ownership and updates in accordance with your site's policy.

Add the following to your shell startup file (for example `~/.bashrc`):

```sh
export PATH="/usr/freeware/bin:/usr/freeware/sbin:$PATH"
export MANPATH="/usr/freeware/man:${MANPATH:-}"
```

On systems that already manage manual paths, `man -M /usr/freeware/man rotate` works without changing the shell configuration. For a checkout elsewhere, invoke `./bin/rotate` directly or adapt the paths above.

## Usage

```sh
rotate ./settings.conf
rotate '/path/with spaces/hosts copy'
# Protected system files typically require elevated privileges:
sudo /usr/freeware/bin/rotate /etc/hosts
man -M /usr/freeware/man rotate
```

`rotate` requires **exactly one** argument: the path of an existing regular file (not a symbolic link). Backups are written next to the source. The command requires permission to create, rename, and delete entries in that directory, and it refuses unexpected non-file entries in `.0` through `.9`. Only matching numeric files `.10`, `.11`, etc. are removed as legacy versions; names such as `.01` or `.10.notes` are left alone.

A short-lived directory named `FILE.rotate.lock` prevents concurrent cooperating rotations. If a process is forcibly terminated, inspect the directory before deleting a stale lock. Rotations are **not transactionally atomic**: interruption during renames can leave gaps; always check critical backups. Copied file permissions and timestamps are preserved by `cp -p`, subject to OS and user privileges. Backup files may contain secrets; secure their parent directory.

For details, restoration instructions, and failure handling, read [the full rotate guide](docu/rotate.md).

## Development and verification

```sh
make test
bash -n bin/rotate
```

The test suite covers the ten-version limit, old-version cleanup, filenames with spaces, binary content, invalid inputs, locks, and backup-slot conflicts. GitHub Actions is configured to run `make test` on Ubuntu and macOS for pushes and pull requests; this does not imply a successful CI run until GitHub reports one.

## Contributing, licensing, and security

See [CONTRIBUTING.md](CONTRIBUTING.md) for file locations, contribution practices, and tests; [SECURITY.md](SECURITY.md) for security reporting; and [CHANGELOG.md](CHANGELOG.md) for project history. The repository is licensed under the [MIT License](LICENSE). Review individual tool requirements before executing commands with elevated privileges.

**Project:** [github.com/SASD-Sysadmin/freeware](https://github.com/SASD-Sysadmin/freeware)
