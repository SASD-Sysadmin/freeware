#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M8.3 offline contract and hostile-input suite.
# All snapshots are synthetic. Tests never open network sockets or invoke ss.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3;
use Symbol qw(gensym);

my $root=File::Spec->rel2abs("$FindBin::Bin/..");
my $tool="$root/bin/network-service-report";
my $tmp=tempdir('sasd-services-XXXXXXXX',TMPDIR=>1,CLEANUP=>1);

sub run_cmd {
    my (@args)=@_;
    my $err=gensym();
    my $pid=open3(undef,my $out,$err,$^X,$tool,@args);
    local $/;
    my $stdout=<$out> // '';
    my $stderr=<$err> // '';
    close($out); close($err);
    waitpid($pid,0);
    return ($? >> 8,$stdout,$stderr);
}
sub fixture {
    my ($name,$text)=@_;
    my $file="$tmp/$name";
    open my $fh,'>',$file or die $!;
    binmode($fh);
    print {$fh} $text;
    close($fh) or die $!;
    return $file;
}

my $ss = <<'SS';
tcp LISTEN 0 128 127.0.0.1:22 0.0.0.0:*
tcp LISTEN 0 4096 [::1]:443 [::]:*
udp UNCONN 0 0 0.0.0.0:5353 0.0.0.0:*
udp UNCONN 0 0 [fe80::1%en0]:547 [::]:*
tcp LISTEN 0 50 *:8080 *:*
tcp ESTAB 0 0 127.0.0.1:8080 127.0.0.1:51001
udp ESTAB 0 0 127.0.0.1:53000 192.0.2.53:53
SS
my $netstat = <<'NETSTAT';
Active Internet connections (including servers)
Proto Recv-Q Send-Q Local Address          Foreign Address        (state)
tcp4       0      0 127.0.0.1.22            *.*                    LISTEN
tcp6       0      0 ::1.443                  *.*                    LISTEN
udp4       0      0 *.5353                   *.*
udp6       0      0 fe80::1%en0.547           *.*
tcp4       0      0 127.0.0.1.22            192.0.2.5.12345        ESTABLISHED
udp4       0      0 127.0.0.1.53000         192.0.2.53.53
Active UNIX domain sockets
Address Type Recv-Q Send-Q Inode Conn Refs Nextref Addr
aaaa stream 0 0 0 0 0 0 /tmp/sasd.sock
NETSTAT
my $ssfile=fixture('ss.snapshot',$ss);
my $netfile=fixture('netstat.snapshot',$netstat);
my ($rc,$out,$err)=run_cmd('--help');
is($rc,0,'help exit success');
like($out,qr/\AUsage: network-service-report/,'help usage');
like($out,qr/unconnected UDP BOUND/,'help distinguishes UDP from TCP');
is($err,'','help no diagnostic');
($rc,$out,$err)=run_cmd('--version');
is($rc,0,'version exit success');
is($out,"network-service-report 0.1.0\n",'version stable');
is($err,'','version no diagnostic');

($rc,$out,$err)=run_cmd('--input',$ssfile,'--format','ss');
is($rc,0,'ss fixture succeeds');
is($err,'','valid ss quiet');
like($out,qr/\AFAMILY\tPROTOCOL\tLOCAL_ADDRESS\tLOCAL_PORT\tSTATE\tPEER_ADDRESS\tPEER_PORT\n/,'seven-field header');
like($out,qr/^inet\ttcp\t127\.0\.0\.1\t22\tLISTEN\t0\.0\.0\.0\t\*$/m,'IPv4 TCP listener');
like($out,qr/^inet6\ttcp\t::1\t443\tLISTEN\t::\t\*$/m,'IPv6 TCP listener');
like($out,qr/^inet\tudp\t0\.0\.0\.0\t5353\tBOUND\t0\.0\.0\.0\t\*$/m,'UDP bind not listener');
like($out,qr/^inet6\tudp\tfe80::1%en0\t547\tBOUND\t::\t\*$/m,'IPv6 scoped UDP bind');
like($out,qr/^unknown\ttcp\t\*\t8080\tLISTEN\t\*\t\*$/m,'ambiguous wildcard family not guessed');
is(scalar(split /\n/,$out),6,'only five bound/listening sockets');
unlike($out,qr/ESTAB|53000|51001/,'connected sockets excluded');
($rc,$out)=run_cmd('--input',$ssfile);
is($rc,0,'ss auto format succeeds');
like($out,qr/^inet6\tudp/m,'auto selects ss');
($rc,$out)=run_cmd('--input',$ssfile,'--protocol','tcp');
is($rc,0,'TCP filtering succeeds');
unlike($out,qr/^inet\tudp|^inet6\tudp/m,'TCP filter excludes UDP');
like($out,qr/^unknown\ttcp/m,'TCP filter retains unknown family');
($rc,$out)=run_cmd('--input',$ssfile,'--protocol','udp');
is($rc,0,'UDP filtering succeeds');
unlike($out,qr/\ttcp\t/,'UDP filter excludes TCP');
($rc,$out)=run_cmd('--input',$ssfile,'--family','inet6');
is($rc,0,'IPv6 filtering succeeds');
unlike($out,qr/^inet\t|^unknown\t/m,'IPv6 filter excludes ambiguous family');
like($out,qr/^inet6\tudp/m,'IPv6 filter retains UDP');
($rc,$out)=run_cmd('--input',$ssfile,'--family','inet');
is($rc,0,'IPv4 filtering succeeds');
unlike($out,qr/^inet6\t|^unknown\t/m,'IPv4 filter excludes ambiguous family');
($rc,$out)=run_cmd('--input',$ssfile,'--null');
is($rc,0,'NUL output succeeds');
unlike($out,qr/FAMILY\t/,'NUL no header');
my @fields=split /\0/,$out,-1;
is($fields[-1],'','NUL terminates final field');
is(scalar(@fields),5*7+1,'seven fields per row');

($rc,$out,$err)=run_cmd('--input',$netfile,'--format','netstat');
is($rc,0,'BSD netstat fixture succeeds');
is($err,'','valid netstat quiet');
is(scalar(split /\n/,$out),5,'netstat has four bound/listening rows');
like($out,qr/^inet\ttcp\t127\.0\.0\.1\t22\tLISTEN\t\*\t\*$/m,'netstat IPv4 TCP listen');
like($out,qr/^inet6\ttcp\t::1\t443\tLISTEN\t\*\t\*$/m,'netstat IPv6 TCP listen');
like($out,qr/^inet\tudp\t\*\t5353\tBOUND\t\*\t\*$/m,'netstat wildcard UDP binds with family from protocol');
like($out,qr/^inet6\tudp\tfe80::1%en0\t547\tBOUND\t\*\t\*$/m,'netstat zoned IPv6 UDP');
unlike($out,qr/53000|ESTABLISHED|\.sock/,'connected and Unix sockets excluded');
($rc,$out)=run_cmd('--input',$netfile);
is($rc,0,'auto selects netstat');
like($out,qr/^inet6\ttcp/m,'auto parser netstat IPv6');
($rc,$out)=run_cmd('--input',$netfile,'--family','inet6','--protocol','udp');
is($rc,0,'combined family/protocol netstat filter');
is(scalar(split /\n/,$out),2,'one selected netstat socket');
like($out,qr/^inet6\tudp/m,'selected netstat IPv6 UDP');

my $empty=fixture('empty.ss','');
($rc,$out,$err)=run_cmd('--input',$empty,'--format','ss');
is($rc,0,'empty ss snapshot valid');
is($out,"FAMILY\tPROTOCOL\tLOCAL_ADDRESS\tLOCAL_PORT\tSTATE\tPEER_ADDRESS\tPEER_PORT\n",'empty ss header only');
my $empty_net=fixture('empty.netstat',"Active Internet connections (including servers)\nProto Recv-Q Send-Q Local Address Foreign Address (state)\n");
($rc,$out)=run_cmd('--input',$empty_net,'--format','netstat');
is($rc,0,'empty but framed BSD snapshot valid');
is(scalar(split /\n/,$out),1,'empty BSD inventory header only');

# Fail-closed table: every rejected snapshot must return no stdout, even if
# some valid rows precede the error. Rejecting also when an unrelated family
# is selected detects malformed inventory that filtering would otherwise hide.
my $many_rows = ('tcp LISTEN 0 0 127.0.0.1:22 0.0.0.0:*' . "\n") x 4100;
my @bad=(
    ['ss-malformed-port',"tcp LISTEN 0 0 127.0.0.1:65536 0.0.0.0:*\n",'ss'],
    ['ss-zero-port',"tcp LISTEN 0 0 127.0.0.1:0 0.0.0.0:*\n",'ss'],
    ['ss-non-numeric-port',"tcp LISTEN 0 0 127.0.0.1:http 0.0.0.0:*\n",'ss'],
    ['ss-bad-IP',"tcp LISTEN 0 0 999.0.0.1:22 0.0.0.0:*\n",'ss'],
    ['ss-invalid-scope',"udp UNCONN 0 0 [fe80::1%bad zone]:53 [::]:*\n",'ss'],
    ['ss-family-mismatch',"tcp LISTEN 0 0 [::1]:22 0.0.0.0:*\n",'ss'],
    ['ss-extra-column',"tcp LISTEN 0 0 127.0.0.1:22 0.0.0.0:* users:evil\n",'ss'],
    ['ss-missing-column',"tcp LISTEN 0 0 127.0.0.1:22\n",'ss'],
    ['ss-negative-queue',"tcp LISTEN -1 0 127.0.0.1:22 0.0.0.0:*\n",'ss'],
    ['ss-tcp-peer',"tcp LISTEN 0 0 127.0.0.1:22 192.0.2.1:123\n",'ss'],
    ['ss-udp-peer',"udp UNCONN 0 0 127.0.0.1:53 192.0.2.1:53\n",'ss'],
    ['ss-peer-port',"tcp LISTEN 0 0 127.0.0.1:22 0.0.0.0:80\n",'ss'],
    ['ss-invalid-state',"tcp FROZEN 0 0 127.0.0.1:22 0.0.0.0:*\n",'ss'],
    ['ss-unsupported-UDP',"udp FROZEN 0 0 127.0.0.1:53 0.0.0.0:*\n",'ss'],
    ['ss-bad-protocol',"raw UNCONN 0 0 127.0.0.1:53 0.0.0.0:*\n",'ss'],
    ['ss-leading-junk',"JUNK\n$ss",'ss'],
    ['ss-partial-after-good',"$ss\ntcp LISTEN 0",'ss'],
    ['ss-unterminated',"tcp LISTEN 0 0 127.0.0.1:22 0.0.0.0:*",'ss'],
    ['ss-control-byte',"tcp LISTEN 0 0 127.0.0.1:22 0.0.0.0:*\x1b\n",'ss'],
    ['ss-NUL',"tcp LISTEN 0 0 127.0.0.1:22 0.0.0.0:*\0\n",'ss'],
    ['ss-bareCR',"tcp LISTEN 0 0 127.0.0.1:22 0.0.0.0:*\r",'ss'],
    ['ss-too-many-rows',$many_rows,'ss'],
    ['ss-overbyte-limit','x'x(8*1024*1024+1),'ss'],
    ['netstat-no-header',"tcp4 0 0 127.0.0.1.22 *.* LISTEN\n",'netstat'],
    ['netstat-no-proto-heading',"Active Internet connections\ntcp4 0 0 127.0.0.1.22 *.* LISTEN\n",'netstat'],
    ['netstat-missing-state',"Active Internet connections\nProto Recv-Q Send-Q Local Address Foreign Address (state)\ntcp4 0 0 127.0.0.1.22 *.*\n",'netstat'],
    ['netstat-port-text',"Active Internet connections\nProto Recv-Q Send-Q Local Address Foreign Address (state)\ntcp4 0 0 127.0.0.1.ssh *.* LISTEN\n",'netstat'],
    ['netstat-ip-mismatch',"Active Internet connections\nProto Recv-Q Send-Q Local Address Foreign Address (state)\ntcp6 0 0 127.0.0.1.22 *.* LISTEN\n",'netstat'],
    ['netstat-local-zero',"Active Internet connections\nProto Recv-Q Send-Q Local Address Foreign Address (state)\nudp4 0 0 *.0 *.*\n",'netstat'],
    ['netstat-udp-extra',"Active Internet connections\nProto Recv-Q Send-Q Local Address Foreign Address (state)\nudp4 0 0 *.5353 *.* LISTEN\n",'netstat'],
    ['netstat-bad-queue',"Active Internet connections\nProto Recv-Q Send-Q Local Address Foreign Address (state)\ntcp4 0 -1 127.0.0.1.22 *.* LISTEN\n",'netstat'],
    ['netstat-unterminated',"Active Internet connections\nProto Recv-Q Send-Q Local Address Foreign Address (state)",'netstat'],
    ['netstat-control',"Active Internet connections\nProto Recv-Q Send-Q Local Address Foreign Address (state)\nudp4 0 0 *.5353 *.*\x1b\n",'netstat'],
    ['netstat-bad-peer',"Active Internet connections\nProto Recv-Q Send-Q Local Address Foreign Address (state)\ntcp4 0 0 127.0.0.1.22 *.80 LISTEN\n",'netstat'],
    ['netstat-too-many-lines', ("Active Internet connections\nProto Recv-Q Send-Q Local Address Foreign Address (state)\n" . ("\n" x 8200)), 'netstat'],
);
for my $case (@bad) {
    my ($name,$data,$format)=@$case;
    my $path=fixture("bad-$name",$data);
    ($rc,$out,$err)=run_cmd('--input',$path,'--format',$format,'--protocol','udp');
    is($rc,3,"$name returns input failure");
    is($out,'',"$name never prints partial TSV");
    like($err,qr/\Anetwork-service-report: /,"$name diagnostic identifies command");
    unlike($err,qr/127\.0\.0\.1|999\.0\.0\.1|bad-$name|sasd-services/,"$name does not leak snapshot/path");
}
for my $args (
    ['--protocol','raw'],['--family','ipv6'],['--format','other'],
    ['--input',''],['--Unknown'],['--Protocol','udp'],
    ['--null=true'],['--family','INet'],['--protocol','Udp'],
) {
    ($rc,$out)=run_cmd(@$args);
    is($rc,2,'invalid CLI option rejected');
    is($out,'','invalid CLI prints no inventory');
}
($rc,$out,$err)=run_cmd('--input',"$tmp/does-not-exist");
is($rc,3,'missing input file rejected');
is($out,'','missing input no report');
unlike($err,qr/sasd-services|does-not-exist/,'missing file pathname not exposed');
my $link="$tmp/snapshot-link";
symlink($ssfile,$link) or die $!;
($rc,$out,$err)=run_cmd('--input',$link);
is($rc,3,'symbolic link rejected');
is($out,'','symbolic link no report');
unlike($err,qr/sasd-services|snapshot-link/,'symlink target/name not exposed');

# CRLF framing is accepted, while bare CR is deliberately rejected.
my $crlf=$ss;
$crlf =~ s/\n/\r\n/g;
($rc,$out,$err)=run_cmd('--input',fixture('crlf.ss',$crlf),'--format','ss');
is($rc,0,'normal Windows-style CRLF accepted as fixture');
like($out,qr/inet6\ttcp/,'CRLF snapshot decoded');

# An auto-selected parser can remain valid on an empty host, where Linux ss
# truly returns zero bytes. No TCP listener is invented from that condition.
($rc,$out,$err)=run_cmd('--input',$empty);
is($rc,0,'empty snapshot auto-selects ss');
is(scalar(split /\n/,$out),1,'no fictitious rows for empty auto ss');

done_testing();
