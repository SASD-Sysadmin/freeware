package SASD::Freeware::FirewallBSD;
# SPDX-License-Identifier: MIT
# M8.4.2 – Portable, pure parsers for BSD packet-filter snapshots.
#
# Deliberately separate from the Linux-oriented FirewallAudit module:
# the various BSD firewalls have different status concepts, rule grammars,
# command-line conventions, and visibility limits. Mixing them into one
# regex-driven, platform-agnostic "firewall active" test would be dangerous.
#
# This module only accepts bounded textual snapshots. It never invokes a
# command, opens a device, reads configuration files, or modifies a firewall.
# In particular, a ruleset LISTING is not proof of enabled filtering and a
# disabled frontend does not prove the host has no other packet filter.
#
# Row contract shared with M8.4.1:
# ENGINE, SCOPE, STATE, FAMILY, TABLE, CHAIN, POLICY, RULES.
# No source text, IP address, interface, anchor name or rule expression is
# copied into the output. A PARTIAL count is not a whole-host rule count.
use strict;
use warnings;
use Exporter qw(import);
our @EXPORT_OK = qw(parse_bsd_snapshot);

my $MAX_BYTES = 8 * 1024 * 1024;
my $MAX_LINE = 128 * 1024;
my $MAX_LINES = 16_384;

sub parse_bsd_snapshot {
    my ($text, $source) = @_;
    defined($text) && !ref($text) && length($text) <= $MAX_BYTES &&
        defined($source) && !ref($source) &&
        $source =~ /\A(?:pf-info|pf-rules|ipfw-list|npf-show)\z/
        or die "invalid BSD firewall parser arguments\n";

    # Reject incomplete snapshots and framing tricks *before* interpreting
    # anything. Native commands can return partial stdout on failure; the CLI
    # additionally checks their exit status before calling this function.
    $text =~ /\n\z/ or die "unterminated BSD firewall snapshot\n";
    $text !~ /\x00|\r(?!\n)|[\x01-\x08\x0b\x0c\x0e-\x1f\x7f]/
        or die "invalid BSD firewall snapshot framing\n";
    my @lines = split /\n/, $text;
    @lines <= $MAX_LINES or die "BSD firewall record limit exceeded\n";
    for (@lines) {
        s/\r\z//;
        length($_) <= $MAX_LINE or die "oversized BSD firewall snapshot line\n";
    }
    return _pf_info(\@lines)  if $source eq 'pf-info';
    return _pf_rules(\@lines) if $source eq 'pf-rules';
    return _ipfw(\@lines)     if $source eq 'ipfw-list';
    return _npf(\@lines);
}

sub _row {
    my (@fields) = @_;
    @fields == 8 or die "invalid BSD firewall output row\n";
    # All fields are locally constructed constant tokens or bounded counts.
    # Keeping this check here (rather than relying on the CLI) also protects
    # callers that import the parser as a Perl library.
    for my $field (@fields) {
        defined($field) && !ref($field) && length($field) <= 128 &&
            $field !~ /[\x00-\x1f\x7f]/
            or die "unsafe BSD firewall output field\n";
    }
    return \@fields;
}

sub _pf_info {
    my ($lines) = @_;
    # `pfctl -s info`: OpenBSD/FreeBSD ordinarily begin with
    #   Status: Enabled for ...  Debug: ...
    # or `Status: Disabled`. Do not infer status from an existing ruleset.
    my @present = grep { /\S/ } @$lines;
    @present && $present[0] =~ /\AStatus:\s*(Enabled|Disabled)(?:\s+.*)?\z/i
        or die "unrecognized PF status header\n";
    my $state = uc($1) eq 'ENABLED' ? 'ACTIVE' : 'INACTIVE';
    for my $idx (1 .. $#present) {
        $present[$idx] !~ /\AStatus:\s*/i
            or die "duplicate PF status header\n";
    }
    return [_row('pf', 'runtime', $state, '-', '-', '-', '-', '-')];
}

sub _pf_rules {
    my ($lines) = @_;
    # `pfctl -s rules` prints the MAIN filter ruleset. Anchors can contain
    # further rules and are not expanded by this operation; NAT, tables,
    # interface skips and rules of other filters are not included. We mark
    # this summary PARTIAL even for an empty listing. Parsing arbitrary PF
    # expressions is purposely out of scope; count only recognized statements
    # and reject unexpected framing instead of silently skipping it.
    my ($filter, $anchors) = (0, 0);
    for my $line (@$lines) {
        next if $line =~ /\A\s*\z/;
        if ($line =~ /\A\s*anchor\s+\S.*\z/) {
            ++$anchors;
        } elsif ($line =~ /\A\s*(?:pass|block|match)(?:\s+.*)?\z/) {
            ++$filter;
        } else {
            # A changed pfctl format is UNKNOWN, not an incomplete success.
            die "unsupported PF rules listing line\n";
        }
    }
    return [
        _row('pf', 'runtime', 'PARTIAL', '-', 'main', 'filter', '-', $filter),
        _row('pf', 'runtime', 'PARTIAL', '-', 'main', 'anchors', '-', $anchors),
    ];
}

sub _ipfw {
    my ($lines) = @_;
    # FreeBSD `ipfw list` (without -a, -t, or -d) gives one static rule per
    # numbered line. Duplicate rule numbers can be legitimate, so count
    # LINES, not distinct IDs. The `65535` default rule is included. We do
    # not parse action-specific parameters and never claim that IPFW's
    # kernel hook is active merely because numbered rules are listed.
    # Dynamic states, disabled sets, NAT objects, and forwarding policy are
    # outside this summary; report PARTIAL even for an empty listing.
    my $count = 0;
    for my $line (@$lines) {
        next if $line =~ /\A\s*\z/;
        $line =~ /\A(\d{1,5})\s+\S.*\z/ && $1 <= 65535
            or die "unsupported IPFW rule listing line\n";
        ++$count;
    }
    return [_row('ipfw', 'runtime', 'PARTIAL', '-', '-', 'static', '-', $count)];
}

sub _npf {
    my ($lines) = @_;
    # NetBSD npfctl show has emitted at least two status-header dialects:
    #   # filtering: active        # config: loaded
    # and historical `Filtering: active` / `Configuration: loaded`.
    # NPF start/stop and load/reload are independent. This is why we ALWAYS
    # emit two rows instead of combining 'active' and 'loaded' into one.
    # The remaining show text is not a stable machine-readable grammar:
    # we intentionally don't claim any authoritative rule count. Runtime
    # dynamic rules and multiline expressions may not be fully visible.
    my @present = grep { /\S/ } @$lines;
    @present >= 2 or die "incomplete NPF show headers\n";
    my ($first, $second) = @present[0,1];
    my ($state, $config);
    if ($first =~ /\A#\s*filtering:\s*(active|inactive)\s*\z/i) {
        $state = uc($1);
        $second =~ /\A#\s*config:\s*(loaded|empty)\s*\z/i
            or die "invalid NPF configuration header\n";
        $config = uc($1);
    } elsif ($first =~ /\AFiltering:\s*(active|inactive)\s*\z/i) {
        $state = uc($1);
        $second =~ /\AConfiguration:\s*(loaded|empty)\s*\z/i
            or die "invalid legacy NPF configuration header\n";
        $config = uc($1);
    } else {
        die "unrecognized NPF filtering header\n";
    }
    for my $idx (2 .. $#present) {
        # A second header could be an accidentally concatenated snapshot.
        $present[$idx] !~ /\A(?:#\s*)?(?:(?:filtering|config|configuration):)\s*/i
            or die "duplicate NPF status header\n";
    }
    if ($config eq 'EMPTY') {
        # A successfully read empty NPF configuration normally has no rule
        # descriptions. Do not accept an internally inconsistent snapshot.
        for my $idx (2 .. $#present) {
            $present[$idx] !~ /\A\s*(?:pass|block|group|map|procedure|table)\b/i
                or die "NPF empty configuration contains rules\n";
        }
    }
    return [
        _row('npf', 'runtime', $state, '-', '-', '-', '-', '-'),
        _row('npf', 'configuration', $config, '-', '-', '-', '-', '-'),
    ];
}

1;
