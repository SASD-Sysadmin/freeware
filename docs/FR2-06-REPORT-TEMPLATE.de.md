# FR2-06 – Vorlage für eine manuelle Release-Abnahme (Deutsch)

[English](FR2-06-REPORT-TEMPLATE.md) · [VM-Abnahmeplan](FR2-06-VM-ACCEPTANCE.de.md) · [Evidenzregister](RELEASE-EVIDENCE.de.md)

**Diese Datei ist eine Vorlage, kein Testprotokoll und keine Freigabe.** Eine ausgefüllte Kopie **außerhalb des öffentlichen Git-Repositories** aufbewahren, solange darin Hostnamen, Benutzer, Speicherpfade oder andere schutzbedürftige Daten stehen.

## Identifikation

| Feld | Eintragung |
| --- | --- |
| Gate-ID (`staged-upgrade` / `privileged-vm` / andere) | NICHT AUSGEFÜHRT |
| Repository / Branch / vollständiger Commit-SHA | NICHT ERFASST |
| Release-Kandidat, Tag, Lizenz-Track (MIT-Beta / AGPL-Produkt) | NICHT FESTGELEGT |
| Testdatum / Zeitzone / Prüfer / unabhängig abnehmende Person | NICHT ERFASST |
| Debian-Version / Kernel / Perl / native Tools | NICHT ERFASST |
| VM-UUID / Testnetz / Mounts / Disk-Format / Backup-ID | NUR PRIVATES PROTOKOLL |
| Restore-Verfahren vorab erprobt? | BLOCKED |
| Einzelgenehmigung für `--apply --confirm-apply` erteilt? | NEIN |
| Rohlogs, Prüfsummen, Quellen und Zugriffsrechte | NICHT ERFASST |

## Prüfmatrix

| ID | Erwartung und unabhängiger Nachweis | Tatsächlich / Exit-Code / Log-Hash | Status |
| --- | --- | --- | --- |
| ST-01 | Fresh-Install in Wegwerf-DESTDIR; Lizenz im Manifest | — | NOT RUN |
| ST-02 | Repeat-Install ohne unerwartete Änderung | — | NOT RUN |
| ST-03 | Fremde Zieldatei blockiert; unverändert | — | NOT RUN |
| ST-04 | Upgrade ausschließlich der Wegwerf-Quelle | — | NOT RUN |
| ST-05 | Modifizierte verwaltete Datei blockiert Uninstall | — | NOT RUN |
| ST-06 | Transaktionsmarker blockiert weitere Operation | — | NOT RUN |
| ST-07 | Uninstall entfernt nur eigene Dateien; Lock und fremde Daten bleiben | — | NOT RUN |
| VM-01 | Test-VM/Netz eindeutig isoliert, alle Disks und NVRAM erfasst | — | BLOCKED |
| VM-02 | Gast- und Quota-Mount-Basiszustand unabhängig gesichert | — | BLOCKED |
| VM-03 | Konto-Vorschau ohne Schreibwirkung | — | NOT RUN |
| VM-04 | Quota-Vorschau ohne Schreibwirkung | — | NOT RUN |
| VM-05 | Gesondert genehmigtes Konto-Apply und unabhängige Verifikation | — | BLOCKED |
| VM-06 | Gesondert genehmigtes Quota-Apply auf separater Gast-Disk | — | BLOCKED |
| VM-07 | Sicher verweigerte Negativfälle, keine Nebenwirkung | — | NOT RUN |
| VM-08 | Vollständiger Snapshot-/Backup-Restore unabhängig geprüft | — | BLOCKED |

**Status nur:** `PASS`, `FAIL`, `SKIP`, `BLOCKED`, `NOT RUN`. `SKIP`/`BLOCKED` sind niemals `PASS`. Leere Tabellen sind keine Nachweise. Testausgaben mit persönlichem Inhalt vor öffentlicher Dokumentation anonymisieren.

## Nachweis-/Abweichungsregister

| Prüf-ID | Erwarteter Code | Beobachteter Code | Quelle / SHA-256 | Abweichung und Konsequenz |
| --- | --- | --- | --- | --- |
| — | — | — | — | Noch keine Ausführung |

## Rücksetzung und Freigabe

- Wiederherstellungs-Sollzustand: **NICHT FESTGELEGT**
- Tatsächlich wiederhergestellte Disk-/NVRAM-/Account-/Quota-Zustände: **NICHT GEPRÜFT**
- Unabhängiger Vergleich zur Baseline: **NICHT GEPRÜFT**
- Sicherheitsrisiken / Restabweichungen / Regressionen: **OFFEN**
- Benannte verantwortliche Prüfstelle und Entscheidung: **NICHT FREIGEGEBEN**
- Entscheidung zum Gate: **OFFEN**
- Gesamtrelease: **NICHT FREIGEGEBEN**

**Lizenzentscheidung ist bereits getroffen:** MIT für `SASD-SysAdmin/freeware`, AGPL-3.0-only für eine spätere, getrennte `SASDGMBH`-Fassung. Die Rechts- und NOTICE-Freigabe gehört weiterhin zum Unternehmensrelease.
