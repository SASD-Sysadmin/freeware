#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M6.1 offline SMTP + real TLS fixtures; loopback only, no production server.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use IO::Socket::INET;
use IPC::Open3;
use Symbol qw(gensym);

my $script = "$FindBin::Bin/../bin/mail-probe";
my $tmp = tempdir('sasd-mail-probe-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
sub command {
    my (@args) = @_;
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, $^X, $script, @args);
    close $in;
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    close $out;
    close $err;
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}
my ($rc, $out, $err) = command('--help');
is($rc, 0, 'help returns success');
like($out, qr/STARTTLS/, 'help states TLS mode');
is($err, '', 'help has no stderr');
($rc, $out, $err) = command('--version');
is($rc, 0, 'version returns success');
is($out, "mail-probe 0.1.0\n", 'version follows convention');
for my $args ([], ['--host', ''], ['--host', '-evil'],
              ['--host', 'bad.example;touch /tmp/hacked'],
              ['--host', "foo\nbar"], ['--host', 'bad..name'],
              ['--host', 'localhost', '--port', '0'],
              ['--host', 'localhost', '--port', '65536'],
              ['--host', 'localhost', '--timeout', '31'],
              ['--host', 'localhost', '--timeout', '0'],
              ['--host', 'localhost', '--unknown']) {
    ($rc, $out) = command(@$args);
    is($rc, 2, 'reject invalid command syntax');
    is($out, '', 'no success output on invalid command');
}
($rc, $out) = command('--host','localhost','--ca-file','relative.pem');
is($rc, 3, 'invalid CA prerequisite explicitly rejected');

# Platform-specific TLS fixture policy: on macOS only, missing dependencies
# produce a visible SKIP of this isolated subtest. Linux must run every TLS
# fixture in CI. A present TLS backend is always tested; handshake failures
# can never be ignored or treated as success.
my $ssl_available = eval {
    require IO::Socket::SSL;
    IO::Socket::SSL->VERSION(2.009);
    1;
};
my $openssl_available = eval {
    # Check the executable without invoking a shell or leaking fixture data.
    my $pid = open(my $pipe, '-|', 'openssl', 'version');
    defined($pid) or die "cannot execute openssl";
    my $version = <$pipe>;
    my $closed = close($pipe);
    $closed && defined($version) && $version =~ /\A(?:OpenSSL|LibreSSL)\b/;
};
subtest 'SMTP and verified STARTTLS fixtures' => sub {
    if ($^O eq 'darwin' && (!$ssl_available || !$openssl_available)) {
        plan skip_all => 'macOS optional: IO::Socket::SSL >= 2.009 or openssl is unavailable; native TLS acceptance is still pending';
    }
    BAIL_OUT('IO::Socket::SSL >= 2.009 missing: Linux TLS fixtures are mandatory')
        unless $ssl_available;
    BAIL_OUT('openssl executable missing: Linux TLS fixtures are mandatory')
        unless $openssl_available;

# Create disposable self-signed certificates without bundling private keys.
# The SAN is essential: modern TLS must not accept CN-only name checks.
my $config = "$tmp/cert.cnf";
my $certificate = sub {
    my ($name, $san) = @_;
    open my $cfg, '>', $config or die $!;
    print {$cfg} "[req]\nprompt=no\ndistinguished_name=subject\nx509_extensions=v3_req\n";
    print {$cfg} "[subject]\nCN=$name\n[v3_req]\nsubjectAltName=$san\n";
    close $cfg;
    my ($key, $cert) = ("$tmp/$name.key", "$tmp/$name.crt");
    # No shell; certificate creation is a local test fixture, not mail probing.
    my $pid = fork(); defined $pid or die "fork: $!";
    if (!$pid) {
        open STDERR, '>', '/dev/null' or die $!;
        exec 'openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
            '-days', '2', '-keyout', $key, '-out', $cert,
            '-config', $config, '-extensions', 'v3_req';
        die "exec openssl: $!";
    }
    waitpid($pid, 0);
    is($? >> 8, 0, 'TLS fixture generated with openssl');
    return ($key, $cert);
};
my ($good_key, $good_cert) = $certificate->('localhost', 'IP:127.0.0.1,DNS:localhost');
my ($bad_key, $bad_cert) = $certificate->('wronghost', 'DNS:wronghost.test');

my $serve = sub {
    my (%opt) = @_;
    my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1',
        LocalPort => 0, Listen => 1, ReuseAddr => 1, Proto => 'tcp') or die $!;
    my $port = $listener->sockport;
    my $pid = fork(); defined $pid or die "fork: $!";
    if (!$pid) {
        eval {
            local $SIG{ALRM} = sub { die "server watchdog\n"; };
            alarm(10);
            my $sock = $listener->accept() or die 'accept failed';
            close $listener;
            binmode($sock);
            if ($opt{mode} && $opt{mode} eq 'timeout') {
                sleep(3); close($sock); exit 0;
            }
            if ($opt{mode} && $opt{mode} eq 'badbanner') {
                print {$sock} "220 ready\n"; close($sock); exit 0;
            }
            if ($opt{mode} && $opt{mode} eq 'oversize') {
                print {$sock} '220 ' . ('X' x 1024) . "\r\n";
                close($sock); exit 0;
            }
            if ($opt{mode} && $opt{mode} eq 'control') {
                print {$sock} "220 fixture\033[31m bad\r\n";
                close($sock); exit 0;
            }
            if ($opt{mode} && $opt{mode} eq 'refused') {
                print {$sock} "421 service temporarily unavailable\r\n";
                close($sock); exit 0;
            }
            print {$sock} "220 fixture ESMTP ready\r\n";
            scalar(<$sock>) =~ /\AEHLO sasd-probe\.invalid\r\n\z/
                or die 'wrong pre-TLS command';
            if ($opt{mode} && $opt{mode} eq 'no-starttls') {
                print {$sock} "250-fixture.test\r\n250 SIZE 1000\r\n";
                close($sock); exit 0;
            }
            if ($opt{mode} && $opt{mode} eq 'invalid-ehlo') {
                print {$sock} "250-fixture.test\r\n550 STARTTLS\r\n";
                close($sock); exit 0;
            }
            print {$sock} "250-fixture.test\r\n250-STARTTLS\r\n250 SIZE 1000\r\n";
            scalar(<$sock>) eq "STARTTLS\r\n" or die 'wrong TLS command';
            if ($opt{mode} && $opt{mode} eq 'tls-refused') {
                print {$sock} "454 TLS temporarily unavailable\r\n";
                close($sock); exit 0;
            }
            print {$sock} "220 Go ahead\r\n";
            my $tls = IO::Socket::SSL->start_SSL($sock,
                SSL_server => 1, SSL_cert_file => ($opt{cert} // $good_cert),
                SSL_key_file => ($opt{key} // $good_key));
            if ($tls) {
                scalar(<$tls>) eq "EHLO sasd-probe.invalid\r\n"
                    or die 'wrong post-TLS command';
                print {$tls} "250-fixture.test\r\n250-PIPELINING\r\n250 SIZE 1000\r\n";
                close($tls);
            }
            alarm(0);
        };
        exit 0; # Client exit status and output are the observable contract.
    }
    close $listener;
    return ($port, $pid);
};
my $probe = sub {
    my ($opt, @args) = @_;
    my ($port, $pid) = $serve->(%$opt);
    my @cmd = ('--host', '127.0.0.1', '--port', $port, '--timeout', 2,
               '--ca-file', $good_cert, @args);
    my @output = command(@cmd);
    waitpid($pid, 0);
    return @output;
};
($rc, $out, $err) = $probe->({});
is($rc, 0, 'correct certificate and STARTTLS accepted');
like($out, qr/verified-starttls/, 'verified TLS explicitly reported');
like($out, qr/PIPELINING,SIZE 1000/, 'post-TLS capabilities shown');
is($err, '', 'no diagnostics on successful probe');
($rc, $out, $err) = $probe->({}, '--null');
is($rc, 0, 'NUL output accepted');
like($out, qr/\A127\.0\.0\.1\000[0-9]+\000verified-starttls\000/, 'stable binary output');
unlike($out, qr/HOST\tPORT/, 'NUL output has no header');
($rc, $out, $err) = $probe->({ mode => 'no-starttls' });
is($rc, 1, 'no STARTTLS never silently downgraded');
is($out, '', 'no optimistic success on absent STARTTLS');
($rc, $out, $err) = $probe->({ mode => 'badbanner' });
is($rc, 3, 'LF-only SMTP banner is malformed');
is($out, '', 'no success on malformed banner');
($rc, $out, $err) = $probe->({ mode => 'oversize' });
is($rc, 3, 'oversized banner rejected');
($rc, $out, $err) = $probe->({ mode => 'invalid-ehlo' });
is($rc, 3, 'inconsistent multiline EHLO status rejected');
($rc, $out, $err) = $probe->({ mode => 'control' });
is($rc, 3, 'remote terminal-control injection rejected');
unlike($err, qr/\e/, 'remote control codes never reach stderr');
($rc, $out, $err) = $probe->({ mode => 'refused' });
is($rc, 1, 'remote 421 classified as negative result');
($rc, $out, $err) = $probe->({ mode => 'tls-refused' });
is($rc, 1, 'remote 454 TLS rejection classified as negative result');
($rc, $out, $err) = $probe->({ cert => $bad_cert, key => $bad_key });
is($rc, 1, 'hostname mismatch rejected');
is($out, '', 'hostname mismatch never prints success');
($rc, $out, $err) = $probe->({ cert => $bad_cert, key => $bad_key }, '--ca-file', $bad_cert);
is($rc, 1, 'trusted wrong-host certificate still rejected');
($rc, $out, $err) = $probe->({}, '--ca-file', $bad_cert);
is($rc, 1, 'unknown CA certificate rejected');
is($out, '', 'untrusted certificate produces no successful results');
($rc, $out, $err) = $probe->({ mode => 'timeout' }, '--timeout', 1);
is($rc, 3, 'silent SMTP server bounded by timeout');
like($err, qr/timed out/, 'timeout message bounded');
};
done_testing();
