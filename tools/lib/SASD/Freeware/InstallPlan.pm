package SASD::Freeware::InstallPlan;
# SPDX-License-Identifier: MIT
#
# Maintainer-only writer for a human-readable installation transaction map.
# This is crash *evidence*, not an executable undo journal: without a durable
# commit protocol the installer must never replay plan rows automatically.
#
# The plan is published BEFORE the first old file moves from the live prefix.
# It maps the installer index used by old-N/new-N to a validated relative path
# and SHA-256 digest. All records are data, never shell commands or absolute
# paths. A human must still verify filesystem and manifest state independently.
use strict;
use warnings;
use Exporter qw(import);
use Fcntl qw(:DEFAULT);

our @EXPORT_OK = qw(write_install_plan);
my $MAGIC = "# sasd-freeware-transaction-plan-v1\n";

sub _rows {
    my ($kind, $entries) = @_;
    ref($entries) eq 'ARRAY' && @$entries <= 10000
        or die "installation: invalid internal plan entries\n";
    my @lines;
    my %seen;
    for my $index (0 .. $#$entries) {
        my $row = $entries->[$index];
        ref($row) eq 'ARRAY' && @$row == 2
            or die "installation: invalid internal plan row\n";
        my ($relative, $hash) = @$row;
        # A stricter pathname rule lives in installation.pl. Reinforcing its
        # printable ASCII and no-dot-components contract prevents malformed
        # data from becoming an ambiguous operator instruction later.
        defined($relative) && $relative =~ m{\A[a-zA-Z0-9][a-zA-Z0-9_./-]*\z} &&
            $relative !~ m{(?:\A|/)\.{1,2}(?:/|\z)|//} &&
            defined($hash) && $hash =~ /\A[0-9a-f]{64}\z/ &&
            !$seen{$relative}++
            or die "installation: invalid internal plan pathname or digest\n";
        push @lines, join("\t", $kind, $index + 1, $relative, $hash) . "\n";
    }
    return @lines;
}

sub write_install_plan {
    my (%args) = @_;
    my $transaction = $args{transaction};
    defined($transaction) && $transaction =~ m{\A/} &&
        $transaction !~ /[\x00-\x1f\x7f]/
        or die "installation: invalid internal transaction path\n";

    # Validate the entire plan BEFORE creating the file, rather than writing
    # a partially validated artifact. Each group is independently numbered:
    # OLD index 1 means old-1; NEW index 1 means new-1.
    my @old = _rows('OLD', $args{old});
    my @new = _rows('NEW', $args{new});
    my $tmp = "$transaction/plan.tmp";
    my $final = "$transaction/plan.tsv";
    # Never overwrite an existing plan, including a dangling symlink.
    !-e $final && !-l $final
        or die "installation: transaction plan already exists\n";
    sysopen(my $out, $tmp, O_WRONLY | O_CREAT | O_EXCL, 0600)
        or die "installation: cannot stage transaction plan: $!\n";
    binmode $out;
    print {$out} $MAGIC, @old, @new
        or die "installation: cannot write transaction plan: $!\n";
    close($out) or die "installation: cannot close transaction plan: $!\n";

    # Within one transaction directory rename() presents either a complete
    # plan or no plan to readers. This is NOT an fsync-based power-loss
    # durability guarantee; crash consistency remains a manual release gate.
    rename($tmp, $final)
        or die "installation: cannot publish transaction plan: $!\n";
    return $final;
}

1;
