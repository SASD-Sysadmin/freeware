# Perl runtime and command dependencies — FR2-02

[Deutsch](PERL-COMPATIBILITY.de.md) · [Project](../README.md) · [Platforms](PLATFORMS.md) · [Tests](TESTING.md) · [Release gaps](RELEASE-GAPS.md)

**Evidence recorded:** 2026-11-18; documentation prepared 2026-11-21. **Verified source baseline:** `b1960f4d0dda11e736fe71829953cfb5e4398c63` (`main`). This is an operator-provided local test record, not independently attested CI evidence. The document records a *tested runtime*, not an unconditional minimum for every Perl release or operating system.

## 1. Compatibility statement and scope

- **Lowest complete-suite Perl runtime demonstrated so far:** **Perl 5.14.4**, specifically on Debian Linux in WSL2 (x86_64, Linux `5.15.167.4-microsoft-standard-WSL2`). `make test` completed with status **0** using the private Perl 5.14.4 interpreter and matching `prove` (TAP::Harness 3.23).
- **Offline regression result:** 49 Perl test files, 6,146 reported TAP test cases, **zero failures**, **10 explicitly skipped** test cases; the two Bash rotation test groups also passed. Skips are not executed acceptance tests. The source and repository remained unchanged during testing.
- **Focused CLI and syntax inventory:** 74 Perl source files and 53 Perl CLI entry points; **0** syntax/help/version failures after repairing the *test interpreter*'s generated `Errno.pm`.
- **Release-gap inventory:** `PASS=288`, `GAP=0`, `MANUAL=7`. All seven manual release gates remain open. Static inventory success does not establish deployment, privileged, or release approval.
- **Other runtime:** local Perl 5.36.0 audit passed; version-specific end-to-end evidence is limited to the runs actually recorded.
- **Not established:** compatibility with Perl 5.8, 5.10, 5.12, 5.14.0–5.14.3, every subsequent Perl release, every Unix variant, every external client version, or production security suitability. Do **not** describe 5.14.4 as a generally proven theoretical minimum or an endorsed production runtime. Perl 5.14 is end-of-life; use a maintained Perl in production.

The obsolete statement “Perl 5.8 or later” is removed from the current READMEs. The defined-or `//` operator appears in shipped source and requires Perl 5.10 or later, while bundled JSON::PP and Socket resolver APIs also impose actual runtime/module requirements. Their mere historical availability does not prove whole-product operation under older Perls.

## 2. Perl modules and relevant features

| Requirement | Scope | Requirement or finding | Evidence boundary |
| --- | --- | --- | --- |
| Perl 5 interpreter and bundled `SASD::Freeware::*` modules | Shipped Perl commands | Use corresponding installed `lib/` modules; do not run bare copied commands without them | Complete offline suite passed with 5.14.4 on one Debian/WSL2 host |
| `strict`, `warnings`, `Getopt::Long`, `File::*`, `Digest::SHA`, `Errno`, `Fcntl` and other standard modules | Selected commands and installer | Must be available and working in the target interpreter | Syntax/CLI, installer and fixture regressions passed on repaired 5.14.4 |
| `JSON::PP` | JSON reporting/parsing, notably `mail-queue` and JSON-based Linux components | Required where JSON operations are performed; bundled with Perl 5.14.4 in the exercised installation (`2.27105`) | Does not imply that *all* Perl 5.14 installations have every module available |
| `Socket` resolver / IPv6 APIs | `host-resolve`, DNS and network helpers | `getaddrinfo`, `getnameinfo`, `inet_pton`, `AF_INET6` where imported | Imports passed in 5.14.4; actual OS resolver behavior remains host-dependent |
| `IO::Socket::SSL >= 2.009` | `mail-probe` verified STARTTLS | **Non-core feature dependency**; fail safely when unavailable; never bypass certificate/hostname checks | Exercised with `IO::Socket::SSL 2.099` and `Net::SSLeay 1.96` |
| `Net::SSLeay`, OpenSSL libraries | TLS module backend | Versions must be compatible with each other and the target OS; no universal minimum established here | Tested `Net::SSLeay 1.96` with OpenSSL 3.0.22 |

On this test host, Perl 5.14.4 initially had a broken, auto-generated `Errno.pm`: `ENOENT`, `ENOTDIR`, `ELOOP`, `EEXIST`, `EWOULDBLOCK`, and `EAGAIN` were not exported, affecting `link-audit`, `InstallLock.pm`, and consequently `installation.pl`. `Fcntl::O_NOFOLLOW` and `Fcntl::S_ISLNK` were **available**. The historical build was made to run with `-O0 -fwrapv -fno-strict-aliasing`; the private Perl 5.14 `Errno_pm.PL` generator was corrected to pass `-P` to the preprocessor when producing errno values. Its generated `Errno.pm` was replaced **only in the private test installation**. No SASD program or security check was weakened. These steps are historical test-fixture repairs, **not** installation guidance or a backported fix to maintain in SASD Freeware.

The read-only dependency scanner also reported `administrative` from the sentence `may require administrative permissions` in `bin/quota-report`; this was a parser false positive, not a missing Perl module. The versioned `tools/fr2-02-compat-audit.sh` narrows its literal-import heuristic accordingly. It is not a full Perl parser.

## 3. Native clients: feature-specific, not global dependencies

Versions below are **not** declared minimum versions unless explicitly stated. Binary availability is *not* equivalent to compatible output formats, permissions, host capabilities or production acceptance.

| Commands / purpose | Native client(s) | Prerequisite boundary |
| --- | --- | --- |
| `fs-usage` | POSIX-compatible `df` | Capacity reporting only; host output varies |
| `quota-report` | `quota` or `repquota` depending on mode | Read-only; quota support/permissions are host-specific |
| `quota-status` / `quota-set` | Linux `quotaon -p` / `setquota` | Status versus explicit privileged apply; quota filesystem support and independent VM acceptance required |
| `dns-query`, `ldap-probe`, `nis-probe` | `dig`, `ldapsearch`, `ypwhich` respectively | Needed only for corresponding live operation; LDAP certificate verification is mandatory |
| `db-probe`, `db-health`, `db-activity` | `psql`, `mysql` or `mariadb` selected by engine | Native SQL clients; TLS, privileges and server compatibility require independent verification |
| `db-storage` | `mysql` or `mariadb` | PostgreSQL is not implemented for this command |
| `mail-queue` | `postqueue -j` from **Postfix >= 3.1** for live queue mode | `JSON::PP` for parsing; offline input tests do not require Postfix |
| `network-interface-report`, `network-route-report`, `network-service-report` | Linux `ip`/`ss`; macOS/BSD `ifconfig`/`netstat` by command/backend | Platform and output-format dependent; `netstat` is not a global Linux prerequisite |
| `firewall-config-audit` | Selected native Linux/BSD/Solaris firewall tools (`nft`, `iptables-save`, `pfctl`, etc.) | Only for selected native mode; static input parsing works without the corresponding host firewall |
| `linux-distro-matrix`, `linux-container-acceptance` | `docker` or `podman` **only for opt-in container mode** | Offline/plan mode does not require a container engine; native certification not implied |
| `rotate` | Bash and standard host file utilities | **No Perl runtime required** |

Native client version floors beyond the existing `postqueue`/Postfix claim remain **unverified**. `quota`, `pfctl`, `docker`, etc. missing from a Debian/WSL2 audit do not disqualify unrelated offline commands. See the individual command guides for precise mode and privilege constraints.

## 4. Test prerequisites and reproduction

The original evidence used a private Perl interpreter at `~/tmp/fr2-02/perl-5.14.4-wrapv/bin/perl`, private CPAN modules at `~/tmp/fr2-02/perl514-tls/lib/perl5`, and OpenSSL 3.0.22. The build's source was the Perl 5.14.4 CPAN tarball, checksum-checked before compiling. The history records compile flags and the local Errno generator correction; it does **not** capture verified checksums for every third-party CPAN distribution, compiler or library. This is an auditable procedure description, **not a bit-for-bit reproducible toolchain**.

From a clean checkout with the *already prepared* historical test interpreter and TLS modules:

```bash
prefix="$HOME/tmp/fr2-02/perl-5.14.4-wrapv"
modules="$HOME/tmp/fr2-02/perl514-tls"
(
    set -euo pipefail
    export PATH="$prefix/bin:$PATH"
    export PERL5LIB="$modules/lib/perl5"
    unset PERL5OPT
    test "$(command -v perl)" = "$prefix/bin/perl"
    test "$(command -v prove)" = "$prefix/bin/prove"
    perl -e 'printf "Perl %vd\n", $^V'
    perl -MJSON::PP -MSocket=getaddrinfo,getnameinfo,inet_pton,AF_INET6 -e 'print "Core API imports OK\n"'
    perl -MIO::Socket::SSL -e 'IO::Socket::SSL->VERSION(2.009); print "Verified TLS dependency OK\n"'
    bash tools/fr2-02-compat-audit.sh . "$prefix/bin/perl" "$HOME/tmp/.test-logs"
    make test
    make release-gap-audit
)
```

`make test` invokes shell tests, syntax checks and individual `prove` suites. It may launch processes using their shebang/PATH conventions; a future test-hardening slice may explicitly log and enforce every child interpreter. Do not assume this transcript covers every native execution path. Full logs and local system identifiers remain **outside Git** and must be reviewed for sensitive data before sharing.

**Acceptance still open:** exact-commit CI rerun after merging this documentation, native OS/runtime matrix, privileged disposable-VM approval and execution, client-version integration, third-party notice/provenance review, and formal release approval. See [release gaps](RELEASE-GAPS.md) for the seven `MANUAL` gates.
