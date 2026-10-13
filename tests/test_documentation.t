#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
use strict;
use warnings;
use Test::More;
use File::Find ();
use File::Basename qw(dirname);
use File::Spec;
use FindBin;

my $root = File::Spec->rel2abs("$FindBin::Bin/..");
my @files = map { "$root/$_" } qw(README.md README.de.md CONTRIBUTING.md);
File::Find::find(
    { no_chdir => 1, wanted => sub { push @files, $File::Find::name if -f $_ && /\.md\z/ } },
    "$root/docs",
);

ok(-d "$root/docs/commands", 'command guides live in docs/commands');
ok(!-e "$root/docu", 'legacy docu directory is not present');
my $links = 0;
for my $file (@files) {
    open my $fh, '<', $file or die "cannot read $file: $!";
    local $/;
    my $contents = <$fh>;
    close $fh or die "cannot close $file: $!";
    # The repository's local Markdown links are ordinary file paths without
    # whitespace or parenthesized targets. External URLs and anchors are omitted.
    while ($contents =~ /\[[^\]]*\]\(([^)]+)\)/g) {
        my $target = $1;
        next if $target =~ /\A(?:[A-Za-z][A-Za-z0-9+.-]*:|#|\/)/;
        $target =~ s/#.*\z//;
        my $location = File::Spec->catfile(dirname($file), $target);
        ok(-e $location, "$file -> $target resolves");
        ++$links;
    }
}
ok($links >= 60, 'documentation contains expected cross-references');
done_testing();
