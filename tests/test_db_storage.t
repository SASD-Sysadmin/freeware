#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M5.4: isolated MariaDB/MySQL CLI doubles; no real database or user changes.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $bin = File::Spec->rel2abs("$FindBin::Bin/../bin/db-storage");
my $tmp = tempdir('sasd-db-storage-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $mock = "$tmp/mock sql client";
open my $fh, '>', $mock or die $!;
print {$fh} <<'MOCK';
#!/usr/bin/env perl
use strict;
use warnings;
if (defined $ENV{SASD_M54_ARGV}) {
    open my $o, '>', $ENV{SASD_M54_ARGV} or die $!;
    print {$o} join("\n", @ARGV), "\nMYSQL_PWD=", ($ENV{MYSQL_PWD} // '<absent>'), "\n";
    close $o or die $!;
}
my $mode = $ENV{SASD_M54_MODE} // 'good';
if ($mode eq 'failure') { print STDERR "secret password=topsecret\n"; exit 6; }
if ($mode eq 'timeout') { sleep 15; exit 0; }
if ($mode eq 'oversize') { print 'X' x 70000; exit 0; }
if ($mode eq 'stderr_oversize') { print STDERR 'secret' x 12000; exit 0; }
if ($mode eq 'single') {
    print "TOTAL\tlab\t<all>\t3\t300\t70\t370\t12\t0\n";
    print "TABLE\ta\tInnoDB\t1\t200\t20\t220\t10\t0\n"; exit 0;
}
if ($mode eq 'empty') {
    print "TOTAL\tlab\t<all>\t0\t0\t0\t0\t0\t0\n"; exit 0;
}
if ($mode eq 'missing') { exit 0; }
if ($mode eq 'header') { print "bad\tlab\t<all>\t2\t10\t2\t12\t0\t0\n"; exit 0; }
if ($mode eq 'database') { print "TOTAL\tother\t<all>\t0\t0\t0\t0\t0\t0\n"; exit 0; }
if ($mode eq 'columns') { print "TOTAL\tlab\t<all>\t2\t10\n"; exit 0; }
if ($mode eq 'negative') { print "TOTAL\tlab\t<all>\t2\t-10\t2\t-8\t0\t0\n"; exit 0; }
if ($mode eq 'inconsistent') { print "TOTAL\tlab\t<all>\t2\t10\t2\t99\t0\t0\n"; exit 0; }
if ($mode eq 'table_missing') {
    print "TOTAL\tlab\t<all>\t1\t10\t2\t12\t0\t0\n";
    print "TABLE\tone\tInnoDB\t1\t10\t2\t12\t0\n"; exit 0;
}
if ($mode eq 'duplicate') {
    print "TOTAL\tlab\t<all>\t1\t10\t2\t12\t0\t0\n";
    print "TOTAL\tlab\t<all>\t1\t10\t2\t12\t0\t0\n"; exit 0;
}
if ($mode eq 'mismatch_count') {
    print "TOTAL\tlab\t<all>\t0\t10\t2\t12\t0\t0\n";
    print "TABLE\tfirst\tInnoDB\t1\t10\t2\t12\t0\t0\n"; exit 0;
}
if ($mode eq 'newline') { print "TOTAL\tlab\t<all>\t1\t1\t2\t3\t0\t0\nTABLE\tbad\033[31m\tInnoDB\t1\t1\t2\t3\t0\t0\n"; exit 0; }
if ($mode eq 'nulls') {
    print "TOTAL\tlab\t<all>\t1\t0\t2\t2\t0\t1\n";
    print "TABLE\tpartial\tInnoDB\t1\t0\t2\t2\t0\t1\n"; exit 0;
}
if ($mode eq 'bad_unknown_total') {
    print "TOTAL\tlab\t<all>\t1\t10\t2\t12\t0\t2\n"; exit 0;
}
if ($mode eq 'unreported_unknown') {
    print "TOTAL\tlab\t<all>\t1\t10\t2\t12\t0\t0\n";
    print "TABLE\tone\tInnoDB\t1\t10\t2\t12\t0\t1\n"; exit 0;
}
if ($mode eq 'bad_unknown') {
    print "TOTAL\tlab\t<all>\t1\t10\t2\t12\t0\t0\n";
    print "TABLE\tone\tInnoDB\t1\t10\t2\t12\t0\t9\n"; exit 0;
}
if ($mode eq 'large') {
    print "TOTAL\tlab\t<all>\t1\t9007199254740993\t100\t9007199254741093\t0\t0\n";
    print "TABLE\tlarge\tInnoDB\t1\t9007199254740993\t100\t9007199254741093\t0\t0\n"; exit 0;
}
if ($mode eq 'too_many') {
    print "TOTAL\tlab\t<all>\t102\t102\t0\t102\t0\t0\n";
    for (1..101) { print "TABLE\ttable$_\tInnoDB\t1\t1\t0\t1\t0\t0\n" }
    exit 0;
}
print "TOTAL\tlab\t<all>\t3\t300\t70\t370\t12\t0\n";
print "TABLE\ta\tInnoDB\t1\t200\t20\t220\t10\t0\n";
print "TABLE\tb\tAria\t1\t80\t40\t120\t2\t0\n";
MOCK
close $fh or die $!;
chmod 0755, $mock or die $!;

sub call {
    my (@args) = @_;
    my $err = gensym();
    my $pid = open3(my $in, my $out, $err, $^X, $bin, @args);
    close $in;
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    close $out;
    close $err;
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}
sub mock_call { return call('--client', $mock, '--engine','mariadb','--database','lab', @_); }
sub argv_read {
    open my $f, '<', "$tmp/argv" or die $!;
    local $/;
    return <$f>;
}
my ($rc, $out, $err) = call('--help');
is($rc,0,'help exits zero');
like($out, qr/^Usage: db-storage/, 'help explains invocation');
is($err, '', 'help does not warn');
($rc,$out,$err) = call('--version');
is($rc,0,'version exits zero');
is($out,"db-storage 0.1.0\n",'version command and semver');
is($err,'','version does not warn');
for my $args (
    [], ['--engine','mariadb'], ['--database','lab'],
    ['--engine','postgresql','--database','lab'], ['--engine','oracle','--database','lab'],
    ['--engine','mysql','--database','lab','--port','3306'],
    ['--engine','mysql','--database','lab','--host','--execute=DROP'],
    ['--engine','mysql','--database','lab','--host','mysql://user:password@server'],
    ['--engine','mysql','--database','../etc/passwd'],
    ['--engine','mysql','--database','lab;DROP TABLE x'],
    ['--engine','mysql','--database','lab name'],
    ['--engine','mysql','--database','-lab'],
    ['--engine','mysql','--database','lab','--limit','0'],
    ['--engine','mysql','--database','lab','--limit','101'],
    ['--engine','mysql','--database','lab','--limit','1.1'],
    ['--engine','mysql','--database','lab','--timeout','0'],
    ['--engine','mysql','--database','lab','--timeout','31'],
    ['--engine','mysql','--database','lab','--sort-by','total;DELETE'],
    ['--engine','mysql','--database','lab','--sort-by','TOTAL'],
    ['--engine','mysql','--database','lab','--port','65536','--host','localhost'],
    ['--engine','mysql','--database','lab','--unknown'],
) {
    ($rc,$out) = call(@$args);
    is($rc, 2, 'invalid argument set has usage status 2');
    is($out, '', 'invalid argument set never claims success');
}
($rc) = call('--engine','mariadb','--database','lab','--client','relative/path');
is($rc,3,'relative CLI path rejected');

local $ENV{SASD_M54_ARGV} = "$tmp/argv";
local $ENV{SASD_M54_MODE} = 'good';
local $ENV{MYSQL_PWD} = 'must-not-leak';
($rc,$out,$err) = mock_call();
is($rc,0,'good fixture exits zero');
like($out,qr/^ENGINE\tSCOPE\tKIND\tNAME\tSTORAGE_ENGINE\tTABLES\tDATA_BYTES\tINDEX_BYTES\tTOTAL_BYTES\tFREE_BYTES\tUNKNOWN\n/, 'stable column header');
like($out,qr/\bTOTAL\tlab\t<all>\t3\t300\t70\t370\t12\t0/, 'aggregate includes all visible base tables');
like($out,qr/\bTABLE\ta\tInnoDB\t1\t200\t20\t220\t10\t0/, 'top table output');
like($out,qr/top 2 table\(s\) out of 3 visible/, 'top N distinguished from aggregate');
is($err,'','clean stderr on success');
my $args=argv_read();
like($args,qr/\A--no-defaults\n/,'no implicit plaintext options');
like($args,qr/\n--protocol=SOCKET\n--host=localhost\n/,'fixed local socket');
like($args,qr/\n--database=lab\n--execute\nSELECT /,'schema selection in argv');
like($args,qr/information_schema\.TABLES/,'read-only metadata query');
like($args,qr/TABLE_SCHEMA = DATABASE\(\)/,'metadata limited to selected database');
like($args,qr/TABLE_TYPE = 'BASE TABLE'/,'views deliberately excluded');
like($args,qr/ORDER BY sort_position ASC, total_bytes DESC, name ASC LIMIT 21/,'bounded top 20 and deterministic sorting');
unlike($args,qr/must-not-leak/,'MYSQL_PWD removed from child environment');
unlike($args,qr/DELETE|UPDATE|INSERT|DROP|SHOW PROCESSLIST/i,'no destructive SQL or process text');

{ local $ENV{SASD_M54_MODE}='single';
($rc,$out) = mock_call('--limit','1','--sort-by','index');
is($rc,0,'limit 1 and sort index accepted');
like(argv_read(),qr/ORDER BY sort_position ASC, index_bytes DESC, name ASC LIMIT 2/,'sort enum maps to safe SQL identifier');
}
($rc,$out) = mock_call('--sort-by','free');
is($rc,0,'free sorting accepted');
like(argv_read(),qr/ORDER BY sort_position ASC, free_bytes DESC, name ASC LIMIT 21/,'free ordering explicit');
($rc,$out) = mock_call('--sort-by','data');
is($rc,0,'data sorting accepted');
like(argv_read(),qr/ORDER BY sort_position ASC, data_bytes DESC, name ASC LIMIT 21/,'data ordering explicit');
($rc,$out) = mock_call('--engine','mysql','--host','db.example.org','--port','3306','--timeout','7');
is($rc,0,'MySQL over explicit TCP mock succeeds');
$args=argv_read();
like($args,qr/\n--protocol=TCP\n--host=db\.example\.org\n--ssl-mode=VERIFY_IDENTITY\n/,'MySQL requires hostname verified TLS');
like($args,qr/\n--port=3306\n/,'port is explicit');
like($args,qr/\n--connect-timeout=7\n/,'bounded connection timeout');
($rc,$out) = mock_call('--host','db.example.org');
is($rc,0,'MariaDB explicit TCP mock succeeds');
like(argv_read(),qr/--ssl\n--ssl-verify-server-cert\n/,'MariaDB verifies server certificate');
($rc,$out) = mock_call('--null');
is($rc,0,'NUL mode success');
is(scalar(() = $out =~ /\0/g),33,'three records with eleven NUL fields');
unlike($out, qr/ENGINE\tSCOPE/, 'NUL mode has no headers');

my $config="$tmp/client.cnf";
open my $f, '>', $config or die $!;
print {$f} "[client]\nuser=reader\npassword=topsecret\nssl-ca=/trusted/ca.pem\n";
close $f;
chmod 0600,$config or die $!;
($rc,$out) = mock_call('--defaults-file',$config);
is($rc,0,'private client credential file accepted');
like(argv_read(),qr/\A--defaults-file=\Q$config\E\n/,'credentials filename first');
unlike(argv_read(),qr/topsecret/, 'credential value not passed in argv');
chmod 0644,$config or die $!;
($rc,$out) = mock_call('--defaults-file',$config);
is($rc,3,'world-readable config refused');
chmod 0600,$config or die $!;
my $link="$tmp/symlink";
symlink($config,$link) or die $!;
($rc) = mock_call('--defaults-file',$link);
is($rc,3,'symlink credential file refused');
for my $bad ("[client]\ninit-command=DELETE FROM x\n", "!include /etc/passwd\n", "[client]\nhost=evil.test\n", "[mysql]\npassword=secret\n") {
    open $f, '>', $config or die $!; print {$f} $bad; close $f;
    ($rc,$out) = mock_call('--defaults-file',$config);
    is($rc,3,'unsafe client option/section refused');
    is($out,'','no output from refused config');
}
for my $case (
    ['empty',0,'valid empty selected database'],
    ['missing',3,'missing TOTAL sentinel'],
    ['header',3,'wrong sentinel'],
    ['database',3,'mismatched database identity'],
    ['columns',3,'malformed metadata columns'],
    ['negative',3,'negative size'],
    ['inconsistent',3,'inconsistent total'],
    ['table_missing',3,'missing per-table column'],
    ['duplicate',3,'duplicate TOTAL'],
    ['mismatch_count',3,'total count smaller than rows'],
    ['newline',3,'control escape in table name'],
    ['bad_unknown',3,'invalid unknown count'],
    ['bad_unknown_total',3,'impossible TOTAL unknown count'],
    ['unreported_unknown',3,'hidden per-table unknown metric'],
    ['large',0,'exact integer above IEEE-754 range'],
    ['too_many',3,'client ignores SQL LIMIT'],
    ['failure',1,'native SQL error'],
    ['oversize',3,'oversized stdout'],
    ['stderr_oversize',3,'oversized stderr'],
) {
    local $ENV{SASD_M54_MODE}=$case->[0];
    ($rc,$out,$err)=mock_call();
    is($rc,$case->[1], "$case->[2] has correct exit status");
    if ($case->[1] == 3 || $case->[0] eq 'failure') { is($out,'',"$case->[2] never prints unvalidated output"); }
    unlike($err,qr/password=topsecret|secretsecret/,"$case->[2] does not leak native stderr");
    if ($case->[0] eq 'large') { like($out,qr/9007199254741093/,'large integer remains exact'); }
}
{
    local $ENV{SASD_M54_MODE}='nulls';
    ($rc,$out,$err)=mock_call();
    is($rc,1,'NULL metadata gives nonzero partial coverage');
    like($out,qr/INCOMPLETE METRICS: 1 table/,'NULL warning shown to human');
    ($rc,$out)=mock_call('--null');
    is($rc,1,'NULL metadata nonzero also in NUL mode');
    unlike($out,qr/INCOMPLETE METRICS/,'NUL mode has no extra diagnostics');
}
{
    local $ENV{SASD_M54_MODE}='timeout';
    ($rc,$out,$err)=mock_call('--timeout','1');
    is($rc,3,'hung client bounded by timeout');
    is($out,'','no false success for timeout');
}
done_testing();
