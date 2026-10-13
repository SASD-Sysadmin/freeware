# Contributing to SASD Freeware

Thank you for improving this collection. Contributions are welcome through GitHub issues and pull requests.

## Before submitting

1. Open an issue for significant new utilities or behavior changes so the purpose and intended audience are clear.
2. Keep utilities focused, understandable, and useful for Unix-like administration. Do not include credentials, confidential files, or host-specific configuration.
3. Place general commands in `bin/`, administration commands in `sbin/`, libraries in `lib/` or `lib64/` as appropriate, documentation in `docu/`, and man pages in `man/manN/`.
4. For a new command, provide a short English description in `README.md`, a German counterpart in `README.de.md`, at least one usage example, a man page, and tests for edge cases and failure modes.
5. Preserve source file formatting (UTF-8, LF line endings). Prefer portable Bash when there is no strong reason to use platform-specific behavior. Document any dependencies and privilege requirements.
6. Run `make test` before submitting. If available, run `shellcheck bin/rotate tests/test_rotate.sh` for shell changes.
7. Keep pull requests scoped and describe what changed, how it was tested, platform support, and any compatibility or security concerns.

## Coding and security conventions

- Quote shell expansions; use `--` or otherwise handle option-looking filenames safely.
- Prefer failing before destructive operations. Use predictable error messages and nonzero exit statuses.
- Never assume a command should run as root; document privileged tasks explicitly.
- Write tests using temporary directories and clean them up. Do not let tests modify real system files.
- Do not introduce broad `.gitignore` patterns that hide source files or files intended for distribution.
- Keep English source docs and German translations synchronized when behavior changes.
- Include an SPDX identifier or appropriate license notice in newly added code where sensible. By contributing, you agree that your contribution is distributed under the repository's existing MIT License.

For vulnerabilities, do **not** open a public issue first; see [SECURITY.md](SECURITY.md).

## External learning materials

Do not include third-party source code or configuration samples without verifying redistribution rights and applicable license conditions. All contributions require tests and maintenance documentation.
