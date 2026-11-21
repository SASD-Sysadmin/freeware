#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# FR2-02: read-only Perl runtime/module inventory and smoke-check evidence.
# No installation, uninstallation, privilege escalation, or external network access.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: fr2-02-compat-audit.sh [REPOSITORY] [PERL_BINARY] [OUTPUT_PARENT]

Defaults: repository=., perl=perl (from PATH), output=$HOME/tmp/.test-logs
Writes a unique private evidence directory outside the repository.
Runs syntax checks and --help/--version for Perl entry points only.
This is NOT proof of a minimum Perl version: repeat with the actual proposed
minimum interpreter in an isolated environment and run the complete test suite.
EOF
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if (($# > 3)); then usage >&2; exit 2; fi
repo_arg=${1:-.}
perl_bin=${2:-perl}
output_parent=${3:-${HOME:?}/tmp/.test-logs}

command -v git >/dev/null 2>&1 || { echo 'ERROR: git unavailable' >&2; exit 3; }
command -v "$perl_bin" >/dev/null 2>&1 || { echo "ERROR: Perl interpreter unavailable: $perl_bin" >&2; exit 3; }
repo=$(git -C "$repo_arg" rev-parse --show-toplevel) || { echo 'ERROR: expected a Git checkout' >&2; exit 3; }
[[ -f "$repo/tools/installation.pl" && -f "$repo/README.md" ]] || {
    echo 'ERROR: not the SASD Freeware source checkout' >&2; exit 3;
}
# All report files are private. Never write into the source tree.
umask 077
mkdir -p "$output_parent"
out=$(mktemp -d "$output_parent/fr2-02-compat-XXXXXXXX")
readme="$out/README.txt"
{
    printf 'FR2-02 compatibility evidence (read-only)\n'
    printf 'UTC timestamp: '; date -u '+%Y-%m-%dT%H:%M:%SZ'
    printf 'Checkout: %s\n' "$repo"
    printf 'Git HEAD: '; git -C "$repo" rev-parse HEAD
    printf 'Working-tree status:\n'; git -C "$repo" status --short
    printf 'Target Perl command: %s\n' "$perl_bin"
    printf 'Target Perl version: '
    "$perl_bin" -e 'printf "%vd\n", $^V' || true
    printf 'OS: '; uname -srm
    printf '\nScope: Perl source syntax, CLI --help/--version, direct and\n'
    printf 'literal dynamic imports, locally installed modules.\n'
    printf 'Not covered: older runtimes not invoked, full program paths,\n'
    printf 'native client versions, CPAN transitive dependencies, VM gates.\n'
} > "$readme"

# Record the exact tracked source inventory; untracked new files are included
# through find below, but each matching source is still part of the working tree.
paths="$out/source-files.txt"
: > "$paths"
while IFS= read -r -d '' file; do
    [[ -f "$file" && ! -L "$file" ]] || continue
    rel=${file#"$repo"/}
    case "$rel" in
        bin/*|sbin/*)
            [[ $rel != */*/* ]] || continue
            if [[ $(head -n 1 "$file") == *perl* ]]; then printf '%s\n' "$rel" >> "$paths"; fi
            ;;
        lib/SASD/Freeware/*.pm|tools/lib/SASD/Freeware/*.pm|tools/*.pl)
            printf '%s\n' "$rel" >> "$paths" ;;
    esac
done < <(find "$repo/bin" "$repo/sbin" "$repo/lib/SASD/Freeware" "$repo/tools" -maxdepth 5 -type f -print0)
sort -u -o "$paths" "$paths"

# A textual inventory, intentionally not confused with a full Perl parser:
# it can miss indirect loading and cannot certify feature-era compatibility.
printf 'relative_path\tmodule\timport_kind\tline\n' > "$out/imports.tsv"
"$perl_bin" - "$repo" "$paths" "$out/imports.tsv" <<'PERL'
use strict;
use warnings;
my ($root,$list,$dest) = @ARGV;
open my $index, '<', $list or die "$list: $!";
open my $out, '>>', $dest or die "$dest: $!";
while (my $rel = <$index>) {
    chomp $rel;
    open my $fh, '<', "$root/$rel" or die "$rel: $!";
    my $line_number = 0;
    while (my $line = <$fh>) {
        ++$line_number;
        next if $line =~ /^\s*#/;
        if ($line =~ /^\s*use\s+([A-Za-z_]\w*(?:::\w+)*)\b/) {
            my $mod = $1;
            print {$out} join("\t",$rel,$mod,'use',$line_number),"\n"
                unless $mod eq 'lib';
        }
        # Heuristic only: accept literal require statements after Perl statement
        # boundaries, not prose such as "may require administrative permissions".
        # This cannot replace a complete Perl parser or detect indirect loads.
        while ($line =~ /(?:\A|[;{(])\s*require\s+([A-Za-z_]\w*(?:::\w+)*)\b/g) {
            my $mod = $1;
            print {$out} join("\t",$rel,$mod,'require',$line_number),"\n";
        }
    }
    close $fh;
}
close $out;
PERL

# Query module availability in the target interpreter; do not imply these
# installed versions are the versions present in historical Perl releases.
printf 'module\tavailable\tinstalled_version\n' > "$out/modules.tsv"
awk -F '\t' 'NR>1 {print $2}' "$out/imports.tsv" | \
    grep -v '^SASD::Freeware::' | sort -u > "$out/modules.names" || true
while IFS= read -r module; do
    [[ $module =~ ^[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_][A-Za-z_0-9]*)*$ ]] || continue
    if version=$(
        "$perl_bin" -e '
            my $module = shift;
            $module =~ /\A[A-Za-z_]\w*(?:::\w+)*\z/ or exit 2;
            eval "require $module; 1" or exit 3;
            no strict "refs";
            my $value = ${"${module}::VERSION"};
            print defined($value) ? $value : "(not declared)";
        ' "$module" 2>/dev/null
    ); then
        printf '%s\tyes\t%s\n' "$module" "$version" >> "$out/modules.tsv"
    else
        printf '%s\tno\t-\n' "$module" >> "$out/modules.tsv"
    fi
done < "$out/modules.names"

# Focused prerequisite tests. IO::Socket::SSL is an optional module for the
# STARTTLS probe, so its absence is reported, not a blanket audit failure.
printf 'feature\tavailable\tcomment\n' > "$out/features.tsv"
feature_check() {
    local label=$1 comment=$2; shift 2
    if "$perl_bin" "$@" >/dev/null 2>&1; then
        printf '%s\tyes\t%s\n' "$label" "$comment" >> "$out/features.tsv"
    else
        printf '%s\tno\t%s\n' "$label" "$comment" >> "$out/features.tsv"
    fi
}
feature_check defined_or 'language feature introduced in Perl 5.10; standalone probe only' \
    -e 'my $x; my $v = $x // "ok"; exit($v eq "ok" ? 0 : 1)'
feature_check json_pp 'JSON::PP core-bundled from Perl 5.14; module may be independently installed' \
    -MJSON::PP -e 'exit 0'
feature_check socket_resolver 'getaddrinfo and getnameinfo importability' \
    -MSocket=getaddrinfo,getnameinfo -e 'exit 0'
feature_check socket_ipv6 'Socket inet_pton and AF_INET6 importability' \
    -MSocket=inet_pton,AF_INET6 -e 'exit 0'
feature_check smtp_ssl 'OPTIONAL mail-probe STARTTLS: IO::Socket::SSL >= 2.009' \
    -MIO::Socket::SSL -e 'IO::Socket::SSL->VERSION(2.009)'

# Inventory external/native clients WITHOUT invoking them or making network calls.
# This checks local availability only; supported client version minima require
# separate, version-pinned integration tests and must not be inferred here.
printf 'client\tavailable\tpath_or_note\n' > "$out/native-clients.tsv"
for client in df quota repquota quotaon setquota dig ldapsearch ypwhich \
              psql mysql mariadb postqueue postconf openssl ip ss netstat \
              ifconfig route nft iptables ufw firewall-cmd pfctl useradd \
              groupadd passwd bash python3 docker; do
    if resolved=$(command -v "$client" 2>/dev/null); then
        printf '%s\tyes\t%s\n' "$client" "$resolved" >> "$out/native-clients.tsv"
    else
        printf '%s\tno\t(not found in PATH)\n' "$client" >> "$out/native-clients.tsv"
    fi
done

# Compile all Perl sources in the target interpreter, then exercise the public
# side-effect-free --help/--version contract for bin/ and sbin/.
printf 'path\tsyntax_rc\thelp_rc\tversion_rc\n' > "$out/checks.tsv"
failed=0
while IFS= read -r rel; do
    set +e
    ( cd "$repo" && "$perl_bin" -Ilib -Itools/lib -c "$rel" ) > "$out/last-command.stdout" 2> "$out/last-command.stderr"
    syntax_rc=$?
    set -e
    help_rc='-'; version_rc='-'
    case "$rel" in
        bin/*|sbin/*)
            set +e
            ( cd "$repo" && "$perl_bin" -Ilib -Itools/lib "$rel" --help ) > "$out/last-command.stdout" 2> "$out/last-command.stderr"
            help_rc=$?
            ( cd "$repo" && "$perl_bin" -Ilib -Itools/lib "$rel" --version ) > "$out/last-command.stdout" 2> "$out/last-command.stderr"
            version_rc=$?
            set -e
            ;;
    esac
    printf '%s\t%s\t%s\t%s\n' "$rel" "$syntax_rc" "$help_rc" "$version_rc" >> "$out/checks.tsv"
    if ((syntax_rc != 0)) || [[ $help_rc != '-' && $help_rc != 0 ]] || [[ $version_rc != '-' && $version_rc != 0 ]]; then
        (( failed += 1 ))
    fi
done < "$paths"
rm -f "$out/last-command.stdout" "$out/last-command.stderr"

{
    printf 'Source files checked: '; wc -l < "$paths"
    printf 'Perl CLI programs checked: '; awk -F '\t' 'NR>1 && $3 != "-" {n++} END {print n+0}' "$out/checks.tsv"
    printf 'Syntax/help/version failing files: %s\n' "$failed"
    printf 'Unavailable direct/literal imports (including optional):\n'
    awk -F '\t' 'NR>1 && $2=="no" {print "  " $1}' "$out/modules.tsv"
    printf 'Native client availability (version compatibility NOT checked):\n'
    awk -F '\t' 'NR>1 && $2=="no" {printf "  missing: %s\n", $1}' "$out/native-clients.tsv"
    printf 'Focused feature availability:\n'
    tail -n +2 "$out/features.tsv"
    printf '\nMinimum-version claim: NOT ESTABLISHED by this single-runtime audit.\n'
} > "$out/SUMMARY.txt"

printf 'Evidence: %s\n' "$out"
cat "$out/SUMMARY.txt"
# Nonzero reports a real problem in syntax/help/version checks for THIS runtime;
# optional dependencies are listed separately and do not fail unrelated CLIs.
((failed == 0))
