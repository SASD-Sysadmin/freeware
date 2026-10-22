# SASD Freeware

[English](README.md) | **Deutsch** · [MIT-Lizenz](LICENSE) · [Mitwirkung](CONTRIBUTING.md) · [Änderungsprotokoll](CHANGELOG.md) · [Roadmap](docs/ROADMAP.de.md) · [Privilegierte Sicherheit](docs/PRIVILEGED-SAFETY.de.md) · [Plattformunterstützung](docs/PLATFORMS.de.md) · [Release-Verfahren](docs/RELEASE-ENGINEERING.de.md)

SASD Freeware stellt Kommandozeilenprogramme, Scripts und Bibliotheken für die Systemadministration unter Linux und Unix bereit. Die Werkzeuge sind für einen zuverlässigen Betrieb, die unkomplizierte Integration in bestehende Umgebungen und eine langfristige Wartbarkeit ausgelegt. Zu jedem Programm gehören Dokumentation, praktische Anwendungsbeispiele und automatisierte Tests.


M6.4 Mail-Integration und Laborabnahme: [Deutsche Anleitung](docs/MAIL-ACCEPTANCE.de.md) · [English](docs/MAIL-ACCEPTANCE.md). Offline-Tests ersetzen keine echte Postfix-Abnahme.

## Enthaltene Werkzeuge

| Befehl | Pfad | Funktion | Dokumentation |
| --- | --- | --- | --- |
| `db-probe` | [`bin/db-probe`](bin/db-probe) | SQL-Verbindung, Datenbankidentität und Serverversion prüfen (M5.1). | [Deutsch](docs/commands/db-probe.de.md) · [English](docs/commands/db-probe.md) · [Manpage](man/man1/db-probe.1) |
| `db-health` | [`bin/db-health`](bin/db-health) | Lesender Datenbank-Zustandsbericht zu Verbindungen, Aktivität und Laufzeit (M5.2). | [Deutsch](docs/commands/db-health.de.md) · [English](docs/commands/db-health.md) · [Manpage](man/man1/db-health.1) |
| `db-activity` | [`bin/db-activity`](bin/db-activity) | Begrenzter SQL-Sitzungsbericht mit Wartezuständen und Sperrhinweisen (M5.3). | [Deutsch](docs/commands/db-activity.de.md) · [English](docs/commands/db-activity.md) · [Manpage](man/man1/db-activity.1) |
| `db-storage` | [`bin/db-storage`](bin/db-storage) | Lesender MariaDB-/MySQL-Speicherbericht für eine Datenbank und ihre größten Tabellen (M5.4). | [Deutsch](docs/commands/db-storage.de.md) · [English](docs/commands/db-storage.md) · [Manpage](man/man1/db-storage.1) |
| `mail-probe` | [`bin/mail-probe`](bin/mail-probe) | Lesende SMTP-Diagnose mit verpflichtender STARTTLS- und Zertifikatsprüfung (M6.1). | [Deutsch](docs/commands/mail-probe.de.md) · [English](docs/commands/mail-probe.md) · [Manpage](man/man1/mail-probe.1) |
| `mail-queue` | [`bin/mail-queue`](bin/mail-queue) | Lesender aggregierter Postfix-Queue-Bericht zu Nachrichten und Größen (M6.2). | [Deutsch](docs/commands/mail-queue.de.md) · [English](docs/commands/mail-queue.md) · [Manpage](man/man1/mail-queue.1) |
| `mail-config-audit` | [`bin/mail-config-audit`](bin/mail-config-audit) | Statische, lesende Prüfung von Postfix-main.cf und optional master.cf (M6.3). | [Deutsch](docs/commands/mail-config-audit.de.md) · [English](docs/commands/mail-config-audit.md) · [Manpage](man/man1/mail-config-audit.1) |
| `journal-summary` | [`bin/journal-summary`](bin/journal-summary) | Strukturierte, datensparsame Prioritätszählung für exportierte systemd-Journal-JSON-Zeilen (M7.1). | [Deutsch](docs/commands/journal-summary.de.md) · [English](docs/commands/journal-summary.md) · [Manpage](man/man1/journal-summary.1) |
| `syslog-summary` | [`bin/syslog-summary`](bin/syslog-summary) | Lesender RFC3164-/RFC5424-Prioritätsbericht ohne Deutung von MESSAGE-Text (M7.2). | [Deutsch](docs/commands/syslog-summary.de.md) · [English](docs/commands/syslog-summary.md) · [Manpage](man/man1/syslog-summary.1) |
| `ssh-auth-summary` | [`bin/ssh-auth-summary`](bin/ssh-auth-summary) | Lesende, datensparsame Auswertung von OpenSSH-Anmeldemeldungsmustern (M7.3). | [Deutsch](docs/commands/ssh-auth-summary.de.md) · [English](docs/commands/ssh-auth-summary.md) · [Manpage](man/man1/ssh-auth-summary.1) |
| `auth-event-summary` | [`bin/auth-event-summary`](bin/auth-event-summary) | Lesende Auswertung ausgewählter sudo-/su-/PAM-Meldungsmuster (M7.4), ohne personenbezogene Ausgabe. | [Deutsch](docs/commands/auth-event-summary.de.md) · [English](docs/commands/auth-event-summary.md) · [Manpage](man/man1/auth-event-summary.1) |
| `log-summary-normalize` | [`bin/log-summary-normalize`](bin/log-summary-normalize) | Vollständige M7.1–M7.4-Zählberichte als einheitliche JSON-Lines normalisieren (M7.5), ohne Korrelation vorzutäuschen. | [Deutsch](docs/commands/log-summary-normalize.de.md) · [English](docs/commands/log-summary-normalize.md) · [Manpage](man/man1/log-summary-normalize.1) |
| `network-interface-report` | [`bin/network-interface-report`](bin/network-interface-report) | Lesendes Inventar von Schnittstellen, IPv4/IPv6-Adressen und Zuständen für Linux/macOS (M8.1). | [Deutsch](docs/commands/network-interface-report.de.md) · [English](docs/commands/network-interface-report.md) · [Manpage](man/man1/network-interface-report.1) |
| `network-route-report` | [`bin/network-route-report`](bin/network-route-report) | Lesende Inventarisierung von IPv4-/IPv6-Routen, Default-Gateways und Schnittstellen (M8.2), mit Linux-JSON und macOS/BSD-netstat. | [Deutsch](docs/commands/network-route-report.de.md) · [English](docs/commands/network-route-report.md) · [Manpage](man/man1/network-route-report.1) |
| `network-service-report` | [`bin/network-service-report`](bin/network-service-report) | Lesendes Inventar lokaler TCP-Listener und unverbundener UDP-Bindungen (M8.3) über Linux-ss und macOS/BSD-netstat. | [Deutsch](docs/commands/network-service-report.de.md) · [English](docs/commands/network-service-report.md) · [Manpage](man/man1/network-service-report.1) |
| `session-report` | [`bin/session-report`](bin/session-report) | Angemeldete interaktive Benutzersitzungen erfassen (Kapitel 4). | [Deutsch](docs/commands/session-report.de.md) · [English](docs/commands/session-report.md) · [Manpage](man/man1/session-report.1) |
| `process-report` | [`bin/process-report`](bin/process-report) | Prozesse nach Benutzer und Status inventarisieren (Kapitel 4). | [Deutsch](docs/commands/process-report.de.md) · [English](docs/commands/process-report.md) · [Manpage](man/man1/process-report.1) |
| `login-audit` | [`bin/login-audit`](bin/login-audit) | Linux-Anmeldehistorie und Fehlversuche lesen (Kapitel 4); gespeicherte ISO-Testdaten auf weiteren Plattformen. | [Deutsch](docs/commands/login-audit.de.md) · [English](docs/commands/login-audit.md) · [Manpage](man/man1/login-audit.1) |
| `core-report` | [`bin/core-report`](bin/core-report) | Dateien mit Core-Dump-typischen Namen und ihre Größen erfassen. | [Deutsch](docs/commands/core-report.de.md) · [English](docs/commands/core-report.md) · [Manpage](man/man1/core-report.1) |
| `path-audit` | [`bin/path-audit`](bin/path-audit) | Überlange Pfadkomponenten und Pfadnamen ermitteln. | [Deutsch](docs/commands/path-audit.de.md) · [English](docs/commands/path-audit.md) · [Manpage](man/man1/path-audit.1) |
| `link-audit` | [`bin/link-audit`](bin/link-audit) | Defekte, zyklische und nicht auflösbare symbolische Links anzeigen. | [Deutsch](docs/commands/link-audit.de.md) · [English](docs/commands/link-audit.md) · [Manpage](man/man1/link-audit.1) |
| `owner-audit` | [`bin/owner-audit`](bin/owner-audit) | Nicht auflösbare UID-/GID-Zuordnungen inventarisieren. | [Deutsch](docs/commands/owner-audit.de.md) · [English](docs/commands/owner-audit.md) · [Manpage](man/man1/owner-audit.1) |
| `permission-audit` | [`bin/permission-audit`](bin/permission-audit) | Weltweit beschreibbare Dateisystemeinträge ermitteln. | [Deutsch](docs/commands/permission-audit.de.md) · [English](docs/commands/permission-audit.md) · [Manpage](man/man1/permission-audit.1) |
| `rotate` | [`bin/rotate`](bin/rotate) | Bis zu zehn Sicherungsgenerationen einer regulären Datei (`.0` neueste, `.9` älteste). | [Deutsch](docs/commands/rotate.de.md) · [English](docs/commands/rotate.md) · [Manpage](man/man1/rotate.1) |
| `fs-report` | [`bin/fs-report`](bin/fs-report) | Verzeichnisse und logische Dateigrößen erfassen. | [Anleitung](docs/commands/fs-report.de.md) · [English](docs/commands/fs-report.md) · [Manpage](man/man1/fs-report.1) |
| `largefiles` | [`bin/largefiles`](bin/largefiles) | Große reguläre Dateien ermitteln. | [Anleitung](docs/commands/largefiles.de.md) · [English](docs/commands/largefiles.md) · [Manpage](man/man1/largefiles.1) |
| `fs-usage` | [`bin/fs-usage`](bin/fs-usage) | Dateisystembelegung per df prüfen. | [Anleitung](docs/commands/fs-usage.de.md) · [English](docs/commands/fs-usage.md) · [Manpage](man/man1/fs-usage.1) |
| `quota-report` | [`bin/quota-report`](bin/quota-report) | Benutzer-, Gruppen- und Dateisystem-Quotas abfragen. | [Anleitung](docs/commands/quota-report.de.md) · [English](docs/commands/quota-report.md) · [Manpage](man/man1/quota-report.1) |
| `quota-status` | [`bin/quota-status`](bin/quota-status) | Aktivierungszustand von Linux-Quotas über `quotaon -p` anzeigen. | [Anleitung](docs/commands/quota-status.de.md) · [English](docs/commands/quota-status.md) · [Manpage](man/man1/quota-status.1) |
| `quota-set` | [`sbin/quota-set`](sbin/quota-set) | Vollständige Linux-Quotas vorbereiten oder ausdrücklich bestätigt anwenden. | [Anleitung](docs/commands/quota-set.de.md) · [English](docs/commands/quota-set.md) · [Manpage](man/man8/quota-set.8) |
| `hosts-lint` | [`bin/hosts-lint`](bin/hosts-lint) | Syntaxprüfung der Hosts-Datei. | [Perl-Anleitung](docs/commands/perl-tools.de.md) · [Manpage](man/man1/hosts-lint.1) |
| `nss-lookup` | [`bin/nss-lookup`](bin/nss-lookup) | Einzelne Benutzer und Gruppen über die System-Namensdienstschnittstelle auflösen. | [Anleitung](docs/commands/nss-lookup.de.md) · [English](docs/commands/nss-lookup.md) · [Manpage](man/man1/nss-lookup.1) |
| `host-resolve` | [`bin/host-resolve`](bin/host-resolve) | Vorwärts- und Rückwärtsauflösung über den System-Resolver (nicht DNS-exklusiv). | [Anleitung](docs/commands/host-resolve.de.md) · [English](docs/commands/host-resolve.md) · [Manpage](man/man1/host-resolve.1) |
| `ldap-probe` | [`bin/ldap-probe`](bin/ldap-probe) | Anonyme LDAPS-Root-DSE-Prüfung mit optionalem ldapsearch. | [Anleitung](docs/commands/ldap-probe.de.md) · [English](docs/commands/ldap-probe.md) · [Manpage](man/man1/ldap-probe.1) |
| `nsswitch-audit` | [`bin/nsswitch-audit`](bin/nsswitch-audit) | Linux-artige NSS-Switch-Datei auf Strukturfehler prüfen. | [Anleitung](docs/commands/nsswitch-audit.de.md) · [English](docs/commands/nsswitch-audit.md) · [Manpage](man/man1/nsswitch-audit.1) |
| `dns-query` | [`bin/dns-query`](bin/dns-query) | Direkte DNS-Anfragen über optionales dig (kein System-Resolver). | [Anleitung](docs/commands/dns-query.de.md) · [English](docs/commands/dns-query.md) · [Manpage](man/man1/dns-query.1) |
| `nis-probe` | [`bin/nis-probe`](bin/nis-probe) | Lokale NIS-/YP-Bindung ohne Map-Zugriff prüfen. | [Anleitung](docs/commands/nis-probe.de.md) · [English](docs/commands/nis-probe.md) · [Manpage](man/man1/nis-probe.1) |
| `ldap-config-audit` | [`bin/ldap-config-audit`](bin/ldap-config-audit) | TLS-Konfiguration des OpenLDAP-Clients ohne Wertausgabe prüfen. | [Anleitung](docs/commands/ldap-config-audit.de.md) · [English](docs/commands/ldap-config-audit.md) · [Manpage](man/man1/ldap-config-audit.1) |
| `account-inventory` | [`bin/account-inventory`](bin/account-inventory) | Lokale Konten oder über NSS aufgezählte Identitäten erfassen. | [Anleitung](docs/commands/account-inventory.de.md) · [English](docs/commands/account-inventory.md) · [Manpage](man/man1/account-inventory.1) |
| `group-audit` | [`bin/group-audit`](bin/group-audit) | Lokale Gruppenstruktur und Mitgliedschaft prüfen. | [Anleitung](docs/commands/group-audit.de.md) · [English](docs/commands/group-audit.md) · [Manpage](man/man1/group-audit.1) |
| `home-audit` | [`bin/home-audit`](bin/home-audit) | Metadaten von Home-Verzeichnissen über lokale Konten/NSS prüfen. | [Anleitung](docs/commands/home-audit.de.md) · [English](docs/commands/home-audit.md) · [Manpage](man/man1/home-audit.1) |
| `account-manage` | [`sbin/account-manage`](sbin/account-manage) | Lokale Linux-Konten mit Vorschau und Bestätigung verwalten. | [Anleitung](docs/commands/account-manage.de.md) · [English](docs/commands/account-manage.md) · [Manpage](man/man8/account-manage.8) |
| `account-audit` | [`bin/account-audit`](bin/account-audit) | Strukturanalyse einer Unix-Kontodatei. | [Perl-Anleitung](docs/commands/perl-tools.de.md) · [Manpage](man/man1/account-audit.1) |
| `log-summary` | [`bin/log-summary`](bin/log-summary) | Logmeldungen nach Schweregrad zählen. | [Perl-Anleitung](docs/commands/perl-tools.de.md) · [Manpage](man/man1/log-summary.1) |
| `ssh-key-audit` | [`bin/ssh-key-audit`](bin/ssh-key-audit) | SSH-Schlüsseldatei schreibgeschützt prüfen. | [Automatisierungs-Anleitung](docs/commands/automation-tools.de.md) · [Manpage](man/man1/ssh-key-audit.1) |
| `file-integrity` | [`bin/file-integrity`](bin/file-integrity) | SHA-256-Basisliste erstellen und Änderungen prüfen. | [Automatisierungs-Anleitung](docs/commands/automation-tools.de.md) · [Manpage](man/man1/file-integrity.1) |
| `suid-audit` | [`bin/suid-audit`](bin/suid-audit) | SUID-/SGID-Dateien inventarisieren. | [Automatisierungs-Anleitung](docs/commands/automation-tools.de.md) · [Manpage](man/man1/suid-audit.1) |
| `tcp-check` | [`bin/tcp-check`](bin/tcp-check) | TCP-Port erreichbar? Optional Nagios-Rückgabewerte. | [Automatisierungs-Anleitung](docs/commands/automation-tools.de.md) · [Manpage](man/man1/tcp-check.1) |

Beispiel: `rotate /etc/hosts` erstellt `/etc/hosts.0`, während `/etc/hosts` unverändert bleibt. Beim nächsten Aufruf wird die bisherige `.0` zu `.1`, und eine neue `.0` entsteht. Sind zehn Generationen vorhanden, wird `.9` vor dem Nachrücken gelöscht. `rotate` ist ein **einfaches Hilfswerkzeug zur Dateisicherung**, aber kein Ersatz für Backups, Versionsverwaltung oder eine umfangreiche `logrotate`-Konfiguration.

## Vorgesehene Verzeichnisstruktur

```text
freeware/
├── bin/               Benutzerprogramme (rotate und Perl-Werkzeuge)
├── sbin/              Administrationsprogramme (quota-set)
├── lib/               Architekturunabhängige Bibliotheken
├── lib64/             64-Bit-Bibliotheken (reserviert)
├── man/
│   ├── man1/          Handbuchseiten für Benutzerprogramme
│   └── man8/          Handbuchseiten für Administrationsprogramme
├── tests/             Automatisierte Tests im Git-Checkout
├── .github/workflows/ CI-Konfiguration im Git-Checkout
├── docs/              Dokumentation und Wartungsinformationen
│   ├── commands/      Englische und deutsche Bedienungsanleitungen
│   └── DEVELOPMENT.*   Entwicklungs- und Wartungsrichtlinien
├── Makefile           Test-, Installations- und Deinstallationsziele
├── README.md          Englische Projektbeschreibung
└── README.de.md       Deutsche Projektbeschreibung
```

Installierte Programme und Anleitungen übernehmen die entsprechende Struktur unter dem gewählten `PREFIX`. Tests, CI-Dateien und Entwicklungsrichtlinien bleiben im Checkout. `lib64` ist nur eine vorgesehene Konvention und nicht auf jeder Plattform erforderlich. Git speichert keine leeren Verzeichnisse; deshalb enthalten noch nicht genutzte Ordner eine `.gitkeep`-Datei.

## Voraussetzungen

- Unix-artiges System mit **Bash** und den Standardwerkzeugen `cp`, `mv`, `rm`, `mkdir`, `rmdir` und `mktemp` (lokale Tests unter Linux; CI für Ubuntu und macOS konfiguriert).
- Schreibrechte im Verzeichnis der Datei, die gesichert werden soll.
- `git` zum Klonen sowie optional `make` und `install` für die Installation.
- Für `rotate` wird Bash benötigt, nicht Perl. Die Perl-Programme benötigen Perl ab Version 5.8 sowie die mitgelieferten Bibliotheken aus `lib/`. Für `fs-usage` wird zusätzlich ein POSIX-kompatibles `df` benötigt, für `quota-report` die systemeigenen Programme `quota` oder `repquota`. Unter Linux benötigt `quota-status` ein `quotaon` mit `-p`, das Anwenden mit `quota-set` außerdem `setquota` und aktivierte Quotas. Die meisten Werkzeuge benötigen keine zusätzlichen CPAN-Module; `mail-probe` benötigt jedoch das separat installierte Perl-Modul `IO::Socket::SSL` (ab 2.009). Für dessen Offline-TLS-Tests ist zusätzlich `openssl` erforderlich. `mail-queue` benötigt `JSON::PP` (in aktuellen Perl-Installationen enthalten) und für Live-Abfragen Postfix ab 3.1; Offline-Tests funktionieren ohne Postfix. `mail-config-audit` prüft Textdateien lesend mit Perl-Standardmodulen und benötigt keinen installierten Postfix-Server. `host-resolve` setzt die Socket-APIs für `getaddrinfo`/`getnameinfo` (typischerweise Perl 5.14+) voraus; `ldap-probe` benötigt optional den separat installierten OpenLDAP-Client `ldapsearch`. Für `dns-query` wird optional `dig` benötigt, für `nis-probe` optional `ypwhich`; Konfigurationsprüfungen lesen nur Textdateien. Die Namensdienstprüfungen sind lesend, können aber Netzwerkabfragen auslösen.

## Installation

### Empfohlen: Quellcode klonen und ausführbare Dateien installieren

```sh
git clone https://github.com/SASD-Sysadmin/freeware.git
cd freeware
make test
sudo make install PREFIX=/usr/freeware
```

Dieser Weg installiert die Programme, Manpages und Benutzeranleitungen unter `/usr/freeware`; Tests und Git-Metadaten bleiben im Arbeitsverzeichnis. Für Paketbau und Staging kann `DESTDIR` gesetzt werden: `make install DESTDIR=/tmp/package PREFIX=/usr/freeware`.

### Alternative: Git-Checkout direkt unter /usr/freeware

Du kannst das vollständige Repository auch unter `/usr/freeware` ablegen und dort pflegen. Ein durch root verwalteter Checkout eignet sich allerdings nicht für die tägliche Entwicklungsarbeit; fremde Änderungen sollten vor einer privilegierten Ausführung geprüft werden. Eigentümer und Aktualisierungsweg sollten zu Deiner Systemrichtlinie passen.

Damit die Befehle gefunden werden, ergänze beispielsweise `~/.bashrc`:

```sh
export PATH="/usr/freeware/bin:/usr/freeware/sbin:$PATH"
export MANPATH="/usr/freeware/man:${MANPATH:-}"
```

Alternativ lässt sich die Manpage direkt mit `man -M /usr/freeware/man rotate` aufrufen. In einem anderen Checkout funktioniert der Programmaufruf über `./bin/rotate`.

## Benutzung

```sh
rotate ./settings.conf
rotate '/pfad/mit leerzeichen/hosts kopie'
# Für geschützte Systemdateien sind meist Root-Rechte nötig:
sudo /usr/freeware/bin/rotate /etc/hosts
man -M /usr/freeware/man rotate
```

`rotate` akzeptiert **genau einen** Parameter: eine bestehende reguläre Datei, keinen symbolischen Link. Alle Sicherungen liegen im gleichen Verzeichnis. Zum Anlegen, Umbenennen und Löschen der Sicherungen sind die entsprechenden Verzeichnisrechte erforderlich. Unerwartete Verzeichnisse oder symbolische Links auf den Plätzen `.0` bis `.9` führen zum Abbruch. Alte Sicherungen mit rein numerischer Endung ab `.10` werden entfernt; Namen wie `.01` oder `.10.notes` bleiben erhalten.

Das kurzlebige Sperrverzeichnis `DATEI.rotate.lock` verhindert gleichzeitige Rotationen kooperierender Prozesse. Nach einem erzwungenen Programmabbruch muss eine eventuell zurückgebliebene Sperre geprüft und gegebenenfalls manuell entfernt werden. Die Gesamtabfolge der Umbenennungen ist **nicht transaktional atomar**; bei einem Abbruch sind Lücken möglich. `cp -p` übernimmt Berechtigungen und Zeitstempel, soweit System und Rechte dies zulassen. Sensible Sicherungen müssen über passende Verzeichnisrechte geschützt werden.

Weiterführende Bedienungsanleitungen: [rotate](docs/commands/rotate.de.md), [core-report](docs/commands/core-report.de.md), [path-audit](docs/commands/path-audit.de.md), [Dateisystem- und Kontowerkzeuge](docs/commands/perl-tools.de.md) sowie [SSH-, Integritäts- und Monitoringwerkzeuge](docs/commands/automation-tools.de.md). Entwicklungs- und Wartungsrichtlinien stehen in [docs/DEVELOPMENT.de.md](docs/DEVELOPMENT.de.md).

## Entwicklung und Qualitätssicherung

**Qualitätssicherung:** `make test` führt Offline- und Regressionstests aus. `make integration-test` prüft zusätzlich optional DNS und LDAPS über reale Clients gegen lokale Testdienste. GitHub Actions verlangt beides unter Ubuntu und DNS unter macOS. Siehe [Testanleitung](docs/TESTING.de.md), [Rückgabecodes](docs/EXIT-CODES.de.md) und [Plattformübersicht](docs/PLATFORMS.de.md). Die Testdienste sind keine vollständigen produktiven DNS-/LDAP-Server.

```sh
make test
make integration-test  # optional; dig/ldapsearch ggf. installieren
bash -n bin/rotate
```

Die Bash-Tests prüfen die Dateirotation. Die Perl-Tests prüfen Dateisystemberichte, Pfadlängen, Core-Dateien, Hosts-Dateien, Benutzerkonten, Logs, SSH-Schlüsseldateien, Datei-Integrität, SUID/SGID und TCP-Erreichbarkeit einschließlich Fehlerfällen. GitHub Actions soll die Tests unter Ubuntu und macOS bei Pushes und Pull Requests ausführen; die Konfiguration allein bedeutet noch keinen erfolgreichen CI-Lauf.

## Beiträge, Lizenz und Sicherheit

Hinweise zur Mitarbeit stehen in [CONTRIBUTING.md](CONTRIBUTING.md), Sicherheitsmeldungen in [SECURITY.md](SECURITY.md) und die Entwicklungshistorie in [CHANGELOG.md](CHANGELOG.md). Für das Repository gilt die vorhandene [MIT-Lizenz](LICENSE). Bevor Werkzeuge mit erhöhten Rechten ausgeführt werden, sollten Code und benötigte Berechtigungen geprüft werden.

**Projekt:** [github.com/SASD-Sysadmin/freeware](https://github.com/SASD-Sysadmin/freeware)
