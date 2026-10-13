# quota-report

`quota-report` gibt Benutzer- und Gruppen-Quotas über das systemeigene Programm `quota` aus. Für eine administrative Übersicht verwendet es `repquota`. Das Programm aktiviert keine Quotas und ändert keine Grenzen.

## Voraussetzungen

Perl ab 5.8 mit `Getopt::Long` und `FindBin` sowie das mitgelieferte Modul `SASD::Freeware::External`. Abhängig vom Aufruf muss `quota` oder `repquota` ausführbar im `PATH` liegen; unter Umständen gehören sie zu einem zusätzlich zu installierenden Unix-Paket. Das Dateisystem muss Quotas unterstützen und entsprechend konfiguriert sein. Übersichten können erhöhte Rechte benötigen. Die verfügbaren Schalter und das Ausgabeformat hängen vom Unix-System ab. Das Programm interpretiert die systemspezifische Quotatabelle ausdrücklich nicht selbst.

## Aufruf

```sh
quota-report                  # quota -v für das aktuelle Konto
quota-report --user alice     # quota -v alice
quota-report --group staff    # quota -v -g staff, sofern verfügbar
quota-report --all            # repquota -a, ggf. mit erhöhten Rechten
```

Es wird genau ein Fremdprogramm **ohne Shell** gestartet und dessen Ausgabe unverändert übernommen. `--user`, `--group` und `--all` schließen sich gegenseitig aus. Zulässig sind nur einfache Unix-Kontonamen; abweichende Zeichenfolgen werden abgelehnt.

Die Ausgabe des Systemprogramms beschreibt unter anderem Soft- und Hard-Limits, Blöcke, Inodes und gegebenenfalls Nachfristen. Nicht jedes Unix bietet dieselben Schalter für Gruppen oder Gesamtübersichten; Fehlermeldungen des jeweiligen Programms bleiben sichtbar. Ein erfolgreicher Aufruf beweist nicht, dass für jedes Dateisystem Quotas eingerichtet sind.

## Rückgabewerte

- `0`: Systemprogramm erfolgreich beendet.
- `2`: ungültige Argumente.
- `3`: erforderliches Systemprogramm fehlt oder meldet einen Ausführungsfehler.

## Installation

`make test && make install PREFIX=/usr/freeware`. Die Installation richtet keine Betriebssystem-Quotas ein. Für Benutzerabfragen sind normalerweise keine Root-Rechte notwendig.

## Verwandte Befehle

Unter Linux zeigt `quota-status --all` den Quota-Aktivierungszustand an, ohne ihn zu verändern. `quota-set` bereitet vollständige Grenzen zunächst als Vorschau vor und übernimmt diese erst nach ausdrücklicher Bestätigung. Siehe [quota-status](quota-status.de.md) und [quota-set](quota-set.de.md).
