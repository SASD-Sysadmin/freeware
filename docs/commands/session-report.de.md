# session-report – Aktive Benutzersitzungen

[English](session-report.md) · [Projekt](../../README.de.md) · [Kapitelplanung](../ROADMAP.de.md)

`session-report` listet interaktive Anmeldesitzungen mit Benutzer, Terminal und
unverändertem, systemspezifischem Zeit-/Herkunftstext auf. Es nutzt `who`
(ohne Shell) und verändert keine Anmeldedaten. Unter Linux und macOS können
Datums- und Herkunftsangaben unterschiedlich aussehen; sie werden bewusst
**nicht** als einheitliche Zeitstempel ausgegeben.

## Beispiele

```sh
./bin/session-report
./bin/session-report --user alice
./bin/session-report --input ./tests/fixtures/who.txt
./bin/session-report --null > sessions.bin
```

Die Textausgabe hat `USER`, `TTY`, `DETAILS` sowie zwei Summen (`Sessions`,
`Users`). `--user` schränkt die Sicht auf einen Kontonamen ein. `--null`
ermöglicht drei rohe NUL-getrennte Felder je Sitzung ohne Kopfzeile und
Zusammenfassung. Tabs, Zeilenumbrüche und Backslashes werden in der lesbaren
Tabelle escaped. Mit `--input FILE` kann eine zuvor gespeicherte `who`-Ausgabe
reproduzierbar analysiert werden (nur reguläre Dateien, keine Symlinks).

## Grenzen und Sicherheit

- Nur die von `who` sichtbaren **aktuellen** Sitzungen; kein historisches
  Login-Audit, keine Garantie für sämtliche Remote-Sitzungen oder Container.
- Keine Root-Rechte, kein `sudo`, keine Konto- oder Sitzungsänderungen.
- Benutzer, Terminal und Host-Angaben können personenbezogene Betriebsdaten
  enthalten. Ausgabe und gespeicherte Dateien entsprechend schützen.
- Backend wird ausschließlich über `/usr/bin/who` oder `/bin/who` ausgeführt;
  die Suchreihenfolge des aufrufenden `PATH` wird nicht verwendet.

## Rückgabewerte

`0` vollständig gelesen (auch bei 0 Sitzungen); `1` fehlerhafte Zeilen
übersprungen, andere Zeilen trotzdem angezeigt; `2` ungültiger Aufruf;
`3` Quelle bzw. Systemkommando nicht verfügbar oder Ausführungsfehler.
Perl 5 mit Kernmodul `Getopt::Long`; keine CPAN-Abhängigkeiten.
