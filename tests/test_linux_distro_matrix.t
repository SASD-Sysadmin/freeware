#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M8.5.2 hermetic acceptance-framework tests. No container daemon or network.
# All negative cases use synthetic data; native-host smoke tests run in SKIP
# mode on unsupported hosts rather than claiming a foreign distro passed.
use strict;
use warnings;
use Test::More;
use FindBin;
use JSON::PP ();
use File::Spec ();
use lib "$FindBin::Bin/../lib";
use SASD::Freeware::LinuxDistroMatrix qw(
    targets offline_snapshot assess_snapshot parse_report_tsv record
    report_tsv report_jsonl valid_image container_command
);
my $cli = "$FindBin::Bin/../bin/linux-distro-matrix";
my @expected = qw(debian ubuntu arch almalinux rocky);
my @targets = targets();
is_deeply(\@targets, \@expected, 'stable five-target order');

# These five are *fixtures*, not actual distro compatibility evidence.
my %families = (debian => 'debian', ubuntu => 'debian', arch => 'arch',
                almalinux => 'rhel', rocky => 'rhel');
for my $target (@targets) {
    my $snap = offline_snapshot($target);
    like($snap, qr/\bID=$target\b/, "$target fixture identifies itself");
    my $pass = assess_snapshot($target, $snap, 'INPUT');
    is($pass->{status}, 'PASS', "$target offline match");
    is($pass->{mode}, 'OFFLINE', "$target offline provenance");
    is($pass->{family}, $families{$target}, "$target expected family");
    is($pass->{reason}, 'ID_MATCH', "$target exact identity match");
    ok(!eval { assess_snapshot('not-distro', $snap, 'INPUT'); 1 },
       "$target fixture rejects unknown target");
    my $other = $target eq 'debian' ? 'ubuntu' : 'debian';
    is(assess_snapshot($other, $snap, 'INPUT')->{status}, 'FAIL',
       "$target cannot masquerade as $other");
}

my $ubuntu = offline_snapshot('ubuntu');
my $different = assess_snapshot('debian', $ubuntu, 'INPUT');
is($different->{status}, 'FAIL', 'ID_LIKE cannot falsely certify Debian');
is($different->{observed_id}, 'ubuntu', 'wrong ID preserved as evidence');
like($ubuntu, qr/ID_LIKE=debian/, 'fixture captures parent distribution only');

for my $bad (
    "ID=debian\n\$(touch /tmp/malicious)\n", "ID=debian\x00\n",
    "ID=debian\nexport X=1\n", "ID=debian\nID=evil\\\n",
) {
    ok(!eval { assess_snapshot('debian', $bad, 'INPUT'); 1 },
       'hostile os-release input rejected without execution');
}

my $header = "SOURCE\tID\tID_LIKE\tVERSION_ID\tFAMILY\tEVIDENCE\tVERSION_MODE\n";
my $good = $header . "ETC\tdebian\t-\t12\tdebian\tID\tVERSIONED\n";
my $row = parse_report_tsv($good);
is($row->[1], 'debian', 'strict output parser: correct ID');
is($row->[4], 'debian', 'strict output parser: correct family');
for my $bad (
    '', $good . "TRAILER\n", $header, $header . "debian\n",
    $header . "ETC\tdebian\t-\t12\tdebian\tID\tVERSIONED\tEXTRA\n",
    $header . "ETC\tdebian\t-\t12\trhel\tID\tVERSIONED\n",
    $header . "ETC\tubuntu\tdebian\t24.04\tdebian\tID_LIKE\tVERSIONED\n",
    $header . "ETC\tdebian\t-\t12\tdebian\tID\tROLLING\n",
    $header . "ETC\tdebian\t-\t12\tdebian\tID\tVERSIONED\r\n",
    $header . "ETC\tdebian\t-\t12\tdebian\tID\tVERSIONED\x1b\n",
    'A' x 4097,
) {
    ok(!eval { parse_report_tsv($bad); 1 }, 'rejects malformed or misleading CLI output');
}

for my $bad (
    undef, '', 'almalinux:9', 'docker.io/library/ubuntu:24.04',
    "registry/image\@sha256:" . 'G' x 64,
    "registry/image\@sha256:" . 'a' x 63,
    "../ubuntu\@sha256:" . 'a' x 64,
    "ubuntu/../image\@sha256:" . 'a' x 64,
    "image//name\@sha256:" . 'a' x 64,
    "x\n--privileged\@sha256:" . 'a' x 64,
) {
    ok(!valid_image($bad), 'rejects unpinned or malformed image reference');
}
ok(valid_image('docker.io/library/debian@sha256:' . ('a' x 64)),
   'digest-pinned Docker reference accepted');
ok(valid_image('registry.example.org:5000/ns/rocky@sha256:' . ('0' x 64)),
   'registry port accepted with immutable digest');

my @argv = container_command('/usr/bin/timeout', '/usr/bin/podman',
    '/home/test/repo', 'registry.example.org/test/debian@sha256:' . ('a' x 64));
is($argv[0], '/usr/bin/timeout', 'pure plan uses absolute timeout binary');
ok(grep($_ eq '--pull=never', @argv), 'container plan cannot pull images');
ok(grep($_ eq '--network=none', @argv), 'container has no network');
ok(grep($_ eq '--read-only', @argv), 'container root is read-only');
ok(grep($_ eq '--cap-drop=ALL', @argv), 'all capabilities dropped');
ok(grep($_ eq '--security-opt=no-new-privileges', @argv), 'no-new-privileges enforced');
ok(grep($_ eq '/home/test/repo:/workspace:ro', @argv), 'repository mounted read-only');
ok(grep($_ eq '--entrypoint=/bin/sh', @argv), 'image entrypoint overridden');
ok(!grep($_ eq '--privileged', @argv), 'no privileged mode');
ok(!grep($_ eq '--publish', @argv), 'no exposed ports');
ok(!grep($_ eq '--security-opt=label:disable', @argv), 'SELinux not disabled');
ok(!eval { container_command('/bin/timeout', '/usr/bin/docker',
    '/tmp:unsafe', 'image@sha256:' . ('a' x 64)); 1 },
   'ambiguous colon in repository mount rejected');

my $positive = record(target => 'debian', mode => 'HOST', status => 'PASS',
    observed_id => 'debian', family => 'debian', evidence => 'ID', reason => 'ID_MATCH');
my $skip = record(target => 'ubuntu', mode => 'HOST', status => 'SKIP',
    observed_id => '-', family => '-', evidence => '-', reason => 'NOT_THIS_HOST');
my $failure = record(target => 'rocky', mode => 'CONTAINER', status => 'FAIL',
    observed_id => 'almalinux', family => 'rhel', evidence => 'ID', reason => 'ID_MISMATCH');
like(report_tsv($positive, $skip, $failure), qr/^TARGET\tMODE\tSTATUS/m,
     'TSV report header');
my $output = report_tsv($positive, $skip, $failure);
my @lines = split /\n/, $output;
is(scalar(@lines), 4, 'all statuses retained as separate lines');
like($output, qr/ubuntu\tHOST\tSKIP\t-\t-\t-\tNOT_THIS_HOST/,
     'skip is not silently treated as pass');
like($output, qr/rocky\tCONTAINER\tFAIL\talmalinux\trhel\tID\tID_MISMATCH/,
     'failed image identity is preserved');
my $jsonl = report_jsonl($positive, $skip, $failure);
my @objects = map { JSON::PP::decode_json($_) } split /\n/, $jsonl;
is(scalar(@objects), 3, 'JSONL has one object per record');
is($objects[0]{schema}, 'sasd.distro-matrix.v1', 'stable JSONL schema');
is($objects[2]{status}, 'FAIL', 'JSONL preserves failures');
is($objects[1]{reason}, 'NOT_THIS_HOST', 'JSONL preserves SKIP reason');
for my $invalid (
    { %$positive, observed_id => 'rocky' },
    { %$positive, mode => 'INVENTED' },
    { %$positive, reason => 'ID_MISMATCH' },
    { %$skip, reason => 'ID_MATCH' },
    { %$positive, evidence => "ID\nInjected" },
    { %$positive, target => 'other' },
) {
    ok(!eval { record(%$invalid); 1 }, 'rejects inconsistent or injected evidence record');
}

sub run_cli {
    my (@args) = @_;
    open my $out, '-|', $^X, $cli, @args
        or die "cannot run matrix CLI: $!";
    local $/;
    my $text = <$out> // '';
    close $out;
    return ($? >> 8, $text);
}
my ($rc, $text) = run_cli();
is($rc, 0, 'default offline mode exits successfully');
my @offline_lines = split /\n/, $text;
is(scalar(@offline_lines), 6, 'header plus five offline fixtures');
is(scalar(grep { /\tPASS\t/ } @offline_lines), 5,
   'five PASS records are explicitly tagged OFFLINE');
($rc, $text) = run_cli('--mode', 'offline', '--target', 'rocky', '--format', 'jsonl');
is($rc, 0, 'selected target / JSONL returns successful exit');
my $object = JSON::PP::decode_json($text);
is($object->{target}, 'rocky', 'selected target is honored');
is($object->{mode}, 'OFFLINE', 'JSONL carries OFFLINE provenance');
($rc, $text) = run_cli('--mode', 'host', '--require-complete');
is($rc, 4, 'require-complete treats other-host SKIPs as incomplete acceptance');
($rc, $text) = run_cli('--mode', 'host');
is($rc, 0, 'host probing never changes host settings');
like($text, qr/^TARGET\tMODE\tSTATUS/m, 'host output structured');
my @host_lines = split /\n/, $text;
is(scalar(@host_lines), 6, 'all host target records emitted');
if ($^O ne 'linux') {
    is(scalar(grep { /\tSKIP\t/ } @host_lines), 5,
       'non-Linux has five skips, no false positives');
} else {
    ok(scalar(grep { /\t(?:PASS|SKIP)\t/ } @host_lines) == 5,
       'Linux host has five explicitly classified records');
}
($rc, $text) = run_cli('--mode', 'container', '--engine', 'docker', '--target', 'debian');
is($rc, 0, 'container with no image produces SKIP without engine contact');
like($text, qr/debian\tCONTAINER\tSKIP\t-\t-\t-\tNOT_CONFIGURED/,
     'missing image is explicitly reported');
($rc, $text) = run_cli('--mode', 'container', '--engine', 'docker', '--target', 'debian', '--require-complete');
is($rc, 4, 'require-complete refuses to pass skipped container target');
for my $args (
    ['--mode', 'invalid'], ['--mode', 'container'], ['--engine', 'docker'],
    ['--mode', 'container', '--engine', 'shell'], ['--target', 'invented'],
    ['--target', 'debian', '--target', 'debian'],
    ['--mode', 'container', '--engine', 'docker', '--image', 'debian=ubuntu:latest'],
    ['--format', 'xml'], ['--mode', 'host', '--image', 'debian=anything'],
) {
    # Suppress expected usage diagnostics from invalid argument cases.
    open my $sink, '>', File::Spec->devnull or die $!;
    my $pid = fork();
    defined $pid or die $!;
    if ($pid == 0) {
        open STDERR, '>&', $sink;
        exec $^X, $cli, @$args;
        exit 127;
    }
    waitpid($pid, 0);
    isnt($? >> 8, 0, 'invalid arguments rejected before running any container');
}
done_testing();
