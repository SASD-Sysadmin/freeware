# linux-container-evidence-audit – M8.5.3a

[English](linux-container-evidence-audit.md) · [Container-Runner](linux-container-acceptance.de.md) · [Abnahmeprotokoll](linux-container-acceptance-protocol.de.md)

## Aufgabe

`linux-container-evidence-audit` wertet **ausschließlich lokal und lesend**
JSONL-Berichte von `linux-container-acceptance --format jsonl` aus. Das
Werkzeug fasst Debian, Ubuntu, Arch Linux, AlmaLinux und Rocky Linux in einem
fest definierten Bericht zusammen. Es startet weder Docker/Podman noch lädt
es Images herunter. Die Berichte werden bewusst separat erstellt.

Eine Distribution erhält nur dann `PASS`, wenn alle fünf Prüfungen
(`IDENTITY`, `TOOLCHAIN`, `TEST`, `INSTALL`, `SMOKE`) in einem tatsächlichen
`CONTAINER`-Lauf bestanden wurden. Fehlende Ziele erscheinen explizit als
`SKIP/NO_REPORT`; mindestens eine fehlgeschlagene Prüfung ergibt `FAIL`.

## Bedienung

```sh
# Ohne Eingaben: fünf sichtbare SKIP/NO_REPORT-Zeilen.
bin/linux-container-evidence-audit

# Ein Bericht pro Ziel, zuvor mit dem vorhandenen Container-Runner erzeugt.
# Die tatsächlich geprüften Images müssen lokal liegen und mit Digest
# festgelegt sein; Platzhalter sind KEINE nutzbaren Images.
bin/linux-container-acceptance --run --engine podman \
  --target debian --image 'debian=registry.example/debian@sha256:REPLACE_WITH_64_HEX' \
  --format jsonl > /tmp/sasd-debian.jsonl

# Nachdem die fünf Berichte vorliegen:
bin/linux-container-evidence-audit \
  --input /tmp/sasd-debian.jsonl \
  --input /tmp/sasd-ubuntu.jsonl \
  --input /tmp/sasd-arch.jsonl \
  --input /tmp/sasd-almalinux.jsonl \
  --input /tmp/sasd-rocky.jsonl \
  --require-complete --format jsonl
```

Jede `--input`-Datei muss regulär (kein Symlink) und höchstens 32 KiB groß
sein. Maximal fünf Eingabedateien sind zulässig. Ein Bericht muss genau fünf
kanonische JSON-Zeilen mit eindeutigen Prüfphasen und demselben Ziel sowie
Modus enthalten. Zusätzliche Felder, doppelte Phasen, fehlende Einträge,
inkonsistente Vorgängerprüfungen und nichtkanonische JSON-Darstellungen
führen zur Ablehnung. Potenziell vertrauliche Dateinamen gelangen nicht in
die Ausgabe.

## Bericht und Rückgabewerte

TSV-Spalten: `TARGET MODE STATUS PASS FAIL SKIP REASON`.
JSONL-Schema: `sasd.container-evidence.v1`.
Gründe: `ALL_STAGES_PASS`, `STAGE_FAILED`, `INCOMPLETE`, `NO_REPORT`.

- `0`: Gültige Berichte ohne `FAIL`. Ohne `--require-complete` dürfen
  `SKIP`-Befunde enthalten sein.
- `1`: Mindestens eine tatsächliche Prüfung ist fehlgeschlagen.
- `4`: Mit `--require-complete` fehlen erforderliche Abnahmen.
- Sonstiger Fehlercode: Ungültige Argumente oder fehlerhafte Nachweise.

## Aussagegrenzen

**JSONL ist kein signierter Nachweis.** Das Programm prüft Format und
Widerspruchsfreiheit, aber nicht die Authentizität der Image-, Host- oder
Git-Identität. Bitte Git-Commit, geprüfte Image-Digests, Engine-Version und
Originalberichte separat dokumentieren. Auch fünf bestandene Container-
Abnahmen beweisen **keine** native systemd-, Firewall-, SELinux-, AppArmor-,
Kernel- oder VM-Kompatibilität. Diese Prüfungen bleiben gesondert erforderlich.
