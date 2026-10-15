# db-probe – Read-only SQL connection and identity probe (M5.1)

[Deutsch](db-probe.de.md) · [Project](../../README.md) · [Manpage](../../man/man1/db-probe.1) · [Roadmap](../ROADMAP.md)

`db-probe` executes **one fixed read-only SQL query** using the native database
client. It reports the database, effective SQL identity and server version.
A reachable TCP port alone does **not** count as a successful SQL probe.

## Engines and clients

| Engine | Client | Fixed identity query |
| --- | --- | --- |
| `postgresql` | `psql` | `current_database()`, `current_user`, `current_setting('server_version')` |
| `mysql` | `mysql` | `DATABASE()`, `CURRENT_USER()`, `VERSION()` |
| `mariadb` | `mariadb` | `DATABASE()`, `CURRENT_USER()`, `VERSION()` |

Oracle and Microsoft SQL Server remain planned for M5, not implemented in
M5.1. The CLI explicitly rejects unsupported engines.

## Usage

```sh
./bin/db-probe --engine postgresql --database postgres
./bin/db-probe --engine postgresql --host db.example.org --port 5432 \
    --user db_reader --database reporting --timeout 8
./bin/db-probe --engine mariadb
./bin/db-probe --engine mysql --host mysql.example.org --port 3306 \
    --defaults-file "$HOME/.config/sasd/mysql-client.cnf" --database reporting
./bin/db-probe --engine postgresql --client /opt/homebrew/opt/libpq/bin/psql
./bin/db-probe --engine postgresql --null > db-probe.bin
```

Human output has `ENGINE`, `DATABASE`, `DB_USER` and `VERSION`. `DB_USER`
is the identity reported by the server (possibly different from `--user`).
`--null` emits the four fields terminated with NUL, without a header.

## Create and modify a test user (MySQL/MariaDB)

A local Debian/WSL smoke test requires only **`USAGE`** (no table-level
privileges). Create the dedicated account as a SQL administrator; run
`db-probe` itself **without** database `root` privileges.

```sh
mysql -u root -p
```

```sql
-- Create a local account for Unix-socket authentication:
CREATE USER 'sasd_probe'@'localhost'
    IDENTIFIED BY 'USE_A_UNIQUE_LOCAL_TEST_PASSWORD';

-- For an existing account, change its password instead of creating it again:
ALTER USER 'sasd_probe'@'localhost'
    IDENTIFIED BY 'USE_ANOTHER_LOCAL_TEST_PASSWORD';

-- USAGE is enough for M5.1:
SHOW GRANTS FOR 'sasd_probe'@'localhost';
```

Run `CREATE USER` only once; use `ALTER USER` for subsequent password
changes. Passwords above are placeholders. Ordinary `CREATE USER` and
`ALTER USER` statements do **not** need `FLUSH PRIVILEGES`. For later
administrative diagnostics, grant only the permissions actually required,
not blanket `ALL PRIVILEGES`.

Create a private client configuration file, with no extra options:

```sh
mkdir -p -m 700 "$HOME/.config/sasd"
umask 077
# Do not truncate an existing credential file:
test -e "$HOME/.config/sasd/mysql-probe.cnf" ||
    touch "$HOME/.config/sasd/mysql-probe.cnf"
chmod 600 "$HOME/.config/sasd/mysql-probe.cnf"
${EDITOR:-vi} "$HOME/.config/sasd/mysql-probe.cnf"
```

```ini
[client]
user=sasd_probe
password=PASSWORD_FROM_CREATE_OR_ALTER_USER
```

Verify the restricted account over the local Unix socket:

```sh
./bin/db-probe --engine mariadb \
    --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"
```

The reported `DB_USER` should be `sasd_probe@localhost`. Running the
identity query beforehand as `root` does **not** validate the restricted
account. A different server/host setup needs an account with the
corresponding `@host` qualifier; `--host` forces TCP with certificate
verification.

## Authentication, TLS and safety

- **Never pass passwords on the command line.** This program deliberately has
  no `--password` or free-form `--sql` option. PostgreSQL uses native libpq
  authentication (`~/.pgpass`, `PGPASSFILE`, sockets, etc.); `-w` disables
  interactive prompts. Missing credentials cause failure.
- MySQL and MariaDB either start with `--no-defaults` or, with
  `--defaults-file ABSOLUTE_PATH`, start with the specified config file.
  The file must be a non-symlink regular file with permission mode 0600.
  Only `[client]` values `user`, `password`, `ssl-ca`, `ssl-capath`, `ssl-cert`,
  `ssl-key`, `ssl-cipher`, `ssl-crl`, `ssl-crlpath` are allowed. Settings such
  as `init-command`, `host`, extra sections and `!include` are rejected.
- Remote PostgreSQL forces `PGSSLMODE=verify-full`; MySQL forces
  `--ssl-mode=VERIFY_IDENTITY`; MariaDB forces `--ssl --ssl-verify-server-cert`.
  Configure trusted CA certificates and correct hostnames. A client lacking
  these capabilities must fail instead of downgrading TLS. There is no
  insecure override flag.
- Without `--host`, MySQL and MariaDB explicitly use a local Unix socket;
  with `--host`, they use TCP and enforce certificate validation. MySQL may
  still load `.mylogin.cnf` when `--no-defaults` is used; manage it securely.
  The tool removes inherited `MYSQL_PWD` from the native client's environment.
- Use a **least-privilege read-only SQL account** and a trusted native client.
  The command itself issues one SELECT, but server access can still create
  server-side connection/audit log records.

## Reliability and error classification

The subprocess receives argv directly without a shell or password prompt.
Overall elapsed time is bounded to `--timeout` + five seconds; stdout and
stderr are each limited to 16 KiB. Client stderr is never passed through:
it can contain private connection details. Empty, malformed, extra-row and
control-character results are not mistaken for success. Safeguard collected
reports because database names and versions are operational metadata.

| Exit | Meaning |
| --- | --- |
| `0` | The SQL client produced exactly one valid identity/version record |
| `1` | Database connection, authentication or read-only query failed |
| `2` | Invalid invocation or unsupported engine |
| `3` | Missing client, unsafe config, timeout or malformed client output |

Tests use only offline native-client stand-ins. A successful fixture test does
not establish that any production or test server is reachable or that TLS
and authentication work end to end. Linux/macOS, Perl 5 core modules only.
