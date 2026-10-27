package SASD::Freeware::LinuxDistroMatrix;
# SPDX-License-Identifier: MIT
# M8.5.2: pure, bounded evidence/evaluation layer for Linux acceptance.
#
# This module owns NO shell commands, process management, file I/O, or
# containers. It accepts observations collected by an explicit runner and
# generates a small vocabulary of audit-safe outcomes. A matching OS ID is
# evidence of the *reported identity*, not a distribution certification.
use strict;
use warnings;
use Exporter qw(import);
use JSON::PP ();
use SASD::Freeware::LinuxPlatform qw(parse_os_release summarize_os_release);
our @EXPORT_OK = qw(targets offline_snapshot assess_snapshot parse_report_tsv record report_tsv report_jsonl valid_image container_command);

my @TARGETS = qw(debian ubuntu arch almalinux rocky);
my %TARGET  = map { $_ => 1 } @TARGETS;
my %OFFLINE = (
    debian    => "ID=debian\nVERSION_ID=12\n",
    ubuntu    => "ID=ubuntu\nID_LIKE=debian\nVERSION_ID=24.04\n",
    arch      => "ID=arch\n",
    almalinux => "ID=almalinux\nID_LIKE=\"rhel centos fedora\"\nVERSION_ID=9.5\n",
    rocky     => "ID=rocky\nID_LIKE=\"rhel centos fedora\"\nVERSION_ID=9.5\n",
);

sub targets { return @TARGETS; }
sub offline_snapshot {
    my ($target) = @_;
    _target($target);
    # Return a scalar copy; callers cannot mutate our fixture registry.
    return $OFFLINE{$target};
}
sub _target {
    my ($value) = @_;
    defined($value) && !ref($value) && $TARGET{$value // ''}
        or die "invalid matrix target\n";
    return $value;
}

# Exactly one seven-column data row, following the documented M8.5.1 header.
# Never extract a matching substring from a larger or potentially hostile
# subprocess response: reject extra lines, escape sequences and malformed IDs.
sub parse_report_tsv {
    my ($data) = @_;
    defined($data) && !ref($data) && length($data) <= 4096
        or die "invalid platform-report output size\n";
    my $header = "SOURCE\tID\tID_LIKE\tVERSION_ID\tFAMILY\tEVIDENCE\tVERSION_MODE";
    my @lines = split /\n/, $data, -1;
    @lines == 3 && $lines[0] eq $header && $lines[2] eq ''
        or die "invalid platform-report framing\n";
    my @row = split /\t/, $lines[1], -1;
    @row == 7 or die "invalid platform-report column count\n";
    my ($source, $id, $like, $version, $family, $evidence, $mode) = @row;
    $source =~ /\A(?:ETC|USR_LIB)\z/ &&
    $id =~ /\A[a-z0-9._-]+\z/ &&
    $like =~ /\A(?:-|[a-z0-9._-]+(?: [a-z0-9._-]+)*)\z/ &&
    $version =~ /\A(?:-|[A-Za-z0-9._+-]+)\z/ &&
    $family =~ /\A(?:debian|arch|rhel|suse|alpine|unknown)\z/ &&
    $evidence =~ /\A(?:ID|ID_LIKE|UNKNOWN)\z/ &&
    $mode =~ /\A(?:VERSIONED|ROLLING|UNKNOWN)\z/
        or die "invalid platform-report values\n";
    # Cross-check semantic invariants to prevent a forged row from claiming
    # an ID-based match for an unrelated family. Do not trust mere shape.
    my $fields = { ID => $id };
    $fields->{VERSION_ID} = $version unless $version eq '-';
    $fields->{ID_LIKE} = $like unless $like eq '-';
    my $expected = summarize_os_release($fields, $source);
    join("\t", @$expected) eq $lines[1]
        or die "inconsistent platform-report classification\n";
    return $expected;
}

# Only an EXACT distribution ID can satisfy a target. ID_LIKE carries lineage
# hints; accepting it as target identity would falsely certify derivatives.
sub assess_snapshot {
    my ($target, $snapshot, $source) = @_;
    _target($target);
    defined($source) && $source =~ /\A(?:ETC|USR_LIB|INPUT)\z/
        or die "invalid matrix source\n";
    my $row = summarize_os_release(parse_os_release($snapshot), $source);
    return record(
        target => $target, mode => $source eq 'INPUT' ? 'OFFLINE' : 'HOST',
        status => $row->[1] eq $target ? 'PASS' : 'FAIL',
        observed_id => $row->[1], family => $row->[4],
        evidence => $row->[5],
        reason => $row->[1] eq $target ? 'ID_MATCH' : 'ID_MISMATCH',
    );
}
sub valid_image {
    my ($ref) = @_;
    return defined($ref) && !ref($ref) && length($ref) <= 240 &&
           $ref =~ /\A[a-zA-Z0-9][a-zA-Z0-9._:\/-]*\@sha256:[0-9a-f]{64}\z/ &&
           $ref !~ m{(?:\A|/)\.\.?/} && $ref !~ m{//};
}

# No unbounded or arbitrary strings can appear in the public report. The
# reason vocabulary makes missing prerequisites distinguishable from failures.
sub record {
    my (%input) = @_;
    _target($input{target});
    for my $item ([mode => qr/\A(?:OFFLINE|HOST|CONTAINER)\z/],
                  [status => qr/\A(?:PASS|FAIL|SKIP)\z/],
                  [observed_id => qr/\A(?:-|[a-z0-9._-]+)\z/],
                  [family => qr/\A(?:-|debian|arch|rhel|suse|alpine|unknown)\z/],
                  [evidence => qr/\A(?:-|ID|ID_LIKE|UNKNOWN)\z/],
                  [reason => qr/\A(?:ID_MATCH|ID_MISMATCH|NOT_THIS_HOST|NOT_CONFIGURED|MISSING_PERL|ENGINE_UNAVAILABLE|ENGINE_FAILED|TIMEOUT|INVALID_OUTPUT|HOST_UNAVAILABLE)\z/]) {
        my ($key,$regex) = @$item;
        defined($input{$key}) && !ref($input{$key}) && $input{$key} =~ $regex
            or die "invalid matrix record $key\n";
    }
    # A SKIP or FAIL cannot claim a positive match. Conversely PASS must be
    # accompanied by exact-ID evidence. This is an audit-report invariant.
    if ($input{status} eq 'PASS') {
        $input{observed_id} eq $input{target} && $input{reason} eq 'ID_MATCH'
            or die "inconsistent positive matrix result\n";
    } elsif ($input{status} eq 'FAIL') {
        $input{reason} ne 'ID_MATCH' or die "inconsistent failed matrix result\n";
    } elsif ($input{status} eq 'SKIP') {
        $input{reason} ne 'ID_MATCH' && $input{reason} ne 'ID_MISMATCH'
            or die "inconsistent skipped matrix result\n";
    }
    return { map { $_ => $input{$_} } qw(target mode status observed_id family evidence reason) };
}
sub report_tsv {
    my (@rows) = @_;
    my $text = "TARGET\tMODE\tSTATUS\tOBSERVED_ID\tFAMILY\tEVIDENCE\tREASON\n";
    for my $r (@rows) {
        ref($r) eq 'HASH' or die "invalid matrix row\n";
        my $valid = record(%$r);
        $text .= join("\t", map { $valid->{$_} } qw(target mode status observed_id family evidence reason)) . "\n";
    }
    return $text;
}
sub report_jsonl {
    my (@rows) = @_;
    my $json = JSON::PP->new->canonical->ascii;
    return join '', map {
        ref($_) eq 'HASH' or die "invalid matrix row\n";
        $json->encode({ schema => 'sasd.distro-matrix.v1', %{record(%$_)} }) . "\n";
    } @rows;
}
# Assemble argv in a *pure* function so CI can verify isolation invariants
# without requiring Docker/Podman or contacting their privileged daemons.
# Only caller-validated absolute executable paths may be used.
sub container_command {
    my ($timeout, $engine, $repo, $image) = @_;
    for my $path ($timeout, $engine, $repo) {
        defined($path) && !ref($path) && $path =~ m{\A/[A-Za-z0-9_. /-]+\z} &&
            $path !~ m{(?:\A|/)\.\.?/|//} or die "invalid container path\n";
    }
    valid_image($image) or die "invalid container image\n";
    return (
        $timeout, '--kill-after=2s', '30s', $engine, 'run', '--rm',
        '--pull=never', '--network=none', '--read-only',
        '--cap-drop=ALL', '--security-opt=no-new-privileges',
        '--pids-limit=128', '--memory=512m', '--user=65534:65534',
        '--volume', "$repo:/workspace:ro", '--workdir=/workspace',
        # Override the image's ENTRYPOINT: its own wrapper must not turn a
        # smoke check into an unrelated custom command.
        '--entrypoint=/bin/sh', $image, '-c',
        'command -v perl >/dev/null 2>&1 || exit 77; exec perl /workspace/bin/linux-platform-report',
    );
}

1;
