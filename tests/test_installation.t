#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# No root access or system paths. Every mutation targets disposable fixtures.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use Cwd ();
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $installer = File::Spec->catfile($FindBin::Bin, '..', 'tools', 'installation.pl');
my $tmp = tempdir('sasd-install-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $source = "$tmp/source";
my $stage = "$tmp/stage";
my $installed = "$stage/usr/freeware";
make_path("$source/bin", "$source/sbin", "$source/lib/SASD/Freeware", "$source/man/man1",
          "$source/man/man8", "$source/docs/commands", "$stage");

sub write_file {
    my ($file, $data, $mode) = @_;
    open my $out, '>', $file or die "$file: $!";
    print {$out} $data;
    close $out or die "$file: $!";
    chmod($mode // 0644, $file) or die "chmod $file: $!";
}
sub read_file {
    my ($file) = @_;
    open my $in, '<', $file or die "$file: $!";
    local $/;
    my $data = <$in>;
    close $in;
    return $data;
}
sub invoke {
    my ($action, @args) = @_;
    my $err = gensym();
    my $pid = open3(undef, my $out, $err, $^X, $installer,
        '--mode', $action, '--prefix', '/usr/freeware', '--destdir', $stage,
        ($action eq 'install' ? ('--source', $source) : ()), @args);
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    close $out;
    close $err;
    waitpid($pid, 0);
    return ($? >> 8, $stdout . $stderr);
}

write_file("$source/bin/alpha", "#!/bin/sh\necho first\n", 0755);
write_file("$source/sbin/admin", "#!/bin/sh\nexit 0\n", 0755);
# Real Git checkouts contain these non-executable placeholders. They must not
# be classified as installable commands or copied into the ownership manifest.
write_file("$source/bin/.gitkeep", "", 0644);
write_file("$source/sbin/.gitkeep", "", 0644);
write_file("$source/lib/SASD/Freeware/Account.pm", "1;\n");
write_file("$source/man/man1/alpha.1", "manual\n");
write_file("$source/docs/commands/alpha.de.md", "guide\n");
write_file("$source/docs/PLATFORMS.md", "platforms\n");
my ($rc, $output) = invoke('install');
is($rc, 0, 'fresh staged install succeeds');
like($output, qr/Installed 6 managed files/, 'payload count is reported');
ok(-x "$installed/bin/alpha", 'executables are installed as executables');
is((stat("$installed/bin/alpha"))[2] & 0777, 0755, 'executable mode is 0755');
is((stat("$installed/docs/commands/alpha.de.md"))[2] & 0777, 0644, 'documentation mode is 0644');
ok(!-e "$installed/bin/.gitkeep" && !-e "$installed/sbin/.gitkeep",
    'hidden repository placeholders are not installed');
ok(-f "$installed/.sasd-freeware-install.tsv", 'install manifest is written');
like(read_file("$installed/.sasd-freeware-install.tsv"),
     qr{\A\# sasd-freeware-manifest-v1\n(?:[^\n]+\n)+\z}, 'versioned manifest contains file records');

($rc, $output) = invoke('install');
is($rc, 0, 'repeat install is idempotent');
write_file("$installed/operator-notes.txt", "unowned\n");
unlink("$source/bin/alpha") or die $!;
write_file("$source/bin/beta", "#!/bin/sh\necho updated\n", 0755);
($rc, $output) = invoke('install');
is($rc, 0, 'upgrade with renamed command succeeds');
ok(!-e "$installed/bin/alpha", 'obsolete managed command removed on upgrade');
ok(-x "$installed/bin/beta", 'new command installed');
is(read_file("$installed/operator-notes.txt"), "unowned\n", 'unknown operator file preserved');
like($output, qr/1 obsolete files removed/, 'obsolete entry count is accurate');

write_file("$installed/bin/beta", "operator-edited\n", 0755);
($rc, $output) = invoke('install');
isnt($rc, 0, 'upgrade refuses modified installed content');
like($output, qr/changed or missing/, 'diagnostic identifies modified content');
is(read_file("$installed/bin/beta"), "operator-edited\n", 'modified content remains intact');
($rc, $output) = invoke('uninstall');
isnt($rc, 0, 'uninstall refuses modified installed content');
write_file("$installed/bin/beta", "#!/bin/sh\necho updated\n", 0755);

write_file("$source/bin/collision", "#!/bin/sh\nexit 0\n", 0755);
write_file("$installed/bin/collision", "unowned\n");
($rc, $output) = invoke('install');
isnt($rc, 0, 'upgrade refuses unowned filename collision');
is(read_file("$installed/bin/collision"), "unowned\n", 'collision does not overwrite operator file');
unlink("$source/bin/collision") or die $!;

($rc, $output) = invoke('uninstall');
is($rc, 0, 'manifest-based uninstall succeeds after clean fixtures');
ok(!-e "$installed/bin/beta", 'managed executable removed');
ok(!-e "$installed/.sasd-freeware-install.tsv", 'ownership manifest removed last');
is(read_file("$installed/operator-notes.txt"), "unowned\n", 'uninstall preserves unowned file');
is(read_file("$installed/bin/collision"), "unowned\n", 'uninstall preserves unowned collision');
($rc, $output) = invoke('uninstall');
isnt($rc, 0, 'uninstall refuses absent manifest rather than guessing');
like($output, qr/no ownership manifest/, 'missing manifest reports safe refusal');

# First installation must likewise refuse any existing unowned file.
write_file("$installed/bin/beta", "someone else's beta\n", 0755);
($rc, $output) = invoke('install');
isnt($rc, 0, 'fresh install refuses collision without manifest');
is(read_file("$installed/bin/beta"), "someone else's beta\n", 'fresh install preserves unowned data');
unlink("$installed/bin/beta") or die $!;

# macOS exposes its normal temporary directories via /var -> /private/var.
# Reaching this point on Darwin proves the trusted alias allowed the staged
# install while the tests below still reject an attacker-selected symlink.
SKIP: {
    skip 'Darwin-specific trusted temporary-directory alias', 1
        unless $^O eq 'darwin';
    my $canonical = Cwd::abs_path($stage);
    ok(defined($canonical) && -d $canonical,
       'Darwin staging directory works with its system path aliases');
}

# Refuse symlinks in the installed directory chain, not just at file leaf.
my $external = "$tmp/elsewhere";
make_path($external);
my $badstage = "$tmp/symlink-stage";
make_path("$badstage/usr");
symlink($external, "$badstage/usr/freeware") or die $!;
($rc, $output) = invoke('install', '--destdir', $badstage);
isnt($rc, 0, 'symlinked installation root is refused');
ok(!-e "$external/.sasd-freeware-install.tsv", 'external symlink target untouched');

($rc, $output) = invoke('install', '--prefix', '/');
isnt($rc, 0, 'PREFIX=/ is rejected');
($rc, $output) = invoke('install', '--prefix', '/usr/../etc');
isnt($rc, 0, 'parent-directory traversal in PREFIX rejected');
($rc, $output) = invoke('install', '--destdir', '/tmp/../bad');
isnt($rc, 0, 'parent-directory traversal in DESTDIR rejected');

# Corrupted manifests cannot become arbitrary file-delete instructions.
($rc, $output) = invoke('install');
is($rc, 0, 'reinstall restores a valid owned package');
my $manifest = "$installed/.sasd-freeware-install.tsv";
my $valid_manifest = read_file($manifest);
write_file($manifest, "# sasd-freeware-manifest-v1\n../operator-notes.txt\t" . ('a' x 64) . "\n");
($rc, $output) = invoke('uninstall');
isnt($rc, 0, 'uninstall rejects traversal entries in manifest');
ok(-f "$installed/bin/beta", 'malformed manifest cannot cause partial uninstall');
write_file($manifest, $valid_manifest);
($rc, $output) = invoke('uninstall');
is($rc, 0, 'valid manifest allows safe cleanup');

done_testing();
