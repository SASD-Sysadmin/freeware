#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# FR2-05 is a documentation-only evidence/decision slice. This regression
# protects the chosen license split without changing any shipped code/license.
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

my $root = File::Spec->catdir($FindBin::Bin, '..');
sub source {
    my ($rel) = @_;
    my $path = File::Spec->catfile($root, split m{/}, $rel);
    open my $in, '<', $path or die "cannot read $rel: $!";
    local $/;
    my $content = <$in>;
    close($in) or die "cannot close $rel: $!";
    return $content;
}

my $license = source('LICENSE');
like($license, qr/\AMIT License\s*\n/, 'existing root license remains MIT');
unlike($license, qr/AGPL-3\.0-only/, 'root MIT license was not silently replaced');

for my $lang ('', '.de') {
    my $suffix = $lang eq '' ? 'English' : 'German';
    my $policy = source('docs/LICENSE-STRATEGY' . $lang . '.md');
    my $register = source('docs/RELEASE-EVIDENCE' . $lang . '.md');
    my $readme = source($lang eq '' ? 'README.md' : 'README.de.md');
    my $provenance = source('docs/LICENSE-PROVENANCE' . $lang . '.md');
    my $roadmap = source('docs/ROADMAP' . $lang . '.md');
    my $gaps = source('docs/RELEASE-GAPS' . $lang . '.md');

    like($policy, qr/SASD-Sysadmin\/freeware/, "$suffix: existing repo identified");
    like($policy, qr/\bMIT\b/, "$suffix: MIT beta policy documented");
    like($policy, qr/SASDGMBH/, "$suffix: future corporate track identified");
    like($policy, qr/AGPL-3\.0-only/, "$suffix: exact AGPL-only identifier documented");
    like($policy, qr/(?:OFFEN|OPEN)/, "$suffix: unresolved legal/release actions not silently passed");
    like($register, qr/686a86b88317c15a6be0413a3278e32d069dbd75/, "$suffix: baseline pinned");
    like($register, qr/45131942704/, "$suffix: actual CI run linked");
    like($register, qr/45128966544/, "$suffix: installer CI evidence linked");
    like($register, qr/44950599429/, "$suffix: Perl-documentation CI linked");
    like($register, qr/\bMANUAL\b/, "$suffix: manual gates remain visible");
    for my $gate (qw(current-ci privileged-vm staged-upgrade artifact-provenance release-approval native-platforms live-services)) {
        like($register, qr/\Q$gate\E/, "$suffix: manual gate $gate recorded");
    }
    like($readme, qr/docs\/LICENSE-STRATEGY\Q$lang\E\.md/, "$suffix: README links to the decided strategy");
    like($readme, qr/docs\/RELEASE-EVIDENCE\Q$lang\E\.md/, "$suffix: README links the evidence record");
    like($provenance, qr/LICENSE-STRATEGY\Q$lang\E\.md/, "$suffix: provenance points to current decision");
    like($roadmap, qr/RELEASE-EVIDENCE\Q$lang\E\.md/, "$suffix: roadmap points to evidence record");
    like($gaps, qr/RELEASE-EVIDENCE\Q$lang\E\.md/, "$suffix: release gaps point to evidence record");
}

my $changelog = source('CHANGELOG.md');
my $heading = index($changelog, '## [Unreleased]');
my $fr2 = index($changelog, '### FR2-04 – Preliminary MIT notice');
ok($heading >= 0 && $fr2 > $heading, 'old FR2-04 changelog section is under Unreleased');
like($changelog, qr/FR2-05 – Recorded release evidence/, 'FR2-05 change recorded');

done_testing();
