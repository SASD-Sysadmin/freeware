#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# FR2-04: offline, read-only *heuristic* inventory of license/provenance clues.
# This does not establish authorship, license compatibility, or release approval.
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Find ();
use File::Spec ();
use Cwd qw(abs_path);

my $root = '.';
my $help = 0;
GetOptions('root=s' => \$root, 'help' => \$help) or usage(2);
usage(0) if $help;
@ARGV == 0 or usage(2);
$root = abs_path($root);
defined($root) && -d $root or die "fr2-04: --root must name a real directory\n";

my %count = (PASS => 0, REVIEW => 0, INFO => 0);
print "status\tcategory\titem\tdetail\n";

sub emit {
    my ($status, $category, $item, $detail) = @_;
    exists $count{$status} or die "fr2-04: invalid internal status\n";
    $count{$status}++;
    for ($category, $item, $detail) {
        $_ = '' unless defined $_;
        s/[\t\r\n]/ /g;   # stable machine-readable single-line TSV
    }
    print join("\t", $status, $category, $item, $detail), "\n";
}

sub read_text {
    my ($file) = @_;
    return undef if -l $file || !-f $file;
    open my $fh, '<', $file or return undef;
    binmode $fh;
    local $/;
    my $content = <$fh>;
    close $fh or return undef;
    return undef if !defined($content) || $content =~ /\0/;
    return $content;
}

my $license = read_text(File::Spec->catfile($root, 'LICENSE'));
if (!defined $license) {
    emit('REVIEW', 'license', 'LICENSE', 'missing, unreadable, symlink or binary');
} elsif ($license =~ /\AMIT License\s*\n/ &&
         $license =~ /Copyright \(c\)/ &&
         $license =~ /Permission is hereby granted/ &&
         $license =~ /THE SOFTWARE IS PROVIDED/) {
    emit('PASS', 'license', 'LICENSE', 'MIT text and copyright notice detected; not a legal validation');
} else {
    emit('REVIEW', 'license', 'LICENSE', 'unexpected or incomplete license format; manual review required');
}
if (defined($license) && $license =~ /^Copyright \(c\) [^\r\n]+/m) {
    my ($holder) = $license =~ /^Copyright \(c\) ([^\r\n]+)/m;
    emit('INFO', 'ownership', 'LICENSE', 'copyright holder string: ' . $holder);
    emit('REVIEW', 'ownership', 'LICENSE', 'verify legal rights holder and authority separately');
}

my $contrib = read_text(File::Spec->catfile($root, 'CONTRIBUTING.md'));
if (!defined $contrib) {
    emit('REVIEW', 'contributions', 'CONTRIBUTING.md', 'no readable contribution policy');
} elsif ($contrib =~ /contribution is distributed under the repository.s existing MIT License/i) {
    emit('PASS', 'contributions', 'CONTRIBUTING.md', 'MIT contribution policy recorded');
    emit('REVIEW', 'contributions', 'CONTRIBUTING.md',
         'MIT contribution rule does not prove assignment or separate commercial relicensing rights');
} else {
    emit('REVIEW', 'contributions', 'CONTRIBUTING.md',
         'contribution licensing terms require manual inspection');
}

my $installer = read_text(File::Spec->catfile($root, 'tools', 'installation.pl'));
if (!defined $installer) {
    emit('REVIEW', 'distribution', 'tools/installation.pl', 'installer missing or unreadable');
} else {
    # Detect the known scoped inventory and root LICENSE omission. A string
    # match is only a signal: runtime staging and manifest tests are required.
    my $root_list = $installer =~ /for my \$section \('bin', 'sbin', 'lib\/SASD\/Freeware'/;
    my $license_listed = $installer =~ /['"]LICENSE['"]/;
    if ($root_list && !$license_listed) {
        emit('REVIEW', 'distribution', 'LICENSE',
             'source inventory has no visible root LICENSE handling; validate staged payload');
    } elsif ($root_list && $license_listed) {
        emit('INFO', 'distribution', 'LICENSE',
             'candidate root LICENSE handling detected; confirm using staged install and manifest tests');
    } else {
        emit('INFO', 'distribution', 'LICENSE',
             'source inspection cannot establish license payload; verify actual DESTDIR install');
    }
}

my @files;
for my $part (qw(bin sbin lib tools tests)) {
    my $dir = File::Spec->catdir($root, $part);
    next unless -d $dir && !-l $dir;
    File::Find::find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            return if -d $path;
            my $rel = File::Spec->abs2rel($path, $root);
            $rel =~ s{\\}{/}g;
            return if $rel =~ m{(?:\A|/)\.gitkeep\z};
            return unless $rel =~ m{\A(?:bin/[^/]+|sbin/[^/]+|(?:lib|tools)/.+\.(?:pm|pl|sh)|tests/.+\.(?:t|sh))\z};
            push @files, [$rel, $path];
        },
    }, $dir);
}

my ($mit, $missing, $other) = (0, 0, 0);
for my $pair (sort { $a->[0] cmp $b->[0] } @files) {
    my ($rel, $path) = @$pair;
    my $source = read_text($path);
    if (!defined $source) {
        ++$missing;
        emit('REVIEW', 'source', $rel, 'not readable regular text or symlink');
        next;
    }
    # Only real, line-leading source comments count as SPDX declarations.
    # An unanchored scan mistakes Perl string literals, regexes and synthetic
    # test fixtures mentioning SPDX identifiers for additional licenses.
    my @spdx = $source =~ /^[ \t]*\#[ \t]*SPDX-License-Identifier:[ \t]*([^\r\n]+)/mg;
    if (@spdx == 1 && $spdx[0] =~ /^MIT\s*$/) {
        ++$mit;
    } elsif (@spdx) {
        ++$other;
        emit('REVIEW', 'spdx', $rel, 'non-MIT or multiple SPDX identifiers; review original notices');
    } else {
        ++$missing;
        emit('REVIEW', 'spdx', $rel, 'SPDX license identifier missing');
    }
    # Deliberately narrow provenance clues: comments containing clear
    # attribution wording only. A complete forensic/source comparison
    # cannot be implemented with string heuristics.
    my $line_number = 0;
    for my $line (split /\n/, $source) {
        ++$line_number;
        if ($line =~ /^\s*(?:#|\/\/|\*)\s*(?:copied from|adapted from|derived from|copyright\s*\(c\))/i) {
            emit('REVIEW', 'provenance-clue', $rel,
                 'attribution-like comment at line ' . $line_number . '; inspect original source');
        }
    }
}
emit('PASS', 'spdx', 'source-and-tests',
     "$mit files carry a single MIT SPDX tag; inspected=" . scalar(@files) .
     ", missing-or-unreadable=$missing, other-or-multiple=$other") if !$missing && !$other;
emit('REVIEW', 'spdx', 'source-and-tests',
     "inspected=" . scalar(@files) . ", MIT=$mit, missing-or-unreadable=$missing, other-or-multiple=$other")
     if $missing || $other;
emit('REVIEW', 'scope', 'documentation-and-manpages',
     'manual attribution/code-snippet review remains; not covered by SPDX-only source scan');
emit('REVIEW', 'scope', 'git-history',
     'identify contributors and rights chain from contracts plus full history; git author names alone do not prove rights');

print join("\t", 'SUMMARY', 'PASS=' . $count{PASS},
           'REVIEW=' . $count{REVIEW}, 'INFO=' . $count{INFO}), "\n";
exit 0;  # Read-only audit completed. REVIEW rows do not grant release approval.

sub usage {
    my ($code) = @_;
    print "Usage: perl tools/fr2-04-provenance-audit.pl [--root DIR] [--help]\n";
    exit $code;
}
