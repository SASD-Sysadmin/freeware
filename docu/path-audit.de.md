# path-audit — Prüfung von Dateinamen und Pfadlängen

[English](path-audit.md) · [Manpage](../man/man1/path-audit.1)

## Zusammenfassung

`path-audit` erfasst Verzeichniseinträge, deren Dateinamenkomponente oder gesamter Pfad selbst festgelegte Bytegrenzen überschreitet. Das ist beispielsweise bei Dateisystemwechseln, Archiven, Backup-Programmen und Anwendungsmigrationen hilfreich.

## Voraussetzungen

Perl 5 und die Standardmodule `Getopt::Long`, `File::Spec`, `File::Basename` und `Fcntl`. Leserechte für den zu untersuchenden Verzeichnisbaum. Unter Linux getestet; weitere Unix-Systeme sind separat zu prüfen.

## Aufruf

```sh
path-audit /srv/data
path-audit --component-limit 200 --path-limit 900 /home
path-audit --one-file-system /export
path-audit --null /srv/data > /tmp/path-inventory.dat
```

## Parameter und Ausgabe

| Option | Bedeutung |
| --- | --- |
| `--component-limit N` | Erlaubte Länge einer Pfadkomponente in Byte; Standard `240` |
| `--path-limit N` | Erlaubte Länge des vollständigen Pfads in Byte; Standard `1024` |
| `--one-file-system` | Andere Dateisysteme überspringen |
| `--null` | NUL-getrennte Felder `REASON`, `COMPONENT_BYTES`, `PATH_BYTES`, `PATH` |
| `--help`, `-h`; `--version` | Hilfe; Version |

Die Textausgabe verwendet Tabulatoren als Trennzeichen, enthält eine Kopfzeile und eine Fundstatistik. `REASON` ist `component`, `path` oder `both`. Sonderzeichen in angezeigten Dateinamen werden maskiert. Mit `--null` werden **alle vier Felder** durch NUL-Bytes getrennt; Kopfzeile und Summen entfallen. Die Längenangaben beziehen sich auf die Bytefolge des Pfads, nicht auf die Anzahl Unicode-Zeichen.

Die Grenzwerte sind frei wählbare Prüfregeln und **keine** Aussage über tatsächliche `NAME_MAX`- oder `PATH_MAX`-Grenzen des Betriebssystems. Der vollständige Pfad enthält die Schreibweise des übergebenen Verzeichnisses. Relative und absolute Pfade können deshalb unterschiedliche Werte ergeben. Symlinks können hinsichtlich ihres eigenen Namens gemeldet werden, werden aber nicht durchlaufen. Dateien werden weder umbenannt noch gelöscht.

## Rückgabewerte

`0`: vollständig untersucht; `1`: Verzeichnis unzugänglich oder Lese-/Stat-Fehler; `2`: Parameterfehler. Fehlermeldungen erscheinen auf stderr. Bei sich während der Untersuchung ändernden Verzeichnissen kann das Ergebnis unvollständig sein.

## Installation

Im Repository `make install PREFIX=/usr/freeware` oder direkter Aufruf über `perl bin/path-audit VERZEICHNIS`. Handbuch unter `man -M /usr/freeware/man path-audit`.
