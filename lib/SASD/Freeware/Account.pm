package SASD::Freeware::Account;
# SPDX-License-Identifier: MIT
# Read native Unix passwd/group records without conflating local and NSS identities.
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(read_local valid_name display_field);
our $VERSION = '0.1.0';

sub valid_name {
    my ($name) = @_;
    return defined($name) && $name =~ /\A[A-Za-z_][A-Za-z0-9_.-]*\$?\z/;
}
sub display_field {
    my ($field) = @_;
    $field = '' unless defined($field);
    $field =~ s/([\\\x00-\x1f\x7f])/sprintf('\\x%02X', ord($1))/ge;
    return $field;
}
sub valid_id {
    my ($id) = @_;
    return 0 if !defined($id) || $id !~ /\A[0-9]{1,10}\z/;
    $id =~ s/\A0+(?=[0-9])//;
    return length($id) < 10 || (length($id) == 10 && $id le '4294967295');
}
# Returns undef only for file I/O failure. Other malformed records are reported
# and skipped; the caller receives an error count and MUST return nonzero.
sub read_local {
    my ($file, $type, $diagnostic) = @_;
    die 'type must be passwd or group' unless $type eq 'passwd' || $type eq 'group';
    my $fh;
    if (!open($fh, '<', $file)) {
        $diagnostic->("cannot read " . display_field($file) . ": $!");
        return undef;
    }
    my @records;
    my ($errors, $compat, $line_no) = (0, 0, 0);
    while (my $line = <$fh>) {
        ++$line_no;
        $line =~ s/\n\z//;
        $line =~ s/\r\z//;
        next if $line eq '' || $line =~ /\A\s*#/;
        if ($line =~ /\A[+-]/) {
            ++$compat;
            $diagnostic->(display_field($file) . ":$line_no: NIS compatibility record skipped");
            next;
        }
        my @parts = split(/:/, $line, -1);
        my $valid = $type eq 'passwd'
            ? @parts == 7 && valid_name($parts[0]) && valid_id($parts[2]) &&
              valid_id($parts[3]) && $parts[5] =~ m{\A/} && $parts[5] !~ /[\x00-\x1f\x7f]/
            : @parts == 4 && valid_name($parts[0]) && valid_id($parts[2]);
        if (!$valid) {
            ++$errors;
            $diagnostic->(display_field($file) . ":$line_no: invalid $type record");
            next;
        }
        push @records, \@parts;
    }
    if (!close($fh)) {
        $diagnostic->('cannot close ' . display_field($file) . ": $!");
        return undef;
    }
    return {records => \@records, errors => $errors, compat => $compat};
}
1;
