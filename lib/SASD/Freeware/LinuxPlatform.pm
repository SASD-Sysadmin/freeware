package SASD::Freeware::LinuxPlatform;
# SPDX-License-Identifier: MIT
# M8.5.1: pure parser and conservative distro-family classifier.
#
# Architecture:
#   (1) Acquisition belongs to the CLI; this module does not access the host.
#   (2) This parser accepts assignment *data*, never shell code. No eval,
#       backticks, interpolation, command invocation or environment mutation.
#   (3) Distribution ID is evidence; ID_LIKE is merely a compatibility hint.
#       We do not infer installed package managers or security configuration.
use strict;
use warnings;
use Exporter qw(import);
our @EXPORT_OK = qw(parse_os_release summarize_os_release);

my $MAX_BYTES = 64 * 1024;
my $MAX_LINES = 512;
my $MAX_LINE_BYTES = 4096;

sub parse_os_release {
    my ($data) = @_;
    defined($data) && !ref($data) && length($data) <= $MAX_BYTES
        or die "invalid os-release input size\n";
    # No control characters, embedded NUL, isolated CR or terminal escapes.
    # LF and CRLF line delimiters are the only accepted control framing.
    $data !~ /\x00|\r(?!\n)|[\x01-\x09\x0b\x0c\x0e-\x1f\x7f]/
        or die "invalid os-release framing\n";
    my @lines = split /\n/, $data, -1;
    @lines <= $MAX_LINES + 1 or die "too many os-release lines\n";
    my %entries;
    for my $line (@lines) {
        $line =~ s/\r\z//;
        length($line) <= $MAX_LINE_BYTES or die "os-release line too long\n";
        next if $line =~ /\A *\z/ || $line =~ /\A *\#[^\r\n]*\z/;
        # Reject shell constructs such as export, substitutions, pipelines,
        # trailing comments after assignments and quoted-string concatenation.
        $line =~ /\A([A-Z][A-Z0-9_]*)=(.*)\z/s
            or die "invalid os-release assignment\n";
        my ($key, $raw) = ($1, $2);
        my $value;
        if ($raw =~ /\A"((?:\\.|[^"\\])*)"\z/s) {
            $value = $1;
            # Shell-like escaping *only* for syntax characters. Retain no
            # interpolation semantics: even an escaped $ is a literal byte.
            $value =~ s/\\(.)/_escaped_byte($1)/ge;
        } elsif ($raw =~ /\A'([^']*)'\z/s) {
            # POSIX single quotes have no escape processing.
            $value = $1;
        } elsif ($raw =~ /\A[A-Za-z0-9._+\/:\-]*\z/) {
            $value = $raw;
        } else {
            die "unsupported os-release value\n";
        }
        # os-release explicitly permits a repeated assignment; last wins.
        $entries{$key} = $value;
    }
    keys(%entries) or die "empty os-release input\n";
    return \%entries;
}

# Only the four shell syntax bytes are unescaped. No expansion takes place.
sub _escaped_byte {
    my ($ch) = @_;
    ($ch eq '\\' || $ch eq '"' || $ch eq '$' || $ch eq '`')
        or die "unsupported os-release escape\n";
    return $ch;
}

sub summarize_os_release {
    my ($fields, $source) = @_;
    ref($fields) eq 'HASH' && defined($source) && $source =~ /\A(?:ETC|USR_LIB|INPUT)\z/
        or die "invalid Linux platform summary arguments\n";
    my $id = exists($fields->{ID}) ? $fields->{ID} : 'linux';
    $id =~ /\A[a-z0-9._-]+\z/ or die "invalid os-release ID\n";
    my $version = $fields->{VERSION_ID} // '';
    $version =~ /\A[a-zA-Z0-9._+\-]*\z/ or die "invalid os-release VERSION_ID\n";
    my $like = $fields->{ID_LIKE} // '';
    $like =~ /\A(?:[a-z0-9._-]+(?: [a-z0-9._-]+)*)?\z/
        or die "invalid os-release ID_LIKE\n";
    my @like = length($like) ? split(/ /, $like) : ();
    # Family means packaging *lineage*, not OS identity or a validated tool.
    my %family = (
        debian => 'debian', ubuntu => 'debian',
        arch => 'arch',
        rhel => 'rhel', fedora => 'rhel', centos => 'rhel',
        almalinux => 'rhel', rocky => 'rhel',
        opensuse => 'suse', 'opensuse-leap' => 'suse',
        'opensuse-tumbleweed' => 'suse', sles => 'suse', suse => 'suse',
        alpine => 'alpine',
    );
    my $found = $family{$id};
    my $evidence = defined($found) ? 'ID' : 'UNKNOWN';
    if (!defined $found) {
        # Multiple conflicting parent families are ambiguous: do not guess.
        my %families = map { $family{$_} => 1 } grep { exists $family{$_} } @like;
        if (keys(%families) == 1) {
            ($found) = keys %families;
            $evidence = 'ID_LIKE';
        }
    }
    $found //= 'unknown';
    my $version_mode = length($version) ? 'VERSIONED'
                     : $id eq 'arch' ? 'ROLLING'
                     : 'UNKNOWN';
    # Output is intentionally restricted to vetted identifiers. PRETTY_NAME
    # and other arbitrary user/vendor strings are never emitted.
    return [$source, $id, (length($like) ? $like : '-'),
            (length($version) ? $version : '-'), $found,
            $evidence, $version_mode];
}

1;
