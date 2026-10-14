# Privilegierte Operationen: Sicherheitsgrenzen und VM-Testplan

[English](PRIVILEGED-SAFETY.md) · [Tests](TESTING.de.md) · [Sicherheitsrichtlinie](../SECURITY.md) · [Roadmap](ROADMAP.de.md)

## Umfang und Bedrohungsmodell

SASD Freeware unterscheidet **lesende Prüfungen**, **lokale Schreibvorgänge**
und **privilegierte Systemänderungen**. Ein Kommando ist keine Berechtigung,
einen Host zu verändern. Insbesondere dürfen Agenten, CI-Jobs oder
Administratoren eine erfolgreiche Vorschau nicht als Freigabe für `--apply`
interpretieren.

| Werkzeug | Mögliche Änderung | Standard/Schutzmechanismus | Verbleibendes Risiko |
| --- | --- | --- | --- |
| `account-manage` | Linux-Benutzer, Gruppen, Passwortsperren | Vorschau; `--apply --confirm-apply`; lokale Identitätsprüfung; Root und vertrauenswürdige native Programme | Verhalten des Backends, NSS-Änderungen während der Ausführung, bestehende Sitzungen/SSH-Schlüssel |
| `quota-set` | Benutzer-/Gruppenquotas | Vorschau; zweifache Bestätigung; zusätzlich `--allow-unlimited` bei Nullwerten; Prüfung von Mountpunkt und Grenzen | Quota-Verfügbarkeit, Dateisystemsemantik, parallele Änderungen |
| `rotate` | Nummerierte lokale Dateisicherungen | Kopie vor Rotation; Abweisung von Symlinks; kooperatives Verzeichnisschloss | **Nicht transaktional:** Fehler beim späteren Umbenennen/Löschen können einen teilweise rotierten Stand hinterlassen; kein externes Backup |
| `file-integrity --init` | Neues SHA-256-Baseline-Manifest | Manifest außerhalb des Prüfpads; private temporäre Datei; atomare Veröffentlichung ohne Überschreiben | Veränderungen während des Scans, Hardlink-Unterstützung, nicht vertrauenswürdige Verzeichnisse; keine Authentizitätsgarantie |

Für die Veröffentlichung einer Integritäts-Baseline muss das Dateisystem
Hardlinks innerhalb des Manifest-Verzeichnisses unterstützen. Fehler werden
gemeldet; vorhandene Manifeste werden nicht ersetzt. Nach erzwungenem Abbruch
(z. B. SIGKILL) kann eine private temporäre Datei `.sasd-integrity-*`
zurückbleiben. Sie ist **kein** veröffentlichtes Manifest und kann nach
Prüfung entfernt werden.

## Sichere automatisierte Tests (auch GitHub Actions)

`make test` führt reproduzierbare Tests mit isolierten Testdaten aus;
`make shellcheck` prüft Bash-Dateien statisch. Geprüft werden Bestätigungs-
und Ablehnungspfade, das Nichtaufrufen simulierter Backends, der Schutz
bestehender Integritäts-Manifeste, Symlinks, Kopierfehler sowie konkurrierende
Rotationsversuche.

- `tests/test_privileged_safety.t` verwendet ein temporäres Verzeichnis und
  simulierte Systemprogramme. **Vollständig bestätigte Aufrufe zur Änderung
  von Konten oder Quotas finden hier niemals statt**, auch nicht als Root.
- `tests/test_rotate_safety.sh` verwendet ausschließlich Wegwerf-Dateien;
  ein simuliertes `cp` erzwingt Fehler und hält einen Lock während eines
  parallelen Versuchs.
- `file-integrity` prüft ein Wegwerf-Verzeichnis mit separatem Manifest;
  `--check` verändert die Baseline nicht.

Diese Tests dürfen keine echten Konten anlegen, `/etc` verändern, Quotas
aktivieren oder privilegierte Backends ausführen. **Kein pauschales `sudo`
für die Testsuiten hinzufügen.**

## Manuelles Linux-VM-Labor — Voraussetzung für echte Apply-Freigabe

Dies ist ein **Testplan**, keine Aufforderung, privilegierte Änderungen auf
Deinem Arbeitsplatz, unter WSL oder auf einem produktiven System auszuführen.

1. Eine isolierte, wegwerfbare Linux-VM mit überprüfbarem Snapshot oder
   Sicherung anlegen. Keine realen Zugangsdaten oder produktiven Daten
   verwenden. OS, Kernel, Dateisystem, Repository-Revision und den
   Ausgangszustand von Konten und Quotas dokumentieren.
2. Native Kommandos und Rechte vorab prüfen. Eindeutige Testkonten und
   -gruppen sowie ein eigenes quota-fähiges Testdateisystem auswählen.
   Zuerst die normalen Vorschauen inklusive Exit-Code, stdout/stderr und
   geplanten Backend-Aufruf dokumentieren.
3. **Nur innerhalb dieser VM und nach gesonderter menschlicher Freigabe**
   jeweils eine `account-manage`-Aktion mit beiden Bestätigungsschaltern
   ausführen. Ergebnis unabhängig gegen Konten-/Gruppendatenbank sowie
   Home-Verzeichnisse und bestehende Sitzungen prüfen. Passwortsperre
   beendet weder SSH-Key-Zugänge noch laufende Sitzungen.
4. Für das isolierte Quota-Testdateisystem Zustand und Grenzen unabhängig
   erfassen; danach eine ausdrücklich bestätigte `quota-set`-Änderung
   durchführen und mit nativen Quota-Werkzeugen nachprüfen. Auch ungültige
   und unbegrenzte Werte testen. **Nicht** das Root-Dateisystem benutzen.
5. Backend-Fehler und fehlende Voraussetzungen simulieren, Rückgabewerte
   und Diagnosen aufzeichnen. Späte Fehler bei `rotate` getrennt prüfen:
   Das Werkzeug besitzt keine transaktionale Wiederherstellung der Historie.
6. Snapshot zurückspielen und Konten, `/etc`-Metadaten, Mounts, Quotas
   sowie Testdateien mit dem dokumentierten Ausgangszustand vergleichen.
   Bei nicht wiederherstellbarem Zustand keine Freigabe erteilen.

Der Laborbericht enthält Revision, Freigabe durch den Operator, Vorher-/
Nachher-Nachweise, erwartete und tatsächliche Rückgabewerte, Abweichungen
und das Ergebnis der Snapshot-Wiederherstellung. **Grüne CI allein ersetzt
keine Abnahme mit einer isolierten VM.**
