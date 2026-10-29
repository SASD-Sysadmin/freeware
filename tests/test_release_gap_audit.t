#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Hermetic release-gap regression tests: never touch a real host, git remote,
# repository branch, account database or system installation.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use FindBin;

my $tool = File::Spec->catfile($FindBin::Bin, '..', 'tools', 'release-gap-audit.pl');
my $fixture = tempdir('sasd-release-gap-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my @required = qw(
    LICENSE SECURITY.md CONTRIBUTING.md CHANGELOG.md
    README.md README.de.md Makefile .github/workflows/ci.yml
    tools/installation.pl
    docs/RELEASE-ENGINEERING.md docs/RELEASE-ENGINEERING.de.md
    docs/PLATFORMS.md docs/PLATFORMS.de.md
    docs/PRIVILEGED-SAFETY.md docs/PRIVILEGED-SAFETY.de.md
    docs/TESTING.md docs/TESTING.de.md
);

sub make_file {
    my ($relative, $content) = @_;
    my $path = File::Spec->catfile($fixture, split m{/}, $relative);
    my ($dir) = $path =~ m{\A(.*)/[^/]+\z};
    make_path($dir) unless -d $dir;
    open(my $fh, '>', $path) or die "create $relative: $!";
    print {$fh} $content;
    close($fh) or die "close $relative: $!";
}

sub execute {
    my (@args) = @_;
    # Argument-list launch bypasses the shell, protecting fixture paths.
    open(my $fh, '-|', $^X, $tool, '--root', $fixture, @args)
        or die "cannot start release-gap-audit: $!";
    local $/;
    my $output = <$fh>;
    close($fh);
    return ($? >> 8, defined($output) ? $output : '');
}

for my $file (@required) { make_file($file, "fixture\n"); }
make_file('README.md', "[alpha](bin/alpha) [admin](sbin/admin)\n");
make_file('README.de.md', "[alpha](bin/alpha) [admin](sbin/admin)\n");
make_file('bin/alpha', "#!/bin/sh\nexit 0\n");
make_file('sbin/admin', "#!/bin/sh\nexit 0\n");
for my $pair (
    ['alpha', 1], ['admin', 8],
) {
    my ($name, $section) = @$pair;
    make_file("man/man$section/$name.$section", "manual\n");
    make_file("docs/commands/$name.md", "English\n");
    make_file("docs/commands/$name.de.md", "Deutsch\n");
}

my ($status, $report) = execute();
is($status, 0, 'ordinary scan exits zero even with manual gates open');
like($report, qr/\Astatus\tpriority\tcategory\titem\tdetail\n/,
    'TSV header is stable');
like($report, qr/\bPASS\tP0\tinventory\tcommands\t2 regular command files discovered/,
    'both bin and sbin commands are discovered');
like($report, qr/\bMANUAL\tP0\trelease-evidence\tprivileged-vm\t/,
    'privileged operations are never auto-approved');
like($report, qr/\bMANUAL\tP0\trelease-evidence\tartifact-provenance\t/,
    'archive and checksums require independent proof');
like($report, qr/SUMMARY\tPASS=\d+\tGAP=0\tMANUAL=7\n\z/,
    'complete static fixture still has seven manual gates');

($status, $report) = execute('--strict');
is($status, 1, 'strict release gate rejects pending human evidence');

unlink(File::Spec->catfile($fixture, 'docs', 'commands', 'alpha.de.md')) or die $!;
($status, $report) = execute();
like($report, qr/GAP\tP1\trepository-file\tdocs\/commands\/alpha.de\.md\tmissing or symlinked/,
    'missing translation is a specific P1 gap');
like($report, qr/SUMMARY\tPASS=\d+\tGAP=1\tMANUAL=7/,
    'gap tally increases after one document is removed');

# Unexpected objects and symlinked artifacts must not masquerade as a command
# or a valid license. Platforms may not permit symlink creation (e.g. Windows),
# therefore treat that capability as an explicit, not silently passing, skip.
my $linked = File::Spec->catfile($fixture, 'bin', 'symbolic');
SKIP: {
    skip 'symlink creation unavailable on this platform', 2
        unless symlink(File::Spec->catfile($fixture, 'bin', 'alpha'), $linked);
    ($status, $report) = execute();
    like($report, qr/GAP\tP0\tcommand-entry\tbin\/symbolic\t/,
        'symlinked executable is rejected rather than followed');
    like($report, qr/\binventory\tcommands\t2 regular command files discovered/,
        'symlink does not increase executable count');
}

# No tool invocation or writes occur. A shell command masquerading as an
# executable should not run just because the release scanner encountered it.
my $side_effect = File::Spec->catfile($fixture, 'executed-marker');
make_file('bin/untrusted', "#!/bin/sh\ntouch '$side_effect'\n");
($status, $report) = execute();
ok(!-e $side_effect, 'audit never runs inventoried programs');
like($report, qr/\binventory\tcommands\t3 regular command files discovered/,
    'new tool is inventoried without execution');
like($report, qr/GAP\tP0\trepository-file\tman\/man1\/untrusted\.1\t/,
    'undocumented tool is reported without hiding its missing manpage');

# Encoded record fields must remain a single TSV line when a hostile filename
# contains a newline. Do not allow a forged PASS/GAP/SUMMARY line in output.
make_file("bin/odd\nname", "text\n");
($status, $report) = execute();
like($report, qr/GAP\tP0\tcommand-entry\tbin\/odd\\nname\t/,
    'unsafe filename newline is escaped in the TSV record');

# A missing top-level contract file is an explicit P0 structural gap.
unlink(File::Spec->catfile($fixture, 'SECURITY.md')) or die $!;
($status, $report) = execute();
like($report, qr/GAP\tP0\trepository-file\tSECURITY\.md\t/,
    'missing security policy is a P0 gap');

# --help is a no-side-effect metadata option, independent of the source tree.
open(my $help_fh, '-|', $^X, $tool, '--help') or die $!;
local $/;
my $help_text = <$help_fh>;
close($help_fh);
is($? >> 8, 0, 'help exits successfully without a fixture');
like($help_text, qr/Usage: perl tools\/release-gap-audit\.pl/, 'help documents usage');

done_testing();
