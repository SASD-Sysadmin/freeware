#!/usr/bin/env perl
# SPDX-License-Identifier: MIT
# No real user, authentication event, log or privileged service is changed.
# All history is synthetic; tests require only Perl core modules.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $root = File::Spec->rel2abs("$FindBin::Bin/..");
my $tool = File::Spec->catfile($root, 'bin', 'login-audit');
my $tmp = tempdir('sasd-login-audit-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
sub write_file {
    my ($path, $value) = @_;
    open my $fh, '>', $path or die "cannot create fixture $path: $!";
    print {$fh} $value;
    close $fh or die "cannot close fixture $path: $!";
}
sub call_tool {
    my (@args) = @_;
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, $^X, $tool, @args);
    close $in;
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    close $out;
    close $err;
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}
my $success = "$tmp/last.txt";
my $failed = "$tmp/lastb.txt";
write_file($success,
    "alice pts/1 192.0.2.10 2026-10-14T09:01:00+02:00 - 2026-10-14T09:02:00+02:00 (00:01)\n" .
    "bob console 2026-10-14T08:40:00Z - still logged in\n" .
    "reboot system boot 6.1.0 2026-10-14T08:00:00Z - still running\n" .
    "wtmp begins 2026-10-01T00:00:00Z\n");
write_file($failed,
    "alice ssh:notty 198.51.100.9 2026-10-14T09:04:00+02:00 - 2026-10-14T09:04:00+02:00 (00:00)\n" .
    "carol pts/4 203.0.113.2 2026-10-13T20:00:00Z - 2026-10-13T20:00:00Z (00:00)\n" .
    "btmp begins 2026-10-01T00:00:00Z\n");
my ($rc, $out, $err);
($rc, $out, $err) = call_tool('--help');
is($rc,0,'help returns zero');
like($out, qr/^Usage: login-audit/, 'help is informative');
is($err,'','help has clean stderr');
($rc,$out,$err) = call_tool('--version');
is($rc,0,'version returns zero');
is($out,"login-audit 0.1.0\n",'version adheres to repository CLI contract');
is($err,'','version has clean stderr');
for my $args (
    ['--bogus'], ['--kind','invalid'], ['--limit','0'],
    ['--limit','1001'], ['--limit','1.5'], ['--user','bad name'],
    ['--user',''], ['--kind','failed','--input-success',$success],
    ['--kind','success','--input-failed',$failed],
    ['--kind','both','--input-success',$success],
    ['--kind','both','--input-failed',$failed],
) {
    ($rc) = call_tool(@$args);
    is($rc,2,'invalid arguments rejected: '.join(' ',@$args));
}
($rc,$out,$err) = call_tool('--kind','both','--input-success',$success,'--input-failed',$failed);
is($rc,0,'both fixture sources accepted');
like($out,qr/^KIND\tUSER\tTTY\tHOST\tLOGIN\tDETAILS\n/,'stable output header');
like($out,qr/success\talice\tpts\/1\t192\.0\.2\.10\t2026-10-14T09:01:00\+02:00/,'successful remote login parsed');
like($out,qr/success\tbob\tconsole\t\t2026-10-14T08:40:00Z/,'console login without host parsed');
like($out,qr/failed\talice\tssh:notty\t198\.51\.100\.9/,'failed login preserved');
unlike($out,qr/^success\treboot/m,'reboot marker excluded');
unlike($out,qr/wtmp begins/,'wtmp footer ignored');
like($out,qr/Matching: 4\nShown: 4\nSuccessful: 2\nFailed: 2\nSources: success,failed\n\z/,'source totals explicit');
is($err,'','well-formed fixture has no diagnostics');
($rc,$out) = call_tool('--kind','success','--input-success',$success,'--user','alice');
is($rc,0,'successful user filter works');
like($out,qr/Matching: 1\nShown: 1/,'filter matching count');
unlike($out,qr/\tbob\t/,'user filter excludes others');
($rc,$out) = call_tool('--kind','failed','--input-failed',$failed,'--user','nobody');
is($rc,0,'no matching user is not a parser error');
like($out,qr/Matching: 0\nShown: 0\nSuccessful: 0\nFailed: 0/,'zero observations explicit');
($rc,$out) = call_tool('--kind','both','--input-success',$success,'--input-failed',$failed,'--limit','1');
is($rc,0,'limit one accepted');
like($out,qr/Matching: 4\nShown: 1/,'matching versus shown not confused');
($rc,$out) = call_tool('--kind','success','--input-success',$success,'--null');
is($rc,0,'NUL mode works');
like($out,qr/success\x00alice\x00pts\/1\x00192\.0\.2\.10\x002026-10-14T09:01:00\+02:00\x00/,'six NUL terminated fields');
unlike($out,qr/^KIND\t|Matching: /,'NUL mode omits headings/totals');
my $broken = "$tmp/malformed.txt";
write_file($broken,
    "alice pts/1 192.0.2.10 2026-10-14T09:01:00+02:00 - (00:00)\n" .
    "wrong data\n" .
    "eve pts/0 192.0.2.8 2026-02-30T09:01:00Z - still logged in\n" .
    "frank pts/0 192.0.2.8 2024-02-29T09:01:00Z - still logged in\n");
($rc,$out,$err) = call_tool('--kind','success','--input-success',$broken);
is($rc,1,'malformed records produce finding status');
like($err,qr/skipped 2 malformed record/,'malformed count accurate');
like($out,qr/frank\tpts\/0/,'leap year date accepted');
unlike($out,qr/\teve\t/,'invalid calendar date rejected');
my $empty = "$tmp/empty";
write_file($empty,'');
($rc,$out) = call_tool('--kind','success','--input-success',$empty);
is($rc,0,'empty readable fixture can be parsed');
like($out,qr/Matching: 0/,'no matches reported for empty file');
($rc) = call_tool('--kind','success','--input-success',"$tmp/absent");
is($rc,3,'missing fixture produces missing-source code');
my $link = "$tmp/link";
symlink($success,$link) or die "cannot symlink fixture: $!";
($rc) = call_tool('--kind','success','--input-success',$link);
is($rc,3,'fixture symlink rejected');
($rc) = call_tool('--kind','success','--input-success',$tmp);
is($rc,3,'fixture directory rejected');
my $binary = "$tmp/binary.txt";
write_file($binary,"alice pts/1 192.0.2.10 2026-10-14T09:01:00Z - x\0\n");
($rc,$out,$err) = call_tool('--kind','success','--input-success',$binary);
is($rc,1,'NUL input detected');
like($err,qr/skipped 1 malformed/, 'binary line diagnostic');
# Never run the native backends in routine tests: host btmp permissions,
# occupancy and retention are nondeterministic. Metadata tests run offline.
SKIP: {
    skip 'native successful-login collection is intentionally not run in CI',1;
}
SKIP: {
    skip 'native failed-login collection is intentionally not run in CI',1;
}
done_testing();
