#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M9.3a: fail-closed recovery contract for a simulated interrupted upgrade.
#
# All writes are confined to a disposable DESTDIR. We deliberately model one
# persisted mid-transaction state instead of sending SIGKILL to a live installer:
# a real asynchronous kill would create a flaky, scheduler-dependent test and
# could not prove that every possible interruption point is safe.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $installer = File::Spec->catfile($FindBin::Bin, '..', 'tools', 'installation.pl');
my $tmp = tempdir('sasd-m93a-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $source = "$tmp/source";
my $stage = "$tmp/stage";
my $prefix = "$stage/usr/freeware";
my $manifest = "$prefix/.sasd-freeware-install.tsv";

# The installer enumerates these directories even when they contain no files.
# Provide a miniature valid source tree so the test never reads system tools.
make_path(map { "$source/$_" }
    qw(bin sbin lib/SASD/Freeware man/man1 man/man8 docs/commands));
make_path($stage);

sub write_file {
    my ($path, $content, $mode) = @_;
    open my $out, '>', $path or die "create $path: $!";
    print {$out} $content or die "write $path: $!";
    close $out or die "close $path: $!";
    chmod $mode, $path or die "chmod $path: $!";
}

sub read_file {
    my ($path) = @_;
    open my $in, '<', $path or die "open $path: $!";
    local $/;
    my $bytes = <$in>;
    close $in or die "close $path: $!";
    return $bytes;
}

sub invoke {
    my ($action) = @_;
    my $stderr = gensym();
    # Argument-list execution avoids shell interpolation of any fixture path.
    my $pid = open3(undef, my $stdout, $stderr, $^X, $installer,
        '--mode', $action, '--prefix', '/usr/freeware', '--destdir', $stage,
        ($action eq 'install' ? ('--source', $source) : ()));
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    close $stdout;
    close $stderr;
    waitpid($pid, 0);
    return ($? >> 8, $out . $err);
}

my $original = "#!/bin/sh\necho original\n";
my $replacement = "#!/bin/sh\necho upgraded\n";
write_file("$source/bin/alpha", $original, 0755);
write_file("$source/docs/commands/alpha.md", "alpha guide\n", 0644);

my ($status, $output) = invoke('install');
is($status, 0, 'fixture installation succeeds before interruption simulation');
my $original_manifest = read_file($manifest);
write_file("$prefix/operator-notes.txt", "operator-owned\n", 0644);

# Prepare an upgrade but model a crash immediately after the installer has
# moved the first old managed file into its transaction backup directory.
# The manifest still records the previous version; the backup must survive.
write_file("$source/bin/alpha", $replacement, 0755);
write_file("$source/bin/beta", "#!/bin/sh\nexit 0\n", 0755);
my $transaction = "$prefix/.sasd-freeware-txn-simulated";
make_path($transaction);
rename("$prefix/bin/alpha", "$transaction/old-1")
    or die "simulate interrupted backup: $!";

($status, $output) = invoke('install');
isnt($status, 0, 'upgrade refuses an outstanding transaction');
like($output, qr/interrupted installation transaction exists/,
    'upgrade explains why automatic recovery was refused');
($status, $output) = invoke('uninstall');
isnt($status, 0, 'uninstall also refuses an outstanding transaction');
like($output, qr/interrupted installation transaction exists/,
    'uninstall does not bypass the interruption guard');

is(read_file("$transaction/old-1"), $original,
    'the previous managed payload remains in the transaction backup');
is(read_file($manifest), $original_manifest,
    'neither rejected operation publishes a new ownership manifest');
ok(!-e "$prefix/bin/beta", 'the requested new command was not installed');
is(read_file("$prefix/operator-notes.txt"), "operator-owned\n",
    'unmanaged operator data is not modified');
ok(-d $transaction, 'the recovery evidence is not silently deleted');

# These next actions model an explicitly reviewed manual recovery of a known
# fixture state. The installer must NOT be taught to guess which old-N file
# corresponds to which pathname: that mapping requires independent review.
rename("$transaction/old-1", "$prefix/bin/alpha")
    or die "restore simulated backup: $!";
remove_tree($transaction);
is(read_file("$prefix/bin/alpha"), $original,
    'the independently restored file matches the original version');
is(read_file($manifest), $original_manifest,
    'manual restoration did not forge a new ownership manifest');

($status, $output) = invoke('install');
is($status, 0, 'upgrade succeeds once the fixture is independently repaired');
is(read_file("$prefix/bin/alpha"), $replacement,
    'new version is deployed after validated recovery');
ok(-x "$prefix/bin/beta", 'new managed command is installed');
is(read_file("$prefix/operator-notes.txt"), "operator-owned\n",
    'unmanaged file remains intact after the upgrade');

($status, $output) = invoke('uninstall');
is($status, 0, 'verified fixture can be safely uninstalled');
ok(!-e "$prefix/bin/alpha" && !-e "$prefix/bin/beta",
    'owned commands are removed on uninstall');
is(read_file("$prefix/operator-notes.txt"), "operator-owned\n",
    'uninstall retains the unmanaged operator file');

done_testing();
