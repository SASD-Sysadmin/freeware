# fs-usage

`fs-usage` fragt die Belegung eingehängter Dateisysteme über `df -P -k` ab. Es meldet Gesamtkapazität, belegte und verfügbare 1024-Byte-Blöcke. Das Programm arbeitet ausschließlich lesend und nimmt mehrere existierende Pfade entgegen.

## Voraussetzungen

Perl ab 5.8 mit `Getopt::Long`, `File::Spec` und `FindBin`; die mitgelieferten Module `SASD::Freeware::External` und `SASD::Freeware::Walk`; außerdem ein über `PATH` erreichbares `df` mit den POSIX-Optionen `-P` und `-k`. Ein fehlendes, fehlerhaftes oder inkompatibles `df` führt zu einer aussagekräftigen Fehlermeldung. GNU-spezifische Schalter und eine Shell zur Befehlsausführung werden nicht benötigt.

## Aufruf

```sh
fs-usage / /home /var
fs-usage --warn 80 --critical 95 /srv
```

Tabulator-getrennte Spalten: `STATUS`, `USE%`, `USED_KiB`, `AVAIL_KiB`, `SIZE_KiB`, `FILESYSTEM`, `MOUNT` und `QUERY`. Steuerzeichen in Textfeldern werden maskiert. Die Prozentzahl stammt direkt von `df`.

`--warn PERCENT` erzeugt ab der Grenze WARNING, `--critical PERCENT` entsprechend CRITICAL. Zulässig sind ganze Prozentzahlen von 0 bis 100. Bei beiden Optionen muss der kritische Schwellwert mindestens so hoch wie der Warnwert sein. Ohne Grenzwerte heißt der Status erfolgreicher Abfragen OK.

`fs-usage` ermittelt die Belegung des gesamten Dateisystems, während `fs-report` die logischen Dateilängen eines Verzeichnisbaums summiert. Benutzer-Quotas können die verfügbare Kapazität zusätzlich begrenzen.

## Rückgabewerte

- `0`: alle Abfragen erfolgreich, keine Grenzwertüberschreitung.
- `1`: Warn- oder kritischer Grenzwert erreicht.
- `2`: ungültige Argumente.
- `3`: `df` fehlt oder meldet Fehler, das Ausgabeformat passt nicht oder ein Pfad ist ungültig. Bei mehreren Pfaden können Teilinformationen ausgegeben werden; ein Ausführungsfehler hat Vorrang vor einem Grenzwerttreffer.

## Installation

`make test && make install PREFIX=/usr/freeware`; im Checkout auch `./bin/fs-usage /`.
