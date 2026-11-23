#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# FR2-06a: strictly nonprivileged, throwaway-DESTDIR acceptance smoke.
# It does NOT change host users, groups, quotas, mounts, domains or snapshots.
# See docs/FR2-06-VM-ACCEPTANCE.md for the separate human-authorized VM gate.
set -Eeuo pipefail
umask 077
export LC_ALL=C

usage() {
    cat <<'HELP'
Usage: bash tools/fr2-06a-staging-acceptance.sh [--repo /absolute/source/path] [--keep]
Run fresh/repeat/conflict/upgrade/tamper/transaction-guard/uninstall checks
using a private temporary source copy and DESTDIR. No sudo, no --apply,
no host installation, no VM or snapshot actions. --keep retains the private
sandbox for manual inspection; by default it is deleted on completion.
Test results alone do not close the manual staged-upgrade or VM release gate.
HELP
}
repo="$(pwd -P)"
keep=0
while (($#)); do
    case "$1" in
        --repo)
            (($# >= 2)) || { usage >&2; exit 2; }
            repo=$2
            shift 2
            ;;
        --keep)
            keep=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            usage >&2
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

if ((EUID == 0)); then
    echo 'BLOCKED: do not run this fixture test as root; use an unprivileged user' >&2
    exit 3
fi
[[ -d "$repo" ]] || { echo 'BLOCKED: missing source directory' >&2; exit 3; }
repo="$(cd -- "$repo" && pwd -P)"
for p in LICENSE bin sbin lib man docs tools/installation.pl; do
    [[ -e "$repo/$p" && ! -L "$repo/$p" ]] || {
        echo "BLOCKED: source fixture prerequisite missing or symlinked: $p" >&2
        exit 3
    }
done
[[ -x "$repo/bin/rotate" ]] || { echo 'BLOCKED: source bin/rotate missing/non-executable' >&2; exit 3; }
command -v perl >/dev/null || { echo 'BLOCKED: perl not found' >&2; exit 3; }
command -v cmp >/dev/null || { echo 'BLOCKED: cmp not found' >&2; exit 3; }
command -v mktemp >/dev/null || { echo 'BLOCKED: mktemp not found' >&2; exit 3; }

sandbox="$(mktemp -d "${TMPDIR:-/tmp}/sasd-fr2-06a.XXXXXXXX")"
cleanup() {
    local rc=$?
    trap - EXIT
    if ((keep)); then
        printf 'EVIDENCE: private sandbox retained at %s (do not commit raw logs)\n' "$sandbox"
    else
        rm -rf -- "$sandbox"
    fi
    exit "$rc"
}
trap cleanup EXIT

src="$sandbox/source"
stage="$sandbox/stage"
root="$stage/usr/freeware"
logs="$sandbox/logs"
mkdir -p "$src" "$stage" "$logs"
# The checkout is NEVER modified; all upgrade mutations are in this private copy.
cp -R "$repo/bin" "$repo/sbin" "$repo/lib" "$repo/man" "$repo/docs" "$src/"
cp "$repo/LICENSE" "$src/LICENSE"
installer="$repo/tools/installation.pl"

run_ok() {
    local name=$1
    shift
    if "$@" >"$logs/$name.log" 2>&1; then
        printf 'PASS %-25s\n' "$name"
    else
        printf 'FAIL %-25s (exit nonzero, inspect %s)\n' "$name" "$logs/$name.log" >&2
        cat "$logs/$name.log" >&2
        return 1
    fi
}
run_reject() {
    local name=$1
    shift
    if "$@" >"$logs/$name.log" 2>&1; then
        printf 'FAIL %-25s (unsafe operation unexpectedly succeeded)\n' "$name" >&2
        return 1
    else
        printf 'PASS %-25s (refused as expected)\n' "$name"
    fi
}
install() { perl "$installer" --mode install --source "$src" --prefix /usr/freeware --destdir "$stage"; }
uninstall() { perl "$installer" --mode uninstall --prefix /usr/freeware --destdir "$stage"; }

# The manifest must own exactly the installed LICENSE bytes (independent digest).
manifest_has_license() {
    perl -MDigest::SHA -e '
        my ($manifest, $license) = @ARGV;
        open my $fh, "<", $license or die "license read: $!";
        binmode $fh;
        my $digest = Digest::SHA->new(256)->addfile($fh)->hexdigest;
        close $fh or die "license close: $!";
        open my $in, "<", $manifest or die "manifest read: $!";
        my $count = 0;
        while (<$in>) {
            chomp;
            my ($name, $sha) = split /\t/, $_, -1;
            if ($name eq "LICENSE") {
                ++$count;
                exit 1 if !defined($sha) || $sha ne $digest;
            }
        }
        close $in or die "manifest close: $!";
        exit($count == 1 ? 0 : 1);
    ' "$root/.sasd-freeware-install.tsv" "$root/LICENSE"
}

printf 'FR2-06a staging smoke | source: %s | all payload mutations are disposable\n' "$repo"
run_ok 'fresh' install
[[ -f "$root/LICENSE" && -f "$root/.sasd-freeware-install.tsv" ]] || exit 1
cmp "$src/LICENSE" "$root/LICENSE"
manifest_has_license
cp "$root/.sasd-freeware-install.tsv" "$sandbox/baseline.tsv"
run_ok 'repeat' install
cmp "$sandbox/baseline.tsv" "$root/.sasd-freeware-install.tsv"

# Create a collision only inside the scratch source and scratch install prefix.
collision='sasd-fr2-06a-unowned-collision'
[[ ! -e "$root/bin/$collision" && ! -e "$src/bin/$collision" ]] || {
    echo 'BLOCKED: unexpected fixture name collision' >&2; exit 1;
}
printf 'operator fixture, do not overwrite\n' > "$root/bin/$collision"
cp "$root/bin/$collision" "$sandbox/unowned-copy"
printf '#!/bin/sh\nexit 0\n' > "$src/bin/$collision"
chmod 0755 "$src/bin/$collision"
run_reject 'unowned-collision' install
grep -q 'unowned destination exists' "$logs/unowned-collision.log" || { echo 'FAIL: wrong conflict diagnostic' >&2; exit 1; }
cmp "$sandbox/unowned-copy" "$root/bin/$collision"
cmp "$sandbox/baseline.tsv" "$root/.sasd-freeware-install.tsv"
rm -- "$src/bin/$collision"

# A real upgrade, still only of a private copy; no repository edits.
printf '\n# FR2-06a scratch-source upgrade\n' >> "$src/bin/rotate"
run_ok 'upgrade' install
cmp "$src/bin/rotate" "$root/bin/rotate"
manifest_has_license
cp "$root/.sasd-freeware-install.tsv" "$sandbox/upgraded.tsv"

printf '\n# unowned operator change\n' >> "$root/bin/rotate"
run_reject 'modified-uninstall' uninstall
grep -q 'changed or missing' "$logs/modified-uninstall.log" || { echo 'FAIL: wrong tamper diagnostic' >&2; exit 1; }
cmp "$sandbox/upgraded.tsv" "$root/.sasd-freeware-install.tsv"
cp "$src/bin/rotate" "$root/bin/rotate"
chmod 0755 "$root/bin/rotate"

# Simulate a transaction marker, NOT an actual process crash.
marker="$root/.sasd-freeware-txn-fr2-06a-simulated"
mkdir "$marker"
run_reject 'transaction-guard' uninstall
grep -q 'interrupted installation transaction exists' "$logs/transaction-guard.log" || { echo 'FAIL: wrong interruption diagnostic' >&2; exit 1; }
[[ -d "$marker" ]] || { echo 'FAIL: transaction marker lost' >&2; exit 1; }
rmdir "$marker"

printf 'operator-owned, should survive uninstall\n' > "$root/operator-note.txt"
run_ok 'uninstall' uninstall
[[ ! -e "$root/LICENSE" && ! -e "$root/bin/rotate" && ! -e "$root/.sasd-freeware-install.tsv" ]] || {
    echo 'FAIL: managed payload still present' >&2; exit 1;
}
cmp "$sandbox/unowned-copy" "$root/bin/$collision"
[[ -f "$root/operator-note.txt" && -f "$root/.sasd-freeware-install.lock" ]] || {
    echo 'FAIL: unowned files or persistent lock missing' >&2; exit 1;
}
printf 'PASS final-manifest-and-unowned-checks\n'
printf 'SUMMARY: PASS (nonprivileged staging only; manual VM gates OPEN)\n'
