# SPDX-License-Identifier: MIT
PREFIX ?= /usr/freeware
DESTDIR ?=

.PHONY: all test install uninstall

all: test

test:
	bash -n bin/rotate tests/test_rotate.sh
	bash tests/test_rotate.sh

install:
	install -d "$(DESTDIR)$(PREFIX)/bin" "$(DESTDIR)$(PREFIX)/man/man1"
	install -m 755 bin/rotate "$(DESTDIR)$(PREFIX)/bin/rotate"
	install -m 644 man/man1/rotate.1 "$(DESTDIR)$(PREFIX)/man/man1/rotate.1"

uninstall:
	rm -f "$(DESTDIR)$(PREFIX)/bin/rotate" "$(DESTDIR)$(PREFIX)/man/man1/rotate.1"
