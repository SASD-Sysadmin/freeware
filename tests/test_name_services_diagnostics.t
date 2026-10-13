#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Fully offline fixtures for NSS config, DNS wire client, NIS and LDAP config.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);
my $root=File::Spec->rel2abs("$FindBin::Bin/..");
my $temp=tempdir('sasd-nameservice-diagnostics-XXXXXXXX',TMPDIR=>1,CLEANUP=>1);
sub run {
    my ($tool,$args,$env)=@_;
    my $err=gensym();
    local %ENV=(%ENV,%{$env||{}});
    my $pid=open3(undef,my $stdout,$err,$^X,File::Spec->catfile($root,'bin',$tool),@$args);
    local $/;
    my $out=<$stdout> // '';
    my $stderr=<$err> // '';
    close($stdout);close($err);waitpid($pid,0);
    return ($out,$?>>8,$stderr);
}
sub fixture {my($name,$text)=@_;my $path=File::Spec->catfile($temp,$name);
    open my $f,'>',$path or die "$path: $!";print {$f} $text;close $f;return $path;}
for my $tool (qw(nsswitch-audit dns-query nis-probe ldap-config-audit)) {
    my ($out,$rc)=run($tool,['--help']);
    is($rc,0,"$tool --help works");like($out,qr/Usage: \Q$tool\E/,"$tool usage provided");
    ($out,$rc)=run($tool,['--version']);
    is($rc,0,"$tool --version works");like($out,qr/\Q$tool\E 0\.1\.0/,"$tool version printed");
    ($out,$rc)=run($tool,['--invalid']);is($rc,2,"$tool rejects unknown option");
}
my $valid=fixture('nsswitch-good',<<'NSS');
passwd: files systemd
shadow: files
group: files [SUCCESS=return] sss
hosts: files mdns4_minimal [NOTFOUND=return] dns
services: files
NSS
my ($out,$rc,$err)=run('nsswitch-audit',['--file',$valid]);
is($rc,0,'valid nsswitch file accepted');like($out,qr/Databases: 5/,'databases counted');
like($out,qr/Issues: 0/,'valid bracketed action did not trigger an issue');
my $invalid=fixture('nsswitch-invalid',<<'NSS');
passwd: files nis
passwd: files files
hosts: files [SUCCESS=return
services: files [BOGUS=panic]
group:
invalid line
NSS
($out,$rc)=run('nsswitch-audit',['--file',$invalid]);
is($rc,1,'invalid nsswitch reports findings');
for my $code (qw(duplicate-database duplicate-service invalid-service-list invalid-action-clause no-services malformed-database-line)) {
    like($out,qr/\Q$code\E/,"nsswitch detects $code");
}
like($out,qr/legacy-nis-family-service/,'NIS explicitly classified as legacy but not invalid');
my $missing=File::Spec->catfile($temp,'missing-conf');
($out,$rc,$err)=run('nsswitch-audit',['--file',$missing]);
is($rc,3,'missing NSS file reports prerequisite error');
($out,$rc)=run('nsswitch-audit',['--file','']);is($rc,2,'empty NSS pathname rejected');
my $partial=fixture('nsswitch-partial',"aliases: files\n");
($out,$rc)=run('nsswitch-audit',['--file',$partial]);
is($rc,0,'absent commonly configured databases are notes, not a fabricated failure');
like($out,qr/database-not-configured-hosts/,'absence explicitly noted');
my $control=fixture('nsswitch-control',"hosts: files\x1b\[31m\n");
($out,$rc)=run('nsswitch-audit',['--file',$control]);
is($rc,1,'control sequences rejected');unlike($out,qr/\x1b/,'untrusted control byte not printed');

my $ldapgood=fixture('ldap-good',<<'LDAP');
# OpenLDAP sample
URI ldaps://directory.example.test
TLS_REQCERT demand
TLS_CACERT /etc/ssl/certs/custom.pem
BASE dc=example,dc=test
LDAP
($out,$rc)=run('ldap-config-audit',['--file',$ldapgood]);
is($rc,0,'hardened LDAP client config passes');like($out,qr/Issues: 0/,'no findings in hardened fixture');
my $ldapbad=fixture('ldap-bad',<<'LDAP');
URI ldap://directory.internal.example
TLS_REQCERT never
TLS_REQCERT allow
INCLUDE /etc/openldap/secret-options.conf
SASL_MECH GSSAPI
LDAP
($out,$rc)=run('ldap-config-audit',['--file',$ldapbad]);
is($rc,1,'weak LDAP certificate policy fails');
like($out,qr/weak-tls-certificate-policy/,'weak TLS policy detected');
like($out,qr/duplicate-tls-reqcert/,'duplicate TLS directive detected');
like($out,qr/plaintext-ldap-uri-requires-explicit-starttls/,'LDAP non-LDAPS scheme noted, not assumed plaintext');
like($out,qr/include-not-followed-review-separately/,'included file omission is disclosed');
unlike($out,qr/directory\.internal|secret-options|GSSAPI/,'raw LDAP configuration values not disclosed');
my $ldapunknown=fixture('ldap-unknown',"TLS_REQCERT insecure_magic\n");
($out,$rc)=run('ldap-config-audit',['--file',$ldapunknown]);
is($rc,1,'unknown TLS policy fails closed');like($out,qr/unknown-tls-certificate-policy/,'unknown TLS policy named');
my $ldapnone=fixture('ldap-none',"BASE dc=secret,dc=example\n");
($out,$rc)=run('ldap-config-audit',['--file',$ldapnone]);
is($rc,0,'missing TLS fields are notes since client defaults can apply');
like($out,qr/tls-reqcert-not-explicit-client-default-applies/,'missing TLS setting disclosed');
unlike($out,qr/secret/,'base DN not printed');
($out,$rc,$err)=run('ldap-config-audit',['--file',$missing]);
is($rc,3,'missing LDAP file returns status 3');
($out,$rc)=run('ldap-config-audit',['--file','']);is($rc,2,'empty LDAP pathname refused');

my $emptybin=File::Spec->catdir($temp,'emptybin');make_path($emptybin);
($out,$rc,$err)=run('dns-query',['--name','example.test'],{PATH=>$emptybin});
is($rc,3,'DNS requires optional dig client');like($err,qr/dig not found/,'missing dig reported');
($out,$rc,$err)=run('nis-probe',[],{PATH=>$emptybin});
is($rc,3,'NIS requires optional ypwhich');like($err,qr/ypwhich not found/,'missing NIS client reported');
my $bin=File::Spec->catdir($temp,'fakebin');make_path($bin);
my $dig=File::Spec->catfile($bin,'dig');
my $ypwhich=File::Spec->catfile($bin,'ypwhich');
my $digargs=File::Spec->catfile($temp,'dig.args');
my $nisargs=File::Spec->catfile($temp,'nis.args');
my $head=';; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 1234';
open my $f,'>',$dig or die $!;
print {$f} "#!$^X\n";
print {$f} <<'STUB';
use strict;use warnings;
open my $a,'>',$ENV{SASD_DIG_ARGS} or die $!;
print {$a} join("\0",@ARGV),"\0";close $a;
if ($ENV{SASD_DIG_FAIL}) {print "dig failed\n";exit 9;}
if ($ENV{SASD_DIG_HUGE}) {print "X" x (131073);exit 0;}
if ($ENV{SASD_DIG_BAD_HEADER}) {print "not a DNS response\n";exit 0;}
my $code=$ENV{SASD_DIG_NXDOMAIN} ? 'NXDOMAIN' : 'NOERROR';
print ";; ->>HEADER<<- opcode: QUERY, status: $code, id: 1234\n";
if (!$ENV{SASD_DIG_NOANSWER} && $code eq 'NOERROR') {
    print ";; ANSWER SECTION:\nexample.test. 300 IN A 192.0.2.1\n";
    print "example.test. 300 IN A 192.0.2.2\x1b[31m\n" if $ENV{SASD_DIG_ESC};
}
STUB
close $f;chmod 0755,$dig;
open $f,'>',$ypwhich or die $!;
print {$f} "#!$^X\n";
print {$f} <<'STUB';
use strict;use warnings;
open my $a,'>',$ENV{SASD_NIS_ARGS} or die $!;
print {$a} join("\0",@ARGV),"\0";close $a;
if ($ENV{SASD_NIS_FAIL}) {exit 7;}
if ($ENV{SASD_NIS_BIG}) {print 'a' x 8193;exit 0;}
if ($ENV{SASD_NIS_EMPTY}) {exit 0;}
print "nis-master.example.test\n";
STUB
close $f;chmod 0755,$ypwhich;
my %e=(PATH=>$bin,SASD_DIG_ARGS=>$digargs,SASD_NIS_ARGS=>$nisargs);
($out,$rc,$err)=run('dns-query',['--name','example.test','--type','a','--server','192.0.2.53','--timeout','2'],\%e);
is($rc,0,'DNS mock query returns success');like($out,qr/DNS status: NOERROR/,'DNS status printed');
like($out,qr/Answers: 1/,'DNS answer counted');
open $f,'<',$digargs or die $!;my $raw=do{local $/;<$f>};close $f;
my @args=split /\0/,$raw;
ok((grep {$_ eq '@192.0.2.53'} @args),'DNS server constrained as numeric IP');
ok((grep {$_ eq '-q'} @args),'DNS query name passed in a dedicated flag');
ok((grep {$_ eq '-t'} @args),'DNS type passed in a dedicated flag');
ok((grep {$_ eq '+time=2'} @args),'DNS native timeout bounded');
($out,$rc)=run('dns-query',['--name','example.test','--server','[2001:db8::1]'],\%e);
is($rc,0,'DNS accepts bracketed numeric IPv6 server');
($out,$rc)=run('dns-query',['--name','example.test'],{%e,SASD_DIG_NXDOMAIN=>1});
is($rc,1,'NXDOMAIN is not reported as success');like($out,qr/DNS status: NXDOMAIN/,'DNS failure status preserved');
($out,$rc)=run('dns-query',['--name','example.test'],{%e,SASD_DIG_NOANSWER=>1});
is($rc,1,'NOERROR with no data is not reported as success');like($out,qr/Answers: 0/,'NODATA identified');
($out,$rc,$err)=run('dns-query',['--name','example.test'],{%e,SASD_DIG_FAIL=>1});
is($rc,1,'failed dig propagates unsuccessful status');
($out,$rc,$err)=run('dns-query',['--name','example.test'],{%e,SASD_DIG_BAD_HEADER=>1});
is($rc,3,'malformed native DNS output is rejected');
($out,$rc,$err)=run('dns-query',['--name','example.test'],{%e,SASD_DIG_HUGE=>1});
is($rc,3,'oversized DNS response rejected');is($out,'','partial oversized DNS result never printed');
($out,$rc)=run('dns-query',['--name','example.test'],{%e,SASD_DIG_ESC=>1});
is($rc,0,'control-byte DNS response still parsed');unlike($out,qr/\x1b/,'DNS response terminal escape was sanitized');
for my $bad (['--name','-x'],['--name','evil;test'],['--name','example.test','--type','AXFR'],
             ['--name','example.test','--server','evil.example'],
             ['--name','example.test','--server','192.0.2.1;rm'],
             ['--name','example.test','--timeout','100']) {
    unlink $digargs;
    ($out,$rc)=run('dns-query',$bad,\%e);
    is($rc,2,'invalid DNS selector rejected');
    ok(!-e $digargs,'invalid DNS selector did not reach dig');
}
($out,$rc)=run('nis-probe',['--domain','legacy.example','--timeout','2'],\%e);
is($rc,0,'NIS probe succeeds with bound server mock');like($out,qr/NIS binding: nis-master\.example\.test/,'NIS binding displayed');
open $f,'<',$nisargs or die $!;$raw=do{local $/;<$f>};close $f;
is($raw,"-d\0legacy.example\0",'NIS domain passed through dedicated -d option');
($out,$rc,$err)=run('nis-probe',[],{%e,SASD_NIS_FAIL=>1});
is($rc,1,'unbound NIS returns 1');like($err,qr/unbound or server unavailable/,'NIS failure is explained');
($out,$rc)=run('nis-probe',[],{%e,SASD_NIS_EMPTY=>1});
is($rc,1,'empty NIS response is not success');
($out,$rc)=run('nis-probe',[],{%e,SASD_NIS_BIG=>1});
is($rc,3,'oversized NIS response fails closed');is($out,'','oversized NIS response is not exposed');
for my $bad (['--domain','-bad'],['--domain',"bad\nname"],['--domain','example;cmd'],['--timeout','0'],['--timeout','11']) {
    unlink $nisargs;
    ($out,$rc)=run('nis-probe',$bad,\%e);
    is($rc,2,'invalid NIS option rejected');ok(!-e $nisargs,'invalid NIS option never invokes ypwhich');
}
done_testing();
