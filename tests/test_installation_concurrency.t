#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M9.3c: cooperative prefix locking and crash-evidence transaction plan.
#
# All filesystem mutations are confined to an isolated, disposable DESTDIR.
# A parent-held flock makes cross-process contention deterministic; there is
# no sleep, race with a scheduler, root operation, or SIGKILL of a real install.
# The plan tests do not pretend that a plan is a replayable recovery journal.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path remove_tree);
use File::Spec;
use Digest::SHA qw(sha256_hex);
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);
use lib "$FindBin::Bin/../tools/lib";
use SASD::Freeware::InstallLock qw(acquire_install_lock);
use SASD::Freeware::InstallPlan qw(write_install_plan);

my $installer = File::Spec->catfile($FindBin::Bin, '..', 'tools', 'installation.pl');
my $tmp = tempdir('sasd-m93c-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $stage = "$tmp/stage";
my $source = "$tmp/source";
my $root = "$stage/usr/freeware";
my $lock_path = "$root/.sasd-freeware-install.lock";
my $manifest = "$root/.sasd-freeware-install.tsv";
make_path(map { "$source/$_" }
    qw(bin sbin lib/SASD/Freeware man/man1 man/man8 docs/commands));
make_path($stage);

sub write_file {
    my ($path, $bytes, $mode) = @_;
    open my $out, '>', $path or die "create $path: $!";
    binmode $out;
    print {$out} $bytes or die "write $path: $!";
    close $out or die "close $path: $!";
    chmod($mode // 0644, $path) or die "chmod $path: $!";
}
sub read_file {
    my ($path) = @_;
    open my $in, '<', $path or die "open $path: $!";
    binmode $in;
    local $/;
    my $bytes = <$in>;
    close $in or die "close $path: $!";
    return $bytes;
}
sub invoke {
    my ($action, $selected_stage) = @_;
    my $err = gensym();
    my $pid = open3(undef, my $out, $err, $^X, $installer,
        '--mode', $action, '--prefix', '/usr/freeware',
        '--destdir', $selected_stage // $stage,
        ($action eq 'install' ? ('--source', $source) : ()));
    local $/;
    my $output = (<$out> // '') . (<$err> // '');
    close $out;
    close $err;
    waitpid($pid, 0);
    return ($? >> 8, $output);
}

my $old = "#!/bin/sh\necho original\n";
my $new = "#!/bin/sh\necho replacement\n";
write_file("$source/bin/alpha", $old, 0755);
write_file("$source/docs/commands/alpha.md", "guide\n");
my ($status, $output) = invoke('install');
is($status, 0, 'first installation succeeds and creates the persistent lock');
ok(-f $lock_path && !-l $lock_path, 'persistent prefix lock is regular');
is((stat($lock_path))[2] & 07777, 0600, 'lock is private mode 0600');
is(read_file($lock_path), "sasd-freeware-install-lock-v1\n", 'lock has fixed protocol marker');
my $first_manifest = read_file($manifest);
write_file("$source/bin/alpha", $new, 0755);

{
    # The parent holds the exact lock inode also opened by a new installer.
    # If the child used a different lock path or removed the marker on exit,
    # these tests would permit unsafe overlapping access.
    my $held = acquire_install_lock($lock_path);
    ($status, $output) = invoke('install');
    isnt($status, 0, 'second process cannot upgrade while lock is held');
    like($output, qr/another install\/uninstall holds the prefix lock/,
         'contention is explicitly diagnosed');
    is(read_file("$root/bin/alpha"), $old, 'contended upgrade leaves live bytes unchanged');
    is(read_file($manifest), $first_manifest, 'contended upgrade leaves manifest unchanged');
    ($status, $output) = invoke('uninstall');
    isnt($status, 0, 'uninstall also obeys the same exclusive lock');
    ok(-f "$root/bin/alpha", 'contended uninstall preserves owned files');
    close $held or die "close held lock: $!";
}

($status, $output) = invoke('install');
is($status, 0, 'upgrade succeeds after previous process releases lock');
is(read_file("$root/bin/alpha"), $new, 'new payload is installed');
is(read_file($lock_path), "sasd-freeware-install-lock-v1\n",
   'success does not unlink or replace lock inode');
($status, $output) = invoke('uninstall');
is($status, 0, 'uninstall succeeds with released lock');
ok(!-f "$root/bin/alpha" && !-f $manifest,
   'owned files and manifest removed without removing lock');
ok(-f $lock_path, 'stable lock remains for future installations');

# Malicious or accidental collisions with the reserved lock name must be
# rejected WITHOUT writing to an operator-owned object.
{
    my $outside = "$tmp/operator-secret";
    write_file($outside, "do not modify\n");
    my $other_stage = "$tmp/linked-stage";
    make_path("$other_stage/usr/freeware");
    my $candidate = "$other_stage/usr/freeware/.sasd-freeware-install.lock";
    SKIP: {
        skip 'symlinks unavailable', 3 unless symlink($outside, $candidate);
        ($status, $output) = invoke('install', $other_stage);
        isnt($status, 0, 'symlink lock is refused');
        is(read_file($outside), "do not modify\n", 'symlink target is not touched');
        ok(!-f "$other_stage/usr/freeware/bin/alpha",
           'unsafe lock is rejected before copying payload');
    }
}
{
    my $other_stage = "$tmp/foreign-stage";
    make_path("$other_stage/usr/freeware");
    my $candidate = "$other_stage/usr/freeware/.sasd-freeware-install.lock";
    write_file($candidate, "operator data\n", 0600);
    ($status, $output) = invoke('install', $other_stage);
    isnt($status, 0, 'foreign regular file with lock name is refused');
    is(read_file($candidate), "operator data\n", 'foreign lock contents not changed');
    write_file($candidate, "sasd-freeware-install-lock-v1\n", 0666);
    ($status, $output) = invoke('install', $other_stage);
    isnt($status, 0, 'world-writable lock marker is refused');
    is((stat($candidate))[2] & 07777, 0666, 'unsafe lock permissions not silently repaired');
}

{
    my $other_stage = "$tmp/hardlink-stage";
    make_path("$other_stage/usr/freeware");
    my $first = "$other_stage/usr/freeware/.sasd-freeware-install.lock";
    write_file($first, "sasd-freeware-install-lock-v1\n", 0600);
    my $second = "$tmp/extra-lock-hardlink";
    SKIP: {
        skip 'hardlinks unavailable', 2 unless link($first, $second);
        ($status, $output) = invoke('install', $other_stage);
        isnt($status, 0, 'hardlinked lock is refused even with correct contents');
        is(read_file($second), "sasd-freeware-install-lock-v1\n",
           'unexpected hardlink remains intact for operator inspection');
    }
}
{
    my $other_stage = "$tmp/empty-lock-stage";
    make_path("$other_stage/usr/freeware");
    my $candidate = "$other_stage/usr/freeware/.sasd-freeware-install.lock";
    write_file($candidate, '', 0600);
    ($status, $output) = invoke('install', $other_stage);
    isnt($status, 0, 'truncated/incomplete lock marker is not silently adopted');
    is(read_file($candidate), '', 'incomplete lock is retained unchanged');
}

# The transaction plan is immutable, printable, keyed by the installer's
# exact old-N/new-N numbering, and published before the first old-file move.
{
    my $txn = "$tmp/plan-case/.sasd-freeware-txn-documented";
    make_path($txn);
    my $old_sha = sha256_hex('before');
    my $new_sha = sha256_hex('after');
    my $path = write_install_plan(transaction => $txn,
        old => [['bin/alpha', $old_sha]],
        new => [['bin/alpha', $new_sha], ['docs/commands/alpha.md', $new_sha]]);
    is($path, "$txn/plan.tsv", 'plan has a stable path within transaction');
    is(read_file($path),
       "# sasd-freeware-transaction-plan-v1\n" .
       "OLD\t1\tbin/alpha\t$old_sha\n" .
       "NEW\t1\tbin/alpha\t$new_sha\n" .
       "NEW\t2\tdocs/commands/alpha.md\t$new_sha\n",
       'plan records both stages with explicit index/path/checksum mapping');
    is((stat($path))[2] & 07777, 0600, 'plan is private mode 0600');
    my $ok = eval { write_install_plan(transaction => $txn,
        old => [], new => []); 1 };
    ok(!$ok, 'published plan cannot be accidentally overwritten');
    ok(!-e "$txn/plan.tmp", 'rejected duplicate plan creates no partial file');
}
{
    my $txn = "$tmp/bad-plan/.sasd-freeware-txn-bad";
    make_path($txn);
    my $ok = eval { write_install_plan(transaction => $txn,
        old => [['../operator', 'a' x 64]], new => []); 1 };
    ok(!$ok, 'unsafe relative path is rejected before plan creation');
    ok(!-e "$txn/plan.tsv" && !-e "$txn/plan.tmp",
       'malformed plan does not create an apparently valid marker');
}
{
    my $txn = "$tmp/early-stop/.sasd-freeware-txn-simulated";
    make_path($txn);
    # Model a real-world inspection point, not automatic restoration: after
    # a crash an old-N may be the only surviving copy. The operator can read
    # plan.tsv and independently verify the old bytes against the old digest.
    my $sha = sha256_hex($old);
    write_install_plan(transaction => $txn, old => [['bin/alpha', $sha]], new => []);
    write_file("$txn/old-1", $old);
    is(sha256_hex(read_file("$txn/old-1")), $sha,
       'old backup corresponds to the human-readable recovery mapping');
    is((split /\t/, (split /\n/, read_file("$txn/plan.tsv"))[1])[2], 'bin/alpha',
       'operator can identify exact old-1 destination without guessing');
}

# This is a contract regression: future installer refactoring must not leave
# lock acquisition until after preflight or publish a plan after backup moves.
{
    my $code = read_file($installer);
    like($code, qr/acquire_install_lock\s*\(/, 'production installer acquires lock');
    like($code, qr/write_install_plan\s*\(/, 'production installer publishes recovery map');
    my $plan = index($code, 'write_install_plan(');
    my $first_move = index($code, 'rename($original, $backup)');
    ok($plan >= 0 && $first_move > $plan,
       'plan publication appears before first backup rename in production');
}

done_testing();
