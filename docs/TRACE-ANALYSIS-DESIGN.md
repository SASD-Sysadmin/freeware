# System call trace analysis design (TRACE-01)

[Deutsch](TRACE-ANALYSIS-DESIGN.de.md) · [Roadmap](ROADMAP.md) · [Project](../README.md)

**Status:** TRACE-01 planning evidence, 25 November 2026. This document specifies a design; it does not ship a parser, a new command, a native adapter, or a release commitment.

## 1. Purpose and non-goals

The proposed toolbox turns an explicitly supplied, saved system-call trace into a small, reproducible, read-only diagnostic report. It is intended for shell pipelines and incident handoff, not for replacing the tracer that produced the input.

Non-goals for TRACE-01 and the initial MVP:

- no live attach, capture, command execution, debugger, GUI, web service, daemon, database, upload, or automatic repair;
- no claim that a failed or slow call proves an application defect;
- no universal lossless representation of every Unix tracing format;
- no platform-support promise for Solaris, AIX, BSD, or macOS;
- no change to `core-report` or the CD-01–CD-07 application-crash plan.

The initial implementation boundary is TRACE-02–04 and TRACE-07 after this design is separately reviewed. TRACE-01 itself is documentation only.

## 2. Existing repository baseline

The repository is a Perl/shell command collection with offline tests, explicit exit-code conventions and read-only defaults. Relevant reuse points are:

| Existing component | Reuse decision |
| --- | --- |
| `SASD::Freeware::External` | Locate an allowlisted native helper using absolute `PATH` entries. It must not become a shell-command evaluator. |
| `bin/process-report` | Pattern for bounded input, explicit `ps` argument vectors, fixture input, malformed-record counts and read-only process reporting. |
| `bin/log-summary` | Small streaming loop and pipeline-friendly aggregate output. Its unstructured severity matching is not a trace parser. |
| `SASD::Freeware::Walk` and network modules | Existing bounded filesystem/native-output patterns where a later feature genuinely needs them; do not couple them to TRACE-02. |
| `bin/core-report` | Separate candidate inventory for core-like filenames. It does not validate dump content and must not be duplicated by trace tools. |
| `tests/test_cli_contracts.t`, `tests/test_repository_contracts.t` | Preserve help/version, documentation, mode and Markdown contracts for later commands. |

No current library parses system-call traces. No current command captures or attaches to a process. `lib/SASD/Freeware/External.pm` is a locator, not permission handling or sandboxing.

## 3. Evidence and tool survey

The following was checked on 25 November 2026. “Not verified” means that neither a local executable nor a sufficiently authoritative, version-specific source was available; it is not a support claim.

### Linux and optional analyzers

| Tool | Observed capability and useful boundary | Cost, license, and decision |
| --- | --- | --- |
| `strace` | Linux userspace tracer using ptrace. `-o` writes text; `-f` follows children/threads, `-ff` separates files; `-tt`/`-ttt` add timestamps; `-T` adds call duration; `-y`/`-yy` decode descriptor paths or device/socket details where available. Output can contain signals, unfinished/resumed calls and abbreviated or escaped arguments. | Official project states LGPL-2.1-or-later for the program. Native tracing has ptrace/kernel/security and workload-impact constraints. Use it as an input producer, never as a library dependency of the offline parser. |
| `strace-log-merge` | Official strace helper for merging `strace -ff -tt` per-process files by textual timestamp. It is not a general causal-order reconstruction and is unsuitable when timestamps are absent or incomparable. | Bundled with strace and LGPL-2.1-or-later. Optional operator tool; TRACE code should not invoke it automatically. |
| `stracepy` | Python scripts convert strace logs to CSV and provide summaries/filesystem views; the project describes multithreaded input support. Its own setup/requirements and format assumptions are outside SASD's Perl runtime. | MIT according to its repository. Useful as comparison material, not a dependency or adoption target. Maintenance/activity and exact format coverage require later review. |
| `strace-analyzer` | Rust program focused on reads/writes and filesystem byte summaries. Its README limits supported input to a particular `-s0 -ff -o` shape and does not support timed variants or multiple process IDs in one input. | GPL-3.0-or-later according to its repository. Valuable as a narrow comparator; license and format boundary prevent embedding in the MIT repository. |
| `strace-tui` | Rust TUI parses common strace flags, can emit JSON, filters/searches calls, and visualizes process/fd relationships. The project also lists missing filters/export and truncation limitations. | Apache-2.0 or MIT. Optional interactive exploration is outside SASD's CLI/offline core and introduces a Rust/Cargo dependency. |
| `strace-graph` | No single authoritative project/version was identified in this review; the name is ambiguous. | Do not infer capability or license from similarly named projects. Revisit only with an exact upstream reference. |

Primary sources reviewed: [strace repository](https://github.com/strace/strace), [strace manual](https://man7.org/linux/man-pages/man1/strace.1.html), [strace Makefile/licensing](https://github.com/strace/strace/blob/master/Makefile.am), [stracepy](https://github.com/bmwcarit/stracepy), [strace-analyzer](https://github.com/wookietreiber/strace-analyzer), and [strace-tui](https://github.com/Rodrigodd/strace-tui). Availability was not verified by installation: all named tools were absent from `PATH` in the working environment.

### Other Unix tracing families

| Family | Evidence and boundary | TRACE decision |
| --- | --- | --- |
| Solaris `truss` | The historical/Oracle ecosystem has version-specific text formats, timestamps/delta times, signals and optional user-level tracing. A Solaris execution environment was not available for native verification in TRACE-01. | Candidate adapter only. Record exact Solaris release, output examples and privilege behavior before coding. |
| AIX `truss` | IBM documentation describes syscall tracing, thread IDs, timestamps/delta times, signals and optional user-level calls; privileged operations are explicitly possible. Output includes AIX-specific names and `Err#` forms. | Candidate adapter only. Do not equate AIX `truss` with Solaris/Linux syntax or request privilege automatically. |
| FreeBSD `truss` | The FreeBSD manual documents a native syscall tracer with platform-specific options and output. No FreeBSD fixture or native run was available. | Candidate adapter only; preserve unknown fields and version-specific semantics. |
| FreeBSD/OpenBSD `ktrace`/`kdump` | `ktrace` records a kernel trace and `kdump` renders it. The binary/renderer relationship and record vocabulary differ from line-oriented strace; formats must not be guessed. | If later needed, use trusted native `kdump` output or a separately evidenced decoder. No binary decoder in the MVP. |
| macOS `dtruss` | DTrace-based output can include syscall arguments, return values, errno and timing. Current macOS security policy, entitlements, SIP and root requirements affect availability; the cited manual describes root-only use. | Capture is outside TRACE-01/MVP. Later work must be version-specific and separately authorized. |

References: [IBM AIX truss](https://www.ibm.com/docs/en/aix/7.1.0?topic=t-truss-command), [FreeBSD truss](https://man.freebsd.org/cgi/man.cgi?manpath=FreeBSD+13.4-RELEASE&query=truss&sektion=1), [macOS dtruss manual mirror](https://man.freebsd.org/cgi/man.cgi?apropos=0&manpath=macOS+13.6.5&query=dtruss&sektion=1m). Solaris and OpenBSD native behavior remain not verified here.

The practical value of a SASD implementation is therefore a small, dependency-free, bounded offline parser and explainable report contract: existing tools capture or visualize well, but none provides the repository's Perl, pipeline, safety, EN/DE documentation, conservative evidence and cross-format uncertainty contract.

## 4. Architecture

Implement only after TRACE-01 review, in small layers:

1. `SASD::Freeware::Trace::Reader` — bounded byte/line reader for an explicit regular file or stdin; counts truncation and rejected records.
2. `SASD::Freeware::Trace::Strace` — Linux text adapter. It recognizes documented variants and returns events or explicit `unknown`, `incomplete`, `malformed` and `unsupported` records.
3. `SASD::Freeware::Trace::Event` — small event constructor/validation layer; it never fills missing fields with guesses.
4. `SASD::Freeware::Trace::Aggregate` — bounded counters and top-N views by syscall, errno, PID/TID and known resource. It must stream and cap cardinality.
5. `SASD::Freeware::Trace::Rules` — pure, explainable findings with evidence references and confidence class.
6. One first CLI, likely `trace-report` or `trace-summary`, after the contract is chosen. Separate commands are justified only when their output and pipeline use are materially different.

Do not create twelve thin aliases. A likely initial split is a compact summary/report command, followed later by focused errors/timing/resource views. `trace-capture`, `trace-sanitize` and comparison are separate authorization/design slices.

Use Perl core modules, three-argument opens, explicit argument vectors and no shell interpolation. The parser should accept a file handle abstraction so tests can use scalar fixtures without changing production input rules.

## 5. Minimal event model

An event is a fact record, not a promise that every backend can populate every field:

| Field | Meaning and absence rule |
| --- | --- |
| `schema` | Versioned internal schema identifier, introduced only with a documented machine-readable contract. |
| `platform` | Observed adapter family, initially `linux-strace`; never inferred from a syscall name alone. |
| `source_format` | Variant such as `strace-text`, `strace-text-pid`, or `unknown`. |
| `source_line` | 1-based input line or bounded source reference; retain for evidence. |
| `pid`, `tid` | Numeric identifiers only when printed and validated; otherwise unknown. A PID is not silently reused as a TID. |
| `timestamp` | Parsed timestamp plus precision/clock form when present; absent means absent. |
| `syscall` | Printed call name, or an explicit unknown record. |
| `arguments` | Bounded, escaped textual representation; parsing must not execute or evaluate it. |
| `return_value` | Parsed numeric/symbolic result when unambiguous. |
| `errno` | Error symbol and optional number when printed; `ERESTART*` is not automatically a final application error. |
| `duration` | Only a printed `-T`-style duration; it is call duration, not CPU or total elapsed time. |
| `signal` | Signal record and bounded text, separate from a syscall result. |
| `process_event` | `fork`, `clone`, `exec`, `exit` or `exit_group` only when observed. Parentage is not inferred from ordering. |
| `fd/resource` | Known decoded path/socket/device only when the source supports it; descriptor reuse and process scope remain explicit. |
| `continuation` | `complete`, `unfinished`, `resumed`, `signal`, `unknown`, or `malformed`. Pending matches are keyed by validated PID/TID and bounded. |
| `confidence` | `observed` for parsed text, `heuristic` for a rule hint, `corroborated` only when independent evidence is supplied. |

Unknown and missing values remain null/unknown. No synthetic timestamp, duration, parent, resource identity or ordering is allowed.

## 6. Linux V1 format contract

The first parser should cover ordinary saved `strace -o trace.log` text without requiring time or duration, then selected combinations:

- plain calls and results;
- PID/TID prefixes from `-f`/`-ff` outputs;
- `-tt` and `-ttt` timestamps;
- `-T` durations;
- signals, process exits, and unfinished/resumed pairs;
- `-y`/`-yy` annotations only as bounded, opaque resource evidence initially.

`-c`/`-C` aggregate summaries are not syscall event streams and should be rejected or treated as a separate unsupported source format. Separate `-ff` files require an explicit list and later merge contract; a single input must not pretend to reconstruct cross-file order.

Parsing rules:

- handle nested brackets, braces, parentheses, quoted strings and escaped quotes without evaluating them;
- join only documented unfinished/resumed records for the same validated PID/TID; leave ambiguous or interrupted pairs visible as incomplete;
- accept multiline records only with a bounded continuation policy and a visible source reference;
- preserve unknown syscall names and unsupported syntax as data, not as silently dropped lines;
- reject or count NULs, terminal controls, overlong lines, invalid numeric ranges, unterminated quotes and truncated continuations;
- stream large files, cap pending calls and aggregate keys, and report all caps/truncation in the summary;
- use byte-safe escaping for terminal output and unambiguous delimiters for machine output.

The parser must distinguish a trace ending while a call is pending from a call that returned an error. It must also keep `EINTR`, restart markers and normal nonblocking results available to the diagnostic layer.

## 7. Diagnostic rule catalog

Rules produce a finding with observed lines, context and an alternative explanation. They do not repair anything or label root cause without corroboration.

| Signal | Conservative interpretation |
| --- | --- |
| `ENOENT` | Missing path or expected probe; relevant when repeated in a required path context. |
| `EACCES`, `EPERM` | Permission/policy evidence; distinguish access denial from lack of privilege to reproduce. |
| `EAGAIN`, `EINTR`, `EINPROGRESS` | Often normal retry/nonblocking/signal behavior; report patterns, not universal failure. |
| `ENOSPC`, `ENOMEM`, `EMFILE`, `EIO`, `EROFS` | High-value context-dependent hints requiring operation, process and nearby evidence. |
| `ECONNREFUSED`, `ETIMEDOUT` | Endpoint/availability or timeout evidence; not proof of remote root cause. |

Long `poll`, `select`, `futex`, `read` or similar calls can be expected waits. `-T` durations are per-call and concurrent calls overlap. A “slow call” view must therefore say “long observed call duration” and never “CPU bottleneck” or “application hang” without more evidence.

Finding classes: `fact`, `normal-pattern`, `attention`, `hypothesis`, `corroborated`. TRACE-02 tests parsing; TRACE-03/04 tests rule output with positive and negative fixtures.

## 8. CLI, privacy and safety contract

The first command should follow repository conventions: `--help` and `--version` are side-effect-free; explicit `--input FILE` or `-` is read-only; no default host scan or capture; diagnostics go to stderr; output is bounded and suitable for a pipe. Exit statuses should reuse the repository distinction: `0` complete/no findings, `1` complete with findings or rejected records as finalized by the command contract, `2` usage/input contract error, `3` missing prerequisite or execution failure. This must be finalized before TRACE-02 coding and documented in `docs/EXIT-CODES.md` only if a new shared convention is actually adopted.

Trace contents are untrusted and potentially secret-bearing. Validate regular files and symlink policy, do not overwrite the source, never execute trace text, avoid echoing argument buffers by default, escape controls, and require explicit private output paths for exports. No network dependency, upload, symbol download, privilege escalation, ptrace-policy change or live attachment is allowed.

## 9. Test strategy

TRACE-02 must add secret-free fixtures covering:

- plain untimed `-o`, PID/TID, `-tt`/`-ttt`, `-T`, `-y`/`-yy`, and separate `-ff` samples;
- nested/escaped/multiline arguments, signals, exits, restarts and unfinished/resumed records;
- unknown syscalls, missing fields, truncated lines, malformed quoting, NUL/control characters and overlong lines;
- repeated errno patterns, expected probes, blocking waits, descriptor reuse and ambiguous process relationships;
- generated large streams to prove bounded memory, pending-state and output limits;
- exact positive/negative rule results and stable source-line references.

Fixture tests are not native acceptance. Later TRACE-10 native Linux acceptance must record exact strace version, kernel/distribution, capture flags, expected facts and limitations in a disposable non-root environment. TRACE-11 needs separate native evidence on each OS/tool/version. CI may run offline fixtures on Ubuntu/macOS, but cannot establish ptrace permission, Solaris/AIX/BSD/macOS tracing support or production safety.

## 10. Open decisions and acceptance criteria

Open before TRACE-02: final command name and output schema; precise line/pending limits; whether malformed input returns 1 or 3; selected multiline grammar; descriptor annotation policy; timestamp clock labels; and whether a future JSONL output is needed.

TRACE-01 is complete when this design is reviewed in both languages, tool/licensing evidence is linked and bounded, the event and V1 format contracts reject invented information, safety boundaries are explicit, and TRACE-02 has deterministic fixture/native acceptance criteria. It does not close a release gate or claim platform support.

## 11. Recommendation for TRACE-02

Implement one shared, streaming Linux text reader and one strace adapter in Perl using only core modules. Start with plain `-o` plus PID/TID, timestamps, duration, signals and unfinished/resumed records. Emit an internal event stream and diagnostics for malformed/unknown/truncated input before adding summaries. Add no native capture and no non-Linux adapter in that slice.
