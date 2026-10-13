# quota-status

`quota-status` zeigt an, was das Linux-Systemprogramm `quotaon -p` über die Aktivierung von Dateisystem-Quotas meldet. Es **aktiviert, deaktiviert und verändert keine Quotas**. Die Ausgabe des Betriebssystems wird unverändert übernommen, da sich die Formate zwischen Systemversionen unterscheiden können.

## Voraussetzungen

Linux, Perl 5 mit den Kernmodulen `Getopt::Long`, `FindBin`, `File::Spec` und `Cwd`, das mitgelieferte Modul `SASD::Freeware::External` sowie das Betriebssystemprogramm `quotaon` mit Unterstützung für **`-p` (Status anzeigen)**. Unter Linux gehört es üblicherweise zum Paket `quota`. Möglicherweise sind besondere Berechtigungen nötig. Unterstützt das installierte `quotaon` kein `-p`, führt das zu einem Fehler.

## Aufruf

```sh
quota-status --all
quota-status --filesystem /home
```

Ein Betriebsmodus ist zwingend anzugeben. `--all` ruft `quotaon -p -a` auf, während `--filesystem` den absoluten, kanonischen Verzeichnispfad an `quotaon -p` übergibt. Beide Optionen dürfen nicht kombiniert werden. Ein symbolischer Link als letztes Pfadelement wird abgewiesen. Der Aufruf erfolgt ohne Shell.

Die native Statusausgabe wird unverändert angezeigt. Das Programm interpretiert diese nicht, kontrolliert keine Quota-Grenzen und aktiviert kein Quota-Accounting. `quota-report` liest Benutzer- beziehungsweise Gruppenquotas; `quota-set` verwaltet Grenzwerte nach ausdrücklicher Bestätigung.

## Rückgabewerte

- `0`: Systemprogramm `quotaon -p` erfolgreich beendet (keine Garantie, dass Quotas überall aktiviert sind).
- `2`: fehlende, widersprüchliche oder ungültige Parameter.
- `3`: Betriebssystem nicht unterstützt, Systemprogramm fehlt oder Fehler beim nativen Aufruf.

Installation über `make install PREFIX=/usr/freeware`. Handbuchseite: `man -M /usr/freeware/man 1 quota-status`.
