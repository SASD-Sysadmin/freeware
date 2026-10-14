# process-report – Laufende Prozesse nach Benutzer und Status

[English](process-report.md) · [Projekt](../../README.de.md) · [Kapitelplanung](../ROADMAP.de.md)

`process-report` erzeugt eine **lesende Momentaufnahme** der laufenden Prozesse.
Es verwendet das systemeigene `ps` mit den Feldern `pid`, `ppid`, `user`,
`stat`, `etime` und `comm`. Linux und macOS werden unterstützt, ohne
Linux-spezifische `/proc`-Annahmen.

## Beispiele

```sh
./bin/process-report
./bin/process-report --user alice --limit 25
./bin/process-report --state Z
./bin/process-report --input ps-snapshot.txt --null > processes.bin
```

Die Ausgabe enthält `PID`, `PPID`, `USER`, `STATE`, `ELAPSED` und `COMMAND`.
`--state` filtert nach dem **ersten Buchstaben** des von `ps` gelieferten
Status (`R`, `S`, `Z` usw.); Zusatzzeichen wie `+` bleiben in der Ausgabe.
`--limit` begrenzt angezeigte Zeilen auf 1 bis 5000 (Standard: 200).
`Matching` zählt alle gültigen Treffer, `Shown` die tatsächlich angezeigten.
`--null` gibt sechs rohe NUL-Felder je ausgegebener Zeile ohne Überschrift oder
Summen aus. `--input FILE` akzeptiert eine reguläre Datei (keinen symbolischen Link)
auf eine gespeicherte, **kopfzeilenlose** `ps`-Ausgabe des obigen Formats.

## Grenzen und Sicherheit

- Eine Momentaufnahme ist keine Prozesshistorie und kein Beweis für
  Benutzeraktivität; Prozesse können zwischen Messungen verschwinden.
- Der `comm`-Wert ist die vom Betriebssystem gelieferte Programmbezeichnung,
  keine zuverlässig vollständige Kommandozeile.
- Keine Root-Rechte, keine Signale, keine Prozessänderungen. Die Sichtbarkeit
  hängt von Systemkonfiguration und Berechtigungen ab.
- Benutzer- und Prozessbezeichnungen können vertraulich sein; Berichte
  entsprechend schützen.
- Ausführung nur von `/bin/ps` oder `/usr/bin/ps`, ohne Shell oder `PATH`.

## Rückgabewerte

`0` vollständig gelesen, `1` fehlerhafte Datensätze übersprungen,
`2` Parameterfehler, `3` Datei oder System-Backend nicht verfügbar.
Perl 5 und Kernmodul `Getopt::Long`; keine CPAN-Module.
