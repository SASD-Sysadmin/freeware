#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Validate the common exit-status boundary for read-only name-service tools.
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $root = File::Spec->rel2abs("$FindBin::Bin/..");
sub run {
    my ($program, @arguments) = @_;
    my $err = gensym();
    my $pid = open3(undef, my $out, $err, $^X,
        File::Spec->catfile($root,'bin',$program), @arguments);
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    close $out;
    close $err;
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}

for my $program (qw(nss-lookup host-resolve ldap-probe nsswitch-audit dns-query nis-probe ldap-config-audit)) {
    my ($rc, $stdout, $stderr) = run($program, '--help');
    is($rc, 0, "$program: help returns 0");
    like($stdout, qr/Usage:/, "$program: help has usage details");
    ($rc, $stdout, $stderr) = run($program, '--version');
    is($rc, 0, "$program: version returns 0");
    like($stdout, qr/\Q$program\E/, "$program: version identifies the tool");
    ($rc, $stdout, $stderr) = run($program, '--sasd-unsupported-option');
    is($rc, 2, "$program: unknown option returns status 2");
}
my ($rc, $out, $err) = run('dns-query', '--name', 'good.test', '--port', '0');
is($rc, 2, 'invalid DNS port is a usage error, independent of dig installation');
($rc, $out, $err) = run('ldap-probe', '--uri', 'ldap://localhost');
is($rc, 2, 'plaintext LDAP remains a usage error, independent of ldapsearch installation');
($rc, $out, $err) = run('nss-lookup', '--uid', '4294967296');
is($rc, 2, 'invalid UID is a usage error');

done_testing();
