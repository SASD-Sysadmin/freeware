#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
rotate="$here/../bin/rotate"
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/sasd-rotate-tests.XXXXXXXX")
trap 'rm -rf -- "$tmpdir"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_content() {
    local actual=$1 expected=$2
    [[ -f $actual ]] || fail "missing $actual"
    [[ $(cat -- "$actual") == "$expected" ]] || fail "wrong content: $actual"
}

[[ -x $rotate ]] || fail 'rotate must be executable'
bash -n "$rotate"

# Reject missing or excessive parameters, absent files, directories, symlinks.
if "$rotate" >/dev/null 2>&1; then fail 'no-argument call succeeded'; fi
if "$rotate" one two >/dev/null 2>&1; then fail 'two-argument call succeeded'; fi
if "$rotate" "$tmpdir/missing" >/dev/null 2>&1; then fail 'missing-file call succeeded'; fi
if "$rotate" "$tmpdir" >/dev/null 2>&1; then fail 'directory call succeeded'; fi
printf 'linked\n' > "$tmpdir/real"
ln -s real "$tmpdir/link"
if "$rotate" "$tmpdir/link" >/dev/null 2>&1; then fail 'symlink call succeeded'; fi

# A full cycle keeps exactly ten snapshots and leaves the source unchanged.
file="$tmpdir/hosts file"
for (( i=0; i<12; i++ )); do
    printf 'revision-%s\n' "$i" > "$file"
    "$rotate" "$file"
    assert_content "$file" "revision-$i"
done
for (( i=0; i<10; i++ )); do
    assert_content "${file}.${i}" "revision-$((11 - i))"
done
[[ ! -e ${file}.10 ]] || fail 'version .10 exists'
[[ ! -e ${file}.rotate.lock ]] || fail 'lock not removed'

# Clean up only numerical suffixes >= 10; preserve unrelated names.
printf 'obsolete\n' > "${file}.10"
printf 'obsolete\n' > "${file}.987"
printf 'keep\n' > "${file}.01"
printf 'keep\n' > "${file}.10.notes"
"$rotate" "$file"
[[ ! -e ${file}.10 && ! -e ${file}.987 ]] || fail 'old numeric backups survive'
assert_content "${file}.01" keep
assert_content "${file}.10.notes" keep

# Fail safely on an unexpected directory, symlink, or occupied lock.
other="$tmpdir/blocked"
printf 'before\n' > "$other"
mkdir "${other}.2"
if "$rotate" "$other" >/dev/null 2>&1; then fail 'directory slot accepted'; fi
[[ ! -e ${other}.0 ]] || fail 'created backup despite invalid slot'
rmdir "${other}.2"
ln -s real "${other}.1"
if "$rotate" "$other" >/dev/null 2>&1; then fail 'symlink slot accepted'; fi
rm "${other}.1"
mkdir "${other}.rotate.lock"
if "$rotate" "$other" >/dev/null 2>&1; then fail 'occupied lock accepted'; fi
[[ ! -e ${other}.0 ]] || fail 'created backup despite occupied lock'
rmdir "${other}.rotate.lock"

# Preserve binary input and support a file name beginning with '-'.
printf '\000\377\001\000' > "$tmpdir/-binary"
(cd "$tmpdir" && "$rotate" -binary)
cmp "$tmpdir/-binary" "$tmpdir/-binary.0" || fail 'binary copy differs'

printf 'PASS: rotate tests\n'
