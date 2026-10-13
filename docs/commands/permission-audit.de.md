# permission-audit

`permission-audit` inventarisiert Einträge, deren Unix-Modus das **Schreibrecht für Andere** enthält. Das Programm **ändert keine Berechtigungen**. Ein solches Schreibrecht ist ein Prüfhinweis, nicht automatisch eine Sicherheitslücke.

## Voraussetzungen

Perl ab 5.8, die Kernmodule `Getopt::Long`, `FindBin`, `Fcntl` und die mitgelieferte Bibliothek `SASD::Freeware::Walk`. Keine externen Programme erforderlich. Die Verzeichnisse müssen lesbar sein.

## Beispiele

```sh
permission-audit /srv
permission-audit --one-file-system /home
permission-audit --include-sticky /tmp
permission-audit --null /srv > writable.bin
```

## Ausgabe und Interpretation

Die Spalten `TYPE`, `MODE`, `PATH` enthalten Eintragstyp, oktale Berechtigungen und den maskierten Pfad. Berechtigungsbits symbolischer Links werden bewusst **nicht bewertet**. Link-Verzeichnisse werden nicht betreten.

Verzeichnisse mit Schreibrecht für Andere **und** gesetztem Sticky-Bit, beispielsweise `/tmp` (`1777`), sind standardmäßig ausgenommen. Mit `--include-sticky` erscheinen sie gesondert als `sticky-directory`. Weitere Typen heißen `file`, `directory` und `special`. Das Startverzeichnis selbst wird ebenfalls geprüft. ACLs (POSIX oder NFSv4) und sonstige Zugriffsrichtlinien werden nicht ausgewertet; der tatsächliche Schreibzugriff kann vom reinen Modus abweichen.

Mit `--null` erscheinen nullbytegetrennte Datensätze (`TYPE`, `MODE`, `PATH`) ohne Kopf- und Fußzeile. `--one-file-system` begrenzt den Scan auf ein Dateisystem. Das Programm führt weder `chmod` noch `chown` noch `rm` aus.

## Rückgabewerte

- `0` — vollständig durchlaufen, auch wenn Schreibrechte gefunden wurden.
- `1` — Fehler beim Lesen oder Durchsuchen; Ergebnis möglicherweise unvollständig.
- `2` — ungültige Optionen.
- `3` — mitgelieferte Perl-Bibliothek fehlt.

## Installation

`make test && make install PREFIX=/usr/freeware`. Weitere Angaben: `man -M /usr/freeware/man permission-audit`.
