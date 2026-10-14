#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Fault injection and cooperative concurrency; operate only on temp fixtures.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
rotate="$here/../bin/rotate"
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/sasd-rotate-safety.XXXXXXXX")
child_pid=
cleanup() {
    if [[ -n $child_pid ]]; then
        # Release a potentially paused fake cp before waiting for the child.
        touch -- "$tmpdir/release" 2>/dev/null || true
        wait "$child_pid" 2>/dev/null || true
    fi
    rm -rf -- "$tmpdir"
}
trap cleanup EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_contents() {
    local file=$1 expected=$2
    [[ -f $file && $(cat -- "$file") == "$expected" ]] || fail "unexpected content: $file"
}

mkdir -- "$tmpdir/fake-bin"
input="$tmpdir/critical file"
printf 'current\n' > "$input"
printf 'previous\n' > "${input}.0"
printf 'oldest\n' > "${input}.9"
printf 'legacy\n' > "${input}.10"

# A failing copy must leave all snapshots, including the legacy slot, intact.
cat > "$tmpdir/fake-bin/cp" <<'EOF'
#!/usr/bin/env bash
exit 47
EOF
chmod 755 "$tmpdir/fake-bin/cp"
if PATH="$tmpdir/fake-bin:$PATH" "$rotate" "$input" > /dev/null 2>&1; then
    fail 'rotation accepted a failed copy'
fi
assert_contents "$input" current
assert_contents "${input}.0" previous
assert_contents "${input}.9" oldest
assert_contents "${input}.10" legacy
[[ ! -e ${input}.rotate.lock ]] || fail 'failed copy left an occupied lock'
shopt -s nullglob
leftovers=("${input}".rotate.????????)
(( ${#leftovers[@]} == 0 )) || fail 'failed copy left a private snapshot'

# Pause a real rotation immediately before the copy, while it owns its lock.
# A second cooperating process must fail instead of rotating the same file.
cat > "$tmpdir/fake-bin/cp" <<'EOF'
#!/usr/bin/env bash
: > "$SASD_ROTATE_READY"
for ((i=0; i<200; i++)); do
    [[ -e $SASD_ROTATE_RELEASE ]] && exec /bin/cp "$@"
    sleep 0.05
done
exit 48
EOF
chmod 755 "$tmpdir/fake-bin/cp"
export SASD_ROTATE_READY="$tmpdir/ready"
export SASD_ROTATE_RELEASE="$tmpdir/release"
PATH="$tmpdir/fake-bin:$PATH" "$rotate" "$input" &
child_pid=$!
for ((i=0; i<100; i++)); do
    [[ -f $SASD_ROTATE_READY ]] && break
    sleep 0.05
done
[[ -f $SASD_ROTATE_READY ]] || fail 'first rotation did not reach copy fixture'
if "$rotate" "$input" > /dev/null 2>&1; then
    fail 'parallel rotation bypassed the occupied lock'
fi
assert_contents "${input}.0" previous
assert_contents "${input}.9" oldest

touch -- "$SASD_ROTATE_RELEASE"
wait "$child_pid" || fail 'first rotation failed after release'
child_pid=
assert_contents "$input" current
assert_contents "${input}.0" current
assert_contents "${input}.1" previous
[[ ! -e ${input}.rotate.lock ]] || fail 'successful rotation left its lock'

printf 'PASS: rotate failure and concurrency safety tests\n'
