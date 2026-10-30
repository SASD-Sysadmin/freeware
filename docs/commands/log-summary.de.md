# `log-summary` — Zeilenweise Text-Logauswertung

**Deutsch** · [English](log-summary.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/log-summary.1) · [Quellcode](../../bin/log-summary)

## Zweck und Einsatzbereich

Zählt Zeilen aus einer Textdatei oder Standardeingabe. Ausgegeben werden nur Zähler, keine Originalmeldungen. Das Verfahren ist eine Wörter-Heuristik, **kein** syslog-/JSON-Parser, keine Ereigniskorrelation und keine Manipulationserkennung.

## Verhalten und geprüfte Eigenschaften

Für jede gelesene Zeile steigt `Lines read:`. Bei `--match` werden nur Zeilen mit der wörtlichen Teilzeichenkette (ohne Groß-/Kleinschreibung) verarbeitet; **kein Regex**. Jede ausgewählte Zeile zählt in genau einer Kategorie: `CRITICAL` (EMERG, EMERGENCY, ALERT, CRIT, CRITICAL, FATAL), `ERROR` (ERR, ERROR), `WARNING` (WARN, WARNING), `NOTICE`, `INFO`, `DEBUG`, `TRACE` oder `OTHER`. Wortgrenzen bestimmen Treffer; bei mehreren Wörtern gewinnt der höhere Schweregrad, auch wenn das Wort nur im freien Nachrichtentext vorkommt.

## Aufruf und Optionen

```text
log-summary --help
```

| Option | Bedeutung |
| --- | --- |
| `--match LITERAL` | Wörtlicher, nicht groß-/kleinschreibungssensitiver Filter. |
| `LOGFILE` | Eine Textdatei lesen. |
| `-` oder ohne Pfad | Standardeingabe lesen. |
| `-h`, `--help` | Hilfe anzeigen. |
| `--version` | `log-summary 0.1.0` anzeigen. |

## Praktisches Beispiel

```sh
printf '%s\n' 'INFO started' 'WARN retry' 'ERROR refused' | \
  ./bin/log-summary -
printf '%s\n' 'INFO sshd ready' 'WARN job delayed' 'ERROR sshd refused' | \
  ./bin/log-summary --match sshd -
```

Echte Logs lassen sich bei ausreichenden Leserechten mit `./bin/log-summary /var/log/syslog` oder `journalctl --no-pager -n 1000 | ./bin/log-summary -` verarbeiten. Der Befehl endet am Dateiende und verfolgt keine wachsende Datei.

## Ausgabe und Rückgabewerte

`Lines read:`, `Lines matched:` und die acht Klassen `CRITICAL`, `ERROR`, `WARNING`, `NOTICE`, `INFO`, `DEBUG`, `TRACE`, `OTHER`. Herausgefilterte Zeilen zählen in keiner Klasse.

`0` = erfolgreiche Auswertung, **auch bei vielen ERROR-/CRITICAL-Wörtern**; `2` = Aufruffehler; andere Werte ungleich 0 = Datei-/Schließfehler. Alarmierungsskripte müssen die Zähler lesen.

## Grenzen, Sicherheit und Portabilität

Keine Zeiträume, strukturierte Prioritäten, Deduplikation, Rotation, Anwendungsdiagnose oder beweissichere Logaufzeichnung. Auch wenn nur Zähler ausgegeben werden, können Eingabelogs vertraulich sein. Perl-Standardfunktionen reichen aus; Logpfade unterscheiden sich je Betriebssystem.

## Weiterführende Informationen

[`syslog-summary`](syslog-summary.de.md) · [`journal-summary`](journal-summary.de.md) · [Perl-Sammelanleitung](perl-tools.de.md)
