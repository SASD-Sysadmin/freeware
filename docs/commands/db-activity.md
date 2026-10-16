# db-activity – read-only SQL activity and lock hints (M5.3)

[Deutsch](db-activity.de.md) · [Project](../../README.md) · [Manual](../../man/man1/db-activity.1) · [Roadmap](../ROADMAP.md)

`db-activity` collects a **bounded, read-only snapshot** of visible sessions
from PostgreSQL (10+), MySQL 8.x and MariaDB (including 10.11). It executes
fixed `SELECT` SQL through native command-line clients. It never fetches
SQL statement text or client IP addresses and cannot kill/cancel sessions,
release locks or change the database.

## Usage

```sh
./bin/db-activity --engine mariadb \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"

./bin/db-activity --engine mariadb \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf" \
  --min-seconds 5 --limit 30 --include-idle

./bin/db-activity --engine postgresql --database postgres \
  --user sasd_activity --min-seconds 10
```

Connection options: `--engine postgresql|mysql|mariadb`, `--host`, `--port`,
`--database`, `--user`, `--timeout 1..30`, `--client ABSOLUTE_PATH`,
`--defaults-file ABSOLUTE_PATH` (MySQL/MariaDB only).

| Option | Description |
| --- | --- |
| `--min-seconds 0..86400` | Only include sessions whose reported current activity/state age is at least this duration (default `0`). |
| `--limit 1..100` | Maximum printed sessions, default `25`; query asks for one extra row to detect truncation. |
| `--include-idle` | Include PostgreSQL `idle` and MySQL/MariaDB `Sleep` sessions. |
| `--null` | Ten NUL-delimited fields per session; no headings or comments. |

Columns: `ENGINE`, `SCOPE`, `SESSION_ID`, `DB_USER`, `DATABASE`, `STATE`,
`SECONDS`, `WAIT`, `LOCK_STATUS`, `BLOCKERS`. Values are a *momentary* sample.
The probing connection itself is excluded. A successful **empty** result does
not prove that the entire database server has no activity.

### Interpretation

**SCOPE** is `cluster` for PostgreSQL after checking full monitoring rights,
or `visible` for MySQL/MariaDB, where an unprivileged account sees only its
own sessions. **SECONDS** is MySQL/MariaDB `PROCESSLIST.TIME`, i.e. current
command/state age. For PostgreSQL it is query age when active, otherwise age
since the current state began. These metrics are not directly equivalent.

**WAIT** gives PostgreSQL `wait_event_type:wait_event` or MySQL/MariaDB
`PROCESSLIST.STATE`; `<none>` means no wait string reported. **LOCK_STATUS**
is `blocked` only when PostgreSQL `pg_blocking_pids()` identifies at least one
blocker, `waiting` if a PostgreSQL lock wait has zero reported blockers, and
`none` otherwise. MySQL/MariaDB report `possible` from textual hints such as
"Waiting for ... lock", or `unknown` otherwise: **never a confirmed blocker**.
**BLOCKERS** is the PostgreSQL count; `?` on MySQL/MariaDB. A long-running
session is not necessarily bad. Sleeping sessions may hold open transactions;
use `--include-idle` for investigations involving suspected blockers.

### Minimum permissions and user setup

**MariaDB/MySQL:** a normal login with `USAGE` is enough to inspect its *own*
sessions. An existing local `sasd_probe` account from M5.1 can be reused.

```sql
CREATE USER 'sasd_probe'@'localhost' IDENTIFIED BY 'EXAMPLE_PASSWORD';
ALTER USER 'sasd_probe'@'localhost' IDENTIFIED BY 'NEW_EXAMPLE_PASSWORD';
SHOW GRANTS FOR 'sasd_probe'@'localhost';
-- Optional broader process visibility, granted by an administrator:
GRANT PROCESS ON *.* TO 'sasd_probe'@'localhost';
-- Remove this optional grant when no longer needed:
REVOKE PROCESS ON *.* FROM 'sasd_probe'@'localhost';
```

`CREATE USER` is needed only if the account does not already exist. `PROCESS`
**is not required** for the default limited view and grants broader visibility
in other clients than `db-activity` exposes. For credentials, use a regular
non-symlink client configuration file with private permissions:

```ini
[client]
user=sasd_probe
password=EXAMPLE_PASSWORD
```

```sh
chmod 600 "$HOME/.config/sasd/mysql-probe.cnf"
./bin/db-activity --engine mariadb \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"
```

Unsafe client options such as `init-command`, `!include`, embedded host
settings and SSL downgrade flags are rejected. Passwords are never accepted
in argv. Explicit MySQL TCP requires TLS identity verification; MariaDB TCP
requires verified server certificates. MySQL has deprecated
`INFORMATION_SCHEMA.PROCESSLIST`; a future adapter may be necessary.

**PostgreSQL:** `pg_read_all_stats` (or superuser) is required to avoid
misleading partially visible activity. An administrator may use:

```sql
CREATE ROLE sasd_activity LOGIN PASSWORD 'EXAMPLE_PASSWORD';
GRANT pg_read_all_stats TO sasd_activity;
-- Later: REVOKE pg_read_all_stats FROM sasd_activity;
```

The role must have `CONNECT` access to the target database. This PostgreSQL
role exposes more activity data to other clients than our command selects,
so approve its use explicitly. Use an existing password method (`.pgpass`,
`PGPASSFILE` or local socket authentication), not password argv. Explicit
PostgreSQL TCP enforces `verify-full` TLS.

### Completeness, exits and tests

The server selects at most `--limit + 1` rows. If an extra row exists,
output is capped at `--limit` and the **exit status is `1`**, including
`--null`. Consumers must check status before treating the result as complete.
The command reports no detailed MySQL blocker relationships, does no
transaction graph/deadlock analysis and does not continuously sample activity.

| Code | Meaning |
| --- | --- |
| `0` | Complete read (possibly no visible matches) |
| `1` | Query/permission error **or** truncated snapshot |
| `2` | Invalid arguments |
| `3` | Missing client, timeout, malformed or oversized native output |

```sh
prove tests/test_db_activity.t
make test
```

Tests use offline native-client doubles, never real accounts. For an *optional
local-only* integration check, execute `SELECT SLEEP(15)` in another MariaDB
session of the same user while running `db-activity` in a second shell. This
creates temporary database workload; do not run it on production systems.

References: [PostgreSQL stats](https://www.postgresql.org/docs/current/monitoring-stats.html),
[pg_blocking_pids](https://www.postgresql.org/docs/current/functions-info.html),
[MariaDB PROCESSLIST](https://mariadb.com/docs/server/reference/system-tables/information-schema/information-schema-tables/information-schema-processlist-table),
[MySQL process access](https://dev.mysql.com/doc/refman/8.4/en/processlist-access.html).
