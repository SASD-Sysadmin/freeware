#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use FindBin;

my $core = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'core-report');
my $paths = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'path-audit');
my $root = tempdir('sasd-filesystem-tests-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);

sub make_file {
    my ($name, $bytes) = @_;
    open my $fh, '>', $name or die "create $name: $!";
    binmode $fh;
    print {$fh} ('z' x $bytes);
    close $fh or die "close $name: $!";
}
sub run_tool {
    my ($program, @args) = @_;
    open my $pipe, '-|', $^X, $program, @args
        or die "execute $program: $!";
    binmode $pipe;
    local $/;
    my $output = <$pipe>;
    close $pipe;
    return (defined($output) ? $output : '', $? >> 8);
}

my $nested = File::Spec->catdir($root, 'nested space');
make_path($nested);
my $plain = File::Spec->catfile($root, 'core');
my $numbered = File::Spec->catfile($nested, 'core.123');
my $noise = File::Spec->catfile($root, 'mycore');
my $unrelated = File::Spec->catfile($root, 'normal.txt');
make_file($plain, 2);
make_file($numbered, 8);
make_file($noise, 25);
make_file($unrelated, 14);
my $outside = tempdir('sasd-filesystem-outside-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
make_file(File::Spec->catfile($outside, 'core'), 50);
my $link = File::Spec->catfile($root, 'linked');
my $symlinks = eval { symlink($outside, $link) || die $!; 1 };

my ($output, $status) = run_tool($core, $root);
is($status, 0, 'core-report succeeds');
like($output, qr/^BYTES\tPATH\n/m, 'core-report prints a header');
like($output, qr/\Q$plain\E\n/, 'core-report finds exact core name');
like($output, qr/\Q$numbered\E\n/, 'core-report finds numbered core name');
unlike($output, qr/\Q$noise\E\n/, 'core-report ignores a lookalike');
like($output, qr/Candidates: 2\nLogical bytes: 10\nErrors: 0\n/, 'core-report summarizes size');
if ($symlinks) { unlike($output, qr/linked\/core/, 'core-report does not follow directory symlinks'); }
($output, $status) = run_tool($core, '--min-size', '3', $root);
is($status, 0, 'minimum size scan succeeds');
like($output, qr/Candidates: 1\nLogical bytes: 8\n/, 'minimum size limits matches');
($output, $status) = run_tool($core, '--one-file-system', $root);
is($status, 0, 'device limit accepted');
($output, $status) = run_tool($core, '--null', $root);
is($status, 0, 'NUL mode succeeds');
like($output, qr/2\0\Q$plain\E\0/, 'NUL mode retains exact pathname');
unlike($output, qr/Candidates:/, 'NUL mode omits human summary');
($output, $status) = run_tool($core, '--help');
is($status, 0, 'core-report help succeeds');
like($output, qr/Usage: core-report/, 'help has synopsis');
($output, $status) = run_tool($core, '--version');
is($status, 0, 'version succeeds');
like($output, qr/^core-report 0\.1\.0\n$/, 'version identifies utility');
($output, $status) = run_tool($core, '--min-size', 'bad', $root);
is($status, 2, 'bad minimum size rejected');
($output, $status) = run_tool($core, $root, 'unexpected');
is($status, 2, 'extra argument rejected');
($output, $status) = run_tool($core, File::Spec->catdir($root, 'missing'));
is($status, 1, 'missing root rejected');
if ($symlinks) {
    ($output, $status) = run_tool($core, $link);
    is($status, 1, 'symlink root rejected');
}

# Check byte-count semantics and reports for both components and full paths.
my $long_base = 'X' x 30;
my $long_path = File::Spec->catfile($nested, $long_base);
make_file($long_path, 1);
($output, $status) = run_tool($paths, '--component-limit', '20', '--path-limit', '9999', $root);
is($status, 0, 'path-audit succeeds');
like($output, qr/component\t30\t\d+\t\Q$long_path\E\n/, 'overlong component detected');
unlike($output, qr/\Q$unrelated\E\n/, 'normal name not flagged');
($output, $status) = run_tool($paths, '--component-limit', '999', '--path-limit', '10', $root);
is($status, 0, 'path threshold succeeds');
like($output, qr/^path\t\d+\t\d+\t/m, 'path-only finding reported');
($output, $status) = run_tool($paths, '--component-limit', '2', '--path-limit', '10', $root);
is($status, 0, 'combined thresholds succeed');
like($output, qr/^both\t/m, 'both reasons distinguished');
($output, $status) = run_tool($paths, '--null', '--component-limit', '20', '--path-limit', '9999', $root);
is($status, 0, 'path audit NUL mode succeeds');
like($output, qr/component\0(?:30)\0\d+\0\Q$long_path\E\0/, 'NUL format includes field boundaries');
($output, $status) = run_tool($paths, '--version');
is($status, 0, 'path-audit version succeeds');
like($output, qr/^path-audit 0\.1\.0\n$/, 'path-audit version reported');
($output, $status) = run_tool($paths, '--help');
is($status, 0, 'path-audit help succeeds');
like($output, qr/Usage: path-audit/, 'path-audit help has synopsis');
($output, $status) = run_tool($paths, '--component-limit', '0', $root);
is($status, 2, 'zero threshold rejected');
($output, $status) = run_tool($paths, '--path-limit', 'nope', $root);
is($status, 2, 'nonnumeric threshold rejected');
($output, $status) = run_tool($paths, File::Spec->catfile($root, 'missing'));
is($status, 1, 'path-audit rejects missing root');
if ($symlinks) {
    ($output, $status) = run_tool($paths, $link);
    is($status, 1, 'path-audit rejects symlink root');
}

# No source data is modified; both commands only report.
ok(-f $plain && -s $plain == 2, 'core file remains intact');
ok(-f $long_path && -s $long_path == 1, 'long-named file remains intact');

done_testing();
