# `auth-event-summary` – Offline-Zählung von sudo-/su-/PAM-Meldungen (M7.4)

[English](auth-event-summary.md) · [Roadmap](../ROADMAP.de.md) · [Manpage](../../man/man1/auth-event-summary.1)

`auth-event-summary` ist ein **lesendes, ressourcenbegrenztes Perl-Programm**
für ausgewählte `sudo`-, `su`- und `pam_unix`-Meldungen in **klassischen
RFC3164-ähnlichen Syslog-Exporten**, mit oder ohne `<PRI>` am Zeilenanfang.
Es öffnet keine Systemlogs automatisch, startet keine Dienste und benötigt
für bereits lesbare Eingaben keine Root-Rechte.

Es zählt ausschließlich **Meldungsmuster**, nicht eindeutige Personen oder
Anmeldeversuche. Ein protokollierter `sudo`-Aufruf beweist weder den Abschluss
noch den Erfolg des aufgerufenen Befehls. Eine PAM-Meldung über eine geöffnete
Sitzung beweist keine erfolgreiche Passwortauthentifizierung. Gefälschte,
fehlende, verspätete oder unvollständige Logdaten bleiben grundsätzlich möglich.

## Verwendung

```sh
# Harmloses Testbeispiel, keine echten Host-Logs:
printf '%s\n' \
  'Oct 22 08:15:20 lab sudo[7]: user : TTY=pts/0 ; PWD=/tmp ; USER=root ; COMMAND=/usr/bin/id' \
  | ./bin/auth-event-summary

# Ein vorher exportierter, regulärer Log-Snapshot:
./bin/auth-event-summary --input ./auth-export.log

# Maschinenlesbares Format:
./bin/auth-event-summary --input ./auth-export.log --null
```

`--input FILE|-` liest eine einzelne reguläre Datei ohne Symlinks oder stdin
(Standard `-`). Es gibt kein `--follow`, keine automatische Logrotation,
Dekompression oder Dateisuche in `/var/log`. Unter macOS sind nur die
Offline-Tests belegt; es besteht **keine native Unified-Log-Unterstützung**.

## Ereignisklassen

| Klasse | Tatsächlich erkanntes Meldungsmuster |
| --- | --- |
| `SUDO_COMMAND` | Strukturierte sudo-Zeile mit TTY, PWD, USER, COMMAND und ggf. CHROOT/GROUP/TSID – **kein Nachweis für erfolgreiche Befehlsausführung**. |
| `SUDO_DENIED` | Bestimmte sudoers-Ablehnungen oder protokollierte fehlgeschlagene Passworteingaben. |
| `SU_SUCCESS` | util-linux-su-Muster `(to ZIEL) AUFRUFER on TTY` – **kein Nachweis für eine gestartete Sitzung**. |
| `SU_FAILED` | Muster `FAILED SU (to ZIEL) AUFRUFER on TTY`. |
| `PAM_AUTH_FAILURE` | Unterstützte `pam_unix(DIENST:auth): authentication failure`-Meldung. |
| `PAM_SESSION_OPEN` | `pam_unix(DIENST:session): session opened for user ...`; keine sichere Aussage über die vorherige Authentifizierung. |
| `PAM_SESSION_CLOSE` | Entsprechende PAM-Meldung zum Schließen der Sitzung. |
| `OTHER_AUTH` | Sonstige oder nicht unterstützte Meldungen der Tags `sudo`, `sudo-i`, `su`, `su-l`. |
| `OTHER_SERVICE` | Formal gültige Zeile eines anderen Dienstes, beispielsweise `sshd`. |
| `UNKNOWN` | Nicht interpretierbare Log-Hülle oder ungültiges PRI. |
| `TOTAL` | Alle eingelesenen physischen Datensätze. |

Jede Logzeile wird **genau einmal** zugeordnet. Ein menschlicher Versuch kann
mehrere Logzeilen verursachen, etwa eine PAM-Fehlermeldung und eine separate
su-Fehlermeldung. Deshalb ist die Gesamtzahl kein Zähler eindeutiger Versuche.

Die unterstützte Hülle verlangt englische Monatskürzel, plausibles Datum und
Uhrzeit, Host, Dienst-Tag und Nachricht. Das optionale PRI muss kanonisch und
im Bereich 0..191 liegen. Die PAM-Dienstfamilie muss zum Tag passen:
`sudo*` zu `sudo*`, `su*` zu `su*`. PAM-Ereignisse anderer Dienste sowie
RFC5424-/ISO-Zeitstempel gehören noch **nicht** zu diesem Meilenstein.
Das Programm interpretiert keine Syslog-Prioritäten und überlappt nicht mit
den SSHD-Klassen aus M7.3.

## Ausgabe, Grenzen und Rückgabecodes

TSV enthält die Spalten `EVENT` und `COUNT`: zehn Ereignisklassen sowie
`TOTAL`. `--null` liefert elf Zeilen mit je zwei NUL-terminierten Feldern,
ohne Kopfzeile. Benutzernamen, Hostnamen, IP-Adressen, Befehle, Dateipfade,
PIDs, Zeitstempel und rohe Nachrichten werden **niemals ausgegeben**.

| Code | Bedeutung |
| --- | --- |
| `0` | Vollständig gelesen, alle Datensatzhüllen interpretierbar; auch bei fehlgeschlagenen Anmeldeereignissen. |
| `1` | Vollständig gelesen, mindestens eine Hülle/PRI `UNKNOWN`. |
| `2` | Ungültige Kommandozeile. |
| `3` | Datei-/Lesefehler, gefährliche Datensatzrahmung, unvollständige Zeile, Leerzeile oder Limitüberschreitung; **kein Teilbericht**. |

Limits: **16 MiB** Gesamtgröße, **128 KiB** pro physischer Zeile und
**50.000** Datensätze. CRLF ist erlaubt, ansonsten muss jede nichtleere
Eingabe mit LF enden. NUL und eingebettete CR werden abgewiesen. Die gesamte
Eingabe wird vor der Ausgabe überprüft. Bei parallel veränderten Dateien kann
kein atomarer Snapshot garantiert werden; für zuverlässige Zahlen stabile
Exporte verwenden. Niemals Rohlogs mit personenbezogenen Daten in öffentliche
Issues stellen.

## Tests

```sh
perl -c bin/auth-event-summary
prove tests/test_auth_event_summary.t
make test
make shellcheck
```

Die Tests prüfen synthetische Ereignisse, keine reale Hostkonfiguration.
Hintergrund zu den Logmustern: [sudoers(5)](https://man7.org/linux/man-pages/man5/sudoers.5.html),
[util-linux `su`](https://github.com/util-linux/util-linux/blob/master/login-utils/su-common.c).
