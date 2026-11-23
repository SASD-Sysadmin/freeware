#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# Documentation and safety contracts for FR2-06a. No privileged operations.
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

my $root = File::Spec->catdir($FindBin::Bin, '..');
sub load_file {
    my ($relative) = @_;
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    open my $fh, '<', $path or die "cannot read $relative: $!";
    local $/;
    my $contents = <$fh>;
    close $fh or die "cannot close $relative: $!";
    return $contents;
}
my $script_path = File::Spec->catfile($root, qw(tools fr2-06a-staging-acceptance.sh));
my $shell = load_file('tools/fr2-06a-staging-acceptance.sh');
like($shell, qr/\A\#!\/usr\/bin\/env bash\n/, 'Bash shebang');
like($shell, qr/^# SPDX-License-Identifier: MIT$/m, 'source remains MIT');
like($shell, qr/\bset -Eeuo pipefail\b/, 'strict Bash failure propagation');
like($shell, qr/\bEUID == 0\b/, 'privileged execution rejected');
like($shell, qr/\bmktemp -d\b/, 'disposable private fixture');
like($shell, qr/\bDESTDIR|--destdir\b/, 'installer restricted to DESTDIR');
like($shell, qr/--mode install/, 'real installer is used for local fixtures');
like($shell, qr/--mode uninstall/, 'real uninstaller is used for local fixtures');
unlike($shell, qr/\bsudo\s+(?:perl|make|useradd|setquota|virsh)\b/, 'no sudo execution');
unlike($shell, qr/\s--apply(?:\s|$)/m, 'no real privileged apply arguments');
unlike($shell, qr/\bvirsh\s+(?:snapshot-create|snapshot-revert|destroy|undefine)\b/, 'no mutating libvirt calls');

my $syntax = system('bash', '-n', $script_path);
is($syntax >> 8, 0, 'shell syntax check');
my $help = qx{bash "$script_path" --help};
is($? >> 8, 0, 'help returns zero');
like($help, qr/nonprivileged|Unprivileged|No sudo/i, 'help identifies safety boundary');

for my $lang ('', '.de') {
    my $label = $lang eq '' ? 'EN' : 'DE';
    my $plan = load_file('docs/FR2-06-VM-ACCEPTANCE' . $lang . '.md');
    my $form = load_file('docs/FR2-06-REPORT-TEMPLATE' . $lang . '.md');
    for my $gate (qw(privileged-vm staged-upgrade current-ci artifact-provenance release-approval native-platforms live-services)) {
        like($plan, qr/\Q$gate\E/, "$label: manual gate $gate not erased");
    }
    like($plan, qr/f25aa3f2f5c84911fa03d7b8a93daff06b736bef/, "$label: starting commit recorded");
    like($plan, qr/45139166377/, "$label: verified CI evidence recorded");
    like($plan, qr/AGPL-3\.0-only/, "$label: company license choice retained");
    like($plan, qr/FR2-06-REPORT-TEMPLATE\Q$lang\E\.md/, "$label: report template linked");
    like($form, qr/VM-08/, "$label: restore evidence row exists");
    like($form, qr/NOT RUN/, "$label: no fabricated run results");
    like($form, qr/BLOCKED/, "$label: real apply remains blocked by default");
}
my $license = load_file('LICENSE');
like($license, qr/\AMIT License\s*\n/, 'current repository LICENSE unchanged');
my $changelog = load_file('CHANGELOG.md');
like($changelog, qr/FR2-06a/, 'FR2-06a recorded in changelog');
for my $lang ('', '.de') {
    my $readme = load_file($lang eq '' ? 'README.md' : 'README.de.md');
    like($readme, qr/docs\/FR2-06-VM-ACCEPTANCE\Q$lang\E\.md/, 'README links to VM plan');
}
done_testing();
