#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M8.4.2 – Deterministic BSD firewall contract, portability and hostility tests.
#
# No test runs pfctl, ipfw or npfctl, opens /dev/pf, or requires root. All
# snapshots are synthetic and are replayed through the SAME public CLI used
# on BSD. Tests additionally exercise the pure module's independent API.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use IPC::Open3;
use Symbol qw(gensym);
use lib "$FindBin::Bin/../lib";
use SASD::Freeware::FirewallBSD qw(parse_bsd_snapshot);
use SASD::Freeware::FirewallAudit qw(parse_snapshot);

my $tool = "$FindBin::Bin/../bin/firewall-config-audit";
my $tmp = tempdir('sasd-firewall-bsd-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $seq = 0;
my $header = "ENGINE\tSCOPE\tSTATE\tFAMILY\tTABLE\tCHAIN\tPOLICY\tRULES\n";
sub snap {
    my ($text) = @_;
    my $path = "$tmp/" . ++$seq;
    open my $fh, '>', $path or die $!;
    binmode($fh);
    print {$fh} $text;
    close($fh) or die $!;
    return $path;
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
sub run {
    my ($source, $text, @extra) = @_;
    return cli('--source', $source, '--input', snap($text), @extra);
}
sub good {
    my ($label, $source, $data, $expected) = @_;
    my ($rc, $out, $err) = run($source, $data);
    is($rc, 0, "$label: returns success");
    is($out, $header . $expected, "$label: exact schema");
    is($err, '', "$label: no diagnostics");
    unlike($out, qr/192\.0\.2|SECRET|em0|wm0|ext_if/, "$label: input data redacted");
}
sub bad {
    my ($label, $source, $data) = @_;
    my ($rc, $out, $err) = run($source, $data);
    is($rc, 3, "$label: fail closed");
    is($out, '', "$label: no partial header or rows");
    like($err, qr/\Afirewall-config-audit: malformed or unsupported firewall snapshot\n\z/,
         "$label: deterministic private diagnostic");
}

my $pf_active = "Status: Enabled for 1 days 00:00:00         Debug: Urgent\nState Table                          Total             Rate\n";
my $pf_off = "Status: Disabled\n";
my $pf_rules = "pass in on em0 proto tcp from 192.0.2.1 to any port 22\nblock drop out all\nmatch in all\nanchor \"authpf/*\" all\n";
my $pf_zero = "\n";
my $ipfw = "00100 allow ip from any to any via lo0\n00100 deny tcp from 192.0.2.1 to any 25\n65535 deny ip from any to any\n";
my $npf_new = "# filtering:    active\n# config:       loaded\n\nprocedure \"log\"\ngroup \"external\" on wm0 { # id=\"1\"\n  pass stateful out final all # id=\"2\"\n  block final all # id=\"3\"\n}\n";
my $npf_old = "Filtering:\tinactive\nConfiguration:\tloaded\n\ngroup default {\n block all\n}\n";
my $npf_empty = "# filtering: inactive\n# config: empty\n";

good('PF active runtime', 'pf-info', $pf_active, "pf\truntime\tACTIVE\t-\t-\t-\t-\t-\n");
good('PF disabled runtime', 'pf-info', $pf_off, "pf\truntime\tINACTIVE\t-\t-\t-\t-\t-\n");
good('PF partial main rules', 'pf-rules', $pf_rules,
     "pf\truntime\tPARTIAL\t-\tmain\tfilter\t-\t3\npf\truntime\tPARTIAL\t-\tmain\tanchors\t-\t1\n");
good('PF zero rules not disabled', 'pf-rules', $pf_zero,
     "pf\truntime\tPARTIAL\t-\tmain\tfilter\t-\t0\npf\truntime\tPARTIAL\t-\tmain\tanchors\t-\t0\n");
good('IPFW static lines', 'ipfw-list', $ipfw,
     "ipfw\truntime\tPARTIAL\t-\t-\tstatic\t-\t3\n");
good('IPFW empty listing', 'ipfw-list', "\n",
     "ipfw\truntime\tPARTIAL\t-\t-\tstatic\t-\t0\n");
good('NPF modern headers', 'npf-show', $npf_new,
     "npf\truntime\tACTIVE\t-\t-\t-\t-\t-\nnpf\tconfiguration\tLOADED\t-\t-\t-\t-\t-\n");
good('NPF legacy headers', 'npf-show', $npf_old,
     "npf\truntime\tINACTIVE\t-\t-\t-\t-\t-\nnpf\tconfiguration\tLOADED\t-\t-\t-\t-\t-\n");
good('NPF empty configuration', 'npf-show', $npf_empty,
     "npf\truntime\tINACTIVE\t-\t-\t-\t-\t-\nnpf\tconfiguration\tEMPTY\t-\t-\t-\t-\t-\n");
good('NPF active but empty', 'npf-show', "# filtering: active\n# config: empty\n",
     "npf\truntime\tACTIVE\t-\t-\t-\t-\t-\nnpf\tconfiguration\tEMPTY\t-\t-\t-\t-\t-\n");

my ($rc, $out, $err) = run('pf-rules', $pf_rules, '--null');
is($rc, 0, 'NUL serialization success');
is(scalar(() = $out =~ /\0/g), 16, 'two rows of eight NUL fields');
unlike($out, qr/ENGINE|192\.0\.2/, 'NUL mode has no header or rule content');
like($out, qr/\0\z/, 'last NUL field complete');
is($err, '', 'NUL mode no stderr');
($rc, $out, $err) = cli('--help');
is($rc, 0, 'help succeeds');
like($out, qr/pf-info.*pf-rules.*ipfw-list.*npf-show/s, 'help documents BSD sources');

# Full-input atomicity: inject a malformed trailing item AFTER a valid row.
# The CLI must not emit even the TSV header before discovering the error.
my @bad = (
    ['pf status absent', 'pf-info', "Info: Enabled\n"],
    ['pf status ambiguous', 'pf-info', "Status: Maybe\n"],
    ['pf status duplicate', 'pf-info', "Status: Enabled\nStatus: Disabled\n"],
    ['pf rules unknown syntax', 'pf-rules', "pass in all\nSECRET_TOKEN\n"],
    ['pf rules truncated', 'pf-rules', 'pass in all'],
    ['pf rules CR only', 'pf-rules', "pass in all\r\nblock all\r"],
    ['pf rules NUL', 'pf-rules', "pass all\n\0block all\n"],
    ['pf rules control', 'pf-rules', "pass all\n\x1b[2J\n"],
    ['pf rules tab after action', 'pf-rules', "pass all\nunknown table\n"],
    ['IPFW invalid label', 'ipfw-list', "00100 pass ip from any to any\nbad-rule\n"],
    ['IPFW negative ID', 'ipfw-list', "-1 allow ip from any to any\n"],
    ['IPFW non-numeric', 'ipfw-list', "000x0 allow ip from any to any\n"],
    ['IPFW out of range', 'ipfw-list', "65536 allow ip from any to any\n"],
    ['IPFW no statement', 'ipfw-list', "00010 \n"],
    ['IPFW truncated', 'ipfw-list', "00010 allow ip from any to any"],
    ['IPFW excessive digits', 'ipfw-list', "000010 allow ip from any to any\n"],
    ['IPFW control', 'ipfw-list', "00010 allow ip from any to any\n\x07"],
    ['NPF absent state', 'npf-show', "# config: loaded\n"],
    ['NPF unsupported state', 'npf-show', "# filtering: waiting\n# config: loaded\n"],
    ['NPF missing configuration', 'npf-show', "# filtering: active\n"],
    ['NPF unsupported configuration', 'npf-show', "# filtering: active\n# config: unknown\n"],
    ['NPF mixed header dialects', 'npf-show', "Filtering: active\n# config: loaded\n"],
    ['NPF duplicate filtering', 'npf-show', "$npf_new# filtering: inactive\n"],
    ['NPF duplicate configuration', 'npf-show', "$npf_new# config: empty\n"],
    ['NPF empty with block', 'npf-show', "# filtering: inactive\n# config: empty\nblock all\n"],
    ['NPF trailing partial line', 'npf-show', "# filtering: active\n# config: loaded\nSECRET_TOKEN"],
    ['NPF embedded NUL', 'npf-show', "# filtering: active\n# config: loaded\n\0"],
);
for my $case (@bad) { bad(@$case); }

# Attack families applied to every adapter at the same public boundary.
for my $source (qw(pf-info pf-rules ipfw-list npf-show)) {
    for my $payload ("", "\x00\n", "\x7f\n", "\x01\n", "\r", "abc\rdef\n") {
        bad("common framing $source (" . unpack('H*', $payload) . ')', $source, $payload);
    }
}

# Module API is also tested to ensure consumers cannot bypass bounds checks.
for my $source (qw(pf-info pf-rules ipfw-list npf-show)) {
    my $invalid = eval { parse_bsd_snapshot([], $source); 1 };
    ok(!$invalid && $@, "module rejects reference payload for $source");
    $invalid = eval { parse_snapshot("\x00\n", $source); 1 };
    ok(!$invalid && $@, "dispatcher rejects control payload for $source");
}
my $reject_source = eval { parse_bsd_snapshot("Status: Enabled\n", 'ufw-status'); 1 };
ok(!$reject_source && $@, 'BSD module rejects Linux grammar');

# Verify the native guard on known non-BSD CI systems. The tool must NEVER
# invoke BSD utilities merely because they happen to be installed on Linux.
if ($^O eq 'linux' || $^O eq 'darwin') {
    for my $source (qw(pf-info pf-rules ipfw-list npf-show)) {
        ($rc, $out, $err) = cli('--source', $source);
        is($rc, 3, "native $source not claimed supported on this platform");
        is($out, '', "native $source no misleading output");
        like($err, qr/unsupported on this OS/, "native $source explicit diagnostic");
    }
}

# Prevent unbounded memory/data growth regardless of the adapter selected.
my $big = " " x (8 * 1024 * 1024 + 1);
($rc, $out, $err) = run('pf-rules', $big);
is($rc, 3, 'oversized data rejected');
is($out, '', 'oversized data has no output');
like($err, qr/exceeds byte limit/, 'oversized input has safe error');

# Existing v1 Linux parser should still be routed to its original module.
my $linux = parse_snapshot("ENABLED=yes\n", 'ufw-config');
is($linux->[0][0], 'ufw', 'Linux source dispatched unchanged');

done_testing();
