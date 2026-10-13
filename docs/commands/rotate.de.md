# `rotate` — Rotierende Dateisicherungen

[English](rotate.md) | [Deutsch](rotate.de.md) · [Projektbeschreibung](../../README.de.md) · [Manpage](../../man/man1/rotate.1)

## Zusammenfassung

`rotate` erstellt eine durchnummerierte Kopie einer vorhandenen regulären Datei, ohne deren Inhalt zu verändern. Im gleichen Verzeichnis werden bis zu zehn Generationen vorgehalten: `.0` ist die neueste, `.9` die älteste. Bei jedem Aufruf rücken bisherige Kopien um eine Nummer weiter; die bisherige `.9` wird bei Bedarf entfernt. Zusätzlich werden ältere Sicherungen mit rein numerischen Endungen ab `.10` gelöscht. Das Programm ist in Bash implementiert und verwendet übliche Unix-Werkzeuge.

## Aufruf und Beispiel

```text
rotate DATEI
```

```sh
printf '%s\n' '127.0.0.1 localhost' > hosts
./bin/rotate hosts
# erzeugt hosts.0; hosts bleibt unverändert
./bin/rotate hosts
# hosts.0 -> hosts.1; eine neue hosts.0 wird erstellt
```

Die Sicherungen liegen **neben der Originaldatei**. Bei Pfaden mit Leerzeichen sind Anführungszeichen erforderlich. Auch Dateinamen, die mit `-` beginnen, werden verarbeitet.

## Regeln für die Versionen

| Datei | Bedeutung |
| --- | --- |
| `DATEI` | Original, bleibt unverändert |
| `DATEI.0` | Neueste Sicherung |
| `DATEI.1` | Vorherige Sicherung |
| `DATEI.9` | Älteste verbleibende Sicherung |
| `DATEI.10` und höher | Rein numerisch benannte alte Sicherungen; vorhandene reguläre Dateien und Links werden gelöscht |
| `DATEI.01`, `DATEI.10.notes` | Keine erkannten Versionsnummern; bleiben erhalten |
| `DATEI.rotate.lock` | Temporäres Sperrverzeichnis gegen parallele Aufrufe |

Zuerst kopiert das Script den Inhalt in eine temporäre Datei im gleichen Verzeichnis. Scheitert dies, bleiben die bestehenden Sicherungen unberührt. Danach entfernt es alte `.10+`-Dateien sowie `.9`, verschiebt `.8` nach `.9` bis `.0` nach `.1` und setzt die vorbereitete Kopie als `.0` ein. Der Verschiebevorgang ist **nicht atomar** und wird bei einer Unterbrechung nicht automatisch rückgängig gemacht.

## Eingaben und Sicherheit

- Genau ein Dateipfad ist erforderlich. Er muss auf eine vorhandene **reguläre Datei** zeigen, nicht auf einen symbolischen Link oder ein Verzeichnis.
- Die Plätze `.0` bis `.9` dürfen fehlen oder reguläre Dateien sein. Ein Link, Verzeichnis oder eine Spezialdatei an diesen Stellen führt zum Abbruch vor der Rotation.
- Während der Ausführung wird `DATEI.rotate.lock` mit eingeschränkten Berechtigungen angelegt. Existiert die Sperre bereits, bricht das Programm ab. Nach `SIGKILL` oder einem Absturz kann sie zurückbleiben; vor dem Entfernen prüfen, dass keine Rotation mehr läuft.
- Im Verzeichnis der Originaldatei werden Schreibrechte benötigt. Bei `/etc/hosts` sind hierfür in der Regel Root-Rechte erforderlich.
- `cp -p` versucht, Dateimodus, Zeitstempel und Eigentümer gemäß den Möglichkeiten und Rechten des Systems zu erhalten. Sicherungen enthalten den vollständigen Originalinhalt, möglicherweise einschließlich Zugangsdaten. Das Verzeichnis entsprechend schützen.
- Das Script sperrt keine anderen Programme, die die Originaldatei gleichzeitig bearbeiten. Bei einer laufenden Änderung kann die Kopie einen Zwischenstand enthalten. Es ist kein Datenbank-Backup und kein transaktionaler Snapshot.
- Die Abfolge ist nicht vollständig absturzsicher. Andere Programme sollten nicht gleichzeitig dieselben Sicherungsnamen benutzen.

## Sicherung wiederherstellen

Vor dem Zurückkopieren die gewünschte Version prüfen:

```sh
ls -l -- /etc/hosts /etc/hosts.[0-9]
# Nach Prüfung mit geeigneten Rechten:
cp -p -- /etc/hosts.2 /etc/hosts
```

Dieser Vorgang überschreibt die Originaldatei und erstellt **keine** neue Sicherungsversion. Bei wichtigen Daten vorher noch eine zusätzliche Kopie anlegen. Sensible Inhalte nicht versehentlich in öffentlich zugängliche Logs kopieren.

## Installation, Tests und Fehlerbehebung

`make test && sudo make install PREFIX=/usr/freeware` installiert Programm und Handbuchseite. Alternativ ist `./bin/rotate` direkt im Repository ausführbar. Nach der Installation zeigt `man -M /usr/freeware/man rotate` die Handbuchseite. `make test` arbeitet ausschließlich mit temporären Testdateien und verändert `/etc` nicht.

Rückgabewerte: `0` bedeutet Erfolg, `2` eine falsche Anzahl von Parametern und ein anderer Wert ungleich null einen Datei-, Sperr- oder Betriebssystemfehler. Fehlermeldungen erscheinen auf der Standardfehlerausgabe. Bei einer verbliebenen Sperre zuerst den möglichen aktiven Prozess prüfen. Nach einem teilweise abgebrochenen Vorgang vor einem weiteren Aufruf sämtliche vorhandenen Versionen `DATEI.[0-9]` kontrollieren.

## Plattformen und Grenzen

Das Script setzt Bash voraus und vermeidet bewusst Funktionen, die Bash 4 erfordern; dies ist für ältere macOS-Bash-Versionen hilfreich. Es verwendet übliche GNU-/BSD-Werkzeuge. Eine CI-Prüfung ist für Ubuntu und macOS konfiguriert; maßgeblich sind die tatsächlichen Ergebnisse auf GitHub. Für umfangreiche Logrotation, Dateisystem-Snapshots und externe Backups sind geeignete Speziallösungen vorzuziehen.

Es gilt die [MIT-Lizenz](../../LICENSE) des Repositories.
