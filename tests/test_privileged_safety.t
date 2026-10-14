#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# All tests are unprivileged in effect: no account, quota or system mutation.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);
use JSON::PP;

my $project = File::Spec->catdir($FindBin::Bin, '..');
my $account = File::Spec->catfile($project, 'sbin', 'account-manage');
my $quota = File::Spec->catfile($project, 'sbin', 'quota-set');
my $integrity = File::Spec->catfile($project, 'bin', 'file-integrity');
my $tmp = tempdir('sasd-privileged-safety-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $fake_bin = File::Spec->catdir($tmp, 'fake-bin');
mkdir $fake_bin or die "mkdir $fake_bin: $!";
my $backend_log = File::Spec->catfile($tmp, 'backend-invoked');

# If a protected operation unexpectedly calls useradd/groupadd/usermod or
# setquota, an isolated fake executable records the violation. Never invoke
# the real system commands in CI, even when a runner happens to be root.
for my $program (qw(useradd groupadd usermod setquota)) {
    my $fake = File::Spec->catfile($fake_bin, $program);
    open my $fh, '>', $fake or die "open $fake: $!";
    print {$fh} "#!$^X\n";
    print {$fh} 'open my $fh, ">>", $ENV{SASD_BACKEND_LOG} or die $!; print {$fh} "invoked\\n"; close $fh; exit 77;', "\n";
    close $fh or die "close $fake: $!";
    chmod 0755, $fake or die "chmod $fake: $!";
}

sub run_tool {
    my ($program, @arguments) = @_;
    local $ENV{PATH} = $fake_bin; # No real privileged binary can be resolved.
    local $ENV{SASD_BACKEND_LOG} = $backend_log;
    my $stderr_handle = gensym();
    my $pid = open3(undef, my $stdout_handle, $stderr_handle,
                    $^X, $program, @arguments);
    local $/;
    my $stdout = <$stdout_handle> // '';
    my $stderr = <$stderr_handle> // '';
    close $stdout_handle;
    close $stderr_handle;
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}

sub untouched {
    ok(!-e $backend_log, $_[0]);
}

# Deliberately avoid ever passing both approval switches to account-manage.
# These checks must be harmless even when the test runner has effective UID 0.
my $new_user = 'sasd_m2_safety_93641';
for my $action (qw(user-create group-create password-lock)) {
    my ($rc, $out, $err) = run_tool($account,
        '--action', $action, '--name', $new_user, '--apply');
    is($rc, 2, "$action refuses --apply without --confirm-apply");
    like($err, qr/confirm-apply/, "$action explains the approval requirement");
    untouched("$action did not call an account backend");
}
my ($rc, $out, $err) = run_tool($account, '--action', 'user-create',
                               '--name', $new_user, '--confirm-apply');
is($rc, 2, 'confirmation switch without apply is invalid');
untouched('no account backend after invalid approval combination');

my $known_user = getpwuid($<);
SKIP: {
    skip 'current UID has no resolvable NSS name', 7 unless defined $known_user;
    my @limits = ('--user', $known_user, '--filesystem', '/',
                  '--block-soft', '1', '--block-hard', '2',
                  '--inode-soft', '3', '--inode-hard', '4');
    ($rc, $out, $err) = run_tool($quota, @limits);
    is($rc, 0, 'quota-set defaults to a read-only preview');
    like($out, qr/dry-run/, 'quota preview is visibly non-mutating');
    untouched('quota preview does not invoke setquota');
    ($rc, $out, $err) = run_tool($quota, @limits, '--apply');
    is($rc, 2, 'quota apply without explicit confirmation is rejected');
    untouched('unconfirmed quota cannot call backend');
    ($rc, $out, $err) = run_tool($quota, @limits,
        '--inode-soft', '0', '--apply', '--confirm-apply');
    is($rc, 2, 'unlimited quota requires separate explicit acknowledgment');
    untouched('unacknowledged unlimited quota cannot call backend');
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $contents or die "write $path: $!";
    close $fh or die "close $path: $!";
}
sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}
sub no_staging_files {
    opendir my $dir, $tmp or die "opendir $tmp: $!";
    my @staged = grep { /^\.sasd-integrity-/ } readdir $dir;
    closedir $dir;
    is_deeply(\@staged, [], $_[0]);
}

my $watched = File::Spec->catdir($tmp, 'watched');
mkdir $watched or die "mkdir $watched: $!";
write_file(File::Spec->catfile($watched, 'a.txt'), 'original');
my $manifest = File::Spec->catfile($tmp, 'baseline.json');
($rc, $out, $err) = run_tool($integrity, '--root', $watched,
                            '--manifest', $manifest, '--init');
is($rc, 0, 'baseline initializes in a private temporary directory');
ok(-f $manifest, 'finished manifest exists');
is((stat($manifest))[2] & 0777, 0600, 'baseline manifest is private (0600)');
my $original = slurp($manifest);
my $decoded = decode_json($original);
is($decoded->{format}, 'sasd-integrity-v1', 'baseline schema preserved');
no_staging_files('successful publication leaves no private staging file');

($rc, $out, $err) = run_tool($integrity, '--root', $watched,
                            '--manifest', $manifest, '--init');
ok($rc != 0, 'reinitialization cannot overwrite the existing manifest');
is(slurp($manifest), $original, 'existing baseline content is unchanged');
no_staging_files('failed reinitialization removes private staging file');

my $victim = File::Spec->catfile($tmp, 'protected-data');
write_file($victim, 'DO NOT REPLACE');
my $link_manifest = File::Spec->catfile($tmp, 'baseline-link.json');
symlink($victim, $link_manifest) or die "symlink: $!";
($rc, $out, $err) = run_tool($integrity, '--root', $watched,
                            '--manifest', $link_manifest, '--init');
ok($rc != 0, 'symlink manifest is rejected');
is(slurp($victim), 'DO NOT REPLACE', 'symlink target data unchanged');
no_staging_files('symlink refusal leaves no staging files');

my $internal = File::Spec->catfile($watched, 'inside.json');
($rc, $out, $err) = run_tool($integrity, '--root', $watched,
                            '--manifest', $internal, '--init');
ok($rc != 0, 'baseline within the observed tree is refused');
ok(!-e $internal, 'no internal baseline was created');

write_file(File::Spec->catfile($watched, 'a.txt'), 'modified');
($rc, $out, $err) = run_tool($integrity, '--root', $watched,
                            '--manifest', $manifest, '--check');
is($rc, 1, 'changed watched file reports finding status');
like($out, qr/CHANGED: a\.txt/, 'changed file correctly identified');
is(slurp($manifest), $original, 'read-only check never updates the baseline');

done_testing();
