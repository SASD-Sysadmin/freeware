#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use IPC::Open3;
use Symbol qw(gensym);
use FindBin;
my $root = tempdir('sasd-account-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $bin = File::Spec->catdir($FindBin::Bin,'..','bin');
my $sbin = File::Spec->catdir($FindBin::Bin,'..','sbin');
my $passwd = File::Spec->catfile($root,'passwd');
my $groups = File::Spec->catfile($root,'group');
my $home = File::Spec->catdir($root,'safe home');
my $unowned = File::Spec->catdir($root,'other home');
my $missing = File::Spec->catdir($root,'missing home');
my $symlink = File::Spec->catfile($root,'linked-home');
make_path($home,$unowned);
chmod 0750, $home;
chmod 0777, $unowned;
symlink($home,$symlink) or die "symlink fixture unavailable: $!";
my $uid = $<;
sub save {
    my ($name,$data) = @_;
    open my $fh, '>', $name or die "cannot create fixture: $!";
    print {$fh} $data;
    close $fh or die "cannot save fixture: $!";
}
save($passwd,
    "sample:x:$uid:$uid:Test Account:$home:/bin/sh\n" .
    "missing:x:25001:25001:Missing:$missing:/bin/sh\n" .
    "linked:x:25002:25002:Linked:$symlink:/bin/sh\n" .
    "other:x:25003:25003:Other:$unowned:/bin/sh\n" .
    "+::::::\n" .
    "broken:with:too:few\n");
save($groups,
    "sample:x:$uid:sample\n" .
    "duplicate:x:$uid:sample,sample\n" .
    "sample:x:25003:\n" .
    "invalid:x:25004:sample,,bad!member\n" .
    "+::::\n" .
    "broken:too:few\n");
sub run {
    my ($command,@args) = @_;
    my $path = $command eq 'account-manage'
        ? File::Spec->catfile($sbin,$command)
        : File::Spec->catfile($bin,$command);
    my $err = gensym();
    my $pid = open3(undef,my $out,$err,$^X,$path,@args);
    local $/;
    my $stdout = <$out>;
    my $stderr = <$err>;
    close $out; close $err;
    waitpid($pid,0);
    return (defined($stdout)?$stdout:'', ($? >> 8), defined($stderr)?$stderr:'');
}
for my $command (qw(account-inventory group-audit home-audit account-manage)) {
    my ($out,$rc) = run($command,'--help');
    is($rc,0,"$command --help succeeds");
    like($out,qr/Usage: \Q$command\E/,"$command usage supplied");
    ($out,$rc) = run($command,'--version');
    is($rc,0,"$command --version succeeds");
    like($out,qr/\A\Q$command\E 0\.1\.0\n\z/,"$command version identified");
}
my ($out,$rc,$err) = run('account-inventory','--source','local',
    '--passwd-file',$passwd,'--group-file',$groups);
is($rc,1,'invalid local passwd and group records make inventory nonzero');
like($out,qr/user\tsample\t$uid\t$uid\t/, 'local passwd record appears');
like($out,qr/group\tsample\t\t$uid\t/, 'local group record appears');
like($out,qr/Invalid records: 2\n/, 'both invalid records counted');
like($out,qr/NIS compatibility records skipped: 2\n/, 'compatibility records counted separately');
like($err,qr/NIS compatibility record skipped/, 'compatibility record warning is explicit');
($out,$rc) = run('account-inventory','--source','local','--kind','users',
    '--passwd-file',$passwd,'--null');
is($rc,1,'NUL inventory still propagates record errors');
like($out,qr/user\x00sample\x00\Q$uid\E\x00\Q$uid\E\x00\Q$home\E\x00\/bin\/sh\x00\x00/,
    'NUL output preserves complete account fields');
unlike($out,qr/TYPE\tNAME/,'NUL output has no human header');
($out,$rc) = run('account-inventory','--source','nss','--kind','users');
is($rc,0,'NSS enumeration interface succeeds on current host');
like($out,qr/^TYPE\tNAME/m,'NSS inventory displays header');
($out,$rc) = run('account-inventory','--source','oops');
is($rc,2,'invalid inventory source is rejected');
($out,$rc) = run('account-inventory','--kind','users','--passwd-file',"$root/missing");
is($rc,3,'missing local identity file produces prerequisite status');
($out,$rc) = run('account-inventory','--source','nss','--passwd-file', $passwd);
is($rc,2,'NSS source and local fixtures cannot be mixed');

($out,$rc,$err) = run('group-audit','--file',$groups);
is($rc,1,'malformed group file fails the audit');
like($out,qr/Groups: 4\n/,'group audit counts valid records');
like($err,qr/shared GID/,'duplicate group GID detected');
like($err,qr/duplicate group name/,'duplicate group name detected');
like($err,qr/duplicate member/,'duplicate member detected');
like($err,qr/invalid member/,'invalid group member detected');
like($err,qr/NIS compatibility record skipped/,'NIS compatibility record not treated as a group');
($out,$rc) = run('group-audit','--file',"$root/missing");
is($rc,3,'missing group file is reported');
($out,$rc) = run('group-audit','--weird');
is($rc,2,'invalid group-audit switch refused');

($out,$rc,$err) = run('home-audit','--file',$passwd,'--all');
is($rc,1,'home audit reports malformed passwd records');
like($out,qr/missing\tmissing\t25001\t\Q$missing\E/, 'missing home reported');
like($out,qr/symlink\tlinked\t25002\t\Q$symlink\E/, 'symlink home not followed');
like($out,qr/wrong-owner\tother\t25003\t\Q$unowned\E/, 'unexpected home owner reported');
like($out,qr/world-writable\tother\t25003\t\Q$unowned\E/,'world-writable home reported');
like($out,qr/Accounts checked: 4\nFindings: 4\nErrors: 1\n/,'home summary keeps findings and parsing errors distinct');
($out,$rc) = run('home-audit','--file',$passwd,'--all','--null');
is($rc,1,'NUL home audit retains parse error exit');
like($out,qr/missing\x00missing\x0025001\x00\Q$missing\E\x00/, 'NUL home record has exact fields');
unlike($out,qr/ISSUE\tUSER/,'NUL home records have no header');
($out,$rc) = run('home-audit','--file',$passwd,'--min-uid','50000');
is($rc,1,'high minimum UID accepted without truncation');
unlike($out,qr/wrong-owner/,'UID filtering excludes lower UID accounts');
($out,$rc) = run('home-audit','--min-uid','60000','--max-uid','1000');
is($rc,2,'invalid UID interval refused');
($out,$rc) = run('home-audit','--file',"$root/missing");
is($rc,3,'missing passwd file is reported');

my $newname = 'sasd_unittest_24918';
($out,$rc) = run('account-manage','--action','user-create','--name',$newname);
is($rc,0,'user-create preview succeeds');
like($out,qr/Mode: dry-run \(no changes\)/,'preview is explicit');
like($out,qr/Planned command: useradd -m -- /,'user-create uses native backend with home creation');
($out,$rc) = run('account-manage','--action','group-create','--name',$newname);
is($rc,0,'group-create preview succeeds');
like($out,qr/Planned command: groupadd -- /,'group-create backend explicitly shown');
($out,$rc) = run('account-manage','--action','password-lock','--name','root');
is($rc,2,'root password locking is refused');
($out,$rc) = run('account-manage','--action','password-lock','--name',$newname);
is($rc,3,'remote/unknown account cannot be password locked');
($out,$rc) = run('account-manage','--action','user-create','--name','root');
is($rc,2,'root name cannot be created');
my $known_user = defined(scalar(getpwnam('nobody'))) ? 'nobody' : scalar(getpwuid($<));
SKIP: {
    skip 'no known non-root NSS account',1 if !defined($known_user) || $known_user eq 'root';
    ($out,$rc) = run('account-manage','--action','user-create','--name',$known_user);
    is($rc,3,'existing NSS user cannot be created a second time');
}
($out,$rc) = run('account-manage','--action','user-create','--name','-h');
is($rc,2,'option injection name rejected');
($out,$rc) = run('account-manage','--action','group-create','--name','x;touch');
is($rc,2,'shell metacharacters rejected');
($out,$rc) = run('account-manage','--action','user-create','--name','machine\$');
is($rc,2,'dollar-suffixed machine accounts are not created by this limited manager');
($out,$rc) = run('account-manage','--action','user-create','--name',$newname,
    '--apply');
is($rc,2,'apply without confirmation rejected');
($out,$rc) = run('account-manage','--action','group-create','--name',$newname,
    '--confirm-apply');
is($rc,2,'confirmation without apply rejected');
($out,$rc) = run('account-manage','--action','unknown','--name',$newname);
is($rc,2,'unknown management action rejected');
($out,$rc) = run('account-manage','--name',$newname);
is($rc,2,'action mandatory');
# A root invocation must reject an attacker-owned executable path; a nonroot
# invocation must reject the action before searching for any backend.
my $fakebin=File::Spec->catdir($root,'bin'); make_path($fakebin);
my $sentinel=File::Spec->catfile($root,'executed');
for my $command (qw(useradd groupadd usermod)) {
    my $tool=File::Spec->catfile($fakebin,$command);
    save($tool,"#!/bin/sh\nprintf executed > '$sentinel'\n");
    chmod 0755,$tool;
}
{
    local $ENV{PATH} = $fakebin;
    ($out,$rc,$err) = run('account-manage','--action','group-create','--name',$newname,
        '--apply','--confirm-apply');
}
is($rc,3,'an untrusted test backend or missing root privileges blocks mutation');
ok(!-e $sentinel,'unsafe backend was never executed');
# Prove non-mutating use of fixtures without touching real /etc files.
open my $check, '<', $passwd or die $!; local $/; my $after=<$check>; close $check;
like($after,qr/\+::::::/, 'passwd fixture remains unchanged');
open $check,'<',$groups or die $!; my $groups_after=<$check>;close $check;
like($groups_after,qr/invalid:x:25004/, 'group fixture remains unchanged');
done_testing();
