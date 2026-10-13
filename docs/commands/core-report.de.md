# core-report — Übersicht möglicher Core-Dump-Dateien

[English](core-report.md) · [Manpage](../../man/man1/core-report.1)

## Zusammenfassung

`core-report` sucht unterhalb eines Verzeichnisses nach regulären Dateien namens `core` oder mit dem Präfix `core.`. Es meldet mögliche Core-Dump-Dateien, ihre logische Größe in Byte und Summen. Das Programm prüft nicht den Dateityp anhand seines Inhalts und verändert oder löscht keine Dateien.

## Voraussetzungen

Perl 5 mit `Getopt::Long`, `File::Spec` und `Fcntl` (Perl-Standardmodule). Die untersuchten Verzeichnisse müssen lesbar sein. Unter Linux getestet; die Kompatibilität mit anderen Unix-Systemen ist gesondert zu prüfen. Root-Rechte werden nur benötigt, wenn die Verzeichnisberechtigungen dies erforderlich machen.

## Aufruf

```sh
core-report /var/tmp
core-report --min-size 1048576 /home
core-report --one-file-system /srv
core-report --null /var/tmp > /tmp/core-inventory.dat
```

## Parameter

| Option | Bedeutung |
| --- | --- |
| `--min-size BYTES` | Nur Dateien ab dieser logischen Größe berücksichtigen, Standard `0` |
| `--one-file-system` | Einträge außerhalb des Dateisystems des Startverzeichnisses überspringen |
| `--null` | Felder `BYTES\0PATH\0` ohne Kopfzeile und Summen ausgeben |
| `--help`, `-h` | Hilfe anzeigen |
| `--version` | Programmversion anzeigen |

Die normale Ausgabe beginnt mit `BYTES<TAB>PATH` und listet danach Fundstellen auf. Backslashes, Tabulatoren und Zeilenumbrüche in Pfaden werden für die Anzeige maskiert. Abschließend erscheinen Anzahl der Kandidaten, logische Gesamtgröße und Fehlerzahl. Bei `--null` sind die Felder durch NUL-Bytes getrennt, damit Dateinamen mit Sonderzeichen unverändert weiterverarbeitet werden können.

## Suchumfang und Grenzen

- `core` und `core.*` sind Namensmuster, keine verbindliche Erkennung echter Absturzabbilder. Andere Dateien können ebenfalls passen, tatsächliche Core-Dumps anders heißen.
- Symbolischen Links wird nicht gefolgt. Mit `--one-file-system` lässt sich der Durchlauf auf ein Dateisystem begrenzen.
- Das Programm räumt nichts auf. Es berechnet Größen anhand der logischen Dateilänge (`lstat`), nicht anhand belegter Dateisystemblöcke.
- Gleichzeitige Änderungen im Dateibaum können zu unvollständigen Ergebnissen führen; es wird kein Dateisystem-Snapshot erstellt.

## Rückgabewerte und Fehlersuche

`0`: erfolgreich untersucht; `1`: Startverzeichnis unzugänglich oder Lese-/Stat-Fehler; `2`: ungültige Parameter. Fehlermeldungen erscheinen auf stderr. Für die unverfälschte Weiterverarbeitung von ungewöhnlichen Pfaden `--null` verwenden.

## Installation

Im geprüften Repository `make install PREFIX=/usr/freeware` verwenden oder das Script direkt über `perl bin/core-report VERZEICHNIS` aufrufen. Die Manpage wird standardmäßig unter `/usr/freeware/man/man1/core-report.1` installiert.
