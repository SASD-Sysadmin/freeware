package SASD::Freeware::Trace::Strace;
# SPDX-License-Identifier: MIT
# Conservative parser for saved Linux strace text. No syscall name list is
# used: unknown names remain observable records rather than being discarded.
use strict;
use warnings;
use SASD::Freeware::Trace::Event;
our $VERSION = '0.1.0';

sub new {
    my ($class, %args) = @_;
    ref($args{reader}) && $args{reader}->can('next_record')
        or die "trace parser: reader is required\n";
    my $pending_limit = defined($args{max_pending}) ? $args{max_pending} : 1024;
    $pending_limit =~ /\A[1-9][0-9]*\z/ && $pending_limit <= 65536
        or die "trace parser: invalid pending limit\n";
    return bless { reader => $args{reader}, pending => {}, max_pending => $pending_limit,
                   eof_done => 0, stats => {} }, $class;
}

sub next_event {
    my ($self) = @_;
    if ($self->{eof_done}) { return undef; }
    while (1) {
        my $row = $self->{reader}->next_record();
        if ($row->{status} eq 'eof') {
            my @keys = sort keys %{$self->{pending}};
            if (@keys) {
                my $key = shift @keys;
                my $p = delete $self->{pending}{$key};
                return _event($self, 'incomplete', $p->{lines},
                    syscall => $p->{name}, arguments => $p->{args},
                    continuation => 'unfinished-at-eof',
                    diagnostic => 'unfinished call reached end of input');
            }
            $self->{eof_done} = 1;
            return undef;
        }
        if ($row->{status} eq 'error') {
            $self->{eof_done} = 1;
            return _event($self, 'reader_error', [], diagnostic => $row->{diagnostic});
        }
        if ($row->{status} ne 'line') {
            return _event($self, $row->{status} eq 'truncated' ? 'malformed' : 'malformed',
                [$row->{line_no}], diagnostic => $row->{diagnostic} || 'input record rejected',
                continuation => $row->{status});
        }
        my $event = $self->_parse_line($row->{text}, $row->{line_no});
        return $event if $event;
    }
}

sub _event {
    my ($self, $type, $lines, %args) = @_;
    $self->{stats}{$type}++;
    return SASD::Freeware::Trace::Event->new(type => $type, source_lines => $lines, %args);
}

sub stats { return { %{$_[0]->{stats}} }; }

sub _parse_line {
    my ($self, $line, $number) = @_;
    my ($prefix, $body, $trace_id) = ('', $line, undef);
    if ($body =~ s/^\[pid\s+([0-9]+)\]\s+//) { $trace_id = $1; }
    elsif ($body =~ /^([0-9]+)\s{2,}/) {
        $trace_id = $1;
        $body =~ s/^[0-9]+\s{2,}//;
    }
    my ($timestamp, $timestamp_format);
    if ($body =~ s/^(\d{2}:\d{2}:\d{2}\.\d+)\s+//) {
        $timestamp = $1; $timestamp_format = 'tt';
    } elsif ($body =~ s/^(\d+\.\d+)\s+//) {
        $timestamp = $1; $timestamp_format = 'ttt';
    }
    my %base = (source_lines => [$number]);
    $base{trace_id} = $trace_id if defined $trace_id;
    $base{pid_kind} = 'pid-or-tid' if defined $trace_id;
    $base{timestamp} = $timestamp if defined $timestamp;
    $base{timestamp_format} = $timestamp_format if defined $timestamp_format;
    if ($body =~ /^---\s+(SIG[A-Z0-9]+)\b(.*?)---\s*$/) {
        return $self->_event('signal', [$number], %base, signal => $1, arguments => $2,
                              continuation => 'signal');
    }
    if ($body =~ /^\+\+\+\s+(?:exited with\s+([^ ]+)|killed by\s+(SIG[A-Z0-9]+))\s*\+\+\+.*\z/) {
        return $self->_event('process_exit', [$number], %base,
            return_value => defined($1) ? $1 : '', signal => $2,
            process_event => defined($2) ? 'killed' : 'exited', continuation => 'complete');
    }
    if ($body =~ /^<\.\.\.\s+([A-Za-z_][A-Za-z0-9_]*)\s+resumed>(.*)$/) {
        my ($name, $tail) = ($1, $2);
        my $key = defined($trace_id) ? "pid:$trace_id" : 'stream:1';
        my $p = delete $self->{pending}{$key};
        return $self->_event('incomplete', [$number], %base, syscall => $name,
            continuation => 'resumed-without-previous', diagnostic => 'no matching unfinished call')
            unless $p && $p->{name} eq $name;
        my $combined = $p->{name} . '(' . $p->{args};
        $combined .= $tail unless $combined =~ /\s\z/ || $tail =~ /^\s/;
        $combined .= $tail if $combined =~ /\s\z/ || $tail =~ /^\s/;
        my $complete = $self->_parse_call($combined, [$p->{lines}[0], $number], \%base);
        return $complete if $complete;
        return $self->_event('malformed', [$p->{lines}[0], $number], %base,
            syscall => $name, continuation => 'resumed', diagnostic => 'resumed call syntax is invalid');
    }
    if ($body =~ /^([A-Za-z_][A-Za-z0-9_]*)\((.*)<unfinished \.\.\.>\s*$/s) {
        my ($name, $args) = ($1, $2);
        my $key = defined($trace_id) ? "pid:$trace_id" : 'stream:1';
        if (exists $self->{pending}{$key}) {
            my $old = delete $self->{pending}{$key};
            return $self->_event('incomplete', $old->{lines}, %base, syscall => $old->{name},
                arguments => $old->{args}, continuation => 'unfinished-replaced',
                diagnostic => 'another unfinished call used the same trace identity');
        }
        if (scalar(keys %{$self->{pending}}) >= $self->{max_pending}) {
            return $self->_event('incomplete', [$number], %base, syscall => $name,
                continuation => 'pending-limit', diagnostic => 'pending-call limit reached');
        }
        $self->{pending}{$key} = { name => $name, args => $args, lines => [$number] };
        return undef;
    }
    return $self->_parse_call($body, [$number], \%base)
        if $body =~ /^[A-Za-z_][A-Za-z0-9_]*\(/;
    return $self->_event('unsupported', [$number], %base,
        continuation => 'unsupported', diagnostic => 'record is not a supported strace event');
}

sub _parse_call {
    my ($self, $text, $lines, $base) = @_;
    my ($name) = $text =~ /^([A-Za-z_][A-Za-z0-9_]*)\(/;
    return undef unless defined $name;
    my $open = index($text, '(');
    my $close = _matching_paren($text, $open);
    return $self->_event('malformed', $lines, %$base, syscall => $name,
        continuation => 'malformed', diagnostic => 'unbalanced or unterminated arguments')
        unless defined $close;
    my $args = substr($text, $open + 1, $close - $open - 1);
    my $tail = substr($text, $close + 1);
    my ($duration) = $tail =~ /\s+<([0-9]+(?:\.[0-9]+)?)>\s*\z/;
    $tail =~ s/\s+<[0-9]+(?:\.[0-9]+)?>\s*\z// if defined $duration;
    $tail =~ s/^\s+//;
    my ($return, $errno, $error_text, $annotation);
    if ($tail =~ /^=\s*(.*?)\s*\z/s) {
        $return = $1;
        if ($return =~ /^-1\s+([A-Z][A-Z0-9_]*)(?:\s+\((.*)\))?\z/s) {
            $errno = $1; $error_text = $2 if defined $2;
        }
        if ($return =~ s/(\s*<[^>]{0,512}>\s*)\z//) { $annotation = $1; }
    } elsif ($tail ne '') {
        return $self->_event('malformed', $lines, %$base, syscall => $name,
            continuation => 'malformed', diagnostic => 'missing return separator');
    } else {
        return $self->_event('incomplete', $lines, %$base, syscall => $name,
            continuation => 'missing-result', diagnostic => 'call has no result');
    }
    my %args = (%$base, syscall => $name, arguments => _bounded($args),
        return_value => _bounded($return), continuation => 'complete');
    delete $args{source_lines};
    $args{errno} = _bounded($errno) if defined $errno;
    $args{error_text} = _bounded($error_text) if defined $error_text;
    $args{duration} = $duration if defined $duration;
    $args{resource_annotation} = _bounded($annotation) if defined $annotation;
    return $self->_event('syscall', $lines, %args);
}

sub _bounded { my ($s) = @_; return undef unless defined $s; return substr($s, 0, 4096); }

sub _matching_paren {
    my ($s, $open) = @_;
    my @stack = ('('); my $quote = ''; my $escape = 0;
    for (my $i = $open + 1; $i < length($s); ++$i) {
        my $c = substr($s, $i, 1);
        if ($quote ne '') {
            if ($escape) { $escape = 0; next; }
            if ($c eq '\\') { $escape = 1; next; }
            $quote = '' if $c eq $quote;
            next;
        }
        if ($c eq '"' || $c eq "'") { $quote = $c; next; }
        if ($c eq '(' || $c eq '[' || $c eq '{') { push @stack, $c; next; }
        if ($c eq ')' || $c eq ']' || $c eq '}') {
            my %close = (')' => '(', ']' => '[', '}' => '{');
            return undef unless @stack && $stack[-1] eq $close{$c};
            pop @stack; return $i if !@stack;
        }
    }
    return undef;
}

1;
