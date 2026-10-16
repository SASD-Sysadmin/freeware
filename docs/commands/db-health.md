# db-health – read-only SQL health snapshot (M5.2)

[Deutsch](db-health.de.md) · [Project](../../README.md) · [Manual](../../man/man1/db-health.1) · [Roadmap](../ROADMAP.md)

`db-health` runs exactly one **fixed read-only SQL statement** through a
locally installed `psql`, `mysql` or `mariadb` client. It reports a bounded
snapshot of client connections, active activity and server uptime. No CPAN
modules, arbitrary SQL, shell command, administrative changes or user passwords
on the command line are needed.

## Examples

```sh
# Local Debian/WSL MariaDB: Unix socket, no transport TLS required
./bin/db-health --engine mariadb \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"

# Explicit remote MySQL requires verified server identity
./bin/db-health --engine mysql --host db.example.org --port 3306 \
  --user sasd_probe --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"

# PostgreSQL using a libpq password file or PGPASSFILE
./bin/db-health --engine postgresql --host pg.example.org \
  --port 5432 --database postgres --user sasd_health

# Exactly five NUL-delimited machine fields
./bin/db-health --engine mariadb --null \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"
```

## Report and semantics

Columns are tab-separated `ENGINE`, `SCOPE`, `CONNECTIONS`, `ACTIVE`,
`UPTIME_SECONDS` (or exactly five NUL-delimited fields). A sample:

```text
ENGINE   SCOPE   CONNECTIONS   ACTIVE   UPTIME_SECONDS
mariadb  server  8             1        53001
```

| Field | MySQL / MariaDB | PostgreSQL |
| --- | --- | --- |
| `SCOPE` | `server` | `cluster` |
| `CONNECTIONS` | Global `Threads_connected` | Client backends in `pg_stat_activity` |
| `ACTIVE` | Global `Threads_running` (non-sleeping threads) | Client backends with `state='active'` |
| `UPTIME_SECONDS` | Global `Uptime` | Seconds since `pg_postmaster_start_time()` |

Activity definitions differ between engines, and the probe itself adds
activity. The metrics are an **instantaneous, non-atomic** snapshot, not an
assessment of healthy/unhealthy operation. Many connections do not
necessarily indicate a problem. This version intentionally does **not** expose
query texts, individual users, blocking chains, long queries, pool capacity,
history or alarm thresholds.

## Minimal MySQL/MariaDB permissions

`SHOW GLOBAL STATUS` needs no special database permissions (documented by
MySQL). The M5.1 `sasd_probe` account with `USAGE` is sufficient. An
administrator may create or modify this account in a *test environment*:

```sql
CREATE USER 'sasd_probe'@'localhost'
    IDENTIFIED BY 'CHOOSE_A_TEST_PASSWORD';
SHOW GRANTS FOR 'sasd_probe'@'localhost';

-- Change an existing test user's password:
ALTER USER 'sasd_probe'@'localhost'
    IDENTIFIED BY 'CHOOSE_A_NEW_PASSWORD';
```

Do not re-run `CREATE USER` when the account already exists. For the socket
example, put the credentials in a regular, non-symlink, private mode-0600 file:

```sh
mkdir -p -m 700 "$HOME/.config/sasd"
( umask 077; set -C; : > "$HOME/.config/sasd/mysql-probe.cnf" )
# Edit it to contain:
# [client]
# user=sasd_probe
# password=CHOOSE_A_TEST_PASSWORD
```

The creation command intentionally refuses to overwrite an existing file.
Use an editor for any subsequent changes.

## PostgreSQL permissions

PostgreSQL restricts other users' session state in `pg_stat_activity`. To
avoid misleading undercounts, `db-health` **requires** `pg_read_all_stats`
(or superuser privileges) for full cluster-wide activity reporting. A DBA
may explicitly grant this to a dedicated monitoring login:

```sql
CREATE ROLE sasd_health LOGIN PASSWORD 'CHOOSE_A_TEST_PASSWORD';
GRANT pg_read_all_stats TO sasd_health;
-- Allow CONNECT to the chosen database separately, if restricted.
```

This built-in role also grants visibility into **other sessions and their SQL
texts**. Treat it as a sensitive cross-database monitoring privilege; it is
not comparable to `USAGE`. For a simple version/connection check, use
`db-probe` instead. Requires PostgreSQL **10+** and an inherited effective
`pg_read_all_stats` privilege.

## Transport, safety and errors

- Explicit TCP destinations require server-identity-verified TLS:
  `--ssl-mode=VERIFY_IDENTITY` (MySQL), `--ssl --ssl-verify-server-cert`
  (MariaDB), `PGSSLMODE=verify-full` (PostgreSQL). Missing support or trust
  fails closed. Configure an appropriate CA and server certificate.
- Without a host, MySQL/MariaDB force the local Unix socket; PostgreSQL uses
  the local default connection and removes inherited target overrides.
- No arbitrary SQL, CLI passwords, client startup statements or TLS bypass.
  `MYSQL_PWD` is removed. MySQL option files must be mode 0600, non-symlink,
  ≤64 KiB, and contain only allowed `[client]` credential/TLS keys.
- Native clients are sought in fixed executable paths. An explicit absolute
  `--client` path is a deliberate trust decision. Child runtime and output
  are bounded; untrusted native stderr is discarded rather than leaking
  credentials or remote SQL contents. libpq can use `.pgpass` or `PGPASSFILE`.
- Inputs `--host`, `--port`, `--database`, `--user`, `--timeout`, `--null` and
  `--defaults-file` follow the M5.1 `db-probe` constraints.

| Exit | Meaning |
| --- | --- |
| `0` | Complete valid snapshot (not a health verdict) |
| `1` | Native query/connection failure, or PostgreSQL stats role unavailable |
| `2` | Invalid invocation |
| `3` | Missing prerequisite, timeout, unsafe config or malformed response |

Default tests use isolated client doubles, **not** running database servers.
Live PostgreSQL and MySQL integration must be tested explicitly with suitable
credentials and TLS setup; CI checks Linux and macOS fixture behavior.
