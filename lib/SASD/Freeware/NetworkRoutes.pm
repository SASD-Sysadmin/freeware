package SASD::Freeware::NetworkRoutes;
# SPDX-License-Identifier: MIT
# M8.2: Strict, side-effect-free routing snapshot normalization.
#
# The parser never launches a command, reads a file, or looks at the local
# routing table. This is intentional: it lets us replay synthetic Linux and
# BSD/macOS captures in CI without creating routes or requiring privileges.
#
# One normalized record is exactly eight fields:
#   FAMILY, DESTINATION, GATEWAY, INTERFACE, TABLE, METRIC, TYPE, FLAGS
# The '-' sentinel means "not represented in this source", never "zero".
# A valid empty snapshot is possible and produces no rows; a syntactically
# incomplete snapshot is an error. Every record is checked BEFORE emission.
use strict;
use warnings;
use Exporter qw(import);
use JSON::PP ();
use Socket qw(AF_INET AF_INET6 inet_pton);
our @EXPORT_OK = qw(parse_routes);

my $MAX_ROUTES = 8192;
my $MAX_LINE = 16384;

sub parse_routes {
    my ($bytes, $format, $family) = @_;
    defined($bytes) && length($bytes) && !ref($bytes) &&
        defined($format) && $format =~ /\A(?:ip-json|netstat)\z/ &&
        defined($family) && $family =~ /\A(?:all|inet|inet6)\z/
        or die "invalid parser arguments\n";
    # JSON and terminal captures must have unambiguous byte framing.
    $bytes !~ /\x00|\r(?!\n)/ or die "unsafe input framing\n";
    my $routes = $format eq 'ip-json'
        ? _linux_json($bytes, $family) : _bsd_netstat($bytes, $family);
    @$routes <= $MAX_ROUTES or die "too many routes\n";
    return $routes;
}

sub _token {
    my ($text, $max) = @_;
    return defined($text) && !ref($text) && length($text) > 0 &&
           length($text) <= $max && $text =~ /\A[A-Za-z0-9_.:\@%+\/-]+\z/;
}

sub _iface {
    my ($text) = @_;
    return _token($text, 64) && $text !~ m{/} && $text ne '-' &&
           $text !~ /\A\./;
}

sub _ip {
    my ($value, $family) = @_;
    _token($value, 96) or die "invalid IP address\n";
    my $bare = $value;
    if ($family eq 'inet6' && $bare =~ /%/) {
        $bare =~ s/%([A-Za-z0-9_.-]{1,64})\z//
            or die "invalid IPv6 zone\n";
        # IPv6 zones are only meaningful on IPv6 addresses, not prefixes.
    }
    # Disallow noncanonical IPv4 shorthand, DNS names and input that the
    # kernel's address parser would accept too permissively.
    if ($family eq 'inet') {
        $bare =~ /\A(?:[0-9]{1,3}\.){3}[0-9]{1,3}\z/
            or die "invalid dotted IPv4 address\n";
        for my $octet (split /\./, $bare) {
            $octet <= 255 && ($octet eq '0' || $octet !~ /\A0/)
                or die "invalid IPv4 octet\n";
        }
    }
    defined(inet_pton($family eq 'inet' ? AF_INET : AF_INET6, $bare))
        or die "invalid IP literal\n";
    return lc($value);
}

sub _destination {
    my ($dest, $family) = @_;
    defined($dest) && !ref($dest) or die "missing destination\n";
    return 'default' if $dest eq 'default';
    _token($dest, 110) or die "invalid destination token\n";
    my @parts = split m{/}, $dest, -1;
    @parts <= 2 or die "ambiguous CIDR destination\n";
    my ($ip, $prefix) = @parts;
    !defined($prefix) || $prefix =~ /\A(?:0|[1-9][0-9]{0,2})\z/
        or die "invalid CIDR prefix\n";
    defined($prefix) && $prefix > ($family eq 'inet' ? 32 : 128)
        and die "CIDR prefix out of range\n";
    return _ip($ip, $family) . (defined($prefix) ? "/" . (0+$prefix) : '');
}

sub _bsd_destination {
    my ($text, $family) = @_;
    # Historic BSD routing displays abbreviate IPv4 network destinations.
    # For example, "127" or "192.0.2" is NOT a canonical dotted address,
    # and blindly expanding it to a /8 or /24 would invent route semantics.
    # Preserve the original token with a deliberately narrow numeric grammar;
    # callers can distinguish it from a validated explicit CIDR.
    return 'default' if defined($text) && $text eq 'default';
    if ($family eq 'inet' && defined($text) && !ref($text) &&
        $text =~ /\A([0-9]+(?:\.[0-9]+){0,2})(?:\/(0|[1-9][0-9]{0,1}))?\z/) {
        my ($short, $prefix) = ($1, $2);
        for my $octet (split /\./, $short) {
            length($octet) <= 3 && $octet <= 255 &&
                ($octet eq '0' || $octet !~ /\A0/)
                or die "malformed BSD abbreviated destination\n";
        }
        !defined($prefix) || $prefix <= 32
            or die "invalid BSD short prefix\n";
        return $text;
    }
    return _destination($text, $family);
}

sub _route {
    my (%f) = @_;
    $f{family} =~ /\A(?:inet|inet6)\z/ or die "invalid family\n";
    $f{destination} = $f{format} && $f{format} eq 'netstat'
        ? _bsd_destination($f{destination}, $f{family})
        : _destination($f{destination}, $f{family});
    if ($f{gateway} ne '-') {
        if ($f{gateway} =~ /\Alink\#(?:0|[1-9][0-9]{0,9})\z/) {
            # BSD link-layer route: a link#N token is NOT an IP next hop.
        } elsif ($f{gateway} =~ /\A(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}\z/) {
            $f{gateway} = lc($f{gateway});
        } else {
            $f{gateway} = _ip($f{gateway}, $f{family});
        }
    }
    $f{interface} eq '-' || _iface($f{interface})
        or die "invalid interface identifier\n";
    $f{table} eq '-' || $f{table} =~ /\A(?:main|local|default|[1-9][0-9]{0,9})\z/
        or die "invalid routing table\n";
    $f{metric} eq '-' || $f{metric} =~ /\A(?:0|[1-9][0-9]{0,9})\z/
        or die "invalid routing metric\n";
    $f{type} eq '-' || $f{type} =~ /\A(?:unicast|local|broadcast|multicast|blackhole|unreachable|prohibit|throw|nat|anycast)\z/
        or die "invalid route type\n";
    $f{flags} eq '-' || $f{flags} =~ /\A[A-Za-z0-9_,]{1,128}\z/
        or die "invalid route flags\n";
    return [@f{qw(family destination gateway interface table metric type flags)}];
}

sub _linux_json {
    my ($text, $selection) = @_;
    # A single array has no reliable family information for `default` and
    # therefore is accepted ONLY when --family explicitly selects one family.
    # The all-family snapshot is a small envelope with both named arrays:
    # {"inet":[...], "inet6":[...]}. It preserves the provenance of defaults.
    my $data = eval { JSON::PP->new->utf8->max_depth(24)->decode($text) };
    !$@ or die "malformed route JSON\n";
    my %groups;
    if (ref($data) eq 'ARRAY') {
        $selection ne 'all' or die "ambiguous family for route array\n";
        $groups{$selection} = $data;
    } elsif (ref($data) eq 'HASH') {
        keys(%$data) == 2 && exists($data->{inet}) && exists($data->{inet6}) &&
            ref($data->{inet}) eq 'ARRAY' && ref($data->{inet6}) eq 'ARRAY'
            or die "invalid dual-family route envelope\n";
        %groups = %$data;
    } else {
        die "route JSON must be array or dual-family envelope\n";
    }
    my @out;
    for my $family (qw(inet inet6)) {
        next unless exists($groups{$family});
        my $items = $groups{$family};
        for my $obj (@$items) {
            ref($obj) eq 'HASH' or die "route entry is not an object\n";
            # Never misrepresent ECMP, encapsulation, or a next-hop ID as a
            # single ordinary gateway. These require their own later model.
            !exists($obj->{nexthops}) && !exists($obj->{nhid}) &&
                !exists($obj->{encap}) && !exists($obj->{via})
                or die "unsupported advanced next-hop representation\n";
            # Never convert a blank/partial object into a fabricated default.
            exists($obj->{dst}) or die "route destination is missing\n";
            my $dst = $obj->{dst};
            my $gateway = exists($obj->{gateway}) ? $obj->{gateway} : '-';
            $gateway = '-' if !defined($gateway);
            my $dev = exists($obj->{dev}) ? $obj->{dev} : '-';
            $dev = '-' if !defined($dev);
            my $table = exists($obj->{table}) ? $obj->{table} : 'main';
            my $metric = exists($obj->{metric}) ? $obj->{metric} : '-';
            my $type = exists($obj->{type}) ? $obj->{type} : 'unicast';
            my $flags = '-';
            if (exists($obj->{flags})) {
                ref($obj->{flags}) eq 'ARRAY' or die "invalid route flags\n";
                my @flags = @{ $obj->{flags} };
                @flags <= 12 or die "too many route flags\n";
                for my $flag (@flags) {
                    _token($flag, 24) && $flag =~ /\A[A-Za-z0-9_]+\z/
                        or die "invalid route flag\n";
                }
                $flags = join(',', @flags) if @flags;
            }
            my $declared = $obj->{family};
            !defined($declared) || (!ref($declared) && $declared eq $family)
                or die "route family mismatch\n";
            push @out, _route(
                family=>$family, destination=>$dst, gateway=>$gateway,
                interface=>$dev, table=>defined($table) ? "$table" : '-',
                metric=>defined($metric) ? "$metric" : '-',
                type=>defined($type) ? $type : '-', flags=>$flags,
            );
            @out <= $MAX_ROUTES or die "too many routes\n";
        }
    }
    return [grep { $selection eq 'all' || $_->[0] eq $selection } @out];
}

sub _bsd_netstat {
    my ($text, $selection) = @_;
    $text =~ /\n\z/ or die "unterminated netstat snapshot\n";
    my ($family, $seen_v4, $seen_v6, $header, $iface_col);
    my @out;
    for my $line (split /\n/, $text) {
        $line =~ s/\r\z//;
        length($line) <= $MAX_LINE or die "overlong netstat line\n";
        next if $line =~ /\A\s*\z/;
        next if $line =~ /\A(?:Routing tables|Routing Table)\s*:?\s*\z/i;
        if ($line =~ /\AInternet6?:\s*\z/) {
            $family = $line =~ /6/ ? 'inet6' : 'inet';
            if ($family eq 'inet') {
                !$seen_v4++ or die "duplicate netstat IPv4 section\n";
            } else {
                !$seen_v6++ or die "duplicate netstat IPv6 section\n";
            }
            $header = undef; $iface_col = undef;
            next;
        }
        defined($family) or die "netstat data before address-family heading\n";
        if ($line =~ /\A\s*Destination\s+Gateway\s+/) {
            defined($header) and die "duplicate netstat header\n";
            my @columns = split /\s+/, $line;
            @columns >= 4 && $columns[2] eq 'Flags'
                or die "unsupported netstat heading\n";
            for my $i (3..$#columns) {
                if ($columns[$i] =~ /\A(?:Netif|Iface|Interface)\z/i) {
                    $iface_col = $i;
                    last;
                }
            }
            defined($iface_col) or die "netstat lacks interface column\n";
            $header = 1;
            next;
        }
        $header or die "route row before netstat heading\n";
        my $route_line = $line;
        $route_line =~ s/\A\s+//;
        my @parts = split /\s+/, $route_line;
        @parts > $iface_col or die "truncated netstat route row\n";
        # Ignore only trailing optional columns such as Expire. Their values
        # cannot alter the destination, gateway, interface or Flags columns.
        my ($dst, $gateway, $flags, $iface) = @parts[0,1,2,$iface_col];
        $flags =~ /\A[A-Za-z0-9_]{1,64}\z/ or die "invalid netstat flags\n";
        _iface($iface) or die "invalid netstat interface\n";
        # Validate the destination in _route, including bounded legacy BSD
        # abbreviations. A short printed token is preserved, not expanded.
        push @out, _route(family=>$family, destination=>$dst,
            gateway=>$gateway, interface=>$iface, table=>'-', metric=>'-',
            type=>'-', flags=>$flags, format=>'netstat');
        @out <= $MAX_ROUTES or die "too many routes\n";
    }
    # Accept empty routing tables, not a missing/partial family section.
    if ($selection eq 'all') {
        $seen_v4 && $seen_v6 or die "incomplete dual-family netstat capture\n";
    } else {
        ($selection eq 'inet' ? $seen_v4 : $seen_v6)
            or die "missing requested netstat family\n";
    }
    return [grep { $selection eq 'all' || $_->[0] eq $selection } @out];
}
1;
