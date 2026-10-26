# SPDX-License-Identifier: MIT
# M8.5.1 – Distinct parser, classifier and CLI regression tests.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Spec;
use IPC::Open3;
use Symbol qw(gensym);
use lib "$FindBin::Bin/../lib";
use SASD::Freeware::LinuxPlatform qw(parse_os_release summarize_os_release);
my $bin = "$FindBin::Bin/../bin/linux-platform-report";
my $dir = tempdir(CLEANUP => 1);

sub summary {
    my ($str) = @_;
    return summarize_os_release(parse_os_release($str), 'INPUT');
}
sub reject {
    my ($str, $name) = @_;
    my $ok = eval { summary($str); 1 };
    ok(!$ok, $name);
}
sub run_cli {
    my ($fixture, @args) = @_;
    my $p = File::Spec->catfile($dir, 'os-release-fixture');
    open my $out, '>', $p or die $!;
    binmode $out;
    print {$out} $fixture;
    close $out or die $!;
    my $err = gensym;
    my $pid = open3(my $in, my $stdout, $err, $^X, $bin, '--input', $p, @args);
    close $in;
    local $/;
    my $got = <$stdout> // '';
    my $errors = <$err> // '';
    waitpid($pid, 0);
    return ($? >> 8, $got, $errors);
}

my @dists = (
    [qq{ID=debian\nVERSION_ID="12"\n}, 'debian', 'debian', 'VERSIONED', 'ID'],
    [qq{ID=ubuntu\nID_LIKE=debian\nVERSION_ID="24.04"\n}, 'ubuntu', 'debian', 'VERSIONED', 'ID'],
    [qq{ID=arch\nPRETTY_NAME="Arch Linux"\n}, 'arch', 'arch', 'ROLLING', 'ID'],
    [qq{ID=almalinux\nID_LIKE="rhel centos fedora"\nVERSION_ID="9.6"\n}, 'almalinux', 'rhel', 'VERSIONED', 'ID'],
    [qq{ID=rocky\nID_LIKE="rhel centos fedora"\nVERSION_ID="9.6"\n}, 'rocky', 'rhel', 'VERSIONED', 'ID'],
    [qq{ID=opensuse-tumbleweed\n}, 'opensuse-tumbleweed', 'suse', 'UNKNOWN', 'ID'],
    [qq{ID=alpine\nVERSION_ID="3.22.1"\n}, 'alpine', 'alpine', 'VERSIONED', 'ID'],
);
for my $c (@dists) {
    my ($fixture, $id, $family, $mode, $evidence) = @$c;
    my $row = summary($fixture);
    is($row->[1], $id, "$id ID");
    is($row->[4], $family, "$id family");
    is($row->[5], $evidence, "$id provenance");
    is($row->[6], $mode, "$id version mode");
}
my $derived = summary("ID=custom\nID_LIKE=\"fedora rhel\"\n");
is($derived->[4], 'rhel', 'ID_LIKE derives a single coherent lineage');
is($derived->[5], 'ID_LIKE', 'derived family is explicitly labeled');
my $ambiguous = summary("ID=custom\nID_LIKE=\"debian arch\"\n");
is($ambiguous->[4], 'unknown', 'conflicting ID_LIKE parents cannot be guessed');
is($ambiguous->[5], 'UNKNOWN', 'conflicting evidence marked unknown');
my $unknown = summary("ID=brandnew\n");
is($unknown->[4], 'unknown', 'unknown distro stays unknown');
is($unknown->[6], 'UNKNOWN', 'missing version does not imply rolling release');
is(summary('NAME="Some Linux"' . "\n")->[1], 'linux', 'specification fallback ID=linux');
is(summary("ID=rocky\nID=ubuntu\n")->[1], 'ubuntu', 'last duplicate assignment wins');
is(summary("  \nID=debian\n")->[1], 'debian', 'whitespace-only lines allowed');
is(summary("ID='debian'\n")->[1], 'debian', 'single quote accepted');
is(summary("ID=debian\r\nVERSION_ID=12\r\n")->[3], '12', 'CRLF accepted');
is(parse_os_release("ID=debian\nPRETTY_NAME=\"Has \\\$ literal\"\n")->{PRETTY_NAME},
   'Has $ literal', 'escaped dollar is literal (never expanded)');
is(parse_os_release("ID=debian\nPRETTY_NAME=\"Foo\\\\Bar\"\n")->{PRETTY_NAME},
   'Foo\\Bar', 'escaped backslash is preserved as data');

reject('', 'empty file rejected');
reject("# comment only\n", 'comment only rejected');
reject("ID=Debian\n", 'ID must be lower case');
reject("ID=\n", 'empty ID rejected');
reject("ID_LIKE=\"rhel  debian\"\n", 'noncanonical ID_LIKE rejected');
reject("ID=debian\nVERSION_ID=\"12 (old)\"\n", 'non-token VERSION_ID rejected');
reject("export ID=debian\n", 'export command refused');
reject("ID=\$(touch /tmp/never)\n", 'shell substitution rejected');
reject("ID=debian;id\n", 'command separator rejected');
reject("ID=\"debian\"suffix\n", 'quote concatenation rejected');
reject("ID=debian #comment\n", 'trailing inline comment rejected');
reject("ID=debian\0\n", 'NUL rejected');
reject("ID=debian\e[31m\n", 'escape sequences rejected');
reject("ID=debian\rX\n", 'isolated CR rejected');
reject("ID=debian\n" . ('A' x 4096) . "=1\n", 'oversized line rejected');
reject("ID=debian\n" . ('#x' . "\n") x 515, 'excessive number of lines rejected');
reject('ID=debian' . (' ' x 65536), 'input above size limit rejected');
reject("ID=debian\nPRETTY_NAME=\"invalid\\q\"\n", 'unsupported escape rejected');
reject("id=debian\n", 'lowercase key rejected');
reject("ID=debian\nPRETTY_NAME=\"bad" . "\t" . "name\"\n", 'embedded tab rejected');

my ($status, $stdout, $stderr) = run_cli("ID=ubuntu\nID_LIKE=debian\nVERSION_ID=24.04\n");
is($status, 0, 'CLI fixture accepted');
like($stdout, qr/\ASOURCE\tID\tID_LIKE\tVERSION_ID\tFAMILY\tEVIDENCE\tVERSION_MODE\n/, 'TSV header is stable');
like($stdout, qr/INPUT\tubuntu\tdebian\t24\.04\tdebian\tID\tVERSIONED\n\z/, 'CLI output follows contract');
is($stderr, '', 'no stderr on success');
($status, $stdout) = run_cli("ID=arch\n", '--null');
is($status, 0, 'NUL output succeeds');
is($stdout, join("\0", 'INPUT', 'arch', '-', '-', 'arch', 'ID', 'ROLLING') . "\0", 'exactly seven NUL fields, no header');
($status, $stdout, $stderr) = run_cli("ID=\$(id)\n");
is($status, 3, 'malformed offline snapshot fails closed');
is($stdout, '', 'invalid fixture produces no partial output');
unlike($stderr, qr/\$\(id\)/, 'invalid fixture value not echoed in diagnostics');

my $badlink = File::Spec->catfile($dir, 'alias');
symlink(File::Spec->catfile($dir, 'os-release-fixture'), $badlink) or die $!;
my $pid = open3(my $in, my $out, my $err = gensym, $^X, $bin, '--input', $badlink);
close $in;
local $/;
my $stdo = <$out> // '';
my $stde = <$err> // '';
waitpid($pid, 0);
is($? >> 8, 3, 'CLI rejects user-provided symlinks');
is($stdo, '', 'symlink rejection emits no report');
like($stde, qr/unsafe input/, 'safe concise symlink diagnostic');

my $native = qx{$^X "$bin"};
if ($^O eq 'linux' && (-e '/etc/os-release' || -e '/usr/lib/os-release')) {
    is($? >> 8, 0, 'local Linux native os-release can be read');
    like($native, qr/\A(?:SOURCE\t.*\n)(?:ETC|USR_LIB)\t/, 'native provenance reported');
} else {
    pass('native Linux probe not applicable here');
}

done_testing();
