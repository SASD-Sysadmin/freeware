# SASD Freeware – Installation, Upgrades und Release-Abnahme

## Stand und Geltungsbereich

Diese Anleitung beschreibt den **Quellcode-Installer** ab M3. `v0.1.0` ist erst
nach erfolgreicher Freigabe ein Release; der Versionsstring der Programme ist
kein Nachweis einer bereits erfolgten Veröffentlichung. Die Tests unter Ubuntu
und macOS ersetzen keine reale privilegierte Sicherheitsabnahme in einer VM.

## Staging vor Installation

```sh
make test
make shellcheck             # auf Ubuntu bzw. mit installiertem ShellCheck
staging=$(mktemp -d)
make install DESTDIR="$staging" PREFIX=/usr/freeware
cat "$staging/usr/freeware/.sasd-freeware-install.tsv"
make uninstall DESTDIR="$staging" PREFIX=/usr/freeware
```

Für einen echten Host wird `DESTDIR` weggelassen und bei Bedarf mit den dafür
vorgesehenen Rechten ausgeführt. `PREFIX` muss ein absoluter Pfad ungleich `/`
sein. `DESTDIR` ist optional, ebenfalls absolut. Pfadkomponenten `.` und `..`
sowie symbolische Links in der Zielverzeichniskette werden grundsätzlich
abgelehnt. Ausgenommen sind ausschließlich die fest definierten, geprüften
macOS-Systemalias-Pfade `/var`, `/tmp` und `/etc` nach `/private/...`;
selbst angelegte Symlinks im Installationspfad bleiben verboten.

## Eigentum und Schutz

Die Datei `PREFIX/.sasd-freeware-install.tsv` listet jede installierte Datei
und ihren SHA-256-Inhaltswert. Sie wird **zuletzt** veröffentlicht. Bei einem
erneuten `make install` werden nur zuvor nachweislich installierte Dateien
ersetzt; inzwischen nicht mehr ausgelieferte Dateien werden entfernt.

Abbruch *vor* Änderungen, falls:

- ein zuvor installiertes Objekt fehlt oder inhaltlich verändert wurde;
- ein neuer Dateiname bereits von jemand anderem verwendet wird;
- ein gefährlicher oder symbolischer Pfad, ein fremder Dateityp oder ein
  manipuliertes Manifest festgestellt wird;
- kein Manifest vorhanden ist und bereits Zieldateien im Weg stehen.

`make uninstall` benötigt das Manifest und löscht ausschließlich unveränderte,
darin genannte Dateien. Unbekannte Dateien und Verzeichnisse bleiben erhalten.
Bewusst geänderte Installationsdateien müssen **manuell geprüft** werden;
es gibt keinen automatischen `--force`-Schalter.

Ein vorhandener älterer SASD-Installationsstand *ohne* Manifest kann **nicht
ungeprüft übernommen** werden: Sicherung und Dateiliste vergleichen, alten
Stand kontrolliert migrieren und erst dann das neue Installationsverfahren
verwenden. Auf keinen Fall eine alte quellcodebasierte `uninstall`-Routine
blind auf produktive Verzeichnisse loslassen.

## Fehler, Abbruch und Rollback

Der Installer kopiert die neue Nutzlast in ein temporäres Verzeichnis innerhalb
des Zielpräfixes. Bei einem regulär erkannten Fehler wird versucht, die zuvor
installierten Dateien aus temporären Backups wiederherzustellen. Dies ist
**keine vollständig transaktionale Installation**: Stromausfall, `SIGKILL`,
platzbedingte Dateisystemfehler und parallele externe Änderungen erfordern
unter Umständen eine manuelle Reparatur. Erhaltene Verzeichnisse mit Namen
`.sasd-freeware-txn-*` signalisieren einen unterbrochenen Vorgang. Nicht blind
löschen: darin können alte Installationsdateien liegen. Zuerst den Zustand und
die Sicherungen prüfen und gegebenenfalls den VM-Snapshot wiederherstellen.

## Freigabe-Checkliste

1. Für einen reproduzierbaren Commit oder Tag eine saubere Git-Arbeitskopie
   verwenden; Versionsnummern und `CHANGELOG.md` abstimmen.
2. `make test`, `make shellcheck`, verpflichtende DNS-/LDAPS-Integration und
   Linux-/macOS-CI ohne ungeklärte Fehler prüfen.
3. Frische Installation, wiederholte Installation, Upgrade mit entfernten
   Programmen, Uninstall und Konfliktverhalten in Wegwerf-Staging testen.
4. Die separate privilegierte Linux-VM-Abnahme gemäß
   [PRIVILEGED-SAFETY.de.md](PRIVILEGED-SAFETY.de.md) durchführen.
5. Release-Archiv und SHA-256-Prüfsumme dokumentieren; Ergebnis aus einem
   unveränderten Tag erneut herstellen und gegentesten.
6. Erst danach ein GitHub-Release veröffentlichen; Version, Plattformgrenzen,
   bekannte Risiken und Rückweg ausdrücklich angeben.
