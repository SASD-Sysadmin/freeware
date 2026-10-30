# `account-audit` — Strukturprüfung einer Unix-Kontodatei

**Deutsch** · [English](account-audit.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/account-audit.1) · [Quellcode](../../bin/account-audit)

## Zweck und Einsatzbereich

Lesende Prüfung eines siebenteiligen `passwd(5)`-Textformats, standardmäßig `/etc/passwd`. **Keine** Prüfung von Passwörtern, Anmeldung, NSS, LDAP, PAM oder `/etc/shadow`. Die Datei bleibt unverändert.

## Verhalten und geprüfte Eigenschaften

Leerzeilen und Kommentarzeilen (auch mit führenden Leerzeichen) werden ignoriert. Alte `+`/`-`-NIS-Einträge werden mit Warnung übersprungen. Alle anderen Zeilen benötigen sieben mit `:` getrennte Felder (`name:password:uid:gid:gecos:home:shell`). Kontonamen folgen einem eingeschränkten ASCII-Muster; UID/GID müssen Dezimalziffern sein; das Home-Feld beginnt mit `/`. Doppelte Namen, verschiedene Namen mit gleicher UID, weitere UID-0-Konten und leere Shells erzeugen **Warnungen**. Passwort-, GECOS- und Shell-Inhalte werden ansonsten nicht validiert; ein Home-Pfad wird nicht auf Existenz geprüft.

## Aufruf und Optionen

```text
account-audit --help
```

| Option | Bedeutung |
| --- | --- |
| `--file PATH` | Textdatei (Standard `/etc/passwd`). |
| `-h`, `--help` | Hilfe ohne Zugriff auf die Eingabedatei. |
| `--version` | `account-audit 0.1.0` anzeigen. |

## Praktisches Beispiel

```sh
sample="$(mktemp)"
printf '%s\n' 'root:x:0:0:root:/root:/bin/sh' \
  'operator:x:1000:1000:Operator:/home/operator:/bin/sh' \
  'second:x:1000:1001:Second:/home/second:' > "$sample"
./bin/account-audit --file "$sample"
rm -- "$sample"
```

Die gemeinsame UID und die leere Shell erzeugen Warnungen, **aber Exitcode 0**, solange die Struktur gültig ist. Keine Systemkonten werden verändert.

## Ausgabe und Rückgabewerte

Auf stdout erscheinen `Accounts:`, `Distinct UIDs:`, `Warnings:`, `Errors:`. Zeilenbezogene Diagnosen mit Pfad und Zeilennummer stehen auf stderr.

`0` = keine strukturellen Fehler, **Warnungen möglich**; `1` = fehlerhafte Datensätze; `2` = Aufruffehler; andere Werte ungleich 0 = Dateizugriffs-/Schließfehler. Für Warnungen müssen Skripte `Warnings:` oder stderr prüfen.

## Grenzen, Sicherheit und Portabilität

Momentaufnahme einer Unix-Textdatei, keine vollständige Benutzerinventur und keine Aussage zur Anmeldung. Die Ausgabe kann vertrauliche Kontonamen enthalten. Auf macOS ist `/etc/passwd` keine authoritative Directory-Services-Datenbank; dort nur geeignete Unix-Testdateien verwenden. Es werden keine Root-Rechte angefordert.

## Weiterführende Informationen

[Perl-Sammelanleitung](perl-tools.de.md) · [`account-inventory`](account-inventory.de.md) · [Plattformgrenzen](../PLATFORMS.de.md)
