#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M6.2: offline JSONL fixtures and an argv-only fake postqueue executable.
# No Postfix installation, mail server, user messages or root access required.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $tool = File::Spec->rel2abs("$FindBin::Bin/../bin/mail-queue");
my $tmp = tempdir('sasd-mail-queue-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $input = "$tmp/queue.jsonl";
my $log = "$tmp/argv.txt";
my $mock = "$tmp/postqueue fake client";
my $record = sub {
    my (%p) = @_;
    my $q = $p{queue} // 'incoming';
    my $size = $p{size} // 150;
    my $r = $p{recipients} // '[{"address":"secret@example.test"}]';
    return '{"queue_name":"' . $q . '","queue_id":"A1B2C3",' .
           '"arrival_time":1700000000,"message_size":' . $size . ',' .
           '"sender":"confidential@example.test","recipients":' . $r . '}';
};
sub fixture {
    my ($content) = @_;
    open my $out, '>', $input or die $!;
    binmode $out;
    print {$out} $content;
    close $out or die $!;
    return $input;
}
sub invoke {
    my (@args) = @_;
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, $^X, $tool, @args);
    close $in;
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    close $out;
    close $err;
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}
my ($rc, $out, $err) = invoke('--help');
is($rc, 0, '--help succeeds');
like($out, qr/Usage: mail-queue/, 'help provides usage');
is($err, '', 'help stderr empty');
($rc, $out, $err) = invoke('--version');
is($rc, 0, '--version succeeds');
is($out, "mail-queue 0.1.0\n", 'SemVer metadata correct');
is($err, '', 'version stderr empty');

for my $args (['--bogus'], ['--timeout','0'], ['--timeout','31'],
              ['--timeout','abc'], ['--input',$input,'--client','/x'],
              ['anything'], ['--client', '/tmp/fake', '--input', $input]) {
    ($rc, $out) = invoke(@$args);
    is($rc, 2, 'invalid CLI fails with status 2');
    is($out, '', 'invalid CLI produces no report');
}
($rc, $out, $err) = invoke('--input', "$tmp/missing");
is($rc, 3, 'missing fixture is a prerequisite error');
is($out, '', 'missing fixture cannot produce report');

{
    # Native discovery must not accidentally execute a program from a
    # relative PATH segment or the current directory.
    local $ENV{PATH} = '.';
    ($rc, $out, $err) = invoke();
    is($rc, 3, 'native postqueue missing from safe absolute PATH');
    is($out, '', 'missing native client cannot yield zero-queue success');
}


($rc, $out, $err) = invoke('--input', fixture(''));
is($rc, 0, 'empty Postfix queue succeeds');
like($out, qr/^TOTAL\t0\t0\t0\n/m, 'empty queue total is exactly zero');
is($err, '', 'empty queue has no diagnostic');

my $mixed = join("\n",
    $record->(queue => 'incoming', size => 50),
    $record->(queue => 'active', size => 100, recipients => '[{"address":"a"},{"address":"b"}]'),
    $record->(queue => 'deferred', size => 700),
    $record->(queue => 'hold', size => 200, recipients => '[]'),
    $record->(queue => 'maildrop', size => 20),
) . "\n";
($rc, $out, $err) = invoke('--input', fixture($mixed));
is($rc, 1, 'deferred and hold are actionable findings');
like($out, qr/^deferred\t1\t700\t1\n/m, 'deferred totals correct');
like($out, qr/^hold\t1\t200\t0\n/m, 'hold totals correct');
like($out, qr/^active\t1\t100\t2\n/m, 'recipient counts correct');
like($out, qr/^TOTAL\t5\t1070\t5\n/m, 'all queue totals correct');
unlike($out, qr/confidential|secret|example\.test|A1B2C3/, 'report hides addresses and queue ids');
is($err, '', 'deferred is a finding, not a parse error');
($rc, $out) = invoke('--input', $input, '--null');
is($rc, 1, 'NUL result retains finding status');
my @fields = split(/\0/, $out, -1);
is(scalar(@fields), 29, 'seven four-field rows plus trailing NUL');
is(join("\0", @fields[24..27]), "TOTAL\0005\0001070\0005", 'total NUL record exact');
unlike($out, qr/QUEUE\tMESSAGES/, 'no header in --null mode');
($rc, $out) = invoke('--input', fixture($record->(queue=>'active',size=>123) . "\n"));
is($rc, 0, 'active-only queue is healthy');
like($out, qr/TOTAL\t1\t123\t1/, 'active-only queue totals');
($rc, $out) = invoke('--input', fixture($record->(queue=>'newqueue',size=>12) . "\n"));
is($rc, 1, 'unknown future queue is not mislabeled healthy');
like($out, qr/^other\t1\t12\t1$/m, 'unknown state aggregated as other');
unlike($out, qr/newqueue/, 'unknown raw queue name never emitted');
($rc, $out) = invoke('--input', fixture($record->(queue=>'active',size=>0) . "\n"));
is($rc, 0, 'zero-byte message is valid');
($rc, $out) = invoke('--input', fixture($record->(size=>'1e5') . "\n"));
is($rc, 0, 'integer-valued JSON exponent is accepted');
like($out, qr/TOTAL\t1\t100000\t1/, 'integer-valued exponent counted exactly');

# Postfix explicitly permits new object members; ignore them rather than
# rejecting legitimate future versions or displaying sensitive extensions.
my $extended = $record->(queue => 'active');
substr($extended, -1, 1, ',"future_sender_debug":"never display this"}');
($rc, $out) = invoke('--input', fixture($extended . "\n"));
is($rc, 0, 'unknown Postfix extension member is harmless');
unlike($out, qr/never display this/, 'future metadata is kept private');

# Overly large queues must never return a plausible but truncated total.
my $many = ($record->(queue => 'incoming', size => 1) . "\n") x 20001;
($rc, $out, $err) = invoke('--input', fixture($many));
is($rc, 3, '20001 records exceed the explicit message-count bound');
is($out, '', 'message overflow never publishes partial total');
like($err, qr/message limit/, 'message limit is explained without metadata');


my @bad = (
    ['unterminated', $record->() , qr/unterminated/],
    ['blank', "\n", qr/empty/],
    ['invalid JSON', "{oops}\n", qr/malformed/],
    ['array top-level', "[]\n", qr/malformed/],
    ['missing metadata', "{\"queue_name\":\"active\"}\n", qr/invalid|missing/],
    ['bad queue name', $record->(queue=>"act\\u001bive") . "\n", qr/queue name/],
    ['invalid size', $record->(size=>'-1') . "\n", qr/size/],
    ['fractional size', $record->(size=>'1.5') . "\n", qr/size/],
    ['too large size', $record->(size=>'9999999999999999') . "\n", qr/size/],
    ['bad recipients', $record->(recipients=>'"hidden"') . "\n", qr/recipient/],
    ['bad recipient record', $record->(recipients=>'[{"private":"yes"}]') . "\n", qr/recipient/],
    ['malicious control field', $record->(queue=>'bad\\nname') . "\n", qr/queue/],
    ['trailing garbage', $record->() . "\nGARBAGE\n", qr/malformed/],
    ['line size', ' ' x (65537) . "\n", qr/record exceeds/],
    ['overall size', ' ' x (8 * 1024 * 1024 + 10) . "\n", qr/8 MiB/],
);
for my $test (@bad) {
    my ($name, $blob, $pattern) = @$test;
    ($rc, $out, $err) = invoke('--input', fixture($blob));
    is($rc, 3, "$name rejects untrustworthy report");
    is($out, '', "$name prints no misleading partial summary");
    like($err, $pattern, "$name diagnostic categorized");
    unlike($err, qr/confidential|secret|example\.test|A1B2C3|GARBAGE/, "$name does not echo message details");
}
# Explicitly reject symlink inputs and sensitive paths without echoing them.
fixture($record->() . "\n");
symlink($input, "$tmp/linked.jsonl") or die $!;
($rc, $out) = invoke('--input', "$tmp/linked.jsonl");
is($rc, 3, 'symlink fixture rejected');
is($out, '', 'symlink fixture has no report');

open my $fh, '>', $mock or die $!;
print {$fh} <<'MOCK';
#!/usr/bin/env perl
use strict;
use warnings;
if (defined $ENV{SASD_MAIL_QUEUE_ARG_LOG}) {
    open my $log, '>', $ENV{SASD_MAIL_QUEUE_ARG_LOG} or die $!;
    print {$log} join('\n', @ARGV), "\nMAIL_CONFIG=", ($ENV{MAIL_CONFIG} // '<unset>'), "\n";
    close $log;
}
my $mode = $ENV{SASD_MAIL_QUEUE_MODE} // 'normal';
if ($mode eq 'failure') { print STDERR "SECRET-RECIPIENT-error\n"; exit 4; }
if ($mode eq 'timeout') { sleep 3; exit 0; }
if ($mode eq 'huge') { print 'A' x (8*1024*1024+1); exit 0; }
print '{"queue_name":"active","queue_id":"ABCD",' .
      '"arrival_time":1700000000,"message_size":42,' .
      '"sender":"do-not-print@private.test",' .
      '"recipients":[{"address":"private.test"}]}' . "\n";
MOCK
close $fh or die $!;
chmod(0755, $mock) or die $!;
local $ENV{SASD_MAIL_QUEUE_ARG_LOG} = $log;
local $ENV{SASD_MAIL_QUEUE_MODE} = 'normal';
local $ENV{MAIL_CONFIG} = '/tmp/untrusted-queue-instance';
($rc, $out, $err) = invoke('--client', $mock);
is($rc, 0, 'argv-only postqueue stub succeeds');
like($out, qr/^active\t1\t42\t1$/m, 'postqueue -j parsed');
is($err, '', 'native client stub produces no stderr');
open my $inspect, '<', $log or die $!;
my $logged = do { local $/; <$inspect> };
close $inspect;
is($logged, "-j\nMAIL_CONFIG=<unset>\n", 'only -j is passed; environment config override removed');
unlike($out, qr/private\.test/, 'native client addresses never shown');
{
    local $ENV{SASD_MAIL_QUEUE_MODE} = 'failure';
    ($rc, $out, $err) = invoke('--client', $mock);
    is($rc, 1, 'native postqueue nonzero is finding');
    is($out, '', 'native failure produces no output');
    unlike($err, qr/SECRET-RECIPIENT/, 'native stderr suppressed');
}
{
    local $ENV{SASD_MAIL_QUEUE_MODE} = 'timeout';
    ($rc, $out, $err) = invoke('--client', $mock, '--timeout', '1');
    is($rc, 3, 'hanging native client is bounded by timeout');
    is($out, '', 'timeout produces no partial report');
    like($err, qr/timed out/, 'timeout has useful diagnostic');
}
{
    local $ENV{SASD_MAIL_QUEUE_MODE} = 'huge';
    ($rc, $out, $err) = invoke('--client', $mock);
    is($rc, 3, 'oversized native listing fails safely');
    is($out, '', 'oversize native listing not printed');
}
($rc, $out) = invoke('--client', 'relative/path');
is($rc, 3, 'relative client path rejected');
is($out, '', 'invalid client path no output');
symlink($mock, "$tmp/client-symlink") or die $!;
($rc) = invoke('--client', "$tmp/client-symlink");
is($rc, 3, 'symlink native client rejected');

done_testing();
