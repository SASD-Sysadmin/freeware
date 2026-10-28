#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M8.5.3a: pure offline evidence audit, including hostile/malformed inputs.
# Never runs a container engine or changes the host's configuration.
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use lib "$FindBin::Bin/../lib";
use SASD::Freeware::LinuxContainerAcceptance qw(stages);
use SASD::Freeware::LinuxContainerEvidence qw(
    parse_batch summarize_batches summary_tsv summary_jsonl
);

my @stages = stages();
my @targets = qw(debian ubuntu arch almalinux rocky);
my $json = JSON::PP->new->canonical->ascii;
my $cli = "$FindBin::Bin/../bin/linux-container-evidence-audit";

sub document {
    my ($target, $mode, $statuses, $reasons) = @_;
    my @lines;
    for my $i (0..$#stages) {
        push @lines, $json->encode({
            schema => 'sasd.container-acceptance.v1',
            target => $target, stage => $stages[$i], mode => $mode,
            status => $statuses->[$i], reason => $reasons->[$i],
        });
    }
    return join("\n", @lines) . "\n";
}
sub passing {
    my ($target) = @_;
    return document($target, 'CONTAINER', [ ('PASS') x 5 ],
        [ 'ID_MATCH', ('CHECK_OK') x 4 ]);
}
sub planned {
    my ($target) = @_;
    return document($target, 'PLAN', [ ('SKIP') x 5 ],
        [ ('NOT_EXECUTED') x 5 ]);
}
sub rejected {
    my ($payload, $comment) = @_;
    ok(!eval { parse_batch($payload); 1 }, $comment);
}
my $pass = parse_batch(passing('debian'));
is($pass->{target}, 'debian', 'exact target is preserved');
is($pass->{mode}, 'CONTAINER', 'container evidence mode is preserved');
is(scalar(keys %{$pass->{rows}}), 5, 'all five stages are parsed');
is($pass->{rows}{IDENTITY}{reason}, 'ID_MATCH', 'positive ID evidence retained');
my $plan = parse_batch(planned('ubuntu'));
is($plan->{mode}, 'PLAN', 'default plan remains PLAN');
my @rows = summarize_batches($pass, $plan);
is(scalar(@rows), 5, 'all five target summaries are emitted');
is_deeply([map { $_->{target} } @rows], \@targets, 'stable distribution order');
is($rows[0]{status}, 'PASS', 'all five container stages pass');
is($rows[0]{pass}, 5, 'five positive stages counted');
is($rows[0]{reason}, 'ALL_STAGES_PASS', 'explicit success reason');
is($rows[1]{status}, 'SKIP', 'PLAN is not counted as passed');
is($rows[1]{skip}, 5, 'five unexecuted plan stages counted');
is($rows[2]{status}, 'SKIP', 'unreported target is skipped');
is($rows[2]{reason}, 'NO_REPORT', 'unreported target remains visible');
like(summary_tsv(@rows), qr/\ATARGET\tMODE\tSTATUS\tPASS\tFAIL\tSKIP\tREASON\n/,
    'TSV summary has stable columns');
my @jsonrows = split /\n/, summary_jsonl(@rows);
is(scalar(@jsonrows), 5, 'JSONL emits five entries');
is(JSON::PP::decode_json($jsonrows[0])->{schema},
   'sasd.container-evidence.v1', 'new summary schema is versioned');
is(JSON::PP::decode_json($jsonrows[2])->{reason}, 'NO_REPORT',
    'JSONL preserves absent target');
ok(!eval { summarize_batches($pass, $pass); 1 }, 'duplicate target batches rejected');

my $bad_identity = document('debian', 'CONTAINER',
    [qw(FAIL SKIP SKIP SKIP SKIP)],
    ['ID_MISMATCH', ('PRIOR_STAGE_FAILED') x 4]);
my @failed = summarize_batches(parse_batch($bad_identity));
is($failed[0]{status}, 'FAIL', 'identity mismatch causes target failure');
is($failed[0]{fail}, 1, 'failed stage is counted');
is($failed[0]{skip}, 4, 'blocked stages remain skipped');

my $missing_tools = document('arch', 'CONTAINER',
    [qw(PASS SKIP SKIP SKIP SKIP)],
    ['ID_MATCH','MISSING_DEPENDENCY', ('PRIOR_STAGE_FAILED') x 3]);
my @skipped = summarize_batches(parse_batch($missing_tools));
is($skipped[2]{status}, 'SKIP', 'missing toolchain is not a pass');
is($skipped[2]{pass}, 1, 'only confirmed identity counts as pass');
is($skipped[2]{skip}, 4, 'remaining stages are skipped');

for my $reason (qw(NOT_CONFIGURED IMAGE_UNAVAILABLE)) {
    my $doc = document('rocky', 'CONTAINER', [ ('SKIP') x 5 ],
        [ ($reason) x 5 ]);
    my @summary = summarize_batches(parse_batch($doc));
    is($summary[4]{status}, 'SKIP', "$reason is skipped");
}
my $no_engine = document('rocky', 'CONTAINER',
    [ ('FAIL') x 5 ], [ ('ENGINE_UNAVAILABLE') x 5 ]);
my @engine_rows = summarize_batches(parse_batch($no_engine));
is($engine_rows[4]{status}, 'FAIL', 'missing runtime marks failure');
is($engine_rows[4]{fail}, 5, 'all five runtime preflight failures retained');

rejected('', 'empty document rejected');
rejected("{}\n", 'one record rejected');
my @noncanonical = split /\n/, passing('debian');
$noncanonical[0] =~ s/\{/{ /;
rejected(join("\n", @noncanonical) . "\n", 'noncanonical JSON rejected');
my @duplicate_json_keys = split /\n/, passing('debian');
$duplicate_json_keys[0] =~ s/\}$/,"status":"PASS"}/;
rejected(join("\n", @duplicate_json_keys) . "\n", 'duplicate JSON keys rejected');
rejected(passing('debian') . "\n", 'extra blank row rejected');
rejected(substr(passing('debian'),0,-1), 'missing final LF rejected');
rejected(passing('debian') . "{}\n", 'sixth record rejected');
rejected(('x' x (32 * 1024 + 1)) . "\n", 'oversized batch rejected');
rejected("\x1b" . passing('debian'), 'ANSI ESC rejected');
rejected("\x00" . passing('debian'), 'embedded NUL rejected');

my @valid_lines = split /\n/, passing('debian');
my @duplicate = @valid_lines;
$duplicate[4] = $duplicate[0];
rejected(join("\n", @duplicate) . "\n", 'duplicate identity stage rejected');
my @mixed = @valid_lines;
$mixed[1] =~ s/"target":"debian"/"target":"ubuntu"/;
rejected(join("\n", @mixed) . "\n", 'mixed targets rejected');
@mixed = @valid_lines;
$mixed[1] =~ s/"mode":"CONTAINER"/"mode":"PLAN"/;
rejected(join("\n", @mixed) . "\n", 'mixed plan and container evidence rejected');
@mixed = @valid_lines;
$mixed[2] =~ s/"status":"PASS"/"status":"SKIP"/;
rejected(join("\n", @mixed) . "\n", 'unjustified SKIP reason rejected');
@mixed = @valid_lines;
$mixed[2] =~ s/"stage":"TEST"/"stage":"UNKNOWN"/;
rejected(join("\n", @mixed) . "\n", 'unknown stage rejected');
@mixed = @valid_lines;
$mixed[0] =~ s/"schema":"sasd.container-acceptance.v1"/"schema":"other"/;
rejected(join("\n", @mixed) . "\n", 'foreign schema rejected');
@mixed = @valid_lines;
$mixed[0] =~ s/\}$/,"extra":"injected"}/;
rejected(join("\n", @mixed) . "\n", 'extra evidence field rejected');
@mixed = @valid_lines;
$mixed[0] =~ s/"reason":"ID_MATCH"/"reason":"ID_MISMATCH"/;
rejected(join("\n", @mixed) . "\n", 'pass with mismatched reason rejected');
rejected(document('debian', 'PLAN', [ ('SKIP') x 5 ],
    ['NOT_EXECUTED','NOT_CONFIGURED', ('NOT_EXECUTED') x 3]),
    'plan stage cannot claim image preflight result');
rejected(document('debian', 'CONTAINER',
    [qw(FAIL PASS PASS PASS PASS)],
    ['ID_MISMATCH', ('CHECK_OK') x 4]),
    'checks cannot pass after identity failure');
rejected(document('debian', 'CONTAINER',
    [qw(PASS FAIL PASS PASS PASS)],
    ['ID_MATCH','CHECK_FAILED', ('CHECK_OK') x 3]),
    'checks cannot pass after toolchain failure');
rejected(document('debian', 'CONTAINER',
    [qw(SKIP PASS PASS PASS PASS)],
    ['NOT_CONFIGURED', ('CHECK_OK') x 4]),
    'mixed preflight outcomes rejected');

# Exercise the published CLI via argv only (never via a shell).
sub run_cli {
    my (@args) = @_;
    my $pid = open(my $pipe, '-|');
    defined($pid) or die "fork failed: $!";
    if (!$pid) {
        open STDERR, '>', '/dev/null';
        exec { $^X } $^X, $cli, @args;
        exit 127;
    }
    local $/;
    my $output = <$pipe> // '';
    close $pipe;
    return ($? >> 8, $output);
}
my ($exit, $output) = run_cli();
is($exit, 0, 'default empty report is informational');
like($output, qr/debian\tNONE\tSKIP\t0\t0\t5\tNO_REPORT/,
    'default output explicitly marks no report');
($exit, $output) = run_cli('--require-complete');
is($exit, 4, 'complete mode refuses absent reports');
my $dir = tempdir(CLEANUP => 1);
sub write_report {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($dir, $filename);
    open my $fh, '>', $path or die "fixture write failed: $!";
    print {$fh} $content;
    close $fh or die "fixture close failed: $!";
    return $path;
}
my @files;
for my $target (@targets) {
    push @files, write_report("$target.jsonl", passing($target));
}
my @args = map { ('--input', $_) } @files;
($exit, $output) = run_cli(@args, '--require-complete');
is($exit, 0, 'five complete actual container reports satisfy requirement');
my @result_lines = split /\n/, $output;
is(scalar @result_lines, 6, 'five report rows plus header');
like($output, qr/rocky\tCONTAINER\tPASS\t5\t0\t0\tALL_STAGES_PASS/,
    'last distro is verified');
($exit, $output) = run_cli(@args, '--format', 'jsonl');
is($exit, 0, 'JSONL CLI output works');
is(JSON::PP::decode_json((split /\n/, $output)[0])->{status}, 'PASS',
    'JSONL CLI carries validated positive result');
($exit, $output) = run_cli('--input', $files[0], '--require-complete');
is($exit, 4, 'partial target coverage fails require-complete');
($exit, $output) = run_cli('--input', $files[0], '--input', $files[0]);
ok($exit != 0, 'CLI duplicate target fails closed');
my $bad_file = write_report('bad.jsonl', 'NOT JSON' . "\n");
($exit, $output) = run_cli('--input', $bad_file);
ok($exit != 0, 'malformed report fails closed');
my $link = File::Spec->catfile($dir, 'symlink.jsonl');
if (symlink($files[0], $link)) {
    ($exit, $output) = run_cli('--input', $link);
    ok($exit != 0, 'CLI rejects symlink input');
} else {
    pass('symlink fixture unavailable');
}
($exit, $output) = run_cli('--help');
is($exit, 0, 'help succeeds');
like($output, qr/\AUsage:/, 'help provides usage');
($exit, $output) = run_cli('--version');
is($exit, 0, 'version succeeds');
like($output, qr/\Alinux-container-evidence-audit 0\.1\.0\n\z/,
    'version follows repository contract');
done_testing();
