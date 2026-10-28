#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M8.5.3 unit/contract tests. All tests are offline: NO Docker, Podman,
# network activity, image pulls or host firewall commands are invoked.
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use FindBin;
use lib "$FindBin::Bin/../lib";
use SASD::Freeware::LinuxContainerAcceptance qw(
    stages container_argv assess_identity evidence report_tsv report_jsonl
);

my $cli = "$FindBin::Bin/../bin/linux-container-acceptance";
my $sha = ('a' x 64);
my $image = "docker.io/library/debian\@sha256:$sha";
my @steps = stages();
is_deeply(\@steps, [qw(IDENTITY TOOLCHAIN TEST INSTALL SMOKE)], 'stable acceptance steps');

for my $step (@steps) {
    my @argv = container_argv('/usr/bin/timeout', '/usr/bin/docker',
        '/home/example/SASD', $image, $step);
    is($argv[0], '/usr/bin/timeout', "$step uses explicit timeout executable");
    ok(grep($_ eq '--pull=never', @argv), "$step cannot auto-pull");
    ok(grep($_ eq '--network=none', @argv), "$step has no network");
    ok(grep($_ eq '--read-only', @argv), "$step has read-only root");
    ok(grep($_ eq '--cap-drop=ALL', @argv), "$step drops capabilities");
    ok(grep($_ eq '--security-opt=no-new-privileges', @argv), "$step no-new-privileges");
    ok(grep($_ eq '--user=65534:65534', @argv), "$step unprivileged identity");
    ok(grep($_ eq '/home/example/SASD:/workspace:ro', @argv), "$step uses read-only source mount");
    ok(grep($_ eq '--entrypoint=/bin/sh', @argv), "$step overrides image entrypoint");
    ok(grep($_ eq '--rm', @argv), "$step asks engine to remove container");
    ok(!grep(/\A--privileged\z|\A--publish(?:=|\z)|\A--net=host\z|label:disable/, @argv),
        "$step never disables isolation or exposes a service");
    is($argv[-2], '-c', "$step runs fixed shell text as one argv entry");
    unlike($argv[-1], qr{\Q$image\E|\Q/home/example/SASD\E}, "$step has no input interpolated into shell");
}

for my $bad (
    [ '/usr/bin/timeout', '/usr/bin/docker', '/home/foo:bar', $image, 'TEST' ],
    [ '/usr/bin/timeout', '/usr/bin/docker', '/home/a,b', $image, 'TEST' ],
    [ '/usr/bin/timeout', '/usr/bin/docker', '/home/../etc', $image, 'TEST' ],
    [ '/usr/bin/timeout', '/usr/bin/docker', '/home/foo\nX', $image, 'TEST' ],
    [ 'timeout', '/usr/bin/docker', '/home/foo', $image, 'TEST' ],
    [ '/usr/bin/timeout', '/usr/bin/docker', '/home/foo', 'debian:12', 'TEST' ],
    [ '/usr/bin/timeout', '/usr/bin/docker', '/home/foo', $image, 'EVAL' ],
) {
    ok(!eval { container_argv(@$bad); 1 }, 'invalid path, image or stage is rejected');
}

my $header = "SOURCE\tID\tID_LIKE\tVERSION_ID\tFAMILY\tEVIDENCE\tVERSION_MODE\n";
my $debian = $header . "ETC\tdebian\t-\t12\tdebian\tID\tVERSIONED\n";
my $ubuntu = $header . "ETC\tubuntu\tdebian\t24.04\tdebian\tID\tVERSIONED\n";
my $pass = assess_identity('debian', $debian);
is($pass->{status}, 'PASS', 'exact distribution ID yields PASS');
is($pass->{reason}, 'ID_MATCH', 'positive ID evidence is explicit');
my $fail = assess_identity('debian', $ubuntu);
is($fail->{status}, 'FAIL', 'ID_LIKE cannot masquerade as exact ID');
is($fail->{reason}, 'ID_MISMATCH', 'mismatch explicitly retained');
is(assess_identity('debian', $debian . "EXTRA\n")->{reason},
    'INVALID_OUTPUT', 'extra output rejected');
is(assess_identity('debian', '')->{reason}, 'INVALID_OUTPUT', 'empty output rejected');

my $skip = evidence(target=>'arch', stage=>'TEST', mode=>'PLAN',
    status=>'SKIP', reason=>'NOT_EXECUTED');
is($skip->{status}, 'SKIP', 'planning is a skipped, unexecuted test');
like(report_tsv($pass, $skip), qr/^TARGET\tSTAGE\tMODE\tSTATUS\tREASON\n/,
    'TSV has stable header');
my @json = split /\n/, report_jsonl($pass, $skip);
is(scalar @json, 2, 'JSONL has one object per evidence row');
is(JSON::PP::decode_json($json[0])->{schema}, 'sasd.container-acceptance.v1',
    'JSONL schema is versioned');
is(JSON::PP::decode_json($json[1])->{status}, 'SKIP',
    'JSONL preserves non-executed evidence');
for my $invalid (
    { %$pass, mode=>'PLAN' },
    { %$pass, status=>'SKIP' },
    { %$pass, status=>'PASS', reason=>'CHECK_FAILED' },
    { %$pass, target=>'freebsd' },
    { %$pass, stage=>'HACK' },
    { %$pass, reason=>"ID_MATCH\tINJECTED" },
    { %$skip, status=>'PASS' },
) {
    ok(!eval { evidence(%$invalid); 1 }, 'inconsistent/injected evidence rejected');
}

# CLI commands below never use --run. The default plan MUST remain inert.
sub run_cli {
    my (@args) = @_;
    my $pid = open(my $pipe, '-|');
    defined($pid) or die "cannot fork CLI: $!";
    if (!$pid) {
        open STDERR, '>', '/dev/null';
        exec { $^X } $^X, $cli, @args;
        exit 127;
    }
    local $/;
    my $output = <$pipe> // '';
    close $pipe;
    return ($? >> 8, $output);
}
my ($rc, $output) = run_cli();
is($rc, 0, 'default plan returns zero without daemon');
my @lines = split /\n/, $output;
is(scalar @lines, 26, 'plan has 25 rows plus header');
is(scalar(grep { /\tPLAN\tSKIP\tNOT_EXECUTED\z/ } @lines), 25,
    'all five distributions and five stages are SKIP in plan');
($rc, $output) = run_cli('--target', 'debian', '--format', 'jsonl');
is($rc, 0, 'selected target JSONL plan returns success');
my @report = map { JSON::PP::decode_json($_) } split /\n/, $output;
is(scalar(@report), 5, 'selected target emits exactly five stages');
is($report[0]{target}, 'debian', 'requested target retained');
is($report[0]{status}, 'SKIP', 'JSONL never presents PLAN as PASS');
($rc, $output) = run_cli('--require-complete');
is($rc, 4, 'required complete plan exits incomplete');
($rc, $output) = run_cli('--run', '--engine', 'docker', '--target', 'rocky');
is($rc, 0, 'not-configured run emits skips without engine contact');
like($output, qr/rocky\tIDENTITY\tCONTAINER\tSKIP\tNOT_CONFIGURED/, 'run without image is not counted as PASS');
($rc, $output) = run_cli('--run', '--engine', 'docker', '--target', 'rocky', '--require-complete');
is($rc, 4, 'require-complete rejects missing image');
for my $args (
    [ '--run' ],
    [ '--run', '--engine', 'invalid' ],
    [ '--target', 'freebsd' ],
    [ '--target', 'debian', '--target', 'debian' ],
    [ '--format', 'xml' ],
    [ '--image', 'debian=debian:12' ],
    [ '--image', 'debian=debian:12', '--run' ],
    [ '--image', 'badtarget=' . $image ],
) {
    ($rc, $output) = run_cli(@$args);
    is($rc, 2, 'invalid option rejected before daemon contact');
}
($rc, $output) = run_cli('--help');
is($rc, 0, '--help works');
like($output, qr/--run/, '--help explicitly distinguishes opt-in execution');
($rc, $output) = run_cli('--version');
is($rc, 0, '--version works');
like($output, qr/0\.1\.0/, 'version is stable');

done_testing();
