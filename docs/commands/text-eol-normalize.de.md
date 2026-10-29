# `text-eol-normalize` — Sichere Umwandlung von CRLF nach LF

[English](text-eol-normalize.md) | [Deutsch](text-eol-normalize.de.md) · [Projekt-README](../../README.de.md) · [Manpage](../../man/man1/text-eol-normalize.1)

## Zweck

Das Werkzeug erkennt DOS-/Windows-Zeilenenden (`CRLF`, oft als `^M` sichtbar) und ersetzt sie auf ausdrücklichen Wunsch durch Unix-Zeilenenden (`LF`). Bereits korrekt formatierte Dateien werden **nicht neu geschrieben**. Gemischte CRLF-/LF-Zeilenenden werden vereinheitlicht. Es kann einzelne Dateien oder Verzeichnisse prüfen; `--recursive` schaltet die Suche in Unterverzeichnissen frei.

Die Erkennung sagt **nicht**, auf welchem Betriebssystem die Datei erstellt wurde, sondern ausschließlich etwas über deren Zeilenenden.

## Beispiele

```sh
text-eol-normalize --check --recursive /srv/import
text-eol-normalize --dry-run --recursive /srv/import
text-eol-normalize --apply --recursive --min-age 120 /srv/import
```

Standard ist `--check` ohne Änderungen. `--dry-run` meldet geplante Änderungen als `WOULD_CONVERT`. Erst `--apply` schreibt umgewandelte Dateien und meldet sie als `CONVERT`. Ein Fehlercode signalisiert Verarbeitungsfehler, **nicht** bloß das Vorhandensein von CRLF.

| Option | Bedeutung |
| --- | --- |
| `--check` | Nur prüfen (Standard). |
| `--dry-run` | Änderungen anzeigen, nicht ausführen. |
| `--apply` | Tatsächlich umwandeln. |
| `--recursive` | Unterverzeichnisse untersuchen; Symlinks nicht folgen. |
| `--one-file-system` | Bei rekursiver Suche auf einem Dateisystem bleiben. |
| `--include EXT` | Dateiendung zulassen, wiederholbar; ersetzt die Standardliste. |
| `--exclude EXT` | Dateiendung ausschließen, wiederholbar. |
| `--min-age SEKUNDEN` | Kürzlich geänderte Dateien auslassen. |
| `--max-bytes N` | Maximalgröße (Standard 16 MiB, Obergrenze 1 GiB). |
| `--verbose` | Auch übersprungene Dateien und Gründe melden. |

Die voreingestellten Dateiendungen sind `txt`, `csv`, `sh`, `md`, `conf`, `cfg`, `ini`, `json`, `xml`, `yaml`, `yml`, `sql`, `py` und `pl`. `bin`, `xls`, `xlsx`, `xlsm` und `xlsb` bleiben ausnahmslos ausgeschlossen. Binärinhalte werden zusätzlich durch eine vollständige (größenbegrenzte) Prüfung auf NUL und unzulässige Steuerzeichen erkannt. UTF-16-/UTF-32-Dateien und Dateien mit alleinstehenden CR-Zeichen werden vorsichtshalber übersprungen.

## Cron-Beispiel

```cron
*/15 * * * * /usr/bin/flock -n /var/lock/sasd-eol-import.lock /usr/freeware/bin/text-eol-normalize --apply --recursive --min-age 120 /srv/import >> /var/log/sasd-eol-import.log 2>&1
```

Das ausführende Benutzerkonto muss auf die Dateien und deren Verzeichnisse zugreifen und dort neue Dateien anlegen sowie umbenennen dürfen. Der Lock-Pfad muss beschreibbar sein. `flock` gehört nur zum Linux-Beispiel und ist keine Abhängigkeit des Programms. **Bitte nur vollständig übertragene Dateien in einem kontrollierten Importverzeichnis verarbeiten.** Das Mindestalter ist keine Garantie, dass ein Schreibprozess beendet ist. Noch sicherer ist die Übernahme fertiger Dateien durch atomares Umbenennen.

## Sicherheitsgrenzen

- Ohne `--apply` bleibt alles unverändert. Dateien ohne CRLF werden auch bei `--apply` nicht neu geschrieben.
- Symlinks werden nicht verfolgt; Hardlinks und setuid-/setgid-Dateien werden ausgelassen. Die Datei muss dem effektiv ausführenden Benutzer gehören.
- Eine Konvertierung wird zunächst in eine private temporäre Datei im gleichen Verzeichnis geschrieben. Danach wird diese über den ursprünglichen Dateinamen umbenannt; bei Schreibfehlern bleibt die Ursprungsdatei erhalten.
- **Die Inode-Nummer und die Änderungszeit ändern sich.** Normale Dateirechte und die Gruppe bleiben nach Möglichkeit erhalten. **ACLs, Extended Attributes, Dateiflags, besondere Metadaten, Sparse-Eigenschaften, ursprüngliche Zeitstempel und fremdes Eigentum werden nicht erhalten.** Deshalb nicht unbesehen auf Systemdateien oder besonders geschützte Daten anwenden.
- Änderungen durch gleichzeitig schreibende Fremdprozesse können im kurzen Zeitfenster vor dem Umbenennen nicht vollständig verhindert werden. Ein Dateisperrmechanismus auf Aufruferseite und kontrollierte Eingangsverzeichnisse sind erforderlich. Crash-Durability (`fsync`) ist nicht zugesichert.
- Das Programm ist kein allgemeiner Zeichensatzkonverter. Es verarbeitet nur konservativ als Text erkannte Dateien, keine Binärdaten oder unbekannten Kodierungen.

## Installation und Tests

```sh
make test
make install PREFIX=/usr/freeware DESTDIR=/tmp/staging-root
```

Die automatischen Tests arbeiten ausschließlich in temporären Verzeichnissen und prüfen LF, CRLF, gemischte Zeilenenden, Blockgrenzen, Sonderdateinamen, Binärdateien, ausgeschlossene Endungen, Symlinks, Hardlinks, Dateialter, Dry-Run und wiederholte Ausführung. Die Perl-Implementierung benötigt kein `dos2unix`. Geplante Portabilität ist nicht mit geprüfter Plattformunterstützung gleichzusetzen; vor produktivem Cron-Einsatz ist ein isolierter Praxistest sinnvoll.

Rückgabewerte: `0` erfolgreich, `1` Dateiverarbeitungsfehler, `2` fehlerhafte Parameter. Die Ausgabe enthält eine Statistik mit `examined`, `dos`, `converted`, `skipped` und `errors`.

MIT-Lizenz.
