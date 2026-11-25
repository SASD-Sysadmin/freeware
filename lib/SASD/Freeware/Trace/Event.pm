package SASD::Freeware::Trace::Event;
# SPDX-License-Identifier: MIT
# Small, deliberately boring internal event model for offline trace parsing.
use strict;
use warnings;
our $VERSION = '0.1.0';

my %TYPES = map { $_ => 1 } qw(syscall signal process_exit malformed unsupported incomplete reader_error);

sub new {
    my ($class, %args) = @_;
    my $type = $args{type};
    defined($type) && $TYPES{$type} or die "invalid trace event type\n";
    my $lines = $args{source_lines};
    if (defined $lines) {
        ref($lines) eq 'ARRAY' or die "invalid trace source lines\n";
        for my $line (@$lines) {
            defined($line) && !ref($line) && $line =~ /\A[1-9][0-9]*\z/
                or die "invalid trace source line\n";
        }
    } else {
        $args{source_lines} = [];
    }
    for my $field (qw(syscall arguments return_value errno duration signal process_event
                      timestamp timestamp_format diagnostic continuation trace_id)) {
        defined($args{$field}) && !ref($args{$field})
            or next;
        $args{$field} =~ s/[\x00-\x1f\x7f]/sprintf('\\x%02X', ord($&))/ge;
        $args{$field} = substr($args{$field}, 0, 4096) if length($args{$field}) > 4096;
    }
    $args{type} = $type;
    $args{platform} = 'linux' if !defined $args{platform};
    $args{source_format} = 'strace-text' if !defined $args{source_format};
    return bless \%args, $class;
}

sub type { return $_[0]->{type}; }
sub as_hash { my ($self) = @_; return { %$self }; }

1;
