# link-audit

`link-audit` durchsucht Verzeichnisbäume nach symbolischen Links, deren Ziele nicht aufgelöst werden können. Es **ändert oder löscht keine Links**. Fehlende Ziele, Auflösungsschleifen und sonstige Fehler werden getrennt ausgewiesen.

## Voraussetzungen

Perl ab 5.8, die Kernmodule `Getopt::Long`, `FindBin`, `Fcntl` und `Errno` sowie das mitgelieferte Modul `SASD::Freeware::Walk`. Externe Programme sind nicht erforderlich. Zum Lesen der Verzeichnisse und Auflösen der Linkziele müssen ausreichende Rechte vorhanden sein.

## Beispiele

```sh
link-audit /srv/data
link-audit --one-file-system /home
link-audit --all /srv/projects
link-audit --null /srv/data > links.bin
```

## Ausgabe und Verhalten

Die Tabelle enthält `STATUS`, `PATH`, `TARGET` und eine Zusammenfassung. `dangling` bezeichnet ein nicht existentes oder nicht durchlaufbares Ziel (`ENOENT`/`ENOTDIR`); `loop` eine Verweisschleife (`ELOOP`); `unresolved` einen anderen, nicht eindeutig bewertbaren Fehler wie fehlende Rechte. Mit `--all` erscheinen zusätzlich gültige Links (`valid`).

Symbolische Links auf Verzeichnisse werden **nicht rekursiv betreten**. Zur Prüfung eines Linkziels kann dessen Pfad dennoch außerhalb des Scanverzeichnisses liegen. `--one-file-system` begrenzt das Durchsuchen auf ein Dateisystem. Als Startpunkt ist ein echtes Verzeichnis erforderlich. Während der Durchsuchung veränderte Links können das Ergebnis beeinflussen.

Mit `--null` werden Gruppen aus `STATUS`, `PATH` und `TARGET` nullbytegetrennt ausgegeben, ohne Kopfzeile oder Zusammenfassung. Die Standardausgabe maskiert Backslashes und Steuerzeichen.

## Rückgabewerte

- `0` — vollständige Durchsuchung, auch wenn defekte Links gefunden wurden.
- `1` — unvollständiger Scan oder nicht ermittelbarer Linkstatus; Meldung auf stderr.
- `2` — ungültige Parameter.
- `3` — mitgelieferte Perl-Bibliothek fehlt.

## Installation

`make test && make install PREFIX=/usr/freeware`. Weitere Angaben: `man -M /usr/freeware/man link-audit`.
