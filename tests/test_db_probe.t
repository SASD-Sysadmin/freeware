#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# M5.1 is tested against isolated native-client doubles. No database server,
# account, credentials or network connection is required for this suite.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $bin = File::Spec->rel2abs("$FindBin::Bin/../bin/db-probe");
my $tmp = tempdir('sasd-db-probe-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $mock = "$tmp/mock client";   # Embedded space tests argv-safe exec.
open my $fh, '>', $mock or die $!;
print {$fh} <<'MOCK';
#!/usr/bin/env perl
use strict;
use warnings;
if (defined $ENV{SASD_DB_TEST_ARGS}) {
    open my $out, '>', $ENV{SASD_DB_TEST_ARGS} or die $!;
    print {$out} join("\n", @ARGV), "\nPGSSLMODE=", ($ENV{PGSSLMODE} // ''),
        "\nPGCONNECT_TIMEOUT=", ($ENV{PGCONNECT_TIMEOUT} // ''),
        "\nMYSQL_PWD=", ($ENV{MYSQL_PWD} // '<absent>'), "\n";
    close $out or die $!;
}
my $mode = $ENV{SASD_DB_TEST_MODE} // 'good';
if ($mode eq 'failure') {
    print STDERR "sensitive secret password=not-for-logs\n";
    exit 9;
}
if ($mode eq 'timeout') { sleep 12; exit 0; }
if ($mode eq 'many') { print "db\tuser\t1\nDB2\tuser\t2\n"; exit 0; }
if ($mode eq 'columns') { print "db\tuser\n"; exit 0; }
if ($mode eq 'empty') { exit 0; }
if ($mode eq 'control') { print "db\tuser\tbad\033[31m\n"; exit 0; }
if ($mode eq 'oversize') { print 'X' x 20000; exit 0; }
if ($mode eq 'stderr-oversize') { print STDERR 'secret' x 5000; exit 0; }
print "catalog\treadonly_user\t16.4\n";
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
sub mock_cli {
    my (@args) = @_;
    return cli('--client', $mock, @args);
}
sub args_read {
    my $record = "$tmp/argv-record";
    open my $in, '<', $record or die $!;
    local $/;
    my $data = <$in>;
    close $in;
    return $data;
}
my ($rc, $out, $err);
($rc, $out, $err) = cli('--help');
is($rc, 0, 'help returns success');
like($out, qr/\AUsage: db-probe/, 'help has usage');
is($err, '', 'help has no stderr');
($rc, $out, $err) = cli('--version');
is($rc, 0, 'version returns success');
is($out, "db-probe 0.1.0\n", 'version has stable shape');
is($err, '', 'version has no stderr');
for my $opts (
    [], ['--engine', 'oracle'], ['--engine','postgresql','--port','123'],
    ['--engine','postgresql','--timeout','0'],
    ['--engine','mysql','--port','65536','--host','127.0.0.1'],
    ['--engine','mysql','--host','--init-command=DELETE'],
    ['--engine','mysql','--host','mysql://name:secret@host'],
    ['--engine','mysql','--user',"foo\nbar"],
    ['--engine','mysql','--database','-help'],
    ['--engine','postgresql','--database','postgresql://db.example.org/test?sslmode=disable'],
    ['--engine','postgresql','--database','dbname=admin;sslmode=disable'],
    ['--engine','mysql','--unknown-option'],
    ['--engine','mysql','--defaults-file',"$tmp/missing",'--client', $mock],
) {
    ($rc) = cli(@$opts);
    ok($rc == 2 || $rc == 3, 'invalid arguments/prerequisites are rejected');
}
($rc, $out, $err) = cli('--engine','postgresql','--client','relative/path');
is($rc, 3, 'relative client path rejected');

my $record = "$tmp/argv-record";
local $ENV{SASD_DB_TEST_ARGS} = $record;
local $ENV{SASD_DB_TEST_MODE} = 'good';
local $ENV{PGSSLMODE} = 'disable';
local $ENV{PGCONNECT_TIMEOUT} = '100';
local $ENV{MYSQL_PWD} = 'do-not-forward';
($rc, $out, $err) = mock_cli('--engine', 'postgresql', '--host', 'db.example.org',
    '--port','5432','--user','reader','--database','example','--timeout','7');
is($rc, 0, 'PostgreSQL probe succeeds');
is($out, "ENGINE\tDATABASE\tDB_USER\tVERSION\npostgresql\tcatalog\treadonly_user\t16.4\n", 'table is deterministic');
is($err, '', 'successful probe has clean stderr');
my $argv = args_read();
like($argv, qr/\A-X\n/, 'psql no startup script');
like($argv, qr/\n-w\n/, 'psql forbids interactive password prompts');
like($argv, qr/\n-v\nON_ERROR_STOP=1\n/, 'psql treats SQL errors as failures');
like($argv, qr/\nPGSSLMODE=verify-full\n/, 'TLS verify-full overrides insecure environment');
like($argv, qr/\nPGCONNECT_TIMEOUT=7\n/, 'connection timeout constrained');
unlike($argv, qr/do-not-forward/, 'obsolete MySQL password environment removed');
like($argv, qr/\n-c\nSELECT current_database\(\), current_user, current_setting\('server_version'\)\n/,
    'only fixed PostgreSQL SQL is sent');
($rc, $out) = mock_cli('--engine','postgresql','--null');
is($rc, 0, 'NUL variant exits zero');
is($out, join("\0", qw(postgresql catalog readonly_user 16.4)) . "\0", 'exact four NUL fields');

($rc, $out) = mock_cli('--engine','mysql','--host','db.example.org','--port','3306',
    '--user','reader','--database','catalog');
is($rc, 0, 'MySQL TCP probe succeeds');
$argv = args_read();
like($argv, qr/\A--no-defaults\n/, 'without config MySQL ignores plaintext defaults');
like($argv, qr/\n--protocol=TCP\n--host=db.example.org\n/, 'MySQL remote TCP explicit');
like($argv, qr/\n--ssl-mode=VERIFY_IDENTITY\n/, 'MySQL remote identity verification required');
like($argv, qr/\n--execute\nSELECT COALESCE\(DATABASE\(\), '<none>'\), CURRENT_USER\(\), VERSION\(\)\n/,
    'only fixed MySQL SQL sent');
($rc, $out) = mock_cli('--engine','mariadb','--host','db.example.org');
is($rc, 0, 'MariaDB TCP probe succeeds');
$argv = args_read();
like($argv, qr/\n--ssl\n--ssl-verify-server-cert\n/, 'MariaDB verifies server certificate');
($rc, $out) = mock_cli('--engine','mysql');
is($rc, 0, 'local MySQL socket mode succeeds');
$argv = args_read();
like($argv, qr/\n--protocol=SOCKET\n--host=localhost\n/, 'local socket prevents hidden remote host defaults');
unlike($argv, qr/--ssl-mode=VERIFY_IDENTITY/, 'local socket needs no network TLS');

my $config = "$tmp/mysql client.conf";
open my $cf, '>', $config or die $!;
print {$cf} "[client]\nuser=reader\npassword=topsecret\nssl-ca=/etc/ssl/certs/ca.pem\n";
close $cf or die $!;
chmod 0600, $config or die $!;
($rc) = mock_cli('--engine','mysql','--defaults-file',$config,'--host','db.example.org');
is($rc, 0, 'private MySQL option file accepted');
$argv = args_read();
like($argv, qr/\A--defaults-file=\Q$config\E\n/, 'defaults file is first client argument');
unlike($argv, qr/topsecret/, 'password contents never appear in argv');
chmod 0644, $config or die $!;
($rc) = mock_cli('--engine','mysql','--defaults-file',$config);
is($rc, 3, 'world-readable credential file rejected');
chmod 0600, $config or die $!;
my $link = "$tmp/config-symlink";
symlink($config, $link) or die $!;
($rc) = mock_cli('--engine','mysql','--defaults-file',$link);
is($rc, 3, 'credential file symlink rejected');
open $cf, '>', $config or die $!;
print {$cf} "[client]\npassword=topsecret\ninit-command=DROP TABLE users\n";
close $cf;
($rc, $out, $err) = mock_cli('--engine','mysql','--defaults-file',$config);
is($rc, 3, 'dangerous client initialization command rejected');
unlike($err, qr/topsecret|DROP TABLE/, 'client secret and forbidden statement not echoed');
open $cf, '>', $config or die $!;
print {$cf} "!include /etc/my.cnf\n";
close $cf;
($rc) = mock_cli('--engine','mysql','--defaults-file',$config);
is($rc, 3, 'external file includes rejected');
open $cf, '>', $config or die $!;
print {$cf} "[client]\npassword=topsecret\nhost=attacker.example\n";
close $cf;
($rc) = mock_cli('--engine','mysql','--defaults-file',$config);
is($rc, 3, 'credential file cannot override target host');

for my $test (
    ['failure', 1, 'native backend failure'],
    ['many', 3, 'multiple SQL rows'],
    ['columns', 3, 'malformed SQL columns'],
    ['empty', 3, 'empty SQL response'],
    ['control', 3, 'malicious control bytes'],
    ['oversize', 3, 'oversized stdout'],
    ['stderr-oversize', 3, 'oversized stderr'],
) {
    local $ENV{SASD_DB_TEST_MODE} = $test->[0];
    ($rc, $out, $err) = mock_cli('--engine','postgresql');
    is($rc, $test->[1], "$test->[2] uses expected status");
    is($out, '', "$test->[2] does not print misleading successful table");
    unlike($err, qr/not-for-logs|secret/, "$test->[2] never exposes raw client stderr");
}
{
    local $ENV{SASD_DB_TEST_MODE} = 'timeout';
    ($rc, $out, $err) = mock_cli('--engine','postgresql','--timeout','1');
    is($rc, 3, 'hung backend is terminated after bounded wallclock time');
    is($out, '', 'hung backend has no incomplete success table');
}
done_testing();
