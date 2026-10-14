#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Offline, non-privileged Chapter 4 regression tests. No login logs or
# production processes are changed; system-backend smoke tests are read-only.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $root = File::Spec->rel2abs("$FindBin::Bin/..");
my $bin = "$root/bin";
my $tmp = tempdir('sasd-user-activity-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
sub put_file {
    my ($name, $content) = @_;
    open my $fh, '>', $name or die "cannot write $name: $!";
    print {$fh} $content;
    close $fh or die "cannot finish $name: $!";
}
sub run_cli {
    my ($tool, @args) = @_;
    my $err = gensym();
    my $pid = open3(undef, my $out, $err, $^X, "$bin/$tool", @args);
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    close $out;
    close $err;
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}

my $who = "$tmp/who.txt";
put_file($who,
    "alice pts/0 2026-10-14 09:01 (vpn.example)\n" .
    "bob console Oct 14 09:02\n" .
    "alice pts/1 2026-10-14 09:03 (:0)\n");
my $ps = "$tmp/ps.txt";
put_file($ps,
    " 101 1 alice S 00:10 /usr/bin/editor\n" .
    " 102 101 alice R+ 00:01 /usr/bin/bash\n" .
    " 103 1 bob Z 2-01:00:00 [zombie]\n");
my ($rc, $out, $err);
for my $cmd (qw(session-report process-report)) {
    ($rc, $out, $err) = run_cli($cmd, '--help');
    is($rc, 0, "$cmd --help succeeds");
    like($out, qr/\AUsage: \Q$cmd\E/, "$cmd prints usage");
    is($err, '', "$cmd help has clean stderr");
    ($rc, $out, $err) = run_cli($cmd, '--version');
    is($rc, 0, "$cmd --version succeeds");
    is($out, "$cmd 0.1.0\n", "$cmd has stable SemVer output");
    ($rc) = run_cli($cmd, '--unrecognized');
    is($rc, 2, "$cmd refuses unknown option");
    ($rc) = run_cli($cmd, '--input', "$tmp/missing");
    is($rc, 3, "$cmd missing fixture is prerequisite error");
    ($rc) = run_cli($cmd, '--user', 'bad name');
    is($rc, 2, "$cmd rejects whitespace in filter");
    my $link = "$tmp/$cmd-link";
    symlink($who, $link) or die "cannot create symlink fixture: $!";
    ($rc) = run_cli($cmd, '--input', $link);
    is($rc, 3, "$cmd rejects symlinked fixture");
}
($rc, $out, $err) = run_cli('session-report', '--input', $who);
is($rc, 0, 'session-report parses mixed Linux/macOS who-style fixture');
like($out, qr/\AUSER\tTTY\tDETAILS\n/, 'session table has header');
like($out, qr/alice\tpts\/0\t2026-10-14 09:01/, 'first session present');
like($out, qr/bob\tconsole\tOct 14 09:02/, 'macOS-style date retained as detail');
like($out, qr/Sessions: 3\nUsers: 2\n\z/, 'session and distinct user totals');
($rc, $out) = run_cli('session-report', '--input', $who, '--user', 'alice');
is($rc, 0, 'session user filter succeeds');
unlike($out, qr/bob\tconsole/, 'session filter excludes other users');
like($out, qr/Sessions: 2\nUsers: 1\n/, 'filtered totals are accurate');
($rc, $out) = run_cli('session-report', '--input', $who, '--null');
is($rc, 0, 'session raw format succeeds');
like($out, qr/alice\x00pts\/0\x002026-10-14 09:01.*?\x00/s, 'NUL fields preserved');
unlike($out, qr/USER\tTTY/, 'no header in NUL mode');
put_file("$tmp/who-invalid", "broken\nalice pts/2 Oct 14 10:01\n");
($rc, $out, $err) = run_cli('session-report', '--input', "$tmp/who-invalid");
is($rc, 1, 'malformed session record yields finding status');
like($out, qr/alice\tpts\/2/, 'valid session survives malformed line');
like($err, qr/skipped 1 malformed/, 'malformed session diagnostic');
put_file("$tmp/who-empty", "");
($rc, $out) = run_cli('session-report', '--input', "$tmp/who-empty");
is($rc, 0, 'empty who inventory succeeds');
like($out, qr/Sessions: 0\nUsers: 0\n/, 'empty who totals explicit');

($rc, $out, $err) = run_cli('process-report', '--input', $ps);
is($rc, 0, 'process-report parses saved ps output');
like($out, qr/\APID\tPPID\tUSER\tSTATE\tELAPSED\tCOMMAND\n/, 'process header');
like($out, qr/102\t101\talice\tR\+\t00:01\t\/usr\/bin\/bash/, 'process state flags preserved');
like($out, qr/Matching: 3\nShown: 3\n\z/, 'process totals');
($rc, $out) = run_cli('process-report', '--input', $ps, '--user', 'alice', '--state', 'R');
is($rc, 0, 'process filters succeed');
like($out, qr/102\t101\talice/, 'matching process included');
unlike($out, qr/101\t1\talice/, 'non-matching process excluded');
like($out, qr/Matching: 1\nShown: 1/, 'filtered process total');
($rc, $out) = run_cli('process-report', '--input', $ps, '--limit', '1');
is($rc, 0, 'process limit accepted');
like($out, qr/Matching: 3\nShown: 1/, 'limit reports matching versus displayed');
($rc, $out) = run_cli('process-report', '--input', $ps, '--null');
is($rc, 0, 'process raw format succeeds');
like($out, qr/101\x001\x00alice\x00S\x0000:10\x00\/usr\/bin\/editor\x00/, 'process NUL fields preserved');
unlike($out, qr/PID\tPPID/, 'no header in NUL process mode');
($rc) = run_cli('process-report', '--limit', '0');
is($rc, 2, 'zero limit rejected');
($rc) = run_cli('process-report', '--limit', '5001');
is($rc, 2, 'excessive limit rejected');
($rc) = run_cli('process-report', '--state', 'S+');
is($rc, 2, 'multiple state letters rejected');
put_file("$tmp/ps-invalid", "invalid line\n 55 1 bob S 00:01 /bin/sh\n");
($rc, $out, $err) = run_cli('process-report', '--input', "$tmp/ps-invalid");
is($rc, 1, 'malformed ps row yields finding status');
like($out, qr/55\t1\tbob/, 'valid process row survives bad line');
like($err, qr/skipped 1 malformed/, 'malformed ps row diagnosed');

# Read-only smoke tests need no users and make no assumption about live
# session counts or process state. Skip only if native backend is absent.
SKIP: {
    skip 'native who not installed', 1 unless -x '/usr/bin/who' || -x '/bin/who';
    ($rc) = run_cli('session-report');
    is($rc, 0, 'native who execution succeeds');
}
SKIP: {
    skip 'native ps not installed', 1 unless -x '/bin/ps' || -x '/usr/bin/ps';
    ($rc) = run_cli('process-report', '--limit', '2');
    is($rc, 0, 'native ps execution succeeds');
}
done_testing();
