# db-activity – SQL-Aktivität und mögliche Sperren (M5.3)

[English](db-activity.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/db-activity.1) · [Roadmap](../ROADMAP.de.md)

`db-activity` erfasst eine **begrenzte, lesende Momentaufnahme** der sichtbaren
Datenbanksitzungen. Es unterstützt PostgreSQL (mindestens Version 10), MySQL 8.x
und MariaDB (unter anderem 10.11). Das Programm führt ausschließlich fest
vorgegebene `SELECT`-Abfragen über die nativen Kommandozeilenclients aus.
Es liest **keinen SQL-Abfragetext** und gibt auch keine Client-IP-Adressen aus.
Es kann weder Transaktionen noch Sitzungen beenden oder Sperren freigeben.

## Aufruf und Beispiele

```sh
./bin/db-activity --engine mariadb \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"

./bin/db-activity --engine mariadb \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf" \
  --min-seconds 5 --limit 30 --include-idle

./bin/db-activity --engine postgresql --database postgres \
  --user sasd_activity --min-seconds 10 --limit 20
```

Die gleichen Verbindungsschalter wie bei `db-probe` und `db-health` sind
vorhanden: `--engine`, `--host`, `--port`, `--database`, `--user`, `--client`
(absoluter Pfad), `--defaults-file` (nur MySQL/MariaDB), `--timeout 1..30`
und `--null`. Ergänzt werden:

| Option | Bedeutung |
| --- | --- |
| `--min-seconds 0..86400` | Nur Sitzungen berücksichtigen, deren berichteter Zustands-/Abfragezeitraum mindestens so lange ist (Standard `0`). |
| `--limit 1..100` | Höchstzahl ausgegebener Sitzungen (Standard `25`). SQL liest höchstens `limit + 1` Datensätze für die Vollständigkeitsprüfung. |
| `--include-idle` | Auch `Sleep` (MySQL/MariaDB) beziehungsweise `idle` (PostgreSQL) anzeigen. |
| `--null` | Pro Datensatz zehn NUL-terminierte Felder ohne Tabellenüberschrift. |

Beispielspalten:

```text
ENGINE   SCOPE   SESSION_ID  DB_USER  DATABASE  STATE   SECONDS WAIT                LOCK_STATUS BLOCKERS
mariadb  visible 55          worker   app       Query   12      Waiting for metadata lock possible    ?
```

Ein leerer Bericht ist zulässig: Standardmäßig wird die eigene Diagnosesitzung
ausgeschlossen und `Sleep`/`idle` ausgeblendet. Insbesondere mit dem nur zu
`USAGE` berechtigten lokalen Konto `sasd_probe` kann der Bericht leer sein,
wenn keine zweite Sitzung desselben Kontos arbeitet. Das bedeutet **nicht**,
dass auf dem ganzen Server keine anderen Sitzungen existieren.

## Bedeutung der Spalten

- **SCOPE:** `visible` bei MySQL/MariaDB – nur für das Konto sichtbare Sitzungen;
  `cluster` bei PostgreSQL – nur bei bestätigter Leseberechtigung.
- **SECONDS:** MySQL/MariaDB `PROCESSLIST.TIME` (Zeit im aktuellen Kommando- bzw.
  Ausführungszustand); PostgreSQL bei `active` Zeit seit Abfragebeginn,
  ansonsten seit dem letzten Zustandswechsel. Die Werte sind nicht identisch.
- **WAIT:** PostgreSQL `wait_event_type:wait_event`, ansonsten `<none>`;
  MySQL/MariaDB `PROCESSLIST.STATE` (ein Zustands-Hinweis, kein SQL-Text).
- **LOCK_STATUS:** `blocked` bei PostgreSQL, wenn `pg_blocking_pids()`
  mindestens einen Blockierer meldet; `waiting` bei PostgreSQL-Lock-Warteereignis
  ohne gemeldeten Blockierer zum Zeitpunkt der Abfrage; `none` sonst.
  MySQL/MariaDB melden **`possible`** bei Text-Hinweisen auf Sperren und
  **`unknown`** sonst. Dort wird keine bestätigte Sperrbeziehung behauptet.
- **BLOCKERS:** Anzahl von `pg_blocking_pids()` bei PostgreSQL. Bei
  MySQL/MariaDB steht `?`, weil die verwendete Prozessliste die Blockierer
  nicht eindeutig bestimmen kann.

Eine „lange“ Sitzung ist nicht automatisch fehlerhaft. `--include-idle` ist
wichtig: Ein `Sleep`-Client kann noch eine offene Transaktion mit Sperren halten.
Die Sicht ist auf `--limit` begrenzt und kann weitere Vorgänge übersehen.

## Benutzer und Berechtigungen

### MariaDB / MySQL

Der bereits für M5.1 angelegte lokale Benutzer genügt für einen **eigenen,
eingeschränkten** Blick. `USAGE` wird standardmäßig durch `CREATE USER`
erteilt; die eigene laufende Diagnoseabfrage wird nicht aufgelistet.

```sql
-- Als berechtigter Administrator, falls das Konto noch nicht existiert:
CREATE USER 'sasd_probe'@'localhost' IDENTIFIED BY 'BEISPIELPASSWORT';
-- Passwort eines bestehenden Kontos aktualisieren:
ALTER USER 'sasd_probe'@'localhost' IDENTIFIED BY 'NEUES_BEISPIELPASSWORT';
SHOW GRANTS FOR 'sasd_probe'@'localhost';
```

Um auch Sitzungen **anderer Benutzer** zu sehen, kann ein Administrator
optional globales `PROCESS` gewähren:

```sql
GRANT PROCESS ON *.* TO 'sasd_probe'@'localhost';
SHOW GRANTS FOR 'sasd_probe'@'localhost';
-- Später wieder entfernen:
REVOKE PROCESS ON *.* FROM 'sasd_probe'@'localhost';
```

**Vorsicht:** `PROCESS` bietet außerhalb unseres Programms weitreichendere
Einblicke (beispielsweise Abfragetexte in anderen Clients). Es ist deshalb
kein Standarderfordernis und sollte bewusst genehmigt werden. Unser Werkzeug
fragt die `INFO`-Spalte nicht ab. MySQL kennzeichnet
`INFORMATION_SCHEMA.PROCESSLIST` als veraltet; zukünftige Versionen benötigen
eventuell einen anderen Backend-Adapter.

Die bereits verwendete Konfigurationsdatei funktioniert unverändert:

```ini
[client]
user=sasd_probe
password=BEISPIELPASSWORT
```

```sh
chmod 600 "$HOME/.config/sasd/mysql-probe.cnf"
./bin/db-activity --engine mariadb \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"
```

Die Zugangsdaten gehören nicht in Kommandozeilenargumente oder das Repository.
Der Client-Konfigurationsdateipfad muss absolut sein, eine reguläre Datei ohne
Symlink und für Gruppen/Fremde unzugänglich. Unsichere Client-Optionen,
insbesondere `init-command`, Includes und Ziel-Overrides, werden verweigert.

### PostgreSQL

Für den **vollständigen** Blick verlangt das Werkzeug `pg_read_all_stats`
(oder Superuser). Ohne diese Berechtigung gibt es Status `1` und **keine
vermeintlich vollständigen Ergebnisse**. Beispiel durch einen Administrator:

```sql
CREATE ROLE sasd_activity LOGIN PASSWORD 'BEISPIELPASSWORT';
GRANT pg_read_all_stats TO sasd_activity;
-- Bei Bedarf später: REVOKE pg_read_all_stats FROM sasd_activity;
```

Ein `CONNECT`-Recht auf die Zieldatenbank muss ebenfalls bestehen.
`pg_read_all_stats` erlaubt mehr Informationen, als `db-activity` ausgibt.
Das ist bewusst zu prüfen; SQL-Texte selbst werden vom Werkzeug nicht gelesen.
Für passwortlose Unix-Socket-Authentifizierung, `.pgpass` oder `PGPASSFILE`
siehe `db-probe`; Passwörter dürfen nicht in argv stehen. Bei explizitem
TCP-Ziel gilt `PGSSLMODE=verify-full` ohne Downgrade.

## Grenzen, Fehler und Tests

Das Programm fragt nur begrenzte Momentaufnahmen ab und ersetzt keine
kontinuierliche Überwachung, transaktionsgenaue Deadlock-Analyse oder
Wartegraphen. Es ruft keine `KILL`-, `CANCEL`- oder `SET`-Anweisungen auf.
PostgreSQL `pg_blocking_pids()` erkennt Blockierer zum Zeitpunkt der Abfrage;
bei MySQL/MariaDB sind Sperren **nur Vermutungen** aus dem Zustandsfeld.

Der Server liefert höchstens `--limit + 1` Datensätze. Werden mehr als
`--limit` gefunden, bleibt die Ausgabe auf `--limit` begrenzt, aber der
**Exitcode lautet `1` (unvollständige Abdeckung)**, auch im `--null`-Modus.
Ein Skript muss den Exitcode immer prüfen.

| Exitcode | Bedeutung |
| --- | --- |
| `0` | Abfrage vollständig ausgewertet (auch keine sichtbaren Sitzungen möglich) |
| `1` | Rechte-/Datenbankfehler oder auf `--limit` gekürzte Stichprobe |
| `2` | Falsche Argumente |
| `3` | Fehlender Client, Zeitlimit, falsches/zu großes Client-Ergebnis |

Die isolierten Tests verwenden künstliche Native-Client-Programme; sie
benötigen weder Datenbankserver noch Passwörter:

```sh
prove tests/test_db_activity.t
make test
```

Für einen **freiwilligen lokalen Praxistest** kann eine zweite Sitzung als
`sasd_probe` einen einfachen `SELECT SLEEP(15)` ausführen. In einer anderen
Shell zeigt `db-activity` mit `--include-idle` und `--min-seconds 0` währenddessen
die entsprechende Sitzung. `SLEEP` verändert keine Tabellen, erzeugt aber
absichtlich kurzfristig Datenbanklast und sollte nicht auf Produktionssystemen
ausgeführt werden.

Quellen: [PostgreSQL Monitoring](https://www.postgresql.org/docs/current/monitoring-stats.html),
[pg_blocking_pids](https://www.postgresql.org/docs/current/functions-info.html),
[MariaDB PROCESSLIST](https://mariadb.com/docs/server/reference/system-tables/information-schema/information-schema-tables/information-schema-processlist-table),
[MySQL Process List](https://dev.mysql.com/doc/refman/8.4/en/processlist-access.html).
