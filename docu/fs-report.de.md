# fs-report

`fs-report` liest einen Verzeichnisbaum und meldet die Zahl der Verzeichnisse, regulären Dateien, symbolischen Links und sonstigen Einträge, die Summe der logischen Dateigrößen sowie die größten regulären Dateien. Es nimmt keine Änderungen vor.

## Voraussetzungen

Perl ab 5.8 mit den Standardmodulen `Getopt::Long`, `FindBin`, `Fcntl` und `File::Spec`. Das mitgelieferte Modul `SASD::Freeware::Walk` aus `lib/` muss zusammen mit dem Befehl installiert sein. Externe Systembefehle oder Root-Rechte sind nicht erforderlich. Zum Durchsuchen müssen Lese- und Verzeichnisrechte vorhanden sein.

## Aufruf

```sh
fs-report /home
fs-report --top 25 --min-size 10M /srv
fs-report --one-file-system --top 0 /
```

| Option | Bedeutung |
| --- | --- |
| `--top N` | Höchstens N größte Dateien anzeigen, `0..1000` (Vorgabe 10). |
| `--min-size SIZE` | Mindestgröße für die Liste der größten Dateien; die Gesamtsummen bleiben unverändert. |
| `--one-file-system` | Einträge auf einem anderen Device als dem Startverzeichnis nicht berücksichtigen. |
| `--help`, `--version` | Hilfe oder Version anzeigen. |

`SIZE` ist eine Bytezahl mit optionalem **binärem** Suffix `K`, `M`, `G` oder `T` (`1M` = 1.048.576 Byte). Nicht exakt darstellbare übergroße Werte werden abgelehnt. Steuerzeichen in Dateinamen werden in der Textausgabe maskiert. Symbolische Links werden gezählt, aber nicht verfolgt. Das Startverzeichnis darf selbst kein Link sein.

**Größenberechnung:** Die logischen Bytezahlen beruhen auf `st_size` je Pfad. Mehrere Hardlinks derselben Datei werden mehrfach gezählt. Dateisystembelegung und Sparse-Dateien sind damit nicht direkt vergleichbar. Dafür steht `fs-usage` bereit.

Lesefehler werden auf der Standardfehlerausgabe gemeldet. Die Zusammenfassung nennt ihre Anzahl. Bei Fehlern ist die Ausgabe möglicherweise unvollständig.

## Rückgabewerte

- `0`: Durchsuchung vollständig.
- `1`: Fehler beim Durchsuchen; möglicherweise unvollständige Ergebnisse.
- `2`: Ungültige Optionen oder Argumente.
- `3`: Startverzeichnis nicht zugänglich.

## Installation

`make test`, anschließend `make install PREFIX=/usr/freeware`. Dabei wird auch das benötigte Perl-Modul kopiert. Aus dem vollständigen Checkout ist `./bin/fs-report` direkt ausführbar.
