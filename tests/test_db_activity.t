#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M5.3: isolated subprocess doubles only. No real database/server required.
# The doubles capture exact argv, transport policy and requested fixed SQL.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $bin = File::Spec->rel2abs("$FindBin::Bin/../bin/db-activity");
my $tmp = tempdir('sasd-db-activity-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $mock = "$tmp/mock native client";
open my $fh, '>', $mock or die $!;
print {$fh} <<'MOCK';
#!/usr/bin/env perl
use strict;
use warnings;
if (defined $ENV{SASD_DB_TEST_ARGS}) {
    open my $f, '>', $ENV{SASD_DB_TEST_ARGS} or die $!;
    print {$f} join("\n", @ARGV), "\nPGSSLMODE=", ($ENV{PGSSLMODE} // ''),
        "\nPGCONNECT_TIMEOUT=", ($ENV{PGCONNECT_TIMEOUT} // ''),
        "\nMYSQL_PWD=", ($ENV{MYSQL_PWD} // '<absent>'), "\n";
    close $f or die $!;
}
my $sql = join(' ', @ARGV);
my $pg = $sql =~ /SASD_PRIV/;
my $mode = $ENV{SASD_DB_TEST_MODE} // 'good';
if ($mode eq 'failure') { print STDERR "secret password=do-not-echo\n"; exit 9; }
if ($mode eq 'hang') { sleep 12; exit 0; }
if ($mode eq 'oversize') { print 'X' x 80000; exit 0; }
if ($mode eq 'stderr-oversize') { print STDERR 'secret' x 14000; exit 0; }
if ($mode eq 'empty') { exit 0; }
if ($mode eq 'denied') { print "SASD_PRIV\tno\t<none>\t<none>\t0\t<none>\t<none>\t0\n"; exit 0; }
if ($mode eq 'bad-sentinel') { print "SASD_PRIV\tmaybe\t<none>\t<none>\t0\t<none>\t<none>\t0\n"; exit 0; }
if ($mode eq 'double-sentinel') { print "SASD_PRIV\tyes\t<none>\t<none>\t0\t<none>\t<none>\t0\nSASD_PRIV\tyes\t<none>\t<none>\t0\t<none>\t<none>\t0\n"; exit 0; }
if ($mode eq 'bad-columns') {
    print $pg ? "SASD_PRIV\tyes\t<none>\t<none>\t0\t<none>\t<none>\t0\n21\treader\tapp\n" : "21\treader\tapp\n";
    exit 0;
}
if ($mode eq 'bad-id') { print $pg ? "SASD_PRIV\tyes\t<none>\t<none>\t0\t<none>\t<none>\t0\nabc\treader\tapp\tactive\t12\tLock\trelation\t1\n" : "abc\treader\tapp\tQuery\t12\tLocked\n"; exit 0; }
if ($mode eq 'bad-seconds') { print $pg ? "SASD_PRIV\tyes\t<none>\t<none>\t0\t<none>\t<none>\t0\n21\treader\tapp\tactive\t-1\tLock\trelation\t1\n" : "21\treader\tapp\tQuery\t-1\tLocked\n"; exit 0; }
if ($mode eq 'control') { print $pg ? "SASD_PRIV\tyes\t<none>\t<none>\t0\t<none>\t<none>\t0\n21\treader\tapp\tactive\t12\tLock\tbad\033[0m\t1\n" : "21\treader\tapp\tQuery\t12\tbad\033[0m\n"; exit 0; }
if ($mode eq 'bad-blockers') { print "SASD_PRIV\tyes\t<none>\t<none>\t0\t<none>\t<none>\t0\n21\treader\tapp\tactive\t12\tLock\trelation\tabc\n"; exit 0; }
if ($mode eq 'none') { print "SASD_PRIV\tyes\t<none>\t<none>\t0\t<none>\t<none>\t0\n" if $pg; exit 0; }
if ($mode eq 'many') {
    print "SASD_PRIV\tyes\t<none>\t<none>\t0\t<none>\t<none>\t0\n" if $pg;
    for (1..4) { print $pg ? "$_\treader\tapp\tactive\t12\tLock\trelation\t1\n" : "$_\treader\tapp\tQuery\t12\tWaiting for metadata lock\n"; }
    exit 0;
}
if ($pg) {
    print "SASD_PRIV\tyes\t<none>\t<none>\t0\t<none>\t<none>\t0\n";
    if ($mode eq 'wait') { print "21\treader\tapp\tactive\t12\tLock\trelation\t0\n"; exit 0; }
    print "21\treader\tapp\tactive\t12\tLock\ttransactionid\t2\n";
    print "22\treader\tapp\tidle in transaction\t6\t<none>\t<none>\t0\n";
} else {
    print "21\treader\tapp\tQuery\t12\tWaiting for table metadata lock\n";
    print "22\treader\t<none>\tSleep\t6\t<none>\n";
}
MOCK
close $fh or die $!;
chmod 0755, $mock or die $!;

sub cli {
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
sub fake {
    my (@args) = @_;
    return cli('--client', $mock, @args);
}
sub captured {
    open my $f, '<', "$tmp/args" or die $!;
    local $/;
    my $data = <$f>;
    close $f;
    return $data;
}
my ($rc,$out,$err);
($rc,$out,$err) = cli('--help');
is($rc,0,'--help exits zero');
like($out, qr/\AUsage: db-activity/, 'help text');
is($err, '', 'help no stderr');
($rc,$out,$err) = cli('--version');
is($rc,0,'--version exits zero');
is($out,"db-activity 0.1.0\n",'version shape');
is($err, '', 'version no stderr');

for my $case (
    [], ['--engine','oracle'], ['--engine','mariadb','--port','3306'],
    ['--engine','mysql','--host','-option'], ['--engine','mysql','--host','mysql://invalid'],
    ['--engine','postgresql','--database','host=test sslmode=disable'],
    ['--engine','postgresql','--database','postgresql://secret@test/db'],
    ['--engine','mariadb','--database','-admin'],
    ['--engine','mysql','--user',"bad\nuser"],
    ['--engine','mysql','--timeout','0'],
    ['--engine','mysql','--timeout','31'],
    ['--engine','mysql','--limit','0'],
    ['--engine','mysql','--limit','101'],
    ['--engine','mysql','--limit','0001'],
    ['--engine','mysql','--min-seconds','-1'],
    ['--engine','mysql','--min-seconds','86401'],
    ['--engine','mysql','--min-seconds','99999999999999'],
    ['--engine','mysql','--min-seconds','1;DROP'],
    ['--engine','mysql','--unknown'],
    ['--engine','mysql','--port','65536','--host','db.example.org'],
    ['--engine','postgresql','--defaults-file',"$tmp/nonexistent"],
) {
    ($rc) = cli(@$case);
    is($rc,2,'invalid CLI rejected');
}
($rc) = cli('--engine','mysql','--client','relative-client');
is($rc,3,'relative executable refused');
($rc) = cli('--engine','mysql','--defaults-file',"$tmp/nope",'--client',$mock);
is($rc,3,'missing credentials file refused');

local $ENV{SASD_DB_TEST_ARGS} = "$tmp/args";
local $ENV{SASD_DB_TEST_MODE} = 'good';
local $ENV{PGSSLMODE} = 'disable';
local $ENV{PGCONNECT_TIMEOUT} = '300';
local $ENV{MYSQL_PWD} = 'do-not-forward';
($rc,$out,$err) = fake('--engine','postgresql','--host','db.example.org',
    '--port','5432','--user','reader','--database','app','--limit','5','--min-seconds','4');
is($rc,0,'PostgreSQL activity successful');
like($out,qr/\AENGINE\tSCOPE\tSESSION_ID/, 'stable activity header');
like($out,qr/postgresql\tcluster\t21\treader\tapp\tactive\t12\tLock:transactionid\tblocked\t2/, 'real blocker count with wait event');
like($out,qr/postgresql\tcluster\t22\treader\tapp\tidle in transaction\t6\t<none>\tnone\t0/, 'idle in transaction identified');
is($err,'','no native stderr on success');
my $args=captured();
like($args,qr/\A-X\n/,'psql ignores startup scripts');
like($args,qr/\n-w\n/,'psql disallows interactive password');
like($args,qr/\n-v\nON_ERROR_STOP=1\n/,'psql SQL errors fail');
like($args,qr/PGSSLMODE=verify-full/,'psql verifies remote host TLS');
like($args,qr/PGCONNECT_TIMEOUT=5/,'psql bounded connect time');
like($args,qr/pg_has_role\(current_user, 'pg_read_all_stats', 'USAGE'\)/,'psql explicitly verifies stats rights');
like($args,qr/pg_blocking_pids\(a.pid\)/,'psql gathers real blockers');
like($args,qr/UNION ALL/,'psql privilege sentinel and sessions in one result set');
like($args,qr/LIMIT 6\) SELECT/,'PostgreSQL limit plus one');
like($args,qr/\>= 4 ORDER BY/,'PostgreSQL min-seconds server side');
unlike($args,qr/(?:query\s*,|a\.query\s*,|SELECT\s+\*)/i,'SQL does not fetch query text');
unlike($args,qr/do-not-forward/,'mysql password environment removed');
($rc,$out) = fake('--engine','postgresql','--include-idle','--null');
is($rc,0,'PostgreSQL NUL mode succeeds');
is($out,join("\0",'postgresql','cluster','21','reader','app','active','12','Lock:transactionid','blocked','2')."\0".
         join("\0",'postgresql','cluster','22','reader','app','idle in transaction','6','<none>','none','0')."\0",
   'PostgreSQL NUL records exact, 10 fields each');
like(captured(),qr/AND a\.pid <> pg_backend_pid\(\) AND GREATEST/s,'--include-idle does not filter idle state');
{
    local $ENV{SASD_DB_TEST_MODE} = 'denied';
    ($rc,$out,$err) = fake('--engine','postgresql');
    is($rc,1,'PostgreSQL denied stats is a query/permission failure');
    is($out,'','PostgreSQL no misleading partial session report');
    like($err,qr/pg_read_all_stats/,'role requirement explained');
}
{
    local $ENV{SASD_DB_TEST_MODE} = 'wait';
    ($rc,$out) = fake('--engine','postgresql');
    is($rc,0,'waiting query no blockers is valid');
    like($out,qr/\twaiting\t0\n/,'waiting not misreported as confirmed block');
}
($rc,$out,$err) = fake('--engine','mysql','--host','db.example.org','--port','3306',
    '--user','reader','--limit','4','--min-seconds','2');
is($rc,0,'MySQL processlist snapshot');
like($out,qr/mysql\tvisible\t21\treader\tapp\tQuery\t12\tWaiting for table metadata lock\tpossible\t\?/, 'MySQL lock hint is only possible, never confirmed');
like($out,qr/mysql\tvisible\t22\treader\t<none>\tSleep\t6\t<none>\tunknown\t\?/, 'native state is not converted into invented lock result');
is($err,'','MySQL no stderr on success');
$args=captured();
like($args,qr/\A--no-defaults\n/, 'MySQL ignores plaintext defaults by default');
like($args,qr/--protocol=TCP\n--host=db.example.org/,'explicit TCP target');
like($args,qr/--ssl-mode=VERIFY_IDENTITY/,'MySQL certificate and identity verified');
like($args,qr/AND TIME >= 2/,'MySQL server-side min seconds');
like($args,qr/LIMIT 5\n/,'MySQL SQL limit plus one');
like($args,qr/ID <> CONNECTION_ID\(\)/,'MySQL own diagnostic session excluded');
unlike($args,qr/\bINFO\b/i,'MySQL statement text never selected');
unlike($args,qr/do-not-forward/,'MySQL plaintext password env removed');
($rc,$out) = fake('--engine','mariadb');
is($rc,0,'MariaDB local socket snapshot');
$args=captured();
like($args,qr/\A--no-defaults\n/,'MariaDB ignores plaintext defaults');
like($args,qr/--protocol=SOCKET\n--host=localhost/,'MariaDB local socket pinned');
unlike($args,qr/--ssl-verify-server-cert/,'socket does not use network TLS');
like($args,qr/COMMAND <> 'Sleep'/,'default MySQL hides Sleep');
($rc,$out) = fake('--engine','mariadb','--host','db.example.org','--include-idle');
is($rc,0,'MariaDB explicit TCP snapshot');
like(captured(),qr/--ssl\n--ssl-verify-server-cert/,'MariaDB TLS verifies certificate');
unlike(captured(),qr/COMMAND <> 'Sleep'/,'--include-idle includes sleeping sessions');

my $config="$tmp/db config";
open my $cfg,'>',$config or die $!;
print {$cfg} "[client]\nuser=reader\npassword=secret-value\nssl-ca=/tmp/ca.pem\n";
close $cfg;
chmod 0600,$config or die $!;
($rc) = fake('--engine','mariadb','--defaults-file',$config);
is($rc,0,'private credential file is accepted');
like(captured(),qr/\A--defaults-file=\Q$config\E\n/,'defaults file is first argv');
unlike(captured(),qr/secret-value/,'password not embedded in argv');
chmod 0644,$config or die $!;
($rc) = fake('--engine','mariadb','--defaults-file',$config);
is($rc,3,'world readable credential file refused');
chmod 0600,$config or die $!;
my $symlink="$tmp/secret-link";
symlink $config,$symlink or die $!;
($rc) = fake('--engine','mariadb','--defaults-file',$symlink);
is($rc,3,'config file symlink refused');
for my $line ('init-command=DROP TABLE important','host=other.example.org',
              '!include /tmp/anything','ssl-mode=DISABLED','[mysql]') {
    open $cfg,'>',$config or die $!;
    print {$cfg} "[client]\npassword=secret\n$line\n";
    close $cfg;
    ($rc,$out,$err) = fake('--engine','mariadb','--defaults-file',$config);
    is($rc,3,"unsafe config rejected ($line)");
    is($out,'','no data from unsafe config');
    unlike($err,qr/secret|DROP TABLE/,'no secret from config logged');
}
for my $case (
    ['failure','postgresql',1], ['failure','mariadb',1],
    ['bad-sentinel','postgresql',3], ['double-sentinel','postgresql',3],
    ['bad-columns','postgresql',3], ['bad-columns','mariadb',3],
    ['bad-id','postgresql',3], ['bad-id','mariadb',3],
    ['bad-seconds','postgresql',3], ['bad-seconds','mysql',3],
    ['control','postgresql',3], ['control','mysql',3],
    ['bad-blockers','postgresql',3],
    ['oversize','postgresql',3], ['oversize','mysql',3],
    ['stderr-oversize','postgresql',3], ['stderr-oversize','mariadb',3],
    ['empty','postgresql',3],
) {
    local $ENV{SASD_DB_TEST_MODE}=$case->[0];
    ($rc,$out,$err) = fake('--engine',$case->[1]);
    is($rc,$case->[2], "$case->[0] $case->[1] exit correct");
    is($out,'',"$case->[0] $case->[1] no partial success output");
    unlike($err,qr/do-not-echo|password=|secretsecret/,"$case->[0] $case->[1] hides native secrets");
}
{
    local $ENV{SASD_DB_TEST_MODE}='none';
    ($rc,$out) = fake('--engine','postgresql');
    is($rc,0,'empty PostgreSQL snapshot is valid after role check');
    like($out,qr/No visible sessions matched/,'empty report explicit');
    ($rc,$out) = fake('--engine','mysql','--null');
    is($rc,0,'empty MySQL null output successful');
    is($out,'','no fabricated null records');
}
{
    local $ENV{SASD_DB_TEST_MODE}='many';
    ($rc,$out) = fake('--engine','postgresql','--limit','2');
    is($rc,3,'more than limit plus one PostgreSQL rows refused');
    is($out,'','too many rows no output');
    ($rc,$out) = fake('--engine','mariadb','--limit','2');
    is($rc,3,'more than limit plus one MySQL rows refused');
    is($out,'','too many rows no output');
    ($rc,$out) = fake('--engine','mariadb','--limit','3');
    is($rc,1,'truncated snapshot returns nonzero status');
    like($out,qr/INCOMPLETE: limit 3 reached/,'truncation prominently disclosed');
    unlike($out,qr/\n4\treader/,'fourth row not printed');
    ($rc,$out) = fake('--engine','mariadb','--limit','3','--null');
    is($rc,1,'NUL truncation is reported by nonzero status');
    is(scalar(() = $out =~ /\0/g),30,'NUL contains exactly three ten-field records');
}
{
    local $ENV{SASD_DB_TEST_MODE}='hang';
    ($rc,$out) = fake('--engine','mysql','--timeout','1');
    is($rc,3,'hung backend terminated');
    is($out,'','hung backend produces no fake success');
}
done_testing();
