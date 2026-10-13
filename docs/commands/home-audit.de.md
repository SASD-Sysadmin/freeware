# home-audit

[English](home-audit.md) · [Projekt](../../README.de.md)

`home-audit` überprüft Metadaten von Home-Verzeichnissen anhand **lokaler passwd-Dateien** oder der systemeigenen **NSS-/Directory-Services-Aufzählung**. Das Programm betritt keine Benutzerverzeichnisse, verfolgt keine Home-Symlinks und verändert keine Dateien.

```sh
./bin/home-audit
./bin/home-audit --source nss
./bin/home-audit --source local --file ./passwd.sample --all
./bin/home-audit --min-uid 2000 --max-uid 49999
./bin/home-audit --all --null > homes.bin
```

## Quellen und UID-Grenzen

- **Linux/andere Unix-Systeme:** standardmäßig `local` (`/etc/passwd`), UID-Bereich **1000..59999**.
- **macOS:** standardmäßig `nss` (`getpwent` über die systemeigene Benutzerauflösung), UID-Bereich **500..59999**. Die Textdatei `/etc/passwd` ist unter macOS **keine vollständige Kontenliste**.
- **`--source local`:** lokale passwd-Datei. Die explizite Option `--file PATH` wählt ebenfalls lokal, sofern die Quelle nicht ausdrücklich anders gesetzt wurde.
- **`--source nss`:** Aufzählung über den Namensdienst, nicht zusammen mit `--file` möglich. **NSS garantiert keine vollständige Erfassung**, insbesondere bei externen Verzeichnisdiensten. Ungültige UID- oder Home-Felder führen zu einer Fehlermeldung.

UID-Grenzen sind eine wählbare Verwaltungsrichtlinie und keine sichere Einteilung in Personen- und Systemkonten. `--all` berücksichtigt alle aufgezählten Konten einschließlich Dienstkonten mit teils ungewöhnlichen Home-Pfaden.

## Befunde und Status

Mögliche Befunde: `missing`, `symlink`, `not-directory`, `wrong-owner` und `world-writable`. Ein Befund verlangt fachliche Einordnung und löst keine Korrektur aus. Fehler beim `lstat` außerhalb nicht vorhandener Pfade machen die Prüfung unvollständig. **APFS-ACLs und macOS-TCC-/Datenschutzregeln werden nicht geprüft**; Unix-Modusbits bilden keine vollständige Rechtebewertung ab.

Lesbare Ausgabe: `ISSUE USER UID HOME` mit Tabulatoren und maskierten Steuerzeichen. `--null` liefert vier NUL-getrennte Felder je Befund ohne Kopfzeile und Summe. Exitstatus 0: Prüfung abgeschlossen (auch bei Befunden); 1: Daten- oder Zugriffsfehler; 2: Parameterfehler; 3: fehlende Voraussetzungen. Benötigt Perl-Kernmodule und `SASD::Freeware::Account`, keine CPAN-Pakete.
