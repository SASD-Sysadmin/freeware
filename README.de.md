# SASD Freeware

[English](README.md) | **Deutsch** · [MIT-Lizenz](LICENSE) · [Mitwirkung](CONTRIBUTING.md) · [Änderungsprotokoll](CHANGELOG.md)

SASD Freeware stellt Kommandozeilenprogramme, Scripts und Bibliotheken für die Systemadministration unter Linux und Unix bereit. Die Werkzeuge sind für einen zuverlässigen Betrieb, die unkomplizierte Integration in bestehende Umgebungen und eine langfristige Wartbarkeit ausgelegt. Zu jedem Programm gehören Dokumentation, praktische Anwendungsbeispiele und automatisierte Tests.

## Enthaltenes Werkzeug

| Befehl | Pfad | Funktion | Dokumentation |
| --- | --- | --- | --- |
| `core-report` | [`bin/core-report`](bin/core-report) | Dateien mit Core-Dump-typischen Namen und ihre Größen erfassen. | [Deutsch](docu/core-report.de.md) · [English](docu/core-report.md) · [Manpage](man/man1/core-report.1) |
| `path-audit` | [`bin/path-audit`](bin/path-audit) | Überlange Pfadkomponenten und Pfadnamen ermitteln. | [Deutsch](docu/path-audit.de.md) · [English](docu/path-audit.md) · [Manpage](man/man1/path-audit.1) |
| `rotate` | [`bin/rotate`](bin/rotate) | Bis zu zehn Sicherungsgenerationen einer regulären Datei (`.0` neueste, `.9` älteste). | [Deutsch](docu/rotate.de.md) · [English](docu/rotate.md) · [Manpage](man/man1/rotate.1) |
| `fs-report` | [`bin/fs-report`](bin/fs-report) | Verzeichnisse und logische Dateigrößen erfassen. | [Anleitung](docu/fs-report.de.md) · [English](docu/fs-report.md) · [Manpage](man/man1/fs-report.1) |
| `largefiles` | [`bin/largefiles`](bin/largefiles) | Große reguläre Dateien ermitteln. | [Anleitung](docu/largefiles.de.md) · [English](docu/largefiles.md) · [Manpage](man/man1/largefiles.1) |
| `fs-usage` | [`bin/fs-usage`](bin/fs-usage) | Dateisystembelegung per df prüfen. | [Anleitung](docu/fs-usage.de.md) · [English](docu/fs-usage.md) · [Manpage](man/man1/fs-usage.1) |
| `quota-report` | [`bin/quota-report`](bin/quota-report) | Benutzer-, Gruppen- und Dateisystem-Quotas abfragen. | [Anleitung](docu/quota-report.de.md) · [English](docu/quota-report.md) · [Manpage](man/man1/quota-report.1) |
| `hosts-lint` | [`bin/hosts-lint`](bin/hosts-lint) | Syntaxprüfung der Hosts-Datei. | [Perl-Anleitung](docu/perl-tools.de.md) · [Manpage](man/man1/hosts-lint.1) |
| `account-audit` | [`bin/account-audit`](bin/account-audit) | Strukturanalyse einer Unix-Kontodatei. | [Perl-Anleitung](docu/perl-tools.de.md) · [Manpage](man/man1/account-audit.1) |
| `log-summary` | [`bin/log-summary`](bin/log-summary) | Logmeldungen nach Schweregrad zählen. | [Perl-Anleitung](docu/perl-tools.de.md) · [Manpage](man/man1/log-summary.1) |
| `ssh-key-audit` | [`bin/ssh-key-audit`](bin/ssh-key-audit) | SSH-Schlüsseldatei schreibgeschützt prüfen. | [Automatisierungs-Anleitung](docu/automation-tools.de.md) · [Manpage](man/man1/ssh-key-audit.1) |
| `file-integrity` | [`bin/file-integrity`](bin/file-integrity) | SHA-256-Basisliste erstellen und Änderungen prüfen. | [Automatisierungs-Anleitung](docu/automation-tools.de.md) · [Manpage](man/man1/file-integrity.1) |
| `suid-audit` | [`bin/suid-audit`](bin/suid-audit) | SUID-/SGID-Dateien inventarisieren. | [Automatisierungs-Anleitung](docu/automation-tools.de.md) · [Manpage](man/man1/suid-audit.1) |
| `tcp-check` | [`bin/tcp-check`](bin/tcp-check) | TCP-Port erreichbar? Optional Nagios-Rückgabewerte. | [Automatisierungs-Anleitung](docu/automation-tools.de.md) · [Manpage](man/man1/tcp-check.1) |

Beispiel: `rotate /etc/hosts` erstellt `/etc/hosts.0`, während `/etc/hosts` unverändert bleibt. Beim nächsten Aufruf wird die bisherige `.0` zu `.1`, und eine neue `.0` entsteht. Sind zehn Generationen vorhanden, wird `.9` vor dem Nachrücken gelöscht. `rotate` ist ein **einfaches Hilfswerkzeug zur Dateisicherung**, aber kein Ersatz für Backups, Versionsverwaltung oder eine umfangreiche `logrotate`-Konfiguration.

## Vorgesehene Verzeichnisstruktur

```text
/usr/freeware/
├── bin/               Benutzerprogramme (rotate und Perl-Werkzeuge)
├── sbin/              Administrationsprogramme (reserviert)
├── lib/               Architekturunabhängige Bibliotheken
├── lib64/             64-Bit-Bibliotheken (reserviert)
├── man/
│   └── man1/          Handbuchseiten für alle Programme
├── docu/              Englische und deutsche Bedienungsanleitungen
├── tests/             Automatisierte Tests im Git-Checkout
├── .github/workflows/ CI-Konfiguration im Git-Checkout
├── docs/              Entwicklungs- und Wartungsinformationen
├── Makefile           Test-, Installations- und Deinstallationsziele
├── README.md          Englische Projektbeschreibung
└── README.de.md       Deutsche Projektbeschreibung
```

Die Verzeichnisnamen orientieren sich bewusst an der geplanten Installation. `lib64` ist nur eine vorgesehene Konvention und nicht auf jeder Plattform erforderlich. Git speichert keine leeren Verzeichnisse; deshalb enthalten noch nicht genutzte Ordner eine `.gitkeep`-Datei.

## Voraussetzungen

- Unix-artiges System mit **Bash** und den Standardwerkzeugen `cp`, `mv`, `rm`, `mkdir`, `rmdir` und `mktemp` (lokale Tests unter Linux; CI für Ubuntu und macOS konfiguriert).
- Schreibrechte im Verzeichnis der Datei, die gesichert werden soll.
- `git` zum Klonen sowie optional `make` und `install` für die Installation.
- Für `rotate` wird Bash benötigt, nicht Perl. Die Perl-Programme benötigen Perl ab Version 5.8 sowie die mitgelieferten Bibliotheken aus `lib/`. Für `fs-usage` wird zusätzlich ein POSIX-kompatibles `df` benötigt, für `quota-report` die systemeigenen Programme `quota` oder `repquota`. Zusätzliche CPAN-Module sind nicht erforderlich.

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

Weiterführende Bedienungsanleitungen: [rotate](docu/rotate.de.md), [core-report](docu/core-report.de.md), [path-audit](docu/path-audit.de.md), [Dateisystem- und Kontowerkzeuge](docu/perl-tools.de.md) sowie [SSH-, Integritäts- und Monitoringwerkzeuge](docu/automation-tools.de.md). Entwicklungs- und Wartungsrichtlinien stehen in [docs/DEVELOPMENT.de.md](docs/DEVELOPMENT.de.md).

## Entwicklung und Qualitätssicherung

```sh
make test
bash -n bin/rotate
```

Die Bash-Tests prüfen die Dateirotation. Die Perl-Tests prüfen Dateisystemberichte, Pfadlängen, Core-Dateien, Hosts-Dateien, Benutzerkonten, Logs, SSH-Schlüsseldateien, Datei-Integrität, SUID/SGID und TCP-Erreichbarkeit einschließlich Fehlerfällen. GitHub Actions soll die Tests unter Ubuntu und macOS bei Pushes und Pull Requests ausführen; die Konfiguration allein bedeutet noch keinen erfolgreichen CI-Lauf.

## Beiträge, Lizenz und Sicherheit

Hinweise zur Mitarbeit stehen in [CONTRIBUTING.md](CONTRIBUTING.md), Sicherheitsmeldungen in [SECURITY.md](SECURITY.md) und die Entwicklungshistorie in [CHANGELOG.md](CHANGELOG.md). Für das Repository gilt die vorhandene [MIT-Lizenz](LICENSE). Bevor Werkzeuge mit erhöhten Rechten ausgeführt werden, sollten Code und benötigte Berechtigungen geprüft werden.

**Projekt:** [github.com/SASD-Sysadmin/freeware](https://github.com/SASD-Sysadmin/freeware)
