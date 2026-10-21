#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M7.2: Fully offline, deterministic regression tests; no host logs are read.
# The key security property is refusing "severity" words in MESSAGE.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $program = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'syslog-summary');
my $tmp = tempdir('sasd-syslog-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);

sub fixture {
    my ($name, $data) = @_;
    my $path = File::Spec->catfile($tmp, $name);
    open my $handle, '>', $path or die "cannot create fixture: $!";
    binmode($handle);
    print {$handle} $data or die "cannot write fixture: $!";
    close $handle or die "cannot close fixture: $!";
    return $path;
}

sub invoke {
    my ($stdin, @args) = @_;
    # Never use a shell to pass malicious test fixtures or source filenames.
    my $stderr = gensym();
    my $pid = open3(my $input, my $stdout, $stderr, $^X, $program, @args);
    binmode($input);
    print {$input} $stdin if defined $stdin && length($stdin);
    close $input;
    binmode($stdout);
    binmode($stderr);
    local $/;
    my $output = <$stdout> // '';
    my $error = <$stderr> // '';
    close $stdout;
    close $stderr;
    waitpid($pid, 0);
    return ($? >> 8, $output, $error);
}

my ($rc, $out, $err) = invoke(undef, '--help');
is($rc, 0, '--help exits 0');
like($out, qr/\AUsage: syslog-summary /, '--help has usage');
is($err, '', '--help no stderr');
($rc, $out, $err) = invoke(undef, '--version');
is($rc, 0, '--version exits 0');
is($out, "syslog-summary 0.1.0\n", 'stable version');
is($err, '', '--version no stderr');
for my $args (['--unknown'], ['--input'], ['other'], ['--input', ''],
              ['--format', 'invalid'], ['--format', 'RFC5424'],
              ['--format'], ['--null', 'other']) {
    ($rc, $out) = invoke(undef, @$args);
    is($rc, 2, 'invalid command line exits 2');
    is($out, '', 'bad CLI never prints a report');
}

# Include all severities using facility offsets, so PRI modulo eight rather
# than direct PRI equality is verified. TEXT deliberately contradicts PRI.
my $rfc3164 = join('', map {
    my $pri = 32 + $_;
    "<$pri>Oct 21 08:30:04 lab-host postfix/smtpd[42]: ERROR WARNING secret-3164\n";
} 0..7);
my $rfc5424 = join('', map {
    my $pri = 160 + $_;
    "<$pri>1 2026-10-21T08:30:04Z lab-app daemon 123 EVENT - ALERT secret-5424\n";
} 0..7);
my $f = fixture('all.syslog', $rfc3164 . $rfc5424);
my $path_with_space = fixture('name with spaces.syslog', $rfc3164);
($rc, $out, $err) = invoke(undef, '--input', $f);
is($rc, 0, 'all sixteen correctly formed RFC3164/RFC5424 records accepted');
like($out, qr/\APRIORITY\tLEVEL\tCOUNT\n/, 'TSV schema');
for my $n (0..7) {
    like($out, qr/^$n\t[A-Z]+\t2$/m, "severity $n calculated from PRI, not MESSAGE");
}
like($out, qr/^-\tTOTAL\t16$/m, 'full count');
like($out, qr/^-\tUNKNOWN\t0$/m, 'no unverified levels');
unlike($out, qr/secret-3164|secret-5424|lab-host|lab-app|EVENT/, 'never disclose sources');
is($err, '', 'valid fixtures have no error output');
($rc, $out) = invoke(undef, '--input', $path_with_space);
is($rc, 0, 'path containing spaces is not shell-split');
like($out, qr/^-\tTOTAL\t8$/m, 'file with whitespace path parsed');

($rc, $out) = invoke(undef, '--input', $f, '--null');
is($rc, 0, 'NUL output success');
ok($out =~ /\0\z/, 'NUL stream correctly terminated');
my @fields = split /\0/, $out, -1;
pop @fields;
is(scalar(@fields), 30, '10 rows x 3 NUL fields');
is(join('|', @fields[0..2]), '0|EMERGENCY|2', 'NUL data schema');
is(join('|', @fields[-3..-1]), '-|TOTAL|16', 'NUL terminal record');
unlike($out, qr/secret-3164|secret-5424/, 'NUL output does not leak message');

($rc, $out) = invoke($rfc3164, '--format', 'rfc3164');
is($rc, 0, 'RFC3164-only accepts matching records');
like($out, qr/^-\tTOTAL\t8$/m, 'RFC3164 count');
($rc, $out) = invoke($rfc5424, '--format', 'rfc5424');
is($rc, 0, 'RFC5424-only accepts matching records');
like($out, qr/^-\tTOTAL\t8$/m, 'RFC5424 count');
($rc, $out) = invoke($rfc3164, '--format', 'rfc5424');
is($rc, 1, 'RFC3164 source not silently upgraded to RFC5424');
like($out, qr/^-\tUNKNOWN\t8$/m, 'mismatched format marked unknown');
($rc, $out) = invoke($rfc5424, '--format', 'rfc3164');
is($rc, 1, 'RFC5424 source not misread as RFC3164');
like($out, qr/^-\tUNKNOWN\t8$/m, 'format mismatch still counted');

# These plausible-looking lines have no authoritative PRI. In particular,
# a process can include '<3>' in MESSAGE; it must never become ERROR.
my @unknowns = (
    'Oct 21 08:30:04 host app: ERROR CRITICAL WARNING',
    'Oct 21 08:30:04 host app: <3> malicious message',
    '<3> forged-prefix-with-no-syslog-envelope',
    '<192>Oct 21 08:30:04 host app: invalid PRI',
    '<003>Oct 21 08:30:04 host app: noncanonical PRI',
    '<-1>Oct 21 08:30:04 host app: negative PRI',
    '<3>Dec 00 08:30:04 host app: invalid day',
    '<3>Dec 32 08:30:04 host app: invalid day',
    '<3>Feb 30 08:30:04 host app: impossible February day',
    '<3>Apr 31 08:30:04 host app: impossible April day',
    ' <3>Oct 21 08:30:04 host app: leading whitespace before PRI',
    '<3>Dec 15 25:30:04 host app: invalid hour',
    '<3>Dec 15 08:60:04 host app: invalid minute',
    '<3>Dec 15 08:30:60 host app: invalid second',
    '<3>Foo 15 08:30:04 host app: bogus month',
    '<3>Oct 21 08:30:04: fake-header',
    'prefix <3>Oct 21 08:30:04 host app: unanchored PRI',
    '<3>1 bogus-timestamp host app id id - MESSAGE',
    '<3>1 2026-02-30T08:30:04Z host app id id - MESSAGE',
    '<3>1 2026-10-21T24:30:04Z host app id id - MESSAGE',
    '<3>1 2026-10-21T08:30:04+25:00 host app id id - MESSAGE',
    '<3>2 2026-10-21T08:30:04Z host app id id - wrong version',
    '<3>1 2026-10-21T08:30:04Z host app id id [id bad="unclosed] MESSAGE',
    '<3>1 2026-10-21T08:30:04Z host app id id [id bad="unescaped]value"] MESSAGE',
    '<3>1 2026-10-21T08:30:04Z host app id id [id a="oops"]oops MESSAGE',
    '<3>1 2026-10-21T08:30:04Z host app id id',
    '<3>1 2026-04-31T08:30:04Z host app id id - invalid date',
);
($rc, $out, $err) = invoke(join("\n", @unknowns) . "\n");
is($rc, 1, 'all unverified priorities cause finding code 1');
like($out, qr/^-\tUNKNOWN\t27$/m, 'all 27 unverified records counted');
like($out, qr/^3\tERROR\t0$/m, 'not a single ERROR fabricated from text');
like($out, qr/^-\tTOTAL\t27$/m, 'no unverified records silently ignored');
unlike($out, qr/malicious|forged|MESSAGE|oops|unclosed/, 'unverified message content not disclosed');
is($err, '', 'unknown metadata is not a fatal parsing error');
($rc, $out) = invoke(join("\n", @unknowns) . "\n", '--null');
is($rc, 1, 'NUL mode retains UNKNOWN finding status 1');
like($out, qr/-\x00UNKNOWN\x0027\x00/, 'NUL UNKNOWN count is machine readable');
unlike($out, qr/malicious|forged/, 'NUL unknown mode does not expose content');

my @valid_edge = (
    '<0>Oct  9 00:00:00 single h: ALERT',
    '<9>Feb 29 11:11:11 host app: possible in leap year',
    '<191>Dec 31 23:59:59 host app: HELLO',
    '<11>1 - - - - - -',
    '<20>1 2024-02-29T23:59:59+02:30 host app 001 id [x@1 a="escaped\\]bracket" b="quoted\\"x" c="slash\\\\ok"] text',
    '<22>1 2026-10-21T08:30:04Z host app id ID [first@1 a="a"][second@1 b="b"]',
    '<5>1 2026-10-21T08:30:04.123456Z host app id ID - MESSAGE',
    '<4>1 2026-10-21T08:30:04Z host app id ID [id a="literal\\q"] MESSAGE',
);
($rc, $out) = invoke(join("\n", @valid_edge) . "\n");
is($rc, 0, 'edge-formatted valid records accepted');
like($out, qr/^-\tTOTAL\t8$/m, 'valid edge total');
like($out, qr/^-\tUNKNOWN\t0$/m, 'valid edge count');

($rc, $out, $err) = invoke('');
is($rc, 0, 'empty input is a successful empty snapshot');
like($out, qr/^-\tTOTAL\t0$/m, 'empty snapshot total zero');
($rc, $out) = invoke("<13>Oct 21 08:30:04 host app: \e[31mPRIVATE\e[0m\r\n");
is($rc, 0, 'opaque ANSI MESSAGE and CRLF safely counted');
unlike($out, qr/PRIVATE|\e/, 'control bytes not emitted');

my $many_records = ('<3>Oct 21 08:30:04 host app: sample' . "\n") x 50001;
my @fatal = (
    ['unfinished', '<3>Oct 21 08:30:04 host app: truncated', 'unfinished record'],
    ['blank', "\n", 'blank line'],
    ['middle_blank', "<3>Oct 21 08:30:04 host app: good\n\n", 'middle blank'],
    ['line_too_long', '<3>Oct 21 08:30:04 host app: ' . ('x' x 140000) . "\n", 'line limit'],
    ['many_records', $many_records, 'record limit'],
    ['too_many_bytes', ('x' x (16 * 1024 * 1024 + 1)), 'byte limit'],
);
for my $t (@fatal) {
    my ($name, $body, $why) = @$t;
    my $path = fixture("$name.syslog", $body);
    ($rc, $out, $err) = invoke(undef, '--input', $path);
    is($rc, 3, "$why exits 3");
    is($out, '', "$why emits no partial report");
    like($err, qr/\Asyslog-summary: /, "$why diagnostic is generic");
    unlike($err, qr/host|PRIVATE|truncated|sample/, "$why never discloses input");
}
my $missing = File::Spec->catfile($tmp, 'secret-missing-file');
($rc, $out, $err) = invoke(undef, '--input', $missing);
is($rc, 3, 'missing file is unavailable');
is($out, '', 'missing file no report');
unlike($err, qr/secret-missing-file/, 'path never appears in diagnostics');
($rc, $out) = invoke(undef, '--input', $tmp);
is($rc, 3, 'directory is not accepted');
is($out, '', 'directory no report');
my $symlink = File::Spec->catfile($tmp, 'source-link');
SKIP: {
    skip 'symlinks unavailable on this platform', 2 unless symlink($f, $symlink);
    ($rc, $out) = invoke(undef, '--input', $symlink);
    is($rc, 3, 'symlink refused');
    is($out, '', 'symlink no report');
}

done_testing();
