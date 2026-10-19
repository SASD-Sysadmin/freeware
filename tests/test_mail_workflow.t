#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M6.4: cross-command regression for the mail diagnostics contract.
# Only artificial fixture files are read. No Postfix binary, server, root,
# external network, queue mutation or actual message is required.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3;
use Symbol qw(gensym);

my $root = File::Spec->rel2abs("$FindBin::Bin/..");
my $bin = File::Spec->catdir($root, 'bin');
my $tmp = tempdir('sasd-mail-workflow-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);

sub write_fixture {
    my ($name, $data) = @_;
    my $path = File::Spec->catfile($tmp, $name);
    open my $out, '>', $path or die "cannot prepare fixture: $!";
    binmode $out;
    print {$out} $data or die "cannot write fixture: $!";
    close $out or die "cannot close fixture: $!";
    return $path;
}

sub run_tool {
    my ($tool, @args) = @_;
    my $path = File::Spec->catfile($bin, $tool);
    my $err = gensym();
    # Explicit executable/argv, never a shell; use perl interpreter so that
    # local filesystem execute modes do not affect fixture-only testing.
    my $pid = open3(my $in, my $out, $err, $^X, $path, @args);
    close $in;
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    close $out;
    close $err;
    waitpid($pid, 0);
    return (($? & 127) ? -1 : $? >> 8, $stdout, $stderr);
}

for my $tool (qw(mail-probe mail-queue mail-config-audit)) {
    my ($rc, $out, $err) = run_tool($tool, '--help');
    is($rc, 0, "$tool: help works offline");
    like($out, qr/^Usage: \Q$tool\E/m, "$tool: usage contract");
    is($err, '', "$tool: no help diagnostics");
    ($rc, $out, $err) = run_tool($tool, '--version');
    is($rc, 0, "$tool: version works offline");
    like($out, qr/^\Q$tool\E \d+\.\d+\.\d+\n\z/, "$tool: SemVer contract");
    is($err, '', "$tool: no version diagnostics");
    ($rc, $out) = run_tool($tool, '--not-an-option');
    is($rc, 2, "$tool: malformed command line is exit 2");
    is($out, '', "$tool: malformed command has no success report");
}

# An explicit, synthetic configuration. Dynamic defaults and service-level
# overrides still cannot be proven correct by a purely static parser.
my $good_main = write_fixture('good-main.cf', <<'CFG');
myhostname = placeholder.example.test
mynetworks = 127.0.0.0/8 [::1]/128
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
smtpd_sasl_auth_enable = yes
smtpd_tls_auth_only = yes
smtpd_tls_security_level = may
CFG
my $master = write_fixture('master.cf', <<'CFG');
smtp      inet  n       -       y       -       -       smtpd
submission inet n       -       y       -       -       smtpd
  -o smtpd_tls_security_level=encrypt
CFG
my ($rc, $out, $err) = run_tool('mail-config-audit', '--main', $good_main, '--master', $master);
is($rc, 0, 'synthetic explicitly guarded main.cf has no definite ISSUE');
like($out, qr/^LEVEL\tSOURCE\tLINE\tCODE\n/, 'config report schema stable');
like($out, qr/service-override-requires-review/, 'master service override is not silently certified');
like($out, qr/runtime-defaults-maps-and-tls-not-verified/, 'runtime limitations stay visible');
unlike($out, qr/placeholder\.example\.test/, 'config never prints private hostname');
is($err, '', 'normal static notes are not stderr errors');

my $bad_main = write_fixture('bad-main.cf', <<'CFG');
myhostname = PRIVATE-HOST.internal.example
mynetworks = 0.0.0.0/0
smtpd_relay_restrictions = permit, reject_unauth_destination
smtpd_sasl_auth_enable = yes
smtpd_tls_security_level = may
CFG
($rc, $out, $err) = run_tool('mail-config-audit', '--main', $bad_main);
is($rc, 1, 'multiple unsafe explicit settings produce finding status');
like($out, qr/mynetworks-matches-all-addresses/, 'broad network trust detected');
like($out, qr/unconditional-permit-before-relay-boundary/, 'unconditional permit before guard detected');
like($out, qr/sasl-auth-may-be-offered-without-tls/, 'potential plaintext SASL detected');
unlike($out . $err, qr/PRIVATE-HOST|internal\.example/, 'config private data not exposed');

($rc, $out, $err) = run_tool('mail-config-audit', '--main', $bad_main, '--null');
is($rc, 1, 'config NUL format preserves negative status');
my @config_fields = split(/\0/, $out, -1);
is($config_fields[-1], '', 'config NUL format has final separator');
my $config_count = @config_fields - 1;
ok($config_count % 4 == 0, 'config NUL format emits four-field records');
my @config_records;
for (my $idx = 0; $idx < $config_count; $idx += 4) {
    push @config_records, [@config_fields[$idx..$idx+3]];
}
ok((grep { $_->[0] eq 'SUMMARY' } @config_records) == 1, 'one config NUL summary');
unlike($out, qr/PRIVATE-HOST|internal\.example/, 'NUL report never discloses private settings');

# Only synthetic Postfix JSON lines; no queue is accessed or modified.
my $safe_queue = write_fixture('empty-queue.jsonl', '');
($rc, $out, $err) = run_tool('mail-queue', '--input', $safe_queue);
is($rc, 0, 'empty synthetic queue is healthy');
like($out, qr/^TOTAL\t0\t0\t0$/m, 'zero totals explicit');
is($err, '', 'empty queue no diagnostic');

my $queue = write_fixture('mixed-queue.jsonl', <<'JSONL');
{"queue_name":"active","queue_id":"SECRET-QUEUE-A","arrival_time":1700000000,"message_size":100,"sender":"private-sender@example.test","recipients":[{"address":"private-a@example.test"}]}
{"queue_name":"deferred","queue_id":"SECRET-QUEUE-D","arrival_time":1700000001,"message_size":200,"sender":"private-sender@example.test","recipients":[{"address":"private-b@example.test"}]}
JSONL
($rc, $out, $err) = run_tool('mail-queue', '--input', $queue);
is($rc, 1, 'deferred synthetic queue is a finding');
like($out, qr/^deferred\t1\t200\t1$/m, 'deferred queue report correct');
like($out, qr/^TOTAL\t2\t300\t2$/m, 'aggregate total correct');
unlike($out . $err, qr/SECRET-QUEUE|private-|\@example\.test/, 'queue metadata remains confidential');

($rc, $out, $err) = run_tool('mail-queue', '--input', $queue, '--null');
is($rc, 1, 'queue NUL format preserves finding status');
my @queue_fields = split(/\0/, $out, -1);
is(scalar(@queue_fields), 29, 'queue emits seven four-field records and terminating NUL');
unlike($out . $err, qr/SECRET-QUEUE|private-|\@example\.test/, 'queue NUL output remains confidential');

my $invalid_queue = write_fixture('truncated.jsonl', '{"queue_name":"active"');
($rc, $out, $err) = run_tool('mail-queue', '--input', $invalid_queue);
is($rc, 3, 'truncated queue data is prerequisite/protocol error');
is($out, '', 'truncated input never outputs partial healthy queue');
unlike($err, qr/SECRET-QUEUE|private-/, 'truncated queue error sanitized');

# mail-probe's verified SMTP/TLS behavior is covered by test_mail_probe.t;
# here we assert invalid invocations cannot trigger network interactions.
($rc, $out, $err) = run_tool('mail-probe', '--host', 'bad/host');
is($rc, 2, 'invalid SMTP target rejected before socket or TLS loading');
is($out, '', 'invalid SMTP target has no report');
($rc, $out, $err) = run_tool('mail-probe', '--host', 'localhost', '--port', '0');
is($rc, 2, 'invalid SMTP port rejected before network');
is($out, '', 'invalid SMTP port has no report');

for my $name (qw(MAIL-ACCEPTANCE.md MAIL-ACCEPTANCE.de.md)) {
    ok(-f File::Spec->catfile($root, 'docs', $name), "bilingual acceptance runbook: $name");
}

done_testing();
