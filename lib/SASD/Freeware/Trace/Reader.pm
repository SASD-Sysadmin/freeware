package SASD::Freeware::Trace::Reader;
# SPDX-License-Identifier: MIT
# Bounded byte reader. It never uses <> or readline, because those can first
# allocate an arbitrarily large physical line supplied by an untrusted trace.
use strict;
use warnings;
use Fcntl qw(S_ISREG S_ISLNK);
our $VERSION = '0.1.0';

sub open_file {
    my ($class, $path, %opts) = @_;
    defined($path) && $path ne '' && $path ne '-' or die "trace reader: invalid path\n";
    my @st = lstat($path);
    @st && S_ISREG($st[2]) && !S_ISLNK($st[2])
        or die "trace reader: input is not a regular non-symlink file\n";
    open my $fh, '<', $path or die "trace reader: cannot open input\n";
    binmode $fh or die "trace reader: cannot set binary mode\n";
    return $class->new(fh => $fh, %opts);
}

sub new {
    my ($class, %args) = @_;
    my $fh = $args{fh};
    defined($fh) or die "trace reader: filehandle is required\n";
    binmode $fh or die "trace reader: cannot set binary mode\n";
    my $max = defined($args{max_line_bytes}) ? $args{max_line_bytes} : 65536;
    my $chunk = defined($args{chunk_bytes}) ? $args{chunk_bytes} : 4096;
    my $discard = defined($args{max_discard_bytes}) ? $args{max_discard_bytes} : 1048576;
    $max =~ /\A[1-9][0-9]*\z/ && $max <= 1048576 or die "trace reader: invalid line limit\n";
    $chunk =~ /\A[1-9][0-9]*\z/ && $chunk <= 1048576 or die "trace reader: invalid chunk limit\n";
    $discard =~ /\A[1-9][0-9]*\z/ && $discard >= $max && $discard <= 16777216
        or die "trace reader: invalid discard limit\n";
    return bless {
        fh => $fh, max => 0 + $max, chunk => 0 + $chunk, discard => 0 + $discard,
        buffer => '', line => 0, eof => 0, pending_error => undef,
    }, $class;
}

sub next_record {
    my ($self) = @_;
    return { status => 'eof' } if $self->{eof} && $self->{buffer} eq '';
    my $discarded = 0;
    while (1) {
        my $pos = index($self->{buffer}, "\n");
        if ($pos >= 0) {
            my $raw = substr($self->{buffer}, 0, $pos + 1, '');
            ++$self->{line};
            $raw =~ s/\n\z//;
            $raw =~ s/\r\z//;
            if ($discarded) {
                return { status => 'truncated', line_no => $self->{line},
                         discarded_bytes => $discarded + length($raw) };
            }
            return _validate($self, $raw);
        }
        if (length($self->{buffer}) > $self->{max}) {
            my $cut = length($self->{buffer}) - $self->{max};
            substr($self->{buffer}, 0, $cut, '');
            $discarded += $cut;
            if ($discarded > $self->{discard}) {
                # Keep consuming safely until LF, but report one bounded record.
                $discarded = $self->{discard};
            }
        }
        if ($self->{eof}) {
            if ($self->{buffer} ne '') {
                my $raw = substr($self->{buffer}, 0, length($self->{buffer}), '');
                ++$self->{line};
                return { status => 'truncated', line_no => $self->{line},
                         discarded_bytes => $discarded + length($raw) }
                    if $discarded;
                $raw =~ s/\r\z//;
                return _validate($self, $raw);
            }
            return { status => 'eof' };
        }
        my $bytes = '';
        my $read = sysread($self->{fh}, $bytes, $self->{chunk});
        if (!defined $read) {
            return { status => 'error', diagnostic => 'input read failed' };
        }
        if ($read == 0) { $self->{eof} = 1; next; }
        $self->{buffer} .= $bytes;
    }
}

sub _validate {
    my ($self, $line) = @_;
    return { status => 'invalid', line_no => $self->{line}, diagnostic => 'NUL byte' }
        if $line =~ /\x00/;
    return { status => 'invalid', line_no => $self->{line}, diagnostic => 'control byte' }
        if $line =~ /[\x01-\x08\x0b\x0c\x0e-\x1f\x7f]/;
    return { status => 'line', line_no => $self->{line}, text => $line };
}

1;
