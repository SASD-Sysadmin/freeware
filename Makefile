# SPDX-License-Identifier: MIT
# Standard targets for the SASD Freeware command collection.
PREFIX ?= /usr/freeware
DESTDIR ?=

.PHONY: all check test integration-test shellcheck install uninstall
all: test

check:
	@command -v perl >/dev/null 2>&1 || { echo "make check: Perl is required (Perl 5)" >&2; exit 1; }
	@set -eu; for script in bin/* sbin/*; do \
		[ -f "$$script" ] && [ -x "$$script" ] || continue; \
		case "$$(head -n 1 "$$script")" in *perl*) perl -c "$$script" ;; esac; \
	done
	@set -eu; for module in lib/SASD/Freeware/*.pm; do \
		[ -f "$$module" ] || continue; perl -Ilib -c "$$module"; \
	done

test: check
	@command -v prove >/dev/null 2>&1 || { echo "make test: prove (Perl Test::Harness) is required" >&2; exit 1; }
	@set -eu; for script in tests/test_*.sh; do \
		[ -f "$$script" ] || continue; \
		bash "$$script"; \
	done
	@set -eu; for suite in tests/*.t; do \
		[ -f "$$suite" ] || continue; \
		prove -v "$$suite"; \
	done

# Explicit opt-in: native dig/ldapsearch run against loopback protocol fixtures.
# Ordinary make test stays offline and requires no optional network clients.
# Optional locally, mandatory in Ubuntu CI: static Bash analysis.
shellcheck:
	@command -v shellcheck >/dev/null 2>&1 || { echo "make shellcheck: install ShellCheck first" >&2; exit 1; }
	@shellcheck bin/rotate tests/test_rotate.sh tests/test_rotate_safety.sh

integration-test: check
	@command -v prove >/dev/null 2>&1 || { echo "make integration-test: prove is required" >&2; exit 1; }
	@prove -v tests/integration/name_services.t

# Installation operates only on files enumerated in the owned SHA-256 manifest.
# Use DESTDIR for staging; privileged host installation requires review.
install:
	@perl tools/installation.pl --mode install --source . --prefix "$(PREFIX)" --destdir "$(DESTDIR)"

# Uninstallation is independent of the current checkout file list.
uninstall:
	@perl tools/installation.pl --mode uninstall --prefix "$(PREFIX)" --destdir "$(DESTDIR)"
