# nss-lookup — gezielte Konto- und Gruppenauflösung

[English](nss-lookup.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/nss-lookup.1)

`nss-lookup` fragt über die **Namensdienstschnittstelle des Betriebssystems** genau einen Benutzer oder eine Gruppe ab. Dazu dienen Perls `getpwnam`, `getpwuid`, `getgrnam` und `getgrgid`. Das Programm verändert keine Konten und benötigt keine Root-Rechte.

## Beispiele

```sh
./bin/nss-lookup --user root
./bin/nss-lookup --uid 501                  # häufige macOS-Benutzer-ID
./bin/nss-lookup --uid 1000                 # häufige Linux-Benutzer-ID
./bin/nss-lookup --group staff
./bin/nss-lookup --gid 0
./bin/nss-lookup --user root --null > root-account.bin
```

Genau eine Option `--user NAME`, `--uid N`, `--group NAME` oder `--gid N` ist erforderlich. Namen müssen 1–255 Bytes lang sein und dürfen keine Steuerzeichen enthalten. IDs sind dezimale Ganzzahlen von `0` bis `4294967295`. Namen werden nicht an eine Shell übergeben.

## Datenquellen und Grenzen

Die libc-/NSS-Konfiguration des Rechners entscheidet, ob ein Eintrag beispielsweise aus lokalen Dateien, LDAP, NIS, Cache-Diensten oder auf macOS aus Directory Services stammt. **Eine erfolgreiche Einzelabfrage beweist weder die Vollständigkeit einer Aufzählung noch die Herkunft des Eintrags.** Für lokale und enumerierte Daten gibt es zusätzlich `account-inventory`. Ergebnisse gelten stets für die aktuelle Konfiguration des ausführenden Systems.

## Ausgabe und Rückgabecodes

Lesbare Ausgabe: `TYPE NAME UID GID HOME SHELL MEMBERS`, durch Tabulatoren getrennt. Steuerzeichen und Backslashes werden als `\xHH` maskiert. Mit `--null` werden **genau sieben unveränderte, NUL-getrennte Felder** ohne Tabellenkopf ausgegeben. Bei Gruppen bleiben `UID`, `HOME` und `SHELL` leer. Das Feld `MEMBERS` ist keine vollständige Darstellung aller Benutzer-Gruppen-Zuordnungen.

- `0`: gefunden; `1`: nicht gefunden; `2`: falsche Argumente. Eine NSS-Störung kann von libc wie ein fehlender Eintrag gemeldet werden und ist dann nicht sicher unterscheidbar.

Benötigt nur Perl 5 mit Standardmodulen. Fehlende Namensdienst-Backends des Betriebssystems können hierdurch nicht ergänzt werden.
