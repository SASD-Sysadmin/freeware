package SASD::Freeware::FirewallFirewalld;
# SPDX-License-Identifier: MIT
# M8.4.5 – Pure, deliberately conservative firewalld snapshot adapters.
#
# No filesystem, D-Bus or subprocess access belongs here. firewall-cmd can
# manage the daemon as well as query it, so the CLI must select from an exact
# *read-only* allowlist and hand a complete bounded capture to this module.
# The parser never interprets ports, interfaces, sources, rich-rule matches or
# user-defined comments as packet-filter effectiveness. Those details may be
# sensitive and are never copied into the published summary.
#
# This is a control-plane observation, not a kernel-policy equivalence test:
# firewalld runtime and permanent configuration diverge between reloads;
# nftables/iptables views may represent the very same underlying rules.
use strict;
use warnings;
use Exporter qw(import);
our @EXPORT_OK = qw(parse_firewalld_snapshot);

my $MAX_BYTES = 8 * 1024 * 1024;
my $MAX_LINES = 16_384;
my $MAX_LINE = 128 * 1024;
my $MAX_RICH = 16_384;
my %ALLOWED_FIELD = map { $_ => 1 } (
    'target', 'icmp-block-inversion', 'interfaces', 'sources', 'services',
    'ports', 'protocols', 'forward', 'masquerade', 'forward-ports',
    'source-ports', 'icmp-blocks', 'rich rules', 'helpers',
    'ingress-priority', 'egress-priority',
);

sub _row {
    my (@parts) = @_;
    @parts == 8 or die "invalid firewalld report structure\n";
    for my $value (@parts) {
        defined($value) && !ref($value) && length($value) <= 128 &&
            $value !~ /[\x00-\x1f\x7f]/
            or die "unsafe firewalld report field\n";
    }
    return \@parts;
}

sub _lines {
    my ($text) = @_;
    # Every successful capture is newline-terminated; allowing a missing
    # newline can turn abruptly interrupted native output into false facts.
    $text eq '' || $text =~ /\n\z/ or die "unterminated firewalld snapshot\n";
    $text !~ /\x00|\r(?!\n)|[\x01-\x08\x0b\x0c\x0e-\x1f\x7f]/
        or die "invalid firewalld framing\n";
    my @lines = split /\n/, $text;
    @lines <= $MAX_LINES or die "too many firewalld lines\n";
    for my $line (@lines) {
        $line =~ s/\r\z//;
        length($line) <= $MAX_LINE or die "oversized firewalld line\n";
    }
    return @lines;
}

sub parse_firewalld_snapshot {
    my ($text, $source) = @_;
    defined($text) && !ref($text) && length($text) <= $MAX_BYTES &&
        defined($source) && !ref($source) &&
        $source =~ /\A(?:firewalld-state|firewalld-active-zones|firewalld-runtime-zones|firewalld-permanent-zones)\z/
        or die "invalid firewalld source or capture\n";
    my @lines = _lines($text);
    if ($source eq 'firewalld-state') {
        # firewall-cmd --state prints 'running' on success. When it reports
        # 'not running', the real CLI may exit nonzero; the acquisition layer
        # will then reject it, rather than treating command failure as proof.
        @lines == 1 && $lines[0] =~ /\A(?:running|not running)\z/
            or die "unsupported firewalld daemon state\n";
        my $state = $lines[0] eq 'running' ? 'RUNNING' : 'NOT_RUNNING';
        return [_row('firewalld', 'daemon', $state, '-', '-', '-', '-', '-')];
    }
    if ($source eq 'firewalld-active-zones') {
        return _active_zones(\@lines);
    }
    return _zone_summary(\@lines, $source);
}

sub _active_zones {
    my ($lines) = @_;
    # --get-active-zones lists only zones that have interface/source bindings.
    # A binding is not evidence of a particular kernel verdict. Never emit
    # the interface names or source CIDRs returned by this command.
    my (%names, %seen_field, @order, $current, $bindings);
    for my $line (@$lines) {
        # firewalld documentation formats examples with optional blank
        # separators; ignore them without inventing an empty zone.
        next if $line eq '';
        if ($line =~ /\A([A-Za-z0-9_-]{1,64})\z/) {
            my $name = $1;
            !$names{$name}++ or die "duplicate active firewalld zone\n";
            if (defined($current) && !$bindings) {
                die "active firewalld zone without bindings\n";
            }
            push @order, $name;
            $current = $name;
            $bindings = 0;
            %seen_field = ();
        } elsif ($line =~ /\A  (interfaces|sources):\s+(.+?)\s*\z/) {
            defined($current) or die "orphan firewalld binding\n";
            # Validate the complete nonempty item-list shape, but do not parse
            # potentially sensitive names or addresses; they are discarded.
            my ($kind, $value) = ($1, $2);
            !$seen_field{$kind}++
                or die "duplicate firewalld zone binding field\n";
            $value !~ /\s{2}/ && $value !~ /\A\s|\s\z/
                or die "unsupported firewalld binding list\n";
            ++$bindings;
        } else {
            die "unsupported firewalld active-zones line\n";
        }
    }
    defined($current) && !$bindings and die "active firewalld zone without bindings\n";
    return [_row('firewalld', 'runtime', 'NONE_BOUND', '-', '-', 'zones', '-', '-')]
        unless @order;
    return [map { _row('firewalld', 'runtime', 'BOUND', '-', $_, 'bindings', '-', '-') } sort @order];
}

sub _target {
    my ($raw) = @_;
    $raw =~ s/\A\s+|\s+\z//g;
    return 'DEFAULT' if lc($raw) eq 'default';
    return uc($raw) if $raw =~ /\A(?:ACCEPT|DROP|REJECT)\z/i;
    # Some versions display the symbolic default-zone reject target with
    # percent delimiters. Normalize it to a fixed safe output token.
    return 'REJECT' if $raw =~ /\A%{1,2}REJECT%{1,2}\z/;
    die "unsupported firewalld zone target\n";
}

sub _zone_summary {
    my ($lines, $source) = @_;
    my $scope = $source eq 'firewalld-permanent-zones' ? 'configuration' : 'runtime';
    my (%zones, $current, $field);
    for my $line (@$lines) {
        next if $line eq '';
        if ($line =~ /\A([A-Za-z0-9_-]{1,64})(?: \(active\))?\z/) {
            my $name = $1;
            !$zones{$name} or die "duplicate firewalld zone\n";
            $zones{$name} = {fields => {}, rich => 0};
            $current = $name;
            $field = undef;
            next;
        }
        # The two-space field boundary is part of firewall-cmd's public
        # output format. Unknown field names fail closed rather than being
        # silently interpreted as a familiar configuration schema.
        if ($line =~ /\A  ([a-z][a-z-]*(?: [a-z]+)?):(?: (.*))?\z/) {
            defined($current) or die "orphan firewalld zone attribute\n";
            my ($key, $value) = ($1, defined($2) ? $2 : '');
            $ALLOWED_FIELD{$key} or die "unsupported firewalld zone attribute\n";
            !exists($zones{$current}{fields}{$key})
                or die "duplicate firewalld zone attribute\n";
            $zones{$current}{fields}{$key} = $value;
            $field = $key;
            next;
        }
        if ($line =~ /\A    (.+)\z/) {
            # Save the outer match immediately: the validation regex for the
            # current key below would otherwise replace Perl's $1 capture.
            my $content = $1;
            defined($current) && defined($field) &&
                $field =~ /\A(?:rich rules|forward-ports)\z/
                or die "unexpected firewalld continuation\n";
            $content =~ /\S/ or die "blank firewalld continuation\n";
            if ($field eq 'rich rules') {
                $content =~ /\Arule\s+\S.*\z/ or die "invalid firewalld rich rule\n";
                ++$zones{$current}{rich} <= $MAX_RICH
                    or die "too many firewalld rich rules\n";
            }
            next;
        }
        die "unsupported firewalld zone line\n";
    }
    # Requiring both the target and rich-rule section makes a truncated
    # '--list-all-zones' capture less likely to pass as an empty/full report.
    # Even a complete zone listing is not the full effective kernel policy.
    my @rows;
    for my $name (sort keys %zones) {
        my $item = $zones{$name};
        exists($item->{fields}{target}) && exists($item->{fields}{'rich rules'})
            or die "incomplete firewalld zone listing\n";
        $item->{fields}{'rich rules'} eq ''
            or die "unsupported inline rich rules\n";
        my $target = _target($item->{fields}{target});
        push @rows, _row('firewalld', $scope, 'PARTIAL', '-', $name,
                         'rich-rules', $target, $item->{rich});
    }
    push @rows, _row('firewalld', $scope, 'PARTIAL', '-', '-', 'rich-rules', '-', '0')
        unless @rows;
    return \@rows;
}

1;
