# log-summary-normalize – Einheitliches Format für M7.5-Zählberichte

`log-summary-normalize` überführt einen **vollständigen Zählbericht** von
`journal-summary`, `syslog-summary`, `ssh-auth-summary` oder
`auth-event-summary` in versionierte JSON-Lines. Das Programm arbeitet
rein lesend und gibt keine Lognachrichten, Benutzernamen, Rechnernamen,
IP-Adressen oder Befehle aus.

**Bewusste Grenze:** M7.5 vereinheitlicht *aggregierte Berichte*, **nicht**
einzelne Ereignisse. Eine Syslog-Nachricht kann beispielsweise sowohl im
Prioritätsbericht als auch in der SSH-Auswertung vorkommen. Die Summen der
vier Quellen dürfen deshalb **nicht zu einer Zahl eindeutiger Ereignisse
addiert** werden. Es gibt hier weder Ereigniszeitstempel noch stabile
Ereignis-IDs, Dublettenerkennung oder eine behauptete zeitliche Korrelation.
Eine belastbare Ereigniskorrelation erfordert später eine eigene Architektur.

## Verwendung

```sh
./bin/syslog-summary --input ./syslog.txt > ./syslog.tsv
./bin/log-summary-normalize \
    --source syslog-summary --input ./syslog.tsv > ./syslog-summary.jsonl

# NUL-Ausgabe des bestehenden SSH-Werkzeugs übernehmen.
./bin/ssh-auth-summary --input ./auth.log --null > ./ssh.counts
./bin/log-summary-normalize \
    --source ssh-auth-summary --format null --input ./ssh.counts

# Standardmäßig liest der Normalisierer von stdin.
./bin/auth-event-summary --input ./auth.log |
    ./bin/log-summary-normalize --source auth-event-summary
```

`--source` ist vorgeschrieben und akzeptiert ausschließlich die vier
obigen Programmnamen. `--input FILE|-` liest standardmäßig stdin.
`--format tsv|null` erwartet entweder TSV mit exakt definierter Kopfzeile
oder die NUL-getrennte Ausgabe (`--null`) des Quellprogramms.
`--help` und `--version` sind vorhanden. Als Eingabe werden **keine rohen
Syslog-Dateien**, sondern fertige Zählberichte erwartet.

Bei einem UNKNOWN-Eintrag liefert das Quellprogramm bereits Status `1`.
Mit `set -o pipefail` kann dieser Status die Pipeline beeinflussen, selbst
wenn die JSONL-Ausgabe des Normalisierers korrekt ist. Diesen Befund bitte
nicht versehentlich unterdrücken.

## Festes Ausgabeformat `sasd.log-summary.v1`

Jede JSONL-Zeile enthält ausschließlich:

| Feld | Bedeutung |
| --- | --- |
| `schema` | `sasd.log-summary.v1` |
| `scope` | `source_summary` – ausdrücklich keine Einzelereignisse |
| `source` | Name eines der vier Programme |
| `type` | `category` oder `total` |
| `category` | Vorbestimmte Ereignis- bzw. Prioritätsklasse oder `TOTAL` |
| `priority` | Ganzzahl von 0 bis 7 nur bei bekannten Syslog-/Journal-Prioritäten; sonst JSON `null` |
| `count` | Nichtnegative Ganzzahl bis 50000 |

Beispiel:

```json
{"category":"FAILED","count":3,"priority":null,"schema":"sasd.log-summary.v1","scope":"source_summary","source":"ssh-auth-summary","type":"category"}
```

Alle erwarteten Kategorien erscheinen auch mit Zähler 0; eine eigene
`type=total`-Zeile gibt die Gesamtzahl an. Die Reihenfolge entspricht dem
Quellprogramm. Die Kontrolle ist absichtlich streng: falsche Kopfzeilen,
fehlende oder doppelte Kategorien, ungültige Prioritäten, zusätzliche Felder,
unzulässige Dezimaldarstellungen und eine falsche Gesamtsumme führen zum
Abbruch **ohne Teilausgabe**.

Journal und Syslog liefern drei Spalten/Felder (`PRIORITY`, `LEVEL`, `COUNT`).
SSH und sudo/su/PAM liefern zwei (`EVENT`, `COUNT`). Aus
Authentifizierungsereignissen wird **kein** Schweregrad geraten.

## Grenzen und Rückgabewerte

- Höchstens 8192 Eingabebytes, 16 Zeilen und Zähler bis 50000.
- Nur begrenzte Datei oder stdin; symbolische Links und nichtreguläre Dateien
  werden abgewiesen. Der geöffnete Dateideskriptor wird zusätzlich geprüft.
- Keine Root-Rechte, Dienste, Netzwerkzugriffe oder Änderungen am System.
  Quellpfade und Inhalte erscheinen nicht in Fehlermeldungen.
- `0`: gültiger Bericht ohne UNKNOWN; `1`: gültiger Bericht mit UNKNOWN;
  `2`: ungültige Parameter; `3`: fehlerhafte, unvollständige oder zu große
  Eingabe bzw. fehlendes JSON::PP. Bei Status 3 keine Teil-JSON-Ausgabe.

## Tests

```sh
perl -c bin/log-summary-normalize
prove -v tests/test_log_summary_normalize.t
make test
make shellcheck
```

Offline-Regressionen prüfen alle vier Quellen, TSV/NUL, Grenzwerte,
fehlende Zeilen, doppelte Kategorien, irreführende Eingaben, unzulässige
Steuerzeichen, falsche Gesamtsummen und Symlinks. Live-Prüfungen,
plattformübergreifende Vollständigkeit und echte Ereigniskorrelation sind
noch offen.
