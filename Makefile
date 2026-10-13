# SPDX-License-Identifier: MIT
# Standard targets for the SASD Freeware command collection.
PREFIX ?= /usr/freeware
DESTDIR ?=

.PHONY: all check test install uninstall
all: test

check:
	@command -v perl >/dev/null 2>&1 || { echo "make check: Perl is required (Perl 5)" >&2; exit 1; }
	@set -eu; for script in bin/* sbin/*; do \
		[ -f "$$script" ] && [ -x "$$script" ] || continue; \
		case "$$(head -n 1 "$$script")" in *perl*) perl -c "$$script" ;; esac; \
	done
	@set -eu; for module in lib/SASD/Freeware/*.pm; do \
		[ -f "$$module" ] || continue; perl -c "$$module"; \
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

install:
	@set -eu; \
		for section in bin sbin; do \
			for src in "$$section"/*; do \
				[ -e "$$src" ] || continue; \
				[ -f "$$src" ] && [ ! -L "$$src" ] && [ -x "$$src" ] || { echo "Invalid executable: $$src" >&2; exit 1; }; \
				install -d "$(DESTDIR)$(PREFIX)/$$section"; \
				install -m 755 "$$src" "$(DESTDIR)$(PREFIX)/$$src"; \
			done; \
		done; \
		for module in lib/SASD/Freeware/*.pm; do \
			[ -e "$$module" ] || continue; \
			[ -f "$$module" ] && [ ! -L "$$module" ] || { echo "Invalid module: $$module" >&2; exit 1; }; \
			install -d "$(DESTDIR)$(PREFIX)/lib/SASD/Freeware"; \
			install -m 644 "$$module" "$(DESTDIR)$(PREFIX)/$$module"; \
		done; \
		for page in man/man[1-9]/*.[1-9]; do \
			[ -e "$$page" ] || continue; \
			[ -f "$$page" ] && [ ! -L "$$page" ] || { echo "Invalid man page: $$page" >&2; exit 1; }; \
			dir=$${page%/*}; \
			install -d "$(DESTDIR)$(PREFIX)/$$dir"; \
			install -m 644 "$$page" "$(DESTDIR)$(PREFIX)/$$page"; \
		done; \
		for doc in docu/*.md; do \
			[ -e "$$doc" ] || continue; \
			[ -f "$$doc" ] && [ ! -L "$$doc" ] || { echo "Invalid guide: $$doc" >&2; exit 1; }; \
			install -d "$(DESTDIR)$(PREFIX)/docu"; \
			install -m 644 "$$doc" "$(DESTDIR)$(PREFIX)/$$doc"; \
		done

uninstall:
	@set -eu; \
		for section in bin sbin; do \
			for src in "$$section"/*; do \
				[ -f "$$src" ] && [ ! -L "$$src" ] || continue; \
				rm -f "$(DESTDIR)$(PREFIX)/$$src"; \
			done; \
		done; \
		for module in lib/SASD/Freeware/*.pm; do \
			[ -f "$$module" ] && [ ! -L "$$module" ] || continue; \
			rm -f "$(DESTDIR)$(PREFIX)/$$module"; \
		done; \
		for page in man/man[1-9]/*.[1-9] docu/*.md; do \
			[ -f "$$page" ] && [ ! -L "$$page" ] || continue; \
			rm -f "$(DESTDIR)$(PREFIX)/$$page"; \
		done
