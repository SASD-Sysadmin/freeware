# db-probe – Lesende SQL-Verbindungs- und Identitätsprüfung (M5.1)

[English](db-probe.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/db-probe.1) · [Kapitelplanung](../ROADMAP.de.md)

`db-probe` prüft **eine echte SQL-Abfrage** über den installierten nativen
Datenbankclient. Es zeigt Datenbankname, tatsächlich verwendete SQL-Identität und
Serverversion an. Ein funktionierender TCP-Port allein gilt **nicht** als
funktionsfähige SQL-Verbindung. Es werden keine freien SQL-Befehle angenommen.

## Unterstützte Systeme

| Engine | Client | Feste Nur-Lese-Abfrage |
| --- | --- | --- |
| `postgresql` | `psql` | `current_database()`, `current_user`, `current_setting('server_version')` |
| `mysql` | `mysql` | `DATABASE()`, `CURRENT_USER()`, `VERSION()` |
| `mariadb` | `mariadb` | `DATABASE()`, `CURRENT_USER()`, `VERSION()` |

**Oracle und Microsoft SQL Server gehören zu M5, aber noch nicht zu M5.1.**
Für sie werden eigene Backends mit belastbaren CLI- und Authentifizierungsverträgen
benötigt; `--engine oracle` und `--engine sqlserver` werden derzeit abgewiesen.

## Beispiele

```sh
# PostgreSQL über lokale Standard-Socket-Authentifizierung oder libpq-Konfiguration
./bin/db-probe --engine postgresql --database postgres

# PostgreSQL über TCP; CA-Vertrauen z. B. über PGSSLROOTCERT festlegen
./bin/db-probe --engine postgresql --host db.example.org --port 5432 \
    --user db_reader --database reporting --timeout 8

# MariaDB über lokalen Unix-Socket, z. B. mit unix_socket-Authentifizierung
./bin/db-probe --engine mariadb

# MySQL über TCP mit privater Authentifizierungs- und CA-Datei
./bin/db-probe --engine mysql --host mysql.example.org --port 3306 \
    --defaults-file "$HOME/.config/sasd/mysql-client.cnf" --database reporting

# Alternative Clientinstallation ausdrücklich angeben
./bin/db-probe --engine postgresql --client /opt/homebrew/opt/libpq/bin/psql

# Maschinelle Ausgabe: vier NUL-terminierte Felder
./bin/db-probe --engine postgresql --null > db-probe.bin
```

Die Tabelle enthält `ENGINE`, `DATABASE`, `DB_USER` und `VERSION`. `DB_USER`
ist die von der Datenbank zurückgemeldete Identität, nicht zwingend der Wert von
`--user`. `--null` gibt vier NUL-terminierte Felder ohne Tabellenkopf aus.

## Testbenutzer anlegen und ändern (MySQL/MariaDB)

Für einen lokalen Test unter Debian/WSL genügt **`USAGE`** (keine zusätzlichen
Tabellenrechte). Ein SQL-Administrator legt das Konto einmalig an; `db-probe`
selbst wird anschließend **nicht** als Datenbank-`root` ausgeführt.

```sh
mysql -u root -p
```

```sql
-- Neues, nur lokal über den Unix-Socket benutztes Testkonto:
CREATE USER 'sasd_probe'@'localhost'
    IDENTIFIED BY 'EIN_NEUES_NUR_LOKAL_VERWENDETES_PASSWORT';

-- Bestehendes Konto: Passwort ändern (statt CREATE USER zu wiederholen):
ALTER USER 'sasd_probe'@'localhost'
    IDENTIFIED BY 'EIN_ANDERES_LOKALES_PASSWORT';

-- Kontoberechtigungen prüfen; USAGE ist für M5.1 ausreichend:
SHOW GRANTS FOR 'sasd_probe'@'localhost';
```

`CREATE USER` nur beim ersten Einrichten ausführen; existiert das Konto bereits,
für Passwortänderungen `ALTER USER` verwenden. Die beiden Beispielpasswörter
sind Platzhalter. Nach `CREATE USER` oder `ALTER USER` ist bei normaler
Benutzerverwaltung **kein `FLUSH PRIVILEGES`** nötig. Für spätere
Administrationswerkzeuge Rechte nur gezielt auf die wirklich benötigten
Objekte gewähren, nicht pauschal `ALL PRIVILEGES`.

Passende Clientdatei ohne andere Optionen oder Abschnitte anlegen:

```sh
mkdir -p -m 700 "$HOME/.config/sasd"
umask 077
# Vorhandene Datei beim erneuten Einrichten NICHT überschreiben:
test -e "$HOME/.config/sasd/mysql-probe.cnf" ||
    touch "$HOME/.config/sasd/mysql-probe.cnf"
chmod 600 "$HOME/.config/sasd/mysql-probe.cnf"
${EDITOR:-vi} "$HOME/.config/sasd/mysql-probe.cnf"
```

```ini
[client]
user=sasd_probe
password=PASSWORT_AUS_CREATE_ODER_ALTER_USER
```

Dann mit dem **eingeschränkten Benutzer** über den lokalen Socket testen:

```sh
./bin/db-probe --engine mariadb \
    --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"
```

`DB_USER` soll dann `sasd_probe@localhost` melden. Eine zuvor von
`root` ausgeführte `SELECT VERSION()`-Abfrage prüft dagegen nicht das
neue Testkonto. In einer anderen Server-/Host-Konfiguration muss ein
entsprechender Benutzer mit passendem `@host` eingerichtet werden;
`--host` verwendet TCP mit obligatorischer Zertifikatsprüfung.

## Anmeldedaten und Transport

- **Niemals Passwörter in der Befehlszeile.** Es gibt bewusst kein `--password`
  und kein `--sql`. Für PostgreSQL `~/.pgpass`, `PGPASSFILE`, libpq-Mechanismen
  oder lokale Socket-Authentifizierung konfigurieren. `-w` verhindert
  interaktive Passwortdialoge; bei fehlenden Daten schlägt der Probe fehl.
- MySQL/MariaDB erhalten entweder `--no-defaults` (lokaler Socket oder
  gegebenenfalls MySQL-Login-Pfad) oder `--defaults-file /absoluter/pfad` als
  erstes natives Argument. Die Datei muss eine **reguläre Datei ohne Symlink**
  mit Modus `0600` sein und darf nur einen Abschnitt `[client]` mit
  `user`, `password` sowie `ssl-ca`, `ssl-capath`, `ssl-cert`, `ssl-key`,
  `ssl-cipher`, `ssl-crl` oder `ssl-crlpath` enthalten. Insbesondere
  `init-command`, weitere Abschnitte, Host-Overrides und `!include` werden
  abgewiesen. Beispielinhalt (Datei nur lokal mit umask 077 anlegen):

  ```ini
  [client]
  user=db_reader
  password=HIER_NICHT_DEN_ECHTEN_SCHLUESSEL_IN_DIE_DOKUMENTATION_EINTRAGEN
  ssl-ca=/etc/ssl/certs/internal-database-ca.pem
  ```

- **PostgreSQL über TCP** erzwingt `PGSSLMODE=verify-full`. Ein korrektes
  CA-Vertrauen und ein zum Zertifikat passender Hostname sind Voraussetzung.
  MySQL über TCP erzwingt `--ssl-mode=VERIFY_IDENTITY`; MariaDB über TCP
  `--ssl --ssl-verify-server-cert`. Clients ohne diese Optionen müssen
  fehlschlagen, statt unsicher fortzufahren. Es gibt keinen TLS-Downgrade-Schalter.
- **MySQL/MariaDB ohne `--host`** werden ausdrücklich an einen lokalen
  Unix-Socket gebunden (`--protocol=SOCKET --host=localhost`). Ein Login-Pfad
  darf die Verbindung nicht unbemerkt zu einem entfernten Host umleiten.
  `--host` aktiviert dagegen ausdrücklich TCP und Zertifikatsprüfung.
- MySQL-Clients können die separate Datei `.mylogin.cnf` trotz
  `--no-defaults` lesen. Sie muss vom Benutzer selbst geschützt und verwaltet
  werden. Die unsichere Umgebungsvariable `MYSQL_PWD` wird nicht an den Client
  weitergegeben. Keine Passwort- oder Serverfehlermeldungen werden gespiegelt.
- Verwende ein **dediziertes SQL-Konto mit minimalen Rechten (USAGE reicht für M5.1)** und einen
  vertrauenswürdigen nativen Client. Ein SQL-SELECT beweist weder Replikations-
  noch Datenintegrität, fehlende Administrationsrechte oder Produktionsreife.

## Laufzeit, Datenschutz und Fehlercodes

Der externe Client wird mit einer Argumentliste **ohne Shell** ausgeführt.
Gesamtlaufzeit höchstens `--timeout` + 5 Sekunden (Standard: 5+5).
Standardausgabe und Standardfehler sind auf je 16 KiB begrenzt; fehlerhafte,
mehrzeilige oder unerwartete SQL-Ausgaben werden verworfen. Vorhandene
Zugangsdaten, Verbindungsfehler und Client-Stderr werden nicht ausgegeben.
Gespeicherte Erfolgsberichte können dennoch interne DB-Namen und Versionsdaten
enthalten und müssen geschützt werden. Das Programm verändert weder DB-Schema
noch Daten, kann aber Verbindungs-/Audit-Logs auf dem Server erzeugen.

| Code | Bedeutung |
| --- | --- |
| `0` | Client führte die feste Abfrage aus und lieferte genau eine gültige Zeile |
| `1` | Datenbankverbindung, Anmeldung oder SQL-Abfrage fehlgeschlagen |
| `2` | Ungültiger Aufruf / nicht unterstützte Engine |
| `3` | Fehlender Client, ungültige Authentifizierungsdatei, Zeitüberschreitung oder unbrauchbare Ausgabe |

**Testumfang:** Die automatisierte Standardsuite nutzt nur simulierte native
Clients und stellt keine externen DB-Verbindungen her. Ein echter
Verbindungs-/TLS-Test muss gezielt gegen eine freigegebene Testdatenbank erfolgen.
Linux und macOS mit Perl 5 und Kernmodulen, ohne zusätzliche CPAN-Module.
