# largefiles

`largefiles` durchsucht einen Verzeichnisbaum nach großen regulären Dateien. Es löscht oder verändert keine Dateien und folgt keinen symbolischen Links. Ohne `--all` bleibt die Ergebnisliste auf die angeforderte Anzahl begrenzt.

## Voraussetzungen

Perl ab 5.8, die Perl-Standardmodule `Getopt::Long`, `FindBin`, `Fcntl` und `File::Spec` sowie das mitgelieferte Modul `SASD::Freeware::Walk`. Für die Durchsuchung sind ausreichende Dateisystemrechte notwendig.

## Aufruf

```sh
largefiles --min-size 500M /var
largefiles --min-size 1G --top 20 /home
largefiles --min-size 10M --one-file-system --all /srv
largefiles --min-size 100M --null /data > /tmp/largefiles.records
```

| Option | Bedeutung |
| --- | --- |
| `--min-size SIZE` | Einschließende Mindestgröße, Vorgabe `100M`. |
| `--top N` | Höchstens N größte Treffer ausgeben, Vorgabe 50; zulässig `1..10000`. |
| `--all` | Alle Treffer fortlaufend in Suchreihenfolge ausgeben, nicht nach Größe sortiert. |
| `--one-file-system` | Einträge auf anderen Devices auslassen. |
| `--null` | Nullbyte-getrennte Paare `Größe\0Pfad\0`, ohne Überschriften oder Summen. |
| `--help`, `--version` | Hilfe oder Version anzeigen. |

Größensuffixe `K/M/G/T` werden binär interpretiert. In der Textausgabe werden Steuerzeichen maskiert. `--null` erhält rohe Pfadnamen einschließlich Zeilenumbrüchen. Ohne `--all` ist die Ergebnisliste nach Größe absteigend sortiert. Trefferanzahl und logische Bytes beziehen sich immer auf **alle** Treffer, nicht nur die angezeigte Auswahl. Mehrere Hardlinks zählen je Pfad.

Ohne `--one-file-system` können auch Netzlaufwerke durchsucht werden. Device-IDs erkennen nicht jede Bind-Mount-Situation eindeutig. Lesefehler führen zu einer möglicherweise unvollständigen Ausgabe und Rückgabewert 1.

## Rückgabewerte

- `0`: vollständig, auch ohne Treffer.
- `1`: mindestens ein Fehler beim Durchsuchen.
- `2`: ungültige Parameter.
- `3`: Startverzeichnis nicht zugänglich.

## Installation

`make test && make install PREFIX=/usr/freeware`; alternativ aus dem vollständigen Checkout `./bin/largefiles`.
