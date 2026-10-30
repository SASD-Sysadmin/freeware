# `file-integrity` — SHA-256-Inhaltsprüfsummen und Vergleichsbasis

**Deutsch** · [English](file-integrity.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/file-integrity.1) · [Quellcode](../../bin/file-integrity)

## Zweck und Einsatzbereich

Bildet rekursiv SHA-256-Werte regulärer Dateien unter `--root DIR`. `--init` **schreibt** eine neue JSON-Basisliste außerhalb des Baums; `--check` (Standard) meldet `ADDED`, `CHANGED` und `MISSING`. **Kein** Backup, Signaturprüfer, Virenscanner oder vollständiges Dateiintegritätsmonitoring.

## Verhalten und geprüfte Eigenschaften

Root muss ein echtes Verzeichnis sein (direkt angegebene Root-Symlinks werden abgewiesen), und Symlinks werden nicht verfolgt. Das Manifest liegt außerhalb des überwachten Baums und darf selbst kein Symlink sein. Es enthält `sasd-integrity-v1`, den aufgelösten absoluten Root-Pfad und relative Namen mit SHA-256-Werten; derselbe Root-Pfad ist für spätere Prüfungen erforderlich. Eigentümer, Rechte, ACLs, Xattrs, Zeitstempel, Sicherheitslabels und Symlink-Ziele werden nicht gehasht. Gleichzeitige Änderungen können inkonsistente Ergebnisse verursachen.

## Aufruf und Optionen

```text
file-integrity --help
```

| Option | Bedeutung |
| --- | --- |
| `--root DIR` | Zu untersuchendes Verzeichnis (erforderlich). |
| `--manifest FILE` | JSON-Basisliste außerhalb des Baums; Elternverzeichnis muss existieren. |
| `--init` | **Neue** Basisliste erzeugen; vorhandenes Manifest niemals überschreiben. |
| `--check` | Lesender Vergleich (Standard). |
| `--help`, `--version` | Metadaten ohne Scan. |

## Praktisches Beispiel

```sh
lab="$(mktemp -d)"
mkdir "$lab/tree" "$lab/baselines"
printf 'version=1\n' > "$lab/tree/test.conf"
./bin/file-integrity --root "$lab/tree" \
  --manifest "$lab/baselines/tree.json" --init
./bin/file-integrity --root "$lab/tree" \
  --manifest "$lab/baselines/tree.json" --check
printf 'version=2\n' > "$lab/tree/test.conf"
./bin/file-integrity --root "$lab/tree" \
  --manifest "$lab/baselines/tree.json" --check
# Wegwerfverzeichnis $lab bei Bedarf nach Prüfung selbst entfernen.
```

Der erste Vergleich liefert 0, die bewusste Änderung ergibt `CHANGED` und Exitcode 1. `--init` niemals automatisch vor jedem Vergleich erneut ausführen: Das würde die Bedeutung einer vertrauenswürdigen Referenz unterlaufen; ein vorhandenes Manifest wird ohnehin nicht überschrieben.

## Ausgabe und Rückgabewerte

Bei Initialisierung: `BASELINE: files=N manifest=...`. Beim Vergleich: `ADDED:`, `CHANGED:`, `MISSING:` und `SUMMARY: files=N changed=N added=N missing=N`. Die Pfade sind kein NUL-getrenntes Maschinenformat.

`0` = Basiserstellung oder keine Inhaltsabweichung; `1` = Inhalt abgeändert/hinzugefügt/fehlend; `2` = Aufruffehler; andere Codes ungleich 0 = Datei-, JSON-, Manifest- oder Veröffentlichungsfehler. **Gleiche Prüfsummen beweisen keine Systemsicherheit.**

## Grenzen, Sicherheit und Portabilität

`--init` schreibt zunächst eine private temporäre Datei und veröffentlicht sie mit einem atomaren, vor Überschreiben geschützten Hardlink (Hardlink-Unterstützung im Manifestverzeichnis erforderlich). Ein harter Abbruch kann `.sasd-integrity-*` zur manuellen Untersuchung hinterlassen. Vertrauen setzt einen unabhängig geschützten Baseline-Speicher voraus; wer Dateien und Manifest ändern kann, kann Manipulationen verbergen. Snapshots, Sperrkonzept, ACL-/Metadatenprüfung und native Dateisystemabnahme gehören nicht dazu.

## Weiterführende Informationen

[Privilegierte Sicherheitsgrenzen](../PRIVILEGED-SAFETY.de.md) · [Sicherheit](../../SECURITY.md) · [Sammelanleitung](automation-tools.de.md)
