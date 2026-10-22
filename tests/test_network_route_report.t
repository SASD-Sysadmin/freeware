#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M8.2 synthetic contract suite. Never touches the system routing table.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Spec;
use IPC::Open3;
use Symbol qw(gensym);
use JSON::PP ();
my $root = File::Spec->rel2abs("$FindBin::Bin/..");
my $tool = "$root/bin/network-route-report";
my $tmp = tempdir('sasd-routes-XXXXXXXX', TMPDIR=>1, CLEANUP=>1);

sub run_cmd {
    my (@args) = @_;
    my $err = gensym();
    my $pid = open3(undef, my $out, $err, $^X, $tool, @args);
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    close($out); close($err);
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}
sub fixture {
    my ($name, $bytes) = @_;
    my $file = "$tmp/$name";
    open my $fh, '>', $file or die $!;
    binmode($fh);
    print {$fh} $bytes;
    close($fh) or die $!;
    return $file;
}
my $json = JSON::PP->new->canonical;
my $v4 = [
    { dst=>'default', gateway=>'192.0.2.1', dev=>'ens3', metric=>100,
      table=>'main', protocol=>'dhcp', flags=>[] },
    { dst=>'192.0.2.0/24', dev=>'ens3', scope=>'link', protocol=>'kernel' },
    { dst=>'203.0.113.0/24', type=>'blackhole', table=>100 },
];
my $v6 = [
    { dst=>'default', gateway=>'fe80::1%ens3', dev=>'ens3', metric=>10 },
    { dst=>'2001:db8::/64', dev=>'ens3', flags=>['onlink'] },
];
my $full = fixture('routes.json', $json->encode({inet=>$v4, inet6=>$v6}));
my $linux4 = fixture('v4.json', $json->encode($v4));
my $linux6 = fixture('v6.json', $json->encode($v6));
my $netstat = fixture('routes.netstat', <<'CAPTURE');
Routing tables

Internet:
Destination        Gateway            Flags        Netif Expire
default            192.0.2.1          UGScg        en0
192.0.2.0/24       link#4             UCS          en0

Routing tables
Internet6:
Destination                             Gateway                   Flags        Netif Expire
default                                 fe80::1%en0                UGcg         en0
2001:db8::/64                          link#4                    UC           en0
CAPTURE

my ($rc,$out,$err) = run_cmd('--help');
is($rc,0,'help returns zero');
like($out,qr/\AUsage: network-route-report/, 'help names command');
is($err,'','help quiet');
($rc,$out) = run_cmd('--version');
is($rc,0,'version returns zero');
is($out,"network-route-report 0.1.0\n",'stable version');

($rc,$out,$err) = run_cmd('--input',$full,'--format','ip-json');
is($rc,0,'Linux dual-family report succeeds');
is($err,'','valid Linux fixture no diagnostics');
like($out,qr/\AFAMILY\tDESTINATION\tGATEWAY\tINTERFACE\tTABLE\tMETRIC\tTYPE\tFLAGS\n/, 'eight-column TSV header');
like($out,qr/inet\tdefault\t192\.0\.2\.1\tens3\tmain\t100\tunicast\t-/, 'IPv4 default gateway and metric');
like($out,qr/inet\t203\.0\.113\.0\/24\t-\t-\t100\t-\tblackhole\t-/, 'blackhole not turned into a gateway route');
like($out,qr/inet6\tdefault\tfe80::1%ens3\tens3\tmain\t10\tunicast/, 'IPv6 scoped gateway');
like($out,qr/inet6\t2001:db8::\/64\t-\tens3\tmain\t-\tunicast\tonlink/, 'IPv6 onlink flag');
is(scalar(split /\n/, $out), 6, 'five routes plus TSV header');
($rc,$out) = run_cmd('--input',$linux4,'--format','ip-json','--family','inet');
is($rc,0,'single-family Linux array supported');
unlike($out,qr/^inet6\t/m,'no IPv6 rows invented');
($rc,$out) = run_cmd('--input',$linux6,'--format','ip-json','--family','inet6');
is($rc,0,'single-family IPv6 array supported');
like($out,qr/^inet6\tdefault/m,'IPv6 default is preserved');
($rc,$out) = run_cmd('--input',$full,'--format','auto','--family','inet6');
is($rc,0,'JSON auto-detection valid');
unlike($out,qr/^inet\t/m,'IPv4 filtered');
($rc,$out) = run_cmd('--input',$full,'--null');
is($rc,0,'NUL output valid');
unlike($out,qr/FAMILY\tDESTINATION/,'NUL output has no header');
my @cells = split /\0/, $out, -1;
is($cells[-1], '', 'NUL report terminates');
is(scalar(@cells), 5*8+1, 'eight NUL fields per route');

($rc,$out,$err) = run_cmd('--input',$netstat,'--format','netstat');
is($rc,0,'macOS-style netstat capture succeeds');
is($err,'','valid netstat snapshot quiet');
like($out,qr/inet\t192\.0\.2\.0\/24\tlink#4\ten0\t-\t-\t-\tUCS/, 'link-layer gateway kept as link reference');
like($out,qr/inet6\tdefault\tfe80::1%en0\ten0\t-\t-\t-\tUGcg/, 'IPv6 netstat default');
is(scalar(split /\n/, $out),5,'four netstat rows');
my $bsdshort = fixture('short.netstat', "Internet:\nDestination Gateway Flags Netif\n127 127.0.0.1 UCS lo0\n192.0.2 link#4 UCS en0\n10/8 link#4 UCS en0\nInternet6:\nDestination Gateway Flags Netif\n");
($rc,$out) = run_cmd('--input',$bsdshort,'--format','netstat');
is($rc,0,'bounded BSD abbreviated IPv4 routes accepted');
like($out,qr/^inet\t127\t127\.0\.0\.1\tlo0/m,'BSD short destination preserved, not invented as a CIDR');
like($out,qr/^inet\t10\/8\tlink#4\ten0/m,'short CIDR token preserved');
($rc,$out) = run_cmd('--input',$netstat);
is($rc,0,'netstat auto-detection succeeds');
like($out,qr/^inet6\t/m,'auto detected netstat format');
($rc,$out) = run_cmd('--input',$netstat,'--family','inet');
is($rc,0,'netstat family filter succeeds');
unlike($out,qr/^inet6\t/m,'netstat IPv6 rows filtered');
($rc,$out) = run_cmd('--input',$netstat,'--family','inet6');
is($rc,0,'netstat IPv6-only selection works');
unlike($out,qr/^inet\t/m,'IPv4 rows filtered');

for my $case (
    ['malformed-json','{"inet": ['],
    ['ambiguous-array', $json->encode($v4)],
    ['missing-family', $json->encode({inet=>$v4})],
    ['null','{"inet":[],"inet6":[]}\0'],
    ['missing-destination', $json->encode({inet=>[{}],inet6=>[]})],
    ['bad-IP', $json->encode({inet=>[{dst=>'default',gateway=>'999.0.2.1'}],inet6=>[]})],
    ['bad-prefix', $json->encode({inet=>[{dst=>'192.0.2.0/33'}],inet6=>[]})],
    ['double-slash', $json->encode({inet=>[{dst=>'192.0.2.0/24/1'}],inet6=>[]})],
    ['family-mismatch', $json->encode({inet=>[{dst=>'default',family=>'inet6'}],inet6=>[]})],
    ['malformed-interface', $json->encode({inet=>[{dst=>'default',dev=>'in valid'}],inet6=>[]})],
    ['negative-metric', $json->encode({inet=>[{dst=>'default',metric=>-2}],inet6=>[]})],
    ['bad-table', $json->encode({inet=>[{dst=>'default',table=>'weird table'}],inet6=>[]})],
    ['bad-route-type', $json->encode({inet=>[{dst=>'default',type=>'wut'}],inet6=>[]})],
    ['ecmp', $json->encode({inet=>[{dst=>'default',nexthops=>[{via=>'192.0.2.1'}]}],inet6=>[]})],
    ['nhid', $json->encode({inet=>[{dst=>'default',nhid=>1}],inet6=>[]})],
    ['via', $json->encode({inet=>[{dst=>'default',via=>{family=>'inet',addr=>'192.0.2.1'}}],inet6=>[]})],
    ['bad-flag', $json->encode({inet=>[{dst=>'default',flags=>['a\tb']}],inet6=>[]})],
    ['injected-json', '{"inet":[],"inet6":[]}\nBAD'],
    ['empty-array','[]'],
    ['short-netstat',"Routing tables\nInternet:\nDestination Gateway Flags Netif\n"],
    ['netstat-invalid-abbrev',"Internet:\nDestination Gateway Flags Netif\n299/8 127.0.0.1 UH lo0\nInternet6:\nDestination Gateway Flags Netif\n"],
    ['netstat-no-header',"Internet:\ndefault 192.0.2.1 UG en0\nInternet6:\nDestination Gateway Flags Netif\n"],
    ['netstat-no-final-lf',"Internet:\nDestination Gateway Flags Netif\ndefault 192.0.2.1 UG en0"],
    ['netstat-bad-gateway',"Internet:\nDestination Gateway Flags Netif\ndefault gobbledygook UG en0\nInternet6:\nDestination Gateway Flags Netif\n"],
    ['control-byte',"Internet:\nDestination Gateway Flags Netif\ndefault 192.0.2.1 UG en0\x1b\nInternet6:\nDestination Gateway Flags Netif\n"],
    ['oversized', 'x' x (8*1024*1024 + 1)],
) {
    my ($id,$contents) = @$case;
    $contents =~ s/\\0/\0/g;
    # Supply explicit JSON selection for syntax cases and let auto detection
    # recognize the text syntax for netstat cases.
    my $fmt = $id =~ /netstat|control-byte/ ? 'netstat' : 'ip-json';
    my $path = fixture("bad-$id",$contents);
    ($rc,$out,$err) = run_cmd('--input',$path,'--format',$fmt);
    is($rc,3,"$id rejected as an input error");
    is($out,'',"$id never prints a partial table");
    like($err,qr/\Anetwork-route-report: /,"$id diagnostic names command");
    unlike($err,qr/gobbledygook|999\.0\.2\.1|weird table|\.\/bad-/,"$id hides raw input");
}
for my $args (
    ['--family','ip4'], ['--format','foo'], ['--input',''],
    ['--unknown'], ['--Family','inet'], ['--null=true'],
) {
    ($rc,$out) = run_cmd(@$args);
    is($rc,2,'invalid command line rejected');
    is($out,'','invalid CLI emits no inventory');
}
($rc,$out,$err) = run_cmd('--input', "$tmp/missing");
is($rc,3,'missing input rejected');
is($out,'','missing file no output');
unlike($err,qr/\/tmp\/|sasd-routes/, 'missing input path hidden');
my $link = "$tmp/symlink";
symlink($full, $link) or die $!;
($rc,$out,$err) = run_cmd('--input', $link);
is($rc,3,'symlink snapshot rejected');
is($out,'','no symlink output');
unlike($err,qr/\/tmp\/|sasd-routes/, 'symlink target not disclosed');
my $empty = fixture('empty', $json->encode({inet=>[],inet6=>[]}));
($rc,$out) = run_cmd('--input',$empty,'--format','ip-json');
is($rc,0,'empty but complete snapshot valid');
is($out,"FAMILY\tDESTINATION\tGATEWAY\tINTERFACE\tTABLE\tMETRIC\tTYPE\tFLAGS\n",'empty report still prints TSV header');

done_testing();
