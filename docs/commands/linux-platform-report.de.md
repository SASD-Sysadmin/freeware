# `linux-platform-report` – vorsichtige Linux-Erkennung (M8.5.1)

## Zweck und Architektur

Das Programm liest die Linux-Distributionskennung aus `os-release(5)` und
erstellt einen **quellenbezogenen Bericht mit sieben Spalten**. Es ist die
Grundlage für die spätere distributionsspezifische M8.5-Abnahme, **kein** Beleg
für produktive Unterstützung, vorhandene Paketmanager, aktive Firewalls,
SELinux, AppArmor oder andere Eigenschaften.

Die Architektur trennt die Aufgaben ausdrücklich:

- `bin/linux-platform-report` liest begrenzte Eingaben und erzeugt die Ausgabe.
- `lib/SASD/Freeware/LinuxPlatform.pm` enthält nur Parser und konservative
  Familienzuordnung. Das Modul öffnet keine Dateien und führt nichts aus.

## Verwendung

```sh
bin/linux-platform-report
bin/linux-platform-report --input /tmp/os-release-kopie
bin/linux-platform-report --input - < /etc/os-release
bin/linux-platform-report --null
```

Native Abfrage nur unter Linux. `/etc/os-release` hat Vorrang vor
`/usr/lib/os-release`; der zweite Pfad wird ausschließlich verwendet, wenn
der erste **fehlt**. Es werden keine Inhalte aus beiden Dateien kombiniert.
Fest vorgegebene native Pfade dürfen System-Symlinks verwenden. Bei `--input`
werden dagegen Symlinks, Geräte und Pipes abgelehnt; `-` liest stdin.

Das Datenformat wird **niemals als Shellskript ausgeführt**. Fehlerhafte oder
nicht unterstützte Syntax beendet die Prüfung ohne Teilbericht.
Wiederholte Schlüssel werden nach der Regel „letzter Wert gewinnt“ gelesen.
Grenzen: 64 KiB pro Quelle, 4.096 Bytes je Zeile, höchstens 512 Zeilen.

## Ausgabeformat

Standardmäßig TSV mit Kopfzeile und einer Datenzeile; `--null` gibt sieben
NUL-terminierte Felder ohne Kopfzeile aus.

| Feld | Bedeutung |
| --- | --- |
| `SOURCE` | `ETC`, `USR_LIB` oder `INPUT` |
| `ID` | Tatsächliche Distributionskennung oder Standardwert `linux` |
| `ID_LIKE` | Geprüfte Hinweise auf verwandte Distributionen |
| `VERSION_ID` | Versionskennung oder `-` |
| `FAMILY` | Hinweise `debian`, `arch`, `rhel`, `suse`, `alpine` oder `unknown` |
| `EVIDENCE` | Direkte `ID`, abgeleitet aus `ID_LIKE`, oder `UNKNOWN` |
| `VERSION_MODE` | `VERSIONED`, `ROLLING` (nur Arch ohne VERSION_ID), sonst `UNKNOWN` |

`ID_LIKE` ist keine sichere Aussage zu Paketverwaltungswerkzeugen. Ebenso sagt
`ID=rocky` nichts darüber aus, ob SELinux oder firewalld tatsächlich installiert,
aktiv oder korrekt konfiguriert sind. Unvereinbare Familienhinweise führen
bewusst zu `unknown`.

## Sicherheit und Grenzen

Keine Root-Rechte, keine Änderungen und keine Ausführung von Shell-Anweisungen.
Keine ungeprüften individuellen Pfade oder `PRETTY_NAME`-Texte in der Ausgabe.
Fehlercodes: `0` vollständige Auswertung, `2` Parameterfehler, `3` unsichere,
unlesbare oder ungültige Quelle.

**Wichtig:** Die GitHub-CI mit Parser-Fixtures unter Ubuntu/macOS ist **keine**
native Abnahme auf Debian, Ubuntu, Arch, AlmaLinux und Rocky Linux. Diese
muss mit M8.5.2 bis M8.5.4 separat nachgeholt werden.

Siehe [Linux-Plattform-Abnahme](linux-platform-acceptance.de.md) und
[os-release(5)](https://www.freedesktop.org/software/systemd/man/latest/os-release.html).
