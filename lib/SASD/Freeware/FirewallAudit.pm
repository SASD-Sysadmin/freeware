package SASD::Freeware::FirewallAudit;
# SPDX-License-Identifier: MIT
# M8.4 – Read-only, format-aware multi-platform firewall snapshot interpretation.
#
# This module NEVER opens files, invokes system utilities, or changes firewall
# rules. The CLI selects a trusted acquisition adapter and bounds the input;
# this module converts *one complete snapshot* into a portable, intentionally
# conservative inventory of observed chains/rule counts or UFW status.
#
# We deliberately do not normalize UFW/iptables/nftables into a single
# 'firewall is active' assertion. UFW is a management frontend, nftables can
# represent the iptables-nft backend, and access restrictions can hide rules.
# Each output row carries both its SOURCE and its SCOPE. No rule contents,
# addresses, interfaces or potentially sensitive strings are disclosed.
use strict;
use warnings;
use JSON::PP ();
use Exporter qw(import);
our @EXPORT_OK = qw(parse_snapshot);

my $MAX_BYTES = 8 * 1024 * 1024;
my $MAX_ITEMS = 16_384;
my $MAX_LINE = 128 * 1024;

sub parse_snapshot {
    my ($data, $source) = @_;
    defined($data) && !ref($data) && length($data) <= $MAX_BYTES &&
        defined($source) && $source =~ /\A(?:ufw-status|ufw-config|nft-json|iptables-save|ip6tables-save|pf-info|pf-rules|ipfw-list|npf-show|solaris-pf-service|solaris-pf-rules|solaris-ipf-service|solaris-ipf-rules4|solaris-ipf-rules6|firewalld-state|firewalld-active-zones|firewalld-runtime-zones|firewalld-permanent-zones)\z/
        or die "invalid firewall parser arguments\n";
    # Reject binary/control framing before interpreting even the first row.
    # CRLF is accepted for exported fixtures; isolated CR is not.
    $data !~ /\x00|\r(?!\n)|[\x01-\x08\x0b\x0c\x0e-\x1f\x7f]/
        or die "invalid firewall snapshot framing\n";
    # BSD adapters are pure format parsers isolated in their own module.
    # Dispatch only after the common framing, size, and source whitelist
    # checks so Linux and BSD share the same safety boundary.
    if ($source =~ /\A(?:pf-info|pf-rules|ipfw-list|npf-show)\z/) {
        require SASD::Freeware::FirewallBSD;
        return SASD::Freeware::FirewallBSD::parse_bsd_snapshot($data, $source);
    }
    # Solaris has a distinct SMF control plane and an IPFilter grammar.
    # Keep its parser separate, even though its later PF resembles BSD PF.
    if ($source =~ /\Asolaris-(?:pf|ipf)-/) {
        require SASD::Freeware::FirewallSolaris;
        return SASD::Freeware::FirewallSolaris::parse_solaris_snapshot($data, $source);
    }
    # firewalld is a Linux management daemon, not an extra independent set
    # of nftables/iptables kernel rules. Dispatch to a pure control-plane
    # parser and never aggregate its counts with kernel rule snapshots.
    if ($source =~ /\Afirewalld-/) {
        require SASD::Freeware::FirewallFirewalld;
        return SASD::Freeware::FirewallFirewalld::parse_firewalld_snapshot($data, $source);
    }
    if ($source eq 'nft-json') { return _nft($data); }
    if ($source =~ /\A(?:ip6?tables-save)\z/) { return _iptables($data, $source); }
    if ($source eq 'ufw-status') { return _ufw_status($data); }
    return _ufw_config($data);
}

sub _row {
    my (@fields) = @_;
    @fields == 8 or die "invalid firewall row\n";
    # Every displayed field is composed by us, not copied from a free-form
    # rule expression. This check is defense in depth against TSV injection.
    for my $field (@fields) {
        defined($field) && !ref($field) && length($field) <= 128 &&
            $field !~ /[\x00-\x1f\x7f]/ or die "unsafe firewall output field\n";
    }
    return \@fields;
}

sub _token {
    my ($value) = @_;
    return defined($value) && !ref($value) && $value =~ /\A[A-Za-z0-9_.:-]{1,64}\z/;
}

sub _nft {
    my ($text) = @_;
    # nft --json list ruleset emits an object containing an nftables array.
    # JSON::PP is core Perl; it lets us validate structure without a new
    # external dependency. We never evaluate expressions from the ruleset.
    my $json = JSON::PP->new->utf8->max_depth(48);
    my $top = eval { $json->decode($text) };
    !$@ && ref($top) eq 'HASH' && keys(%$top) == 1 &&
        ref($top->{nftables}) eq 'ARRAY'
        or die "invalid nft JSON envelope\n";
    my $items = $top->{nftables};
    @$items <= $MAX_ITEMS or die "nft record limit exceeded\n";
    my (%tables, %chains, %counts);
    my $seen_meta = 0;
    for my $entry (@$items) {
        ref($entry) eq 'HASH' && keys(%$entry) == 1
            or die "invalid nft record\n";
        my ($kind) = keys %$entry;
        my $value = $entry->{$kind};
        ref($value) eq 'HASH' or die "invalid nft record payload\n";
        if ($kind eq 'metainfo') {
            $seen_meta++ == 0 or die "duplicate nft metadata\n";
            next;
        }
        # Some nft versions list additional typed objects (sets, flowtables,
        # maps...). They are not evidence of an active filter chain. Accept
        # only known wrappers; the rules within them are NOT invented.
        if ($kind =~ /\A(?:set|map|element|counter|quota|limit|flowtable|ct helper|ct timeout|ct expectation|synproxy|secmark|objref)\z/) {
            next;
        }
        $kind =~ /\A(?:table|chain|rule)\z/ or die "unsupported nft object kind\n";
        my ($family, $table) = @{$value}{qw(family table)};
        if ($kind eq 'table') { $table = $value->{name}; }
        _token($family) && $family =~ /\A(?:ip|ip6|inet|arp|bridge|netdev)\z/ &&
            _token($table) or die "invalid nft family/table\n";
        my $tk = "$family\0$table";
        if ($kind eq 'table') {
            !$tables{$tk}++ or die "duplicate nft table\n";
            next;
        }
        my $name = $kind eq 'chain' ? $value->{name} : $value->{chain};
        _token($name) or die "invalid nft chain name\n";
        my $ck = "$tk\0$name";
        if ($kind eq 'chain') {
            !exists($chains{$ck}) or die "duplicate nft chain\n";
            my $hook = $value->{hook};
            my $policy = $value->{policy};
            my $has_hook = defined $hook;
            if ($has_hook) {
                _token($hook) or die "invalid nft hook\n";
                defined($value->{type}) && _token($value->{type})
                    or die "invalid nft base-chain type\n";
                defined($policy) && !ref($policy) && $policy =~ /\A(?:accept|drop)\z/
                    or die "unsupported nft base-chain policy\n";
            } else {
                !defined($policy) or die "regular nft chain with policy\n";
                $policy = '-';
            }
            $chains{$ck} = [$family, $table, $name, $policy];
        } else {
            # A ruleset may contain complex expressions and references. We
            # count each rule object exactly once, but do not inspect its
            # contents or claim that an accept/drop expression is effective.
            ref($value->{expr}) eq 'ARRAY' or die "malformed nft rule expression\n";
            $counts{$ck}++;
            $counts{$ck} <= $MAX_ITEMS or die "nft rule limit exceeded\n";
        }
    }
    # nft dumps normally contain table/chain definitions. Verify all
    # references, regardless of their order, before returning any inventory.
    for my $ck (keys %chains) {
        my ($family, $table) = split /\0/, $ck;
        exists($tables{"$family\0$table"}) or die "orphan nft chain\n";
    }
    for my $ck (keys %counts) {
        exists($chains{$ck}) or die "orphan nft rule\n";
    }
    my @rows;
    for my $tk (sort keys %tables) {
        my ($family, $table) = split /\0/, $tk;
        my @in_table = sort grep { /^\Q$tk\E\0/ } keys %chains;
        if (!@in_table) {
            push @rows, _row('nftables', 'runtime', 'OBSERVED', $family, $table, '-', '-', '0');
        }
        for my $ck (@in_table) {
            my (undef, undef, $name, $policy) = @{$chains{$ck}};
            push @rows, _row('nftables', 'runtime', 'OBSERVED', $family, $table, $name, $policy, $counts{$ck} // 0);
        }
    }
    push @rows, _row('nftables', 'runtime', 'OBSERVED', '-', '-', '-', '-', '0') unless @rows;
    return \@rows;
}

sub _iptables {
    my ($text, $source) = @_;
    # A successful iptables-save/ip6tables-save dump consists of zero or
    # more *table ... COMMIT sections. Each chain declaration carries a
    # policy, and each -A line adds exactly one rule to a declared chain.
    # We intentionally do not execute or parse individual rule arguments.
    $text =~ /\n\z/ or die "unterminated iptables-save snapshot\n";
    my ($engine, $family) = $source eq 'iptables-save'
        ? ('iptables', 'inet') : ('ip6tables', 'inet6');
    my (%all, $table, %chains, %counts, $count);
    $count = 0;
    my @rows;
    for my $line (split /\n/, $text) {
        $line =~ s/\r\z//;
        length($line) <= $MAX_LINE or die "oversized iptables-save line\n";
        next if $line eq '' || $line =~ /\A#/;
        $count++ < $MAX_ITEMS or die "iptables-save record limit exceeded\n";
        if ($line =~ /\A\*([A-Za-z0-9_-]{1,64})\z/) {
            !defined($table) && !$all{$1}++ or die "reopened iptables table\n";
            $table = $1;
            %chains = (); %counts = ();
        } elsif ($line =~ /\ACOMMIT\z/) {
            defined($table) or die "iptables COMMIT without table\n";
            for my $chain (sort keys %chains) {
                push @rows, _row($engine, 'runtime', 'OBSERVED', $family,
                                  $table, $chain, $chains{$chain}, $counts{$chain} // 0);
            }
            $table = undef;
        } elsif ($line =~ /\A:([A-Za-z0-9_-]{1,64})\s+(ACCEPT|DROP|RETURN|QUEUE|-)\s+\[(\d+):(\d+)\]\z/) {
            defined($table) && !exists($chains{$1}) or die "invalid iptables chain declaration\n";
            $chains{$1} = $2;
        } elsif ($line =~ /\A(?:\[\d+:\d+\]\s+)?-A\s+([A-Za-z0-9_-]{1,64})\s+(.+)\z/) {
            defined($table) && exists($chains{$1}) or die "iptables rule without declared chain\n";
            length($2) <= $MAX_LINE && $2 !~ /[\x00-\x1f\x7f]/
                or die "invalid iptables rule payload\n";
            ++$counts{$1} <= $MAX_ITEMS or die "iptables rule count exceeded\n";
        } else {
            die "unsupported iptables-save line\n";
        }
    }
    !defined($table) or die "unterminated iptables table\n";
    # Empty output can be legitimate when no tables are loaded; it does not
    # demonstrate that a host has no packet filtering or other backends.
    push @rows, _row($engine, 'runtime', 'OBSERVED', $family, '-', '-', '-', 0) unless @rows;
    return \@rows;
}

sub _ufw_config {
    my ($text) = @_;
    # /etc/ufw/ufw.conf records boot-time configuration, NOT kernel state.
    # We parse only the unique, explicit ENABLED assignment and ignore
    # comments/known ancillary settings such as LOGLEVEL. Never execute a
    # configuration file as a shell script or interpolate its contents.
    $text =~ /\n\z/ or die "unterminated UFW configuration\n";
    my ($enabled, $lines);
    $lines = 0;
    for my $line (split /\n/, $text) {
        $line =~ s/\r\z//;
        length($line) <= $MAX_LINE or die "oversized UFW configuration line\n";
        ++$lines <= $MAX_ITEMS or die "UFW config line limit exceeded\n";
        next if $line =~ /\A\s*(?:#.*)?\z/;
        if ($line =~ /\A\s*ENABLED\s*=\s*(yes|no)\s*(?:#.*)?\z/i) {
            !defined($enabled) or die "duplicate UFW ENABLED setting\n";
            $enabled = lc($1) eq 'yes' ? 'ENABLED' : 'DISABLED';
        } elsif ($line =~ /\A\s*LOGLEVEL\s*=\s*[A-Za-z0-9_-]{1,32}\s*(?:#.*)?\z/) {
            next;
        } else {
            die "unsupported UFW configuration line\n";
        }
    }
    defined($enabled) or die "missing UFW ENABLED setting\n";
    return [_row('ufw', 'configuration', $enabled, '-', '-', '-', '-', '-')];
}

sub _ufw_status {
    my ($text) = @_;
    # `ufw status verbose` reports the UFW frontend's current status. It is
    # not evidence that other Netfilter, nftables, container or VPN rules are
    # absent. We count displayed UFW rules, not kernel hooks or rule objects.
    $text =~ /\n\z/ or die "unterminated UFW status\n";
    my @lines = split /\n/, $text;
    @lines <= $MAX_ITEMS or die "UFW status line limit exceeded\n";
    my $state;
    my $in_rules = 0;
    my $separator = 0;
    my $count = 0;
    my $seen_table = 0;
    for my $line (@lines) {
        $line =~ s/\r\z//;
        length($line) <= $MAX_LINE or die "oversized UFW status line\n";
        next if $line =~ /\A\s*\z/;
        if (!defined($state)) {
            $line =~ /\AStatus: (active|inactive)\z/i or die "invalid UFW status header\n";
            $state = uc($1);
            next;
        }
        $state eq 'ACTIVE' or die "inactive UFW status has unexpected payload\n";
        if (!$in_rules) {
            if ($line =~ /\A(?:Logging|Default|New profiles):\s+[^\x00-\x1f]+\z/) {
                next;
            }
            if ($line =~ /\ATo\s{2,}Action\s{2,}From\s*\z/) {
                !$seen_table++ or die "duplicate UFW rule table\n";
                $in_rules = 1;
                next;
            }
            die "unsupported UFW verbose status line\n";
        }
        if (!$separator) {
            $line =~ /\A-+(?:\s+-+){2}\s*\z/ or die "missing UFW header separator\n";
            $separator = 1;
            next;
        }
        # Free-form endpoint values are untrusted. Only the well-known UFW
        # action column is interpreted; no hostnames/IPs reach output.
        my @parts = split /\s{2,}/, $line;
        @parts == 3 && length($parts[0]) && length($parts[2]) &&
            $parts[1] =~ /\A(?:ALLOW|DENY|REJECT|LIMIT)(?:\s+(?:IN|OUT|FWD))?\z/
            or die "malformed UFW rule summary\n";
        ++$count <= $MAX_ITEMS or die "UFW rule limit exceeded\n";
    }
    defined($state) or die "missing UFW status\n";
    !$in_rules || $separator or die "incomplete UFW status table\n";
    return [_row('ufw', 'runtime', $state, '-', '-', '-', '-', $count)];
}

1;
