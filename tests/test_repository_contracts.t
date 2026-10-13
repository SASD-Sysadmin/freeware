#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Guard against repeat regressions: trailing whitespace, unresolved templating
# in Markdown links, and executable Git modes accidentally assigned to docs.
# The Git-index check is deliberately separate from filesystem permission bits:
# WSL /mnt/c and some ZIP extractors do not preserve POSIX modes reliably.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Find ();
use File::Spec;

my $root = File::Spec->rel2abs("$FindBin::Bin/..");
my @markdown;
for my $file (qw(README.md README.de.md CHANGELOG.md CONTRIBUTING.md SECURITY.md)) {
    push @markdown, File::Spec->catfile($root, $file);
}
File::Find::find({no_chdir => 1, wanted => sub {
    push @markdown, $File::Find::name if -f $File::Find::name && /\.md\z/;
}}, File::Spec->catdir($root, 'docs'));

for my $file (sort @markdown) {
    open my $in, '<', $file or die "cannot read $file: $!";
    my $number = 0;
    my @problems;
    while (my $line = <$in>) {
        ++$number;
        push @problems, "line $number" if $line =~ /[ \t]+\r?\n\z/;
        push @problems, "unresolved link on line $number"
            if $line =~ /\]\(\{prefix\}/;
    }
    close $in or die "cannot close $file: $!";
    my $relative = File::Spec->abs2rel($file, $root);
    is_deeply(\@problems, [], "$relative: clean whitespace and links");
}

my $git = File::Spec->catdir($root, '.git');
SKIP: {
    skip 'Git index checks require an actual checkout', 1 unless -e $git;
    my $current = File::Spec->rel2abs('.');
    chdir $root or die "cannot change to $root: $!";
    my $opened = open my $fh, '-|', 'git', 'ls-files', '--stage', '-z';
    if (!$opened) {
        chdir $current or die "cannot change back: $!";
        skip 'Git command is not available', 1;
    }
    local $/ = "\0";
    my @wrong;
    while (my $record = <$fh>) {
        $record =~ s/\0\z//;
        my ($mode, $path) = $record =~ /\A(\d+) [0-9a-f]+ \d+\t(.*)\z/s;
        next unless defined $path && $path =~ /\.md\z/;
        push @wrong, "$path ($mode)" if $mode ne '100644';
    }
    close $fh or die 'git ls-files --stage failed';
    chdir $current or die "cannot change back: $!";
    is_deeply(\@wrong, [], 'all tracked Markdown documents have non-executable 100644 Git mode');
}
done_testing();
