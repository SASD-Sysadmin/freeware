# `hosts-lint` — Syntaxprüfung von Hosts-Dateien

**Deutsch** · [English](hosts-lint.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/hosts-lint.1) · [Quellcode](../../bin/hosts-lint)

## Zweck und Einsatzbereich

Rein lesende Prüfung einer Hosts-Datei im Format `IP NAME [ALIAS ...]` (Standard `/etc/hosts`). Das Werkzeug löst keine Namen auf, fragt kein DNS ab und verändert die Datei nicht.

## Verhalten und geprüfte Eigenschaften

Alles ab dem ersten `#` wird entfernt, Leerraum abgeschnitten und Leerzeilen werden übersprungen. IPv4 benötigt vier Dezimal-Oktette von 0–255 ohne führende Nullen, IPv6 wird mit Perls `Socket::inet_pton` geprüft. Hostnamen dürfen Buchstaben, Ziffern, Unterstriche, Bindestriche und Punkte enthalten (auch Schluss-Punkt). Ein fehlender Hostname ist ein Fehler. Derselbe Name (ohne Beachtung der Großschreibung) mit verschiedenen **Textdarstellungen** von IP-Adressen erzeugt eine **Warnung**; Mehrfachzuordnungen können beabsichtigt sein.

## Aufruf und Optionen

```text
hosts-lint --help
```

| Option | Bedeutung |
| --- | --- |
| `--file PATH` | Eingabedatei (Standard `/etc/hosts`). |
| `-h`, `--help` | Hilfe ohne Dateizugriff. |
| `--version` | `hosts-lint 0.1.0` anzeigen. |

## Praktisches Beispiel

```sh
sample="$(mktemp)"
printf '%s\n' '127.0.0.1 localhost' '::1 localhost ip6-localhost' \
  '192.0.2.10 app.example.test app' > "$sample"
./bin/hosts-lint --file "$sample"
rm -- "$sample"
```

Für `localhost` entsteht bewusst eine Warnung wegen zweier Adressen; Warnungen allein führen **nicht** zu einem Fehler-Exitcode. `./bin/hosts-lint` prüft die aktuelle Hosts-Datei.

## Ausgabe und Rückgabewerte

Die Zähler `Entries:`, `Unique names:`, `Warnings:`, `Errors:` erscheinen auf stdout; Pfad-/Zeilenmeldungen auf stderr.

`0` = keine Syntaxfehler, **Warnungen möglich**; `1` = ungültige IP oder Name bzw. fehlender Name; `2` = falsche Optionen; andere Werte ungleich 0 = Dateifehler.

## Grenzen, Sicherheit und Portabilität

Kein vollständiger herstellerspezifischer Hosts-Parser. Keine semantische IP-Vereinheitlichung, Resolver-Reihenfolge, DNS-/mDNS- oder Cache-Prüfung. IPv6-Zonenkennungen und Sondernamen können abgewiesen werden. Zugelassene Unterstriche beweisen keine allgemeine DNS-Gültigkeit. Unix-Testdateien funktionieren unter Linux und macOS; keine Freigabe sämtlicher Systemfunktionen.

## Weiterführende Informationen

[Perl-Sammelanleitung](perl-tools.de.md) · [`host-resolve`](host-resolve.de.md) · [Plattformen](../PLATFORMS.de.md)
