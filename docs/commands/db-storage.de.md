# db-storage – Lesende SQL-Speicher- und Tabellenanalyse (M5.4)

[English](db-storage.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/db-storage.1) · [Kapitelplanung](../ROADMAP.de.md)

`db-storage` inventarisiert die **sichtbaren Basistabellen einer ausgewählten Datenbank** über `information_schema.TABLES`. M5.4 unterstützt MariaDB (Referenz: 10.11) und MySQL 8.x; PostgreSQL, Oracle und Microsoft SQL Server sind **noch nicht implementiert**. Das Werkzeug verwendet ausschließlich eine festgelegte lesende `SELECT`-Abfrage über `mariadb` beziehungsweise `mysql` und benötigt keine CPAN-Module. Es erstellt oder verändert keine Datenbanken, Tabellen oder Daten.

## Aufruf

```sh
./bin/db-storage --engine mariadb --database sasd_storage_lab \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"

./bin/db-storage --engine mariadb --database sasd_storage_lab \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf" \
  --limit 10 --sort-by index

./bin/db-storage --engine mysql --database appdb \
  --host db.example.org --user reader \
  --defaults-file "$HOME/.config/sasd/mysql-storage.cnf" --limit 25
```

Pflichtparameter: `--engine mariadb|mysql` und `--database NAME`. Datenbanknamen sind bewusst auf einfache ASCII-Bezeichner begrenzt. Ein Tabellenname wird dagegen niemals als Eingabe oder SQL-Bestandteil übernommen. `--limit 1..100` bestimmt die angezeigten größten Tabellen (Standard `20`); `--sort-by total|data|index|free` bestimmt die Sortierung (Standard `total`). Die bekannten sicheren Verbindungsoptionen `--host`, `--port`, `--user`, `--timeout 1..30`, `--client` (absoluter Pfad) und `--defaults-file` (private Clientdatei) werden unterstützt. `--null` gibt pro Datensatz elf NUL-terminierte Felder ohne Überschrift aus.

## Ergebnis und Auswertung

```text
ENGINE  SCOPE    KIND   NAME               STORAGE_ENGINE TABLES DATA_BYTES INDEX_BYTES TOTAL_BYTES FREE_BYTES UNKNOWN
mariadb visible  TOTAL  sasd_storage_lab   <all>          2      32768      16384       49152       0          0
mariadb visible  TABLE  events             InnoDB         1      16384      16384       32768       0          0
mariadb visible  TABLE  sample             InnoDB         1      16384      0           16384       0          0
# Showing top 2 table(s) out of 2 visible BASE TABLE(s); sorted by total.
```

Die Zahlen im Beispiel sind **fiktiv**; die realen Werte hängen von Server und Storage-Engine ab.

- `SCOPE=visible` bedeutet **nur für dieses Konto sichtbare Metadaten**, keine vollständige Serverinventur.
- `TOTAL` summiert die gemeldeten Werte **aller sichtbaren Basistabellen der ausgewählten Datenbank**, unabhängig von `--limit`. `TABLE` zeigt bis zu N sortierte Einzelzeilen. Views werden nicht mitgezählt.
- `DATA_BYTES`, `INDEX_BYTES` und `TOTAL_BYTES` stammen aus `DATA_LENGTH`, `INDEX_LENGTH` und deren Summe. `FREE_BYTES` entspricht `DATA_FREE`; dies ist **nicht der freie Speicher des Dateisystems**.
- `UNKNOWN` zählt Tabellen mit mindestens einem `NULL`-Wert für Daten-, Index- oder freie Größe. Für die Addition werden fehlende Werte rechnerisch als null behandelt; wenn solche Werte vorkommen, meldet das Programm **Exitcode 1** und `INCOMPLETE METRICS`, auch bei `--null`.
- InnoDB-Größen sind teilweise Schätzwerte beziehungsweise zugewiesene Seiten. `DATA_FREE` kann sich auf gemeinsam genutzte Tablespaces beziehen und beim Summieren mehrfach erscheinen. Weder exakter Plattenbedarf noch tatsächliche Belegung/Freikapazität eines Datenträgers sind garantiert. Auch Binärlogs, Redo/Undo-Logs, temporäre Dateien und Dateisystem-Overhead fehlen.
- Eine Momentaufnahme ermittelt **kein Wachstum**. Dafür ist später eine gesonderte Zeitreihen-/Vergleichsfunktion nötig.

Zur Umrechnung von Bytes in MiB gilt `MiB = Bytes / 1048576`, für GiB entsprechend `Bytes / 1073741824`. Unter Linux lässt sich z. B. `numfmt --to=iec-i --suffix=B 49152` verwenden; `numfmt` wird von `db-storage` nicht benötigt.

## Rechte und praktischer Test unter Debian/WSL

Der für M5.1–M5.3 eingerichtete Benutzer `sasd_probe` hat nur `USAGE` und damit **noch keine Tabellenberechtigung**. Für einen nachvollziehbaren M5.4-Test empfiehlt sich eine **gesonderte, ausdrücklich angelegte Testdatenbank**. Diese folgenden SQL-Befehle **verändern das Testsystem** und sind *nicht* Bestandteil von `db-storage`:

```sql
-- Einmalig als berechtigter MariaDB-Administrator ausführen:
CREATE DATABASE sasd_storage_lab;
CREATE TABLE sasd_storage_lab.sample (
    id INT NOT NULL PRIMARY KEY,
    description VARCHAR(100) NOT NULL
) ENGINE=InnoDB;
INSERT INTO sasd_storage_lab.sample (id, description)
VALUES (1, 'Storage-Test');

-- Bereits vorhandenen Benutzer nur für die Testdatenbank berechtigen:
GRANT SELECT ON sasd_storage_lab.* TO 'sasd_probe'@'localhost';
SHOW GRANTS FOR 'sasd_probe'@'localhost';
```

Dann im Terminal **ohne Root-Rechte**:

```sh
./bin/db-storage --engine mariadb --database sasd_storage_lab \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"
echo "Prüfstatus: $?"
```

Zum bewussten Aufräumen nach Abschluss des Tests (nur falls diese Datenbank eigens für den Test neu angelegt wurde):

```sql
REVOKE SELECT ON sasd_storage_lab.* FROM 'sasd_probe'@'localhost';
DROP DATABASE sasd_storage_lab;
```

**Vor `DROP DATABASE` prüfen, dass keine bestehenden oder wichtigen Daten darin liegen.** Auf produktiven Systemen stattdessen eine bereits freigegebene Datenbank mit gezielten Leserechten nutzen. `SHOW GRANTS` ist hilfreich, aber Rechte auf andere Tabellen werden nicht pauschal angenommen. MySQL/MariaDB können die `information_schema`-Tabellenliste abhängig von den effektiven Objektberechtigungen einschränken. Eine erfolgreiche Abfrage mit `0` Tabellen ist daher kein Beweis, dass die Datenbank wirklich leer ist.

## Sicherheit und Betrieb

Die Anmeldeinformationen verbleiben in einer privaten Datei (beispielsweise `~/.config/sasd/mysql-probe.cnf`, Modus `0600`). Die Datei darf kein Symlink sein und nur die `[client]`-Sektion mit ausdrücklich zugelassenen Authentifizierungs- und TLS-Optionen enthalten. Keine Passwörter in Programmargumenten oder im Repository. Bei lokalem Betrieb wird ein Unix-Socket erzwungen. Bei explizitem `--host` ist verifizierte TLS-Zertifikatsprüfung vorgeschrieben (`--ssl-mode=VERIFY_IDENTITY` bei MySQL, `--ssl --ssl-verify-server-cert` bei MariaDB). Fehlende Client-Unterstützung führt zum Abbruch, nicht zum TLS-Downgrade. Native Fehlermeldungen werden wegen möglicher Geheimnisse nicht unverändert ausgegeben.

Die SQL-Antwort wird vollständig geprüft, bevor Ergebnisse angezeigt werden. Größe, Laufzeit und Anzahl ausgegebener Tabellen sind begrenzt. Es werden weder frei eingebbare SQL-Kommandos noch `ANALYZE TABLE` oder andere mutierende Anweisungen angeboten. Vorsicht: Ein Metadaten-Snapshot kann auf sehr großen Datenbanken spürbare Serverlast auslösen; er ist keine kontinuierliche Performance-Messung.

| Exitcode | Bedeutung |
| --- | --- |
| `0` | Gültige, vollständig gemeldete sichtbare Metadaten (auch null sichtbare Tabellen) |
| `1` | Datenbank-/Rechtefehler oder fehlende (`NULL`) Größenmetadaten |
| `2` | Ungültiger Aufruf, nicht unterstütztes Backend |
| `3` | Native-Client-/Timeout-Problem oder ungültige/zu große Ausgabe |

**Offline-Tests ohne Datenbankserver:** `prove tests/test_db_storage.t`; vollständige Suite: `make test`.

Weiterführend: [MariaDB INFORMATION_SCHEMA.TABLES](https://mariadb.com/docs/server/reference/system-tables/information-schema/information-schema-tables/information-schema-tables-table), [MySQL INFORMATION_SCHEMA.TABLES](https://dev.mysql.com/doc/refman/8.4/en/information-schema-tables-table.html).
