#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# FR2-04: the license is an owned, digest-verified installation payload.
# All writes remain within disposable File::Temp fixtures. No root or live
# installation, Git working tree, network service, or external host is touched.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use Digest::SHA qw(sha256_hex);
use IPC::Open3;
use Symbol qw(gensym);

my $installer = File::Spec->catfile($FindBin::Bin, '..', 'tools', 'installation.pl');
my $tmp = tempdir('sasd-fr2-04-license-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $source = "$tmp/source";
my $stage = "$tmp/stage";
my $prefix = "$stage/usr/freeware";
my $license = "$source/LICENSE";
my $installed_license = "$prefix/LICENSE";
my $manifest = "$prefix/.sasd-freeware-install.tsv";
my $license_v1 = "MIT License\n\nCopyright (c) 2026 SASD test fixture\n";
my $license_v2 = "MIT License\n\nCopyright (c) 2026 Updated SASD test fixture\n";

make_path(map { "$source/$_" }
    qw(bin sbin lib/SASD/Freeware man/man1 man/man8 docs/commands));
make_path($stage);

sub put_file {
    my ($path, $content, $mode) = @_;
    open my $out, '>', $path or die "open $path: $!";
    binmode $out or die "binmode $path: $!";
    print {$out} $content or die "write $path: $!";
    close $out or die "close $path: $!";
    chmod($mode || 0644, $path) or die "chmod $path: $!";
}
sub contents {
    my ($path) = @_;
    open my $in, '<', $path or die "read $path: $!";
    binmode $in;
    local $/;
    my $data = <$in>;
    close $in or die "close $path: $!";
    return $data;
}
sub run_installer {
    my ($mode) = @_;
    my $err = gensym();
    my $pid = open3(undef, my $out, $err, $^X, $installer,
        '--mode', $mode,
        '--source', $source,
        '--prefix', '/usr/freeware',
        '--destdir', $stage);
    local $/;
    my $stdout = <$out>;
    my $stderr = <$err>;
    close $out;
    close $err;
    waitpid($pid, 0);
    return ($? >> 8, ($stdout // '') . ($stderr // ''));
}
sub count_managed_license {
    my ($manifest_bytes) = @_;
    return () = $manifest_bytes =~ /^LICENSE\t[0-9a-f]{64}$/mg;
}

put_file("$source/bin/alpha", "#!/bin/sh\nexit 0\n", 0755);
put_file("$source/docs/commands/alpha.md", "alpha test guide\n", 0644);

# Missing source notice must not result in an apparently successful install.
my ($rc, $message) = run_installer('install');
isnt($rc, 0, 'missing source LICENSE blocks first install');
like($message, qr/LICENSE.*(?:missing|regular|source)/i,
    'missing-license diagnostic explains the source requirement');
ok(!-e "$prefix/bin/alpha" && !-e $manifest,
    'missing notice publishes neither program nor ownership manifest');

# A symlink, including one to an otherwise readable notice, is not an owned
# source file. Do not follow arbitrary operator-controlled source links.
my $external = "$tmp/external-license";
put_file($external, $license_v1, 0644);
symlink($external, $license) or die "create symlink: $!";
($rc, $message) = run_installer('install');
isnt($rc, 0, 'symlinked source LICENSE is rejected');
ok(!-e $installed_license && !-e $manifest,
    'refusal never installs the symlink target');
unlink($license) or die "unlink source symlink: $!";

# Ordinary fresh install: the exact license bytes and their hash travel with
# the command through the same staged-publish contract.
put_file($license, $license_v1, 0644);
($rc, $message) = run_installer('install');
is($rc, 0, 'fresh install with regular LICENSE succeeds');
is(contents($installed_license), $license_v1,
    'installed LICENSE retains exact source bytes');
is((stat($installed_license))[2] & 07777, 0644,
    'installed LICENSE has non-executable permissions');
my $entry1 = 'LICENSE' . "\t" . sha256_hex($license_v1);
my $manifest_v1 = contents($manifest);
like($manifest_v1, qr/^\Q$entry1\E$/m,
    'SHA-256 manifest owns LICENSE under its exact root-relative name');
is(count_managed_license($manifest_v1), 1,
    'manifest contains exactly one LICENSE record');
ok(-x "$prefix/bin/alpha", 'installed command remains executable');

($rc, $message) = run_installer('install');
is($rc, 0, 'repeat install of same source is idempotent');
is(contents($manifest), $manifest_v1, 'manifest unchanged by repeat install');

# A source update is permitted only while the previous destination still
# matches the digest recorded in the manifest.
put_file($license, $license_v2, 0644);
($rc, $message) = run_installer('install');
is($rc, 0, 'verified license update succeeds');
is(contents($installed_license), $license_v2, 'updated license bytes are installed');
my $entry2 = 'LICENSE' . "\t" . sha256_hex($license_v2);
my $manifest_v2 = contents($manifest);
like($manifest_v2, qr/^\Q$entry2\E$/m,
    'new license digest is recorded in the manifest');

put_file($installed_license, "operator modification\n", 0644);
($rc, $message) = run_installer('install');
isnt($rc, 0, 'upgrade refuses operator-modified installed LICENSE');
like($message, qr/changed or missing/, 'modified license triggers ordinary preflight failure');
is(contents($installed_license), "operator modification\n",
    'refused upgrade does not overwrite operator data');
is(contents($manifest), $manifest_v2,
    'failed upgrade does not replace the manifest');
($rc, $message) = run_installer('uninstall');
isnt($rc, 0, 'uninstall refuses operator-modified owned LICENSE');
is(contents($installed_license), "operator modification\n",
    'uninstall refusal preserves the modified license');

# Restore original content as a controlled fixture action, not a production
# recovery suggestion. Then demonstrate a normal complete uninstall.
put_file($installed_license, $license_v2, 0644);
($rc, $message) = run_installer('uninstall');
is($rc, 0, 'uninstall succeeds with verified LICENSE');
ok(!-e $installed_license && !-e "$prefix/bin/alpha" && !-e $manifest,
    'uninstall removes owned license, command and manifest');
ok(-f "$prefix/.sasd-freeware-install.lock",
    'persistent cooperative lock is retained');

# After uninstall, an unowned LICENSE at the target is protected just like an
# unowned executable; even if the rest of the prefix is safe to install.
put_file($installed_license, "operator-owned unrelated notice\n", 0644);
($rc, $message) = run_installer('install');
isnt($rc, 0, 'fresh install refuses unowned LICENSE filename collision');
is(contents($installed_license), "operator-owned unrelated notice\n",
    'unowned license collision is never overwritten');
ok(!-e "$prefix/bin/alpha" && !-e $manifest,
    'collision does not create a partially installed product');
unlink($installed_license) or die "remove test-owned collision: $!";

# Migrate a *simulated* historical manifest (which legitimately lacked a
# LICENSE record) to a modern one. We prepare that old fixture deliberately;
# modifying a real manifest by hand is never recommended.
($rc, $message) = run_installer('install');
is($rc, 0, 'baseline for old-manifest upgrade installed');
my $new_manifest = contents($manifest);
my $old_manifest = join('', grep { !/^LICENSE\t/ } split /(?<=\n)/, $new_manifest);
unlink($installed_license) or die "remove fixture notice to model old install: $!";
put_file($manifest, $old_manifest, 0644);
($rc, $message) = run_installer('install');
is($rc, 0, 'upgrade from historic manifest without LICENSE succeeds');
is(contents($installed_license), $license_v2,
    'legacy upgrade adds the missing managed license');
like(contents($manifest), qr/^\Q$entry2\E$/m,
    'legacy upgrade adopts LICENSE into the new manifest');
($rc, $message) = run_installer('uninstall');
is($rc, 0, 'upgraded legacy fixture can be cleanly uninstalled');
ok(!-e $installed_license && !-e $manifest,
    'legacy uninstall removes newly managed license and manifest');

# A sole LICENSE must not bypass the original refusal to publish an empty
# distribution. No commands, libraries, docs or manpages remain in source.
unlink("$source/bin/alpha") or die "remove fixture command: $!";
unlink("$source/docs/commands/alpha.md") or die "remove fixture guide: $!";
($rc, $message) = run_installer('install');
isnt($rc, 0, 'license-only source tree remains an empty-package error');
like($message, qr/refusing to install an empty package/,
    'empty-package diagnostic preserved after adding mandatory LICENSE');
ok(!-e $installed_license && !-e $manifest,
    'license-only refusal does not publish a partial product');

done_testing();
