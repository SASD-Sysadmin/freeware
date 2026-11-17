#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# FR2-03: deterministic, nonprivileged uninstall transaction regressions.
# All mutations are confined to disposable temporary fixtures. The production
# installer does not expose fault-injection flags or environment variables.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Digest::SHA qw(sha256_hex);
use FindBin;
use lib "$FindBin::Bin/../tools/lib";
use SASD::Freeware::UninstallTransaction qw(uninstall_transaction);

my $tmp = tempdir('sasd-fr2-03-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $serial = 0;

sub write_file {
    my ($path, $data) = @_;
    open my $out, '>', $path or die "open $path: $!";
    binmode $out;
    print {$out} $data or die "write $path: $!";
    close $out or die "close $path: $!";
}
sub read_file {
    my ($path) = @_;
    open my $in, '<', $path or die "read $path: $!";
    binmode $in;
    local $/;
    my $data = <$in>;
    close $in or die "close $path: $!";
    return $data;
}
sub remaining_transactions {
    my ($root) = @_;
    opendir my $dh, $root or die "opendir $root: $!";
    my @txns = grep { /\A\.sasd-freeware-txn-/ } readdir $dh;
    closedir $dh;
    return @txns;
}
sub fixture {
    ++$serial;
    my $root = "$tmp/prefix-$serial";
    make_path("$root/bin");
    my $alpha = "original-alpha-$serial\n";
    my $beta = "original-beta-$serial\n";
    write_file("$root/bin/alpha", $alpha);
    write_file("$root/bin/beta", $beta);
    write_file("$root/operator-data", "unowned-$serial\n");
    write_file("$root/.sasd-freeware-install.lock", "stable-lock\n");
    my %previous = ( 'bin/alpha' => sha256_hex($alpha),
                     'bin/beta' => sha256_hex($beta) );
    my $manifest = "$root/.sasd-freeware-install.tsv";
    my $manifest_bytes = "# sasd-freeware-manifest-v1\n" .
      join('', map { "$_\t$previous{$_}\n" } sort keys %previous);
    write_file($manifest, $manifest_bytes);
    return ($root, $manifest, \%previous, $manifest_bytes, $alpha, $beta);
}

{
    my ($root, $manifest, $previous) = fixture();
    is(uninstall_transaction(root => $root, manifest => $manifest, previous => $previous),
       2, 'successful uninstall reports two managed files');
    ok(!-e "$root/bin/alpha" && !-e "$root/bin/beta" && !-e $manifest,
       'successful uninstall removes owned payload and manifest');
    is(read_file("$root/operator-data"), "unowned-$serial\n", 'operator data preserved');
    ok(-f "$root/.sasd-freeware-install.lock", 'persistent lock remains');
    is(scalar(remaining_transactions($root)), 0, 'successful transaction cleaned');
}

{
    my ($root, $manifest, $previous, $saved, $alpha, $beta) = fixture();
    my $moves = 0;
    my $ok = eval { uninstall_transaction(
        root => $root, manifest => $manifest, previous => $previous,
        ops => { protect => sub {
            ++$moves;
            return 0 if $moves == 2; # second move fails after first succeeded
            return rename($_[0], $_[1]);
        } },
    ); 1 };
    ok(!$ok, 'second managed-file move failure reports nonzero');
    like($@, qr/rollback complete/, 'ordinary failure rolls back completely');
    is(read_file("$root/bin/alpha"), $alpha, 'first moved payload restored');
    is(read_file("$root/bin/beta"), $beta, 'second payload still present');
    is(read_file($manifest), $saved, 'manifest unchanged after rollback');
    is(scalar(remaining_transactions($root)), 0, 'successful rollback cleans transaction');
}

{
    my ($root, $manifest, $previous, $saved, $alpha, $beta) = fixture();
    my $ok = eval { uninstall_transaction(
        root => $root, manifest => $manifest, previous => $previous,
        ops => { publish => sub { return 0 } },
    ); 1 };
    ok(!$ok, 'failure to relocate manifest reports nonzero');
    like($@, qr/rollback complete/, 'manifest failure triggers safe rollback');
    is(read_file("$root/bin/alpha"), $alpha, 'alpha restored after manifest failure');
    is(read_file("$root/bin/beta"), $beta, 'beta restored after manifest failure');
    is(read_file($manifest), $saved, 'manifest retained after failed publication');
    is(scalar(remaining_transactions($root)), 0, 'rollback transaction cleaned');
}

{
    my ($root, $manifest, $previous, $saved, $alpha) = fixture();
    my $ok = eval { uninstall_transaction(
        root => $root, manifest => $manifest, previous => $previous,
        ops => { protect => sub {
            my ($src, $dst) = @_;
            rename($src, $dst) or return 0;
            write_file($dst, "concurrent-change\n");
            return 1;
        } },
    ); 1 };
    ok(!$ok, 'tampered backup prevents uninstall');
    like($@, qr/rollback INCOMPLETE/, 'digest failure preserves recovery evidence');
    is(read_file($manifest), $saved, 'active manifest not retired on backup tampering');
    my @txns = remaining_transactions($root);
    is(scalar @txns, 1, 'incomplete rollback retains one transaction');
    ok(-f "$root/$txns[0]/plan.tsv", 'plan survives incomplete rollback');
    ok(-f "$root/$txns[0]/old-1", 'tampered backup survives for independent review');
}

{
    my ($root, $manifest, $previous) = fixture();
    my $ok = eval { uninstall_transaction(
        root => $root, manifest => $manifest, previous => $previous,
        ops => { remove => sub {
            my ($path) = @_;
            return 0 if $path =~ m{/old-2\z};
            return unlink($path);
        } },
    ); 1 };
    ok(!$ok, 'failure of second quarantine deletion is not success');
    like($@, qr/cleanup incomplete/, 'postcommit failure requires manual recovery');
    ok(!-e $manifest, 'active manifest already retired at logical commit');
    ok(!-e "$root/bin/alpha" && !-e "$root/bin/beta",
       'managed files absent from live prefix');
    my @txns = remaining_transactions($root);
    is(scalar @txns, 1, 'postcommit failure retains transaction marker');
    ok(-f "$root/$txns[0]/manifest", 'retired manifest retained as recovery evidence');
    ok(-f "$root/$txns[0]/plan.tsv", 'old-N mapping retained before cleanup completes');
    ok(!-e "$root/$txns[0]/old-1" && -f "$root/$txns[0]/old-2",
       'deleted and surviving backups distinguishable');
    is(read_file("$root/operator-data"), "unowned-$serial\n", 'unowned data preserved');
}

{
    my ($root, $manifest, $previous) = fixture();
    my $ok = eval { uninstall_transaction(
        root => $root, manifest => $manifest, previous => $previous,
        ops => { cleanup => sub { return 0 } },
    ); 1 };
    ok(!$ok, 'simulated cleanup refusal is never treated as success');
    my @txns = remaining_transactions($root);
    is(scalar @txns, 1, 'cleanup refusal retains marker');
    ok(-f "$root/$txns[0]/manifest" && -f "$root/$txns[0]/plan.tsv",
       'cleanup refusal retains manifest and recovery map');
}


{
    my ($root, $manifest, $previous, $saved, $alpha) = fixture();
    my $moves = 0;
    my $ok = eval { uninstall_transaction(
        root => $root, manifest => $manifest, previous => $previous,
        ops => { protect => sub {
            my ($src, $dst) = @_;
            ++$moves;
            return 0 if $moves == 2;
            rename($src, $dst) or return 0;
            # Noncooperating operator created a new object at the vacated path.
            write_file($src, "operator-created-collision\n");
            return 1;
        } },
    ); 1 };
    ok(!$ok, 'occupied restore destination prevents successful rollback');
    like($@, qr/rollback INCOMPLETE/, 'collision fails closed');
    is(read_file("$root/bin/alpha"), "operator-created-collision\n",
       'rollback never overwrites noncooperating operator file');
    is(read_file($manifest), $saved, 'manifest remains original');
    my @txns = remaining_transactions($root);
    is(scalar @txns, 1, 'collision preserves transaction marker');
    is(read_file("$root/$txns[0]/old-1"), $alpha,
       'old managed file survives for independent restoration');
    ok(-f "$root/$txns[0]/plan.tsv", 'old backup mapping is preserved');
}

done_testing();
