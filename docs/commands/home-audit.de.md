# home-audit

[English](home-audit.md) · [Projekt](../../README.de.md)

`home-audit` überprüft ausschließlich die Metadaten der Home-Verzeichnisse aus einer **lokalen passwd-Datei**. Es durchläuft keine privaten Benutzerdateien und ändert keine Eigentümer, Rechte oder Verzeichnisse.

```sh
./bin/home-audit
./bin/home-audit --file ./passwd.sample --all
./bin/home-audit --min-uid 2000 --max-uid 49999
./bin/home-audit --all --null > homes.bin
```

Standardmäßig werden UIDs von **1000 bis 59999** einschließlich geprüft. Damit werden übliche System- und `nobody`-Konten ausgeschlossen. Diese Grenzen sind eine veränderbare Richtlinie und **keine universelle Unix-Definition persönlicher Benutzer**. Mit `--all` untersucht das Werkzeug sämtliche gültigen lokalen Datensätze, auch Systemkonten. Deren Home-Verzeichnis kann absichtlich fehlen oder ungewöhnlich sein.

Mögliche Befunde: `missing` (nicht vorhanden), `symlink` (symbolischer Link), `not-directory` (kein Verzeichnis), `wrong-owner` (UID weicht ab) und `world-writable` (für alle beschreibbar). Befunde sind nicht automatisch Sicherheitsvorfälle. Fehler beim `lstat` jenseits eines fehlenden Pfads machen die Prüfung unvollständig. Symbolische Links werden nicht verfolgt. Nur über NSS/LDAP vorhandene Konten erscheinen nicht im lokalen Dateibericht.

Lesbare Ausgabe: `ISSUE USER UID HOME` mit Tabulatoren und maskierten Steuerzeichen; `--null` liefert unveränderte NUL-getrennte Felder ohne Kopfzeile oder Zusammenfassung. Exitstatus 0 für abgeschlossene Prüfung (auch bei Befunden), 1 für fehlerhafte Datensätze oder Zugriffsfehler, 2 bei Parameterfehler, 3 bei fehlender Datei oder Modul. Keine CPAN-Abhängigkeiten.
