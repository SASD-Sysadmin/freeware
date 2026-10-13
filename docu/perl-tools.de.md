# Perl-Werkzeuge für die Systemadministration

[English](perl-tools.md) | [Deutsch](perl-tools.de.md) · [Projektbeschreibung](../README.de.md)

## Zusammenfassung

Vier Perl-5-Kommandozeilenprogramme liefern lesende Auswertungen zu Verzeichnisinhalten, Hosts-Dateien, Kontodatensätzen und Logmeldungen. Die Programme verwenden Perl-Standardmodule und ändern keine Eingabedaten.

## `fs-report` — Überblick über ein Dateisystemverzeichnis

```sh
./bin/fs-report --top 15 --min-size 1M /var/log
./bin/fs-report --top 0 "$HOME"
```

Durchsucht ein Verzeichnis, ohne symbolischen Links zu folgen. Zeigt die Anzahl der Verzeichnisse, regulären Dateien und Links, die **Summe der logischen Dateigrößen** sowie die N größten regulären Dateien ab einer Mindestgröße. Standardwert für `--top` ist 10 (zulässig 0–1000). `--min-size` akzeptiert Bytes oder `K`, `M`, `G`, `T` als Binärgrößen zur Basis 1024. `--one-file-system` verhindert das Überschreiten der Device-Grenze. Eine eigene, vollständige Anleitung steht in [fs-report.de.md](fs-report.de.md). Sortierung: Größe absteigend, anschließend Pfad.

Die gemeldete Größe entspricht **nicht** zwingend dem belegten Speicherplatz (`du`): Sparse-Dateien und Hardlinks können die Aussage verfälschen. Fehlende Leserechte schränken die Vollständigkeit ein. Steuerzeichen in ausgegebenen Dateipfaden werden maskiert.

## `hosts-lint` — Hosts-Datei überprüfen

```sh
./bin/hosts-lint
./bin/hosts-lint --file ./meine-hosts
```

Prüft Zeilen in der Form `IP HOSTNAME [ALIAS ...]`, einschließlich IPv4 und IPv6. Leerzeilen sowie Kommentare nach `#` werden ignoriert. Fehlerhafte IP-Adressen und Hostnamen sowie fehlende Hostnamen werden gemeldet. Ein mehrfacher Hostname mit unterschiedlichen IP-Adressen erzeugt eine **Warnung**, denn solche Zuordnungen können beabsichtigt sein. Standarddatei: `/etc/hosts`.

Das Werkzeug prüft vor allem Syntax, nicht die tatsächliche DNS-Auflösung. Herstellerspezifische Erweiterungen und ungewöhnliche Hostnamen können abweichen. Die Eingabedatei bleibt unverändert.

## `account-audit` — Unix-Kontodatei untersuchen

```sh
./bin/account-audit
./bin/account-audit --file ./passwd.beispiel
```

Liest Dateien im siebenteiligen `/etc/passwd`-Format und prüft Kontonamen, UID, GID und absolute Home-Verzeichnisse. Meldet doppelte Kontonamen, gemeinsam genutzte UIDs, zusätzliche UID-0-Konten und leere Login-Shells. `+`/`-`-NIS-Einträge werden mit Warnung übersprungen. Standarddatei: `/etc/passwd`.

**Kein vollständiger Sicherheitscheck:** Das Werkzeug liest keine `/etc/shadow`, prüft keine Passwörter und berücksichtigt weder PAM noch alle LDAP-/NSS-Konten. Auffälligkeiten können legitim sein und müssen fachlich geprüft werden. Die Ausgabe kann Kontonamen enthalten und sollte entsprechend geschützt werden.

## `log-summary` — Logmeldungen zählen

```sh
./bin/log-summary /var/log/syslog
./bin/log-summary --match sshd /var/log/auth.log
journalctl --no-pager -n 1000 | ./bin/log-summary -
```

Verarbeitet eine Text-Logdatei oder Standardeingabe (`-`) zeilenweise. Erkennt Schweregrad-Schlüsselwörter und zählt Meldungen als `CRITICAL`, `ERROR`, `WARNING`, `NOTICE`, `INFO`, `DEBUG`, `TRACE` oder `OTHER`. Treten mehrere Schlüsselwörter auf, zählt die schwerwiegendere Klasse. `--match TEXT` filtert vor der Auswertung nach einem **wörtlichen**, nicht nach einem regulären Ausdruck (ohne Unterscheidung der Groß-/Kleinschreibung). Der Originaltext wird nicht ausgegeben.

Die Klassifizierung basiert auf Schlüsselwörtern, nicht auf einer vollständigen Parserlogik für syslog, journald oder JSON. Auch Begriffe innerhalb einer gewöhnlichen Nachricht können die Zuordnung beeinflussen. Das Programm endet am Dateiende und verfolgt die Datei nicht dauerhaft.

## Installation und Tests

```sh
make test
sudo make install PREFIX=/usr/freeware
/usr/freeware/bin/hosts-lint
man -M /usr/freeware/man hosts-lint
```

Die Tests arbeiten mit temporären Beispieldateien und verändern keine realen Systemdateien. Für ein Installationspaket kann `DESTDIR` verwendet werden:

```sh
make install PREFIX=/usr/freeware DESTDIR=/tmp/sasd-stage
```

Ergänze bei Bedarf `/usr/freeware/bin` in `PATH` und `/usr/freeware/man` in `MANPATH`.

## Rückgabewerte, Grenzen und Sicherheit

Für `hosts-lint` und `account-audit` gilt: **0** ohne Syntaxfehler, **1** bei inhaltlichen Fehlern und **2** bei falschen Optionen. Warnungen allein ergeben Rückgabewert 0. Nicht lesbare Eingaben führen ebenfalls zu einem Fehler. `fs-report` signalisiert Dateizugriffsfehler und verwendet 2 bei falschen Parametern. `log-summary` liefert nach erfolgreicher Verarbeitung 0.

Alle vier Programme arbeiten **lesend**. Sie nehmen selbst keine Rechteerhöhung vor und ersetzen keine Sicherheitsprüfung oder konsistente Datensicherung. Linux-Tests sind vorgesehen; die Portabilität auf macOS muss durch den CI-Lauf nach dem Hochladen bestätigt werden.
