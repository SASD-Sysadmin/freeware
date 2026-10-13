# owner-audit

`owner-audit` meldet Eigentümer- und Gruppenkennungen von Dateien, die der aktuelle Namensdienst nicht auflösen kann. Es **verändert keine Eigentümer**. Die Inventarisierung hilft besonders nach Kontenumstellungen oder Änderungen am Namensdienst.

## Voraussetzungen

Perl ab 5.8 mit `Getopt::Long`, `FindBin` und der mitgelieferten Bibliothek `SASD::Freeware::Walk`. Die Abfragen erfolgen mit `getpwuid` und `getgrgid` über die konfigurierte Namensauflösung des Betriebssystems. Eine direkte Auswertung von `/etc/passwd` ist nicht erforderlich. Je nach Konfiguration können NIS oder LDAP beteiligt sein.

## Beispiele

```sh
owner-audit /home
owner-audit --scope user /srv/archive
owner-audit --scope group --one-file-system /srv
owner-audit --null /srv/archive > owners.bin
```

## Ausgabe und Grenzen

Die Tabelle enthält `ISSUE` (`user`, `group`, `user+group`), `UID`, `GID` und `PATH`. Ohne `--scope` werden beide Kennungen geprüft. Die Ergebnisse der Namensauflösung werden je UID beziehungsweise GID zwischengespeichert. Symbolische Links werden nicht verfolgt; ihre eigenen Eigentümerkennungen werden per `lstat` betrachtet. Der Startpfad muss ein echtes Verzeichnis sein.

**Eine nicht auflösbare Kennung beweist nicht, dass der Eigentümer gelöscht wurde.** Auch ein Ausfall von NIS, LDAP oder einer anderen Namensdienstkomponente kann die Ursache sein. Solche Meldungen bitte vor administrativen Maßnahmen prüfen. Das Programm führt weder `chown` noch `chgrp` aus.

`--null` gibt Datensätze aus vier nullbytegetrennten Feldern (`ISSUE`, `UID`, `GID`, `PATH`) aus. In der Tabellenansicht werden Steuerzeichen maskiert.

## Rückgabewerte

- `0` — Scan vollständig, auch bei nicht auflösbaren Kennungen.
- `1` — Zugriffsfehler; Ergebnis gegebenenfalls unvollständig.
- `2` — ungültige Parameter.
- `3` — mitgelieferte Perl-Bibliothek fehlt.

## Installation

`make test && make install PREFIX=/usr/freeware`. Weitere Angaben: `man -M /usr/freeware/man owner-audit`.
