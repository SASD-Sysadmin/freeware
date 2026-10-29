#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Read-only, repository-local release gap inventory for SASD Freeware.
#
# This is intentionally a maintainer tool (tools/), not a shipped command.
# It does not install, execute, modify, or attest to the safety of utilities.
# Static presence checks never substitute for a successful CI job or a
# documented, human-approved native/privileged acceptance test.
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Spec;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

my ($root, $strict, $help) = (undef, 0, 0);
Getopt::Long::Configure('no_auto_abbrev', 'no_ignore_case');
GetOptions('root=s' => \$root, 'strict' => \$strict, 'help|h' => \$help)
    or usage(2);
usage(0) if $help;
usage(2) if @ARGV;

# Resolve a caller-supplied source tree, or default to the containing repo.
# abs_path also rejects missing roots; all subsequent operations remain reads.
$root = File::Spec->catdir(dirname(__FILE__), '..') unless defined $root;
my $resolved = abs_path($root);
defined $resolved && -d $resolved
    or die "release-gap-audit: source root must be an existing directory\n";
$root = $resolved;

# TSV records make a stable, grep-friendly inventory without relying on JSON
# modules or a Git checkout. Escape the few characters that could otherwise
# create forged records if a repository filename includes control bytes.
sub escape_tsv {
    my ($value) = @_;
    $value = '' unless defined $value;
    $value =~ s/\\/\\\\/g;
    $value =~ s/\t/\\t/g;
    $value =~ s/\r/\\r/g;
    $value =~ s/\n/\\n/g;
    $value =~ s/([\x00-\x08\x0b\x0c\x0e-\x1f\x7f])/sprintf('\\x%02X',ord($1))/ge;
    return $value;
}
my %counts = (PASS => 0, GAP => 0, MANUAL => 0);
sub record {
    my ($status, $priority, $category, $name, $detail) = @_;
    ++$counts{$status};
    print join("\t", map { escape_tsv($_) }
        ($status, $priority, $category, $name, $detail)), "\n";
}
sub regular {
    my ($path) = @_;
    # -f alone follows symlinks. Release input artifacts must be real files.
    return -f $path && !-l $path;
}
sub path_for {
    my ($relative) = @_;
    return File::Spec->catfile($root, split m{/}, $relative);
}
sub file_check {
    my ($relative, $priority) = @_;
    record(regular(path_for($relative)) ? 'PASS' : 'GAP', $priority,
        'repository-file', $relative,
        regular(path_for($relative)) ? 'regular file present' : 'missing or symlinked');
}

print "status\tpriority\tcategory\titem\tdetail\n";

# Structural prerequisites are deliberately small and based on the existing
# project contracts. Detailed behavior is tested by the ordinary test suites.
for my $file (qw(
    LICENSE SECURITY.md CONTRIBUTING.md CHANGELOG.md
    README.md README.de.md Makefile .github/workflows/ci.yml
    tools/installation.pl
    docs/RELEASE-ENGINEERING.md docs/RELEASE-ENGINEERING.de.md
    docs/PLATFORMS.md docs/PLATFORMS.de.md
    docs/PRIVILEGED-SAFETY.md docs/PRIVILEGED-SAFETY.de.md
    docs/TESTING.md docs/TESTING.de.md
)) {
    file_check($file, 'P0');
}

my @commands;
for my $section (qw(bin sbin)) {
    my $dir = path_for($section);
    if (!-d $dir || -l $dir) {
        record('GAP', 'P0', 'command-directory', $section, 'missing or symlinked');
        next;
    }
    opendir(my $dh, $dir) or die "release-gap-audit: cannot open $section: $!\n";
    my @entries = sort readdir($dh);
    closedir($dh) or die "release-gap-audit: cannot close $section: $!\n";
    for my $name (@entries) {
        next if $name eq '.' || $name eq '..' || $name eq '.gitkeep';
        my $path = path_for("$section/$name");
        # An unexpected object in bin/sbin is a gap, not an executable.
        if ($name !~ /\A[a-zA-Z0-9][a-zA-Z0-9_.-]*\z/ || !regular($path)) {
            record('GAP', 'P0', 'command-entry', "$section/$name",
                'unexpected name, non-regular file or symlink');
            next;
        }
        push @commands, [$section, $name];
    }
}
record(@commands ? 'PASS' : 'GAP', 'P0', 'inventory', 'commands',
       scalar(@commands) . ' regular command files discovered');

# Read READMEs once. Missing/unreadable READMEs already yield P0 gaps above;
# here we record an additional, precise mapping gap for each affected tool.
my %readme;
for my $file (qw(README.md README.de.md)) {
    my $path = path_for($file);
    next unless regular($path);
    open(my $fh, '<', $path) or die "release-gap-audit: cannot read $file: $!\n";
    local $/;
    $readme{$file} = <$fh>;
    close($fh) or die "release-gap-audit: cannot close $file: $!\n";
}
for my $command (@commands) {
    my ($section, $name) = @$command;
    my $page_section = $section eq 'bin' ? 1 : 8;
    my @associated = (
        ["man/man$page_section/$name.$page_section", 'P0'],
        ["docs/commands/$name.md", 'P1'],
        ["docs/commands/$name.de.md", 'P1'],
    );
    for my $entry (@associated) { file_check(@$entry); }
    for my $language (qw(README.md README.de.md)) {
        # A linked command location proves discoverability without imposing
        # a particular table ordering or the surrounding natural language.
        my $reference = "$section/$name";
        my $present = defined($readme{$language}) &&
            index($readme{$language}, "($reference)") >= 0;
        record($present ? 'PASS' : 'GAP', 'P1', 'readme-index',
            "$language:$name", $present ? 'command link present' : 'command link missing');
    }
}

# These checks cannot be inferred from source code. Always report MANUAL,
# even when every static artifact exists. An operator must attach independent
# evidence and approve the exact release scope before publishing.
for my $gate (
    ['P0', 'current-ci', 'passing required jobs for the release commit, including integration tests'],
    ['P0', 'privileged-vm', 'approved account/quota apply and rollback in isolated, snapshotted VM'],
    ['P0', 'staged-upgrade', 'fresh/repeat/upgrade/conflict/uninstall recovery evidence'],
    ['P0', 'artifact-provenance', 'pristine tag checkout, reproducible archive and SHA-256 verification'],
    ['P0', 'release-approval', 'reviewed scope, risks, version, known limitations and rollback'],
    ['P1', 'native-platforms', 'real distribution/OS tests only for platforms claimed as supported'],
    ['P1', 'live-services', 'realistic mail/SQL/LDAP/firewall environments for claimed behaviors'],
) {
    record('MANUAL', $gate->[0], 'release-evidence', $gate->[1], $gate->[2]);
}

print "SUMMARY\tPASS=$counts{PASS}\tGAP=$counts{GAP}\tMANUAL=$counts{MANUAL}\n";
# --strict is a release veto, not a promise of automatic release approval.
# It intentionally remains nonzero while any manually approved gate is open.
exit($strict && ($counts{GAP} || $counts{MANUAL}) ? 1 : 0);

sub usage {
    my ($exit) = @_;
    my $fh = $exit ? *STDERR : *STDOUT;
    print {$fh} <<'HELP';
Usage: perl tools/release-gap-audit.pl [--root DIRECTORY] [--strict]
       perl tools/release-gap-audit.pl --help
Read-only TSV inventory of structural release gaps and manual evidence gates.
Default exit 0 means scan completed, NOT release approved.
--strict exits 1 when gaps or manual evidence gates remain open.
No files are changed and no programs are executed.
HELP
    exit($exit);
}
