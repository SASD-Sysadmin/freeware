#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M8.4.5 – Deterministic firewalld source and hostile-input acceptance tests.
#
# We exercise the public CLI, not only internal helper routines. Every input
# is an offline synthetic fixture; the suite NEVER invokes the real
# firewall-cmd, D-Bus, sudo or a kernel filtering API. All parser failures
# must happen before any TSV header/row (or NUL field) is printed.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use IPC::Open3;
use Symbol qw(gensym);
use lib "$FindBin::Bin/../lib";
use SASD::Freeware::FirewallAudit qw(parse_snapshot);
use SASD::Freeware::FirewallFirewalld qw(parse_firewalld_snapshot);

my $tool = "$FindBin::Bin/../bin/firewall-config-audit";
my $tmp = tempdir('sasd-firewalld-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $n = 0;
my $heading = "ENGINE\tSCOPE\tSTATE\tFAMILY\tTABLE\tCHAIN\tPOLICY\tRULES\n";

sub fixture {
    my ($data) = @_;
    my $path = "$tmp/" . ++$n;
    open my $fh, '>', $path or die "fixture creation failed: $!";
    binmode $fh;
    print {$fh} $data;
    close $fh or die "fixture close failed: $!";
    return $path;
}
sub command {
    my (@options) = @_;
    my $err = gensym;
    my $pid = open3(undef, my $out, $err, $^X, $tool, @options);
    local $/;
    my ($stdout, $stderr) = (<$out> // '', <$err> // '');
    close $out; close $err;
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}
sub run_source {
    my ($source, $data, @extra) = @_;
    return command('--source', $source, '--input', fixture($data), @extra);
}
sub good {
    my ($label, $source, $data, $rows) = @_;
    my ($rc, $out, $err) = run_source($source, $data);
    is($rc, 0, "$label exit success");
    is($out, $heading . $rows, "$label stable structured output");
    is($err, '', "$label no warning");
    unlike($out, qr/192\.0\.2|198\.51\.100|SECRET|eth0|enp1s0|10000\/tcp/,
           "$label does not leak interfaces, addresses or rule contents");
    my @public = eval { parse_snapshot($data, $source) };
    is($@, '', "$label shared parser accepts input");
    is(scalar(@{$public[0]}), scalar(() = $rows =~ /\n/g),
       "$label direct parser agrees on row count");
}
sub bad {
    my ($label, $source, $data) = @_;
    my ($rc, $out, $err) = run_source($source, $data);
    is($rc, 3, "$label exit failure");
    is($out, '', "$label prints no partial header or data");
    like($err, qr/^firewall-config-audit: malformed or unsupported firewall snapshot\n\z/,
         "$label stable no-input-leak diagnostic");
    my $parsed = eval { parse_firewalld_snapshot($data, $source); 1 };
    ok(!$parsed && $@ ne '', "$label rejected by pure parser too");
}

my $zone = <<'LIST';
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 enp1s0
  sources: 192.0.2.0/24
  services: ssh dhcpv6-client
  ports: 10000/tcp
  protocols:
  forward: no
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
    rule family="ipv4" source address="198.51.100.1" service name="SECRET" accept
    rule family="ipv6" port port="10000" protocol="tcp" drop
internal
  target: ACCEPT
  interfaces:
  sources:
  services:
  ports:
  rich rules:
LIST

my $zone_rows = "firewalld\truntime\tPARTIAL\t-\tinternal\trich-rules\tACCEPT\t0\n" .
                "firewalld\truntime\tPARTIAL\t-\tpublic\trich-rules\tDEFAULT\t2\n";
good('runtime zones', 'firewalld-runtime-zones', $zone, $zone_rows);
my $perm = $zone;
$perm =~ s/public \(active\)/public/;
good('permanent zones are configuration', 'firewalld-permanent-zones', $perm,
     "firewalld\tconfiguration\tPARTIAL\t-\tinternal\trich-rules\tACCEPT\t0\n" .
     "firewalld\tconfiguration\tPARTIAL\t-\tpublic\trich-rules\tDEFAULT\t2\n");
good('daemon running', 'firewalld-state', "running\n",
     "firewalld\tdaemon\tRUNNING\t-\t-\t-\t-\t-\n");
good('offline daemon status sample', 'firewalld-state', "not running\n",
     "firewalld\tdaemon\tNOT_RUNNING\t-\t-\t-\t-\t-\n");
good('active bindings redacted', 'firewalld-active-zones',
     "public\n  interfaces: eth0 enp1s0\n  sources: 192.0.2.0/24\ninternal\n  interfaces: enp1s0\n",
     "firewalld\truntime\tBOUND\t-\tinternal\tbindings\t-\t-\n" .
     "firewalld\truntime\tBOUND\t-\tpublic\tbindings\t-\t-\n");
good('no bound zones is not inactive firewall', 'firewalld-active-zones', '',
     "firewalld\truntime\tNONE_BOUND\t-\t-\tzones\t-\t-\n");
good('blank lines between active zones', 'firewalld-active-zones',
     "public\n  interfaces: eth0\n\ninternal\n  sources: 192.0.2.0/24\n",
     "firewalld\truntime\tBOUND\t-\tinternal\tbindings\t-\t-\n" .
     "firewalld\truntime\tBOUND\t-\tpublic\tbindings\t-\t-\n");
good('forward ports do not count as rich rules', 'firewalld-runtime-zones',
     "public\n  target: default\n  forward-ports:\n    port=8000:proto=tcp:toport=80:toaddr=192.0.2.42\n  rich rules:\n",
     "firewalld\truntime\tPARTIAL\t-\tpublic\trich-rules\tDEFAULT\t0\n");
good('empty zone listing remains partial', 'firewalld-runtime-zones', '',
     "firewalld\truntime\tPARTIAL\t-\t-\trich-rules\t-\t0\n");
for my $target (qw(ACCEPT DROP REJECT default %%REJECT%%)) {
    my $normalized = $target eq 'default' ? 'DEFAULT' : $target eq '%%REJECT%%' ? 'REJECT' : $target;
    good("target $target", 'firewalld-runtime-zones',
         "public\n  target: $target\n  rich rules:\n",
         "firewalld\truntime\tPARTIAL\t-\tpublic\trich-rules\t$normalized\t0\n");
}
# No individual rule is revealed even in NUL output; eight fields/row.
my ($rc, $out, $err) = run_source('firewalld-runtime-zones', $zone, '--null');
is($rc, 0, 'NUL output accepted');
is(scalar(() = $out =~ /\0/g), 16, 'NUL output eight fields per zone');
like($out, qr/\0\z/, 'NUL last field terminated');
unlike($out, qr/ENGINE|SECRET|eth0|192\.0\.2|10000\/tcp/, 'NUL output redacted');
is($err, '', 'NUL output no warning');
($rc, $out, $err) = command('--help');
is($rc, 0, 'help success');
like($out, qr/firewalld-state.*firewalld-active-zones/s, 'help describes firewalld sources');
($rc, $out, $err) = command('--source', 'firewalld-state', '--input', fixture("running\n"), '--bogus');
is($rc, 2, 'unsupported CLI option rejected');

# The following malformed snapshots must never return a valid-looking
# subset (e.g. the 'public' zone from a truncated second zone).
my @bad = (
    ['state empty', 'firewalld-state', ''],
    ['state uppercase', 'firewalld-state', "RUNNING\n"],
    ['state combined', 'firewalld-state', "running\nnot running\n"],
    ['state trailing garbage', 'firewalld-state', "running\nSECRET\n"],
    ['state missing newline', 'firewalld-state', 'running'],
    ['state ANSI escape', 'firewalld-state', "\033[31mrunning\n"],
    ['state NUL', 'firewalld-state', "running\0\n"],
    ['active orphan', 'firewalld-active-zones', "  interfaces: eth0\n"],
    ['active duplicate', 'firewalld-active-zones', "public\n  interfaces: eth0\npublic\n  sources: 192.0.2.5\n"],
    ['active no binding', 'firewalld-active-zones', "public\n"],
    ['active skipped binding', 'firewalld-active-zones', "public\ninternal\n  interfaces: eth0\n"],
    ['active malformed heading', 'firewalld-active-zones', "public (active)\n  interfaces: eth0\n"],
    ['active duplicate spacing', 'firewalld-active-zones', "public\n  interfaces: eth0  enp1s0\n"],
    ['active unknown field', 'firewalld-active-zones', "public\n  rules: ACCEPT\n"],
    ['active missing newline', 'firewalld-active-zones', "public\n  interfaces: eth0"],
    ['active duplicate field', 'firewalld-active-zones', "public\n  interfaces: eth0\n  interfaces: enp1s0\n"],
    ['zone missing target', 'firewalld-runtime-zones', "public\n  rich rules:\n"],
    ['zone missing rich field', 'firewalld-runtime-zones', "public\n  target: default\n"],
    ['zone unknown target', 'firewalld-runtime-zones', "public\n  target: SECRET\n  rich rules:\n"],
    ['zone duplicate', 'firewalld-runtime-zones', $zone . $zone],
    ['zone duplicate target', 'firewalld-runtime-zones', "public\n  target: default\n  target: DROP\n  rich rules:\n"],
    ['zone partial second', 'firewalld-runtime-zones', "public\n  target: default\n  rich rules:\nsecond\n  target: DROP\n"],
    ['zone orphan field', 'firewalld-runtime-zones', "  target: DROP\n"],
    ['zone unknown property', 'firewalld-runtime-zones', "public\n  target: default\n  unexpected: value\n  rich rules:\n"],
    ['zone rich line without header', 'firewalld-runtime-zones', "public\n  target: default\n    rule source address=192.0.2.4 accept\n  rich rules:\n"],
    ['zone rich invalid continuation', 'firewalld-runtime-zones', "public\n  target: default\n  rich rules:\n    nonsense SECRET\n"],
    ['zone unexpected continuation', 'firewalld-runtime-zones', "public\n  target: default\n  services: ssh\n    rule src=192.0.2.5 accept\n  rich rules:\n"],
    ['zone inline rich rule', 'firewalld-runtime-zones', "public\n  target: default\n  rich rules: SECRET\n"],
    ['zone table escape', 'firewalld-runtime-zones', "bad\tname\n  target: DROP\n  rich rules:\n"],
    ['zone newline incomplete', 'firewalld-runtime-zones', "public\n  target: default\n  rich rules:"],
    ['zone embedded NUL', 'firewalld-runtime-zones', "public\n  target: default\n  rich rules:\0\n"],
    ['zone CR invalid', 'firewalld-runtime-zones', "public\r  target: default\n  rich rules:\n"],
    ['zone line too long', 'firewalld-runtime-zones', "public\n  target: default\n  services: " . ('a' x 131072) . "\n  rich rules:\n"],
    ['zone too many rich lines', 'firewalld-runtime-zones', "public\n  target: default\n  rich rules:\n" . ("    rule source address=192.0.2.10 accept\n" x 16385)],
);
for my $case (@bad) {
    bad(@$case);
}
# Each legal source must reject the other formats rather than autodetecting.
my @sources = qw(firewalld-state firewalld-active-zones firewalld-runtime-zones firewalld-permanent-zones);
for my $source (@sources) {
    for my $different (@sources) {
        next if $source eq $different;
        # Listing formats are intentionally the same grammar in two scopes.
        next if $source =~ /zones\z/ && $different =~ /(?:runtime|permanent)-zones\z/ &&
                $source =~ /(?:runtime|permanent)-zones\z/;
        my $input = $different eq 'firewalld-state' ? "running\n" :
                    $different eq 'firewalld-active-zones' ? "public\n  interfaces: eth0\n" :
                    "public\n  target: default\n  rich rules:\n";
        bad("$source rejects $different format", $source, $input);
    }
}
# Confirm direct API refuses scalar refs, unsupported source and huge input.
for my $case ([undef,'firewalld-state'], [\"running\n", 'firewalld-state'],
              ["running\n", 'other'], ["running\n" x 700000, 'firewalld-state']) {
    my $result = eval { parse_firewalld_snapshot(@$case); 1 };
    ok(!$result && $@ ne '', 'invalid parser argument rejected');
}
# Explicitly verify no native firewalld invocation occurs outside Linux.
if ($^O ne 'linux') {
    my ($code, $stdout, $stderr) = command('--source', 'firewalld-state');
    is($code, 3, 'native firewalld rejected outside Linux');
    is($stdout, '', 'unsupported native query prints nothing');
    like($stderr, qr/native Linux firewall backend is unsupported/, 'native error is explanatory');
}
# CRLF captured from a Windows relay is accepted but not forwarded.
good('CRLF zone snapshot', 'firewalld-runtime-zones',
     "public\r\n  target: default\r\n  rich rules:\r\n",
     "firewalld\truntime\tPARTIAL\t-\tpublic\trich-rules\tDEFAULT\t0\n");

done_testing();
