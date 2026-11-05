package SASD::Freeware::InstallRollback;
# SPDX-License-Identifier: MIT
#
# A deliberately small, maintainer-only rollback engine for installation.pl.
# It is NOT installed as a public SASD Freeware library or CLI command.
#
# Contract:
# - Nothing may overwrite a pre-existing destination during recovery.
# - Only files still matching the known SHA-256 value may be removed or restored.
# - A transaction is cleaned up ONLY after every undo step has succeeded.
# - On an incomplete rollback, preserve the entire transaction directory so
#   an operator can inspect the surviving old-N backups and new-N staging files.
#
# The optional operation callbacks exist solely to make low-level failures
# deterministic in the offline tests; installation.pl uses real filesystem
# operations without an environment-variable or CLI fault-injection switch.
use strict;
use warnings;
use Exporter qw(import);
use File::Path qw(remove_tree);
use Digest::SHA ();

our @EXPORT_OK = qw(rollback_installation);

sub _present {
    my ($path) = @_;
    # Unlike -e alone, -l also notices dangling symbolic links. Both matter:
    # rename() would otherwise silently replace another party's object.
    return -e $path || -l $path;
}

sub _matches_digest {
    my ($path, $expected) = @_;
    return 0 unless defined($expected) && $expected =~ /\A[0-9a-f]{64}\z/;
    return 0 unless -f $path && !-l $path;
    open my $in, '<', $path or return 0;
    binmode($in);
    my $hash = Digest::SHA->new(256);
    my $valid = eval { $hash->addfile($in); 1 };
    my $closed = close($in);
    return $valid && $closed && $hash->hexdigest eq $expected;
}

sub _cleanup_transaction {
    my ($txn) = @_;
    # File::Path can report a partial removal through its error list without
    # throwing an exception. Check both the error list and the final path.
    my $errors = [];
    remove_tree($txn, { error => \$errors });
    return !@$errors && !_present($txn);
}

sub rollback_installation {
    my (%args) = @_;
    my $placed  = $args{placed};
    my $backups = $args{backups};
    my $txn     = $args{transaction};
    my $ops     = $args{ops} // {};
    ref($placed) eq 'ARRAY' && ref($backups) eq 'ARRAY' &&
        defined($txn) && length($txn) && ref($ops) eq 'HASH'
        or die "installation: invalid internal rollback arguments\n";

    my $remove = $ops->{remove} // sub { unlink($_[0]) };
    my $restore = $ops->{restore} // sub { rename($_[0], $_[1]) };
    my $cleanup = $ops->{cleanup} // \&_cleanup_transaction;
    my @errors;

    # First remove newly installed content, in the reverse order of placement.
    # Verify its digest before unlinking: concurrent operator modifications
    # must be preserved even though they mean automatic rollback is incomplete.
    for my $entry (reverse @$placed) {
        my ($destination, $digest) = @$entry;
        if (!_matches_digest($destination, $digest)) {
            push @errors, "new file changed or missing: $destination";
            next;
        }
        if (!$remove->($destination) || _present($destination)) {
            push @errors, "cannot remove new file: $destination";
        }
    }

    # Restore only untouched old backups, in reverse order of protection.
    # Never allow rename() to replace a remaining newly installed file, a
    # concurrent operator file, a symlink, or any other occupied destination.
    # This check is fail-closed but not a cross-process transaction lock:
    # the documented requirement to avoid concurrent writers still applies.
    for my $entry (reverse @$backups) {
        my ($destination, $backup, $digest) = @$entry;
        if (!_matches_digest($backup, $digest)) {
            push @errors, "old backup changed or missing: $backup";
            next;
        }
        if (_present($destination)) {
            push @errors, "restore destination occupied: $destination";
            next;
        }
        if (!$restore->($backup, $destination) ||
            _present($backup) || !_matches_digest($destination, $digest)) {
            push @errors, "cannot restore old backup: $backup -> $destination";
        }
    }

    # This is the essential M9.3b fix: incomplete recovery must never call
    # remove_tree() on the transaction, because old-N may be the only surviving
    # copy of an installed file. Leave the marker in place so later install and
    # uninstall operations refuse to run until independent manual recovery.
    if (!@errors && !$cleanup->($txn)) {
        push @errors, "cannot clean completed rollback transaction: $txn";
    }

    return { complete => @errors ? 0 : 1, errors => \@errors,
             transaction => $txn };
}

1;
