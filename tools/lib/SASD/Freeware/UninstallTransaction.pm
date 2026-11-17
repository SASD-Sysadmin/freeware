package SASD::Freeware::UninstallTransaction;
# SPDX-License-Identifier: MIT
#
# Maintainer-only, fail-closed uninstall transaction. The caller MUST already
# hold the stable prefix lock and have verified each manifest-owned file against
# its recorded SHA-256 digest. This module does not expose an operator CLI.
#
# A private transaction and immutable plan are created before the first move.
# The old payload is moved, not deleted, until all moves have succeeded. The
# final manifest rename is the logical commit point. Failures before that
# point use the existing digest-checked rollback engine. Once committed,
# cleanup failure is NOT rolled back: the transaction marker is retained and
# further installer operations must refuse to run pending human inspection.
#
# No fsync/power-loss durability or protection from non-cooperating writers is
# claimed. Test-only callbacks never originate from CLI or environment options.
use strict;
use warnings;
use Exporter qw(import);
use File::Temp qw(tempdir);
use Digest::SHA ();
use SASD::Freeware::InstallPlan qw(write_install_plan);
use SASD::Freeware::InstallRollback qw(rollback_installation);

our @EXPORT_OK = qw(uninstall_transaction);

sub _present {
    my ($path) = @_;
    return -e $path || -l $path;
}

sub _matches_digest {
    my ($path, $expected) = @_;
    return 0 unless -f $path && !-l $path &&
        defined($expected) && $expected =~ /\A[0-9a-f]{64}\z/;
    open my $in, '<', $path or return 0;
    binmode($in);
    my $digest = Digest::SHA->new(256);
    my $ok = eval { $digest->addfile($in); 1 };
    my $closed = close($in);
    return $ok && $closed && $digest->hexdigest eq $expected;
}

sub _cleanup {
    my ($txn, $owned, $previous, $ops) = @_;
    # Delete quarantine backups one at a time. Keep plan.tsv AND the retired
    # manifest until every payload deletion succeeded. Thus an I/O failure
    # cannot discard the mapping for a surviving old-N backup. Never use
    # remove_tree() for the irreversible part of an uninstall.
    my $remove = $ops->{remove} // sub { unlink($_[0]) };
    for my $index (0 .. $#$owned) {
        my $rel = $owned->[$index];
        my $backup = "$txn/old-" . ($index + 1);
        _matches_digest($backup, $previous->{$rel}) or return 0;
        $remove->($backup) or return 0;
        !_present($backup) or return 0;
    }
    # At this point the managed payload is gone; these files contain only
    # evidence for a transaction which has completed its payload deletion.
    -f "$txn/manifest" && !-l "$txn/manifest" or return 0;
    unlink("$txn/manifest") or return 0;
    -f "$txn/plan.tsv" && !-l "$txn/plan.tsv" or return 0;
    unlink("$txn/plan.tsv") or return 0;
    return rmdir($txn) && !_present($txn);
}

sub uninstall_transaction {
    my (%args) = @_;
    my ($root, $manifest, $previous, $ops) =
        @args{qw(root manifest previous ops)};
    $ops //= {};
    defined($root) && $root =~ m{\A/} && $root !~ /[\x00-\x1f\x7f]/ &&
        -d $root && !-l $root &&
        defined($manifest) && $manifest eq "$root/.sasd-freeware-install.tsv" &&
        ref($previous) eq 'HASH' && ref($ops) eq 'HASH' &&
        -f $manifest && !-l $manifest
        or die "installation: invalid uninstall transaction prerequisites\n";

    # The public installer already applies a narrower allowlist. Validate
    # again here so the internal helper cannot accept traversal or control
    # characters even if its caller is refactored later.
    my @owned = sort keys %$previous;
    for my $rel (@owned) {
        $rel =~ m{\A[A-Za-z0-9][A-Za-z0-9_./-]*\z} &&
            $rel !~ m{//|(?:\A|/)\.{1,2}(?:/|\z)} &&
            defined($previous->{$rel}) && $previous->{$rel} =~ /\A[0-9a-f]{64}\z/
            or die "installation: unsafe uninstall manifest entry\n";
    }

    my $txn = tempdir('.sasd-freeware-txn-XXXXXXXX', DIR => $root, CLEANUP => 0);
    my @backups;
    my $protect = $ops->{protect} // sub { rename($_[0], $_[1]) };
    my $publish = $ops->{publish} // sub { rename($_[0], $_[1]) };
    my $reason;
    my $ok = eval {
        write_install_plan(
            transaction => $txn,
            old => [map { [$_, $previous->{$_}] } @owned],
            new => [],
        );
        my $index = 0;
        for my $rel (@owned) {
            ++$index;
            my $live = "$root/$rel";
            my $backup = "$txn/old-$index";
            $protect->($live, $backup)
                or die "cannot protect uninstall file $rel: $!\n";
            push @backups, [$live, $backup, $previous->{$rel}];
            _matches_digest($backup, $previous->{$rel})
                or die "uninstall backup changed or missing: $rel\n";
        }
        # Until this rename succeeds the old manifest remains in place, and
        # any ordinary error can attempt to restore every protected file.
        $publish->($manifest, "$txn/manifest")
            or die "cannot retire uninstall manifest: $!\n";
        # Prevent a misleading success if a faulty callback or filesystem
        # operation claimed success without performing the intended rename.
        !_present($manifest) && -f "$txn/manifest" && !-l "$txn/manifest"
            or die "uninstall manifest publication ambiguous; inspect transaction\n";
        1;
    };
    if (!$ok) {
        $reason = $@ || 'unknown failure';
        # If manifest relocation did complete despite a later ambiguous
        # status, it is unsafe to run the pre-commit rollback automatically.
        if (_present("$txn/manifest") || !_present($manifest)) {
            die "installation: uninstall state ambiguous; transaction preserved at $txn; "
              . "manual recovery required: $reason";
        }
        my $rollback = eval {
            rollback_installation(
                placed => [], backups => \@backups, transaction => $txn,
                (exists($ops->{rollback_ops}) ? (ops => $ops->{rollback_ops}) : ()),
            );
        };
        if (!$rollback) {
            my $unexpected = $@ || 'unknown rollback engine failure';
            die "installation: uninstall failed; rollback error: $unexpected; "
              . "transaction preserved at $txn; initial failure: $reason";
        }
        if (!$rollback->{complete}) {
            warn "installation: uninstall rollback issue: $_\n" for @{$rollback->{errors}};
            die "installation: uninstall failed (rollback INCOMPLETE; "
              . "transaction preserved at $txn; manual recovery required): $reason";
        }
        die "installation: uninstall failed (rollback complete): $reason";
    }

    # The manifest has been retired: cleanup is irreversible. Never claim
    # completion if even part of the transaction still exists.
    my $cleanup = $ops->{cleanup} // \&_cleanup;
    my $cleaned = eval { $cleanup->($txn, \@owned, $previous, $ops) };
    if (!$cleaned || _present($txn)) {
        die "installation: uninstall manifest retired but cleanup incomplete; "
          . "inspect transaction $txn before retrying\n";
    }
    return scalar @owned;
}

1;
