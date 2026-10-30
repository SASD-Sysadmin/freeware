# `ssh-key-audit` — Einfache Prüfung von authorized_keys und Dateirechten

**Deutsch** · [English](ssh-key-audit.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/ssh-key-audit.1) · [Quellcode](../../bin/ssh-key-audit)

## Zweck und Einsatzbereich

Heuristische, lesende Untersuchung einer OpenSSH-`authorized_keys`-Textdatei. Standard `$HOME/.ssh/authorized_keys` (ohne HOME: `./.ssh/authorized_keys`). **Keine** Änderung von Schlüsseln/Rechten, Serververbindung, kryptografische Schlüsselvalidierung oder wirksame Serverkonfigurationsprüfung.

## Verhalten und geprüfte Eigenschaften

Ein Symlink **direkt an der Datei** wird abgewiesen; die Datei muss regulär sein. Geprüft werden Gruppen-/Welt-Schreibbits der Datei und ihres unmittelbaren Elternverzeichnisses, nicht ACLs, Eigentümer oder weitere Elternverzeichnisse. Ein eingeschränkter regulärer Ausdruck sucht in Nichtkommentarzeilen bekannte Schlüsseltypen (`ssh-ed25519`, `ssh-rsa`, `ssh-dss`, `ecdsa-sha2-*`, ausgewählte `sk-*`) mit Base64-artigem Feld; davor können Schlüsseloptionen mit Leerzeichen stehen. Unbekannte Zeilen, doppelte Blobs, veraltetes DSA (`ssh-dss`) und zu weitreichende Schreibbits führen zu Warnungen.

## Aufruf und Optionen

```text
ssh-key-audit --help
```

| Option | Bedeutung |
| --- | --- |
| `--file PATH` | Eine bestimmte `authorized_keys`-Datei. |
| `--help` | Hilfe ohne Dateizugriff. |
| `--version` | `ssh-key-audit 0.1.0` anzeigen. |

## Praktisches Beispiel

```sh
# Nur vorhandene authorized_keys lesen.
./bin/ssh-key-audit --file "$HOME/.ssh/authorized_keys"
# Wegwerfbeispiel mit DSA-Hinweis (KEIN echter öffentlicher Schlüssel).
lab="$(mktemp -d)"
printf '%s\n' 'ssh-dss AAAABBBBCCCC beispiel' > "$lab/authorized_keys"
./bin/ssh-key-audit --file "$lab/authorized_keys"
```

Das falsche Base64-Feld demonstriert nur den Textabgleich. **Niemals als berechtigten Schlüssel installieren.** Eine fehlende echte Datei ist ein Fehler, kein Sicherheitsnachweis.

## Ausgabe und Rückgabewerte

`WARN:`-Meldungen und abschließend `SUMMARY: keys=N warnings=N`; teilweise mit Pfad oder Zeilennummer.

`0` = keine erkannten Warnungen; `1` = mindestens eine Warnung; `2` = ungültige Parameter; andere Werte ungleich 0 = fehlende/nicht reguläre Datei, Symlink-Abwehr oder Datei-I/O.

## Grenzen, Sicherheit und Portabilität

Kein vollständiger OpenSSH-Parser. Keine kryptografische Prüfung der Blobs, Zertifikats-/Widerrufsprüfung, `sshd_config`-/`StrictModes`-Bewertung, vollständige Eigentums- oder Elternpfadkontrolle. `ssh-rsa` beweist allein keine Zulassung veralteter SHA-1-Signaturen. Ausgabe mit Pfaden/Metadaten geschützt behandeln. Echte Serverrichtlinien benötigen native Einzeltests.

## Weiterführende Informationen

[SSH-Logauswertung](ssh-auth-summary.de.md) · [Sicherheit](../../SECURITY.md) · [Sammelanleitung](automation-tools.de.md)
