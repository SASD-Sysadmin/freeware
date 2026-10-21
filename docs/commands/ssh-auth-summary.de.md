# `ssh-auth-summary` – SSH-Anmeldemuster aus gespeicherten Logs (M7.3)

[English](ssh-auth-summary.md) · [Roadmap](../ROADMAP.de.md) · [Manpage](../../man/man1/ssh-auth-summary.1)

`ssh-auth-summary` wertet **OpenSSH-sshd-Meldungsmuster** aus gespeicherten,
klassischen Syslog-Textdateien aus. Das Programm arbeitet begrenzt und
**ausschließlich lesend**. Es ist weder eine vollständige
Authentifizierungskontrolle noch eine Angriffserkennung oder eine Quelle für
beweiskräftige Anmeldehistorien. Logeinträge können gefälscht, gelöscht,
rotiert oder aufgrund unzureichender Zugriffsrechte unvollständig sein.

## Beispiele

```sh
# Synthetische Beispieldaten, keine lokalen Systemlogs:
printf '%s\n' \
  'Oct 21 08:30:04 lab sshd[100]: Failed password for guest from 192.0.2.10 port 2222 ssh2' \
  | ./bin/ssh-auth-summary

# Eine zuvor exportierte, endliche Textdatei auswerten:
./bin/ssh-auth-summary --input ./ssh-beispiel.log

# Maschinenausgabe mit NUL-getrennten Feldern:
./bin/ssh-auth-summary --input ./ssh-beispiel.log --null
```

Standard ist stdin (`--input -` wählt ebenfalls stdin). Benannte Eingaben
müssen lesbare reguläre Dateien sein; symbolische Links werden abgewiesen.
Das Programm ruft weder SSH- noch Log-Dienste auf, verändert keine
Systemdaten und erhöht keine Berechtigungen. systemd-Journal-JSON und
macOS Unified Logging sind keine unterstützten Eingabeformate.

## Unterstützte Eingaben und Grenzen

- Eine nichtleere Eingabe besteht aus mit LF abgeschlossenen, nichtleeren
  Zeilen. CRLF wird akzeptiert. Leere Eingabe ist zulässig.
- Unterstützt wird die klassische, **RFC3164-ähnliche** Struktur
  `Mon TT HH:MM:SS HOST TAG[PID]: NACHRICHT`, optional mit einem kanonischen
  `<PRI>`-Präfix zwischen 0 und 191. Das Datum enthält weder Jahr noch
  Zeitzone; der 29. Februar ist zulässig. Ein `<PRI>` ist bei lokalen
  `/var/log/auth.log`- oder `/var/log/secure`-Dateien oft nicht vorhanden.
  Es wird **niemals** zur Ermittlung von Anmeldeerfolg/-misserfolg verwendet.
- Nur der Programmname `sshd` zählt als SSHD. Meldungen anderer Dienste
  werden nicht als SSH-Anmeldung ausgelegt.
- Erkannt werden die Präfixmuster `Accepted METHODE for BENUTZER from
  ADRESSE port N ssh2`, `Failed METHODE for [invalid user] BENUTZER from
  ADRESSE port N ssh2` und `Invalid user BENUTZER from ADRESSE port N`.
  Erlaubte Methoden: `password`, `publickey`, `keyboard-interactive/pam`,
  `gssapi-with-mic`. Das Adressfeld muss IPv4-/IPv6-ähnlich aussehen, die
  Portzahl liegt bei 1..65535. **Identität und Herkunft werden damit nicht
  unabhängig verifiziert.** Weitere OpenSSH-Meldungen bleiben OTHER_SSHD.
- RFC5424, macOS Unified Logging, rotierten/komprimierten Dateien sowie
  durchgehendes Überwachen werden hier nicht unterstützt. Für strukturierte
  Syslog-Prioritäten gibt es `syslog-summary`; für Journal-JSONL
  `journal-summary`.

## Auswertung und Datenschutz

Die TSV-Ausgabe verwendet `EVENT` und `COUNT` und sieben Datenzeilen:

| Ereignis | Bedeutung |
| --- | --- |
| `ACCEPTED` | Erkanntes `sshd`-Muster für eine akzeptierte Authentifizierung |
| `FAILED` | Erkanntes `sshd`-Muster für eine fehlgeschlagene Authentifizierung |
| `INVALID_USER` | Erkanntes `sshd`-Muster für einen unbekannten Benutzernamen |
| `OTHER_SSHD` | Erkanntes `sshd`-Logformat, anderes Nachrichtenmuster |
| `OTHER_SERVICE` | Erkanntes Syslogformat eines anderen Dienstes |
| `UNKNOWN` | Nicht unterstütztes oder unbekanntes Syslog-Format |
| `TOTAL` | Gesamtzahl der vollständig geprüften Eingabezeilen |

Mit `--null` werden **14 NUL-terminierte Felder** ausgegeben: jeweils
Ereignis und Anzahl, ohne Tabellenkopf. Ausschließlich feste Bezeichnungen
und Zahlen werden ausgegeben: keine Benutzernamen, IP-Adressen,
Schlüsselfingerabdrücke, Hostnamen, Zeitstempel, Nachrichten, Dateipfade oder
Terminal-Steuerzeichen.

**Die Zahlen zählen Meldungen, keine eindeutigen Benutzer oder
Anmeldeversuche.** Ein Versuch kann mehrere Meldungen auslösen, z. B.
`INVALID_USER` und `FAILED`. Ein Exitcode 0 bestätigt weder die
Unverfälschtheit noch die Vollständigkeit der Logs.

## Ressourcen, Rückgabewerte und Tests

Die maximale Eingabe beträgt **16 MiB**, **128 KiB je physischer Zeile** und
**50.000 Datensätze**. Erst nach vollständiger Prüfung wird ein Bericht
veröffentlicht. Leere Zeilen, fehlendes abschließendes LF, NUL, einzelne CR,
Dateizugriffsfehler oder überschrittene Grenzen bewirken Exitcode 3 ohne
Teilbericht. Unbekannte, aber physisch korrekte Logstruktur zählt als
`UNKNOWN` mit Exitcode 1.

| Exit | Bedeutung |
| --- | --- |
| `0` | Eingabe vollständig, alle Zeilen strukturell bekannt oder leer |
| `1` | Vollständig gelesen, mindestens ein `UNKNOWN` |
| `2` | Ungültige Kommandozeile |
| `3` | Eingabe nicht verfügbar, beschädigt, nicht abgeschlossen oder zu groß |

```sh
perl -c bin/ssh-auth-summary
prove -v tests/test_ssh_auth_summary.t
make test
make shellcheck
```

Die automatischen Tests verwenden nur synthetische Daten und verändern keine
SSH-Konfiguration oder Systemkonten. Ubuntu-/macOS-CI belegt den Offline-Code,
nicht den Betrieb auf sämtlichen echten Logsystemen.
