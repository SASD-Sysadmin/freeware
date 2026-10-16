#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M5.2: native client fixtures. No SQL server, credentials, root or Internet.
# Only explicit argv, fixed queries, bounded output and complete metrics count.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $bin = File::Spec->rel2abs("$FindBin::Bin/../bin/db-health");
my $tmp = tempdir('sasd-db-health-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $mock = "$tmp/mock client"; # A space must never cause shell-splitting.
open my $fh, '>', $mock or die $!;
print {$fh} <<'MOCK';
#!/usr/bin/env perl
use strict;
use warnings;
if (defined $ENV{SASD_DB_TEST_ARGS}) {
    open my $log, '>', $ENV{SASD_DB_TEST_ARGS} or die $!;
    print {$log} join("\n", @ARGV), "\nPGSSLMODE=", ($ENV{PGSSLMODE} // ''),
         "\nPGCONNECT_TIMEOUT=", ($ENV{PGCONNECT_TIMEOUT} // ''),
         "\nMYSQL_PWD=", ($ENV{MYSQL_PWD} // '<absent>'), "\n";
    close $log or die $!;
}
my $mode = $ENV{SASD_DB_TEST_MODE} // 'normal';
my $pg = grep { $_ eq '-X' } @ARGV;
if ($mode eq 'failure') { print STDERR "password=hunter2 SECRET\n"; exit 9; }
if ($mode eq 'timeout') { sleep 12; exit 0; }
if ($mode eq 'overflow_stdout') { print 'X' x 20000; exit 0; }
if ($mode eq 'overflow_stderr') { print STDERR 'SECRET' x 5000; exit 0; }
if ($pg) {
    if ($mode eq 'denied') { print "no\t8\t1\t1000\n"; exit 0; }
    if ($mode eq 'pg_extra') { print "yes\t8\t1\t1000\nyes\t2\t0\t1000\n"; exit 0; }
    if ($mode eq 'pg_columns') { print "yes\t8\t1\n"; exit 0; }
    if ($mode eq 'pg_controls') { print "yes\t8\t1\t1\033[31m\n"; exit 0; }
    if ($mode eq 'pg_empty') { exit 0; }
    if ($mode eq 'pg_invalid_flag') { print "maybe\t8\t1\t1000\n"; exit 0; }
    print "yes\t8\t1\t1000\n";
} else {
    if ($mode eq 'mysql_missing') { print "Threads_connected\t8\nUptime\t1000\n"; exit 0; }
    if ($mode eq 'mysql_dup') { print "Threads_connected\t8\nThreads_connected\t8\nUptime\t1000\n"; exit 0; }
    if ($mode eq 'mysql_unknown') { print "Threads_connected\t8\nFake\t1\nUptime\t1000\n"; exit 0; }
    if ($mode eq 'mysql_negative') { print "Threads_connected\t8\nThreads_running\t-1\nUptime\t1000\n"; exit 0; }
    if ($mode eq 'mysql_controls') { print "Threads_connected\t8\nThreads_running\t1\nUptime\t1000\033[31m\n"; exit 0; }
    if ($mode eq 'mysql_many') { print "Threads_connected\t8\nThreads_running\t1\nUptime\t1000\nFake\t99\n"; exit 0; }
    if ($mode eq 'mysql_blank') { exit 0; }
    # Deliberately reorder values. Real SHOW order need not be hard-coded.
    print "Uptime\t1000\nThreads_running\t1\nThreads_connected\t8\n";
}
MOCK
close $fh or die $!;
chmod 0755, $mock or die $!;

sub run {
    my (@options) = @_;
    my $err = gensym();
    my $pid = open3(my $in, my $out, $err, $^X, $bin, @options);
    close $in;
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    close $out;
    close $err;
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}
sub mock_run { return run('--client', $mock, @_); }
sub trace {
    open my $in, '<', "$tmp/argv-record" or die $!;
    local $/;
    my $value = <$in>;
    close $in;
    return $value;
}
my ($rc, $out, $err) = run('--help');
is($rc, 0, 'help is independent of backends');
like($out, qr/\AUsage: db-health/, 'help prints usage');
is($err, '', 'help stderr empty');
($rc, $out, $err) = run('--version');
is($rc, 0, 'version without backend');
is($out, "db-health 0.1.0\n", 'version format');
is($err, '', 'version stderr empty');
for my $options (
    [], ['--engine', 'oracle'], ['--engine', 'postgresql', '--port', '3333'],
    ['--engine', 'mariadb', '--timeout', '0'],
    ['--engine', 'mysql', '--timeout', '31'],
    ['--engine', 'mysql', '--host', '::bad host'],
    ['--engine', 'mysql', '--host', '--defaults-file=evil'],
    ['--engine', 'mysql', '--user', "name\n--execute=DROP"],
    ['--engine', 'mysql', '--database', '-database'],
    ['--engine', 'postgresql', '--database', 'postgresql://host/db?sslmode=disable'],
    ['--engine', 'postgresql', '--database', 'dbname=db sslmode=disable'],
    ['--engine', 'mariadb', '--bad'],
    ['--engine', 'mysql', '--port', '65536', '--host', '127.0.0.1'],
    ['--engine', 'postgresql', '--defaults-file', '/tmp/no-file'],
) {
    ($rc, $out) = run(@$options);
    ok($rc == 2 || $rc == 3, 'invalid arguments rejected');
    is($out, '', 'invalid invocation has no success output');
}
($rc) = run('--engine', 'mariadb', '--client', 'relative/path');
is($rc, 3, 'relative --client rejected');

local $ENV{SASD_DB_TEST_ARGS} = "$tmp/argv-record";
local $ENV{SASD_DB_TEST_MODE} = 'normal';
local $ENV{PGSSLMODE} = 'disable';
local $ENV{PGCONNECT_TIMEOUT} = '900';
local $ENV{MYSQL_PWD} = 'do-not-pass';
($rc, $out, $err) = mock_run('--engine','postgresql','--host','db.example.org',
    '--port','5432','--user','audit_reader','--database','admin','--timeout','7');
is($rc, 0, 'PostgreSQL complete health snapshot succeeds');
is($out, "ENGINE\tSCOPE\tCONNECTIONS\tACTIVE\tUPTIME_SECONDS\npostgresql\tcluster\t8\t1\t1000\n", 'PostgreSQL stable output');
is($err, '', 'successful query has empty stderr');
my $args = trace();
like($args, qr/\A-X\n-w\n-A\n-t\n-F\n/, 'psql disables startup files and prompts');
like($args, qr/\nON_ERROR_STOP=1\n/, 'PostgreSQL stops on query failure');
like($args, qr/\nPGSSLMODE=verify-full\n/, 'TLS verify-full overrides weak setting');
like($args, qr/\nPGCONNECT_TIMEOUT=7\n/, 'PostgreSQL connect timeout bounded');
unlike($args, qr/do-not-pass/, 'obsolete plaintext MySQL env not forwarded');
like($args, qr/\n-c\nSELECT CASE WHEN pg_has_role\(current_user, 'pg_read_all_stats', 'USAGE'\)/,
    'fixed SQL includes role privilege gate');
like($args, qr/backend_type = 'client backend'/, 'exclude background PostgreSQL tasks');
($rc, $out) = mock_run('--engine', 'postgresql','--null');
is($rc, 0, 'PostgreSQL --null succeeds');
is($out, join("\0", qw(postgresql cluster 8 1 1000)) . "\0", 'PostgreSQL exact NUL record');
($rc, $out, $err) = do { local $ENV{SASD_DB_TEST_MODE} = 'denied'; mock_run('--engine', 'postgresql') };
is($rc, 1, 'PostgreSQL without stats role explicitly fails');
is($out, '', 'no incomplete PostgreSQL counts emitted');
like($err, qr/pg_read_all_stats/, 'diagnostic documents minimum role');

($rc, $out, $err) = mock_run('--engine','mysql','--host','db.example.org','--port','3306','--user','reader');
is($rc, 0, 'MySQL server-wide counters succeed');
is($out, "ENGINE\tSCOPE\tCONNECTIONS\tACTIVE\tUPTIME_SECONDS\nmysql\tserver\t8\t1\t1000\n", 'MySQL stable output');
is($err, '', 'successful MySQL has no diagnostic');
$args = trace();
like($args, qr/\A--no-defaults\n/, 'ignore plaintext defaults without explicit file');
like($args, qr/\n--protocol=TCP\n--host=db\.example\.org\n--ssl-mode=VERIFY_IDENTITY\n/,
    'remote MySQL forces TCP with hostname-verified TLS');
like($args, qr/\n--execute\nSHOW GLOBAL STATUS WHERE Variable_name IN \('Threads_connected', 'Threads_running', 'Uptime'\)\n/,
    'only narrow fixed MySQL status query');
($rc, $out) = mock_run('--engine', 'mariadb', '--host', 'db.example.org');
is($rc, 0, 'MariaDB remote query succeeds');
$args = trace();
like($args, qr/\n--ssl\n--ssl-verify-server-cert\n/, 'remote MariaDB verifies server certificate');
($rc, $out) = mock_run('--engine','mariadb','--null');
is($rc, 0, 'MariaDB local --null succeeds');
is($out, join("\0", qw(mariadb server 8 1 1000)) . "\0", 'MariaDB exact NUL fields');
$args = trace();
like($args, qr/\n--protocol=SOCKET\n--host=localhost\n/, 'no implicit remote TCP target');

my $config = "$tmp/config settings.cnf";
open my $cf, '>', $config or die $!;
print {$cf} "[client]\nuser=readonly\npassword=sensitive_secret\nssl-ca=/etc/ssl/certs/ca.pem\n";
close $cf or die $!;
chmod 0600, $config or die $!;
($rc) = mock_run('--engine','mariadb','--defaults-file',$config);
is($rc, 0, 'private MariaDB option file works');
$args = trace();
like($args, qr/\A--defaults-file=\Q$config\E\n/, 'defaults-file is first native option');
unlike($args, qr/sensitive_secret/, 'password not added to process arguments');
chmod 0644, $config or die $!;
($rc) = mock_run('--engine','mariadb','--defaults-file',$config);
is($rc, 3, 'reject world-readable credential file');
chmod 0600, $config or die $!;
symlink($config, "$tmp/conf-link") or die $!;
($rc) = mock_run('--engine','mysql','--defaults-file',"$tmp/conf-link");
is($rc, 3, 'reject credential symlinks');
for my $evil (
    "[client]\ninit-command=DELETE FROM accounts\n",
    "!include /tmp/untrusted.cnf\n",
    "[client]\nhost=other.example.org\n",
    "[server]\npassword=sensitive_secret\n",
) {
    open $cf, '>', $config or die $!;
    print {$cf} $evil;
    close $cf;
    ($rc, $out, $err) = mock_run('--engine','mariadb','--defaults-file',$config);
    is($rc, 3, 'unsafe option file refused');
    is($out, '', 'unsafe option file produced no false success');
    unlike($err, qr/sensitive_secret|DELETE FROM/, 'unsafe option content not leaked');
}
for my $case (
    ['failure', 1, 'native failure'],
    ['overflow_stdout', 3, 'huge stdout'],
    ['overflow_stderr', 3, 'huge stderr'],
    ['mysql_missing', 3, 'missing status'],
    ['mysql_dup', 3, 'duplicate status'],
    ['mysql_unknown', 3, 'unknown status'],
    ['mysql_negative', 3, 'negative status'],
    ['mysql_controls', 3, 'terminal control status'],
    ['mysql_many', 3, 'extra status'],
    ['mysql_blank', 3, 'empty status'],
) {
    local $ENV{SASD_DB_TEST_MODE} = $case->[0];
    ($rc, $out, $err) = mock_run('--engine','mariadb');
    is($rc, $case->[1], "$case->[2] yields intended exit status");
    is($out, '', "$case->[2] produces no success table");
    unlike($err, qr/hunter2|SECRET/, "$case->[2] does not expose client diagnostics");
}
for my $case (qw(pg_extra pg_columns pg_controls pg_empty pg_invalid_flag)) {
    local $ENV{SASD_DB_TEST_MODE} = $case;
    ($rc, $out, $err) = mock_run('--engine','postgresql');
    is($rc, 3, "$case rejects malformed PostgreSQL output");
    is($out, '', "$case emits no partial output");
}
{
    local $ENV{SASD_DB_TEST_MODE} = 'timeout';
    ($rc, $out) = mock_run('--engine','mysql','--timeout','1');
    is($rc, 3, 'hung native client terminated');
    is($out, '', 'hung native client emits no partial output');
}
done_testing();
