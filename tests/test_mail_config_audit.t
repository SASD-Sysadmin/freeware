#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Offline, mutation-free M6.3 checks. Never reads /etc/postfix or calls Postfix.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use File::Spec;
use IPC::Open3;
use Symbol qw(gensym);

my $tool = File::Spec->rel2abs("$FindBin::Bin/../bin/mail-config-audit");
my $dir = tempdir('sasd-mail-config-audit-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $main = "$dir/main.cf";
my $master = "$dir/master.cf";
sub write_file {
    my ($path, $data) = @_;
    open my $fh, '>', $path or die $!;
    binmode($fh);
    print {$fh} $data or die $!;
    close $fh or die $!;
}
sub run {
    my (@args) = @_;
    my $error = gensym;
    my $pid = open3(my $input, my $output, $error, $^X, $tool, @args);
    close($input);
    local $/;
    my $stdout = <$output> // '';
    my $stderr = <$error> // '';
    close($output);
    close($error);
    waitpid($pid, 0);
    return (($? & 127) ? -1 : $? >> 8, $stdout, $stderr);
}
sub audit {
    my ($content, @options) = @_;
    write_file($main, $content);
    return run('--main', $main, @options);
}
my ($rc, $out, $err) = run('--help');
is($rc, 0, 'help succeeds');
like($out, qr/^Usage: mail-config-audit /, 'help output contract');
is($err, '', 'help no stderr');
($rc, $out, $err) = run('--version');
is($rc, 0, 'version succeeds');
is($out, "mail-config-audit 0.1.0\n", 'version stable');
is($err, '', 'version no stderr');
for my $args (
    ['--bogus'], ['extra'], ['--main',''], ['--main','relative/main.cf'],
    ['--main',"/tmp/hello\nfoo"], ['--main','/tmp/../etc/postfix/main.cf'],
    ['--master','relative/master.cf'], ['--main','/missing/main.cf'],
    ['--main','/tmp/a\0b']
) {
    ($rc, $out, $err) = run(@$args);
    # Unknown CLI syntax = 2; invalid/missing pathname is prerequisite = 3.
    is($rc, ($args->[0] eq '--bogus' || $args->[0] eq 'extra') ? 2 : 3,
        'invalid request rejected with documented status');
    is($out, '', 'invalid request has no report');
}
($rc, $out, $err) = audit("smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination\n" .
                           "smtpd_sasl_auth_enable = yes\nsmtpd_tls_auth_only = yes\n" .
                           "smtpd_tls_security_level = may\n");
is($rc, 0, 'explicitly guarded relay and TLS-only AUTH cause no definite issue');
like($out, qr/^LEVEL\tSOURCE\tLINE\tCODE$/m, 'stable report heading');
like($out, qr/^Issues: 0$/m, 'no positive false alarm');
like($out, qr/master-cf-not-inspected/, 'omitted master.cf disclosed');
like($out, qr/runtime-defaults-maps-and-tls-not-verified/, 'runtime verification limitation disclosed');
is($err, '', 'normal review no stderr');

for my $case (
    ['open permit', "smtpd_relay_restrictions = permit, reject_unauth_destination\n", 'unconditional-permit-before-relay-boundary'],
    ['space separated', "smtpd_relay_restrictions = permit_mynetworks permit reject_unauth_destination\n", 'unconditional-permit-before-relay-boundary'],
    ['defer guard', "smtpd_relay_restrictions = permit, defer_unauth_destination\n", 'unconditional-permit-before-relay-boundary'],
    ['legacy relay', "smtpd_relay_restrictions =\nsmtpd_recipient_restrictions = permit, reject_unauth_destination\n", 'unconditional-permit-before-relay-boundary'],
    ['all v4 trusted', "mynetworks = 0.0.0.0/0\n", 'mynetworks-matches-all-addresses'],
    ['all v6 trusted', "mynetworks = [::1]/128 ::/0\n", 'mynetworks-matches-all-addresses'],
    ['all generic trusted', "mynetworks = 0/0\n", 'mynetworks-matches-all-addresses'],
    ['auth without tls', "smtpd_sasl_auth_enable = yes\nsmtpd_tls_security_level = may\n", 'sasl-auth-may-be-offered-without-tls'],
    ['auth with explicit no tls', "smtpd_sasl_auth_enable = yes\nsmtpd_tls_auth_only = no\n", 'sasl-auth-may-be-offered-without-tls'],
    ['auth without explicit tls', "smtpd_sasl_auth_enable = yes\n", 'sasl-auth-may-be-offered-without-tls'],
    ['duplicate assignments', "myhostname = host1.test\nmyhostname = host2.test\n", 'duplicate-parameter'],
    ['malformed assignment', "this is not a setting\n", 'malformed-assignment'],
    ['orphan continuation', "  smtpd_tls_auth_only=yes\n", 'orphan-continuation'],
) {
    my ($label, $data, $expected) = @$case;
    ($rc, $out, $err) = audit($data);
    is($rc, 1, "$label is a definite finding");
    like($out, qr/\Q$expected\E/, "$label code correct");
    is($err, '', "$label does not leak diagnostics");
}

for my $case (
    ['normal local trust', "mynetworks = 127.0.0.0/8 [::1]/128\n"],
    ['normal sasl setting no', "smtpd_sasl_auth_enable = no\n"],
    ['auth forced tls', "smtpd_sasl_auth_enable = yes\nsmtpd_tls_security_level = encrypt\n"],
    ['mixed case', "SMTPD_RELAY_RESTRICTIONS = permit_mynetworks,REJECT_UNAUTH_DESTINATION\n"],
    ['conditional normal', "smtpd_relay_restrictions = permit_sasl_authenticated, permit_mynetworks, defer_unauth_destination\n"],
    ['whitespace comment', "   # smtpd_relay_restrictions=permit\n"],
    ['inline sharp in value', "myhostname = x#y\n"],
    ['empty file', ''],
    ['default may TLS is not error', "smtpd_tls_security_level = may\n"],
) {
    my ($label, $data) = @$case;
    ($rc, $out, $err) = audit($data);
    is($rc, 0, "$label not falsely reported as a definite issue");
    like($out, qr/^Issues: 0$/m, "$label summary clean");
}

for my $case (
    ['unknown relay expansion', "smtpd_relay_restrictions = \${custom_relay_policy}\n", 'relay-policy-expansion-not-evaluated'],
    ['complex access maps', "smtpd_relay_restrictions = check_recipient_access hash:/x, reject_unauth_destination\n", 'relay-access-map-requires-review'],
    ['conditional permit', "smtpd_relay_restrictions = permit_dnswl_client local.test, reject_unauth_destination\n", 'complex-relay-permit-requires-review'],
    ['unproven relay boundary', "smtpd_relay_restrictions = permit_mynetworks\n", 'relay-boundary-not-provable'],
    ['empty relay policy', "smtpd_relay_restrictions =\n", 'empty-relay-policy-review-recipient-restrictions'],
    ['explicit subnet trust', "mynetworks_style = subnet\n", 'mynetworks-style-subnet-review-trust-boundary'],
    ['unknown mynetworks expansion', "mynetworks = \$myhosts\n", 'mynetworks-expansion-not-evaluated'],
    ['inbound none', "smtpd_tls_security_level = none\n", 'inbound-tls-explicitly-disabled'],
    ['outbound none', "smtp_tls_security_level = none\n", 'outbound-tls-explicitly-disabled'],
    ['VRFY enabled', "disable_vrfy_command = no\n", 'vrfy-command-enabled'],
    ['AUTH unknown setting', "smtpd_sasl_auth_enable = \$auth_mode\n", 'sasl-auth-setting-not-evaluated'],
) {
    my ($label, $data, $expected) = @$case;
    ($rc, $out, $err) = audit($data);
    is($rc, 0, "$label is a note, not a fabricated vulnerability");
    like($out, qr/\Q$expected\E/, "$label advisory code visible");
}
($rc, $out, $err) = audit("smtpd_relay_restrictions = permit_mynetworks,\n" .
                          "  permit_sasl_authenticated,\n  reject_unauth_destination\n");
is($rc, 0, 'Postfix continued relay policy parsed');
unlike($out, qr/orphan-continuation|relay-boundary-not-provable/, 'continuation associated with key');

($rc, $out, $err) = audit("smtpd_relay_restrictions = permit,\n  reject_unauth_destination\n", '--null');
is($rc, 1, 'NUL output retains issue status');
like($out, qr/\AISSUE\0main\0[0-9]+\0unconditional-permit-before-relay-boundary\0/, 'NUL record is four fields');
like($out, qr/SUMMARY\x00all\x000\x00issues=1,notes=/, 'NUL summary present');
unlike($out, qr/LEVEL\tSOURCE/, 'NUL format no TSV heading');

write_file($master, <<'MASTER');
smtp inet n - n - - smtpd
  -o smtpd_sasl_auth_enable=yes
  -o { smtpd_tls_security_level = encrypt }
# comment -o secret
submission inet n - n - - smtpd
  -o smtpd_tls_auth_only=yes
MASTER
($rc, $out, $err) = audit("smtpd_relay_restrictions=reject_unauth_destination\n", '--master', $master);
is($rc, 0, 'master overrides reported without alleging vulnerability');
my @overrides = ($out =~ /service-override-requires-review/g);
is(scalar(@overrides), 3, 'all service override lines explicitly noticed');
unlike($out, qr/secret|submission|smtp\s+inet/, 'service text never disclosed');
like($out, qr/master-configuration-not-semantically-evaluated/, 'partial master inspection disclosed');

write_file($master, "  -o smtpd_sasl_auth_enable=yes\nnot a service\n");
($rc, $out, $err) = audit('', '--master', $master);
like($out, qr/master-continuation-without-service/, 'orphan master continuation noticed');
like($out, qr/master-service-syntax-not-recognized/, 'unknown master syntax noticed');

for my $case (
    ['missing main', "$dir/does-not-exist", undef],
    ['missing master', $main, "$dir/missing-master"],
) {
    my ($label, $mp, $sp) = @$case;
    write_file($main, "myhostname=local.example\n");
    my @cmd = ('--main', $mp);
    push @cmd, ('--master', $sp) if defined $sp;
    ($rc, $out, $err) = run(@cmd);
    is($rc, 3, "$label is file prerequisite failure");
    is($out, '', "$label never publishes partial report");
}
write_file($main, "smtpd_relay_restrictions = reject_unauth_destination\n");
symlink($main, "$dir/link.cf") or die $!;
($rc, $out) = run('--main', "$dir/link.cf");
is($rc, 3, 'symlink main.cf rejected');
is($out, '', 'symlink not reported clean');
symlink($master, "$dir/link-master.cf") or die $!;
($rc, $out) = run('--main', $main, '--master', "$dir/link-master.cf");
is($rc, 3, 'symlink master.cf rejected');
is($out, '', 'symlink master cannot publish partial findings');

my $huge_input = ("myhostname=" . ("x" x 1000) . "\n") x 2100;
for my $case (
    ['NUL', "myhostname=ok\0bad\n", qr/invalid control byte/],
    ['control', "myhostname=hello\e[31m\n", qr/invalid control byte/],
    ['mixed CR', "myhostname=x\rjunk\n", qr/invalid line ending/],
    ['unterminated', 'myhostname=unterminated', qr/unterminated/],
    ['oversized line', "myhostname=" . ('X' x 16385) . "\n", qr/exceeds input limits/],
    ['too many lines', "# test\n" x 10001, qr/exceeds input limits/],
    ['too many bytes', $huge_input, qr/exceeds input limits/],
) {
    my ($label, $blob, $msg) = @$case;
    ($rc, $out, $err) = audit($blob);
    is($rc, 3, "$label invalid input rejected");
    is($out, '', "$label invalid input has no partial report");
    like($err, $msg, "$label diagnostic categorized");
    unlike($err, qr/X{50}|unterminated$|\e|myhostname=x/, "$label contents not echoed");
}

# Credentials, mail addresses and arbitrary raw values never enter stdout.
my $secret = 'this-is-a-top-secret-password@example.test';
($rc, $out, $err) = audit("smtpd_sasl_password_maps = $secret\n" .
    "mynetworks = 0.0.0.0/0\n" .
    "custom_setting = dangerous; $secret\n");
is($rc, 1, 'sensitive configuration test still identifies explicit defect');
unlike($out, qr/\Q$secret\E/, 'secrets absent from report');
unlike($err, qr/\Q$secret\E/, 'secrets absent from errors');

done_testing();
