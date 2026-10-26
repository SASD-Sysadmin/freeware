# M8.5 Linux V1.0 – acceptance matrix (work in progress)

**No native distribution has been certified by M8.5.1.** The matrix below is
an acceptance plan, not a list of verified operating systems. A Linux distro
name parsed from a fixture does not prove software is installed on that host.

| Target | Detection fixture | Native install/uninstall | Native tools | Firewall acceptance | Status |
| --- | --- | --- | --- | --- | --- |
| Debian (reference) | Offline test | Pending | Pending | nftables, optional UFW pending | Pending |
| Ubuntu LTS | Offline test | Pending | Pending | UFW/nftables, AppArmor pending | Pending |
| Arch Linux | Offline test | Pending | Pending | nftables/firewalld if installed pending | Pending |
| AlmaLinux | Offline test | Pending | Pending | firewalld/SELinux pending | Pending |
| Rocky Linux | Offline test | Pending | Pending | firewalld/SELinux pending | Pending |

## Planned evidence levels

1. **Parser:** synthetic `os-release` fixtures and negative security cases.
2. **Container:** supported Perl/dependencies, `make test`, stage install and
   uninstall on a real distro image. This does **not** validate systemd,
   kernel filtering, actual rule effectiveness or privileged operation.
3. **Isolated VM:** distribution/version recorded, native read-only commands,
   real service state, expected permission failures, non-privileged account,
   clean installation/uninstallation, before/after firewall policy inspection.
4. **Acceptance:** recorded evidence and explicit gaps for each distro version.

Container image tags must be pinned, and native VM setup must never change a
production firewall. Record the distro identity using `linux-platform-report`
without treating the FAMILY field as a capabilities probe.
