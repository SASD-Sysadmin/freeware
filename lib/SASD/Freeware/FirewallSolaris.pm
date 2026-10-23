package SASD::Freeware::FirewallSolaris;
# SPDX-License-Identifier: MIT
# M8.4.3 – Conservative Oracle Solaris IPFilter/PF read-only adapters.
#
# IMPORTANT: this is a *snapshot parser*, not a security-policy verifier.
# Solaris 10 and Solaris 11.0–11.2 use IPFilter; Solaris 11.3 introduced
# PF alongside IPFilter; Oracle Solaris 11.4 uses PF in place of IPFilter.
# The same machine may expose service status, a loaded ruleset, and actual
# kernel filtering differently. We NEVER collapse these separate sources
# into a single "firewall enabled" answer.
#
# Pure library: this module performs no I/O, privileged operation, kernel
# inspection, shell expansion, or filesystem access. The CLI owns bounded
# native acquisition; the parser validates the *entire* snapshot atomically.
# Any unknown grammar version is an error rather than silent loss of rules.
#
# Output contract: ENGINE SCOPE STATE FAMILY TABLE CHAIN POLICY RULES.
# Values are constructed from constants/validated counts, not user input.
use strict;
use warnings;
use Exporter qw(import);
our @EXPORT_OK = qw(parse_solaris_snapshot);

my $MAX_BYTES = 8 * 1024 * 1024;
my $MAX_LINE  = 128 * 1024;
my $MAX_LINES = 16_384;
my $MAX_RULES = 16_384;

sub parse_solaris_snapshot {
    my ($text, $source) = @_;
    defined($text) && !ref($text) && length($text) <= $MAX_BYTES &&
    defined($source) && !ref($source) &&
    $source =~ /\A(?:solaris-pf-service|solaris-pf-rules|solaris-ipf-service|solaris-ipf-rules4|solaris-ipf-rules6)\z/
        or die "invalid Solaris firewall parser arguments\n";

    # A newline-terminated snapshot is our conservative integrity contract.
    # It cannot prove native output completeness on its own, which is why
    # the CLI also checks the native command's exit code before printing.
    $text =~ /\n\z/ or die "unterminated Solaris firewall snapshot\n";
    $text !~ /\x00|\r(?!\n)|[\x01-\x08\x0b\x0c\x0e-\x1f\x7f]/
        or die "invalid Solaris firewall snapshot framing\n";
    my @lines = split /\n/, $text;
    @lines <= $MAX_LINES or die "Solaris firewall record limit exceeded\n";
    for (@lines) {
        s/\r\z//;
        length($_) <= $MAX_LINE or die "oversized Solaris firewall line\n";
    }

    return _smf(\@lines, 'pf') if $source eq 'solaris-pf-service';
    return _smf(\@lines, 'ipfilter') if $source eq 'solaris-ipf-service';
    return _pf_root(\@lines) if $source eq 'solaris-pf-rules';
    return _ipfilter(\@lines, $source eq 'solaris-ipf-rules6' ? 'inet6' : 'inet');
}

sub _row {
    my (@values) = @_;
    @values == 8 or die "invalid Solaris firewall row\n";
    for my $value (@values) {
        defined($value) && !ref($value) && length($value) <= 128 &&
        $value !~ /[\x00-\x1f\x7f]/
            or die "unsafe Solaris firewall output field\n";
    }
    return \@values;
}

sub _smf {
    my ($lines, $engine) = @_;
    # `svcs -H -o state FMRI` returns ONE state token. Unlike `svcs -x`,
    # it has no localized descriptions, service names, or timestamps.
    # A service can be ONLINE while its loaded rules provide no protection;
    # DEGRADED may mean a fallback or default policy. These are strictly
    # SMF service observations, not PF/IPFilter kernel enablement flags.
    my @nonblank = grep { /\S/ } @$lines;
    @nonblank == 1 or die "invalid Solaris SMF state count\n";
    $nonblank[0] =~ /\A(online|offline|disabled|degraded|maintenance|uninitialized|legacy_run)\z/i
        or die "unsupported Solaris SMF state\n";
    return [_row($engine, 'service', uc($1), '-', '-', '-', '-', '-')];
}

sub _pf_root {
    my ($lines) = @_;
    # Solaris PF `pfctl -sr` displays the ROOT ruleset only. In particular,
    # `pfctl -a '*' -sr` is needed to traverse anchors, so count references
    # separately and ALWAYS mark the root inventory as PARTIAL.
    # Some Oracle outputs include `empty list for firewall(out)` instead
    # of an otherwise blank root. This marker does not prove no active PF.
    my ($filters, $anchors, $empty) = (0, 0, 0);
    my %empty_directions;
    for my $line (@$lines) {
        next if $line =~ /\A\s*\z/;
        if ($line =~ /\Aempty list for firewall\((in|out)\)\z/i) {
            !$empty_directions{lc($1)}++
                or die "duplicate Solaris PF empty-list direction\n";
            ++$empty;
        } elsif ($line =~ /\A\s*anchor\s+\S.*\z/) {
            ++$anchors;
        } elsif ($line =~ /\A\s*(?:pass|block|match)(?:\s+.*)?\z/) {
            ++$filters;
        } else {
            die "unsupported Solaris PF listing line\n";
        }
        $filters + $anchors + $empty <= $MAX_RULES
            or die "Solaris PF record limit exceeded\n";
    }
    # An empty-list marker and visible statements might come from different
    # sections (in/out). Don't infer the missing section's direction.
    $empty <= 2 or die "duplicate Solaris PF empty-list markers\n";
    return [
        _row('pf', 'runtime', 'PARTIAL', '-', 'root', 'filter', '-', $filters),
        _row('pf', 'runtime', 'PARTIAL', '-', 'root', 'anchors', '-', $anchors),
    ];
}

sub _ipfilter {
    my ($lines, $family) = @_;
    # `ipfstat -io` dumps the ACTIVE kernel rule lists for IPv4, while
    # `ipfstat -6io` does the same for IPv6 where supported. Never use
    # the `-I` flag here: it selects an INACTIVE staging ruleset.
    #
    # We recognize only a bounded prefix of IPFilter's grammar, enough
    # to count printed in/out rules without extracting private addresses,
    # interfaces, NAT decisions or policy actions. An unrecognized form
    # is rejected rather than counted or assumed harmless.
    my %counts = (in => 0, out => 0);
    my %empty = (in => 0, out => 0);
    my $seen = 0;
    for my $line (@$lines) {
        next if $line =~ /\A\s*\z/;
        if ($line =~ /\Aempty list for (?:inactive )?ipfilter\((in|out)\)\z/i) {
            my $direction = lc($1);
            # A native "inactive" marker is NOT acceptable for an active
            # ruleset source: it suggests a different command was captured.
            $line !~ /inactive/i or die "inactive IPFilter ruleset supplied\n";
            !$empty{$direction}++ or die "duplicate IPFilter empty list\n";
            $seen++;
            next;
        }
        my $rule = $line;
        # Optional rule numbers appear in some ipfstat dialects. Match only
        # a documented numeric prefix; no expression is evaluated.
        $rule =~ s/\A\@\d{1,10}\s+//;
        $rule =~ /\A(?:pass|block|count|log|auth|preauth|skip|call)\b.*?\s+(in|out)\b(?:\s+.*)?\z/i
            or die "unsupported Solaris IPFilter rule line\n";
        my $direction = lc($1);
        ++$counts{$direction} <= $MAX_RULES or die "IPFilter rule count exceeded\n";
        $seen++ <= $MAX_LINES or die "IPFilter record limit exceeded\n";
    }
    $seen or die "empty or incomplete IPFilter snapshot\n";
    for my $direction (qw(in out)) {
        !$empty{$direction} || !$counts{$direction}
            or die "conflicting IPFilter empty and populated list\n";
    }
    return [
        _row('ipfilter', 'runtime', 'PARTIAL', $family, 'active', 'in', '-', $counts{in}),
        _row('ipfilter', 'runtime', 'PARTIAL', $family, 'active', 'out', '-', $counts{out}),
    ];
}

1;
