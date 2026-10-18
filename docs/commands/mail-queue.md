# `mail-queue` – read-only Postfix queue summary (M6.2)

[Deutsch](mail-queue.de.md) · [Project](../../README.md) · [Roadmap](../ROADMAP.md) · [Manpage](../../man/man1/mail-queue.1)

## Purpose and requirements

`mail-queue` reports a bounded **aggregate snapshot** of a local Postfix mail
queue without revealing message identifiers, addresses, bodies, or recipient
delivery errors. It invokes only `postqueue -j`, available in **Postfix 3.1+**.
It never calls the modifying `postqueue -f`, `postqueue -i` or `postsuper`
operations. There is no mail sending, authentication, queue management or root
requirement. The current user still needs permission to query the Postfix queue.

The command requires Perl with `JSON::PP` (included in contemporary Perl
installations). No CPAN install is performed. Offline `--input` mode works
without Postfix and makes it possible to test fixtures safely on Linux/macOS.
The implementation does not support Exim, Sendmail, old `mailq` text output,
or remote queues in M6.2.

## Usage

```sh
# Live local queue (Postfix 3.1+, no privileged changes)
./bin/mail-queue
./bin/mail-queue --timeout 8

# Explicit trusted native executable (for unusual installations)
./bin/mail-queue --client /usr/sbin/postqueue

# Offline fixture analysis; no postqueue process is launched
./bin/mail-queue --input ./queue-fixture.jsonl

# Four NUL-terminated fields per record, no heading
./bin/mail-queue --input ./queue-fixture.jsonl --null

./bin/mail-queue --help
./bin/mail-queue --version
```

`--timeout` is 1–30 seconds (default 10); it covers the whole native client
execution, not each message. `--client` must name a regular executable with an
absolute path, not a symlink. With no `--client`, the tool locates `postqueue`
using absolute directories in `PATH`; relative PATH entries are ignored.
`--client` and `--input` cannot be combined. `--input` must be a readable
regular file, not a symlink.

The tool discards the inherited `MAIL_CONFIG` and `MAIL_VERBOSE` variables to
avoid silently querying a different Postfix instance. Use only an explicitly
reviewed client executable; do not supply an untrusted script as `--client`.

## Output and interpretation

```text
QUEUE       MESSAGES  BYTES  RECIPIENTS
maildrop    0         0      0
incoming    1         900    2
active      2         1800   2
deferred    1         700    1
hold        0         0      0
other       0         0      0
TOTAL       4         3400   5
```

The real output is tab-separated, with the seven rows in fixed order.
`BYTES` is the sum of Postfix `message_size` fields (message header/body
size), **not filesystem usage**. `RECIPIENTS` counts the recipient objects
associated with queued messages, not unique addresses. `other` aggregates
unknown queue names without displaying untrusted values.

`postqueue -j` is a **non-atomic snapshot**. According to the Postfix manual,
a changing queue can cause duplicate or missing messages; even a successful
exit is therefore not a transactionally consistent audit. A large queue beyond
the built-in bounds fails without presenting incomplete totals.

## Exit codes and bounds

| Code | Meaning |
| --- | --- |
| `0` | Complete listing parsed; no deferred, held, or unrecognized queue entries. An empty queue also returns 0. |
| `1` | Queue findings (`deferred`, `hold`, `other`), or native `postqueue` returned nonzero. Native failures produce no summary. |
| `2` | Invalid command line, including conflicting input/client options. |
| `3` | Missing/unsafe executable or input, missing JSON parser, timeout, malformed JSONL, or any size/count limit exceeded. No partial success summary. |

The tool accepts at most **8 MiB** per listing, **64 KiB** per JSON line,
and **20,000 messages**. Fields and totals must be representable as bounded
nonnegative integers. `--null` reports *exactly four NUL-terminated fields*
per row in the same order: queue name, message count, byte count,
recipient count. There are no headings in this mode.

## Security, privacy, and tests

The raw JSON from Postfix may contain private envelope addresses and delivery
failure text. The tool validates necessary structure but prints **only**
aggregate counts. It also suppresses raw native-client stderr, bounds stdout,
uses an argv-only child process (no shell) and terminates hanging clients.
Avoid storing unredacted production `postqueue -j` output as a test fixture.
A saved fixture is read only; it is never executed as a command.

```sh
perl -c bin/mail-queue
prove tests/test_mail_queue.t
make test
make shellcheck
# Full CI also checks staging install/uninstall and existing DNS/LDAPS integration.
```

The automated suite uses fabricated JSON-Lines data and a fake `postqueue`
executable. **A live Postfix 3.1+ acceptance test has not yet been performed**;
Linux/macOS CI demonstrates parser/CLI portability but not a native Postfix
installation on either platform.

Postfix documentation: [postqueue(1)](https://www.postfix.org/postqueue.1.html).
