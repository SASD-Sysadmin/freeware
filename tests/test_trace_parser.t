#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# TRACE-02: offline, secret-free reader/parser contract tests.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
use SASD::Freeware::Trace::Reader;
use SASD::Freeware::Trace::Strace;

my $tmp = tempdir('sasd-trace-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
sub fixture {
    my ($name, $bytes) = @_;
    my $path = File::Spec->catfile($tmp, $name);
    open my $out, '>', $path or die "$path: $!";
    binmode $out;
    print {$out} $bytes or die "$path: $!";
    close $out or die "$path: $!";
    return $path;
}
sub parse {
    my ($bytes, %opts) = @_;
    my $reader = SASD::Freeware::Trace::Reader->open_file(fixture('input', $bytes), %opts);
    my $parser = SASD::Freeware::Trace::Strace->new(reader => $reader,
        (exists $opts{max_pending} ? (max_pending => $opts{max_pending}) : ()));
    my @events;
    while (my $event = $parser->next_event) { push @events, $event; }
    return \@events;
}

my $events = parse(<<'TRACE');
open("/etc/passwd", O_RDONLY) = 3
close(3) = 0
open("/missing/file", O_RDONLY) = -1 ENOENT (No such file or directory)
TRACE
is(scalar(@$events), 3, 'plain calls produce three events');
is($events->[0]->{type}, 'syscall', 'plain event type');
is($events->[0]->{syscall}, 'open', 'syscall name is not allowlisted');
is($events->[2]->{errno}, 'ENOENT', 'errno is separated from return text');
is($events->[2]->{error_text}, 'No such file or directory', 'error description is retained bounded');
is_deeply($events->[2]->{source_lines}, [3], 'source line is one based');

$events = parse("9999  12:34:56.123456 unknown_old_call({a=[1,2]}, \"x\") = mystery <0.125000>\n");
is($events->[0]->{trace_id}, '9999', 'printed trace identity retained');
is($events->[0]->{pid_kind}, 'pid-or-tid', 'printed identity is not overclaimed as PID');
is($events->[0]->{timestamp_format}, 'tt', 'short timestamp format retained');
is($events->[0]->{duration}, '0.125000', 'call duration retained as text');
is($events->[0]->{return_value}, 'mystery', 'symbolic return value retained');

$events = parse("123  1700000000.123456 open(\"x\") = 4</tmp/x>\n--- SIGCHLD {si_signo=SIGCHLD} ---\n+++ killed by SIGTERM +++ (core dumped)\n");
is($events->[0]->{timestamp_format}, 'ttt', 'epoch timestamp format retained without conversion');
is($events->[1]->{type}, 'signal', 'signal is a separate event');
is($events->[2]->{type}, 'process_exit', 'signal process termination is separate');
is($events->[2]->{signal}, 'SIGTERM', 'termination signal retained');

$events = parse("[pid 10] read(3,  <unfinished ...>\n[pid 11] --- SIGCHLD {si_signo=SIGCHLD} ---\n[pid 10] <... read resumed> \"x\", 1) = 1\n");
is(scalar(@$events), 2, 'interleaved unfinished/resumed yields signal and one syscall');
is($events->[1]->{type}, 'syscall', 'resumed call is completed once');
is_deeply($events->[1]->{source_lines}, [1, 3], 'joined call retains both source lines');
is($events->[1]->{trace_id}, '10', 'joined call retains trace identity');

$events = parse("read(3, <unfinished ...>\n");
is($events->[0]->{type}, 'incomplete', 'open call at EOF is incomplete');
is($events->[0]->{continuation}, 'unfinished-at-eof', 'EOF reason is explicit');
$events = parse("<... read resumed> x) = 1\n");
is($events->[0]->{type}, 'incomplete', 'unmatched resumed is visible');

$events = parse("not a syscall table row\n% time     seconds  usecs/call     calls    errors syscall\n");
is($events->[0]->{type}, 'unsupported', 'non-event text is visible');
is($events->[1]->{type}, 'unsupported', 'strace statistics are not syscall events');

$events = parse("bad(\"unterminated) = 1\n\0\nnext() = 0\n");
is($events->[0]->{type}, 'malformed', 'unbalanced quoting/arguments are malformed');
is($events->[1]->{type}, 'malformed', 'NUL record is visible and does not stop reading');
is($events->[2]->{syscall}, 'next', 'reader resumes after invalid record');

my $long = 'x' x 70000;
$events = parse("bad($long) = 0\nnext() = 0\n", max_line_bytes => 1024);
is($events->[0]->{type}, 'malformed', 'overlong line is bounded and visible');
is($events->[0]->{continuation}, 'truncated', 'overlong reason is explicit');
is($events->[1]->{syscall}, 'next', 'reader resumes after overlong line');

my $crlf = parse("close(3) = 0\r\nlast() = symbolic\r\n");
is(scalar(@$crlf), 2, 'CRLF is accepted');
is($crlf->[1]->{source_lines}[0], 2, 'CRLF line numbering is stable');

my $reader = SASD::Freeware::Trace::Reader->open_file(fixture('large', ("x() = 0\n" x 10000)));
my $count = 0;
while (1) { my $row = $reader->next_record; last if $row->{status} eq 'eof'; $count++ if $row->{status} eq 'line'; }
is($count, 10000, 'large input is streamed record by record');

done_testing();
