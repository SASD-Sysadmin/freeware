package SASD::Freeware::NetworkInterfaces;
# SPDX-License-Identifier: MIT
# M8.1 – Parse finite, untrusted network-interface snapshots.
#
# This module has NO operating-system side effects: it never runs `ip`,
# `ifconfig`, or network requests. Its only responsibility is to translate
# bounded input text into validated rows. A separate executable chooses the
# local backend, owns file descriptors and serializes the result.
#
# A row contains seven public inventory fields:
#   name, index, state, family, address, prefix, mac
# A placeholder row (family='-') keeps an interface visible even when it has
# no addresses of the requested family. No raw backend text is ever returned.
use strict;
use warnings;
use JSON::PP ();
use Socket qw(AF_INET AF_INET6 inet_pton);
use Exporter qw(import);
our @EXPORT_OK = qw(parse_snapshot);

my $MAX_INTERFACES = 512;
my $MAX_ADDRESSES = 4096;
my $MAX_LINE = 128 * 1024;

sub parse_snapshot {
    my ($text, $format, $wanted) = @_;
    defined($text) && length($text) && defined($format) &&
        $format =~ /\A(?:ip-json|ifconfig)\z/ &&
        defined($wanted) && $wanted =~ /\A(?:all|inet|inet6)\z/
        or die "invalid parser arguments\n";
    # Reject framing errors globally, before the first record can be emitted.
    # A stray NUL or bare CR is never considered a valid network address.
    $text !~ /\x00/ && ($text !~ /\r/ || $text !~ /\r(?!\n)/)
        or die "invalid snapshot framing\n";
    if ($format eq 'ip-json') {
        return _parse_ip_json($text, $wanted);
    }
    return _parse_ifconfig($text, $wanted);
}

sub _name {
    my ($s) = @_;
    # Linux accepts @peer names, and BSD accepts alias :suffix names.
    # Whitespace, controls, slash and shell metacharacters are not usable
    # interface identifiers in our strict, stable output contract.
    return defined($s) && !ref($s) &&
        $s =~ /\A[A-Za-z0-9_.:@-]{1,64}\z/;
}

sub _state {
    my ($s) = @_;
    return 'UNKNOWN' unless defined($s) && !ref($s);
    $s = uc($s);
    return $s if $s =~ /\A(?:UP|DOWN|UNKNOWN|DORMANT|LOWERLAYERDOWN|NOTPRESENT|TESTING)\z/;
    return 'UNKNOWN';
}

sub _mac {
    my ($mac) = @_;
    return '-' unless defined $mac;
    !ref($mac) or die "malformed hardware address\n";
    # Non-Ethernet (loopback, tunnels) can lack a link-layer address. For
    # Ethernet only accept a canonical 48-bit representation, never guess.
    return '-' if $mac eq '';
    $mac =~ /\A[0-9A-Fa-f]{2}(?::[0-9A-Fa-f]{2}){5}\z/
        or die "malformed hardware address\n";
    return lc $mac;
}

sub _address {
    my ($family, $value, $prefix) = @_;
    defined($value) && !ref($value) && length($value) <= 80 &&
        defined($prefix) && !ref($prefix) && $prefix =~ /\A(?:0|[1-9][0-9]{0,2})\z/
        or die "malformed network address\n";
    my $max = $family eq 'inet' ? 32 : 128;
    $prefix <= $max or die "invalid address prefix\n";
    # Scoped IPv6 addresses (fe80::1%en0) must preserve their zone: dropping
    # it makes link-local addresses ambiguous on multihomed machines.
    my $binary = $value;
    if ($family eq 'inet6' && $binary =~ /%/) {
        $binary =~ s/%[A-Za-z0-9_.-]{1,64}\z//
            or die "invalid IPv6 scope identifier\n";
    }
    my $type = $family eq 'inet' ? AF_INET : AF_INET6;
    defined inet_pton($type, $binary)
        or die "invalid IP address\n";
    # The entire stored value must be printable, so JSONL/TSV/NUL output
    # never accidentally embeds terminal controls or extra columns.
    $value =~ /\A[0-9A-Za-z:.%_-]{1,80}\z/
        or die "invalid address characters\n";
    return [$family, lc($value), 0 + $prefix];
}

sub _assemble {
    my ($interfaces, $wanted) = @_;
    @$interfaces && @$interfaces <= $MAX_INTERFACES
        or die "interface count out of bounds\n";
    my @rows;
    my $addresses = 0;
    my %seen;
    for my $entry (@$interfaces) {
        my ($name, $index, $state, $mac, $ips) = @$entry;
        _name($name) or die "invalid interface name\n";
        !$seen{$name}++ or die "duplicate interface name\n";
        $index eq '-' || $index =~ /\A[1-9][0-9]{0,9}\z/
            or die "invalid interface index\n";
        my @selected = grep { $wanted eq 'all' || $_->[0] eq $wanted } @$ips;
        $addresses += scalar @$ips;
        $addresses <= $MAX_ADDRESSES or die "address count out of bounds\n";
        if (!@selected) {
            push @rows, [$name, $index, $state, '-', '-', '-', $mac];
        } else {
            push @rows, map { [$name, $index, $state, $_->[0], $_->[1], $_->[2], $mac] } @selected;
        }
    }
    return \@rows;
}

sub _parse_ip_json {
    my ($text, $wanted) = @_;
    # `ip -j address show` is one JSON array, not JSON Lines. Decoder depth
    # and upstream byte limits defend against pathological fixture structure.
    my $decoder = JSON::PP->new->utf8->max_depth(20);
    my $data = eval { $decoder->decode($text) };
    !$@ && ref($data) eq 'ARRAY'
        or die "invalid ip JSON document\n";
    my @interfaces;
    for my $obj (@$data) {
        ref($obj) eq 'HASH' or die "invalid ip interface object\n";
        my $name = $obj->{ifname};
        _name($name) or die "invalid interface name\n";
        my $index = $obj->{ifindex};
        defined($index) && !ref($index) && $index =~ /\A[1-9][0-9]{0,9}\z/
            or die "invalid interface index\n";
        my $state = _state($obj->{operstate});
        my $mac = _mac($obj->{address});
        my $info = $obj->{addr_info} // [];
        ref($info) eq 'ARRAY' or die "invalid address list\n";
        my @ips;
        for my $a (@$info) {
            ref($a) eq 'HASH' or die "invalid address object\n";
            my $family = $a->{family};
            # Non-IP link types (e.g. packet-layer metadata) belong outside
            # the IP inventory, never force them into an invented address.
            next if defined($family) && !ref($family) &&
                $family ne 'inet' && $family ne 'inet6';
            defined($family) && !ref($family) &&
                ($family eq 'inet' || $family eq 'inet6')
                or die "missing address family\n";
            push @ips, _address($family, $a->{local}, $a->{prefixlen});
        }
        push @interfaces, [$name, "$index", $state, $mac, \@ips];
        @interfaces <= $MAX_INTERFACES or die "interface count out of bounds\n";
    }
    return _assemble(\@interfaces, $wanted);
}

sub _prefix_from_netmask {
    my ($mask) = @_;
    defined($mask) or die "missing IPv4 netmask\n";
    my $bits;
    if ($mask =~ /\A0x([0-9a-fA-F]{8})\z/) {
        $bits = unpack('B32', pack('H8', $1));
    } elsif (defined(my $packed = inet_pton(AF_INET, $mask))) {
        $bits = unpack('B32', $packed);
    } else {
        die "invalid IPv4 netmask\n";
    }
    # Prefix is the length of the leading run of 1 bits. A non-contiguous
    # mask must not be rendered as a misleading CIDR prefix.
    $bits =~ /\A(1*)(0*)\z/ or die "noncontiguous IPv4 netmask\n";
    return length $1;
}

sub _parse_ifconfig {
    my ($text, $wanted) = @_;
    $text =~ /\n\z/ or die "unterminated ifconfig snapshot\n";
    my @interfaces;
    my $current;
    for my $line (split /\n/, $text) {
        length($line) <= $MAX_LINE or die "oversized ifconfig line\n";
        $line =~ s/\r\z//;
        next unless length $line;
        if ($line !~ /\A\s/) {
            # Every top-level record must be an interface header, not raw
            # unsolicited text that happens to contain `inet` or `status`.
            $line =~ /\A([A-Za-z0-9_.:@-]{1,64}):\s+flags=([0-9]+)<([^>]*)>\s+mtu\s+([0-9]+)(?:\s.*)?\z/
                or die "invalid ifconfig interface header\n";
            my ($name, $flags) = ($1, $3);
            _name($name) or die "invalid interface name\n";
            $flags =~ /\A[A-Za-z0-9_,]*\z/ or die "invalid interface flags\n";
            my $state = $flags =~ /(?:\A|,)UP(?:,|\z)/ ? 'UP' : 'DOWN';
            $current = [$name, '-', $state, '-', []];
            push @interfaces, $current;
            @interfaces <= $MAX_INTERFACES or die "interface count out of bounds\n";
            next;
        }
        defined($current) or die "interface detail without header\n";
        # First field is whitelisted; unknown ancillary ifconfig properties
        # (media, nd6, groups, options...) are intentionally ignored.
        if ($line =~ /\A\s+ether\s+(\S+)/) {
            $current->[3] = _mac($1);
        } elsif ($line =~ /\A\s+inet6\s+(\S+)\s+.*?\bprefixlen\s+(\d+)(?:\s|\z)/) {
            push @{ $current->[4] }, _address('inet6', $1, $2);
        } elsif ($line =~ /\A\s+inet6\b/) {
            die "malformed IPv6 ifconfig address\n";
        } elsif ($line =~ /\A\s+inet\s+(\S+)\s+.*?\bnetmask\s+(\S+)/) {
            push @{ $current->[4] }, _address('inet', $1, _prefix_from_netmask($2));
        } elsif ($line =~ /\A\s+inet\b/) {
            die "malformed IPv4 ifconfig address\n";
        } elsif ($line =~ /\A\s+status:\s+(active|inactive)\s*\z/i) {
            $current->[2] = lc($1) eq 'active' ? 'UP' : 'DOWN';
        }
    }
    return _assemble(\@interfaces, $wanted);
}

1;
