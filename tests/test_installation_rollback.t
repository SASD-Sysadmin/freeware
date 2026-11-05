#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M9.3b – deterministic rollback-failure regression tests.
#
# These tests exercise the same rollback module as tools/installation.pl.
# Each simulated I/O failure is injected as a local Perl callback, not as a
# production installer option. No root, host installation, SIGKILL, kernel
# fault injection, external service, or network access is involved.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use Digest::SHA qw(sha256_hex);
use Errno qw(EACCES);
use FindBin;
use lib "$FindBin::Bin/../tools/lib";
use SASD::Freeware::InstallRollback qw(rollback_installation);

my $tmp = tempdir('sasd-m93b-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);

sub write_file {
    my ($path, $contents) = @_;
    open my $out, '>', $path or die "cannot create $path: $!";
    binmode $out;
    print {$out} $contents or die "cannot write $path: $!";
    close $out or die "cannot close $path: $!";
}
sub read_file {
    my ($path) = @_;
    open my $in, '<', $path or die "cannot read $path: $!";
    binmode $in;
    local $/;
    my $data = <$in>;
    close $in or die "cannot close $path: $!";
    return $data;
}

# Create an already-started transaction in a unique disposable root. The
# original managed file lives at txn/old-1, while its replacement and a
# brand-new second file are already visible in the installation prefix.
# This is the state reached after successful stage/copy and rename operations
# but before the new ownership manifest is published.
my $serial = 0;
sub fixture {
    ++$serial;
    my $root = "$tmp/case-$serial";
    my $bin = "$root/bin";
    my $txn = "$root/.sasd-freeware-txn-test-$serial";
    make_path($bin, $txn);
    my $destination = "$bin/alpha";
    my $extra = "$bin/beta";
    my $backup = "$txn/old-1";
    my $old = "original-$serial\n";
    my $new = "replacement-$serial\n";
    my $new_extra = "additional-$serial\n";
    write_file($backup, $old);
    write_file($destination, $new);
    write_file($extra, $new_extra);
    write_file("$root/operator.txt", "operator-owned-$serial\n");
    my $input = {
        placed => [[$destination, sha256_hex($new)],
                   [$extra, sha256_hex($new_extra)]],
        backups => [[$destination, $backup, sha256_hex($old)]],
        transaction => $txn,
    };
    return ($input, $root, $destination, $extra, $backup, $old, $new);
}

{
    my ($input, $root, $destination, $extra, $backup, $old) = fixture();
    my $out = rollback_installation(%$input);
    ok($out->{complete}, 'healthy rollback completes');
    is(scalar(@{$out->{errors}}), 0, 'healthy rollback has no errors');
    is(read_file($destination), $old, 'previous managed content is restored');
    ok(!-e $extra, 'newly added file is removed');
    ok(!-e $input->{transaction}, 'completed rollback removes transaction marker');
    is(read_file("$root/operator.txt"), 'operator-owned-1' . "\n",
       'unowned operator file remains intact');
}

{
    my ($input, $root, $destination, $extra, $backup, $old) = fixture();
    my $restore_calls = 0;
    my $cleanup_calls = 0;
    my $out = rollback_installation(%$input, ops => {
        restore => sub { ++$restore_calls; $! = EACCES; return 0 },
        cleanup => sub { ++$cleanup_calls; return 1 },
    });
    ok(!$out->{complete}, 'failed restore marks rollback incomplete');
    is($restore_calls, 1, 'restore failure was exercised deterministically');
    is($cleanup_calls, 0, 'transaction cleanup never runs after failed restore');
    ok(-d $input->{transaction}, 'failed restore retains transaction directory');
    is(read_file($backup), $old, 'failed restore preserves the only old backup');
    ok(!-e $destination, 'new replacement was removed before failed restore');
    ok(!-e $extra, 'newly added file was removed');
    like(join(' ', @{$out->{errors}}), qr/cannot restore old backup/,
        'failure names the action needing manual review');
}

{
    my ($input, $root, $destination, $extra, $backup, $old, $new) = fixture();
    my $cleanup_calls = 0;
    my $restore_calls = 0;
    my $out = rollback_installation(%$input, ops => {
        remove => sub { $! = EACCES; return 0 },
        restore => sub { ++$restore_calls; return 1 },
        cleanup => sub { ++$cleanup_calls; return 1 },
    });
    ok(!$out->{complete}, 'failed remove marks rollback incomplete');
    is($restore_calls, 0, 'occupied destination is never overwritten');
    is($cleanup_calls, 0, 'transaction cleanup is skipped after remove failure');
    is(read_file($destination), $new, 'failed unlink retains newly placed file');
    is(read_file($backup), $old, 'old backup survives alongside new file');
    ok(-f $extra, 'failed extra-file removal preserves its content');
    ok(-d $input->{transaction}, 'failed unlink retains transaction marker');
    like(join(' ', @{$out->{errors}}), qr/restore destination occupied/,
        'diagnostic reports occupied restore destination');
}

{
    my ($input, $root, $destination, $extra, $backup, $old) = fixture();
    write_file($destination, "changed by another process\n");
    my $out = rollback_installation(%$input);
    ok(!$out->{complete}, 'changed new content blocks destructive rollback');
    is(read_file($destination), "changed by another process\n",
       'modified new content is preserved rather than unlinked');
    is(read_file($backup), $old, 'old backup survives modified target');
    ok(-d $input->{transaction}, 'changed new content preserves marker');
    like(join(' ', @{$out->{errors}}), qr/new file changed or missing/,
        'digest mismatch is reported');
}

{
    my ($input, $root, $destination, $extra, $backup, $old) = fixture();
    # This test models a concurrent, unowned file where an old file used to
    # live. It is not one of the installer-recorded newly placed files.
    $input->{placed} = [];
    write_file($destination, "operator collision\n");
    my $out = rollback_installation(%$input);
    ok(!$out->{complete}, 'occupied destination blocks restore');
    is(read_file($destination), "operator collision\n",
       'operator collision is never overwritten by rename');
    is(read_file($backup), $old, 'backup remains for independent recovery');
    ok(-d $input->{transaction}, 'collision preserves transaction marker');
}

{
    my ($input, $root, $destination, $extra, $backup) = fixture();
    write_file($backup, "unexpected altered backup\n");
    my $out = rollback_installation(%$input);
    ok(!$out->{complete}, 'changed backup is not trusted');
    is(read_file($backup), "unexpected altered backup\n",
       'changed backup remains available for investigation');
    ok(!-e $destination, 'altered backup was not installed');
    ok(-d $input->{transaction}, 'altered backup retains transaction marker');
    like(join(' ', @{$out->{errors}}), qr/old backup changed or missing/,
        'digest mismatch of backup is reported');
}

{
    my ($input, $root, $destination, $extra, $backup, $old) = fixture();
    my $cleanup_calls = 0;
    my $out = rollback_installation(%$input, ops => {
        cleanup => sub { ++$cleanup_calls; $! = EACCES; return 0 },
    });
    ok(!$out->{complete}, 'cleanup failure is not reported as full recovery');
    is($cleanup_calls, 1, 'cleanup failure was injected deterministically');
    is(read_file($destination), $old, 'old content was restored before failed cleanup');
    ok(-d $input->{transaction}, 'failed cleanup leaves transaction marker');
    like(join(' ', @{$out->{errors}}), qr/cannot clean completed rollback transaction/,
        'cleanup error is reported separately');
}

{
    my ($input, $root, $destination, $extra, $backup, $old) = fixture();
    # A failure while staging new files happens before any old file is moved.
    # Even such an early abort has a transaction directory that must be
    # removed on complete recovery, without touching unrelated content.
    $input->{placed} = [];
    $input->{backups} = [];
    my $out = rollback_installation(%$input);
    ok($out->{complete}, 'staging-only failure is safely cleaned up');
    ok(!-e $input->{transaction}, 'staging-only transaction marker is removed');
    is(read_file($destination), "replacement-$serial\n",
       'no unrelated file was touched by empty rollback');
}

{
    my ($input, $root, $destination, $extra, $backup, $old) = fixture();
    my $external = "$tmp/external-no-follow";
    write_file($external, "outside object\n");
    unlink $backup or die "cannot remove backup: $!";
    SKIP: {
        skip 'symlink creation unavailable on this platform', 4
            unless symlink($external, $backup);
        my $out = rollback_installation(%$input);
        ok(!$out->{complete}, 'symlink backup is rejected');
        ok(-l $backup, 'symlink is retained for independent inspection');
        is(read_file($external), "outside object\n", 'symlink target was not modified');
        ok(-d $input->{transaction}, 'invalid backup preserves transaction marker');
    }
}

# Prevent future refactors from silently turning the fault-injection hooks
# into command-line or environment-controlled behavior of a production tool.
{
    my $installer = File::Spec->catfile($FindBin::Bin, '..', 'tools', 'installation.pl');
    open my $in, '<', $installer or die "cannot inspect $installer: $!";
    local $/;
    my $contents = <$in>;
    close $in;
    like($contents, qr/rollback_installation\s*\(/,
        'production installer calls the shared rollback implementation');
    like($contents, qr/SASD::Freeware::InstallRollback/,
        'production installer imports the maintainer-only module');
}

done_testing();
