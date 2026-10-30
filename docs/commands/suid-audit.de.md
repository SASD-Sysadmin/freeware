# `suid-audit` — Lesendes Inventar von SUID-/SGID-Dateien

**Deutsch** · [English](suid-audit.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/suid-audit.1) · [Quellcode](../../bin/suid-audit)

## Zweck und Einsatzbereich

Listet reguläre Dateien mit Set-User-ID- (SUID-) oder Set-Group-ID-Bit (SGID) samt oktalem Modus, numerischer UID/GID und Pfad auf. Dateien werden **nicht ausgeführt oder verändert**, und Treffer sind kein automatischer Nachweis einer Schwachstelle.

## Verhalten und geprüfte Eigenschaften

Erfordert ein vorhandenes echtes Root-Verzeichnis, kein Root-Symlink. `File::Find` folgt keinen symbolischen Links; verlinkte oder besondere Dateitypen werden ausgelassen. Dateisystemgrenzen sind nicht festgelegt. SUID/SGID sind nur Berechtigungsbits; die tatsächliche Kernel-Wirkung etwa bei `nosuid` wird nicht geprüft. Pfade werden wörtlich, nicht NUL-getrennt ausgegeben.

## Aufruf und Optionen

```text
suid-audit --help
```

| Option | Bedeutung |
| --- | --- |
| `--root DIRECTORY` | Erforderliches Verzeichnis für rekursiven Scan. |
| `--help` | Hilfe ohne Dateiscan. |
| `--version` | `suid-audit 0.1.0` anzeigen. |

## Praktisches Beispiel

```sh
# Ein Verzeichnis mit Systemprogrammen nur inventarisieren.
./bin/suid-audit --root /usr/bin
# Oder die Suche einschränken.
./bin/suid-audit --root /usr/local/bin
```

Gefundene Programme werden nicht ausgeführt. Für Tests genügen isolierte Testdateien; es muss kein tatsächlich privilegiert ausführbares Programm angelegt werden.

## Ausgabe und Rückgabewerte

Ein Eintrag je Treffer, beispielsweise `SUID mode=4755 uid=0 gid=0 /pfad` oder `SUID+SGID ...`, danach `SUMMARY: scanned=N privileged=N errors=N`.

`0` = erfolgreiches Inventar, **auch bei SUID-/SGID-Treffern**; `2` = Aufruffehler oder erfasster `stat`-Fehler; andere Codes ungleich 0 = ungültiges Verzeichnis oder Laufzeitfehler. Statt Exit 0 als „keine Treffer“ zu deuten, `privileged=` auswerten.

## Grenzen, Sicherheit und Portabilität

Keine Prüfung von Linux-Capabilities, `nosuid`-Mounts, ACLs, SELinux/AppArmor, Paketherkunft, Eigentumsvertrauen oder CVEs. Parallele Änderungen und fehlende Rechte können Ergebnisse unvollständig machen; kein atomarer Snapshot. Treffer mit einer vertrauenswürdigen Betriebssystem-Basisliste vergleichen, statt sie pauschal als Schwachstelle zu behandeln.

## Weiterführende Informationen

[Sicherheit](../../SECURITY.md) · [Privilegierte Sicherheitsgrenzen](../PRIVILEGED-SAFETY.de.md) · [Sammelanleitung](automation-tools.de.md)
