#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M9.2: check the seven formerly missing standalone command guides.
#
# These are source-documentation contract tests, not a claim of release
# readiness. In particular, they NEVER invoke the inspected commands or
# attempt privileged filesystem, network or SSH operations. Existing tests
# exercise command behavior on disposable fixtures; this test ensures that
# operators can locate the behavioral and safety documentation.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;

my $root = File::Spec->rel2abs("$FindBin::Bin/..");
my @names = qw(account-audit file-integrity hosts-lint log-summary
               ssh-key-audit suid-audit tcp-check);

sub read_text {
    my ($relative) = @_;
    my $file = File::Spec->catfile($root, split m{/}, $relative);
    open my $fh, '<:raw', $file or die "cannot open $relative: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $relative: $!";
    return $text;
}

my $readme_en = read_text('README.md');
my $readme_de = read_text('README.de.md');

for my $name (@names) {
    my $command = "bin/$name";
    my $manpage = "man/man1/$name.1";
    ok(-f File::Spec->catfile($root, split m{/}, $command), "$name source exists");
    ok(-f File::Spec->catfile($root, split m{/}, $manpage), "$name manpage exists");

    for my $language ('en', 'de') {
        my $suffix = $language eq 'de' ? '.de.md' : '.md';
        my $opposite = $language eq 'de' ? '.md' : '.de.md';
        my $relative = "docs/commands/$name$suffix";
        my $file = File::Spec->catfile($root, split m{/}, $relative);
        ok(-f $file && !-l $file, "$name $language standalone guide is regular");
        next if !-f $file;
        my $doc = read_text($relative);
        like($doc, qr/\A\# `\Q$name\E` /, "$name $language command-specific title");
        like($doc, qr/\(\Q$name$opposite\E\)/, "$name $language cross-language link");
        like($doc, qr{\Q../../bin/$name\E}, "$name $language source link");
        like($doc, qr{\Q../../man/man1/$name.1\E}, "$name $language manpage link");
        like($doc, qr/```sh\n/s, "$name $language reproducible shell example");
        like($doc, qr/`--help`/s, "$name $language metadata options documented");
        like($doc, qr/`--version`/s, "$name $language version documented");
        like($doc, qr/(?:exit|rückgabewert|exitcode)/i,
            "$name $language has exit-status discussion");
        like($doc, qr/(?:limit|safety|grenz|sicherheit)/i,
            "$name $language has limits and safety discussion");
        ok(length($doc) >= 2000, "$name $language is substantial rather than a stub");
        unlike($doc, qr/\r|[ \t]+\n/s, "$name $language uses clean LF formatting");
    }
    like($readme_en, qr{\Qdocs/commands/$name.md\E}, "$name indexed in English README");
    like($readme_de, qr{\Qdocs/commands/$name.de.md\E}, "$name indexed in German README");
}

# Check important behavioral distinctions, which are easy to accidentally
# misdocument as a generic “0 clean, 1 findings” contract. Each language
# must explain them before the documentation gap can be closed.
for my $language ('en', 'de') {
    my $suffix = $language eq 'de' ? '.de.md' : '.md';
    my $doc = sub { read_text("docs/commands/$_[0]$suffix") };
    like($doc->('account-audit'), qr/warn/i, "account-audit $language warnings documented");
    like($doc->('hosts-lint'), qr/warn/i, "hosts-lint $language warnings documented");
    like($doc->('file-integrity'), qr/`--init`/i, "file-integrity $language write operation explicit");
    like($doc->('file-integrity'), qr/(?:hardlink|hard.link)/i,
         "file-integrity $language publication precondition");
    like($doc->('suid-audit'), qr/(?:privileged=|treffer)/i,
         "suid-audit $language reports inventory, not release clearance");
    like($doc->('tcp-check'), qr/`--nagios`/i,
         "tcp-check $language has alternate exit convention");
    like($doc->('ssh-key-audit'), qr/(?:heuristic|heuristisch)/i,
         "ssh-key-audit $language does not claim full cryptographic verification");
}

done_testing();
