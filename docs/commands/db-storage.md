# db-storage – Read-only database and table storage inventory (M5.4)

[Deutsch](db-storage.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/db-storage.1) · [Roadmap](../ROADMAP.md)

`db-storage` reports **visible base-table metadata for one explicitly selected database** from `information_schema.TABLES`. M5.4 implements MariaDB (development reference: 10.11) and MySQL 8.x. PostgreSQL, Oracle and Microsoft SQL Server are **not yet implemented**. It runs one fixed read-only `SELECT` via the native `mariadb` or `mysql` CLI, without CPAN dependencies. The command never creates or changes databases, tables, roles or rows.

## Usage

```sh
./bin/db-storage --engine mariadb --database sasd_storage_lab \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"

./bin/db-storage --engine mariadb --database sasd_storage_lab \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf" \
  --limit 10 --sort-by index

./bin/db-storage --engine mysql --database appdb --host db.example.org \
  --user reader --defaults-file "$HOME/.config/sasd/mysql-storage.cnf"
```

Both `--engine mariadb|mysql` and `--database NAME` are mandatory. Database names intentionally use a restricted simple-identifier syntax. `--limit 1..100` sets the number of top tables (default `20`). `--sort-by total|data|index|free` picks the sort order (default `total`). Connection options follow the existing secure SQL tools: `--host`, `--port`, `--user`, `--timeout 1..30`, absolute `--client`, and a private `--defaults-file`. `--null` emits exactly eleven NUL-terminated fields per record and no header.

## Reading results

The report begins with a mandatory `TOTAL` row, followed by up to N `TABLE` rows. Columns are `ENGINE`, `SCOPE`, `KIND`, `NAME`, `STORAGE_ENGINE`, `TABLES`, `DATA_BYTES`, `INDEX_BYTES`, `TOTAL_BYTES`, `FREE_BYTES`, `UNKNOWN`.

- `SCOPE=visible`: only metadata visible to this database account, **not a server-wide inventory**. An empty result does not prove a database has no tables.
- `TOTAL`: reported sizes summed over **all visible base tables**, independently of the top-N limit. Views are excluded. `TABLE`: up to N tables ordered by the selected metric. The report explicitly states the visible table count.
- `DATA_BYTES`/`INDEX_BYTES`: server-reported `DATA_LENGTH` and `INDEX_LENGTH`. `TOTAL_BYTES` adds both using exact integer arithmetic. `FREE_BYTES` is `DATA_FREE`, **not filesystem free space**.
- `UNKNOWN`: count of visible tables with at least one NULL data/index/free-size field. NULL components contribute zero to the displayed sum but are explicitly marked incomplete. Exit code **1**, including in `--null` mode, prevents consumers from treating such totals as complete.
- InnoDB statistics may be estimates or allocated pages, and free-space figures for a shared tablespace can be double-counted. Binary logs, redo/undo logs, temporary files and filesystem overhead are not included. A single snapshot cannot determine storage growth.

Use `MiB = bytes / 1048576` and `GiB = bytes / 1073741824`; for example, GNU `numfmt --to=iec-i --suffix=B 49152` can assist outside the program.

## Minimal privileges and Debian/WSL smoke test

The existing `sasd_probe` account with only `USAGE` has **no table-reading permissions**. An administrator can create a dedicated disposable test database and grant SELECT only there. The following statements **do modify that test database**; they are manual setup, not executed by `db-storage`:

```sql
CREATE DATABASE sasd_storage_lab;
CREATE TABLE sasd_storage_lab.sample (
    id INT NOT NULL PRIMARY KEY,
    description VARCHAR(100) NOT NULL
) ENGINE=InnoDB;
INSERT INTO sasd_storage_lab.sample (id, description) VALUES (1, 'Storage-Test');
GRANT SELECT ON sasd_storage_lab.* TO 'sasd_probe'@'localhost';
SHOW GRANTS FOR 'sasd_probe'@'localhost';
```

Then run unprivileged:

```sh
./bin/db-storage --engine mariadb --database sasd_storage_lab \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"
echo "Status: $?"
```

Optional cleanup, **only when this schema was created specifically for the test and contains no important pre-existing data**:

```sql
REVOKE SELECT ON sasd_storage_lab.* FROM 'sasd_probe'@'localhost';
DROP DATABASE sasd_storage_lab;
```

On production systems use an existing approved database and carefully scoped table-reading rights instead. The server may restrict `information_schema` visibility by effective object privileges. A zero-table report is not proof of an empty database.

## Safety and failure handling

A MySQL/MariaDB credentials file must be an absolute regular file (not a symlink), private mode `0600`, with only allow-listed authentication/TLS keys in `[client]`. Never pass passwords on the command line or commit them to Git. Local connections force a Unix socket. Explicit TCP connections require verified server certificates (`VERIFY_IDENTITY` for MySQL, `--ssl-verify-server-cert` for MariaDB); unsupported clients fail closed. Raw native-client stderr is suppressed because it may contain secrets. Fixed metadata SQL does not include user-supplied identifiers and never uses `ANALYZE TABLE` or any modifying operation. Database catalog scans may still require resources on a large server.

| Exit | Meaning |
| --- | --- |
| `0` | Valid, complete visible metadata (possibly zero visible tables) |
| `1` | Database/privilege error or incomplete NULL size metrics |
| `2` | Invalid invocation or unsupported engine |
| `3` | Native client missing, timeout, excessive or malformed output |

Offline regression tests: `prove tests/test_db_storage.t`; full suite: `make test`.

References: [MariaDB INFORMATION_SCHEMA.TABLES](https://mariadb.com/docs/server/reference/system-tables/information-schema/information-schema-tables/information-schema-tables-table), [MySQL INFORMATION_SCHEMA.TABLES](https://dev.mysql.com/doc/refman/8.4/en/information-schema-tables-table.html).
