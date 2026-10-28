package SASD::Freeware::TextEOL;
# SPDX-License-Identifier: MIT
# Detect and (on explicit request) normalize CRLF in conservatively selected
# regular text files. No subprocesses, shells, or external converters are used.
use strict;
use warnings;
use Exporter 'import';
use Fcntl qw(O_RDONLY S_ISREG);
use File::Temp qw(tempfile);
use File::Basename qw(dirname);
use Digest::SHA;

our @EXPORT_OK = qw(inspect_file convert_file);
our $VERSION = '0.1.0';

# Return a status, optional diagnostic, and a source fingerprint. The caller
# can print the status without ever modifying the filesystem.
# Never use -T/-B heuristics: they sample too little and can classify binary
# data containing CRLF as text. Instead reject NUL and most C0 controls in
# the entire bounded file. UTF-16 is intentionally unsupported.
sub inspect_file {
    my ($path, $max_bytes, $min_age) = @_;
    my @before = lstat($path);
    return {status => 'error', detail => "lstat failed: $!"} unless @before;
    return {status => 'skip', detail => 'not an ordinary regular file'}
        unless S_ISREG($before[2]);
    return {status => 'skip', detail => 'multiple hard links'} if $before[3] != 1;
    return {status => 'skip', detail => 'setuid/setgid file'} if $before[2] & 06000;
    return {status => 'skip', detail => 'file exceeds size limit'} if $before[7] > $max_bytes;
    return {status => 'skip', detail => 'file is too recent'}
        if $min_age > 0 && time() - $before[9] < $min_age;

    # O_NOFOLLOW is available on Linux and modern BSD/macOS. An fstat/lstat
    # inode identity check is still mandatory to detect pathname replacement.
    my $no_follow = eval { Fcntl::O_NOFOLLOW() } || 0;
    sysopen(my $in, $path, O_RDONLY | $no_follow)
        or return {status => 'error', detail => "open failed: $!"};
    binmode($in) or return {status => 'error', detail => "binmode failed: $!"};
    my @opened = stat($in);
    if (!_same_inode(\@before, \@opened) || !S_ISREG($opened[2])) {
        close($in);
        return {status => 'error', detail => 'file changed between lstat and open'};
    }
    my ($crlf, $lf, $cr, $bytes, $binary, $tail) = (0,0,0,0,0,'');
    my $sha = Digest::SHA->new(256);
    while (1) {
        my $chunk = '';
        my $read = sysread($in, $chunk, 65536);
        if (!defined($read)) {
            my $error = "$!"; close($in);
            return {status => 'error', detail => "read failed: $error"};
        }
        last if $read == 0;
        $bytes += $read;
        if ($bytes > $max_bytes) {
            close($in);
            return {status => 'skip', detail => 'file exceeds size limit'};
        }
        $sha->add($chunk);
        $binary = 1 if $chunk =~ /[\x00-\x08\x0B\x0E-\x1F\x7F]/;
        # Carry the trailing CR to the next buffer so split CRLF pairs are
        # counted correctly even on a 64 KiB read boundary.
        $chunk = $tail . $chunk;
        $tail = '';
        if (substr($chunk, -1) eq "\r") { chop($chunk); $tail = "\r"; }
        $crlf += () = $chunk =~ /\r\n/g;
        $lf   += () = $chunk =~ /(?<!\r)\n/g;
        $cr   += () = $chunk =~ /\r(?!\n)/g;
    }
    $cr++ if $tail eq "\r";
    my @after = stat($in);
    if (!close($in)) { return {status => 'error', detail => "close failed: $!"}; }
    return {status => 'error', detail => 'file changed during inspection'}
        unless _same_identity(\@before, \@after) && $bytes == $before[7];
    return {status => 'skip', detail => 'binary or unsupported text encoding'} if $binary;
    return {status => 'skip', detail => 'standalone CR line endings present'} if $cr;
    return {status => 'unix', detail => 'no CRLF found'} if !$crlf;
    return {status => 'dos', crlf => $crlf, lf => $lf,
             fingerprint => $sha->hexdigest, stat => \@before};
}

# Convert a previously inspected candidate to a new file in its own parent
# directory, then rename it over the old name. A failed write never truncates
# the original; failures during staging leave no temporary output behind.
# Like all pathname operations, the final check/rename pair is not a lock
# against noncooperating writers. Use completed, privately controlled imports.
sub convert_file {
    my ($path, $inspection) = @_;
    return (0, 'not a confirmed DOS-text candidate')
        unless ref($inspection) eq 'HASH' && ($inspection->{status} || '') eq 'dos';
    my @initial = @{$inspection->{stat}};
    my @now = lstat($path);
    return (0, 'source changed since inspection') unless _same_identity(\@initial, \@now);
    # Replacing an inode may erase ACLs and extended attributes. For the
    # initial release we restrict writes to the current file owner, reject
    # hardlinks, and document that advanced metadata is not preserved.
    return (0, 'source is not owned by effective user') if $now[4] != $>;
    return (0, 'multiple hard links') if $now[3] != 1;
    return (0, 'setuid/setgid file') if $now[2] & 06000;

    my $no_follow = eval { Fcntl::O_NOFOLLOW() } || 0;
    sysopen(my $in, $path, O_RDONLY | $no_follow)
        or return (0, "source open failed: $!");
    binmode($in);
    my @opened = stat($in);
    unless (_same_identity(\@initial, \@opened)) {
        close($in);
        return (0, 'source changed before conversion');
    }

    my ($out, $staged);
    eval { ($out, $staged) = tempfile('.sasd-eol-XXXXXXXX', DIR => dirname($path), UNLINK => 0); 1 }
        or do { my $e = $@ || "$!"; close($in); return (0, "cannot create staging file: $e"); };
    binmode($out);
    my $ok = eval {
        local $SIG{INT} = sub { die "interrupted by SIGINT" };
        local $SIG{TERM} = sub { die "interrupted by SIGTERM" };
        my $sha = Digest::SHA->new(256);
        my $carry = '';
        while (1) {
            my $chunk = '';
            my $n = sysread($in, $chunk, 65536);
            defined($n) or die "source read failed: $!";
            last if $n == 0;
            $sha->add($chunk);
            $chunk = $carry . $chunk;
            $carry = '';
            if (substr($chunk, -1) eq "\r") { chop($chunk); $carry = "\r"; }
            $chunk =~ s/\r\n/\n/g;
            _write_all($out, $chunk);
        }
        _write_all($out, $carry) if length($carry);
        $sha->hexdigest eq $inspection->{fingerprint}
            or die 'source content changed during conversion';
        my @after = stat($in);
        _same_identity(\@initial, \@after)
            or die 'source metadata changed during conversion';
        close($in) or die "source close failed: $!";
        # Preserve the group before applying the final permissions, since
        # chown may clear setgid or other mode bits on some systems.
        my @staged_stat = stat($out);
        if ($staged_stat[5] != $initial[5]) {
            chown(-1, $initial[5], $staged) == 1
                or die "cannot preserve source group: $!";
        }
        chmod($initial[2] & 0777, $staged) == 1 or die "chmod staging file failed: $!";
        close($out) or die "staging close failed: $!";
        my @current = lstat($path);
        _same_identity(\@initial, \@current)
            or die 'source changed before final rename';
        rename($staged, $path) or die "atomic rename failed: $!";
        1;
    };
    my $error = $@;
    unless ($ok) {
        close($in) if defined(fileno($in));
        close($out) if defined(fileno($out));
        unlink($staged) if defined($staged) && -e $staged;
        return (0, $error || 'unknown conversion failure');
    }
    return (1, 'converted');
}

sub _write_all {
    my ($out, $data) = @_;
    my $offset = 0;
    while ($offset < length($data)) {
        my $written = syswrite($out, $data, length($data) - $offset, $offset);
        defined($written) && $written > 0 or die "staging write failed: $!";
        $offset += $written;
    }
}

sub _same_inode {
    my ($a, $b) = @_;
    return @$a && @$b && $a->[0] == $b->[0] && $a->[1] == $b->[1];
}
sub _same_identity {
    my ($a, $b) = @_;
    return _same_inode($a, $b) && $a->[2] == $b->[2]
        && $a->[3] == $b->[3] && $a->[4] == $b->[4]
        && $a->[5] == $b->[5] && $a->[7] == $b->[7]
        && $a->[9] == $b->[9] && $a->[10] == $b->[10];
}
1;
