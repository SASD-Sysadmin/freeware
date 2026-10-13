# Automatisierungswerkzeuge in Perl (Deutsch)

[English](automation-tools.md) | **Deutsch** · [Projekt-README](../../README.de.md) · [Bisherige Perl-Werkzeuge](perl-tools.de.md)

## Zusammenfassung

Vier Perl-5-Programme ermöglichen die Prüfung von SSH-Schlüsseldateien, SHA-256-Dateiintegrität, die Inventarisierung von SUID-/SGID-Dateien und die Kontrolle der IPv4-TCP-Erreichbarkeit. Parameter, Berechtigungen und Rückgabewerte sind jeweils beschrieben.

## `ssh-key-audit` – Prüfung von authorized_keys

```sh
./bin/ssh-key-audit --file "$HOME/.ssh/authorized_keys"
```

Prüft eine angegebene `authorized_keys`-Datei, standardmäßig `$HOME/.ssh/authorized_keys`. Meldet offensichtlich fehlerhafte oder nicht unterstützte Schlüsselzeilen, mehrfach vorhandene Schlüssel, veraltete DSA-Schlüssel (`ssh-dss`) sowie gruppen- oder weltweit beschreibbare Datei bzw. Verzeichnisse. Kommentare und Leerzeilen werden ignoriert. Am Ende erscheint `SUMMARY: keys=N warnings=N`.

**Grenzen:** Vereinfachte Textprüfung, **kein vollständiger Parser für OpenSSH** und keine kryptografische Schlüsselprüfung. Komplexe Schlüsseloptionen, Zertifikate, Widerrufe, Besitzrechte der Elternverzeichnisse und die effektive Serverkonfiguration werden nicht vollständig geprüft. Ein `ssh-rsa`-Schlüssel allein belegt nicht, dass veraltete SHA-1-Signaturen erlaubt sind. Exitcode `0` ohne Auffälligkeiten, `1` bei Warnungen; Fehler führen zu einem anderen Wert ungleich null.

## `file-integrity` – SHA-256-Prüfsummen

```sh
mkdir -p "$HOME/integrity-baselines"
./bin/file-integrity --root /etc/ssh --manifest "$HOME/integrity-baselines/ssh.json" --init
./bin/file-integrity --root /etc/ssh --manifest "$HOME/integrity-baselines/ssh.json" --check
```

`--init` erzeugt eine **neue**, vor Überschreiben geschützte JSON-Basisliste mit SHA-256-Prüfsummen aller regulären Dateien unterhalb des Wurzelverzeichnisses. Die Basisliste muss **außerhalb** des überwachten Verzeichnisses liegen. `--check` (auch Standard ohne Modusangabe) meldet `ADDED`, `CHANGED` und `MISSING` sowie Summen. Exitcode `0`: keine Änderung; `1`: Abweichungen; Fehler ebenfalls ungleich null. Der gespeicherte absolute Wurzelpfad muss beim Prüfen übereinstimmen. Symbolische Links werden nicht verfolgt; Spezialdateien bleiben unberücksichtigt. Verglichen werden Dateiinhalte, **nicht** Rechte, Eigentümer, ACLs, erweiterte Attribute oder SELinux-Kontexte.

**Sicherheit:** Eine nach einer Kompromittierung erstellte Basisliste bietet keinen verlässlichen Ausgangspunkt. Manifestdateien vor unbefugtem Zugriff schützen, nach Möglichkeit extern aufbewahren. Bei laufenden Änderungen kann der Scan inkonsistente Zwischenstände enthalten. Kein Ersatz für Signaturprüfung, vertrauenswürdiges Backup oder professionelle FIM-Lösungen. `--init` bewusst nur bei der Einrichtung verwenden.

## `suid-audit` – Inventar der SUID-/SGID-Dateien

```sh
./bin/suid-audit --root /usr/local/bin
./bin/suid-audit --root /usr/bin
```

Listet reguläre Dateien mit SUID- oder SGID-Bit rekursiv auf. Ausgabe: Kennzeichen, Dateimodus, numerische UID/GID und Dateipfad. Symbolische Links werden nicht verfolgt, Dateien niemals geändert. **Ein SUID-Bit allein ist keine Sicherheitslücke.** Erfolgreiche Inventarisierung ergibt Exitcode `0`, auch wenn solche Dateien gefunden wurden. Fehlende Rechte können die Vollständigkeit beeinträchtigen.

## `tcp-check` – einfacher TCP-Erreichbarkeitstest

```sh
./bin/tcp-check --host 127.0.0.1 --port 22 --timeout 3
./bin/tcp-check --host server.internal --port 443 --nagios
```

Versucht **eine einzige IPv4-TCP-Verbindung**. Zeitüberschreitung: 1–30 Sekunden, Standard 3. Verbindungsaufbau erzeugt `OK`, ein Fehler `CRITICAL`. Normale Rückgabewerte: `0` verbunden, `1` nicht verbunden, `2` ungültige Parameter. Mit `--nagios`: `0` OK, `2` CRITICAL, `3` UNKNOWN (Parameterfehler). Damit kann das Programm in einfache Nagios-Prüfungen eingebunden werden.

Eine offene TCP-Verbindung beweist **nicht**, dass die Anwendung korrekt funktioniert oder ein TLS-Zertifikat gültig ist. IPv6 wird noch nicht unterstützt. Nur Systeme prüfen, für die eine entsprechende Berechtigung vorliegt.

## Installation und Qualitätssicherung

```sh
make test
sudo make install PREFIX=/usr/freeware
man -M /usr/freeware/man file-integrity
```

Die Tests verwenden ausschließlich temporäre Dateien und einen lokalen TCP-Testserver. `DESTDIR` ermöglicht eine Installation in einen Testbaum. Für macOS ist GitHub Actions vorgesehen; dessen Ergebnisse sind nach dem Einspielen separat zu prüfen.
