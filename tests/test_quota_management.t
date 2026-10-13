#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use Cwd qw(realpath);
use IPC::Open3;
use Symbol qw(gensym);
my $root = realpath("$FindBin::Bin/..");
my $quota_set = "$root/sbin/quota-set";
my $quota_status = "$root/bin/quota-status";
my $temp = tempdir('sasd-quota-tests-XXXXXX', TMPDIR => 1, CLEANUP => 1);
my $mockdir = "$temp/fake-bin";
mkdir $mockdir or die "mkdir $mockdir: $!";
my $out_file = "$temp/stdout";
my $err_file = "$temp/stderr";
my $log_file = "$temp/invoked";

my $setquota_stub = "#!$^X\n" . <<'STUB';
use strict;
use warnings;
open my $log, '>', $ENV{SASD_TEST_LOG} or die "cannot open fake log: $!";
for my $arg (@ARGV) { print {$log} "$arg\n"; }
close $log or die $!;
exit(defined($ENV{SASD_TEST_EXIT}) ? $ENV{SASD_TEST_EXIT} : 0);
STUB
my $quotaon_stub = "#!$^X\n" . <<'STUB';
use strict;
use warnings;
open my $log, '>', $ENV{SASD_TEST_LOG} or die $!;
for my $arg (@ARGV) { print {$log} "$arg\n"; }
close $log or die $!;
print "quotaon mock status\n";
exit(defined($ENV{SASD_TEST_EXIT}) ? $ENV{SASD_TEST_EXIT} : 0);
STUB
for my $spec (['setquota', $setquota_stub], ['quotaon', $quotaon_stub]) {
    my ($name, $body) = @$spec;
    open my $file, '>', "$mockdir/$name" or die $!;
    print {$file} $body;
    close $file or die $!;
    chmod 0755, "$mockdir/$name" or die $!;
}

sub invoke {
    my ($program, $path, $return_code, @args) = @_;
    unlink $log_file;
    local $ENV{PATH} = $path;
    local $ENV{SASD_TEST_LOG} = $log_file;
    local $ENV{SASD_TEST_EXIT} = defined($return_code) ? $return_code : 0;
    my $child_error = gensym();
    my $pid = open3(undef, my $child_out, $child_error, $^X, $program, @args);
    local $/;
    my $stdout = <$child_out>;
    my $stderr = <$child_error>;
    close $child_out;
    close $child_error;
    waitpid($pid, 0);
    my $code = $? >> 8;
    my $logged;
    if (-f $log_file) {
        open my $fh, '<', $log_file or die $!;
        $logged = <$fh>;
        close $fh;
    }
    return ($code, $stdout, $stderr, $logged);
}

my $name = getpwuid($<);
my $gid = (split(/\s+/, $( ))[0];
my $group = getgrgid($gid);
defined $name && defined $group or die 'the test account must resolve in NSS';
my @basic = ('--user', $name, '--filesystem', '/',
             '--block-soft', '1024', '--block-hard', '2048',
             '--inode-soft', '10', '--inode-hard', '20');
my ($rc, $stdout, $stderr, $logged);

($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,'--help');
is($rc, 0, 'quota-set --help succeeds');
like($stdout, qr/--confirm-apply/, 'apply confirmation is documented');
($rc,$stdout) = invoke($quota_set,$mockdir,0,'--version');
is($rc,0,'quota-set --version succeeds');
like($stdout, qr/\Aquota-set /, 'quota-set version names utility');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic);
is($rc,0,'quota-set default is dry-run');
like($stdout, qr/dry-run \(no changes\)/, 'dry-run clearly identified');
like($stdout, qr/Block soft \(KiB\): 1024/, 'block units and value printed');
ok(!defined($logged),'dry-run never calls setquota');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,'/not/a/path',0,@basic);
is($rc,0,'dry-run needs no installed setquota');
ok(!defined($logged),'missing backend dry-run does not execute anything');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--apply');
is($rc,2,'apply without confirmation refused');
like($stderr, qr/--confirm-apply/, 'confirmation requirement explained');
ok(!defined($logged),'missing confirmation never executes backend');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--confirm-apply');
is($rc,2,'confirmation alone is invalid');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--dry-run','--apply');
is($rc,2,'contradictory modes rejected');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--block-soft','999999');
is($rc,2,'soft block limit cannot exceed hard limit');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--inode-soft','30');
is($rc,2,'soft inode limit cannot exceed hard limit');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--block-hard','-1');
is($rc,2,'negative limit refused');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--block-hard','1M');
is($rc,2,'quota units do not accept ambiguous size suffixes');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--block-hard','9223372036854775808');
is($rc,2,'overflow limit refused');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--inode-hard','20','trailing');
is($rc,2,'positional arguments refused');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--user','--danger');
is($rc,2,'option-looking identity rejected');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--user','root;id');
is($rc,2,'shell metacharacters in account rejected');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--filesystem','relative/path');
is($rc,2,'relative filesystem path rejected');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--filesystem',"/tmp/evil\npath");
is($rc,2,'control characters in filesystem path rejected');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--filesystem',"$temp/absent");
is($rc,2,'missing filesystem directory refused');
symlink '/', "$temp/link" or die $!;
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--filesystem',"$temp/link");
is($rc,2,'symbolic link mountpoint refused');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--user','sasd_this_account_should_not_exist_zz');
is($rc,3,'unknown user refused');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--group',$group);
is($rc,2,'user and group options are exclusive');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--inode-soft','0');
is($rc,0,'zero quota can be previewed');
like($stdout, qr/zero limits are unlimited/, 'zero quota dry-run warns about unlimited value');
($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--inode-soft','0','--apply','--confirm-apply');
is($rc,2,'zero quota needs extra acknowledgment to apply');
like($stderr, qr/--allow-unlimited/, 'zero quota failure explains remedy');
ok(!defined($logged),'zero quota cannot accidentally call backend');

# An ordinary missing shared library has a controlled prerequisite status.
my $isolated = "$temp/isolated/sbin";
require File::Path;
File::Path::mkpath($isolated);
my $isolated_set = "$isolated/quota-set";
open my $source, '<', $quota_set or die $!;
open my $destination, '>', $isolated_set or die $!;
while (my $line = <$source>) { print {$destination} $line; }
close $source; close $destination;
($rc,$stdout,$stderr) = invoke($isolated_set,$mockdir,0,'--help');
is($rc,3,'missing bundled Perl library returns prerequisite status');
like($stderr,qr/required Perl module/, 'missing library diagnostic is explicit');

($rc,$stdout,$stderr,$logged) = invoke($quota_status,$mockdir,0,'--help');
is($rc,0,'quota-status help succeeds');
($rc,$stdout,$stderr,$logged) = invoke($quota_status,$mockdir,0,'--version');
is($rc,0,'quota-status version succeeds');
($rc,$stdout,$stderr,$logged) = invoke($quota_status,$mockdir,0);
is($rc,2,'quota-status requires a mode');
($rc,$stdout,$stderr,$logged) = invoke($quota_status,$mockdir,0,'--all','--filesystem','/');
is($rc,2,'quota-status modes are exclusive');
($rc,$stdout,$stderr,$logged) = invoke($quota_status,$mockdir,0,'--filesystem','relative');
is($rc,$^O eq 'linux' ? 2 : 3,'invalid status path or unsupported OS rejected');
SKIP: {
    skip 'quota-status backend is Linux-specific', 9 unless $^O eq 'linux';
    ($rc,$stdout,$stderr,$logged) = invoke($quota_status,$mockdir,0,'--all');
    is($rc,0,'quota-status all mock succeeds');
    like($stdout,qr/quotaon mock status/, 'quota-status streams native output');
    is($logged,"-p\n-a\n", 'quotaon print-only args for all');
    ($rc,$stdout,$stderr,$logged) = invoke($quota_status,$mockdir,0,'--filesystem','/');
    is($rc,0,'quota-status mountpoint mock succeeds');
    is($logged,"-p\n/\n", 'quotaon print-only mountpoint args');
    ($rc,$stdout,$stderr,$logged) = invoke($quota_status,'/not/a/path',0,'--all');
    is($rc,3,'missing quotaon dependency reported');
    like($stderr,qr/required command 'quotaon'/, 'missing quotaon named');
    ($rc,$stdout,$stderr,$logged) = invoke($quota_status,$mockdir,7,'--all');
    is($rc,3,'quotaon failure is nonzero');
    like($stderr,qr/status 7/, 'quotaon exit code retained in error');
}
SKIP: {
    skip 'apply test requires non-root Linux using a mock executable', 11
        unless $^O eq 'linux' && $> != 0;
    ($rc,$stdout,$stderr,$logged) = invoke($quota_set,'/not/a/path',0,@basic,'--apply','--confirm-apply');
    is($rc,3,'missing setquota aborts apply');
    like($stderr,qr/required command 'setquota'/, 'missing setquota named');
    ($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--apply','--confirm-apply');
    is($rc,0,'explicitly approved mock application succeeds');
    is($logged,"-u\n$name\n1024\n2048\n10\n20\n/\n", 'complete native setquota user arguments');
    like($stdout,qr/completed successfully/, 'success message avoids claiming verified read-back');
    ($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,9,@basic,'--apply','--confirm-apply');
    is($rc,3,'setquota backend failure aborts');
    like($stderr,qr/status 9/, 'backend failure details present');
    ($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,'--inode-soft','0','--apply','--confirm-apply','--allow-unlimited');
    is($rc,0,'explicit zero quota acknowledgment permits apply');
    like($logged,qr/\n0\n20\n/, 'zero inode soft forwarded to backend');
    ($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,'--group',$group,
       '--filesystem','/', '--block-soft','1','--block-hard','2',
       '--inode-soft','3','--inode-hard','4','--apply','--confirm-apply');
    is($rc,0,'group quota mock application succeeds');
    like($logged,qr/\A-g\n\Q$group\E\n1\n2\n3\n4\n\/\n\z/, 'group mode calls native setquota -g');
}
SKIP: {
    skip 'mountpoint check is Linux-only', 3 unless $^O eq 'linux';
    ($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,
        '--filesystem',$temp,'--apply','--confirm-apply');
    is($rc,3,'existing but unmounted directory cannot receive quota update');
    like($stderr,qr/not an exact mount point/, 'invalid mountpoint diagnostic');
    ok(!defined($logged),'unmounted directory never reaches setquota');
}
SKIP: {
    skip 'privileged backend trust check requires root Linux', 3
        unless $^O eq 'linux' && $> == 0;
    ($rc,$stdout,$stderr,$logged) = invoke($quota_set,$mockdir,0,@basic,
        '--apply','--confirm-apply');
    is($rc,3,'privileged use of untrusted backend directory is refused');
    like($stderr,qr/root-owned, non-writable directory chain/,
         'root backend trust diagnostic is actionable');
    ok(!defined($logged),'untrusted backend was never invoked');
}
SKIP: {
    skip 'symlink rejection is Linux-specific', 2 unless $^O eq 'linux';
    ($rc,$stdout,$stderr,$logged) = invoke($quota_status,$mockdir,0,
        '--filesystem',"$temp/link");
    is($rc,2,'quota-status rejects symlink mountpoint');
    ok(!defined($logged),'quota-status rejected argument before backend');
}
# Neither fake status tool nor quota-set should create or modify host settings.
ok(-e "$mockdir/setquota" && -e "$mockdir/quotaon", 'test uses isolated executable fixtures');
done_testing();
