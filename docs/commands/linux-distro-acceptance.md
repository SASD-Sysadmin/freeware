# M8.5.2 Linux acceptance protocol – evidence tiers

**Status: prepared, not certified.** A record is valid only when its mode,
architecture, date, exact distribution release and test commands are kept.
Synthetic fixtures are not native tests.

| Platform | Parser fixture | Container smoke | VM native read-only | Firewall / SELinux / AppArmor |
| --- | --- | --- | --- | --- |
| Debian | Implemented in M8.5.2 | Operator run pending | Pending | Pending |
| Ubuntu | Implemented in M8.5.2 | Operator run pending | Pending | Pending |
| Arch | Implemented in M8.5.2 | Operator run pending | Pending | Pending |
| AlmaLinux | Implemented in M8.5.2 | Operator run pending | Pending | Pending |
| Rocky Linux | Implemented in M8.5.2 | Operator run pending | Pending | Pending |

Run in this order on a disposable, network-segmented VM:

1. Record release (`/etc/os-release`), kernel (`uname -sr`), architecture,
   Perl version, package manager and any current SELinux/AppArmor settings.
2. Run `make test`, `make shellcheck` (if installed), and `make install`
   **with `DESTDIR` in a temporary staging directory**. Never install to
   the production host or run `make uninstall` on its real prefix.
3. Run `bin/linux-distro-matrix --mode host --target <exact-ID>
   --require-complete --format jsonl`.
4. If container testing is wanted, separately provision and review an image
   with preinstalled Perl, record its SHA-256 digest, and run container mode.
5. For native firewall acceptance: follow the existing firewall tool's
   read-only acceptance guide, use a dedicated VM and store anonymized
   source/count/status results. **Do not alter firewall policy to force a
   passing test.**
6. Record `PASS`/`FAIL`/`SKIP`, the command, date, relevant tool versions,
   host-vs-container mode, and known limitations. Never turn SKIP into PASS.

A host running Debian does **not** establish Ubuntu, Arch, AlmaLinux or Rocky
Linux acceptance. Container tests do **not** establish native kernel, init,
firewall or mandatory-access-control behavior. First release certification
requires actual VM evidence for each target distribution.
