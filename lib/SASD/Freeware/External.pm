package SASD::Freeware::External;
# SPDX-License-Identifier: MIT
# Search PATH explicitly; do not depend on which, whereis, or shell parsing.
use strict;
use warnings;
use Exporter 'import';
use File::Spec;
our @EXPORT_OK = qw(find_program);
our $VERSION = '0.1.0';

sub find_program {
    my ($name) = @_;
    return undef if !defined($name) || $name !~ /\A[A-Za-z0-9_.-]+\z/;
    foreach my $dir (split(/:/, defined($ENV{PATH}) ? $ENV{PATH} : '')) {
        # Ignore relative/empty PATH entries to avoid executing programs from
        # an unexpected working directory in a privileged environment.
        next unless File::Spec->file_name_is_absolute($dir);
        my $file = File::Spec->catfile($dir, $name);
        return $file if -f $file && -x $file;
    }
    return undef;
}
1;
