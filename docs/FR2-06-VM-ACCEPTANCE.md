# FR2-06a – Safe Debian KVM/libvirt staging and VM acceptance

[Deutsch](FR2-06-VM-ACCEPTANCE.de.md) · [Privileged policy](PRIVILEGED-SAFETY.md) · [Release evidence](RELEASE-EVIDENCE.md) · [Report template](FR2-06-REPORT-TEMPLATE.md)

**Prepared:** 2026-11-23. **Pinned starting revision:** `SASD-SysAdmin/freeware` at `f25aa3f2f5c84911fa03d7b8a93daff06b736bef`, [successful CI 45139166377](https://github.com/SASD-SysAdmin/freeware/actions/runs/45139166377) on Ubuntu and macOS. This is a **historical starting point**, not a VM acceptance, signed release, or CI claim for subsequent commits.

## 1. Independent acceptance levels

| Level | Context | Allowed | Not established |
| --- | --- | --- | --- |
| A: automated staging smoke | Unprivileged source checkout | Scratch source copy, private `DESTDIR`, fresh/repeat/collision/upgrade/tamper/guard/uninstall | Host account/quota changes, snapshot tests, actual crash recovery |
| B: isolated VM preflight | Disposable Debian guest | Read-only inventory, CLI previews without `--apply` | Real account or quota changes |
| C: separately approved VM execution | Verified isolated guest with tested restore | One explicitly authorized real action at a time, independent verification, snapshot restore | Blanket permission for scripts to execute privileged changes |

**All seven MANUAL gates remain OPEN** merely by creating or testing these documents. No license change: current repository stays MIT; separate future `SASDGMBH` product will use `AGPL-3.0-only` after rights and release review.

## 2. Run the unprivileged staging smoke

The new script copies all installable source sections into a private scratch directory, invokes the real `tools/installation.pl` with `DESTDIR` pointing **inside that scratch directory**, tests safe source-copy upgrades and refusal scenarios, and cleans up. It never touches the Git checkout or machine account databases. It intentionally refuses effective UID 0.

```bash
cd "$(git rev-parse --show-toplevel)"
set -o pipefail
mkdir -p "$HOME/tmp/.test-logs"
bash tools/fr2-06a-staging-acceptance.sh --repo "$PWD" \
  2>&1 | tee "$HOME/tmp/.test-logs/fr2-06a-staging.log"
printf 'Result: %s\n' "$?"
```

The cases cover: fresh deployment plus exact `LICENSE` and SHA-256 manifest ownership, repeat idempotence, unowned filename conflict, upgrade from a modified **scratch-source copy**, refusal of operator-edited managed content, simulated transaction-marker refusal, manifest-based uninstall, preservation of unowned content and persistent prefix lock. `--keep` explicitly retains the private fixture and its logs; otherwise it is removed. A successful run is only a **partial staged-upgrade evidence record**, never evidence for power failure, SIGKILL, fsync durability, noncooperating writers or real privileged operations.

Log exit status, exact Git SHA, Perl version, date, and local file digest; do not commit raw logs that may contain private paths. Any unexpected success in a refusal test is a FAIL.

## 3. KVM host preflight – read-only

Run on the libvirt host with a **manually chosen, unequivocally disposable domain**; no production domain is assumed:

```bash
LAB_VM='sasd-freeware-lab'  # operator must replace with the actual isolated guest
virsh dominfo "$LAB_VM"
virsh domblklist "$LAB_VM" --details
virsh domiflist "$LAB_VM"
virsh snapshot-list "$LAB_VM" --tree
```

Privately record UUID, storage image formats and backing chains, all attached disks, UEFI/NVRAM, network isolation, free capacity, backup/snapshot identifier and restore procedure. `virsh dumpxml --inactive` may disclose sensitive configuration and should only go into a restricted local evidence store.

**Do not blindly copy a snapshot-create or revert command.** libvirt's internal and external snapshots, multiple disks, qcow2 backing chains and UEFI/NVRAM differ. `virsh snapshot-revert` does not universally restore all external snapshot topologies. Before any modification, ensure the guest is disposable and that a consistent cold backup/clone or suitable complete snapshots include all guest disks and NVRAM where applicable. Independently **test restoration on another disposable instance**; without verified recovery mark the gate `BLOCKED`. See [libvirt virsh](https://libvirt.org/manpages/virsh.html) and [snapshot API](https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html).

STOP if domain identity is uncertain; production credentials/data or networks are present; root/host disks could be selected; the quota test disk is missing; snapshot chain or restore path is unclear; or test accounts collide with real identities. No WSL or production host privileged testing.

## 4. Debian guest preflight and previews

Before any write operation:

```bash
uname -a
cat /etc/os-release
perl -e 'printf "Perl %vd\n", $^V'
findmnt -no TARGET,SOURCE,FSTYPE,OPTIONS /
findmnt -a
command -v useradd groupadd usermod setquota quotaon repquota || true
getent passwd sasd_lab_u1 || true
getent group sasd_lab_g1 || true
```

`getent` is NSS evidence, not proof that an identity is local; independently inspect the local account/group records using a privacy-safe procedure. `account-manage` supports only `user-create`, `group-create`, and `password-lock`. `user-create` uses `useradd -m` and may make a home directory. Password locking does **not** disable SSH keys or established sessions. Valid preview commands in a checked-out source tree:

```bash
./sbin/account-manage --action group-create --name sasd_lab_g1
./sbin/account-manage --action user-create  --name sasd_lab_u1
```

`quota-set` requires an existing mount-point directory and NSS-resolvable test identity **even in preview**. Never use `/`, host or production mounts. A sample, to be used only after manually identifying a separately mounted guest test disk and a dedicated existing user:

```bash
LAB_QUOTA_MOUNT='/mnt/sasd-quota-test'  # replace after verifying a separate guest mount
LAB_QUOTA_USER='sasd_lab_u1'           # must already resolve via NSS
./sbin/quota-set --user "$LAB_QUOTA_USER" \
  --filesystem "$LAB_QUOTA_MOUNT" \
  --block-soft 4096 --block-hard 8192 \
  --inode-soft 100 --inode-hard 200
```

Block limits use **KiB**, inode limits are counts. `0` means unlimited and a real apply additionally requires `--allow-unlimited`. The quota backend is native `setquota`; exact mount-point verification and filesystem support are required. Missing native dependencies or quota setup must be reported `BLOCKED` or `SKIP`, not PASS.

## 5. Manually approved, isolated privileged cases

**No included script runs these tests.** Before every single real apply, record an independent operator authorization, exact VM UUID, verified restore path, selected account/group, source SHA, expected change and verifier.

1. After approved dry-run, test `group-create`, then `user-create` using `account-manage --apply --confirm-apply` with root privileges, verifying local files and NSS independently. Only test `password-lock` on the newly created non-system test user; verify password-authentication impact but do not claim session/key revocation.
2. For `quota-set`, provide a separately mounted quota-enabled scratch disk in the guest. Verify mount, active quota and original values using independent `findmnt`, `quotaon -p`, `repquota`/`quota` before and after **one** individually approved `--apply --confirm-apply` run with explicit nonzero values. The package does not run `mkfs`, `mount`, `quotaon` or native `setquota`.
3. Rejection cases (missing confirmation, malformed name/limit, system account, name collision, soft > hard, invalid path, missing backend) must not modify real account files or storage. Use disposable fixtures for deliberate backend failure injection rather than damaging `/etc`.
4. Restore the guest to its **previously verified** snapshot/backup using the approved host procedure, including extra guest disks and NVRAM. Independently recheck local account records, NSS identities, home directories, mounts, quota records and test markers. Manually deleting a user is **not** equivalent to verifying VM rollback.

Acceptance requires each applied change to match the expectation, every refusal to preserve state, exit codes and before/after evidence captured, then independently confirmed restoration. If restoration fails mark `FAIL`; if authorization or prerequisites are absent mark `BLOCKED`. Neither case can close `privileged-vm`.

## 6. Records and gate semantics

Use the bilingual [report template](FR2-06-REPORT-TEMPLATE.md). Record complete Git SHA and clean/dirty checkout state, environment, explicit per-case authorizations, independent evidence and SHA-256 of sanitized logs. Never commit personal data, private machine addresses or secrets. Preserve the seven release gates without falsely closing them:

- `staged-upgrade`: this nonprivileged run is **partial evidence**, not a full VM/recovery approval.
- `privileged-vm`: **OPEN** until separately approved real apply plus independently checked restore.
- `current-ci`: green on the **starting** `f25aa3f` run [45139166377](https://github.com/SASD-SysAdmin/freeware/actions/runs/45139166377); rerun for the FR2-06a and eventual exact release SHA.
- `artifact-provenance`, `release-approval`, `native-platforms`, `live-services`: separately **OPEN**.

No release tag, publication, AGPL implementation or legal clearance is implied.
