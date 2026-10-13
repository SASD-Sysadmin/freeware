# nsswitch-audit — Strukturprüfung einer NSS-Switch-Datei

[English](nsswitch-audit.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/nsswitch-audit.1)

Prüft ausschließlich die **Textsyntax** einer Linux-artigen `nsswitch.conf`. Unter Linux wird standardmäßig `/etc/nsswitch.conf` gelesen. Unter macOS ist **`--file` verpflichtend**, denn diese Datei ist nicht die maßgebliche Konfiguration für Directory Services. NSS-Module werden nicht geladen und keine Benutzer oder Gruppen abgefragt.

Erkennt doppelte Datenbankdefinitionen und Quellen, fehlerhafte Quellenlisten und Klammeraktionen, leere Regeln und Steuerzeichen. `NOTE` kennzeichnet historische Quellen wie `nis`, `nisplus` oder `compat` und fehlende häufige Datenbanken. Hinweise führen nicht automatisch zu einem Fehlerstatus. **Das Programm überprüft weder installierte NSS-Module noch deren Wirkung oder Sicherheit.**

## Beispiele

```sh
./bin/nsswitch-audit
./bin/nsswitch-audit --file /tmp/nsswitch.conf
```

## Grenzen und Rückgabewerte

Nur Syntax; Fehler in Regeln führen zu Exit 1, fehlende Datei oder nicht unterstützte Voreinstellung zu Exit 3.

Exit `0`: keine Befunde/Erfolg; `1`: Strukturfehler, DNS-/NIS-Fehler oder fehlende Antwort; `2`: ungültige Parameter; `3`: Datei oder Client fehlt, nicht unterstützte Voreinstellung oder unerwarteter Fehler. Fehlende Clients dürfen **nicht** als fehlerfreie Konfiguration ausgelegt werden.
