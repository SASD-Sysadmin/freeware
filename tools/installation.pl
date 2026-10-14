#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Manifest-owned installation lifecycle for the SASD Freeware source tree.
# The manifest contains SHA-256 digests, so an operator's edits are not deleted
# or silently overwritten on a subsequent upgrade or uninstall.
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Spec;
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use File::Copy qw(copy);
use Cwd qw(abs_path);
use Digest::SHA;

my $magic = '# sasd-freeware-manifest-v1';
my $manifest_name = '.sasd-freeware-install.tsv';
my ($mode, $prefix, $destdir, $source) = (undef, '/usr/freeware', '', '.');
Getopt::Long::Configure('no_auto_abbrev', 'no_ignore_case');
GetOptions('mode=s' => \$mode, 'prefix=s' => \$prefix,
           'destdir=s' => \$destdir, 'source=s' => \$source)
    or die "installation: invalid options\n";
@ARGV == 0 && defined($mode) && $mode =~ /\A(?:install|uninstall)\z/
    or die "installation: --mode install|uninstall is required\n";

# No relative paths, dot components or control bytes in installation roots.
# Requiring these simple forms avoids ambiguous POSIX path normalization.
for my $entry ([$prefix, 'PREFIX'], (length $destdir ? ([$destdir, 'DESTDIR']) : ())) {
    my ($value, $name) = @$entry;
    $value =~ m{\A/} && $value !~ m{//|(?:\A|/)\.{1,2}(?:/|\z)|[\x00-\x1f\x7f]}
        or die "installation: unsafe $name path\n";
}
$prefix ne '/' or die "installation: PREFIX=/ is forbidden\n";
$prefix =~ s{/$}{};
$destdir = '' if $destdir eq '/';
$destdir =~ s{/$}{} if length $destdir > 1;
my $root = "$destdir$prefix";
my $manifest = "$root/$manifest_name";

sub regular_file {
    my ($file) = @_;
    return -f $file && !-l $file;
}
# macOS ships a small, stable set of system aliases. In particular, its
# temporary directory is exposed through /var -> /private/var. Recognize only
# those exact operating-system aliases and validate their resolved directories;
# never allow arbitrary symlinks inside the operator's installation path.
sub trusted_darwin_alias {
    my ($path) = @_;
    return 0 unless $^O eq 'darwin';
    my %aliases = (
        '/var' => '/private/var',
        '/tmp' => '/private/tmp',
        '/etc' => '/private/etc',
    );
    my $expected = $aliases{$path};
    return 0 unless defined $expected;
    my $resolved = abs_path($path);
    return 0 unless defined($resolved) && $resolved eq $expected;
    for my $component ('/private', $expected) {
        my @st = lstat($component);
        return 0 unless @st && -d _ && !-l _ && $st[4] == 0;
        # /private/tmp is root-owned, world-writable and sticky by design;
        # no other group/world-writable alias destination is trusted.
        if ($st[2] & 0022) {
            return 0 unless $component eq '/private/tmp' && ($st[2] & 01000);
        }
    }
    return 1;
}
sub ancestors_safe {
    my ($path, $file_target) = @_;
    my $current = '';
    my @components = grep { length $_ } split m{/}, $path;
    for my $i (0 .. $#components) {
        $current .= '/' . $components[$i];
        my @st = lstat($current);
        next unless @st;
        if (-l _) {
            trusted_darwin_alias($current)
                or die "installation: symbolic link in target path $current\n";
            # The alias is a directory, never the final regular-file target.
            die "installation: not a regular target file: $current\n"
                if $i == $#components && $file_target;
            next;
        }
        if ($i == $#components && $file_target) {
            die "installation: not a regular target file: $current\n" unless -f _;
        } else {
            die "installation: not a directory: $current\n" unless -d _;
        }
    }
}
sub allowed_relative {
    my ($rel) = @_;
    return $rel =~ m{\A(?:bin/[A-Za-z0-9][A-Za-z0-9_.-]*|sbin/[A-Za-z0-9][A-Za-z0-9_.-]*|lib/SASD/Freeware/[A-Za-z0-9_.-]+\.pm|man/man[1-9]/[A-Za-z0-9_.-]+\.[1-9]|docs/commands/[A-Za-z0-9_.-]+\.md|docs/(?:PLATFORMS|TESTING|EXIT-CODES|PRIVILEGED-SAFETY|RELEASE-ENGINEERING)(?:\.de)?\.md)\z};
}
sub digest {
    my ($path) = @_;
    open my $in, '<', $path or die "installation: cannot open $path: $!\n";
    binmode $in;
    my $sha = Digest::SHA->new(256);
    $sha->addfile($in);
    close $in or die "installation: cannot close $path: $!\n";
    return $sha->hexdigest;
}
sub load_manifest {
    return () unless -e $manifest || -l $manifest;
    ancestors_safe($manifest, 1);
    open my $in, '<', $manifest or die "installation: cannot read manifest: $!\n";
    my $header = <$in> // '';
    $header eq "$magic\n" or die "installation: unknown manifest version\n";
    my %previous;
    while (my $line = <$in>) {
        chomp $line;
        my ($path, $hash) = split /\t/, $line, -1;
        allowed_relative($path) && defined($hash) && $hash =~ /\A[0-9a-f]{64}\z/
            && !exists($previous{$path})
            or die "installation: invalid or duplicate manifest entry\n";
        $previous{$path} = $hash;
    }
    close $in or die "installation: manifest read failed: $!\n";
    return %previous;
}

ancestors_safe($root, 0);
if (-d $root) {
    opendir my $dh, $root or die "installation: cannot inspect prefix: $!\n";
    my @interrupted = grep { /\A\.sasd-freeware-txn-/ } readdir $dh;
    closedir $dh;
    !@interrupted or die "installation: interrupted installation transaction exists; inspect backup before retrying\n";
}
my %previous = load_manifest();
if ($mode eq 'uninstall' && !-f $manifest) {
    die "installation: no ownership manifest; refusing to guess what to remove\n";
}
my %wanted;
if ($mode eq 'install') {
    my $src = abs_path($source);
    defined($src) && -d $src or die "installation: source tree is unavailable\n";
    for my $section ('bin', 'sbin', 'lib/SASD/Freeware', 'man/man1', 'man/man8',
                     'docs/commands', 'docs') {
        my $folder = "$src/$section";
        opendir my $dh, $folder or die "installation: cannot read $folder: $!\n";
        my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
        closedir $dh;
        for my $name (@names) {
            my $rel = "$section/$name";
            next unless allowed_relative($rel);
            my $path = "$src/$rel";
            # Refuse tampered source entries rather than install symlink contents.
            regular_file($path) or die "installation: unsafe source $rel\n";
            if ($section eq 'bin' || $section eq 'sbin') {
                -x $path or die "installation: not executable: $rel\n";
            }
            $wanted{$rel} = $path;
        }
    }
    keys %wanted or die "installation: refusing to install an empty package\n";
}

# Full preflight happens before writing *any* installed files.
# Old managed files must be byte-for-byte unchanged, even when now obsolete.
for my $rel (sort keys %previous) {
    my $dst = "$root/$rel";
    ancestors_safe($dst, 1);
    regular_file($dst) && digest($dst) eq $previous{$rel}
        or die "installation: installed file changed or missing; refusing: $rel\n";
}
for my $rel (sort keys %wanted) {
    my $dst = "$root/$rel";
    ancestors_safe(dirname($dst), 0);
    if (-e $dst || -l $dst) {
        ancestors_safe($dst, 1);
        exists($previous{$rel})
            or die "installation: unowned destination exists; refusing: $rel\n";
    }
}

if ($mode eq 'uninstall') {
    for my $rel (sort keys %previous) {
        unlink "$root/$rel" or die "installation: cannot remove $rel: $!\n";
    }
    unlink $manifest or die "installation: cannot remove manifest: $!\n";
    print "Uninstalled ", scalar(keys %previous), " managed files; unowned files preserved.\n";
    exit 0;
}

# Stage complete new payload, then replace only previously-owned files.
# A failed copy cannot damage live files. Backups provide best-effort rollback
# if an operation fails before the new manifest has been published.
make_path($root) unless -d $root;
ancestors_safe($root, 0);
my $txn = tempdir('.sasd-freeware-txn-XXXXXXXX', DIR => $root, CLEANUP => 0);
my (@backups, @placed);
my $ok = eval {
    my $index = 0;
    my %newhash;
    for my $rel (sort keys %wanted) {
        ++$index;
        my $tmp = "$txn/new-$index";
        copy($wanted{$rel}, $tmp) or die "cannot stage $rel: $!\n";
        chmod(($rel =~ m{\A(?:bin|sbin)/}) ? 0755 : 0644, $tmp)
            or die "cannot set staged mode for $rel: $!\n";
        $newhash{$rel} = digest($tmp);
    }
    $index = 0;
    for my $rel (sort keys %previous) {
        ++$index;
        my $original = "$root/$rel";
        my $backup = "$txn/old-$index";
        rename($original, $backup) or die "cannot protect previous $rel: $!\n";
        push @backups, [$original, $backup];
    }
    $index = 0;
    for my $rel (sort keys %wanted) {
        ++$index;
        my $dst = "$root/$rel";
        make_path(dirname($dst)) unless -d dirname($dst);
        ancestors_safe(dirname($dst), 0);
        rename("$txn/new-$index", $dst) or die "cannot install $rel: $!\n";
        push @placed, $dst;
    }
    my $new_manifest = "$txn/manifest";
    open my $out, '>', $new_manifest or die "cannot write staged manifest: $!\n";
    print {$out} "$magic\n" or die "cannot write manifest header: $!\n";
    for my $rel (sort keys %wanted) {
        print {$out} "$rel\t$newhash{$rel}\n" or die "cannot write manifest entry: $!\n";
    }
    close $out or die "cannot finish manifest: $!\n";
    chmod(0644, $new_manifest) or die "cannot set manifest mode: $!\n";
    rename($new_manifest, $manifest) or die "cannot publish manifest: $!\n";
    1;
};
if (!$ok) {
    my $reason = $@ || 'unknown failure';
    for my $dst (reverse @placed) { unlink $dst or warn "installation: rollback unlink $dst: $!\n"; }
    for my $item (reverse @backups) {
        rename($item->[1], $item->[0]) or warn "installation: rollback restore $item->[0]: $!\n";
    }
    eval { remove_tree($txn) };
    die "installation: update failed (rollback attempted): $reason";
}
remove_tree($txn);
print "Installed ", scalar(keys %wanted), " managed files; ",
      scalar(keys %previous) - scalar(grep { exists $wanted{$_} } keys %previous),
      " obsolete files removed.\n";
