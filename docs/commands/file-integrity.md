# `file-integrity` — SHA-256 content baseline and integrity comparison

**English** · [Deutsch](file-integrity.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/file-integrity.1) · [Source](../../bin/file-integrity)

## Purpose and use

Recursively hash regular files within `--root DIR`. `--init` **writes** a new JSON baseline outside the tree; `--check` (default) compares current SHA-256 contents and reports `ADDED`, `CHANGED`, and `MISSING`. This is **not** a backup, signature verification, malware scanner or comprehensive FIM system.

## Behavior and checks

The specified root must be a real directory (an explicit root symlink is rejected), and symlinks are not traversed. The manifest must be outside the monitored root and must not be a symlink itself. It stores a format marker `sasd-integrity-v1`, the absolute resolved root path and relative names/digests; the same root path must be used for checks. Hashing does not include ownership, permissions, ACLs, xattrs, timestamps, labels, or symlink targets. Files modified during the scan can give inconsistent results.

## Usage and options

```text
file-integrity --help
```

| Option | Meaning |
| --- | --- |
| `--root DIR` | Existing scanned directory (required). |
| `--manifest FILE` | JSON baseline outside root; parent directory must exist. |
| `--init` | Publish a **new** baseline; never replace an existing manifest. |
| `--check` | Read-only comparison (default). |
| `--help`, `--version` | Metadata without file scan. |

## Practical example

```sh
lab="$(mktemp -d)"
mkdir "$lab/tree" "$lab/baselines"
printf 'version=1\n' > "$lab/tree/test.conf"
./bin/file-integrity --root "$lab/tree" \
  --manifest "$lab/baselines/tree.json" --init
./bin/file-integrity --root "$lab/tree" \
  --manifest "$lab/baselines/tree.json" --check
printf 'version=2\n' > "$lab/tree/test.conf"
./bin/file-integrity --root "$lab/tree" \
  --manifest "$lab/baselines/tree.json" --check
# Inspect the disposable $lab directory before manually removing it.
```

First comparison returns 0; the deliberate change produces `CHANGED` with exit 1. Never automatically run `--init` immediately before each check: that would overwrite the meaning of the trusted reference, although the code refuses replacement of an existing manifest.

## Output and exit status

Initialization: `BASELINE: files=N manifest=...`. Comparison: `ADDED:`, `CHANGED:`, `MISSING:` and `SUMMARY: files=N changed=N added=N missing=N`. Output paths are not a NUL-delimited machine format.

`0` = initialized or no content differences; `1` = comparison found a difference; `2` = invalid invocation; other nonzero = I/O, JSON, manifest, or publication error. **Matching digests do not prove system security.**

## Limits, safety and portability

`--init` writes a private temporary file in the manifest directory and publishes with an atomic no-overwrite hard link (same-directory hardlink support required). Unexpected termination may leave `.sasd-integrity-*` for manual inspection. The baseline is only trustworthy when independently protected. An attacker who changes files and manifest can hide changes. Snapshots, concurrency control, ACL/metadata checks and distribution-specific filesystem acceptance are outside scope.

## Related resources

[Privileged safety](../PRIVILEGED-SAFETY.md) · [Security policy](../../SECURITY.md) · [Automation overview](automation-tools.md)
