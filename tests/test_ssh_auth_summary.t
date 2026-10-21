#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M7.3: Self-contained, offline regression tests. Never consult host auth.log,
# invoke sshd or exercise real login credentials in this fixture suite.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $program = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'ssh-auth-summary');
my $dir = tempdir('sasd-ssh-auth-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);

sub file_with {
    my ($name, $data) = @_;
    my $file = File::Spec->catfile($dir, $name);
    open my $out, '>', $file or die 'cannot create fixture';
    binmode $out;
    print {$out} $data or die 'cannot write fixture';
    close $out or die 'cannot close fixture';
    return $file;
}
sub invoke {
    my ($data, @args) = @_;
    # Passing an argv list directly avoids any test-time shell interpretation.
    my $err = gensym();
    my $pid = open3(my $in, my $out, $err, $^X, $program, @args);
    binmode($in);
    print {$in} $data if defined $data && length $data;
    close $in;
    binmode($out);
    binmode($err);
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    close $out;
    close $err;
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}
sub summary_count {
    my ($report, $kind) = @_;
    my ($number) = $report =~ /^\Q$kind\E\t([0-9]+)$/m;
    return $number;
}

my ($rc, $out, $err) = invoke(undef, '--help');
is($rc, 0, 'help works');
like($out, qr/\AUsage: ssh-auth-summary /, 'help says usage');
is($err, '', 'help no stderr');
($rc, $out, $err) = invoke(undef, '--version');
is($rc, 0, 'version works');
is($out, "ssh-auth-summary 0.1.0\n", 'version exact');
is($err, '', 'version no stderr');
for my $args (['--bad'], ['--input'], ['unexpected'], ['--input', ''], ['--null', 'extra']) {
    ($rc, $out) = invoke(undef, @$args);
    is($rc, 2, 'invalid CLI has status 2');
    is($out, '', 'invalid CLI has no report');
}

my $accepted = 'Oct 21 08:30:04 host sshd[123]: Accepted publickey for alice from 192.0.2.4 port 2200 ssh2: secret-auth-key';
my $failed = '<38>Oct 21 08:30:05 host sshd[124]: Failed password for invalid user eve from 198.51.100.13 port 2222 ssh2';
my $invalid = 'Oct 21 08:30:06 host sshd[125]: Invalid user eve from 2001:db8::1 port 40';
my $other = 'Oct 21 08:30:07 host sshd[126]: Connection closed by authenticating user secret from 192.0.2.5';
my $service = 'Oct 21 08:30:08 host sudo[127]: Accepted password for alice from 192.0.2.4 port 2200 ssh2';
my $content = join("\n", $accepted, $failed, $invalid, $other, $service) . "\n";
($rc, $out, $err) = invoke($content);
is($rc, 0, 'five valid envelopes recognized');
is($err, '', 'valid input no stderr');
like($out, qr/\AEVENT\tCOUNT\n/, 'TSV schema');
for my $kind (qw(ACCEPTED FAILED INVALID_USER OTHER_SSHD OTHER_SERVICE)) {
    is(summary_count($out, $kind), 1, "$kind exactly one");
}
is(summary_count($out, 'UNKNOWN'), 0, 'all structures recognized');
is(summary_count($out, 'TOTAL'), 5, 'five physical input records');
unlike($out, qr/alice|eve|192\.0\.2|198\.51|secret|sshd\[|host/, 'no private payload or identity in TSV');

($rc, $out) = invoke($content, '--null');
is($rc, 0, 'NUL mode success');
like($out, qr/\0\z/, 'NUL last terminator');
my @fields = split(/\0/, $out, -1);
pop @fields;
is(scalar(@fields), 14, 'seven two-field records');
is(join('|', @fields[0,1]), 'ACCEPTED|1', 'NUL first record');
is(join('|', @fields[-2,-1]), 'TOTAL|5', 'NUL last record');
unlike($out, qr/alice|eve|192\.0\.2/, 'NUL does not leak identities');

my $f = file_with('name with spaces.log', $content);
($rc, $out) = invoke(undef, '--input', $f);
is($rc, 0, 'named regular file works');
is(summary_count($out,'TOTAL'), 5, 'file contents accounted for');
($rc, $out) = invoke('', '--input', '-');
is($rc, 0, 'explicit stdin with empty input works');
is(summary_count($out, 'TOTAL'), 0, 'empty snapshot is empty, not a failure');

# An unknown header is a finding, not a fabricated failed authentication.
my @unverifiable = (
    'sshd[123]: Accepted password for admin from 192.0.2.1 port 22 ssh2',
    '<999>Oct 21 08:30:04 host sshd[123]: Accepted password for admin from 192.0.2.1 port 22 ssh2',
    '<003>Oct 21 08:30:04 host sshd[123]: Failed password for bob from 192.0.2.1 port 22 ssh2',
    ' Oct 21 08:30:04 host sshd[123]: Accepted password for bob from 192.0.2.1 port 22 ssh2',
    'Feb 30 08:30:04 host sshd[123]: Accepted password for bob from 192.0.2.1 port 22 ssh2',
    'Oct 00 08:30:04 host sshd[123]: Accepted password for bob from 192.0.2.1 port 22 ssh2',
    'Oct 21 25:30:04 host sshd[123]: Accepted password for bob from 192.0.2.1 port 22 ssh2',
    'Oct 21 08:60:04 host sshd[123]: Accepted password for bob from 192.0.2.1 port 22 ssh2',
    'Oct 21 08:30:70 host sshd[123]: Accepted password for bob from 192.0.2.1 port 22 ssh2',
    'Oct 21 08:30:04 host sshd[pid]: Accepted password for bob from 192.0.2.1 port 22 ssh2',
    'Oct 21 08:30:04 host sshd Accepted password for bob from 192.0.2.1 port 22 ssh2',
    'Oct 21 08:30:04 host',
    '{"SYSLOG_IDENTIFIER":"sshd","MESSAGE":"Accepted password for bob"}',
);
($rc, $out, $err) = invoke(join("\n", @unverifiable) . "\n");
is($rc, 1, 'unverifiable envelopes yield exit 1');
is(summary_count($out,'UNKNOWN'), scalar(@unverifiable), 'all malformed headers unknown');
is(summary_count($out,'ACCEPTED'), 0, 'no success derived from incomplete headers');
is($err, '', 'unknown is a finding, not parser error');
unlike($out, qr/admin|bob|192\.0\.2|pid/, 'no private data on unknown');

my @other_ssh = (
    'Oct 21 08:30:04 host sshd[1]: Client log says Accepted password for someone',
    'Oct 21 08:30:04 host sshd[1]: Failed password for bob from 192.0.2.1 port 00000 ssh2',
    'Oct 21 08:30:04 host sshd[1]: Failed password for bob from 192.0.2.1 port 65536 ssh2',
    'Oct 21 08:30:04 host sshd[1]: Accepted password for bob from malicious-name.invalid port 22 ssh2',
    'Oct 21 08:30:04 host sshd[1]: accepted password for bob from 192.0.2.1 port 22 ssh2',
    'Oct 21 08:30:04 host sshd[1]: Failed password for bob from 192.0.2.1 port 22 ssh1',
    'Oct 21 08:30:04 host sshd[1]: Invalid user bob from 192.0.2.1 port 70000',
    'Oct 21 08:30:04 host sshd[1]: Accepted password for bob from 192.0.2.1 port 22',
    "Oct 21 08:30:04 host sshd[1]: \e[31mAccepted password for bob from 192.0.2.1 port 22 ssh2\e[0m",
);
($rc, $out) = invoke(join("\n", @other_ssh) . "\n");
is($rc, 0, 'unrecognized sshd messages preserve success status');
is(summary_count($out,'OTHER_SSHD'),scalar(@other_ssh),'all out-of-contract patterns OTHER_SSHD');
is(summary_count($out,'ACCEPTED'),0,'no broad success heuristic');
is(summary_count($out,'FAILED'),0,'no broad failed heuristic');
unlike($out, qr/\e|bob|192\.0\.2/, 'control characters and names never escape');

# Cover less common but documented OpenSSH authentication method spellings.
my @methods = (
    'Oct 21 08:30:04 host sshd[1]: Accepted keyboard-interactive/pam for alice from 192.0.2.20 port 23 ssh2',
    'Oct 21 08:30:04 host sshd[2]: Accepted gssapi-with-mic for alice from 192.0.2.21 port 24 ssh2',
    'Oct 21 08:30:04 host sshd[3]: Failed keyboard-interactive/pam for bob from 192.0.2.22 port 25 ssh2',
    'Oct 21 08:30:04 host sshd[4]: Failed gssapi-with-mic for bob from 192.0.2.23 port 26 ssh2',
);
($rc, $out) = invoke(join("\n", @methods) . "\n");
is($rc, 0, 'non-password methods recognized');
is(summary_count($out,'ACCEPTED'),2, 'two alternative accepted methods');
is(summary_count($out,'FAILED'),2, 'two alternative rejected methods');

# UNKNOWN must keep the same nonzero status in NUL output; reporting format
# is presentation only and cannot conceal an incomplete source classification.
($rc, $out) = invoke("garbled envelope\n", '--null');
is($rc, 1, 'NUL does not erase unknown finding status');
like($out, qr/UNKNOWN\x001\x00/, 'UNKNOWN remains machine-readable');

my @valid = (
    '<0>Oct  9 00:00:00 a sshd: Accepted password for abc from 2001:db8::1 port 1 ssh2',
    '<191>Feb 29 23:59:59 a sshd[2147483647]: Failed publickey for abc from 192.0.2.10 port 65535 ssh2',
    'Apr 30 23:59:59 a sshd[999]: Invalid user bob from 192.0.2.10 port 22',
    "Oct 21 08:30:04 a sshd[42]: Accepted password for abc from 192.0.2.10 port 22 ssh2\r",
);
($rc, $out) = invoke(join("\n", @valid) . "\n");
is($rc, 0, 'boundary timestamps, PRI, CRLF valid');
is(summary_count($out,'ACCEPTED'),2,'two accepted patterns');
is(summary_count($out,'FAILED'),1,'one failed pattern');
is(summary_count($out,'INVALID_USER'),1,'one invalid-user pattern');

my $many = ('Oct 21 08:30:04 host sshd[4]: auth challenge' . "\n") x 50001;
my @fatal = (
    ['not_terminated', $accepted, 'unterminated last record'],
    ['blank', "\n", 'blank line'],
    ['embedded_blank', "$accepted\n\n", 'middle blank line'],
    ['bare_cr', "${accepted}\rinside\n", 'bare CR'],
    ['nul', "${accepted}\0inside\n", 'NUL byte'],
    ['too_long', "Oct 21 08:30:04 host sshd[1]: " . ('a' x 135000) . "\n", 'oversize physical line'],
    ['many', $many, 'record count limit'],
    ['total_bytes', ('x' x (16 * 1024 * 1024 + 1)), 'byte limit'],
);
for my $case (@fatal) {
    my ($name, $body, $reason) = @$case;
    my $fixture = file_with("$name.log", $body);
    ($rc, $out, $err) = invoke(undef, '--input', $fixture);
    is($rc, 3, "$reason => exit 3");
    is($out, '', "$reason => no partial report");
    like($err, qr/\Assh-auth-summary: /, "$reason => generic diagnostic");
    unlike($err, qr/host|alice|sshd\[|192\.0\.2|secret/i, "$reason => no raw data");
}
my $missing = File::Spec->catfile($dir,'private-missing-log');
($rc,$out,$err) = invoke(undef,'--input',$missing);
is($rc,3,'missing file exit 3');
is($out,'','missing file no report');
unlike($err,qr/private-missing-log/,'missing private path not echoed');
($rc,$out) = invoke(undef,'--input',$dir);
is($rc,3,'directory not accepted');
is($out,'','directory no report');
my $link=File::Spec->catfile($dir,'log-symlink');
SKIP: {
    skip 'symlinks unavailable', 2 unless symlink($f,$link);
    ($rc,$out) = invoke(undef,'--input',$link);
    is($rc,3,'symlink rejected');
    is($out,'','symlink no report');
}

done_testing();
