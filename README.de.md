# SASD Freeware

[English](README.md) | **Deutsch** · [MIT-Lizenz](LICENSE) · [Mitwirkung](CONTRIBUTING.md) · [Änderungsprotokoll](CHANGELOG.md)

**SASD-SysAdmin** stellt in diesem Repository kleine, praxisorientierte Kommandozeilenprogramme und Werkzeuge für die Systemadministration bereit. Die Verzeichnisstruktur ist auf eine Installation unter `/usr/freeware` ausgelegt, damit die Dateien nicht mit den von der Distribution verwalteten Verzeichnissen `/usr/bin` oder `/usr/lib` vermischt werden. Langfristig können hier Werkzeuge in Bash, Perl, Python, (t)csh und weiteren Sprachen Platz finden.

> **Projektstatus:** Frühe Aufbauphase. `rotate` ist das erste verfügbare Werkzeug. Weitere Verzeichnisse sind vorerst Platzhalter und enthalten noch keine Programme.

## Enthaltenes Werkzeug

| Befehl | Pfad | Funktion | Dokumentation |
| --- | --- | --- | --- |
| `rotate` | [`bin/rotate`](bin/rotate) | Bis zu zehn Sicherungsgenerationen einer regulären Datei (`.0` neueste, `.9` älteste). | [Deutsch](docu/rotate.de.md) · [English](docu/rotate.md) · [Manpage](man/man1/rotate.1) |

Beispiel: `rotate /etc/hosts` erstellt `/etc/hosts.0`, während `/etc/hosts` unverändert bleibt. Beim nächsten Aufruf wird die bisherige `.0` zu `.1`, und eine neue `.0` entsteht. Sind zehn Generationen vorhanden, wird `.9` vor dem Nachrücken gelöscht. `rotate` ist ein **einfaches Hilfswerkzeug zur Dateisicherung**, aber kein Ersatz für Backups, Versionsverwaltung oder eine umfangreiche `logrotate`-Konfiguration.

## Vorgesehene Verzeichnisstruktur

```text
/usr/freeware/
├── bin/               Benutzerprogramme (rotate)
├── sbin/              Administrationsprogramme (reserviert)
├── lib/               Architekturunabhängige Bibliotheken (reserviert)
├── lib64/             64-Bit-Bibliotheken (reserviert)
├── man/
│   └── man1/          Handbuchseiten (rotate.1)
├── docu/              Ausführliche Anleitungen in EN und DE
├── tests/             Automatisierte Tests im Git-Checkout
├── .github/workflows/ CI-Konfiguration im Git-Checkout
├── Makefile           Test-, Installations- und Deinstallationsziele
├── README.md          Englische Projektbeschreibung
└── README.de.md       Deutsche Projektbeschreibung
```

Die Verzeichnisnamen orientieren sich bewusst an der geplanten Installation. `lib64` ist nur eine vorgesehene Konvention und nicht auf jeder Plattform erforderlich. Git speichert keine leeren Verzeichnisse; deshalb enthalten noch nicht genutzte Ordner eine `.gitkeep`-Datei.

## Voraussetzungen

- Unix-artiges System mit **Bash** und den Standardwerkzeugen `cp`, `mv`, `rm`, `mkdir`, `rmdir` und `mktemp` (lokale Tests unter Linux; CI für Ubuntu und macOS konfiguriert).
- Schreibrechte im Verzeichnis der Datei, die gesichert werden soll.
- `git` zum Klonen sowie optional `make` und `install` für die Installation.
- Für `rotate` werden weder Python noch Perl oder zusätzliche Pakete benötigt.

## Installation

### Empfohlen: Quellcode klonen und ausführbare Dateien installieren

```sh
git clone https://github.com/SASD-Sysadmin/freeware.git
cd freeware
make test
sudo make install PREFIX=/usr/freeware
```

Dieser Weg installiert **nur** `bin/rotate` und `man/man1/rotate.1` unter `/usr/freeware`; Quellcode, Tests und Git-Metadaten bleiben im Arbeitsverzeichnis. Für Paketbau und Staging kann `DESTDIR` gesetzt werden: `make install DESTDIR=/tmp/package PREFIX=/usr/freeware`.

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

Weitere Beispiele, Wiederherstellung und Fehlersuche: [ausführliche rotate-Anleitung](docu/rotate.de.md).

## Entwicklung und Qualitätssicherung

```sh
make test
bash -n bin/rotate
```

Die Tests prüfen die Begrenzung auf zehn Versionen, das Löschen älterer Generationen, Dateinamen mit Leerzeichen, Binärdaten, fehlerhafte Argumente, Sperren und Konflikte mit vorhandenen Sicherungsnamen. GitHub Actions soll die Tests unter Ubuntu und macOS bei Pushes und Pull Requests ausführen; die Konfiguration allein bedeutet noch keinen erfolgreichen CI-Lauf.

## Beiträge, Lizenz und Sicherheit

Hinweise zur Mitarbeit stehen in [CONTRIBUTING.md](CONTRIBUTING.md), Sicherheitsmeldungen in [SECURITY.md](SECURITY.md) und die Entwicklungshistorie in [CHANGELOG.md](CHANGELOG.md). Für das Repository gilt die vorhandene [MIT-Lizenz](LICENSE). Bevor Werkzeuge mit erhöhten Rechten ausgeführt werden, sollten Code und benötigte Berechtigungen geprüft werden.

**Projekt:** [github.com/SASD-Sysadmin/freeware](https://github.com/SASD-Sysadmin/freeware)
