package SASD::Freeware::NetworkServices;
# SPDX-License-Identifier: MIT
# M8.3 – Pure, bounded parsers for read-only local TCP/UDP socket snapshots.
#
# ARCHITECTURE
#   This module has no shell execution, filesystem access or network access.
#   The small bin/network-service-report adapter owns subprocesses and input
#   descriptors, while this module validates one COMPLETE snapshot and returns
#   an array of uniformly typed rows. Serializing the rows is the CLI's job.
#
# CONTRACT
#   Each row is [family, protocol, local_address, local_port,
#                state, peer_address, peer_port]. Values are strictly printable
#   (no tabs, newlines or control sequences), so TSV and NUL remain unambiguous.
#   TCP is *only* LISTEN, UDP is *only* unconnected locally bound sockets.
#   UDP's state is called BOUND, NOT LISTEN. Neither implies outside reachability.
#   A wildcard-only Linux ss endpoint can have an unknowable address family;
#   we report 'unknown' rather than quietly inventing IPv4 or IPv6.
use strict;
use warnings;
use Socket qw(AF_INET AF_INET6 inet_pton);
use Exporter qw(import);
our @EXPORT_OK = qw(parse_snapshot);

my $MAX_LINES = 8192;
my $MAX_LINE = 65536;
my $MAX_ROWS = 4096;

sub parse_snapshot {
    my ($raw, $format, $protocol, $family) = @_;
    defined($raw) && !ref($raw) && defined($format) &&
        $format =~ /\A(?:ss|netstat)\z/ &&
        defined($protocol) && $protocol =~ /\A(?:all|tcp|udp)\z/ &&
        defined($family) && $family =~ /\A(?:all|inet|inet6)\z/
        or die "invalid parser arguments\n";
    # Validate all framing before recognizing a row. A terminal escape or a
    # stray CR should never become part of an IP endpoint or a screen column.
    $raw !~ /[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/ && $raw !~ /\r(?!\n)/
        or die "invalid snapshot framing\n";
    $raw eq '' || $raw =~ /\n\z/ or die "unterminated snapshot\n";
    # Count physical lines before splitting. A split without a limit discards
    # trailing empty fields and could otherwise bypass the line-count cap.
    my $physical_lines = () = $raw =~ /\n/g;
    $physical_lines <= $MAX_LINES or die "snapshot line count exceeded\n";
    my @lines = split /\n/, $raw;
    for my $line (@lines) {
        length($line) <= $MAX_LINE or die "snapshot line too long\n";
        $line =~ s/\r\z//;
    }
    my $rows = $format eq 'ss' ? _parse_ss(\@lines) : _parse_netstat(\@lines);
    @$rows <= $MAX_ROWS or die "socket count exceeded\n";
    # Filtering happens ONLY after the source has passed full validation.
    # Malformed rows must not disappear when the user selects another family.
    return [grep {
        ($protocol eq 'all' || $_->[1] eq $protocol) &&
        ($family eq 'all' || $_->[0] eq $family)
    } @$rows];
}

sub _ip {
    my ($value) = @_;
    return ['*', 'unknown'] if defined($value) && $value eq '*';
    defined($value) && length($value) <= 100 &&
        $value =~ /\A[0-9A-Za-z:.%_-]+\z/
        or die "invalid endpoint characters\n";
    my $plain = $value;
    if ($plain =~ /%/) {
        $plain =~ s/%[A-Za-z0-9_.-]{1,64}\z//
            or die "invalid IPv6 zone\n";
    }
    my $family;
    if (defined inet_pton(AF_INET, $plain)) { $family = 'inet'; }
    elsif (defined inet_pton(AF_INET6, $plain)) { $family = 'inet6'; }
    else { die "invalid numeric IP endpoint\n"; }
    $family eq 'inet6' || $value !~ /%/ or die "IPv4 must not have a zone\n";
    return [lc($value), $family];
}

sub _port {
    my ($value, $local) = @_;
    return '*' if !$local && $value eq '*';
    $value =~ /\A(?:0|[1-9][0-9]{0,4})\z/ && $value >= 1 && $value <= 65535
        or die "invalid socket port\n";
    return 0 + $value;
}

sub _endpoint_ss {
    my ($token, $local) = @_;
    # ss emits either IPv4:PORT, [IPv6]:PORT, bare ::PORT, or *:PORT.
    # Splitting at the final colon deliberately supports scoped IPv6 literals.
    my ($address, $port);
    if ($token =~ /\A\[([^\]]+)\]:(\*|[0-9]+)\z/) {
        ($address, $port) = ($1,$2);
    } elsif ($token =~ /\A(.+):(\*|[0-9]+)\z/) {
        ($address, $port) = ($1,$2);
    } else { die "invalid ss endpoint\n"; }
    my ($ip, $family) = @{_ip($address)};
    return [$ip, _port($port,$local), $family];
}

sub _endpoint_netstat {
    my ($token, $local) = @_;
    # BSD netstat separates the host from its numeric port using a dot, even
    # for IPv6: ::1.443, fe80::1%en0.5353 and the wildcard *.*.
    $token =~ /\A(.+)\.(\*|[0-9]+)\z/ or die "invalid netstat endpoint\n";
    my ($address, $port) = ($1,$2);
    my ($ip,$family) = @{_ip($address)};
    return [$ip,_port($port,$local),$family];
}

sub _row {
    my ($protocol,$specified_family,$local,$remote,$state) = @_;
    my $family = $specified_family // 'unknown';
    for my $e ($local,$remote) {
        next if $e->[2] eq 'unknown';
        if ($family ne 'unknown' && $family ne $e->[2]) {
            die "endpoint address family mismatch\n";
        }
        $family = $e->[2];
    }
    # A listener and an unconnected UDP socket cannot have a concrete peer.
    # Check this invariant on both backends rather than trusting netstat/ss.
    $remote->[0] eq '*' ||
        (($remote->[0] eq '0.0.0.0' || $remote->[0] eq '::') && $remote->[1] eq '*')
        or die "listener has unexpected peer\n";
    $remote->[1] eq '*' or die "listener peer port is not wildcard\n";
    return [$family,$protocol,$local->[0],$local->[1],$state,$remote->[0],$remote->[1]];
}

sub _parse_ss {
    my ($lines) = @_;
    my @rows;
    for my $line (@$lines) {
        next if $line =~ /\A\s*\z/;
        # An explicitly headerless invocation is used natively. Accept the
        # standard user-collected header too, but reject other stray text.
        next if $line =~ /\ANetid\s+State\s+Recv-Q\s+Send-Q\s+Local Address:Port\s+Peer Address:Port\s*\z/;
        my @parts = split /\s+/, $line;
        @parts == 6 or die "unexpected ss columns\n";
        my ($proto,$state,$recv,$send,$local_raw,$peer_raw) = @parts;
        $proto =~ /\A(?:tcp|udp)\z/ or die "unexpected ss protocol\n";
        $recv =~ /\A[0-9]{1,12}\z/ && $send =~ /\A[0-9]{1,12}\z/
            or die "invalid ss queue counters\n";
        if ($proto eq 'tcp') {
            # ss -l normally only returns LISTEN. Unexpected TCP states are
            # not listed as services but must still be recognized explicitly.
            $state =~ /\A(?:LISTEN|ESTAB|CLOSE-WAIT|TIME-WAIT|SYN-RECV|SYN-SENT|FIN-WAIT-1|FIN-WAIT-2|LAST-ACK|CLOSING|CLOSED)\z/
                or die "unsupported ss TCP state\n";
            next unless $state eq 'LISTEN';
        } else {
            $state =~ /\A(?:UNCONN|ESTAB)\z/ or die "unsupported ss UDP state\n";
            next unless $state eq 'UNCONN';
        }
        my $local = _endpoint_ss($local_raw,1);
        my $remote = _endpoint_ss($peer_raw,0);
        push @rows, _row($proto,undef,$local,$remote,
                          $proto eq 'tcp' ? 'LISTEN' : 'BOUND');
        @rows <= $MAX_ROWS or die "socket count exceeded\n";
    }
    return \@rows;
}

sub _parse_netstat {
    my ($lines) = @_;
    my ($section,$header) = (0,0);
    my @rows;
    for my $line (@$lines) {
        $section = 1 if $line =~ /\AActive Internet connections\b/;
        $header = 1 if $section && $line =~ /\AProto\s+Recv-Q\s+Send-Q\s+Local Address\s+Foreign Address/;
        # Other sections (routing, UNIX sockets, ancillary statistics) are
        # intentionally not interpreted as a local Internet socket table.
        next unless $line =~ /\A(tcp|udp)([46])\s/;
        $section && $header or die "socket row without Internet header\n";
        my ($proto,$suffix) = ($1,$2);
        my @parts = split /\s+/, $line;
        my $expected = $proto eq 'tcp' ? 6 : 5;
        @parts >= $expected or die "truncated netstat socket row\n";
        my ($recv,$send,$local_raw,$peer_raw) = @parts[1..4];
        $recv =~ /\A[0-9]{1,12}\z/ && $send =~ /\A[0-9]{1,12}\z/
            or die "invalid netstat queue counters\n";
        if ($proto eq 'tcp') {
            # The BSD state column follows the peer endpoint. Only TCP LISTEN
            # indicates a local service endpoint, not ESTABLISHED/TIME_WAIT.
            @parts == 6 or die "unexpected netstat TCP columns\n";
            next unless $parts[5] eq 'LISTEN';
        } else {
            # UDP has no LISTEN state. A concrete remote port means connected
            # UDP, which is excluded from this *unconnected binding* inventory.
            @parts == 5 or die "unexpected netstat UDP columns\n";
        }
        my $local = _endpoint_netstat($local_raw,1);
        my $remote = _endpoint_netstat($peer_raw,0);
        if ($proto eq 'udp' && $remote->[1] ne '*') {
            next; # Connected datagram endpoint: not part of this report.
        }
        my $family = $suffix eq '4' ? 'inet' : 'inet6';
        push @rows, _row($proto,$family,$local,$remote,
                          $proto eq 'tcp' ? 'LISTEN' : 'BOUND');
        @rows <= $MAX_ROWS or die "socket count exceeded\n";
    }
    $section && $header or die "missing netstat Internet table header\n";
    return \@rows;
}

1;
