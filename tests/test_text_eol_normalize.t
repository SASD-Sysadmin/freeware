#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Offline regression tests: all writes stay beneath a disposable tempdir.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use FindBin;

my $program = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'text-eol-normalize');
my $root = tempdir('sasd-eol-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $subdir = File::Spec->catdir($root, 'sub dir');
make_path($subdir);
sub put {
    my ($name, $contents) = @_;
    open my $fh, '>', $name or die "create $name: $!";
    binmode($fh);
    print {$fh} $contents or die "write $name: $!";
    close($fh) or die "close $name: $!";
}
sub get {
    my ($name) = @_;
    open my $fh, '<', $name or die "read $name: $!";
    binmode($fh);
    local $/;
    my $data = <$fh>;
    close($fh) or die "close $name: $!";
    return $data;
}
sub run {
    my (@args) = @_;
    open my $fh, '-|', $^X, $program, @args or die "run failed: $!";
    local $/;
    my $text = <$fh>;
    close($fh);
    return (defined $text ? $text : '', $? >> 8);
}

my $dos = File::Spec->catfile($root, 'first file.txt');
my $unix = File::Spec->catfile($root, 'already.md');
my $mixed = File::Spec->catfile($root, 'mixed.csv');
my $binary = File::Spec->catfile($root, 'packed.txt');
my $excel = File::Spec->catfile($root, 'book.xlsx');
my $bin = File::Spec->catfile($root, 'blob.bin');
my $other = File::Spec->catfile($root, 'unknown.dat');
my $inside = File::Spec->catfile($subdir, 'deep.py');
my $cr_only = File::Spec->catfile($root, 'mac.txt');
my $utf16 = File::Spec->catfile($root, 'utf16.txt');
my $boundary = File::Spec->catfile($root, 'edge.txt');
put($dos, "one\r\ntwo\r\n");
put($unix, "one\ntwo\n");
put($mixed, "alpha\r\nbeta\ngamma\r\n");
put($binary, "HEADER\0\r\nBYTES\n");
put($excel, "excel\r\n");
put($bin, "binary\r\n");
put($other, "unknown\r\n");
put($inside, "deep\r\n");
put($cr_only, "first\rsecond\r");
put($utf16, "\xFF\xFEa\0\r\0\n\0");
# Force CR/LF to occupy different read() chunks.
put($boundary, ('x' x 65535) . "\r\nend\r\n");
my $newline_name = File::Spec->catfile($root, "odd\nname.txt");
put($newline_name, "odd\r\n");
my ($report, $code) = run('--check', '--recursive', $root);
is($code, 0, 'read-only check completes');
like($report, qr/DOS\t.*first file\.txt\tCRLF=2 LF=0/, 'detects CRLF');
like($report, qr/DOS\t.*mixed\.csv\tCRLF=2 LF=1/, 'counts mixed LF and CRLF');
like($report, qr/DOS\t.*edge\.txt\tCRLF=2 LF=0/, 'detects split CRLF boundaries');
like($report, qr/DOS\t.*deep\.py/, 'recursive walk reaches subdirectories');
like($report, qr/odd\\x0Aname\.txt/, 'escapes unsafe filename bytes');
unlike($report, qr/book\.xlsx|blob\.bin|unknown\.dat|packed\.txt/, 'ignores excluded extensions and detected binary files');
is(get($dos), "one\r\ntwo\r\n", 'check leaves source unchanged');
my ($plan, $plan_status) = run('--dry-run', '--recursive', $root);
is($plan_status, 0, 'dry-run succeeds');
like($plan, qr/WOULD_CONVERT\t.*first file\.txt/, 'dry-run reports planned edits');
is(get($dos), "one\r\ntwo\r\n", 'dry-run does not edit');
my $unix_mtime = (stat($unix))[9];
chmod(0640, $dos) or die "chmod test input: $!";
($report, $code) = run('--apply', '--recursive', $root);
is($code, 0, 'apply succeeds');
is(get($dos), "one\ntwo\n", 'converts DOS file');
is((stat($dos))[2] & 0777, 0640, 'preserves ordinary file permissions');
is(get($mixed), "alpha\nbeta\ngamma\n", 'normalizes mixed CRLF and LF');
is(get($boundary), ('x' x 65535) . "\nend\n", 'converts across chunk boundary');
is(get($inside), "deep\n", 'recursive apply converts nested file');
is(get($newline_name), "odd\n", 'filename with newline safely converted');
is(get($unix), "one\ntwo\n", 'preserves already-normalized content');
is((stat($unix))[9], $unix_mtime, 'preserves Unix file modification time');
is(get($binary), "HEADER\0\r\nBYTES\n", 'leaves binary content unchanged');
is(get($excel), "excel\r\n", 'excludes Excel even though it contains CRLF');
is(get($bin), "binary\r\n", 'excludes .bin');
is(get($other), "unknown\r\n", 'unknown extension not allowed by default');
is(get($cr_only), "first\rsecond\r", 'legacy CR file not converted');
is(get($utf16), "\xFF\xFEa\0\r\0\n\0", 'UTF-16-like content safely skipped');
like($report, qr/SUMMARY\texamined=\d+\tdos=5\tconverted=5\t/, 'apply reports actual conversions');
($report, $code) = run('--apply', '--recursive', $root);
is($code, 0, 'repeat apply succeeds');
like($report, qr/\tdos=0\tconverted=0\t/, 'repeat apply performs no writes');

my $newer = File::Spec->catfile($root, 'new.txt');
put($newer, "young\r\n");
($report, $code) = run('--apply', '--min-age', 300, $newer);
is($code, 0, 'min-age accepts recent file without writing');
is(get($newer), "young\r\n", 'recent file remains untouched');
utime(time()-600, time()-600, $newer);
($report, $code) = run('--apply', '--min-age', 300, $newer);
is($code, 0, 'old file becomes eligible');
is(get($newer), "young\n", 'old file converted');

my $large = File::Spec->catfile($root, 'large.txt');
put($large, "large\r\n");
($report, $code) = run('--apply', '--max-bytes', 5, $large);
is($code, 0, 'over-size file safely skipped');
is(get($large), "large\r\n", 'no size-limit write');

my $name = File::Spec->catfile($root, 'extra.dat');
put($name, "custom\r\n");
($report, $code) = run('--apply', '--include', 'dat', $name);
is($code, 0, 'custom include accepted');
is(get($name), "custom\n", 'custom extension converted');

my $forced_excel = File::Spec->catfile($root, 'forced.xlsx');
put($forced_excel, "no\r\n");
($report, $code) = run('--apply', '--include', 'xlsx', $forced_excel);
is($code, 0, 'binary extension remains denied even in explicit allowlist');
is(get($forced_excel), "no\r\n", 'hard-denied extension remains untouched');

my $link = File::Spec->catfile($root, 'linked.txt');
if (symlink($newer, $link)) {
    ($report, $code) = run('--apply', $link);
    is($code, 1, 'root symlink is refused');
    is(get($newer), "young\n", 'symlink target unchanged');
} else { pass('symlinks unavailable'); pass('symlink target not touched'); }

my $original = File::Spec->catfile($root, 'hard.txt');
my $alias = File::Spec->catfile($root, 'alias.txt');
put($original, "hard\r\n");
if (link($original, $alias)) {
    ($report, $code) = run('--apply', $original);
    is($code, 0, 'hardlinked file safely skipped');
    is(get($alias), "hard\r\n", 'hardlink data not replaced');
} else { pass('hardlinks unavailable'); pass('hardlink target not touched'); }

($report, $code) = run('--apply', '--dry-run', $root);
is($code, 2, 'conflicting modes rejected');
($report, $code) = run('--max-bytes', 'invalid', $root);
is($code, 2, 'invalid size limit rejected');
($report, $code) = run('--help');
is($code, 0, 'help returns success');
like($report, qr/^Usage: text-eol-normalize/, 'help contains synopsis');
($report, $code) = run('--version');
is($code, 0, 'version returns success');
is($report, "text-eol-normalize 0.1.0\n", 'version matches CLI contract');

my @leftovers = glob(File::Spec->catfile($root, '.sasd-eol-*'));
is(scalar(@leftovers), 0, 'staging files cleaned up');
done_testing();
