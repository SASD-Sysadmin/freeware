# Development and Maintenance Guidelines

## Scope

SASD Freeware provides command-line utilities, scripts and libraries for Linux and Unix system administration. Programs are designed for reliable operation, integration with existing environments and long-term maintainability.

## Language choice

Choose a language according to the command's operating requirements rather than adopting a language for the entire collection.

- **POSIX shell (`sh`)** is suitable for small portable command wrappers, process orchestration and simple filesystem operations.
- **Bash** is suitable for shell-based administration that requires Bash features or existing Bash integration.
- **tcsh** is supported for csh-family workflows and system-specific administration where tcsh is appropriate; document its runtime requirement.
- **Perl** is preferred for nontrivial text parsing, reports, filesystem inventories, record processing, network utilities and portable administration programs when a shell implementation would be harder to maintain.
- **Python** may be used when its libraries or integration provide a concrete operational advantage; it is not the default alternative to Perl.
- **C, C++ and other languages** are acceptable where native interfaces, performance or integration justify them.

Do not rewrite working utilities merely to impose a uniform language.

## Tool interface

Document each command's purpose, synopsis, options, examples, dependencies, side effects and exit statuses. Implement `--help` and `--version` on new commands. Use predictable output; send diagnostics to stderr. When machine-readable output is supported, delimit filenames unambiguously. Preserve established interfaces when updating a command.

Use clear, short command names; choose descriptive variable names; prefer maintainable implementations over unnecessary optimization. Require explicit authorization for changes to host settings or files. Use least privilege, reject invalid inputs and make failures detectable. For mutating tools, offer a review mode such as `--dry-run` when practical.

## Perl and shell

Perl programs use `strict`, `warnings`, lexical variables, three-argument file opening where applicable and checked filesystem operations. Prefer core modules; specify required Perl versions and any additional modules. Shell programs must quote pathnames, handle names beginning with `-` and document GNU/BSD-specific requirements. If shell tools have differing behavior across operating systems, verify before claiming support.

## Repository layout

`bin/` contains ordinary commands; `sbin/` contains administration-oriented commands; `lib/` and `lib64/` contain supporting libraries. User guides are kept in `docu/` in English and German; manpages are under `man/man1/` or `man/man8/`; tests are in `tests/`; project maintenance information belongs in `docs/`.

## Testing and release

Each tool needs offline, repeatable tests of valid inputs, errors, boundary cases and special filenames. `make test` must not alter system accounts, `/etc`, DNS, NIS, or running system services. Test elevated or destructive operations separately on isolated systems. `make install PREFIX=... DESTDIR=...` must support safe staging. Record tested platforms separately from intended portability. Review source differences and executable bits before committing.

No command is considered released merely because it exists in a local ZIP file; its published version must be present in the repository and accompanied by documentation and passing tests.
