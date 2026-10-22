#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M7.5: Offline-only contract and adversarial regression suite.
# This suite does not query system logs, authenticate, change accounts, or
# require elevated privileges; all inputs are synthetic aggregate reports.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use JSON::PP;
use IPC::Open3 qw(open3);
use Symbol qw(gensym);

my $bin = File::Spec->catfile($FindBin::Bin, '..', 'bin',
                              'log-summary-normalize');
my $dir = tempdir(CLEANUP => 1);
my @sev = qw(EMERGENCY ALERT CRITICAL ERROR WARNING NOTICE INFO DEBUG UNKNOWN);
my @ssh = qw(ACCEPTED FAILED INVALID_USER OTHER_SSHD OTHER_SERVICE UNKNOWN);
my @auth = qw(SUDO_COMMAND SUDO_DENIED SU_SUCCESS SU_FAILED
              PAM_AUTH_FAILURE PAM_SESSION_OPEN PAM_SESSION_CLOSE
              OTHER_AUTH OTHER_SERVICE UNKNOWN);
my %kinds = (
    'journal-summary' => \@sev, 'syslog-summary' => \@sev,
    'ssh-auth-summary' => \@ssh, 'auth-event-summary' => \@auth,
);
my $json = JSON::PP->new->utf8;
my $iteration = 0;

sub fixture {
    my ($source, $format, $counts) = @_;
    my $names = $kinds{$source};
    my $severity = $source =~ /\A(?:journal|syslog)-summary\z/;
    my $sum = 0; $sum += $_ for @$counts;
    my @rows;
    for my $i (0 .. $#$names) {
        my @cols = $severity ? ($i < 8 ? $i : '-', $names->[$i], $counts->[$i])
                             : ($names->[$i], $counts->[$i]);
        push @rows, \@cols;
    }
    push @rows, $severity ? ['-', 'TOTAL', $sum] : ['TOTAL', $sum];
    return $format eq 'null' ?
           join('', map { join("\0", @$_) . "\0" } @rows) :
           ($severity ? "PRIORITY\tLEVEL\tCOUNT\n" : "EVENT\tCOUNT\n") .
           join('', map { join("\t", @$_) . "\n" } @rows);
}

sub invoke {
    my ($content, @args) = @_;
    ++$iteration;
    my $in = "$dir/input-$iteration";
    open my $fh, '>:raw', $in or die $!;
    print {$fh} $content;
    close $fh or die $!;
    my $stderr = gensym();
    # The three argument-list command has no shell. Separate pipes prevent
    # JSONL from contaminating Test::More's TAP stream.
    my $pid = open3(my $writer, my $reader, $stderr,
                    $^X, $bin, '--input', $in, @args);
    close $writer;
    binmode($reader);
    binmode($stderr);
    my $stdout = do { local $/; <$reader> };
    $stdout = '' unless defined $stdout;
    my $errtext = do { local $/; <$stderr> };
    $errtext = '' unless defined $errtext;
    close $reader;
    close $stderr;
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $errtext);
}

sub records {
    my ($stdout) = @_;
    return [map { $json->decode($_) } grep { length } split /\n/, $stdout];
}

for my $source (sort keys %kinds) {
    my @counts = map { 0 } @{ $kinds{$source} };
    $counts[0] = 2;
    $counts[1] = 3;
    for my $format (qw(tsv null)) {
        my $input = fixture($source, $format, \@counts);
        my @fargs = ('--source', $source,
                     '--format', $format);
        my ($code, $stdout, $stderr) = invoke($input, @fargs);
        is($code, 0, "$source $format valid zero-unknown exit 0");
        is($stderr, '', "$source $format no diagnostic");
        my $rows = records($stdout);
        is(scalar(@$rows), scalar(@counts)+1,
           "$source $format emits exact category and total rows");
        is($rows->[0]{source}, $source, "$source $format source fidelity");
        is($rows->[0]{scope}, 'source_summary',
           "$source $format aggregate scope is explicit");
        is($rows->[0]{schema}, 'sasd.log-summary.v1',
           "$source $format versioned schema");
        is($rows->[0]{count}, 2, "$source $format numeric category count");
        ok(!ref($rows->[0]{count}), "$source $format JSON scalar count");
        is($rows->[-1]{type}, 'total', "$source $format total is typed");
        is($rows->[-1]{count}, 5, "$source $format total reconciled");
        is($rows->[-1]{priority}, undef,
           "$source $format total has no priority");
        is($rows->[0]{priority}, $source =~ /\A(?:journal|syslog)/ ? 0 : undef,
           "$source $format severity is not fabricated for auth");
        my $again = fixture($source, $format, \@counts);
        my ($rc2, $out2) = invoke($again, @fargs);
        is($out2, $stdout, "$source $format deterministic canonical JSONL");
    }
    $counts[-1] = 1;
    my ($code, $stdout, $err) = invoke(fixture($source, 'tsv', \@counts),
                                      '--source', $source);
    is($code, 1, "$source unknown category causes finding exit 1");
    is(records($stdout)->[-1]{count}, 6, "$source unknown counted in total");
    is($err, '', "$source unknown is not a processing error");
}

# A valid report with an explicit zero total must still be emitted in full.
for my $source (sort keys %kinds) {
    my @counts = (0) x scalar(@{ $kinds{$source} });
    my ($code, $stdout) = invoke(fixture($source, 'tsv', \@counts),
                                  '--source', $source);
    is($code, 0, "$source all-zero report accepted");
    is(records($stdout)->[-1]{count}, 0, "$source all-zero total is numeric");
}

my @normal = (2,3,(0)x7);
my $good = fixture('journal-summary', 'tsv', \@normal);
my @negative = (
 ['empty', ''],
 ['missing-final-LF', substr($good, 0, -1)],
 ['malformed-header', do { my $s=$good; $s =~ s/PRIORITY/SEVERITY/; $s }],
 ['missing-category', do { my $s=$good; $s =~ s/^7\tDEBUG\t0\n//m; $s }],
 ['duplicate-category', do { my $s=$good; $s =~ s/^1\tALERT/0\tEMERGENCY/m; $s }],
 ['swapped-order', do { my $s=$good; $s =~ s/^0\tEMERGENCY/0\tALERT/m; $s }],
 ['wrong-priority', do { my $s=$good; $s =~ s/^3\tERROR/4\tERROR/m; $s }],
 ['wrong-total', do { my $s=$good; $s =~ s/-\tTOTAL\t5/-\tTOTAL\t4/; $s }],
 ['negative-count', do { my $s=$good; $s =~ s/0\tEMERGENCY\t2/0\tEMERGENCY\t-2/; $s }],
 ['leading-zero', do { my $s=$good; $s =~ s/0\tEMERGENCY\t2/0\tEMERGENCY\t02/; $s }],
 ['plus-count', do { my $s=$good; $s =~ s/0\tEMERGENCY\t2/0\tEMERGENCY\t+2/; $s }],
 ['scientific-count', do { my $s=$good; $s =~ s/0\tEMERGENCY\t2/0\tEMERGENCY\t2e0/; $s }],
 ['integer-overflow', do { my $s=$good; $s =~ s/0\tEMERGENCY\t2/0\tEMERGENCY\t99999999999/; $s }],
 ['record-overflow', do { my $s=$good; $s =~ s/0\tEMERGENCY\t2/0\tEMERGENCY\t50001/; $s }],
 ['embedded-NUL', do { my $s=$good; $s =~ s/0\tEMERGENCY/0\0EMERGENCY/; $s }],
 ['escape-sequence', do { my $s=$good; $s =~ s/0\tEMERGENCY/0\t\e[31mEMERGENCY/; $s }],
 ['bare-CR', do { my $s=$good; $s =~ s/0\tEMERGENCY/0\r\tEMERGENCY/; $s }],
 ['extra-column', do { my $s=$good; $s =~ s/0\tEMERGENCY\t2/0\tEMERGENCY\t2\tsecret/; $s }],
 ['injected-row', $good . "other\tsecrets\t7\n"],
 ['oversized-bytes', $good . ('x' x 9000)],
);
for my $case (@negative) {
    my ($code, $out, $err) = invoke($case->[1], '--source', 'journal-summary');
    is($code, 3, "$case->[0] rejected with input-error status");
    is($out, '', "$case->[0] fails without partial stdout");
    like($err, qr/\Alog-summary-normalize: /,
         "$case->[0] emits controlled diagnostic");
    unlike($err, qr/secret|99999999999|\e\[31m/,
           "$case->[0] does not leak input data");
}

my $null = fixture('ssh-auth-summary', 'null', [2,3,0,0,0,0]);
my @bad_null = (
 ['missing-final-NUL', substr($null, 0, -1)],
 ['extra-field', $null . "secret\0"],
 ['not-a-NUL-report', fixture('ssh-auth-summary', 'tsv', [2,3,0,0,0,0])],
 ['illegal-control', do { my $s=$null; $s =~ s/ACCEPTED/ACCEPT\nED/; $s }],
 ['noncanonical-count', do { my $s=$null; $s =~ s/ACCEPTED\x002\x00/ACCEPTED\x0002\x00/; $s }],
);
for my $case (@bad_null) {
    my ($code, $out) = invoke($case->[1], '--source', 'ssh-auth-summary',
                             '--format', 'null');
    is($code, 3, "$case->[0] rejected");
    is($out, '', "$case->[0] no partial stdout");
}

my ($incorrect, $unexpected) = invoke($good, '--source', 'ssh-auth-summary');
is($incorrect, 3, 'cross-source schema mismatch rejected');
is($unexpected, '', 'schema mismatch emits no stdout');
my ($badformat, $noout) = invoke($good, '--source', 'journal-summary',
                                '--format', 'null');
is($badformat, 3, 'incorrect format rejected');
is($noout, '', 'incorrect format no stdout');
my ($badsource, $badout) = invoke($good, '--source', 'unknown-source');
is($badsource, 2, 'unknown source rejected');
is($badout, '', 'unknown source no stdout');
my ($badarg) = invoke($good, '--source', 'journal-summary', '--unknown');
is($badarg, 2, 'unknown option rejected');
my ($badcase) = invoke($good, '--source', 'journal-summary', '--FORMAT', 'tsv');
is($badcase, 2, 'case-sensitive option required');


# CLI and stdin contract. The converter must work without creating a named
# input and must not require a source for --help or --version.
sub invoke_stdin {
    my ($input, @args) = @_;
    my $error = gensym();
    my $pid = open3(my $writer, my $reader, $error, $^X, $bin, @args);
    binmode($writer);
    print {$writer} $input;
    close $writer;
    my $out = do { local $/; <$reader> };
    my $err = do { local $/; <$error> };
    close $reader; close $error;
    waitpid($pid, 0);
    return ($? >> 8, defined($out) ? $out : '',
                     defined($err) ? $err : '');
}
my ($stdin_code, $stdin_out, $stdin_err) = invoke_stdin(
    $good, '--source', 'journal-summary');
is($stdin_code, 0, 'stdin default is accepted');
is(records($stdin_out)->[-1]{count}, 5, 'stdin output matches file input');
is($stdin_err, '', 'stdin success has no diagnostics');
my ($explicit_code, $explicit_out) = invoke_stdin(
    $good, '--source', 'journal-summary', '--input', '-');
is($explicit_code, 0, 'explicit --input - works');
is($explicit_out, $stdin_out, 'stdin and explicit dash are equivalent');
my ($help_code, $help_out) = invoke_stdin('', '--help');
is($help_code, 0, 'help returns 0');
like($help_out, qr/--source NAME/, 'help documents required source');
my ($version_code, $version_out) = invoke_stdin('', '--version');
is($version_code, 0, 'version returns 0');
is($version_out, "log-summary-normalize 0.1.0\n", 'version format stable');
my ($missing_code, $missing_out) = invoke_stdin($good);
is($missing_code, 2, 'missing --source is an option error');
is($missing_out, '', 'missing source does not leak report');

# A link must not allow access to a hidden target. The path must not be
# echoed in either stdout or stderr. A real log path might be sensitive.
my $actual = "$dir/sensitive-target";
open my $src, '>:raw', $actual or die $!;
print {$src} $good;
close $src;
my $link = "$dir/sensitive-link";
if (symlink($actual, $link)) {
    my $error = gensym();
    my $pid = open3(my $writer, my $reader, $error, $^X, $bin,
                    '--input', $link, '--source', 'journal-summary');
    close $writer;
    my $response = do { local $/; <$reader> };
    $response = '' unless defined $response;
    my $message = do { local $/; <$error> };
    $message = '' unless defined $message;
    close $reader; close $error;
    waitpid($pid, 0);
    my $status = $? >> 8;
    is($status, 3, 'symlink is rejected');
    unlike($message, qr/sensitive-(?:link|target)/,
           'symlink diagnostic hides path');
} else {
    fail('platform supports symlink fixture');
    fail('symlink fixture diagnostic');
}


# Real compatibility smoke tests: feed synthetic RAW log snapshots into the
# actual M7.2-M7.4 parsers, then normalize their reports. This is deliberately
# separate from the many contract tests above. It catches interface drift
# without reading any host logs or relying on a network service.
my @flows = (
    ['syslog-summary',
      "<13>Oct 22 08:12:10 host sudo: robin : TTY=pts/0 ; PWD=/ ; USER=root ; COMMAND=/bin/true\n",
      'NOTICE'],
    ['ssh-auth-summary',
      "Oct 22 08:12:10 host sshd[123]: Failed password for invalid user guest from 192.0.2.10 port 22 ssh2\n",
      'FAILED'],
    ['auth-event-summary',
      "Oct 22 08:12:10 host sudo: robin : TTY=pts/0 ; PWD=/ ; USER=root ; COMMAND=/bin/true\n",
      'SUDO_COMMAND'],
    ['journal-summary', "{\"PRIORITY\":\"3\",\"MESSAGE\":\"secret robin\"}\n", 'ERROR'],
);
for my $flow (@flows) {
    my ($source, $input, $category) = @$flow;
    my $original = File::Spec->catfile($FindBin::Bin, '..', 'bin', $source);
    if (!-f $original) {
        # In a full repository checkout, all four programs exist. This guard
        # is useful only for developing this standalone package in isolation.
        diag("isolated bundle: $source upstream parser not present");
        next;
    }
    ++$iteration;
    my $path = "$dir/raw-$iteration";
    open my $fh, '>:raw', $path or die $!;
    print {$fh} $input;
    close $fh;
    for my $format (qw(tsv null)) {
        my $error = gensym();
        my @arguments = ('--input', $path);
        push @arguments, '--null' if $format eq 'null';
        my $pid = open3(my $writer, my $reader, $error,
                        $^X, $original, @arguments);
        close $writer;
        binmode($reader);
        my $report = do { local $/; <$reader> };
        $report = '' unless defined $report;
        my $diagnostics = do { local $/; <$error> };
        $diagnostics = '' unless defined $diagnostics;
        close $reader; close $error;
        waitpid($pid, 0);
        is($? >> 8, 0, "$source $format upstream fixture accepted");
        is($diagnostics, '', "$source $format upstream parser quiet");
        my ($code, $output) = invoke($report,
                                      '--source', $source,
                                      '--format', $format);
        is($code, 0, "$source $format full parser-normalizer workflow");
        my $lines = records($output);
        my @target = grep { $_->{category} eq $category } @$lines;
        is(scalar(@target), 1, "$source $format expected category present");
        is($target[0]{count}, 1, "$source $format source count preserved");
        is($lines->[-1]{count}, 1, "$source $format total preserved");
        unlike($output, qr/robin|192\.0\.2\.10|secret|\/bin\/true/,
               "$source $format JSONL excludes sensitive raw fields");
    }
}

done_testing();
