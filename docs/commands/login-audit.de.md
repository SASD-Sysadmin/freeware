# login-audit – Historische Linux-Anmeldungen untersuchen

[English](login-audit.md) · [Projekt](../../README.de.md) · [Kapitelplanung](../ROADMAP.de.md)

`login-audit` wertet vorhandene Anmeldehistorie **nur lesend** aus. Unter Linux
verwendet es `last` (wtmp, erfolgreiche Sitzungen) und `lastb` (btmp,
fehlgeschlagene Anmeldeversuche) mit `--time-format iso -w`. Es verwendet
absolute Programmpfade ohne Shell-Aufruf. Es erzeugt **keine** Anmeldungen,
verändert keine Konten und benötigt keine erweiterten Rechte zum Starten.
Das Lesen von btmp kann jedoch entsprechende Zugriffsrechte voraussetzen.

## Beispiele

```sh
./bin/login-audit --kind success --user alice
./bin/login-audit --kind failed --limit 20
./bin/login-audit --kind both
./bin/login-audit --kind success --input-success last-saved.txt
./bin/login-audit --kind both --input-success last-saved.txt --input-failed lastb-saved.txt --null > audit.bin
```

`--kind` wählt `success`, `failed` oder `both` (Standard). `--user` filtert
exakt nach dem Login-Namen. `--limit` begrenzt die **gemeinsam** angezeigten
Zeilen (1–1000, Standard 100). Pro Quelle liest das native Backend höchstens
5000 Einträge; die Auswertung ist daher weder zeitlich noch quantitativ
vollständig. Bei `both` erscheinen zunächst `success`, dann `failed`; die
Ausgabe ist **nicht chronologisch zusammengeführt**.

Tabellenspalten: `KIND`, `USER`, `TTY`, `HOST`, `LOGIN`, `DETAILS`. Der
Zeitstempel `LOGIN` behält die von `last` ausgegebene Zeitzone. `DETAILS`
enthält die restliche, systemspezifische Sitzungs-/Abmeldeinformation, keine
normalisierte Endzeit. Die maschinenlesbare Option `--null` liefert dieselben
sechs Felder NUL-terminiert und unterdrückt Kopfzeile und Summen.

## Gespeicherte Daten und Plattformen

`--input-success FILE` und `--input-failed FILE` lesen gespeicherte,
**kopfzeilenlose beziehungsweise footerhaltige** Ausgaben von
`last --time-format iso -w` oder `lastb --time-format iso -w`, nicht die
binären wtmp-/btmp-Dateien. Im Fixture-Modus muss für jede mit `--kind`
angeforderte Kategorie eine Datei angegeben werden. Reguläre Dateien sind
erlaubt, Symlinks werden verweigert. Diese Betriebsart ist auf Linux und
macOS verwendbar. Das native Backend ist zurzeit **nur Linux**; auf macOS
wird ein Live-Aufruf mit Exit 3 ausdrücklich verweigert. BSD- und
macOS-eigene Varianten von `last` haben abweichende Ausgabeformate.

## Fehlergrenzen und Datenschutz

- Exit **0**: ausgewählte Quellen verarbeitet; null Zeilen sind **kein** Beleg
  für null Anmeldeversuche. Exit **1**: mindestens ein beschädigter Datensatz;
  die übrigen Zeilen werden ausgegeben. Exit **2**: Parameterfehler. Exit
  **3**: fehlende/unlesbare Quelle, Backendfehler oder nicht unterstützte
  native Plattform; teilweise gesammelte Daten werden nicht ausgegeben.
- Fehlgeschlagene Anmeldungen können fehlen, wenn btmp deaktiviert, rotiert
  oder nicht lesbar ist. SSH/PAM-/Journalereignisse werden **nicht** zusätzlich
  abgefragt. `last`/`lastb` liefern keine garantierte, manipulationssichere
  Vollständigkeit und keine automatische Angriffsdiagnose.
- Berichte enthalten möglicherweise persönliche Benutzernamen, Hostnamen und
  Zeitangaben. Sensibel speichern und Zugriff beschränken.
- Tests verwenden ausschließlich synthetische Eingabedateien.

Benötigt Perl 5 mit `Getopt::Long` (Kernmodul); für native Linux-Abfragen
util-linux `last`/`lastb` mit ISO-Zeitformat-Unterstützung.
