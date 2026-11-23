#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# FR2-04: deterministic offline contract checks for the read-only inventory.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use FindBin;

my $script = File::Spec->catfile($FindBin::Bin, '..', 'tools', 'fr2-04-provenance-audit.pl');
ok(-f $script, 'maintainer provenance audit exists');

my $root = tempdir('sasd-fr2-04-fixture-XXXXXX', TMPDIR => 1, CLEANUP => 1);
make_path(File::Spec->catdir($root, 'bin'), File::Spec->catdir($root, 'tools'));

sub put {
    my ($relative, $content) = @_;
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    open my $out, '>', $path or die "cannot create test fixture $relative: $!";
    print {$out} $content or die "cannot write fixture $relative: $!";
    close $out or die "cannot close fixture $relative: $!";
}
put('LICENSE', "MIT License\nCopyright (c) 2026 Demo\nPermission is hereby granted\nTHE SOFTWARE IS PROVIDED\n");
put('CONTRIBUTING.md', "By contributing, you agree that your contribution is distributed under the repository's existing MIT License.\n");
# The second identifier-looking text is ordinary Perl source, not a license.
# It must not be interpreted as another SPDX declaration by the auditor.
put('bin/example', "#!/usr/bin/env perl\n# SPDX-License-Identifier: MIT\nmy \$example = 'SPDX-License-Identifier: Apache-2.0';\nprint qq(ok\\n);\n");
put('tools/installation.pl', "for my \$section ('bin', 'sbin', 'lib/SASD/Freeware') { }\n# SPDX-License-Identifier: MIT\n");

my $pid = open(my $pipe, '-|', $^X, $script, '--root', $root);
ok(defined $pid, 'can start read-only auditor');
my $output = defined($pid) ? do { local $/; <$pipe> } : '';
my $closed = defined($pid) ? close($pipe) : 0;
ok($closed, 'audit exits zero even with manual-review findings');
like($output, qr/^status\tcategory\titem\tdetail$/m, 'TSV header');
like($output, qr/^PASS\tlicense\tLICENSE\t/m, 'recognizes MIT license');
like($output, qr/^REVIEW\tdistribution\tLICENSE\t/m, 'reports missing installer license payload');
like($output, qr/^REVIEW\tcontributions\tCONTRIBUTING\.md\t/m, 'does not invent relicensing authority');
like($output, qr/^PASS\tspdx\tsource-and-tests\t2 files /m, 'verifies both fixture source identifiers');
unlike($output, qr/^REVIEW\tspdx\tbin\/example\t/m,
       'string literal with license-looking text is not a second SPDX header');
like($output, qr/^SUMMARY\tPASS=\d+\tREVIEW=\d+\tINFO=\d+$/m, 'explicit non-approval summary');

put('bin/other', "#!/usr/bin/env perl\n# no license notice here\n");
$pid = open($pipe, '-|', $^X, $script, '--root', $root);
$output = defined($pid) ? do { local $/; <$pipe> } : '';
$closed = defined($pid) ? close($pipe) : 0;
ok($closed, 'audit still completes with missing SPDX');
like($output, qr/^REVIEW\tspdx\tbin\/other\tSPDX license identifier missing$/m,
     'missing SPDX is reported, not silently accepted');
unlike($output, qr/^PASS\tspdx\tsource-and-tests\t/m,
       'aggregate SPDX pass absent if one source identifier is missing');

# A later installer source that explicitly references LICENSE is an INFO
# requiring runtime tests, not a false positive old-bug REVIEW or legal PASS.
put('tools/installation.pl', "for my \$section ('bin', 'sbin', 'lib/SASD/Freeware') { }\n# SPDX-License-Identifier: MIT\nmy \$license = \$src . '/LICENSE';\n\$wanted{'LICENSE'} = \$license;\n");
$pid = open($pipe, '-|', $^X, $script, '--root', $root);
$output = defined($pid) ? do { local $/; <$pipe> } : '';
$closed = defined($pid) ? close($pipe) : 0;
ok($closed, 'auditor completes when installer has license handling');
like($output, qr/^INFO\tdistribution\tLICENSE\tcandidate root LICENSE handling detected/m,
     'new installer avoids historical missing-license finding');
unlike($output, qr/^REVIEW\tdistribution\tLICENSE\t/m,
       'fixed installer is not mislabeled with historical omission');

# Conversely, two actual SPDX source comments must still trigger review.
put('bin/mixed', "#!/usr/bin/env perl\n# SPDX-License-Identifier: MIT\n# SPDX-License-Identifier: Apache-2.0\n");
$pid = open($pipe, '-|', $^X, $script, '--root', $root);
$output = defined($pid) ? do { local $/; <$pipe> } : '';
$closed = defined($pid) ? close($pipe) : 0;
ok($closed, 'multiple-license review audit completes');
like($output, qr/^REVIEW\tspdx\tbin\/mixed\t/m,
     'two real SPDX comment declarations trigger review');

done_testing();
