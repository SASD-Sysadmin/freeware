package SASD::Freeware::InstallLock;
# SPDX-License-Identifier: MIT
#
# Maintainer-only coordination for tools/installation.pl. This module is NOT
# part of the installed public SASD Freeware Perl library.
#
# An advisory flock on a *stable* file serializes cooperating installers and
# uninstallers targeting the same prefix. The file is deliberately permanent:
# unlinking it after unlocking would allow a second process to lock a different
# inode while a first process still holds the old one (a split-lock race).
#
# This is not a security boundary against an administrator who can replace
# paths in the prefix, Windows programs ignoring WSL locks, or other programs
# which do not participate in this protocol. Regular ownership and directory
# permissions are still required. The installer continues to reject unresolved
# interrupted transactions independently of this live-process lock.
use strict;
use warnings;
use Exporter qw(import);
use Fcntl qw(:DEFAULT :flock O_NOFOLLOW);
use Errno qw(EEXIST EWOULDBLOCK EAGAIN);

our @EXPORT_OK = qw(acquire_install_lock);
my $MAGIC = "sasd-freeware-install-lock-v1\n";

sub acquire_install_lock {
    my ($path) = @_;
    defined($path) && $path =~ m{\A/} && $path !~ /[\x00-\x1f\x7f]/
        or die "installation: invalid internal lock path\n";

    # O_EXCL creates a brand-new inode without following an existing link.
    # O_NOFOLLOW also guards the reopen case against an attacker-supplied
    # symlink. Fail closed if this flag is unavailable on the target platform.
    my $created = sysopen(my $handle, $path,
                          O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW, 0600);
    if (!$created) {
        my $error = 0 + $!;
        $error == EEXIST or die "installation: cannot create lock: $!\n";
        sysopen($handle, $path, O_RDWR | O_NOFOLLOW)
            or die "installation: cannot open existing lock: $!\n";
    }
    binmode($handle) or die "installation: cannot set lock byte mode: $!\n";

    # Nonblocking acquisition makes an accidental concurrent `make install`
    # fail immediately, without staging files or waiting indefinitely. A lock
    # is held by the returned open handle until the installer process exits.
    if (!flock($handle, LOCK_EX | LOCK_NB)) {
        # EWOULDBLOCK/EAGAIN indicates a cooperating process holds the lock.
        # Filesystems without working flock support also fail closed but
        # should not be misreported as another running installer.
        my $error = 0 + $!;
        if ($error == EWOULDBLOCK || $error == EAGAIN) {
            die "installation: another install/uninstall holds the prefix lock\n";
        }
        die "installation: cannot acquire reliable prefix lock: $!\n";
    }

    # Check both the opened inode and its directory entry *after* locking.
    # Ownership, private mode, link count and the protocol marker prevent us
    # from treating an arbitrary pre-existing operator file as our own lock.
    # Comparing device/inode also detects a replaced path before proceeding.
    my @opened = stat($handle);
    my @named  = lstat($path);
    @opened && @named && ($opened[2] & 0170000) == 0100000 &&
        ($named[2] & 0170000) == 0100000 &&
        $opened[0] == $named[0] && $opened[1] == $named[1] &&
        $opened[3] == 1 && $opened[4] == $> &&
        ($opened[2] & 07777) == 0600
        or die "installation: unsafe or replaced prefix lock; manual review required\n";

    if ($created) {
        # The new inode starts empty. Publish a small recognizable marker
        # while the exclusive lock is already held, before any payload work.
        # syswrite() avoids leaving the marker in Perl's output buffer if
        # the process is terminated shortly after acquiring the new lock.
        # This reduces an avoidable empty-lock scenario after SIGKILL, but
        # deliberately does not claim fsync-based power-loss durability.
        my $written = syswrite($handle, $MAGIC);
        defined($written) && $written == length($MAGIC)
            or die "installation: cannot initialize prefix lock: $!\n";
    } else {
        # Reject unknown data, oversized files and truncated writes. Do not
        # truncate an unexpected lock file: it may be operator-owned evidence.
        $opened[7] == length($MAGIC)
            or die "installation: invalid prefix lock contents\n";
        seek($handle, 0, 0)
            or die "installation: cannot seek prefix lock: $!\n";
        my $line = <$handle>;
        defined($line) && $line eq $MAGIC
            or die "installation: invalid prefix lock contents\n";
    }

    return $handle;
}

1;
