#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M8.1: no system networking changes and no native dependency in CI.
# Linux iproute2 JSON and macOS/BSD ifconfig snapshots are synthetic and
# explicitly representative, not a claim that every native OS was tested.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $root = File::Spec->rel2abs("$FindBin::Bin/..");
my $exe = "$root/bin/network-interface-report";
my $tmp = tempdir('sasd-m81-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);

sub save {
    my ($name, $bytes) = @_;
    my $path = "$tmp/$name";
    open my $f, '>', $path or die "cannot create fixture: $!";
    binmode($f);
    print {$f} $bytes;
    close $f or die "cannot close fixture: $!";
    return $path;
}
sub run_tool {
    my (@args) = @_;
    my $err = gensym();
    my $pid = open3(undef, my $out, $err, $^X, $exe, @args);
    binmode($out); binmode($err);
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    close $out; close $err;
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}
my $linux_json = <<'JSON';
[
 {"ifindex":1,"ifname":"lo","flags":["LOOPBACK","UP"],"operstate":"UNKNOWN",
  "address":"00:00:00:00:00:00",
  "addr_info":[{"family":"inet","local":"127.0.0.1","prefixlen":8},
               {"family":"inet6","local":"::1","prefixlen":128}]},
 {"ifindex":3,"ifname":"enp0s3","operstate":"UP","address":"52:54:00:aa:bb:cc",
  "addr_info":[{"family":"inet","local":"192.0.2.10","prefixlen":24},
               {"family":"inet6","local":"fe80::1234","prefixlen":64}]},
 {"ifindex":7,"ifname":"veth0@if8","operstate":"DOWN","addr_info":[]}
]
JSON
my $bsd_text = <<'IFCONFIG';
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
	options=1203<RXCSUM,TXCSUM>
	inet 127.0.0.1 netmask 0xff000000
	inet6 ::1 prefixlen 128
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether 9a:88:77:66:55:44
	inet6 fe80::2%en0 prefixlen 64 secured scopeid 0x5
	inet 198.51.100.7 netmask 0xffffff00 broadcast 198.51.100.255
	status: active
awdl0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> mtu 1484
	ether aa:bb:cc:dd:ee:ff
	status: inactive
IFCONFIG
my $lin = save('linux.json', $linux_json);
my $bsd = save('mac.ifconfig', $bsd_text);
my ($rc,$out,$err) = run_tool('--help');
is($rc,0,'help returns success');
like($out,qr/Usage: network-interface-report/,'help documents command');
is($err,'','help emits no errors');
($rc,$out,$err) = run_tool('--version');
is($rc,0,'version returns success');
is($out,"network-interface-report 0.1.0\n",'stable version');
($rc,$out,$err) = run_tool('--input',$lin,'--format','ip-json');
is($rc,0,'Linux ip JSON accepted');
is($err,'','valid Linux report has no diagnostic');
like($out,qr/\AINTERFACE\tINDEX\tSTATE\tFAMILY\tADDRESS\tPREFIX\tMAC\n/,'TSV header stable');
like($out,qr/^lo\t1\tUNKNOWN\tinet\t127\.0\.0\.1\t8\t00:00:00:00:00:00$/m,'loopback parsed');
like($out,qr/^enp0s3\t3\tUP\tinet\t192\.0\.2\.10\t24\t52:54:00:aa:bb:cc$/m,'IPv4 index/state/MAC parsed');
like($out,qr/^enp0s3\t3\tUP\tinet6\tfe80::1234\t64\t52:54:00:aa:bb:cc$/m,'IPv6 parsed');
like($out,qr/^veth0\@if8\t7\tDOWN\t-\t-\t-\t-$/m,'no-address interface retained');
my @output_rows=split /\n/,$out;
is(scalar(@output_rows),6,'four addresses plus link-only row');
($rc,$out) = run_tool('--input',$lin,'--format','ip-json','--family','inet');
is($rc,0,'IPv4 family filter accepted');
unlike($out,qr/\tinet6\t/,'IPv6 excluded');
like($out,qr/^veth0\@if8\t7\tDOWN\t-\t-\t-\t-$/m,'unmatched interface still reported');
($rc,$out)=run_tool('--input',$lin,'--format','ip-json','--null');
is($rc,0,'NUL format succeeds');
unlike($out,qr/INTERFACE\tINDEX/,'NUL output has no header');
like($out,qr/enp0s3\x003\x00UP\x00inet\x00192\.0\.2\.10\x0024\x0052:54:00:aa:bb:cc\x00/,'NUL has seven fields');
($rc,$out,$err)=run_tool('--input',$bsd,'--format','ifconfig');
is($rc,0,'macOS ifconfig accepted');
is($err,'','valid ifconfig has no diagnostic');
like($out,qr/^en0\t-\tUP\tinet\t198\.51\.100\.7\t24\t9a:88:77:66:55:44$/m,'hex netmask converted to CIDR');
like($out,qr/^en0\t-\tUP\tinet6\tfe80::2%en0\t64\t9a:88:77:66:55:44$/m,'scoped IPv6 retained');
like($out,qr/^awdl0\t-\tDOWN\t-\t-\t-\taa:bb:cc:dd:ee:ff$/m,'inactive interface visible');
($rc,$out)=run_tool('--input',$bsd,'--format','auto');
is($rc,0,'ifconfig autodetection accepted');
like($out,qr/en0\t-\tUP\tinet\t/,'auto detected ifconfig format');
($rc,$out)=run_tool('--input',$lin,'--format','auto');
is($rc,0,'JSON autodetection accepted');
like($out,qr/enp0s3\t3\tUP\tinet/,'auto detected ip JSON format');
for my $arg (['--format','bad'],['--family','v4'],['--input',''],['--bad'],['--family','INET']) {
    ($rc,$out)=run_tool(@$arg);
    is($rc,2,'unsupported option rejected');
    is($out,'','option rejection has no report');
}
my $empty=save('empty','');
my $bad_json=save('broken.json','[{"ifname":"xx"}');
my $non_array=save('nonarray.json','{}');
my $no_addr=save('missing-field.json','[{"ifname":"eth0","ifindex":2,"addr_info":[{"family":"inet","prefixlen":24}]}]');
my $dupe=save('duplicate.json','[{"ifname":"eth0","ifindex":2},{"ifname":"eth0","ifindex":3}]');
my $bad_addr=save('invalid-ip.json','[{"ifname":"eth0","ifindex":2,"addr_info":[{"family":"inet","local":"999.4.5.6","prefixlen":24}]}]');
my $bad_prefix=save('invalid-prefix.json','[{"ifname":"eth0","ifindex":2,"addr_info":[{"family":"inet","local":"192.0.2.1","prefixlen":88}]}]');
my $bad_name=save('bad-name.json','[{"ifname":"eth0\tPRIVATE","ifindex":2,"addr_info":[]}]');
my $bad_mac=save('bad-mac.json','[{"ifname":"eth0","ifindex":2,"address":"INJECTED PRIVATE","addr_info":[]}]');
my $bare_cr=save('bare-cr.ifconfig',"en0: flags=9<UP> mtu 1500\r\n\tstatus: active\rBAD\n");
my $no_newline=save('unfinished.ifconfig','en0: flags=9<UP> mtu 1500');
my $invalid_mask=save('invalid-mask.ifconfig',"en0: flags=9<UP> mtu 1500\n\tinet 192.0.2.1 netmask 0xff00ff00\n");
my $missing_mask=save('missing-mask.ifconfig',"en0: flags=9<UP> mtu 1500\n\tinet 192.0.2.1\n");
my $missing_header=save('missing-header.ifconfig',"\tinet 192.0.2.1 netmask 0xffffff00\n");
my $invalid_header=save('invalid-header.ifconfig',"PRIVATE_INJECTION\n\tinet 192.0.2.1 netmask 0xffffff00\n");
my $oversize=save('oversized.json',' ' x (8*1024*1024+1));
for my $t ([$empty,'ifconfig'],[$bad_json,'ip-json'],[$non_array,'ip-json'],[$no_addr,'ip-json'],
           [$dupe,'ip-json'],[$bad_addr,'ip-json'],[$bad_prefix,'ip-json'],[$bad_name,'ip-json'],
           [$bad_mac,'ip-json'],[$bare_cr,'ifconfig'],[$no_newline,'ifconfig'],[$invalid_mask,'ifconfig'],
           [$missing_mask,'ifconfig'],[$missing_header,'ifconfig'],[$invalid_header,'ifconfig'],
           [$oversize,'ip-json']) {
    ($rc,$out,$err) = run_tool('--input',$t->[0],'--format',$t->[1]);
    is($rc,3,'malformed or oversized fixture rejected');
    is($out,'','input error produces no partial inventory');
    like($err,qr/\Anetwork-interface-report: /,'sanitized input diagnostic');
    unlike($err,qr/PRIVATE_INJECTION|INJECTED PRIVATE|$tmp/,'private content/path hidden');
}
my $link="$tmp/snapshot-link";
symlink($lin,$link) or die "symlink test unavailable: $!";
($rc,$out,$err)=run_tool('--input',$link);
is($rc,3,'symlinked snapshot rejected');
is($out,'','symlink refusal emits no report');
unlike($err,qr/\Q$link\E/,'symlink name hidden');
# The native command test is deliberately excluded. CI runners can have
# different interfaces, permissions, formats, or no `ip` installed at all.
# Production behaviour will be assessed separately on a known host.
done_testing();
