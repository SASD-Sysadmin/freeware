# `journal-summary` – strukturierte systemd-Journal-Auswertung (M7.1)

[English](journal-summary.md) · [Roadmap](../ROADMAP.de.md) · [Manpage](../../man/man1/journal-summary.1)

`journal-summary` zählt die Prioritäten von **bereits exportierten**
`journalctl --output=json`-Einträgen. Das Programm wertet nicht die
Nachrichtentexte aus und ruft weder `journalctl` noch andere externe
Programme auf. `log-summary` bleibt für unstrukturierte Textprotokolle
unverändert erhalten; die beiden Werkzeuge dürfen nicht gleichgesetzt werden.

## Aufruf

```sh
# Vom Administrator bewusst exportierte, kontrollierte Testdatei
./bin/journal-summary --input ./test-journal.jsonl

# Eine begrenzte Stichprobe des eigenen Systems, ohne Zwischendatei.
# journalctl läuft explizit durch die Shell, NICHT durch journal-summary.
journalctl --no-pager -n 100 --output=json | ./bin/journal-summary

# Maschinenformat (drei NUL-abgeschlossene Felder je Datensatz)
./bin/journal-summary --input ./test-journal.jsonl --null
```

`--input -` bzw. kein `--input` liest stdin. `--input DATEI` akzeptiert
lesbare reguläre Dateien, aber keine symbolischen Links. Das Programm
verändert weder Journale noch Konfigurationen und benötigt selbst keine
Root-Rechte. Zugriff auf Journale oder deren Export ist Sache des
aufrufenden Administrators.

## Datenmodell und Prioritäten

`journalctl --output=json` erzeugt genau ein JSON-Objekt je Zeile. Das Feld
`PRIORITY` ist normalerweise eine Dezimalzeichenkette von `"0"` bis `"7"`.

| Wert | Ausgabe |
| --- | --- |
| `0` | EMERGENCY |
| `1` | ALERT |
| `2` | CRITICAL |
| `3` | ERROR |
| `4` | WARNING |
| `5` | NOTICE |
| `6` | INFO |
| `7` | DEBUG |
| fehlend, `null`, Array oder ungültig | UNKNOWN |

Auch als JSON-Zahl übermittelte einstellige Werte 0–7 werden akzeptiert.
UNKNOWN ist ein Qualitätsbefund, **keine automatische Sicherheitswarnung**.
Die Ausgabe ist TSV mit den Spalten `PRIORITY`, `LEVEL`, `COUNT`, anschließend
je einer festen Zeile für UNKNOWN und TOTAL. `--null` enthält dieselben zehn
Datensätze ohne Header, je drei NUL-abgeschlossene Felder.

**Datenschutz:** `MESSAGE`, `SYSLOG_IDENTIFIER`, Hostnamen, Zeitstempel,
Benutzernamen und Eingabepfade erscheinen nie im Bericht. Allerdings
können echte Journal-Daten persönliche Informationen enthalten: keine
ungeschwärzten JSON-Exporte in Issues oder auf GitHub veröffentlichen.
Auch ein formal korrektes Feld `PRIORITY` ist clientseitig beeinflussbar.
Die Zählung ist deshalb **keine Sicherheitszertifizierung** und keine
sichere Erkennung von Angriffen.

## Grenzen und Rückgabewerte

- Höchstens **16 MiB** Eingabe, **128 KiB** je JSON-Zeile und **50.000**
  Datensätze. In M7.1 wird die gesamte begrenzte Eingabe im Speicher
  gehalten; ein `journalctl --follow`-Dauerstrom ist nicht vorgesehen.
- Es muss jede JSON-Zeile vollständig und syntaktisch korrekt sein.
  Bei Lesefehlern, abgeschnittenen Zeilen oder Limitüberschreitung wird
  **kein Teilbericht** veröffentlicht.
- `0`: Eingabe vollständig, alle erkannten Datensätze mit gültiger Priorität.
- `1`: Eingabe vollständig, mindestens eine ungültige/fehlende Priorität.
- `2`: ungültige Kommandozeile.
- `3`: fehlende Voraussetzung oder ungültige, abgeschnittene oder zu große
  JSON-Eingabe.
- Keine Echtzeitüberwachung, Persistierung, Alarmierung, Signaturanalyse oder
  plattformspezifischen macOS-Log-Adapter. Unter macOS können exportierte
  systemd-JSON-Testdaten gelesen werden, **nicht** das native Apple-Log.

Offizielle Referenzen:
[systemd-Journalfelder](https://www.freedesktop.org/software/systemd/man/systemd.journal-fields.html),
[journalctl](https://www.freedesktop.org/software/systemd/man/journalctl.html).
