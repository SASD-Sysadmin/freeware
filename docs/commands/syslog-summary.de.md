# `syslog-summary` – strukturierte Syslog-Prioritäten (M7.2)

[English](syslog-summary.md) · [Roadmap](../ROADMAP.de.md) · [Manpage](../../man/man1/syslog-summary.1)

`syslog-summary` ist eine **lesende, begrenzte Offline-Auswertung** von klassischen
Syslog-Zeilen (BSD/RFC3164) und RFC5424-Nachrichten. Das Programm zählt nur
**nachweisbar im Syslog-Header enthaltene** Prioritäten. Es sucht **keine**
Schlüsselwörter wie `error` oder `warning` im Nachrichtentext. So werden
Textinhalte nicht versehentlich als echte Schweregrade ausgegeben.

## Aufrufe

```sh
# Test ohne Zugriff auf produktive Logs:
printf '%s\n' '<34>Oct 21 08:30:04 testhost app: error in message' \
  | ./bin/syslog-summary

# Bewusst exportierte, endliche Datei (regulär, ohne Symlink):
./bin/syslog-summary --input ./test.syslog

# Nur RFC5424 auswerten, Maschinenformat für Automation:
./bin/syslog-summary --input ./test.syslog --format rfc5424 --null
```

Ohne `--input` beziehungsweise mit `--input -` wird stdin gelesen. `--format`
ist `auto` (Standard), `rfc3164` oder `rfc5424`. Das Programm selbst ruft
**kein** `journalctl`, `logger`, `tail`, `cat` oder andere Programme auf.
Es liest weder `/var/log` automatisch noch benötigt es Root-Rechte.

## Warum häufig UNKNOWN ausgegeben wird

Bei RFC3164 steht, sofern vorhanden, ein `<PRI>` am **Beginn der Zeile**.
Diese Zahl kodiert `facility * 8 + severity`; nur `severity = PRI % 8`
(0 bis 7) wird gezählt. Unterstützt sind kanonische PRI-Werte **0–191**.
Danach muss ein plausibler RFC3164-Header mit Monatskürzel, Tag, Uhrzeit,
Hostname und Nachricht folgen. RFC5424 benötigt `<PRI>1`, die Headerfelder
und ein gültiges Structured-Data-Feld beziehungsweise `-`. RFC5424-Nachrichten
mit einer anderen Protokollversion gelten zunächst als UNKNOWN.

**Wichtig:** Viele lokale Syslog-Dateien enthalten zwar Zeitstempel, Host
und Nachricht, aber **keine** `<PRI>`-Angabe. In solchen Dateien lässt sich
der ursprüngliche Schweregrad nicht zuverlässig rekonstruieren. Diese Zeilen
werden als **UNKNOWN** gezählt (Exitcode `1`), nicht durch Textschlüsselwörter
oder vermutete Standardwerte klassifiziert. Ein `<3>` mitten in `MESSAGE`
ändert daran nichts. Es gibt bewusst keinen `--assume-priority`-Schalter.

| Priorität | Kategorie |
| --- | --- |
| 0 | EMERGENCY |
| 1 | ALERT |
| 2 | CRITICAL |
| 3 | ERROR |
| 4 | WARNING |
| 5 | NOTICE |
| 6 | INFO |
| 7 | DEBUG |
| ohne verifizierbaren Header/PRI | UNKNOWN |

Die Ausgabe besteht aus der TSV-Überschrift `PRIORITY`, `LEVEL`, `COUNT`, acht
Prioritätszeilen und je einer Zeile für UNKNOWN und TOTAL. `--null` liefert
zehn Datensätze mit je **drei NUL-terminierten Feldern**, ohne Überschrift.
Dies entspricht dem Ausgabeformat von `journal-summary` (M7.1), nicht aber
dessen Eingabeformat: `journal-summary` erwartet JSONL aus `journalctl`.
Das ältere `log-summary` zählt dagegen *Textschlüsselwörter* und bleibt
unverändert. Die Ergebnisse der drei Programme sind nicht austauschbar.

## Sicherheitsgrenzen und Vollständigkeit

- Höchstens **16 MiB** Eingabe, **128 KiB** pro physischer Zeile und
  **50.000** Datensätze. Vollständig begrenzte Daten werden vor der
  Ausgabe gelesen und geprüft; `tail -f` ist nicht geeignet.
- Leere Eingabe ist zulässig. Jede nichtleere Datei benötigt am Ende ein LF;
  CRLF-Zeilen sind zulässig. Leere Zeilen und überschrittene Grenzen sind
  **Fehler ohne Teilbericht** (`3`). Ungültige/fehlende Header sind dagegen
  Qualitätsbefunde und werden als UNKNOWN gezählt (`1`).
- Eingabezeilen, Zeitstempel, Hostnamen, Programme, Structured Data,
  Nachrichtentexte, Geheimnisse und Eingabepfade erscheinen **niemals** in
  der Ausgabe. Trotzdem sollten echte Syslog-Rohdaten nicht öffentlich in
  Issues oder CI-Protokollen veröffentlicht werden.
- Ein syntaktisch korrektes PRI-Feld kann vom sendenden Programm beeinflusst
  oder von Weiterleitungen verändert worden sein: Es ist **kein** Beweis für
  die tatsächliche Gefährlichkeit eines Ereignisses.
- Kein Zugriff auf rotierte/comprimierte Logs, keine Quellaggregation über
  mehrere Dateien, keine Echtzeitüberwachung, keine Persistenz und kein
  nativer macOS-Unified-Log-Adapter. Plattformübergreifende Offline-Tests
  ersetzen keine reale Abnahme mit lokalen Logformaten.

## Exitcodes

| Code | Bedeutung |
| --- | --- |
| `0` | Alle Zeilen haben einen erkannten PRI/Envelope (oder Eingabe leer) |
| `1` | Vollständige Auswertung, aber mindestens eine Zeile ist UNKNOWN |
| `2` | Ungültige Kommandozeile |
| `3` | Datei-, Lese-, Struktur-, Größen- oder Datensatzlimitfehler |

## Testen

```sh
prove tests/test_syslog_summary.t
make test
make shellcheck
```

Alle Regressionstests nutzen künstliche Syslog-Daten und benötigen keine
privilegierten Berechtigungen oder Netzwerkzugriffe.

**Technische Bezugspunkte:** [RFC 3164](https://www.rfc-editor.org/rfc/rfc3164),
[RFC 5424](https://www.rfc-editor.org/rfc/rfc5424).
