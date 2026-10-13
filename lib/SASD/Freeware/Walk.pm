package SASD::Freeware::Walk;
# SPDX-License-Identifier: MIT
# Read-only, iterative directory walker; Perl 5.8-compatible syntax.
use strict;
use warnings;
use Exporter 'import';
use File::Spec;
use Fcntl qw(S_ISDIR S_ISLNK);
our @EXPORT_OK = qw(walk_tree display_path parse_bytes directory_root);
our $VERSION = '0.1.0';

# Paths returned by readdir are untrusted data. Never pass them through a shell.
# Returns a useful error string, or the empty string for a valid directory.
sub directory_root {
    my ($path) = @_;
    return 'no directory specified' if !defined($path) || $path eq '';
    my @st = lstat($path);
    return "cannot examine directory " . display_path($path) . ": $!" unless @st;
    return "not a real directory (symbolic links are not accepted): " . display_path($path)
        if !S_ISDIR($st[2]) || S_ISLNK($st[2]);
    return '';
}

sub display_path {
    my ($s) = @_;
    $s =~ s/\\/\\\\/g;
    $s =~ s/([\x00-\x1f\x7f])/sprintf('\\x%02X', ord($1))/ge;
    return $s;
}

# A binary size with K/M/G/T suffixes. Intentionally reject numbers outside
# exact IEEE double-integer range, even on Perl builds with smaller integers.
sub parse_bytes {
    my ($s) = @_;
    return undef unless defined($s) && $s =~ /\A([0-9]+)([KkMmGgTt]?)\z/;
    my ($number, $suffix) = ($1, uc($2));
    my %factor = ('' => 1, K => 1024, M => 1048576,
                  G => 1073741824, T => 1099511627776);
    $number =~ s/\A0+(?=[0-9])//;
    return undef if length($number) > 16;
    my $limit = 9007199254740991;
    return undef if $number > int($limit / $factor{$suffix});
    return $number * $factor{$suffix};
}

# walk_tree(ROOT, ONE_FILESYSTEM, ON_ENTRY, ON_ERROR) returns error count.
# ON_ENTRY receives a pathname and a reference to the lstat result.
# Symbolic links are reported but never followed. A device/inode set protects
# against directory cycles through unusual mount arrangements.
sub walk_tree {
    my ($root, $one_fs, $on_entry, $on_error) = @_;
    my @first = lstat($root);
    if (!@first) { $on_error->($root, "lstat failed: $!"); return 1; }
    my $device = $first[0];
    my (@todo, %visited);
    @todo = ($root);
    my $errors = 0;
    while (@todo) {
        my $path = pop @todo;
        my @st = lstat($path);
        if (!@st) { $on_error->($path, "lstat failed: $!"); ++$errors; next; }
        next if $one_fs && $st[0] != $device;
        $on_entry->($path, \@st);
        next unless S_ISDIR($st[2]);
        my $identity = "$st[0]:$st[1]";
        next if $visited{$identity}++;
        my $handle;
        if (!opendir($handle, $path)) {
            $on_error->($path, "cannot read directory: $!"); ++$errors; next;
        }
        # If the directory was replaced between lstat and open, do not scan it.
        my @opened = stat($handle);
        if (!@opened || $opened[0] != $st[0] || $opened[1] != $st[1] || !S_ISDIR($opened[2])) {
            $on_error->($path, 'directory changed while opening it');
            ++$errors; closedir($handle); next;
        }
        $! = 0;
        my @children = sort grep { $_ ne '.' && $_ ne '..' } readdir($handle);
        if ($!) { $on_error->($path, "readdir failed: $!"); ++$errors; }
        if (!closedir($handle)) { $on_error->($path, "closedir failed: $!"); ++$errors; }
        push @todo, reverse map { File::Spec->catfile($path, $_) } @children;
    }
    return $errors;
}
1;
