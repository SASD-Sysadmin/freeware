# TRACE-02 parser reference

Status: implemented and fixture-tested in the TRACE-02 slice. This is an
internal library contract, not a public JSON/JSONL schema and not a native
`strace` acceptance claim.

## API

`SASD::Freeware::Trace::Reader` accepts an explicitly supplied binary filehandle:

```perl
my $reader = SASD::Freeware::Trace::Reader->open_file($path);
my $reader = SASD::Freeware::Trace::Reader->new(fh => \*STDIN);
my $row = $reader->next_record;
```

`open_file` accepts only an existing regular, non-symlink file. `new` is the
filehandle boundary used for stdin and tests. `next_record` returns `line` with
`text` and a 1-based `line_no`, or `truncated`, `invalid`, `error` and `eof`.
Rejected records contain only a safe diagnostic, never their raw contents.

`SASD::Freeware::Trace::Strace` consumes a reader:

```perl
my $parser = SASD::Freeware::Trace::Strace->new(
    reader => $reader, max_pending => 1024,
);
while (my $event = $parser->next_event) { ... }
```

Events are blessed `SASD::Freeware::Trace::Event` hashes. `as_hash` provides a
shallow copy for later internal consumers. No event is serialized as a public
machine-readable format in this slice.

## Event contract

`type` is one of `syscall`, `signal`, `process_exit`, `malformed`,
`unsupported`, `incomplete` or `reader_error`. All events carry `platform`
(`linux`), `source_format` (`strace-text`) and `source_lines`.

Syscall events may carry `syscall`, bounded textual `arguments`,
`return_value`, `errno`, `error_text`, `duration`, `resource_annotation`,
`timestamp`, `timestamp_format`, `trace_id`, `pid_kind` and `continuation`.
Missing fields are absent, never zero-filled. A duration is call duration from
`-T`, not CPU or total elapsed time. Timestamps remain exact strings with
`tt` (`HH:MM:SS.fraction`) or `ttt` (epoch seconds with fraction); no lossy
floating-point conversion is performed. Symbolic returns remain symbolic.

Numeric prefixes and `[pid N]` labels are preserved as `trace_id` with
`pid_kind => pid-or-tid`; the parser does not claim that an ambiguous printed
identifier is a verified PID or TID. An unprefixed stream uses the private key
`stream:1` only for continuation matching and never exposes it as an ID.

## Supported syntax and boundaries

The parser supports classic single-line calls, unknown syscall names, nested
`()`, `[]` and `{}` arguments, quoted/escaped text, `-tt` and `-ttt` prefixes,
`-T` durations, common PID prefixes, signals, normal and signal termination,
restart calls, and bounded opaque `-y`/`-yy`-style annotations. It joins an
`unfinished` record only with the same stream/printed identity and exact
syscall name. Joined events retain both input line numbers and are emitted once.

Unmatched resumes, duplicate unfinished identities, pending-limit overflow and
EOF with an open call are visible `incomplete` events. A malformed or
unsupported record does not stop later records. `strace -c`/`-C` tables,
unknown line formats, multiline syntax without the documented unfinished /
resumed shape, separate `-ff` file merging, and binary trace formats are not
supported. They are never treated as normal syscall events.

## Limits and safety

The reader defaults are 65,536 bytes per line, 4,096-byte reads and a
1 MiB discard budget for one overlong record. It retains at most the configured
line prefix while consuming through the terminating LF, so a hostile line is
not first allocated in full. CRLF and a final unterminated line are accepted.
NUL and C0/DEL controls (except tab) are rejected. The parser defaults to 1,024
pending calls and caps argument/diagnostic text at 4,096 bytes. Limits are
configurable only within defensive bounds.

Trace input is untrusted and potentially secret. The library performs no
network, shell, evaluation, execution, privilege change or source mutation.
Control bytes are escaped in event fields. Consumers must minimize argument
display and keep reports private.

## Evidence and next use

`tests/test_trace_parser.t` covers plain, historical and unknown names,
timestamps, durations, errors, signals, exits, nested syntax,
unfinished/resumed interleaving, malformed/truncated input, NUL/control
handling, CRLF, exact source lines and a 10,000-line stream. These are
synthetic offline fixtures, not native strace acceptance. TRACE-03 may consume
the event stream for bounded aggregation; it must preserve these distinctions.
