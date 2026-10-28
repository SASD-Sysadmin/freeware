package SASD::Freeware::LinuxContainerEvidence;
# SPDX-License-Identifier: MIT
# M8.5.3a: pure, offline evaluation of M8.5.3 container acceptance evidence.
#
# This module NEVER starts a container, reads files, contacts registries or
# trusts a prose log line as a positive result. The CLI owns file acquisition;
# this module deals only with bounded JSON Lines documents and typed records.
#
# Its goal is deliberately narrow: detect incomplete, contradictory or
# duplicate evidence and make missing distributions conspicuously visible.
# Evidence is NOT cryptographic attestation of the image, host or Git commit.
use strict;
use warnings;
use Exporter qw(import);
use JSON::PP ();
use SASD::Freeware::LinuxDistroMatrix qw(targets);
use SASD::Freeware::LinuxContainerAcceptance qw(stages evidence);
our @EXPORT_OK = qw(parse_batch summarize_batches summary_tsv summary_jsonl);

my @TARGETS = targets();
my @STAGES = stages();
my %TARGET = map { $_ => 1 } @TARGETS;
my %STAGE = map { $_ => 1 } @STAGES;
my %EXPECTED = map { $_ => 1 } qw(schema target stage mode status reason);
my $SCHEMA = 'sasd.container-acceptance.v1';
my $SUMMARY_SCHEMA = 'sasd.container-evidence.v1';

sub parse_batch {
    my ($text) = @_;
    # Each M8.5.3 run emits five very small JSON objects for one target.
    # Tight bounds defend automation against accidentally supplied large logs.
    defined($text) && !ref($text) && length($text) <= 32 * 1024 &&
        $text =~ /\n\z/ && $text !~ /[\x00-\x08\x0b-\x1f\x7f]/
        or die "invalid evidence framing\n";
    my @lines = split /\n/, $text, -1;
    pop @lines; # The required final newline leaves one empty terminator.
    @lines == @STAGES or die "expected exactly five evidence rows\n";

    my ($target, $mode);
    my %rows;
    for my $line (@lines) {
        length($line) > 0 && length($line) <= 4096
            or die "invalid evidence line length\n";
        my $raw = eval { JSON::PP::decode_json($line) };
        ref($raw) eq 'HASH' or die "invalid evidence JSON object\n";
        # The M8.5.3 reporter emits canonical JSON::PP ASCII objects. A
        # canonical byte-for-byte comparison rejects duplicate JSON keys,
        # ambiguous whitespace and escape tricks without a second parser.
        # Arbitrary third-party JSON is intentionally not an input contract.
        JSON::PP->new->canonical->ascii->encode($raw) eq $line
            or die "noncanonical or duplicate-key evidence\n";
        keys(%$raw) == keys(%EXPECTED) or die "unexpected evidence fields\n";
        for my $key (keys %EXPECTED) {
            exists $raw->{$key} or die "missing evidence field\n";
        }
        $raw->{schema} eq $SCHEMA or die "unsupported evidence schema\n";
        my $row = evidence(map { $_ => $raw->{$_} }
            qw(target stage mode status reason));
        $target //= $row->{target};
        $mode //= $row->{mode};
        $row->{target} eq $target && $row->{mode} eq $mode
            or die "mixed target or execution mode\n";
        !$rows{$row->{stage}} or die "duplicate evidence stage\n";
        $rows{$row->{stage}} = $row;
    }
    for my $stage (@STAGES) {
        exists($rows{$stage}) or die "missing evidence stage\n";
    }

    # A planning report may never be upgraded to a pass or treated as a
    # container run merely because five records are present.
    if ($mode eq 'PLAN') {
        for my $stage (@STAGES) {
            my $r = $rows{$stage};
            $r->{status} eq 'SKIP' && $r->{reason} eq 'NOT_EXECUTED'
                or die "inconsistent plan evidence\n";
        }
    } else {
        # A uniform preflight outcome occurs before any image is executed.
        # This includes a missing image, missing engine or missing image arg.
        my $first = $rows{IDENTITY};
        my %preflight = (
            NOT_CONFIGURED    => 'SKIP',
            IMAGE_UNAVAILABLE => 'SKIP',
            ENGINE_UNAVAILABLE => 'FAIL',
        );
        if (exists $preflight{$first->{reason}}) {
            for my $stage (@STAGES) {
                my $r = $rows{$stage};
                $r->{status} eq $preflight{$first->{reason}} &&
                $r->{reason} eq $first->{reason}
                    or die "inconsistent preflight evidence\n";
            }
        } elsif ($first->{status} ne 'PASS') {
            # If identity was not confirmed, later checks cannot be credited.
            for my $stage (qw(TOOLCHAIN TEST INSTALL SMOKE)) {
                $rows{$stage}{status} eq 'SKIP' &&
                $rows{$stage}{reason} eq 'PRIOR_STAGE_FAILED'
                    or die "missing identity gate\n";
            }
        } elsif ($rows{TOOLCHAIN}{status} ne 'PASS') {
            for my $stage (qw(TEST INSTALL SMOKE)) {
                $rows{$stage}{status} eq 'SKIP' &&
                $rows{$stage}{reason} eq 'PRIOR_STAGE_FAILED'
                    or die "missing toolchain gate\n";
            }
        }
    }
    return { target => $target, mode => $mode, rows => \%rows };
}

sub summarize_batches {
    my (@batches) = @_;
    my %by_target;
    for my $batch (@batches) {
        ref($batch) eq 'HASH' && $TARGET{$batch->{target} // ''}
            or die "invalid evidence batch\n";
        exists($batch->{rows}) && ref($batch->{rows}) eq 'HASH'
            or die "missing batch rows\n";
        !exists($by_target{$batch->{target}})
            or die "duplicate target evidence\n";
        # Verify that callers haven't modified a parsed batch in memory.
        for my $stage (@STAGES) {
            my $row = $batch->{rows}{$stage};
            ref($row) eq 'HASH' or die "invalid batch row\n";
            evidence(%$row);
            $row->{target} eq $batch->{target} &&
            $row->{mode} eq $batch->{mode} && $row->{stage} eq $stage
                or die "inconsistent batch identity\n";
        }
        $by_target{$batch->{target}} = $batch;
    }
    my @summaries;
    for my $target (@TARGETS) {
        if (!exists $by_target{$target}) {
            push @summaries, {
                target=>$target, mode=>'NONE', status=>'SKIP',
                pass=>0, fail=>0, skip=>5, reason=>'NO_REPORT',
            };
            next;
        }
        my $batch = $by_target{$target};
        my %count = (PASS=>0, FAIL=>0, SKIP=>0);
        $count{$batch->{rows}{$_}{status}}++ for @STAGES;
        my $status = $count{FAIL} ? 'FAIL' : $count{SKIP} ? 'SKIP' : 'PASS';
        push @summaries, {
            target=>$target, mode=>$batch->{mode}, status=>$status,
            pass=>$count{PASS}, fail=>$count{FAIL}, skip=>$count{SKIP},
            reason=>$status eq 'PASS' ? 'ALL_STAGES_PASS' :
                $status eq 'FAIL' ? 'STAGE_FAILED' : 'INCOMPLETE',
        };
    }
    return @summaries;
}

sub _summary {
    my ($r) = @_;
    ref($r) eq 'HASH' or die "invalid summary\n";
    $TARGET{$r->{target} // ''} &&
    ($r->{mode} // '') =~ /\A(?:NONE|PLAN|CONTAINER)\z/ &&
    ($r->{status} // '') =~ /\A(?:PASS|FAIL|SKIP)\z/ &&
    ($r->{reason} // '') =~ /\A(?:ALL_STAGES_PASS|STAGE_FAILED|INCOMPLETE|NO_REPORT)\z/
        or die "invalid summary fields\n";
    for my $key (qw(pass fail skip)) {
        defined($r->{$key}) && $r->{$key} =~ /\A[0-5]\z/
            or die "invalid summary count\n";
    }
    $r->{pass} + $r->{fail} + $r->{skip} == 5
        or die "incomplete summary total\n";
    if ($r->{status} eq 'PASS') {
        $r->{mode} eq 'CONTAINER' && $r->{pass} == 5 &&
        $r->{reason} eq 'ALL_STAGES_PASS'
            or die "unverified positive summary\n";
    } elsif ($r->{status} eq 'FAIL') {
        $r->{fail} > 0 && $r->{reason} eq 'STAGE_FAILED'
            or die "inconsistent failure summary\n";
    } else {
        $r->{fail} == 0 && $r->{skip} > 0 &&
        ($r->{reason} eq 'INCOMPLETE' || $r->{reason} eq 'NO_REPORT')
            or die "inconsistent skipped summary\n";
    }
    return $r;
}

sub summary_tsv {
    my (@rows) = @_;
    return "TARGET\tMODE\tSTATUS\tPASS\tFAIL\tSKIP\tREASON\n" .
        join '', map {
            my $r = _summary($_);
            join("\t", map { $r->{$_} } qw(target mode status pass fail skip reason)) . "\n";
        } @rows;
}

sub summary_jsonl {
    my (@rows) = @_;
    my $json = JSON::PP->new->canonical->ascii;
    return join '', map {
        my $r = _summary($_);
        $json->encode({ schema=>$SUMMARY_SCHEMA, %$r }) . "\n";
    } @rows;
}
1;
