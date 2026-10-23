#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M8.4.3 – Offline Solaris firewall parser tests; NO real Solaris needed.
#
# The tests exercise the same public CLI path used for native inspection.
# All fixtures are synthetic snapshots based on documented ipfstat, pfctl
# and svcs output. We never run native firewall commands or require root.
# An on-host Solaris acceptance test is still necessary before certifying
# actual compatibility, particularly for localized/versioned output.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use IPC::Open3;
use Symbol qw(gensym);
use lib "$FindBin::Bin/../lib";
use SASD::Freeware::FirewallAudit qw(parse_snapshot);
use SASD::Freeware::FirewallSolaris qw(parse_solaris_snapshot);

my $tool = "$FindBin::Bin/../bin/firewall-config-audit";
my $tmp = tempdir('sasd-firewall-solaris-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $counter = 0;
my $header = "ENGINE\tSCOPE\tSTATE\tFAMILY\tTABLE\tCHAIN\tPOLICY\tRULES\n";

sub fixture {
    my ($text) = @_;
    my $name = "$tmp/" . ++$counter;
    open my $fh, '>', $name or die "test fixture open failed: $!";
    binmode($fh);
    print {$fh} $text;
    close $fh or die "test fixture close failed: $!";
    return $name;
}
sub cli {
    my (@args) = @_;
    my $err = gensym;
    my $pid = open3(undef, my $out, $err, $^X, $tool, @args);
    local $/;
    my ($stdout, $stderr) = (<$out> // '', <$err> // '');
    close $out; close $err;
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}
sub run_source {
    my ($source, $text, @options) = @_;
    return cli('--source', $source, '--input', fixture($text), @options);
}
sub good {
    my ($label, $source, $input, $expected) = @_;
    my ($rc, $out, $err) = run_source($source, $input);
    is($rc, 0, "$label: exit zero");
    is($out, $header . $expected, "$label: expected eight-field output");
    is($err, '', "$label: no diagnostic");
    unlike($out, qr/192\.0\.2|198\.51\.100|hme0|SECRET|10\.0\.0\.1/, "$label: addresses/interface data redacted");
}
sub bad {
    my ($label, $source, $input) = @_;
    my ($rc, $out, $err) = run_source($source, $input);
    is($rc, 3, "$label: failure code");
    is($out, '', "$label: no partial header or rows");
    like($err, qr/^firewall-config-audit: malformed or unsupported firewall snapshot\n\z/,
         "$label: stable private diagnostic");
}

my @sources = qw(solaris-pf-service solaris-pf-rules solaris-ipf-service solaris-ipf-rules4 solaris-ipf-rules6);
my @states = qw(online offline disabled degraded maintenance uninitialized legacy_run);
for my $state (@states) {
    for my $which (['solaris-pf-service','pf'], ['solaris-ipf-service','ipfilter']) {
        good("SMF $which->[0] $state", $which->[0], "$state\n",
            "$which->[1]\tservice\t" . uc($state) . "\t-\t-\t-\t-\t-\n");
    }
}
# The presence of loaded PF rules is NOT equivalent to SMF ONLINE, and
# DEGRADED can involve Oracle's fallback/default firewall policy.
my $pf = "empty list for firewall(out)\npass in quick on hme0 from 192.0.2.1 to any\nblock drop in on hme0 all\nanchor \"ssh/*\" all\n";
good('Oracle PF root listing', 'solaris-pf-rules', $pf,
     "pf\truntime\tPARTIAL\t-\troot\tfilter\t-\t2\npf\truntime\tPARTIAL\t-\troot\tanchors\t-\t1\n");
good('PF empty-list marker only', 'solaris-pf-rules', "empty list for firewall(out)\n",
     "pf\truntime\tPARTIAL\t-\troot\tfilter\t-\t0\npf\truntime\tPARTIAL\t-\troot\tanchors\t-\t0\n");
good('PF blank root is partial, not disabled', 'solaris-pf-rules', "\n",
     "pf\truntime\tPARTIAL\t-\troot\tfilter\t-\t0\npf\truntime\tPARTIAL\t-\troot\tanchors\t-\t0\n");

my $ipf = "empty list for ipfilter(out)\npass in quick on hme0 from 192.0.2.0/24 to any\nblock in log all\n";
good('IPFilter IPv4 rules', 'solaris-ipf-rules4', $ipf,
     "ipfilter\truntime\tPARTIAL\tinet\tactive\tin\t-\t2\nipfilter\truntime\tPARTIAL\tinet\tactive\tout\t-\t0\n");
good('IPFilter IPv6 rules', 'solaris-ipf-rules6', "pass out quick all\nblock in all\n",
     "ipfilter\truntime\tPARTIAL\tinet6\tactive\tin\t-\t1\nipfilter\truntime\tPARTIAL\tinet6\tactive\tout\t-\t1\n");
good('IPFilter numeric rule prefix', 'solaris-ipf-rules4', "\@1 pass in all\n\@2 block out all\n",
     "ipfilter\truntime\tPARTIAL\tinet\tactive\tin\t-\t1\nipfilter\truntime\tPARTIAL\tinet\tactive\tout\t-\t1\n");
good('IPFilter both lists empty', 'solaris-ipf-rules4', "empty list for ipfilter(in)\nempty list for ipfilter(out)\n",
     "ipfilter\truntime\tPARTIAL\tinet\tactive\tin\t-\t0\nipfilter\truntime\tPARTIAL\tinet\tactive\tout\t-\t0\n");
good('IPFilter CRLF', 'solaris-ipf-rules4', "block in all\r\npass out all\r\n",
     "ipfilter\truntime\tPARTIAL\tinet\tactive\tin\t-\t1\nipfilter\truntime\tPARTIAL\tinet\tactive\tout\t-\t1\n");

my ($rc, $out, $err) = run_source('solaris-pf-rules', $pf, '--null');
is($rc, 0, 'PF Solaris NUL output succeeds');
is(scalar(() = $out =~ /\0/g), 16, 'PF Solaris two rows, eight NUL fields each');
unlike($out, qr/ENGINE|192\.0\.2|hme0/, 'PF Solaris NUL reveals no private data');
like($out, qr/\0\z/, 'PF Solaris last field terminated');
is($err, '', 'PF Solaris NUL no stderr');
($rc, $out, $err) = cli('--help');
is($rc, 0, 'help succeeds');
like($out, qr/solaris-pf-service.*solaris-pf-rules.*solaris-ipf-service/s, 'help documents Solaris sources');

# Unknown grammar must NOT be tolerated merely because another valid line
# preceded it. No partially verified summary may escape on stdout.
for my $c (
    ['SMF multiple states', 'solaris-pf-service', "online\noffline\n"],
    ['SMF trailing garbage', 'solaris-pf-service', "online\nSECRET\n"],
    ['SMF unsupported state', 'solaris-ipf-service', "running\n"],
    ['SMF wrong case framing', 'solaris-ipf-service', "state: online\n"],
    ['SMF blank', 'solaris-pf-service', "\n"],
    ['PF unrecognized rule', 'solaris-pf-rules', "pass in all\nSECRET\n"],
    ['PF marker duplication', 'solaris-pf-rules', "empty list for firewall(out)\nempty list for firewall(out)\n"],
    ['PF partial last line', 'solaris-pf-rules', "pass in all"],
    ['IPF direction absent', 'solaris-ipf-rules4', "pass quick all\n"],
    ['IPF conflicting empty out', 'solaris-ipf-rules4', "empty list for ipfilter(out)\npass out all\n"],
    ['IPF duplicate empty', 'solaris-ipf-rules4', "empty list for ipfilter(in)\nempty list for ipfilter(in)\n"],
    ['IPF inactive snapshot', 'solaris-ipf-rules4', "empty list for inactive ipfilter(out)\n"],
    ['IPF empty ambiguous', 'solaris-ipf-rules6', "\n"],
    ['IPF hidden data', 'solaris-ipf-rules6', "pass in all\nSECRET\n"],
    ['IPF partial last line', 'solaris-ipf-rules4', "pass in all"],
    ['IPF direction token collision', 'solaris-ipf-rules4', "block incoming all\n"],
) { bad(@$c); }

# Multiple independent hostile-input checks for every source.
for my $source (@sources) {
    for my $payload ("", "\0\n", "\x01\n", "\x7f\n", "\e[2J\n", "online\r", "pass in\rout\n", "broken") {
        bad("framing $source ".unpack('H*',$payload), $source, $payload);
    }
}

# Public parser API and dispatch boundary; the Solaris parser is independent
# of Linux/BSD parsers despite preserving their eight-field presentation.
for my $source (@sources) {
    my $v = eval { parse_solaris_snapshot([], $source); 1 };
    ok(!$v && $@, "$source rejects object instead of snapshot string");
    $v = eval { parse_snapshot("\0\n", $source); 1 };
    ok(!$v && $@, "$source dispatcher rejects binary/control input");
}
my $bad_source = eval { parse_solaris_snapshot("online\n", 'ufw-status'); 1 };
ok(!$bad_source && $@, 'Solaris parser refuses Linux grammar');

if ($^O eq 'linux' || $^O eq 'darwin') {
    for my $source (@sources) {
        ($rc, $out, $err) = cli('--source', $source);
        is($rc, 3, "$source native denied on unsupported OS");
        is($out, '', "$source native denial emits no header");
        like($err, qr/unsupported on this OS/, "$source native denial explicit");
    }
}

my $too_big = " " x (8 * 1024 * 1024 + 1);
($rc, $out, $err) = run_source('solaris-pf-rules', $too_big);
is($rc, 3, 'Solaris bound rejects oversized snapshot');
is($out, '', 'Solaris bound never outputs partial results');
like($err, qr/exceeds byte limit/, 'Solaris bound explains general size limit');

done_testing();
