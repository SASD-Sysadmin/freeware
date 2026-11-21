#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# FR2-02: documentation contract only. This does not claim that any particular
# Perl release or native client has been exercised on this test host.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;

my $root = File::Spec->catdir($FindBin::Bin, '..');

sub read_text {
    my ($relative) = @_;
    my $file = File::Spec->catfile($root, split m{/}, $relative);
    open my $fh, '<', $file or die "cannot read $relative: $!";
    local $/;
    my $data = <$fh>;
    close $fh or die "cannot close $relative: $!";
    return $data;
}

for my $lang ('', '.de') {
    my $readme = read_text("README$lang.md");
    my $details = read_text("docs/PERL-COMPATIBILITY$lang.md");
    my $platforms = read_text("docs/PLATFORMS$lang.md");
    my $testing = read_text("docs/TESTING$lang.md");
    my $gaps = read_text("docs/RELEASE-GAPS$lang.md");

    unlike($readme, qr/Perl\s+(?:5\.8\s+or\s+later|ab\s+Version\s+5\.8)/i,
        "README$lang does not repeat the unsupported generic Perl 5.8 claim");
    like($readme, qr/PERL-COMPATIBILITY$lang\.md/,
        "README$lang links to the runtime matrix");
    like($readme, qr/5\.14\.4/,
        "README$lang identifies the tested historical runtime");
    like($details, qr/b1960f4d0dda11e736fe71829953cfb5e4398c63/,
        "Runtime matrix$lang pins the verified source commit");
    like($details, qr/6[.,]146/,
        "Runtime matrix$lang records test-case count");
    like($details, qr/IO::Socket::SSL\s*(?:>=|ab)\s*2\.009/,
        "Runtime matrix$lang preserves verified-STARTTLS module requirement");
    like($details, qr/MANUAL=7/,
        "Runtime matrix$lang keeps manual gates explicit");
    like($platforms, qr/PERL-COMPATIBILITY$lang\.md/,
        "Platform matrix$lang links runtime evidence");
    like($testing, qr/PERL-COMPATIBILITY$lang\.md/,
        "Testing guide$lang links runtime evidence");
    like($gaps, qr/FR2-02/, "Release gap notes$lang include FR2-02 evidence");
}

ok(-f File::Spec->catfile($root, 'tools', 'fr2-02-compat-audit.sh'),
    'Versioned FR2-02 audit helper exists');
done_testing();
