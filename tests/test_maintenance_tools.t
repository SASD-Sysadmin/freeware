#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use File::Copy qw(copy);
use FindBin;

my $bin = File::Spec->catdir($FindBin::Bin, '..', 'bin');
my $root = tempdir('sasd-maintenance-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $outside = tempdir('sasd-maintenance-outside-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $nested = File::Spec->catdir($root, 'nested space');
make_path($nested);
my $file = File::Spec->catfile($nested, 'normal');
my $open_file = File::Spec->catfile($nested, "writable\nfile");
my $sticky = File::Spec->catdir($root, 'sticky');
make_path($sticky);
my $plain_dir = File::Spec->catdir($root, 'public');
make_path($plain_dir);

sub make_file {
    my ($path, $body) = @_;
    open my $handle, '>', $path or die "cannot create fixture $path: $!";
    print {$handle} $body;
    close($handle) or die "cannot close fixture $path: $!";
}
sub run_tool {
    my ($command, @args) = @_;
    my $program = File::Spec->catfile($bin, $command);
    open my $pipe, '-|', $^X, $program, @args
        or die "cannot execute $program: $!";
    binmode($pipe);
    local $/;
    my $out = <$pipe>;
    close($pipe);
    return (defined $out ? $out : '', $? >> 8);
}
make_file($file, 'keep');
make_file($open_file, 'unchanged');
make_file(File::Spec->catfile($outside, 'secret'), 'outside');
my $valid_link = File::Spec->catfile($root, 'valid');
my $broken = File::Spec->catfile($root, "broken\nlink");
my $loop = File::Spec->catfile($root, 'cycle');
my $outside_link = File::Spec->catfile($root, 'external-directory');
my $symlink_ok = eval {
    symlink($file, $valid_link) or die $!;
    symlink('missing-target', $broken) or die $!;
    symlink('cycle', $loop) or die $!;
    symlink($outside, $outside_link) or die $!;
    1;
};

for my $command (qw(link-audit owner-audit permission-audit)) {
    my ($out, $rc) = run_tool($command, '--help');
    is($rc, 0, "$command help succeeds");
    like($out, qr/Usage: \Q$command\E/, "$command synopsis is present");
    ($out, $rc) = run_tool($command, '--version');
    is($rc, 0, "$command version succeeds");
    like($out, qr/\A\Q$command\E 0\.1\.0\n\z/, "$command version identifies itself");
    ($out, $rc) = run_tool($command, File::Spec->catdir($root, 'no-such-directory'));
    is($rc, 1, "$command refuses nonexisting scan root");
    ($out, $rc) = run_tool($command, '--wrong-option', $root);
    is($rc, 2, "$command rejects unsupported option");
    ($out, $rc) = run_tool($command, '--one-file-system', $root);
    is($rc, 0, "$command accepts one-filesystem scan");
    if ($symlink_ok) {
        ($out, $rc) = run_tool($command, $valid_link);
        is($rc, 1, "$command refuses symbolic-link scan root");
    }
}

SKIP: {
    skip 'symbolic links unsupported by filesystem', 11 unless $symlink_ok;
    my ($out, $rc) = run_tool('link-audit', $root);
    is($rc, 0, 'link-audit reports dangling and loops successfully');
    like($out, qr/^STATUS\tPATH\tTARGET\n/, 'link-audit shows report header');
    like($out, qr/^dangling\t[^\n]*broken\\x0Alink\tmissing-target$/m,
        'dangling link and escaped newline shown');
    like($out, qr/^loop\t[^\n]*cycle\tcycle$/m, 'link cycle distinguished');
    unlike($out, qr/^valid\t/m, 'valid links omitted by default');
    unlike($out, qr/external-directory\/secret/, 'external symlink directory not traversed');
    like($out, qr/Symlinks scanned: 4\nFindings: 2\nErrors: 0\n/,
        'four symlinks scanned, only two findings');
    ($out, $rc) = run_tool('link-audit', '--all', $root);
    is($rc, 0, 'link-audit all mode succeeds');
    like($out, qr/^valid\t/m, 'all mode displays valid symlinks');
    ($out, $rc) = run_tool('link-audit', '--null', $root);
    is($rc, 0, 'link-audit NUL output succeeds');
    like($out, qr/dangling\0\Q$broken\E\0missing-target\0/,
        'NUL output preserves literal pathname with newline');
}

my ($out, $rc) = run_tool('owner-audit', $root);
is($rc, 0, 'owner-audit default inventory succeeds');
like($out, qr/^ISSUE\tUID\tGID\tPATH\n/, 'owner-audit has parseable columns');
like($out, qr/Entries scanned: \d+\nUnresolved entries: 0\nErrors: 0\n/,
    'name service resolves locally created objects');
($out, $rc) = run_tool('owner-audit', '--scope', 'user', $root);
is($rc, 0, 'owner-audit user scope succeeds');
($out, $rc) = run_tool('owner-audit', '--scope', 'group', '--null', $root);
is($rc, 0, 'owner-audit group NUL mode succeeds');
is($out, '', 'owner-audit emits no NUL findings when all groups resolve');
($out, $rc) = run_tool('owner-audit', '--scope', 'neither', $root);
is($rc, 2, 'owner-audit rejects invalid scope');

SKIP: {
    skip 'requires root to create unassigned UID and GID fixtures', 4 unless $> == 0;
    my $unowned = File::Spec->catfile($nested, 'unassigned');
    make_file($unowned, 'not removed');
    my $unknown = 2147483000;
    chown($unknown, $unknown, $unowned) == 1
        or die "cannot chown controlled test file: $!";
    ($out, $rc) = run_tool('owner-audit', $nested);
    is($rc, 0, 'root fixture scan succeeds');
    like($out, qr/user\+group\t\Q$unknown\E\t\Q$unknown\E\t/, 'unknown UID and GID detected');
    ($out, $rc) = run_tool('owner-audit', '--scope', 'user', $nested);
    like($out, qr/^user\t\Q$unknown\E/m, 'user-only view works');
    ($out, $rc) = run_tool('owner-audit', '--scope', 'group', $nested);
    like($out, qr/^group\t\Q$unknown\E/m, 'group-only view works');
}

chmod(0666, $open_file) or die "cannot chmod controlled test file: $!";
chmod(0777, $plain_dir) or die "cannot chmod test directory: $!";
chmod(01777, $sticky) or die "cannot chmod test sticky directory: $!";
($out, $rc) = run_tool('permission-audit', $root);
is($rc, 0, 'permission-audit read-only scan succeeds');
like($out, qr/^TYPE\tMODE\tPATH\n/, 'permission-audit report header');
like($out, qr/^file\t0666\t[^\n]*writable\\x0Afile$/m,
    'world-writable file with escaped newline detected');
like($out, qr/^directory\t0777\t\Q$plain_dir\E$/m,
    'world-writable directory detected');
unlike($out, qr/sticky-directory/, 'sticky directory omitted by default');
unlike($out, qr/\Q$valid_link\E/, 'symlink permissions ignored');
($out, $rc) = run_tool('permission-audit', '--include-sticky', $root);
is($rc, 0, 'include sticky succeeds');
like($out, qr/^sticky-directory\t1777\t\Q$sticky\E$/m,
    'sticky world-writable directory classified separately');
($out, $rc) = run_tool('permission-audit', '--null', $root);
is($rc, 0, 'permission-audit NUL output succeeds');
like($out, qr/file\x00(?:0666)\x00\Q$open_file\E\x00/,
    'raw filename with newline remains intact in NUL output');

# Permission-denied directories and unresolved targets are not silently
# classified as clean or dangling. Avoid privilege-sensitive assumptions.
SKIP: {
    skip 'requires an unprivileged Unix account', 4 if $> == 0 || !$symlink_ok;
    my $private = File::Spec->catdir($root, 'private');
    make_path($private);
    make_file(File::Spec->catfile($private, 'present'), 'x');
    my $protected_link = File::Spec->catfile($root, 'inaccessible-target');
    symlink(File::Spec->catfile($private, 'present'), $protected_link) or die $!;
    chmod(0000, $private) or die "cannot protect fixture: $!";
    my ($result, $state) = run_tool('link-audit', $root);
    is($state, 1, 'indeterminate symlink status returns incomplete-scan status');
    like($result, qr/^unresolved\t[^\n]*inaccessible-target\t/m,
         'inaccessible target is not incorrectly called dangling');
    ($result, $state) = run_tool('permission-audit', $root);
    is($state, 1, 'unreadable directory makes permission inventory incomplete');
    like($result, qr/Errors: [1-9]\d*/, 'incomplete scan reported in summary');
    chmod(0700, $private) or die "cannot restore fixture mode: $!";
}

# Dependency checking and no unintended writes to scanned fixtures.
my $isolate = File::Spec->catdir($root, 'isolated');
make_path($isolate);
for my $command (qw(link-audit owner-audit permission-audit)) {
    my $copy = File::Spec->catfile($isolate, $command);
    copy(File::Spec->catfile($bin, $command), $copy) or die "copy: $!";
    open my $pipe, '-|', $^X, $copy, '--version' or die "cannot execute isolate: $!";
    local $/;
    my $message = <$pipe>;
    close $pipe;
    is($? >> 8, 3, "$command detects missing bundled library");
}
ok(-f $file && -s $file == 4, 'unchanged fixture retains content');
ok(-f $open_file && -s $open_file == 9, 'world-writable fixture retains content');

# File modes were not modified by the report tools.
is((stat($open_file))[2] & 0777, 0666, 'file mode remains unchanged');
is((stat($sticky))[2] & 07777, 01777, 'sticky directory mode remains unchanged');

done_testing();
