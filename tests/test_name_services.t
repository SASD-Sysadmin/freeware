#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Offline name-service tests; no external DNS/LDAP servers or account writes.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $base=File::Spec->rel2abs("$FindBin::Bin/..");
my $temp=tempdir('sasd-name-services-XXXXXXXX', TMPDIR=>1,CLEANUP=>1);
sub run {
    my ($script,$args,$env)=@_;
    my $path=File::Spec->catfile($base,'bin',$script);
    my $err=gensym();
    local %ENV=(%ENV,%{ $env || {} });
    my $pid=open3(undef,my $out,$err,$^X,$path,@$args);
    local $/;
    my $stdout=<$out> // '';
    my $stderr=<$err> // '';
    close $out;close $err;waitpid($pid,0);
    return ($stdout, $? >> 8, $stderr);
}

for my $tool (qw(nss-lookup host-resolve ldap-probe)) {
    my ($out,$rc)=run($tool,['--help']);
    is($rc,0,"$tool help succeeds");
    like($out,qr/Usage: \Q$tool\E/,"$tool usage present");
    ($out,$rc)=run($tool,['--version']);
    is($rc,0,"$tool version succeeds");
    like($out,qr/^\Q$tool\E 0\.1\.0/,"$tool version identifies executable");
}

my ($out,$rc,$err)=run('nss-lookup',['--user','root']);
is($rc,0,'NSS root account resolved');
like($out,qr/\A(?:TYPE\tNAME\tUID\tGID\tHOME\tSHELL\tMEMBERS)\nuser\troot\t0\t/,
    'NSS user fields appear with expected UID');
($out,$rc,$err)=run('nss-lookup',['--uid','0','--null']);
is($rc,0,'NSS numeric root lookup succeeds');
my @cols=split /\0/,$out,-1;
is(scalar(@cols),8,'NUL output includes exactly seven fields and final NUL');
is($cols[0],'user','NUL output identifies user');
is($cols[2],'0','NUL output retains numeric UID');
($out,$rc)=run('nss-lookup',['--gid','0']);
is($rc,0,'NSS primary system group resolves by GID');
like($out,qr/\ngroup\t[^\t\n]+\t\t0\t/,'group GID represented in proper column');
my ($native_group)=(getgrgid(0));
SKIP: {
    skip 'host has no gid 0 name',1 if !defined $native_group;
    ($out,$rc)=run('nss-lookup',['--group',$native_group]);
    is($rc,0,'NSS named group lookup succeeds');
}
($out,$rc,$err)=run('nss-lookup',['--user','sasd_unknown_908214871']);
is($rc,1,'unresolved NSS name returns status 1');
like($err,qr/no user found/,'missing NSS identity is reported');
($out,$rc)=run('nss-lookup',['--uid','4294967296']);
is($rc,2,'UID overflow refused');
($out,$rc)=run('nss-lookup',['--user','root','--gid','0']);
is($rc,2,'ambiguous selector refused');
($out,$rc)=run('nss-lookup',['--user',"hi\nthere"]);
is($rc,2,'control character in name refused');
($out,$rc)=run('nss-lookup',[]);
is($rc,2,'missing selector refused');

($out,$rc,$err)=run('host-resolve',['--name','127.0.0.1','--family','ipv4']);
is($rc,0,'numeric forward IPv4 resolves offline');
like($out,qr/\nforward\tipv4\t127\.0\.0\.1\t127\.0\.0\.1\n/,
    'IPv4 output contains unambiguous fields');
($out,$rc)=run('host-resolve',['--name','127.0.0.1','--family','ipv4','--null']);
is($rc,0,'host resolver NUL mode succeeds');
like($out,qr/\Aforward\x00ipv4\x00127\.0\.0\.1\x00127\.0\.0\.1\x00\z/,
    'NUL output fields are properly terminated');
($out,$rc,$err)=run('host-resolve',['--address','127.0.0.1']);
ok($rc == 0 || $rc == 1,'reverse loopback is name-dependent but never a runtime error');
if ($rc == 0) { like($out,qr/\nreverse\tipv4\t127\.0\.0\.1\t/,'reverse result fields correct'); }
else { like($err,qr/no reverse name|no resolved records/,'missing reverse is distinguished'); }
($out,$rc)=run('host-resolve',['--address','not-an-ip']);
is($rc,1,'non-numeric reverse query rejected by numeric host resolver');
($out,$rc)=run('host-resolve',['--name','127.0.0.1','--family','bad']);
is($rc,2,'bad family rejected');
($out,$rc)=run('host-resolve',['--name','x','--address','127.0.0.1']);
is($rc,2,'two modes rejected');
($out,$rc)=run('host-resolve',['--address','127.0.0.1','--family','ipv4']);
is($rc,2,'family only accepted for forward resolution');
($out,$rc)=run('host-resolve',['--name',"evil\nname"]);
is($rc,2,'control characters refused in hostnames');

my $emptydir=File::Spec->catdir($temp,'empty');make_path($emptydir);
($out,$rc,$err)=run('ldap-probe',['--uri','ldaps://localhost'],{PATH=>$emptydir});
is($rc,3,'missing optional ldapsearch reports status 3');
like($err,qr/ldapsearch not found/,'missing backend error identifies prerequisite');

my $bindir=File::Spec->catdir($temp,'bin');make_path($bindir);
my $client=File::Spec->catfile($bindir,'ldapsearch');
my $argsfile=File::Spec->catfile($temp,'ldap-args');
open my $fake,'>',$client or die "cannot write mock client: $!";
print {$fake} "#!$^X\n";
print {$fake} <<'STUB';
use strict;
use warnings;
open my $args,'>',$ENV{SASD_LDAP_TEST_ARGS} or die 'args fixture unavailable';
print {$args} join("\0",@ARGV),"\0";
close $args;
if ($ENV{LDAPTLS_REQCERT} ne 'demand') { die 'certificate validation was not enforced'; }
if ($ENV{SASD_LDAP_TEST_FAIL}) { print STDERR "mock connection failed\n"; exit 7; }
if ($ENV{SASD_LDAP_TEST_EMPTY}) { exit 0; }
if ($ENV{SASD_LDAP_TEST_LARGE}) { print "dn:\n", ("X" x (1024*1024)); exit 0; }
print "dn:\nsupportedLDAPVersion: 3\nnamingContexts: dc=example,dc=test\n";
if ($ENV{SASD_LDAP_TEST_CONTROL}) { print "vendorName: Test\x1b[31m\n"; }
STUB
close $fake or die "cannot close mock client: $!";
chmod 0755,$client or die "cannot mark mock client executable: $!";
my %mock_env=(PATH=>$bindir,SASD_LDAP_TEST_ARGS=>$argsfile,LDAPTLS_REQCERT=>'never');
($out,$rc,$err)=run('ldap-probe',['--uri','ldaps://directory.example.test:636','--timeout','3'],\%mock_env);
is($rc,0,'valid LDAPS rootDSE probe succeeds with mock backend');
like($out,qr/namingContexts: dc=example,dc=test/,'rootDSE output captured');
like($out,qr/anonymous LDAPS rootDSE/,'tool describes read-only query');
open my $got,'<',$argsfile or die "cannot read arguments: $!";
{local $/;my $bytes=<$got>;my @args=split /\0/,$bytes;
 is_deeply([@args[0..5]],['-x','-H','ldaps://directory.example.test:636','-LLL','-o','nettimeout=3'],
    'backend receives fixed anonymous LDAPv3 options and validated URI');
 ok((grep { $_ eq 'base' } @args),'LDAP search uses base scope');
 ok((grep { $_ eq '(objectClass=*)' } @args),'fixed rootDSE filter only');
}
close $got;
($out,$rc,$err)=run('ldap-probe',['--uri','ldaps://directory.example.test'],{%mock_env,SASD_LDAP_TEST_FAIL=>1});
is($rc,1,'LDAP backend failure propagated as lookup failure');
like($err,qr/rootDSE query failed/,'backend failure explained');
($out,$rc,$err)=run('ldap-probe',['--uri','ldaps://directory.example.test'],{%mock_env,SASD_LDAP_TEST_EMPTY=>1});
is($rc,1,'empty successful LDAP response is not treated as rootDSE');
like($err,qr/no rootDSE entry/,'empty rootDSE is diagnosed');
($out,$rc,$err)=run('ldap-probe',['--uri','ldaps://directory.example.test'],{%mock_env,SASD_LDAP_TEST_LARGE=>1});
is($rc,3,'oversized LDAP response fails closed');
is($out,'','no truncated LDAP output reaches stdout');
($out,$rc,$err)=run('ldap-probe',['--uri','ldaps://directory.example.test'],{%mock_env,SASD_LDAP_TEST_CONTROL=>1});
is($rc,0,'LDAP output with remote control bytes is accepted as data');
unlike($out,qr/\x1b/,'remote terminal-control byte is not emitted literally');
like($out,qr/vendorName: Test\\x1B/,'remote terminal-control byte is escaped');
for my $bad ('ldap://directory.example.test',
             'ldaps://user:password@directory.example.test',
             'ldaps://directory.example.test??sub',
             'ldaps://directory.example.test:65536',
             'ldaps://directory.example.test;touch') {
    unlink $argsfile;
    ($out,$rc,$err)=run('ldap-probe',['--uri',$bad],\%mock_env);
    is($rc,2,"invalid LDAP URI rejected: $bad");
    ok(!-e $argsfile,'invalid URI did not launch backend');
}
($out,$rc)=run('ldap-probe',['--uri','ldaps://directory.example.test','--timeout','11'],\%mock_env);
is($rc,2,'oversized backend network timeout refused');
($out,$rc)=run('ldap-probe',[],\%mock_env);
is($rc,2,'LDAP URI required');

done_testing();
