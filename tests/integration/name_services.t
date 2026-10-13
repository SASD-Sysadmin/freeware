#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Opt-in integration checks with actual UDP DNS and TLS/LDAP client-server exchange.
# The protocol fixtures are loopback-only and the trust anchor is temporary.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3;
use Symbol qw(gensym);
use Sys::Hostname qw(hostname);
use lib "$FindBin::Bin/../../lib";
use SASD::Freeware::External qw(find_program);

my $root = File::Spec->rel2abs("$FindBin::Bin/../..");
my $fixtures = File::Spec->catfile($FindBin::Bin, 'local_servers.py');
my $python = find_program('python3');
my $dig = find_program('dig');
my $ldapsearch = find_program('ldapsearch');
my $openssl = find_program('openssl');
my $required_dns = $ENV{SASD_REQUIRE_DNS_INTEGRATION} // 0;
my $required_ldap = $ENV{SASD_REQUIRE_LDAP_INTEGRATION} // 0;
my $skip_ldap = $ENV{SASD_SKIP_LDAP_INTEGRATION} // 0;
BAIL_OUT('Contradictory LDAPS flags: required and skipped') if $required_ldap && $skip_ldap;

if ($required_dns && (!$python || !$dig)) {
    BAIL_OUT('DNS integration prerequisites are missing: Python 3 and dig are required');
}
if ($required_ldap && (!$python || !$ldapsearch || !$openssl)) {
    BAIL_OUT('LDAPS integration prerequisites are missing: Python 3, ldapsearch and openssl are required');
}
if (!$python) {
    plan skip_all => 'Python 3 is not installed (optional integration fixtures)';
}

sub command {
    my ($tool, $arguments, $environment) = @_;
    my $stderr = gensym();
    local %ENV = (%ENV, %{$environment // {}});
    my $pid = open3(undef, my $stdout, $stderr, $^X,
        File::Spec->catfile($root, 'bin', $tool), @$arguments);
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    close $stdout;
    close $stderr;
    waitpid($pid, 0);
    return ($out, $? >> 8, $err);
}

my $temp = tempdir('sasd-integration-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my ($cert, $key) = map { File::Spec->catfile($temp, $_) } ('cert.pem', 'key.pem');
my $tls_enabled = !!($openssl && $ldapsearch && !$skip_ldap);
if ($tls_enabled) {
    my $config = File::Spec->catfile($temp, 'openssl.cnf');
    open my $config_fh, '>', $config or die "$config: $!";
    # OpenLDAP may compare a canonicalized loopback hostname, not the URI label.
    # Include the host's own name alongside localhost in the ephemeral certificate.
    my $native_hostname = hostname();
    $native_hostname =~ /\A[A-Za-z0-9][A-Za-z0-9._-]{0,252}\z/
        or BAIL_OUT('unsafe or unexpected test host name; refusing to construct certificate');
    print {$config_fh} <<"CONFIG";
[req]
prompt = no
distinguished_name = dn
x509_extensions = v3_req
[dn]
CN = $native_hostname
[v3_req]
subjectAltName = DNS:localhost,DNS:$native_hostname,IP:127.0.0.1
basicConstraints = critical,CA:TRUE
keyUsage = critical,digitalSignature,keyEncipherment,keyCertSign
extendedKeyUsage = serverAuth
CONFIG
    close $config_fh;
    my $pid = fork();
    defined $pid or die "cannot fork openssl: $!";
    if ($pid == 0) {
        open STDERR, '>', File::Spec->catfile($temp, 'openssl.log') or die $!;
        exec {$openssl} $openssl, 'req', '-new', '-x509', '-newkey', 'rsa:2048', '-nodes',
            '-days', '1', '-keyout', $key, '-out', $cert, '-config', $config;
        die "cannot exec openssl: $!";
    }
    waitpid($pid, 0);
    if ($? != 0) {
        BAIL_OUT('could not generate an ephemeral TLS certificate for the integration fixture') if $required_ldap;
        $tls_enabled = 0;
        diag('Skipping optional LDAPS checks: temporary TLS certificate generation failed');
    }
}

my @args = ($fixtures);
push @args, ('--cert', $cert, '--key', $key) if $tls_enabled;
my $server_stderr = gensym();
my $server_pid = open3(my $server_in, my $server_out, $server_stderr, $python, @args);
my $line = <$server_out>;
if (!defined($line) || $line !~ /\ADNS_PORT=(\d+) LDAP_PORT=(\d+)\s*\z/) {
    my $reason = <$server_stderr> // 'no fixture diagnostics';
    kill 'TERM', $server_pid;
    waitpid($server_pid, 0);
    BAIL_OUT("loopback fixture failed to start: $reason");
}
my ($dns_port, $ldap_port) = ($1, $2);
# END ensures the child cannot outlive the test process during normal or failed assertions.
END {
    my $original_status = $?;
    if (defined($server_pid) && $server_pid > 0) {
        kill 'TERM', $server_pid;
        waitpid($server_pid, 0);
    }
    $? = $original_status; # child SIGTERM must not change the test process exit status
}

SKIP: {
    skip 'dig is not available (DNS integration test optional)', 12 if !$dig;
    my @base = ('--server', '127.0.0.1', '--port', $dns_port, '--timeout', '2');
    my ($out, $rc, $err) = command('dns-query', ['--name', 'good.test', '--type', 'A', @base]);
    is($rc, 0, 'real dig resolves A from local UDP DNS service');
    like($out, qr/DNS status: NOERROR/, 'DNS success status parsed');
    like($out, qr/Answers: 1/, 'one DNS answer counted');
    like($out, qr/127\.0\.0\.42/, 'DNS response address surfaced');
    ($out, $rc, $err) = command('dns-query', ['--name', 'good.test', '--type', 'AAAA', @base]);
    is($rc, 0, 'real dig resolves AAAA from local UDP DNS service');
    like($out, qr/\:\:1/, 'IPv6 answer surfaced');
    ($out, $rc, $err) = command('dns-query', ['--name', 'missing.test', @base]);
    is($rc, 1, 'real dig NXDOMAIN is a diagnostic finding');
    like($out, qr/DNS status: NXDOMAIN/, 'NXDOMAIN is not swallowed');
    ($out, $rc, $err) = command('dns-query', ['--name', 'empty.test', @base]);
    is($rc, 1, 'real dig NOERROR/NODATA is not misclassified as success');
    like($out, qr/Answers: 0/, 'empty answer section is counted');
    ($out, $rc, $err) = command('dns-query', ['--name', 'good.test', '--server', '127.0.0.1', '--port', '65536']);
    is($rc, 2, 'invalid port is a usage error before reaching dig');
    ($out, $rc, $err) = command('dns-query', ['--name', 'good.test', '--server', '127.0.0.1', '--port', '53bad']);
    is($rc, 2, 'port option rejects embedded nonnumeric content');
}

SKIP: {
    skip 'LDAPS integration unavailable or explicitly disabled on this runner', 8
        if !$tls_enabled;
    ok($ldap_port > 0, 'loopback LDAPS test listener was started');
    my $uri = "ldaps://127.0.0.1:$ldap_port";
    my %tls = (LDAPTLS_CACERT => $cert, LDAPTLS_REQCERT => 'never');
    my ($out, $rc, $err) = command('ldap-probe', ['--uri', $uri, '--timeout', '3'], \%tls);
    is($rc, 0, 'real ldapsearch successfully performs TLS and LDAP rootDSE exchange')
        or diag("ldapsearch diagnostic: $err");
    like($out, qr/Query: anonymous LDAPS rootDSE/, 'probe reports the actual LDAP query scope');
    like($out, qr/^dn:\s*$/m, 'root DSE entry received');
    like($out, qr/supportedLDAPVersion: 3/, 'synthetic LDAP attribute decoded by native client');
    ($out, $rc, $err) = command('ldap-probe', ['--uri', $uri, '--timeout', '3'],
        {LDAPTLS_CACERT => File::Spec->catfile($temp, 'missing-ca.pem'), LDAPTLS_REQCERT => 'never'});
    is($rc, 1, 'untrusted TLS certificate is rejected even with weak caller environment');
    unlike($out, qr/^dn:\s*$/m, 'failed TLS trust never exposes a successful root DSE');
    ($out, $rc, $err) = command('ldap-probe', ['--uri', 'ldap://localhost:1234']);
    is($rc, 2, 'unencrypted LDAP URI is rejected before starting native client');
}

done_testing();
