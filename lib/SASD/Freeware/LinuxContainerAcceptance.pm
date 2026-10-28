package SASD::Freeware::LinuxContainerAcceptance;
# SPDX-License-Identifier: MIT
# M8.5.3: pure validation, execution planning and evidence formatting.
#
# Security/architecture boundaries:
# * This library NEVER executes commands, opens files or contacts a daemon.
# * A caller supplies trusted absolute paths and pre-cached pinned images.
# * Every container argv is constructed from fixed security flags and a
#   constant shell program; no user-provided bytes are shell-interpolated.
# * The container is NOT a real-host firewall / kernel / MAC-system test.
use strict;
use warnings;
use Exporter qw(import);
use JSON::PP ();
use SASD::Freeware::LinuxDistroMatrix qw(valid_image parse_report_tsv targets);
our @EXPORT_OK = qw(stages container_argv assess_identity evidence report_tsv report_jsonl);

my @STAGES = qw(IDENTITY TOOLCHAIN TEST INSTALL SMOKE);
my %STAGE = map { $_ => 1 } @STAGES;
my %TARGET = map { $_ => 1 } targets();

sub stages { return @STAGES; }

# These fixed shell scripts are passed as one argv element to /bin/sh -c.
# They contain NO image names, host paths or other user-controlled strings.
# All installation artifacts remain in container-local /tmp; the repository
# mount is read-only and no privileged host paths are mounted.
my %SCRIPT = (
    IDENTITY => 'command -v perl >/dev/null 2>&1 || exit 77; exec perl /workspace/bin/linux-platform-report',
    TOOLCHAIN => 'for tool in perl make prove bash git mktemp; do command -v "$tool" >/dev/null 2>&1 || exit 77; done',
    TEST => 'make test >/dev/null 2>&1',
    INSTALL => join(' ',
        'set -eu;',
        'stage="$(mktemp -d /tmp/sasd-m853.XXXXXXXX)";',
        'make install DESTDIR="$stage" PREFIX=/usr/freeware >/dev/null 2>&1;',
        'test -x "$stage/usr/freeware/bin/linux-distro-matrix";',
        'test -x "$stage/usr/freeware/bin/linux-platform-report";',
        'test -f "$stage/usr/freeware/.sasd-freeware-install.tsv";',
        'make uninstall DESTDIR="$stage" PREFIX=/usr/freeware >/dev/null 2>&1;',
        'test ! -e "$stage/usr/freeware/bin/linux-distro-matrix";',
        'test ! -e "$stage/usr/freeware/.sasd-freeware-install.tsv"',
    ),
    SMOKE => join(' ',
        'perl bin/linux-distro-matrix --mode offline --require-complete >/dev/null 2>&1 &&',
        'perl bin/linux-platform-report >/dev/null 2>&1 &&',
        'perl bin/firewall-config-audit --help >/dev/null 2>&1 &&',
        'perl bin/network-route-report --help >/dev/null 2>&1',
    ),
);

sub _valid_abs_path {
    my ($path) = @_;
    # Docker's -v parser treats ':' specially. Reject punctuation that could
    # change the mount grammar, terminal control bytes, dot and empty parts.
    return defined($path) && !ref($path) && length($path) <= 1024 &&
           $path =~ m{\A/[A-Za-z0-9._ /-]+\z} &&
           $path !~ m{//|(?:\A|/)\.{1,2}(?:/|\z)} && $path ne '/';
}

sub container_argv {
    my ($timeout, $engine, $repo, $image, $stage) = @_;
    _valid_abs_path($_) or die "invalid container argv path\n"
        for ($timeout, $engine, $repo);
    valid_image($image) or die "invalid image reference\n";
    defined($stage) && $STAGE{$stage} or die "invalid container stage\n";
    return (
        $timeout, '--kill-after=5s', '300s',
        $engine, 'run', '--rm', '--pull=never', '--network=none',
        '--read-only', '--cap-drop=ALL',
        '--security-opt=no-new-privileges', '--pids-limit=128',
        '--memory=1024m', '--user=65534:65534',
        '--tmpfs=/tmp:rw,nosuid,nodev,size=512m,mode=1777',
        '--volume', "$repo:/workspace:ro", '--workdir=/workspace',
        '--entrypoint=/bin/sh', $image, '-c', $SCRIPT{$stage},
    );
}

sub evidence {
    my (%r) = @_;
    for my $field (qw(target stage mode status reason)) {
        defined($r{$field}) && !ref($r{$field})
            or die "missing container evidence field $field\n";
    }
    $TARGET{$r{target}} or die "invalid evidence target\n";
    $STAGE{$r{stage}} or die "invalid evidence stage\n";
    $r{mode} =~ /\A(?:PLAN|CONTAINER)\z/ or die "invalid evidence mode\n";
    $r{status} =~ /\A(?:PASS|FAIL|SKIP)\z/ or die "invalid evidence status\n";
    $r{reason} =~ /\A(?:ID_MATCH|ID_MISMATCH|CHECK_OK|CHECK_FAILED|NOT_EXECUTED|NOT_CONFIGURED|ENGINE_UNAVAILABLE|IMAGE_UNAVAILABLE|MISSING_DEPENDENCY|PRIOR_STAGE_FAILED|TIMEOUT|INVALID_OUTPUT)\z/
        or die "invalid evidence reason\n";
    if ($r{status} eq 'PASS') {
        ($r{reason} eq 'ID_MATCH' && $r{stage} eq 'IDENTITY') ||
        ($r{reason} eq 'CHECK_OK' && $r{stage} ne 'IDENTITY')
            or die "invalid positive evidence\n";
        $r{mode} eq 'CONTAINER' or die "plan cannot pass\n";
    } elsif ($r{status} eq 'SKIP') {
        $r{reason} =~ /\A(?:NOT_EXECUTED|NOT_CONFIGURED|IMAGE_UNAVAILABLE|MISSING_DEPENDENCY|PRIOR_STAGE_FAILED)\z/
            or die "invalid skipped evidence\n";
    } else {
        $r{reason} =~ /\A(?:ID_MISMATCH|CHECK_FAILED|ENGINE_UNAVAILABLE|TIMEOUT|INVALID_OUTPUT)\z/
            or die "invalid failed evidence\n";
    }
    return { map { $_ => $r{$_} } qw(target stage mode status reason) };
}

sub assess_identity {
    my ($target, $output) = @_;
    $TARGET{$target} or die "invalid identity target\n";
    my $observed = eval { parse_report_tsv($output) };
    return evidence(target=>$target, stage=>'IDENTITY', mode=>'CONTAINER',
        status=>'FAIL', reason=>'INVALID_OUTPUT') unless $observed;
    my $same = $observed->[1] eq $target;
    return evidence(target=>$target, stage=>'IDENTITY', mode=>'CONTAINER',
        status=>$same ? 'PASS' : 'FAIL', reason=>$same ? 'ID_MATCH' : 'ID_MISMATCH');
}

sub report_tsv {
    my (@rows) = @_;
    return "TARGET\tSTAGE\tMODE\tSTATUS\tREASON\n" . join '', map {
        my $r = evidence(%$_);
        join("\t", map { $r->{$_} } qw(target stage mode status reason)) . "\n";
    } @rows;
}
sub report_jsonl {
    my (@rows) = @_;
    my $json = JSON::PP->new->canonical->ascii;
    return join '', map {
        $json->encode({ schema=>'sasd.container-acceptance.v1', %{evidence(%$_)} }) . "\n";
    } @rows;
}
1;
