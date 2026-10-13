#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Test macOS-specific logic on any host; actual macOS CI is still required.
# No external account-management backends are executed by these tests.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $base = File::Spec->rel2abs("$FindBin::Bin/..");
my $temp = tempdir('sasd-macos-compat-XXXXXXXX', TMPDIR=>1, CLEANUP=>1);
my $passwd = File::Spec->catfile($temp,'passwd');
open my $data, '>', $passwd or die "fixture: $!";
print {$data} "testacct:x:501:501:Test Account:$temp:/bin/sh\n";
close $data or die "fixture close: $!";

# $^O is per-interpreter. Set it before loading the tested script so the
# platform logic is covered on Ubuntu as well as in the macOS CI runner.
my $eval_script = '$^O = shift @ARGV; $0 = shift @ARGV; do $0 or die ($@ || $!);';
sub run_as {
    my ($platform, $script, @args) = @_;
    my $path = File::Spec->catfile($base,$script);
    my $error = gensym();
    my $pid = open3(undef, my $out, $error,
        $^X, '-e', $eval_script, $platform, $path, @args);
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$error> // '';
    close $out; close $error;
    waitpid($pid,0);
    return ($stdout, $? >> 8, $stderr);
}

my ($out,$rc,$err)=run_as('darwin','sbin/account-manage',
    '--action','user-create','--name','sasd_unittest_mac');
is($rc,3,'Darwin refuses Linux user creation even in dry run');
like($err,qr/Linux-only/,'Darwin refusal explains unsupported platform');
unlike($out,qr/Planned command/,'Darwin never suggests native Linux mutation');

($out,$rc,$err)=run_as('darwin','sbin/account-manage',
    '--action','group-create','--name','sasd_unittest_mac');
is($rc,3,'Darwin refuses Linux group creation even in dry run');
like($err,qr/Linux-only/,'Darwin group error is explicit');

($out,$rc,$err)=run_as('darwin','sbin/account-manage',
    '--action','group-create','--name','sasd_unittest_mac','--apply');
is($rc,2,'missing confirmation is rejected before platform access');
like($err,qr/confirm-apply/,'missing confirmation has specific diagnostic');

($out,$rc,$err)=run_as('darwin','sbin/account-manage',
    '--action','group-create','--name','sasd_unittest_mac','--apply','--confirm-apply');
is($rc,3,'even confirmed Darwin apply is refused');
like($err,qr/Linux-only/,'confirmed apply never looks for system backend');

($out,$rc,$err)=run_as('darwin','sbin/account-manage','--help');
is($rc,0,'Darwin help remains available');

($out,$rc,$err)=run_as('darwin','bin/account-inventory','--kind','users');
is($rc,0,'Darwin account inventory defaults to NSS');
like($err,qr/NSS enumeration is not a completeness guarantee/,
    'default inventory communicates NSS completeness warning');

($out,$rc,$err)=run_as('darwin','bin/account-inventory',
    '--kind','users','--passwd-file',$passwd);
is($rc,0,'explicit passwd fixture automatically selects local source on Darwin');
like($out,qr/\Qtestacct\E\t501\t501/,'Darwin fixture user parsed');
unlike($err,qr/NSS enumeration/,'file override is not silently treated as NSS');

($out,$rc,$err)=run_as('darwin','bin/home-audit',
    '--min-uid','4294967295','--max-uid','4294967295');
is($rc,0,'Darwin home audit uses NSS without scanning unrelated paths');
like($err,qr/NSS enumeration can omit/,'Darwin home scan warns about completeness');
like($out,qr/Accounts checked: 0\n/,'high UID filter safely excludes service accounts');

($out,$rc,$err)=run_as('darwin','bin/home-audit','--file',$passwd);
is($rc,0,'Darwin home audit accepts an explicit local passwd fixture');
unlike($err,qr/NSS enumeration/,'local home scan does not claim NSS enumeration');

($out,$rc,$err)=run_as('darwin','bin/home-audit','--source','nss','--file',$passwd);
is($rc,2,'Darwin rejects contradictory NSS and file arguments');

($out,$rc,$err)=run_as('darwin','bin/quota-status','--all');
is($rc,3,'quota-status remains explicitly Linux-only');

ok(-f $passwd,'test fixture remains unchanged');
done_testing();
