# db-health – lesende SQL-Zustandsübersicht (M5.2)

[English](db-health.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/db-health.1) · [Planung](../ROADMAP.de.md)

`db-health` ermittelt mit **einer fest vorgegebenen SQL-Abfrage** drei Kennzahlen
für PostgreSQL, MySQL oder MariaDB: bestehende Clientverbindungen, gerade aktive
Verbindungen und Laufzeit des Datenbankservers in Sekunden. Es verwendet die
nativen Clients `psql`, `mysql` oder `mariadb` ohne CPAN-Pflichtmodule. Alle
Abfragen sind lesend; das Programm verändert keine Datenbankobjekte, Rollen
oder Konfigurationen und nimmt keine eigenen SQL-Texte entgegen.

## Beispiele

```sh
# MariaDB in Debian/WSL: lokale Socketverbindung, kein Server-TLS notwendig
./bin/db-health --engine mariadb \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"

# MySQL: TCP nur mit geprüfter TLS-Serveridentität
./bin/db-health --engine mysql --host db.example.org --port 3306 \
  --user sasd_probe --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"

# PostgreSQL: sicheres libpq-Passwortverfahren wie .pgpass / PGPASSFILE
./bin/db-health --engine postgresql --host pg.example.org \
  --port 5432 --database postgres --user sasd_health

# Null-getrennte Ausgabe für Skripte
./bin/db-health --engine mariadb --null \
  --defaults-file "$HOME/.config/sasd/mysql-probe.cnf"
```

## Ergebnis und Interpretation

Die Ausgabe verwendet die Spalten `ENGINE`, `SCOPE`, `CONNECTIONS`, `ACTIVE`,
`UPTIME_SECONDS` (Tabulatoren, optional fünf Null-getrennte Felder):

```text
ENGINE   SCOPE   CONNECTIONS   ACTIVE   UPTIME_SECONDS
mariadb  server  8             1        53001
```

| Feld | MySQL/MariaDB | PostgreSQL |
| --- | --- | --- |
| `SCOPE` | `server`: vollständiger Server | `cluster`: vollständiger PostgreSQL-Cluster |
| `CONNECTIONS` | `Threads_connected`: aktuelle Verbindungen | `pg_stat_activity`: `backend_type='client backend'` |
| `ACTIVE` | `Threads_running`: laufende Threads (nicht schlafend) | `state='active'` bei Client-Backends |
| `UPTIME_SECONDS` | globaler Status `Uptime` | Zeit seit `pg_postmaster_start_time()` |

**Wichtig:** Die Bedeutung von `ACTIVE` unterscheidet sich zwischen den
Datenbanken. Eine hohe Anzahl Verbindungen beweist keinen Fehler. Die Abfrage
selbst erzeugt mindestens kurzzeitig Aktivität. Statuswerte werden nicht
transaktionsweit atomar erfasst. `db-health` meldet **Messdaten, keine
automatische Bewertung**, und liefert keine historischen Zeitreihen.

**Nicht abgedeckt:** SQL-Texte, einzelne Nutzer, langlaufende Abfragen,
Lock-Wait-Details, Blocking-Chains, Connection-Pool-Grenzen oder Alarmwerte.
Dies wird in späteren spezialisierten Diagnosen behandelt, ohne sensible
SQL-Texte ungefragt auszugeben.

## Rechte: MariaDB und MySQL

`SHOW GLOBAL STATUS` benötigt gemäß MySQL-Dokumentation keine besonderen
Datenbankrechte. Der für M5.1 angelegte Benutzer `sasd_probe` mit `USAGE`
reicht aus. Für eine Testumgebung kann ein Administrator ihn so anlegen:

```sql
CREATE USER 'sasd_probe'@'localhost'
    IDENTIFIED BY 'EIGENES_TESTPASSWORT';
SHOW GRANTS FOR 'sasd_probe'@'localhost';

-- Bestehendes Passwort ändern:
ALTER USER 'sasd_probe'@'localhost'
    IDENTIFIED BY 'EIN_NEUES_TESTPASSWORT';
```

Falls der Benutzer bereits existiert, **kein zweites CREATE USER ausführen**.
Die Optionendatei (nur bei lokaler Testinstallation) ist eine reguläre,
**nicht symbolisch verlinkte Datei mit Modus 0600**:

```sh
mkdir -p -m 700 "$HOME/.config/sasd"
( umask 077; set -C; : > "$HOME/.config/sasd/mysql-probe.cnf" )
# Mit dem Editor die folgenden Zeilen eintragen; nicht ins Terminal kopieren:
# [client]
# user=sasd_probe
# password=EIGENES_TESTPASSWORT
```

Bei vorhandener Datei schlägt der Erzeugungsbefehl absichtlich fehl; sie nur
mit einem Editor bearbeiten. Die Dateiberechtigung lässt sich prüfen mit
`stat -c '%a %n' ~/.config/sasd/mysql-probe.cnf` (Linux).

## Rechte: PostgreSQL

Für **vollständige** Aktivitätszahlen benötigt der SQL-Benutzer die
vorinstallierte PostgreSQL-Rolle `pg_read_all_stats` (oder Superuserrechte).
Ohne sie sind Spalten zu fremden Sessions teilweise unsichtbar. `db-health`
beendet die Prüfung deshalb mit Exitcode **1**, anstatt zu kleine Zahlen
als korrekt auszugeben. Ein berechtigter Administrator kann entscheiden:

```sql
CREATE ROLE sasd_health LOGIN PASSWORD 'EIGENES_TESTPASSWORT';
GRANT pg_read_all_stats TO sasd_health;
-- CONNECT auf die verwendete Datenbank muss ebenfalls erlaubt sein.
```

`pg_read_all_stats` erlaubt auch **weitergehenden Einblick in fremde Sessions
und deren SQL-Texte**. Dieses Recht ist daher sicherheitsrelevant und nicht
mit reinem `USAGE` vergleichbar. Ausschließlich an dafür freigegebene
Monitoring-Konten vergeben; für reine Erreichbarkeit genügt `db-probe`.
Die Rechte und die Abfrage setzen PostgreSQL **10 oder neuer** voraus.

## Transport und Sicherheit

- Bei explizitem `--host` wird TCP verwendet: MySQL erzwingt
  `--ssl-mode=VERIFY_IDENTITY`, MariaDB `--ssl --ssl-verify-server-cert`;
  PostgreSQL setzt `PGSSLMODE=verify-full`. Nicht unterstützte
  Clientversionen scheitern geschlossen. Passende CA-Konfiguration und
  Serverzertifikate sind für Remote-Verbindungen nötig.
- Ohne `--host` wird bei MySQL/MariaDB der lokale Unix-Socket erzwungen.
  PostgreSQL verwendet seinen lokalen Standardzugang ohne umgebungsbedingte
  Remote-Zielüberschreibung. `--port` erfordert `--host`.
- Kein Passwort, keine selbst definierten SQL-Abfragen und keine TLS-Abschaltung
  in der Kommandozeile. `MYSQL_PWD` wird entfernt. Optionendateien dürfen
  ausschließlich die unterstützten Client-Zugangsdaten und TLS-Felder
  enthalten, weder Include-Direktiven noch `init-command`.
- Ein optionaler `--client` muss auf eine ausführbare absolute Datei zeigen.
  Standardmäßig werden nur vordefinierte Installationspfade geprüft.
  Fremde Clients sind damit eine ausdrückliche Vertrauensentscheidung.
- Child-Prozess-Ausgabe ist begrenzt; ein Gesamt-Timeout beendet hängende
  Clients. Native Fehlermeldungen werden wegen möglicher Passwort-/SQL-Lecks
  nicht an die Konsole weitergegeben.
- PostgreSQL-Authentifizierung: `.pgpass` oder `PGPASSFILE` nach libpq-Regeln.
  Für Netzwerk-TLS werden Name und Zertifikat geprüft; das Programm
  erzeugt selbst keine Zertifikate und verifiziert keine CA-Dateien unabhängig
  vom nativen Client.

## Exitcodes

| Code | Bedeutung |
| --- | --- |
| `0` | Vollständige, korrekt aufgebaute Antwort; **nicht** automatisch „gesund“ |
| `1` | Verbindung/SQL fehlgeschlagen oder PostgreSQL-Statistikrechte unzureichend |
| `2` | Ungültige Option oder Eingabe |
| `3` | Client fehlt, Timeout, unsichere Datei oder unplausible Antwort |

Standardtests benutzen ausschließlich simulierte native Clients: Ein echtes
MariaDB-/MySQL-/PostgreSQL-System wird damit **nicht** automatisch geprüft.
Für echte Integrationsabnahmen sind Benutzer, Zertifikate und Server separat
vorzubereiten. Die Betriebssysteme Linux und macOS werden über die CI geprüft.
