# SASD Freeware – Systematische Release-Gap-Analyse

[English](RELEASE-GAPS.md) · [Release-Verfahren](RELEASE-ENGINEERING.de.md) · [Roadmap](ROADMAP.de.md) · [Plattformen](PLATFORMS.de.md)

**Bestandsaufnahme:** 29.10.2026, `main`-Commit `ae1571d98fc904cdbfebd1daa2ef9471bc62174f`.
Diese Analyse beschreibt den Stand **vor einer offiziellen Freigabe**. Ein grüner
CI-Lauf ist ein technischer Nachweis, aber keine Freigabeentscheidung. Sie ersetzt
weder eine Sicherheitsprüfung noch eine native Plattform- oder VM-Abnahme.

## 1. Zählbarer Repository-Bestand

| Merkmal | Nachweis am oben genannten Commit | Bedeutung |
| --- | --- | --- |
| Kommandos | 52 unter `bin/`, 2 unter `sbin/` | 54 eigenständige Programme |
| Handbuchseiten | 52 unter `man/man1/`, 2 unter `man/man8/` | Zu jedem Kommando ist eine Manpage vorhanden |
| Eigene Perl-Module | 15 unter `lib/SASD/Freeware/` | Wiederverwendbare Implementierungen |
| Offline-Tests | 43 `tests/*.t`, 2 `tests/test_*.sh` | Umfangreich, jedoch nicht gleich native Abnahme |
| CI | Ubuntu und macOS, letzter verifizierter Main-Lauf `40838884447`: erfolgreich | Nur geprüfte Plattformen und Testfälle |
| GitHub-Veröffentlichung | Kein offizielles GitHub Release beim Audit gefunden | Noch keine Produktfreigabe |
| Einzeldokumentation | 47/54 Kommandos mit gleichnamigem DE-/EN-Leitfaden | Sieben Einzelanleitungen fehlen; Sammeldokumente können Teilabdeckung leisten |

Die sieben Kommandos ohne **eigenen** DE-/EN-Leitfaden sind `account-audit`,
`file-integrity`, `hosts-lint`, `log-summary`, `ssh-key-audit`, `suid-audit`
und `tcp-check`. Das bedeutet nicht automatisch, dass sie undokumentiert sind:
verschiedene Funktionen werden bereits in Sammelanleitungen erklärt. Für eine
nachvollziehbare Release-Inventur empfehlen sich dennoch direkte Leitfäden.

## 2. Freigabelücken nach Priorität

Die Prioritäten beziehen sich auf eine **erste explizit begrenzte Freigabe**,
nicht auf den Anspruch, alle denkbaren Unix-/Linux-Plattformen vollumfänglich
zu unterstützen. P0 muss vor der Freigabe geschlossen oder durch einen formal
abgesicherten Ausschluss aus dem Releaseumfang entschieden werden. P1 kann bei
entsprechend klaren Plattform-/Funktionsgrenzen zum Teil später bearbeitet
werden. P2 ist weitere Produktentwicklung.

| ID | Prio | Aktueller Status | Lücke und Nachweis für die Schließung |
| --- | --- | --- | --- |
| RG-01 | P0 | Offen | Privilegierte Linux-VM-Abnahme von `account-manage` und `quota-set`, inklusive Vorschau, gesonderter Bedienerfreigabe, unabhängiger Zustandsermittlung und erfolgreichem Snapshot-Rollback; siehe `PRIVILEGED-SAFETY.de.md` |
| RG-02 | P0 | Offen | Release-Tag/Versionsabgleich, Quellarchiv aus sauberem Checkout, SHA-256-Vergleich, Wiederholung aus Tag und nachvollziehbare Herkunft |
| RG-03 | P0 | Offen | Freigabeakte mit konkretem Commit, erfolgreichen CI-Jobs, verpflichtender DNS-/LDAPS-Integration, getesteten Installations-/Upgrade-/Uninstallpfaden, Abweichungen und Freigabeentscheidung |
| RG-04 | P0 | Offen | Risiken bei Installer-Abbruch, manipulierten Dateien, fremden Dateinamen und Wiederherstellung in Wegwerf-Staging sowie mit dokumentiertem Rückweg prüfen |
| RG-05 | P1 | Teilweise | Genaue Plattformmatrix und reale Native-Tests; Ubuntu/macOS-CI allein belegt weder fünf Linux-Distributionen noch BSD/Solaris oder einen funktionsfähigen privilegierten Backend-Einsatz |
| RG-06 | P1 | Teilweise | Realistische Systemtests für beanspruchte SQL-, Postfix-, LDAP-/NIS- und Firewall-Funktionen; Mock-/Loopback-Fixtures nicht als Produktionserfahrung darstellen |
| RG-07 | P1 | Offen | Sieben fehlende Einzelanleitungen oder dokumentierte, begründete Abweichung einschließlich direkter Verweise auf Sammelanleitungen |
| RG-08 | P1 | Behoben durch diese Änderung | Entwicklerdokumentation nicht mehr auf die historische Zahl von 30 Programmen festlegen |
| RG-09 | P1 | Zu prüfen | Abhängigkeiten/Versionen, Drittanbieter-Lizenzen, Sicherheitsmeldungsweg und Rechte-/Eigentumsgrenzen für tatsächlich ausgelieferte Programme gegenchecken |
| RG-10 | P2 | Laufend | Funktionale Lücken aus den Kapiteln 2–10 priorisiert nach administrativem Nutzen schließen; kein willkürlicher Blocker für einen bewusst kleineren Releaseumfang |

**Entscheidungsregel:** Es wird **keine** Freigabe allein aufgrund einer
statischen Toolausgabe, bestandener Unit-Tests oder eines Versionsstrings wie
`0.1.0` ausgesprochen. Unbekannte Ergebnisse bleiben ausdrücklich offen.

## 3. Reproduzierbare, rein lesende Inventur

Das Entwicklerwerkzeug `tools/release-gap-audit.pl` scannt Dateibestand und
Dokumentationsverknüpfungen. Es ist **kein installierbares SysAdmin-Kommando**,
führt keine enthaltenen Programme aus, benötigt keinen Root-Zugriff und baut
kein Release. Git, externe Netzwerke, Dienste und Container sind nicht nötig.

```sh
make release-gap-audit
perl tools/release-gap-audit.pl --root . > /tmp/sasd-release-gaps.tsv
perl tools/release-gap-audit.pl --strict --root .
```

Die TSV-Spalten sind `status`, `priority`, `category`, `item`, `detail`.
`PASS` bestätigt lediglich das jeweilige statische Artefakt. `GAP` bezeichnet
eine fehlende oder nicht reguläre Datei bzw. Verknüpfung. `MANUAL` ist ein
**offener externer Nachweis**, kein übersprungener Erfolg. `SUMMARY` enthält
die gezählten Statuswerte. Ohne `--strict` bedeutet Exit 0 nur, dass die
Inventur durchgeführt wurde. Mit `--strict` bedeutet Exit 1: Lücken oder
manuelle Nachweise sind noch offen. Es gibt **keine automatische Freigabe**.

Wichtig: Die gleichnamigen Einzelanleitungen sind ein streng definierter
Indikator und keine vollständige semantische Dokumentationsanalyse. Auch ein
vorhandenes Dokument kann unvollständig sein. Ebenso belegen vorhandene Tests
nicht, dass deren letzte Ausführung erfolgreich war.

## 4. Empfohlene nächste Arbeitsschritte

1. **M9.1 – Evidenzstruktur:** Ein schlichtes, versioniertes Abnahmeprotokoll mit
   Gate-ID, erwarteter Prüfung, Commit/Umgebung, Ergebnis, Link oder Hash zum
   Nachweis und verantwortlicher Freigabe definieren. Keine Zugangsdaten und
   keine produktiven Hostdaten veröffentlichen.
2. **M9.2 – Dokumentationsabgleich:** Fehlende Einzelanleitungen schließen,
   Versionen und Native-Abhängigkeiten prüfen, Plattformgrenzen aktualisieren.
3. **M9.3 – Sichere Integrations- und VM-Abnahme:** Den vorhandenen Prüfplan auf
   Wegwerf-VMs ausführen; reale privilegierte Aktionen nur nach separater,
   ausdrücklicher menschlicher Freigabe.
4. **M10 – Release-Kandidat:** Nach erfüllten P0-Gates einen reproduzierbaren
   Quellrelease-Kandidaten erstellen, unabhängig verifizieren und entscheiden.

Cron-Beispiele in den Anleitungen der einzelnen Werkzeuge sind hilfreiche
Nutzungshinweise; diese Release-Gap-Analyse führt **keinen** Scheduler,
Hintergrunddienst oder zentrale Betriebssteuerung ein.
