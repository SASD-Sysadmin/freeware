#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Copy qw(copy);
use FindBin;
use Cwd qw(abs_path);
my $project = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $bin = File::Spec->catdir($project, 'bin');
my $tmp = tempdir('sasd-disks-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);

sub put {
    my ($where, $data) = @_;
    open my $fh, '>', $where or die "$where: $!";
    binmode $fh;
    print {$fh} $data;
    close $fh or die "$where: $!";
}
sub call {
    my ($name, @args) = @_;
    my $script = File::Spec->catfile($bin, $name);
    my $fh;
    open($fh, '-|', $^X, $script, @args) or die "cannot launch $script: $!";
    binmode $fh;
    local $/;
    my $out = <$fh>;
    $out = '' unless defined $out;
    close $fh;
    return ($? >> 8, $out);
}
my $dir = File::Spec->catdir($tmp, 'space test');
mkdir $dir or die $!;
my $sub = File::Spec->catdir($dir, 'sub');
mkdir $sub or die $!;
my $small = File::Spec->catfile($dir, 'a');
my $med = File::Spec->catfile($dir, 'medium file');
my $large = File::Spec->catfile($sub, 'large');
my $newline = File::Spec->catfile($sub, "odd\nname");
put($small, 'abc');
put($med, '1234567890');
put($large, 'x' x 20);
put($newline, 'y' x 20);
symlink 'sub', File::Spec->catfile($dir, 'linked') or die "symlink: $!";
link $small, File::Spec->catfile($dir, 'hardlink') or die "hardlink: $!";
my ($rc, $out) = call('fs-report', $dir);
is($rc, 0, 'inventory succeeds');
like($out, qr/Directories: 2\n/, 'counts root and child directory');
like($out, qr/Regular files: 5\n/, 'hardlinked pathname counted separately');
like($out, qr/Symbolic links: 1\n/, 'symlink not followed');
like($out, qr/File bytes \(logical\): 56\n/, 'logical sizes include all five entries');
like($out, qr/odd\\x0Aname/, 'control character escaped in inventory');
($rc, $out) = call('fs-report', '--one-file-system', '--top', '0', $dir);
is($rc, 0, 'one device inventory succeeds');
unlike($out, qr/^20\t/m, 'top zero suppresses file list');
($rc) = call('fs-report', '--min-size', '1T', $dir);
is($rc, 0, 'large threshold accepted');
($rc) = call('fs-report', '--top', '1001', $dir);
is($rc, 2, 'huge top rejected');
($rc) = call('fs-report', '--min-size', '9007199254740992', $dir);
is($rc, 2, 'nonexact integer rejected');
($rc) = call('fs-report', File::Spec->catfile($dir, 'missing'));
is($rc, 3, 'missing directory rejected');
($rc) = call('fs-report', File::Spec->catfile($dir, 'linked'));
is($rc, 3, 'symlink root rejected');
($rc, $out) = call('largefiles', '--min-size', '10', '--top', '1', $dir);
is($rc, 0, 'largefiles succeeds');
like($out, qr/Matches: 3\n/, 'all matches counted with top one');
like($out, qr/Logical bytes: 50\n/, 'all matches totaled with top one');
is(scalar(() = $out =~ /^20\t/gm), 1, 'only one top entry displayed');
($rc, $out) = call('largefiles', '--min-size', '20', '--all', $dir);
is($rc, 0, 'all matching files enumerated');
is(scalar(() = $out =~ /^20\t/gm), 2, 'two 20-byte entries reported');
($rc, $out) = call('largefiles', '--min-size', '20', '--null', $dir);
is($rc, 0, 'NUL mode succeeds');
like($out, qr/20\0\Q$newline\E\0/, 'embedded newline is unmodified in NUL output');
unlike($out, qr/Matches:/, 'NUL mode excludes summary');
($rc, $out) = call('largefiles', '--min-size', '999M', $dir);
is($rc, 0, 'no matches is successful');
like($out, qr/Matches: 0\n/, 'zero count reported');
($rc) = call('largefiles', '--top', '0', $dir);
is($rc, 2, 'top zero is invalid for largefiles');
($rc) = call('largefiles', '--min-size', '1X', $dir);
is($rc, 2, 'invalid size suffix rejected');
($rc) = call('largefiles', '--min-size', '9999999999999999T', $dir);
is($rc, 2, 'overflowing size rejected');
($rc) = call('largefiles', File::Spec->catfile($dir, 'linked'));
is($rc, 3, 'largefiles rejects symlink root');
($rc, $out) = call('fs-report', '--version');
is($rc, 0, 'fs-report version succeeds');
like($out, qr/^fs-report /, 'fs-report version identified');
($rc, $out) = call('largefiles', '--help');
is($rc, 0, 'largefiles help succeeds');
like($out, qr/--one-file-system/, 'largefiles help options');

# Missing bundled modules must fail explicitly before scanning.
my $isolated = File::Spec->catdir($tmp, 'isolated');
mkdir $isolated or die $!;
copy(File::Spec->catfile($bin, 'largefiles'),
     File::Spec->catfile($isolated, 'largefiles')) or die $!;
my $isolated_fh;
open($isolated_fh, '-|', $^X, File::Spec->catfile($isolated, 'largefiles'), $dir)
    or die $!;
{ local $/; scalar(<$isolated_fh>); }
close $isolated_fh;
is($? >> 8, 3, 'missing bundled Perl library fails with prerequisite status 3');

my $fakebin = File::Spec->catdir($tmp, 'bin');
mkdir $fakebin or die $!;
my $df = File::Spec->catfile($fakebin, 'df');
my $quota = File::Spec->catfile($fakebin, 'quota');
my $repquota = File::Spec->catfile($fakebin, 'repquota');
put($df, "#!/bin/sh\nprintf '%s\\n' 'Filesystem 1024-blocks Used Available Capacity Mounted on' '/dev/test disk 1000 800 200 80% /mount with space'\n");
chmod 0755, $df;
{
    local $ENV{PATH} = $fakebin;
    ($rc, $out) = call('fs-usage', '--warn', '80', '--critical', '95', $dir);
    is($rc, 1, 'warning threshold yields nonzero');
    like($out, qr/WARNING\t80\t800\t200\t1000\t\/dev\/test disk\t\/mount with space/, 'df output parsed with spaces');
    ($rc, $out) = call('fs-usage', '--warn', '81', $dir);
    is($rc, 0, 'below warning threshold is OK');
    ($rc) = call('fs-usage', '--critical', '80', $dir);
    is($rc, 1, 'critical threshold yields nonzero');
    ($rc) = call('fs-usage', '--critical', '40', '--warn', '50', $dir);
    is($rc, 2, 'critical less than warning rejected');
    ($rc) = call('fs-usage', '--warn', '101', $dir);
    is($rc, 2, 'percentage above 100 rejected');
}
put($df, "#!/bin/sh\necho 'arbitrary output'\n");
chmod 0755, $df;
{
    local $ENV{PATH} = $fakebin;
    ($rc) = call('fs-usage', $dir);
    is($rc, 3, 'unknown df format rejected');
}
put($df, "#!/bin/sh\nexit 4\n");
chmod 0755, $df;
{
    local $ENV{PATH} = $fakebin;
    ($rc) = call('fs-usage', $dir);
    is($rc, 3, 'df nonzero exit propagated as failure');
    ($rc) = call('fs-usage', '/not/a/path/that/exists');
    is($rc, 3, 'missing requested path rejected');
}
{
    local $ENV{PATH} = '/no-such-binaries';
    ($rc) = call('fs-usage', $dir);
    is($rc, 3, 'missing df has dedicated status');
    ($rc) = call('quota-report');
    is($rc, 3, 'missing quota has dedicated status');
    ($rc) = call('quota-report', '--all');
    is($rc, 3, 'missing repquota has dedicated status');
}
put($quota, "#!/bin/sh\nprintf '%s\\n' \"\$@\"\n");
put($repquota, "#!/bin/sh\nprintf '%s\\n' \"\$@\"\n");
chmod 0755, $quota, $repquota;
{
    local $ENV{PATH} = $fakebin;
    ($rc, $out) = call('quota-report');
    is($rc, 0, 'default quota invocation succeeds');
    is($out, "-v\n", 'default quota switches correct');
    ($rc, $out) = call('quota-report', '--user', 'alice');
    is($rc, 0, 'quota for selected user succeeds');
    is($out, "-v\nalice\n", 'selected user passed as argument');
    ($rc, $out) = call('quota-report', '--group', 'staff');
    is($rc, 0, 'group quota succeeds');
    is($out, "-v\n-g\nstaff\n", 'group flag and name passed correctly');
    ($rc, $out) = call('quota-report', '--all');
    is($rc, 0, 'repquota invocation succeeds');
    is($out, "-a\n", 'all mode uses repquota -a');
    ($rc) = call('quota-report', '--user', '-Z');
    is($rc, 2, 'option injection as account rejected');
    ($rc) = call('quota-report', '--user', 'bob;touch /tmp/never');
    is($rc, 2, 'shell injection string rejected');
    ($rc) = call('quota-report', '--user', 'alice', '--all');
    is($rc, 2, 'incompatible quota modes rejected');
    ($rc) = call('quota-report', '--help');
    is($rc, 0, 'quota help succeeds');
}
put($quota, "#!/bin/sh\nexit 7\n");
chmod 0755, $quota;
{
    local $ENV{PATH} = $fakebin;
    ($rc) = call('quota-report');
    is($rc, 3, 'quota backend failure handled');
}
($rc) = call('fs-usage', '--version');
is($rc, 0, 'fs-usage version succeeds');
($rc) = call('quota-report', '--version');
is($rc, 0, 'quota-report version succeeds');
# Read-only assurance: files used in inventory remain unchanged.
open my $check, '<', $med or die $!;
local $/; my $original = <$check>; close $check;
is($original, '1234567890', 'input data unchanged');
done_testing();
