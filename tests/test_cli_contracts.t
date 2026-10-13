#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Test the public metadata contract of every installed command, not only a
# hand-maintained allowlist. --help and --version must never need root access,
# network services, or user-specific configuration.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Basename qw(basename);
use IPC::Open3;
use Symbol qw(gensym);

my $root = File::Spec->rel2abs("$FindBin::Bin/..");
my @commands;
for my $section (qw(bin sbin)) {
    my $directory = File::Spec->catdir($root, $section);
    opendir my $dh, $directory or die "cannot list $directory: $!";
    while (defined(my $name = readdir $dh)) {
        next if $name =~ /^\./;
        my $file = File::Spec->catfile($directory, $name);
        next unless -f $file && -x $file && !-l $file;
        push @commands, [$file, $name, $section];
    }
    closedir $dh or die "cannot close $directory: $!";
}
@commands = sort { $a->[1] cmp $b->[1] } @commands;
ok(@commands >= 30, 'all known commands discovered from bin/ and sbin/');

for my $command (@commands) {
    my ($path, $name, $section) = @$command;
    my ($help_status, $help_out, $help_err) = invoke($path, '--help');
    is($help_status, 0, "$name --help exits successfully");
    like($help_out, qr/^Usage:\s+/m, "$name --help prints usage on stdout");
    is($help_err, '', "$name --help does not print diagnostics");

    my ($version_status, $version_out, $version_err) = invoke($path, '--version');
    is($version_status, 0, "$name --version exits successfully");
    like($version_out, qr/\A\Q$name\E \d+\.\d+\.\d+\n\z/,
        "$name --version has stable command-name and SemVer shape");
    is($version_err, '', "$name --version does not print diagnostics");

    my $section_number = $section eq 'bin' ? 1 : 8;
    ok(-f File::Spec->catfile($root, 'man', "man$section_number", "$name.$section_number"),
       "$name has a matching man$section_number page");
}
done_testing();

# Explicit argv list: no shell interpretation of flags or file paths.
sub invoke {
    my ($path, @args) = @_;
    my $err = gensym();
    my $pid = open3(my $input, my $output, $err, $path, @args);
    close $input;
    local $/;
    my $stdout = <$output>;
    my $stderr = <$err>;
    close $output;
    close $err;
    waitpid($pid, 0);
    my $status = $?;
    return (($status & 127) ? -1 : ($status >> 8),
            defined($stdout) ? $stdout : '',
            defined($stderr) ? $stderr : '');
}
