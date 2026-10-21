#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M7.1 offline, deterministic positive/negative tests; never reads host logs.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $program = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'journal-summary');
my $tmp = tempdir('sasd-journal-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);

sub fixture {
    my ($name, $body) = @_;
    my $path = File::Spec->catfile($tmp, $name);
    open my $out, '>', $path or die "cannot create fixture: $!";
    binmode($out);
    print {$out} $body or die "cannot write fixture: $!";
    close $out or die "cannot close fixture: $!";
    return $path;
}

sub invoke {
    my ($input, @argv) = @_;
    # Lists of arguments bypass a shell; tests intentionally include private
    # strings and control characters that must never be echoed by the tool.
    my $err = gensym();
    my $pid = open3(my $in, my $out, $err, $^X, $program, @argv);
    binmode($in);
    print {$in} $input if defined($input) && length($input);
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

my ($rc, $out, $err) = invoke(undef, '--help');
is($rc, 0, '--help returns zero');
like($out, qr/\AUsage: journal-summary /, '--help shows usage');
is($err, '', '--help never emits diagnostics');
($rc, $out, $err) = invoke(undef, '--version');
is($rc, 0, '--version returns zero');
is($out, "journal-summary 0.1.0\n", '--version stable');
is($err, '', '--version has no diagnostics');
for my $args (['--invalid'], ['--input'], ['unexpected'], ['--input', '']) {
    ($rc, $out) = invoke(undef, @$args);
    is($rc, 2, 'invalid invocation returns 2');
    is($out, '', 'invalid invocation never prints success-shaped report');
}

my $valid = join('', map { qq({"PRIORITY":"$_","MESSAGE":"private-token-42","SYSLOG_IDENTIFIER":"internal-host"}\n) } 0..7);
my $good = fixture('good.jsonl', $valid);
($rc, $out, $err) = invoke(undef, '--input', $good);
is($rc, 0, 'eight valid priorities produce success');
like($out, qr/\APRIORITY\tLEVEL\tCOUNT\n/, 'TSV schema begins with header');
like($out, qr/^0\tEMERGENCY\t1$/m, 'emergency count correct');
like($out, qr/^3\tERROR\t1$/m, 'error count correct');
like($out, qr/^7\tDEBUG\t1$/m, 'debug count correct');
like($out, qr/^-\tTOTAL\t8$/m, 'total count correct');
like($out, qr/^-\tUNKNOWN\t0$/m, 'no unknown priorities');
unlike($out, qr/private-token-42|internal-host/, 'message and syslog identifier never disclosed');
is($err, '', 'valid input has no diagnostics');

($rc, $out) = invoke(undef, '--input', $good, '--null');
is($rc, 0, 'NUL report preserves success');
ok($out =~ /\0\z/, 'NUL output terminated');
my @fields = split /\0/, $out, -1;
pop @fields;
is(scalar(@fields), 30, 'ten records with three fields each');
is(join('|', @fields[0..2]), '0|EMERGENCY|1', 'first NUL row correct');
is(join('|', @fields[-3..-1]), '-|TOTAL|8', 'last NUL row correct');
unlike($out, qr/private-token-42/, 'NUL mode never discloses MESSAGE');

($rc, $out) = invoke($valid, '--input', '-');
is($rc, 0, 'stdin input works without native journalctl');
like($out, qr/^-\tTOTAL\t8$/m, 'stdin summary correct');
($rc, $out) = invoke('', '--input', '-');
is($rc, 0, 'empty stdin is a valid empty snapshot');
like($out, qr/^-\tTOTAL\t0$/m, 'empty snapshot reported explicitly');

my $untrusted = join('',
    qq({"PRIORITY":3,"MESSAGE":"sensitive"}\n),
    qq({"PRIORITY":null,"MESSAGE":"no-value-secret"}\n),
    qq({"MESSAGE":"no-priority-secret"}\n),
    qq({"PRIORITY":"08","MESSAGE":"bad-priority-secret"}\n),
    qq({"PRIORITY":["2","4"],"MESSAGE":"array-secret"}\n),
    qq({"PRIORITY":true,"MESSAGE":"bool-secret"}\n),
    qq({"PRIORITY":"7","MESSAGE":"tail-secret"}\n),
);
($rc, $out, $err) = invoke($untrusted);
is($rc, 1, 'invalid, absent and complex priority values return findings');
like($out, qr/^3\tERROR\t1$/m, 'JSON numeric priority 3 accepted');
like($out, qr/^7\tDEBUG\t1$/m, 'JSON string priority 7 accepted');
like($out, qr/^-\tUNKNOWN\t5$/m, 'unknown priority categories counted');
like($out, qr/^-\tTOTAL\t7$/m, 'complete record total retained');
unlike($out, qr/(?:sensitive|secret)/, 'private values not emitted in anomaly case');
is($err, '', 'unknown priorities are not parser errors');

my $cases = [
    ['truncated.jsonl', qq({"PRIORITY":"3"}), 'incomplete final record'],
    ['invalid.jsonl', qq({"PRIORITY":"3",}\n), 'broken JSON syntax'],
    ['array.jsonl', qq([{"PRIORITY":"3"}]\n), 'non-object record'],
    ['blank.jsonl', "\n", 'blank journal line'],
    ['mixed.jsonl', qq({"PRIORITY":"1"}\nnot-json\n), 'malformed second record'],
    ['oversize.jsonl', qq({"PRIORITY":"3","MESSAGE":") . ('x' x 132000) . qq("}\n), 'oversized record'],
    ['excessive.jsonl', (qq({"PRIORITY":"3"}\n) x 50001), 'too many records'],
    ['deep.jsonl', '{"PRIORITY":' . ('[' x 20) . '1' . (']' x 20) . "}\n", 'excessive JSON nesting'],
];
for my $case (@$cases) {
    my ($name, $body, $description) = @$case;
    my $path = fixture($name, $body);
    ($rc, $out, $err) = invoke(undef, '--input', $path);
    is($rc, 3, "$description returns prerequisite/parse error 3");
    is($out, '', "$description does not publish partial aggregates");
    like($err, qr/\Ajournal-summary: /, "$description returns generic diagnostic");
    unlike($err, qr/PRIORITY|not-json|sensitive|private-token-42/, "$description does not echo source data");
}
my $huge = fixture('huge.jsonl', (qq({"PRIORITY":"3"}\n) x 1200000));
($rc, $out) = invoke(undef, '--input', $huge);
is($rc, 3, 'input byte ceiling is enforced');
is($out, '', 'too-large input does not publish partial report');

my $missing = File::Spec->catfile($tmp, 'not-exists.jsonl');
($rc, $out) = invoke(undef, '--input', $missing);
is($rc, 3, 'missing input rejected');
is($out, '', 'missing input no report');
my $link = File::Spec->catfile($tmp, 'link.jsonl');
SKIP: {
    skip 'symlinks unavailable', 2 unless symlink($good, $link);
    ($rc, $out) = invoke(undef, '--input', $link);
    is($rc, 3, 'symlink input refused');
    is($out, '', 'symlink input no report');
}

# Do not trust field contents even when they carry ANSI terminal controls.
my $control = qq({"PRIORITY":"4","MESSAGE":"\\u001b[31mSECRET\\u001b[0m"}\n);
($rc, $out) = invoke($control);
is($rc, 0, 'control characters within valid JSON strings are not an error');
unlike($out, qr/SECRET|\e/, 'terminal controls cannot escape through aggregate output');

done_testing();
