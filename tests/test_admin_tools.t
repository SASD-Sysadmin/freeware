#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IO::Socket::INET;

my $root = File::Spec->catdir($FindBin::Bin, '..');
my $bin = File::Spec->catdir($root, 'bin');
my $tmp = tempdir('sasd-admin-tools-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
sub path { File::Spec->catfile($tmp, @_) }
sub write_file {
    my ($name, $data) = @_;
    my $p = path($name);
    open my $fh, '>', $p or die "$p: $!";
    print {$fh} $data;
    close $fh or die "$p: $!";
    return $p;
}
sub run_tool {
    my ($tool,@args) = @_;
    my $exe = File::Spec->catfile($bin,$tool);
    open my $pipe, '-|', $^X, $exe, @args or die "cannot execute $exe: $!";
    local $/;
    my $out = <$pipe> // '';
    close $pipe;
    return ($? >> 8,$out);
}

for my $tool (qw(ssh-key-audit file-integrity suid-audit tcp-check)) {
    my ($rc,$out)=run_tool($tool,'--help');
    is($rc,0,"$tool --help exits zero");
    like($out,qr/Usage:/,"$tool usage text");
}

my $auth=write_file('authorized_keys', "# test keys\nssh-ed25519 YWJj test\nssh-rsa ZGVm\n");
chmod 0600,$auth or die "chmod: $!";
my ($rc,$out)=run_tool('ssh-key-audit','--file',$auth);
is($rc,0,'clean keys accepted');
like($out,qr/keys=2 warnings=0/,'two keys counted');
write_file('authorized_keys', "ssh-ed25519 YWJj test\nssh-ed25519 YWJj duplicate\nssh-dss ZGVm obsolete\ninvalid text\n");
($rc,$out)=run_tool('ssh-key-audit','--file',$auth);
is($rc,1,'suspicious keys produce nonzero status');
like($out,qr/duplicate public key/,'duplicate detected');
like($out,qr/legacy DSA/,'DSA warning');
like($out,qr/malformed public key/,'invalid line detected');
chmod 0666,$auth or die "chmod: $!";
($rc,$out)=run_tool('ssh-key-audit','--file',$auth);
like($out,qr/world-writable path/,'unsafe mode detected');
chmod 0600,$auth;

mkdir path('watched') or die $!;
write_file('watched/a','initial');
my $manifest=path('integrity.json');
($rc,$out)=run_tool('file-integrity','--root',path('watched'),'--manifest',$manifest,'--init');
is($rc,0,'integrity baseline created');
like($out,qr/BASELINE: files=1/,'one baseline entry');
($rc,$out)=run_tool('file-integrity','--root',path('watched'),'--manifest',$manifest,'--check');
is($rc,0,'unmodified files pass');
like($out,qr/changed=0 added=0 missing=0/,'stable summary');
($rc,$out)=run_tool('file-integrity','--root',path('watched'),'--manifest',$manifest,'--init');
isnt($rc,0,'refuses overwriting existing baseline');
write_file('watched/a','modified');
write_file('watched/new','new');
($rc,$out)=run_tool('file-integrity','--root',path('watched'),'--manifest',$manifest,'--check');
is($rc,1,'changes return finding status');
like($out,qr/CHANGED: a/,'changed content detected');
like($out,qr/ADDED: new/,'new file detected');
unlink(path('watched/a')) or die $!;
($rc,$out)=run_tool('file-integrity','--root',path('watched'),'--manifest',$manifest);
like($out,qr/MISSING: a/,'removed file detected');
($rc,$out)=run_tool('file-integrity','--root',path('watched'), '--manifest', path('watched/baseline.json'),'--init');
isnt($rc,0,'baseline within watched directory refused');
symlink '/nonexistent/target', path('watched/link') or die $!;
($rc,$out)=run_tool('file-integrity','--root',path('watched'),'--manifest',$manifest);
like($out,qr/added=1/,'symlinks are skipped without failing');

mkdir path('priv') or die $!;
my $normal = write_file('priv/normal','ordinary');
my $special = write_file('priv/executable','#!/bin/true');
chmod 04755,$special or die "chmod setuid: $!";
($rc,$out)=run_tool('suid-audit','--root',path('priv'));
is($rc,0,'suid inventory success');
like($out,qr/SUID mode=4755/,'SUID file discovered');
like($out,qr/scanned=2 privileged=1/,'file count correct');
symlink('executable',path('priv/sym')) or die $!;
($rc,$out)=run_tool('suid-audit','--root',path('priv'));
like($out,qr/scanned=2 privileged=1/,'symlink not followed');
($rc)=run_tool('suid-audit','--root',path('missing'));
isnt($rc,0,'missing root refused');

my $server = IO::Socket::INET->new(LocalAddr=>'127.0.0.1', LocalPort=>0,
                                    Listen=>2, ReuseAddr=>1, Proto=>'tcp')
    or die "cannot bind loopback test socket: $!";
my $port = $server->sockport;
($rc,$out)=run_tool('tcp-check','--host','127.0.0.1','--port',$port,'--timeout',1);
is($rc,0,'localhost listening port reachable');
like($out,qr/^OK:/,'success output');
close $server;
($rc,$out)=run_tool('tcp-check','--host','127.0.0.1','--port',$port,'--timeout',1,'--nagios');
is($rc,2,'Nagios critical exit code on failed connect');
like($out,qr/^CRITICAL:/,'Nagios critical output');
($rc)=run_tool('tcp-check','--host','127.0.0.1','--port',65536);
is($rc,2,'invalid port refused');

done_testing();
