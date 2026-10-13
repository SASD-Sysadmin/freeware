# quota-set

`quota-set` bereitet einen **vollständigen Linux-Datensatz für Benutzer- oder Gruppenquotas** vor und kann ihn mit dem vorhandenen Systemprogramm `setquota` übernehmen. Das Programm aktiviert keine Quotas, mountet keine Dateisysteme, legt keine Benutzer an und ändert keine Karenzzeiten. Standardmäßig zeigt es ausschließlich eine Vorschau und ruft `setquota` **nicht** auf.

## Voraussetzungen

- Linux mit Perl 5 und den Kernmodulen `Getopt::Long`, `FindBin`, `File::Spec` und `Cwd` sowie dem mitgelieferten Modul `SASD::Freeware::External`.
- Für `--apply`: das Betriebssystemprogramm `setquota` (unter Linux üblicherweise aus dem Paket `quota`), ein mit passenden Quotas gemountetes Dateisystem, ein über die System-Namensauflösung bekanntes Benutzer- oder Gruppenkonto und in der Regel Administratorrechte.
- Der Mountpoint muss als genauer Mount-Eintrag in `/proc/self/mounts` vorkommen. Symbolische Links als letztes Pfadelement werden abgelehnt. Die Software kann nicht sämtliche Quota-Konfigurationen erkennen; ein Fehler des Systemprogramms führt zum Abbruch.
- `setquota` muss über `PATH` in einem absoluten Verzeichnis gefunden werden. Bei effektivem Benutzer `root` muss die Programmdatei einschließlich ihres Verzeichnispfades root gehören und gegen Schreibzugriffe anderer Benutzer und Gruppen geschützt sein.

## Aufruf

```sh
# Zuerst nur anzeigen:
quota-set --user alice --filesystem /home \
  --block-soft 100000 --block-hard 120000 \
  --inode-soft 20000 --inode-hard 25000

# Nach Prüfung bewusst anwenden:
sudo /usr/freeware/sbin/quota-set --user alice --filesystem /home \
  --block-soft 100000 --block-hard 120000 \
  --inode-soft 20000 --inode-hard 25000 \
  --apply --confirm-apply

# Gruppenquotas vorbereiten:
quota-set --group engineers --filesystem /srv/projects \
  --block-soft 800000 --block-hard 900000 \
  --inode-soft 15000 --inode-hard 17000
```

`--dry-run` fordert ausdrücklich die ohnehin voreingestellte Vorschau an. `--dry-run` und `--apply` schließen sich aus. Für `--apply` muss außerdem `--confirm-apply` angegeben werden. **Alle vier Grenzwerte müssen vorhanden sein**; auch unveränderte Werte sind aus dem aktuellen Quota-Datensatz zu übernehmen. Dadurch kann ein fehlendes Feld nicht unbemerkt als unbegrenzt gesetzt werden.

Blockgrenzen werden in **1024-Byte-Blöcken (KiB)** angegeben; Inode-Grenzen zählen Dateien. Nur nichtnegative Dezimalzahlen ohne K/M/G-Suffix sind zulässig, höchstens 9223372036854775807. Positive Softlimits dürfen die positiven Hardlimits nicht überschreiten. Der Wert **0 bedeutet unbegrenzt** und nicht „kein Speicher“. Soll ein Nullwert übernommen werden, ist zusätzlich `--allow-unlimited` erforderlich. Schon die Vorschau weist auf diese Bedeutung hin.

Der Systemaufruf entspricht beispielsweise:

```sh
setquota -u alice 100000 120000 20000 25000 /home
```

Für Gruppen wird `-g` statt `-u` verwendet. Das Backend wird ohne Shell gestartet. Benutzer- und Gruppennamen müssen sich über den vorhandenen Namensdienst auflösen lassen; rein numerische IDs werden nicht angenommen. Eine erfolgreiche Rückmeldung von `setquota` bestätigt nur den Rückgabewert des Programms, **nicht** eine erneute Auslesung der gesetzten Quotas. Hierzu anschließend `quota-report` verwenden.

## Betriebshinweise

Vor jeder Änderung Dateisystem, Identität, Blockeinheiten, Quota-Aktivierung und aktuelle Grenzwerte prüfen. Karenzzeiten der Softlimits werden separat vom Betriebssystem verwaltet. Es gibt keine Transaktion, keinen automatischen Rollback und keine Nachbildung unterschiedlicher Unix-Quota-Schnittstellen. Bei einem Fehler den tatsächlichen Zustand prüfen, bevor der Aufruf wiederholt wird. Vorherige Werte für eine mögliche Wiederherstellung dokumentieren.

Das **Anwenden** ist nur unter Linux unterstützt. Eine Vorschau auf anderen Unix-Systemen bedeutet nicht, dass dort ein kompatibles `setquota` existiert.

## Rückgabewerte

- `0`: Vorschau erstellt oder nativer `setquota`-Aufruf erfolgreich beendet.
- `2`: ungültige beziehungsweise widersprüchliche Parameter, unzulässige Grenzen oder fehlende Änderungsbestätigung.
- `3`: Voraussetzung fehlt, Konto unbekannt, Plattform nicht unterstützt, `setquota` fehlt oder ist nicht vertrauenswürdig, Mountpoint ungültig oder Backend-Aufruf gescheitert.

## Installation und weitere Befehle

`make test && sudo make install PREFIX=/usr/freeware`. Installation unter `sbin/`, Handbuchabschnitt 8 (`man -M /usr/freeware/man 8 quota-set`). `quota-status` prüft den Aktivierungszustand unter Linux; `quota-report` liest die bestehenden Quota-Einträge. Das Betriebssystempaket für Quotas wird durch die Installation nicht nachinstalliert.
