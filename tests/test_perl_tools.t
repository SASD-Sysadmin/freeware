#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;

my $root = File::Spec->catdir($FindBin::Bin, '..');
my $bin = File::Spec->catdir($root, 'bin');
my $tmp = tempdir('sasd-perl-tools-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);

sub write_file {
    my ($name, $text) = @_;
    my $path = File::Spec->catfile($tmp, $name);
    open my $out, '>', $path or die "$path: $!";
    print {$out} $text;
    close $out or die "$path: $!";
    return $path;
}
sub run_tool {
    my ($name, @args) = @_;
    my $program = File::Spec->catfile($bin, $name);
    open my $pipe, '-|', $^X, $program, @args or die "exec $program failed: $!";
    local $/;
    my $output = <$pipe> // '';
    close $pipe;
    return ($? >> 8, $output);
}

for my $tool (qw(fs-report hosts-lint account-audit log-summary)) {
    my ($status, $output) = run_tool($tool, '--help');
    is($status, 0, "$tool --help succeeds");
}

my $scan = File::Spec->catdir($tmp, 'scan');
mkdir $scan or die "$scan: $!";
write_file('scan/short.txt', 'abc');
write_file('scan/long file.txt', 'abcdefghijkl');
symlink 'short.txt', File::Spec->catfile($scan, 'link') or die "symlink: $!";
my ($rc, $out) = run_tool('fs-report', '--top', '1', '--min-size', '4', $scan);
is($rc, 0, 'fs-report succeeds');
like($out, qr/Regular files: 2\n/, 'two regular files');
like($out, qr/Symbolic links: 1\n/, 'symlink not followed');
like($out, qr/File bytes \(logical\): 15\n/, 'logical sizes summed');
like($out, qr/12\t.*long file\.txt/, 'largest file shown');
unlike($out, qr/3\t.*short\.txt/, 'too-small file excluded');
($rc, $out) = run_tool('fs-report', '--top', '0', $scan);
is($rc, 0, 'fs-report supports zero largest files');
unlike($out, qr/\n\d+\t.*long file/, 'no file listing with top zero');
($rc) = run_tool('fs-report', '--top', '1001', $scan);
is($rc, 2, 'fs-report refuses huge top count');

my $hosts = write_file('hosts', "127.0.0.1 localhost local # comment\n::1 ipv6-localhost\n192.0.2.42 test.example\n");
($rc, $out) = run_tool('hosts-lint', '--file', $hosts);
is($rc, 0, 'hosts-lint accepts IPv4, IPv6, comments');
like($out, qr/Entries: 3\n/, 'hosts-lint counts entries');
like($out, qr/Errors: 0\n/, 'hosts-lint reports no errors');
$hosts = write_file('bad.hosts', "999.4.5.6 invalid.example\n127.0.0.1\n127.0.0.2 valid\n");
($rc, $out) = run_tool('hosts-lint', '--file', $hosts);
is($rc, 1, 'hosts-lint fails malformed records');
like($out, qr/Errors: 2\n/, 'hosts-lint counts malformed records');

my $passwd = write_file('passwd', "root:x:0:0:root:/root:/bin/sh\nuser:x:1000:1000:User:/home/user:/bin/sh\n");
($rc, $out) = run_tool('account-audit', '--file', $passwd);
is($rc, 0, 'account-audit accepts standard passwd');
like($out, qr/Accounts: 2\n/, 'two accounts counted');
like($out, qr/Warnings: 0\n/, 'no warnings');
$passwd = write_file('unusual.passwd', "root:x:0:0:root:/root:/bin/sh\nadmin:x:0:0:Admin:/home/admin:/bin/sh\ngarbage\n");
($rc, $out) = run_tool('account-audit', '--file', $passwd);
is($rc, 1, 'account-audit detects malformed passwd');
like($out, qr/Warnings: 2\n/, 'account-audit identifies shared root UID');
like($out, qr/Errors: 1\n/, 'account-audit records structural error');

my $log = write_file('log', "INFO boot\nWARNING disk\nERROR disk\nCRITICAL crash\nanything else\n");
($rc, $out) = run_tool('log-summary', $log);
is($rc, 0, 'log-summary succeeds');
like($out, qr/Lines read: 5\nLines matched: 5\n/, 'counts all lines');
like($out, qr/CRITICAL: 1\nERROR: 1\nWARNING: 1\n/, 'counts severity');
like($out, qr/OTHER: 1\n/, 'counts uncategorized lines');
($rc, $out) = run_tool('log-summary', '--match', 'disk', $log);
is($rc, 0, 'literal filter succeeds');
like($out, qr/Lines read: 5\nLines matched: 2\n/, 'literal filter counts correct lines');
like($out, qr/CRITICAL: 0\nERROR: 1\nWARNING: 1\n/, 'filter affects severity counts');

# Tests should not require root privileges or touch system configuration.
done_testing();
