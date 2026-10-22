#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M7.4 deterministic security/privacy regressions. Never read host auth logs;
# every event here is synthetic and all external processes use argv, not shell.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $script = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'auth-event-summary');
my $tmp = tempdir('sasd-auth-m74-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $prefix = 'Oct 22 08:15:20 testhost ';

sub fixture {
    my ($name, $data) = @_;
    my $path = File::Spec->catfile($tmp, $name);
    open my $fh, '>', $path or die 'cannot create test fixture';
    binmode($fh);
    print {$fh} $data or die 'cannot write test fixture';
    close $fh or die 'cannot close test fixture';
    return $path;
}
sub call_tool {
    my ($stdin, @args) = @_;
    # Use only small stdin fixtures: writing 16 MiB into a child which stops
    # reading on a limit would deadlock open3 on some OSes. Large tests use
    # regular temporary files instead.
    my $errfh = gensym();
    my $pid = open3(my $in, my $out, $errfh, $^X, $script, @args);
    binmode($in);
    print {$in} $stdin if defined $stdin && length $stdin;
    close $in;
    binmode($out);
    binmode($errfh);
    local $/;
    my $output = <$out> // '';
    my $error = <$errfh> // '';
    close $out;
    close $errfh;
    waitpid($pid, 0);
    return ($? >> 8, $output, $error);
}
sub count {
    my ($text, $key) = @_;
    return $1 if $text =~ /^\Q$key\E\t([0-9]+)$/m;
    return undef;
}

my ($rc, $out, $err) = call_tool(undef, '--help');
is($rc, 0, '--help succeeds');
like($out, qr/\AUsage: auth-event-summary /, 'usage is printed');
is($err, '', 'help stderr empty');
($rc, $out, $err) = call_tool(undef, '--version');
is($rc, 0, '--version succeeds');
is($out, "auth-event-summary 0.1.0\n", 'exact version output');
is($err, '', 'version stderr empty');
for my $args (['--oops'], ['unexpected'], ['--input'], ['--input',''],
              ['--null','unexpected'], ['--input','-','extra'], ['--format','auto']) {
    ($rc, $out) = call_tool(undef, @$args);
    is($rc, 2, 'bad CLI returns 2');
    is($out, '', 'bad CLI never returns a report');
}

my @known = (
    "${prefix}sudo[120]: alice : TTY=pts/0 ; PWD=/home/alice ; USER=root ; COMMAND=/usr/bin/id PRIVATE",
    "${prefix}sudo: alice : user NOT in sudoers ; TTY=pts/1 ; PWD=/home/alice",
    "${prefix}su[144]: (to root) alice on pts/0",
    "${prefix}su: FAILED SU (to root) alice on pts/0",
    "${prefix}sudo[120]: pam_unix(sudo:auth): authentication failure; logname= uid=1000 rhost=192.0.2.1 user=alice",
    "${prefix}su[155]: pam_unix(su:session): session opened for user root by alice(uid=1000)",
    "${prefix}sudo[120]: pam_unix(sudo-i:session): session closed for user root",
    "${prefix}sudo: unrelated policy trace containing user NOT in sudoers",
    "${prefix}cron[100]: alice : TTY=pts/0 ; PWD=/secret ; USER=root ; COMMAND=/usr/bin/id",
);
my $body = join("\n", @known) . "\n";
($rc, $out, $err) = call_tool($body);
is($rc, 0, 'fully parsed valid local syslog source returns 0');
is($err, '', 'no diagnostics on valid input');
like($out, qr/\AEVENT\tCOUNT\n/, 'TSV schema stable');
for my $name (qw(SUDO_COMMAND SUDO_DENIED SU_SUCCESS SU_FAILED
                 PAM_AUTH_FAILURE PAM_SESSION_OPEN PAM_SESSION_CLOSE
                 OTHER_AUTH OTHER_SERVICE)) {
    is(count($out,$name), 1, "$name counts exactly one record");
}
is(count($out,'UNKNOWN'), 0, 'all envelopes recognized');
is(count($out,'TOTAL'), 9, 'correct physical record count');
unlike($out, qr/PRIVATE|alice|testhost|192\.0\.2|COMMAND=|root|pts\/0/, 'no identity, command or source disclosed');

my $named = fixture('auth with spaces.log', $body);
($rc, $out) = call_tool(undef,'--input',$named);
is($rc, 0, 'regular input with spaces in name supported');
is(count($out,'TOTAL'), 9, 'regular file counts all records');
($rc, $out) = call_tool(undef,'--input','-');
is($rc, 0, 'explicit stdin valid');
is(count($out,'TOTAL'), 0, 'empty stdin is an empty snapshot');
($rc, $out, $err) = call_tool('');
is($rc, 0, 'implicit empty stdin is valid');
is(count($out,'TOTAL'), 0, 'implicit empty stdin total zero');

($rc, $out) = call_tool($body,'--null');
is($rc, 0, 'NUL mode successful');
like($out, qr/\0\z/, 'NUL output terminated');
my @fields = split(/\0/, $out, -1); pop @fields;
is(scalar(@fields), 22, 'eleven rows with two NUL fields each');
is(join('|',@fields[0..1]), 'SUDO_COMMAND|1', 'NUL first row correct');
is(join('|',@fields[-2..-1]), 'TOTAL|9', 'NUL final row correct');
unlike($out, qr/PRIVATE|alice|testhost|COMMAND=/, 'NUL output private-data safe');

# A prefix/embedded keyword is not a verified *event*. For example, a sudo
# COMMAND line containing "NOT in sudoers" is a command invocation log, not
# a sudo policy denial. Also, a PAM session line is not a su login success.
my @other = (
    "${prefix}sudo: alice : TTY=pts/1 ; PWD=/tmp ; USER=root ; COMMAND=/usr/bin/printf user NOT in sudoers",
    "${prefix}sudo: just a message: COMMAND=/root/sensitive",
    "${prefix}sudo: al : PASSWORD FAILURE from host",
    "${prefix}sudo: al : COMMAND=/bin/true ; USER=root ; PWD=/tmp ; TTY=pts/1",
    "${prefix}sudo: pam_unix(su:auth): authentication failure; user=alice",
    "${prefix}sudo: pam_unix(sudo:account): authentication failure; user=alice",
    "${prefix}su: pam_unix(sudo:session): session opened for user root",
    "${prefix}su: pam_unix(su:session): session opened by wrong header",
    "${prefix}su: user (to root) on pts/1",
    "${prefix}su: FAILED SU blurb only",
    "${prefix}su: (to root) alice",
    "${prefix}sudo: pam_unix(sudo:auth): authentication succeeded; user=alice",
);
($rc, $out) = call_tool(join("\n",@other)."\n");
is($rc, 0, 'unsupported but well-formed auth records are not parse failures');
is(count($out,'OTHER_AUTH'), scalar(@other)-1, 'unsupported auth records counted conservatively');
is(count($out,'SUDO_COMMAND'), 1, 'structured sudo command with misleading message still command');
is(count($out,'SUDO_DENIED'), 0, 'no false sudo denial');
is(count($out,'SU_SUCCESS'), 0, 'no false su success');
is(count($out,'SU_FAILED'), 0, 'no false su failure');
is(count($out,'PAM_AUTH_FAILURE'), 0, 'no false PAM failure');
is(count($out,'PAM_SESSION_OPEN'), 0, 'no false PAM open');

my @valid_edge = (
    '<0>Oct  9 00:00:00 x sudo: a : TTY=pts/0 ; PWD=/ ; USER=root ; COMMAND=/bin/id',
    '<191>Feb 29 23:59:59 x su: (to root) a on none',
    "${prefix}sudo-i[400]: pam_unix(sudo-i:session): session opened for user root by (uid=0)",
    "${prefix}su-l[1]: pam_unix(su-l:auth): authentication failure; foo=bar",
    "${prefix}sudo: x : 3 incorrect password attempts ; TTY=pts/0 ; PWD=/tmp",
    "${prefix}sudo: x : command not allowed ; TTY=pts/0 ; PWD=/tmp",
    "${prefix}su: FAILED SU (to admin) x on none",
    "${prefix}sudo: al : user NOT authorized on host ; TTY=pts/0 ; PWD=/tmp",
    "${prefix}sudo: al : TTY=pts/0 ; CHROOT=/var/chroot ; PWD=/ ; USER=root ; GROUP=wheel ; TSID=ab12 ; COMMAND=/bin/id",
);
($rc,$out) = call_tool(join("\r\n",@valid_edge)."\r\n");
is($rc,0,'PRI bounds, leap-day, sudo-i/su-l variants and CRLF accepted');
is(count($out,'SUDO_COMMAND'),2,'PRI-zero and optional-fields sudo commands');
is(count($out,'SU_SUCCESS'),1,'PRI-191 su success');
is(count($out,'PAM_SESSION_OPEN'),1,'sudo-i PAM opened');
is(count($out,'PAM_AUTH_FAILURE'),1,'su-l PAM failure');
is(count($out,'SUDO_DENIED'),3,'three sudo denial variants');
is(count($out,'SU_FAILED'),1,'one su failure');

my @unknown = (
    'malformed sudo: a : TTY=pts/0 ; PWD=/ ; USER=root ; COMMAND=/id',
    '<192>Oct 22 08:15:20 testhost sudo: a : TTY=pts/0 ; PWD=/ ; USER=root ; COMMAND=/id',
    '<002>Oct 22 08:15:20 testhost sudo: a : TTY=pts/0 ; PWD=/ ; USER=root ; COMMAND=/id',
    '<-1>Oct 22 08:15:20 testhost sudo: user NOT in sudoers',
    ' <3>Oct 22 08:15:20 testhost sudo: user NOT in sudoers',
    'Oct 22 08:15:20 testhost sudo[abc]: something',
    'Oct 22 25:15:20 testhost su: (to root) alice on pts/0',
    'Feb 30 10:10:10 testhost su: (to root) alice on pts/0',
    'Apr 31 10:10:10 testhost su: FAILED SU (to root) alice on pts/0',
    'Oct 22 08:60:20 testhost sudo: pam_unix(sudo:auth): authentication failure',
    'Oct 22 08:15:60 testhost sudo: pam_unix(sudo:auth): authentication failure',
    'Oct 22 08:15:20 testhost sudo:',
    'Oct 22 08:15:20 sudo: user NOT in sudoers',
);
($rc,$out,$err)=call_tool(join("\n",@unknown)."\n");
is($rc,1,'unverifiable envelopes return finding exit code 1');
is(count($out,'UNKNOWN'),scalar(@unknown),'all invalid records accounted for');
is(count($out,'TOTAL'),scalar(@unknown),'no dropped invalid records');
is(count($out,'SUDO_DENIED'),0,'no fabricated sudo denial from malformed line');
is(count($out,'SU_SUCCESS'),0,'no fabricated su success');
is($err,'','unknown is not a fatal input error');
($rc,$out)=call_tool(join("\n",@unknown)."\n",'--null');
is($rc,1,'NUL mode preserves unknown finding exit');
like($out,qr/UNKNOWN\0[0-9]+\0/,'unknown NUL record machine readable');

($rc,$out,$err)=call_tool("${prefix}sudo: x : TTY=pts/0 ; PWD=/private ; USER=root ; COMMAND=/bin/true \e[31mPRIVATE\e[0m\n");
is($rc,0,'embedded ANSI sequence in private command does not break snapshot');
unlike($out,qr/\e|PRIVATE|private/,'terminal escapes and private tokens not emitted');

my $many = ("${prefix}su: (to root) a on pts/0\n") x 50_001;
my @fatal = (
    ['unfinished',"${prefix}su: (to root) alice on pts/0",'unterminated record'],
    ['blank',"\n",'blank record'],
    ['middle_blank',"${prefix}sudo: xyz\n\n",'empty middle record'],
    ['bare_cr',"${prefix}su: (to root) a on pts\r/0\n",'bare CR'],
    ['nul',"${prefix}su: (to root) a on pts\0/0\n",'NUL byte'],
    ['long',"${prefix}sudo: ".('a' x 140_000)."\n",'oversized physical record'],
    ['many',$many,'record-count limit'],
    ['bytes',('x' x (16*1024*1024+1)),'total-byte limit'],
);
for my $t (@fatal) {
    my ($name,$bytes,$reason)=@$t;
    my $path=fixture("$name.log",$bytes);
    ($rc,$out,$err)=call_tool(undef,'--input',$path);
    is($rc,3,"$reason exits 3");
    is($out,'',"$reason prints no partial report");
    like($err,qr/\Aauth-event-summary: /,"$reason generic diagnostic");
    unlike($err,qr/alice|PRIVATE|testhost|pts\/0|\x1b/,"$reason never leaks log text");
}
my $missing = File::Spec->catfile($tmp,'private-missing-file');
($rc,$out,$err)=call_tool(undef,'--input',$missing);
is($rc,3,'missing file exits 3');
is($out,'','missing file no report');
unlike($err,qr/private-missing-file/,'no filesystem path in diagnostic');
($rc,$out)=call_tool(undef,'--input',$tmp);
is($rc,3,'directory rejected');
is($out,'','directory no report');
my $link=File::Spec->catfile($tmp,'log-link');
SKIP: {
    skip 'symlinks unsupported on this platform',2 unless symlink($named,$link);
    ($rc,$out)=call_tool(undef,'--input',$link);
    is($rc,3,'symlink input rejected');
    is($out,'','symlink no report');
}

done_testing();
