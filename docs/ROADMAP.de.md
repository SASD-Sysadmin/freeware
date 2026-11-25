# SASD Freeware – Entwicklungsroadmap

[English](ROADMAP.md) · [Projekt](../README.de.md) · [Agentenregeln](../AGENTS.md) · [Release-Lücken](RELEASE-GAPS.de.md) · [Release-Verfahren](RELEASE-ENGINEERING.de.md)

**Aktuelle Produktplanung: 16. November 2026.** Dies ist die einzige maßgebliche deutschsprachige Roadmap. Sie führt `ROADMAP.de.md` und `ROADMAP-CONTINUATION-2.de.md` zusammen und erhält die datierten Nachweise und historischen Bewertungen weiter unten. Das historische Fachbuch ist **kein** verbindlicher Produktanforderungskatalog und keine Voraussetzung für eine Veröffentlichung.

**Verifizierter Ausgangsstand:** `main` bei `606b820b67c08b757339ebcf84b3426fc5eb217d`, [erfolgreicher Ubuntu-/macOS-CI-Lauf 43820682925](https://github.com/SASD-Sysadmin/freeware/actions/runs/43820682925). Das ist eine datierte Beobachtung, keine Aussage über spätere Commits. Dieses Dokument autorisiert oder verkündet keine Veröffentlichung.

## 1. Produktleitbild und Entscheidungsmaßstäbe

SASD Freeware ist eine langfristig wartbare, MIT-lizenzierte Sammlung unabhängig nutzbarer Linux-/Unix-Administrationswerkzeuge. Jedes Werkzeug soll ein praktisches Administrationsproblem lösen, in Unix-Arbeitsabläufe passen, sichere Standards besitzen und einen klar überprüfbaren Vertrag anbieten. Perl wird für umfangreichere Verarbeitung und Administration bevorzugt, Shell dort, wo sie sinnvoll ist. Weder ein Pflicht-Framework noch ein ständig laufender Dienst ist Produktziel.

Arbeitspakete werden nach **Administrationsnutzen, Fehlerrisiko, Sicherheit, reproduzierbaren Tests und Release-Umfang** ausgewählt – nicht nach der Anzahl nachgebildeter Buchkapitel. David N. Blank-Edelmans *Perl for System Administration* (2000) bleibt historische Anregung und optionaler Forschungsgegenstand. Seine Beispiele und die zweite Auflage sind keine stillschweigenden Implementierungspflichten. Historische Kennungen `M*` und `FR2-*` bleiben zur Nachvollziehbarkeit erhalten.

Maßgeblich für implementiertes Verhalten sind Code und aktuelle Tests. Zwischen implementiert, Fixture-geprüft, nativ getestet, abgenommen und veröffentlicht ist zu unterscheiden. Grüne CI beweist weder eine privilegierte VM-Abnahme noch vollständige Plattformunterstützung oder Release-Freigabe. Die zehn RG-Lücken in [RELEASE-GAPS.de.md](RELEASE-GAPS.de.md) behalten ihre Definitionen. Widerspricht eine ältere Aussage dem verifizierten Stand oder dieser Produktausrichtung, darf sie nicht stillschweigend als aktuelle Pflicht verwendet werden.

## 2. Aktuelle priorisierte Arbeitspakete

| Reihenfolge | Bestehende Kennung | Priorität | Liefergegenstand und Grenze |
| --- | --- | --- | --- |
| **1** | **FR2-03 / FR2-F01 / RG-04** | P0 Sicherheit | Isolierte Regression für einen nach Löschfehler teilweisen Uninstall; sichere Wiederholung/Recovery vertraglich festlegen und Manifest, Lock, fremde/veränderte Dateien und Nachweiserhalt prüfen. Fault-Injection ist keine native Crash-Abnahme. |
| **2** | **FR2-02 / FR2-F02** | P0 Kompatibilität | Tatsächliche Mindestversionen für Perl/Module/Clients bestimmen und testen; DE/EN-Dokumentation korrigieren, nicht Perl 5.8 ungeprüft behaupten. |
| **3** | **FR2-04 / FR2-F04–F05 / RG-09** | P0 Herkunft | Ausgelieferte Lizenzhinweise, tatsächliche Drittübernahmen und Nutzungsrechte prüfen. Änderungen am Installationsumfang brauchen Upgrade-/Uninstall-/Konflikttests. |
| **4** | **FR2-05 / RG-03** | P0 Evidenz | Reproduzierbare, SHA-bezogene Test-, CI-, Staging-, Native- und Betreiberbelege dokumentieren; `MANUAL`-Audit-Kategorien nicht als gescheiterte Tests umdeuten. |
| **5** | **FR2-06 / RG-01–RG-04** | P0 Releaseumfang | Freigabe für isolierte Snapshot-VM-Abnahmen zu Konten/Quotas und Installer-Recovery, dazu Archivherkunft und verantwortliche Freigabe für gewählten Scope getrennt einholen. |
| **Bei Bedarf** | **FR2-10–14, FR2-20–25** | P1/P2 | Hosts-/DNS-Generierung, lesendes LDAP/SNMP, administrativen Mailversand, zustandsbehaftete Logs, SQL/Storage, native Adapter und andere Erweiterungen einzeln nach echtem Admin-Bedarf bewerten; je Slice Scope und Tests definieren. |
| **Optionale Forschung** | **FR2-01 / FR2-30** | P3 | Buch-Unterabschnittsmatrix und historische Protokolle nur bei ausdrücklichem Auftrag; kein Releaseblocker für das eigenständige SASD Freeware. |

**Historisch nächster technischer Slice (Stand 16. November 2026):** FR2-03 mit deterministischer Reproduktion außerhalb produktiver Systeme, begründeter Recovery-Architektur und fokussierten positiven/negativen Regressionen. Keine Kombination mit fachfremden Funktionen oder einer Veröffentlichung. Die Zusammenführung dieser Dokumentation schließt keine Release-Lücke.

**FR2-02-Nachtrag (21. November 2026):** Beim Betreiberlauf vom 18.11.2026 auf Quellstand `b1960f4` bestand die vollständige Debian-/WSL2-Offline-Suite mit Perl 5.14.4 (49 Perl-Testsuiten, 6.146 TAP-Fälle mit 10 SKIPs, zwei Bash-Testgruppen), ebenso die Quell-/CLI-Prüfung (74/53) und die statische Release-Inventur (`PASS=288, GAP=0, MANUAL=7`). Siehe [Perl-Kompatibilität](PERL-COMPATIBILITY.de.md). Die aktuelle README-Aussage zu 5.8 wurde korrigiert; eine allgemeine Mindestversion oder andere Release-Gates sind damit nicht nachgewiesen beziehungsweise abgeschlossen. Frühere datierte Roadmap-Befunde bleiben historisch erhalten.

**FR2-04-Vornachweis (22. November 2026):** Im historischen Prüfstand `15e4347` waren die MIT-SPDX-Kennzeichnungen der Programme und Tests konsistent; die damals fehlende Installationsbeilage `LICENSE` wurde mit `1f6f4f0` behoben und in der CI geprüft. Siehe [Lizenz- und Herkunftsprüfung](LICENSE-PROVENANCE.de.md). Dokument und Auditor ändern keine Lizenz und schließen RG-09 nicht. Die Lizenzbeilage-Regression ist umgesetzt und in der CI geprüft. Rechteprüfung und ausdrückliche spätere SASDGMBH-Lizenzentscheidung bleiben offen.

**FR2-04-Abschluss / FR2-05-Evidenznachtrag (23. November 2026):** Beide technischen FR2-04-Teilpakete sind committed und in Ubuntu-/macOS-CI erfolgreich: [Installer-LICENSE-CI `45128966544`](https://github.com/SASD-Sysadmin/freeware/actions/runs/45128966544) auf `1f6f4f0` und [Herkunftsdokumentations-CI `45131942704`](https://github.com/SASD-Sysadmin/freeware/actions/runs/45131942704) auf `686a86b`. Die **Lizenzwahl ist jetzt entschieden**: persönliche Beta **MIT**, getrennte spätere `SASDGMBH`-Fassung **AGPL-3.0-only**; siehe [Lizenzstrategie](LICENSE-STRATEGY.de.md). Das [FR2-05-Evidenzregister](RELEASE-EVIDENCE.de.md) trennt bestandene Nachweise, SKIPs und sieben weiterhin offene manuelle Release-Gates. Rechtekette und Fremdübernahmen bleiben zu prüfen; technischer Abschluss ist keine rechtliche Release-Freigabe.

**FR2-06a-Vorbereitung (23. November 2026):** [Unprivilegierte Staging-Prüfung und gesondert freizugebender Debian-KVM-Abnahmeplan](FR2-06-VM-ACCEPTANCE.de.md) legen Belege und Stop-Kriterien fest. Das Paket führt **keine** privilegierten Änderungen aus, bestätigt keinen Restore und schließt keine `MANUAL`-Release-Gates. Ausgangsstand: `f25aa3f`, CI [45139166377](https://github.com/SASD-SysAdmin/freeware/actions/runs/45139166377).

### 2.1 Anwendungsabstürze und Core-Dump-Analyse (25. November 2026)

**Strategische Entscheidung:** SASD Freeware erhält einen fokussierten, historisch inspirierten Unix-/Linux-Anwendungsdiagnosebereich. Für die SASD GmbH liegen die Ziele in reproduzierbarer Incident-Erstanalyse, Unterstützung älterer Anwendungen und nachweisgestützter Ursachenanalyse an der Schnittstelle von Administration und Softwareentwicklung. Dies ist vereinbarter Planungsumfang, kein Nachweis der Dienstleistungsreife und keine pauschale Implementierungsfreigabe. Bestehende P0-/FR2-Arbeiten (einschließlich FR2-06) und manuelle Release-Gates behalten Vorrang. Diese Erweiterung ist keine neue Voraussetzung für den bisherigen Releaseumfang.

**Vorhandener Ausgangspunkt:** Bei `ac71b19` inventarisiert [core-report](commands/core-report.de.md) reguläre Dateien namens `core` oder `core.*`, logische Größen und Summen unter einem angegebenen Verzeichnis. Das Programm nutzt lstat, überspringt Symlinks, unterstützt Dateisystemgrenzen und NUL-getrennte Ausgabe und validiert keine Dump-Inhalte. Offline-Testfälle stehen in `tests/test_filesystem_tools.t`. Dies ist eine Quellprüfung, kein neu ausgeführter Test. Dokumentierte Optionen, Ausgabe und Exit-Codes erhalten; kein doppeltes Suchprogramm entwickeln. Vor neuen Kommandos vorhandene Prozess-, Dateisystem- und Logwerkzeuge prüfen.

**Architektur:** Kleine eigenständig nutzbare Perl-/Shell-Kommandos und optionale native Werkzeugadapter; vorhandene Module und Programme wiederverwenden. Kein eigener Debugger, Pflicht-Framework, permanenter Daemon, Web-UI oder separates Repository. Repository-typische Namen mit Bindestrichen ohne Sprachsuffix bevorzugen. Die folgenden Namen sind Arbeitsbegriffe, keine endgültigen CLI-Verträge.

| ID | Priorität | Geplanter Umfang und Abnahmegrenze |
| --- | --- | --- |
| CD-01 | P1 | Bestandsaufnahme und klassische Core-Dateidiagnose: core-report prüfen, Format/Architektur mit begrenzten nativen Werkzeugen (file, gegebenenfalls readelf) erkennen, Kandidaten von validierten Core-Dateien unterscheiden und Dump-Einstellungen lesend prüfen. Formatgrenzen, fehlerhafte/abgeschnittene Dateien und Kompatibilität spezifizieren. |
| CD-02 | P1 | Offline-Debuggeranalyse und Symbolabgleich (z. B. core-analyze, core-symbols): ausdrücklich übergebener Dump und Executable, Build-Identität oder Unsicherheit, Signal, Frames, Threads und geladene Bibliotheken soweit verfügbar. Zuerst GDB unter Linux. Unsicheres Auto-Loading und Netzwerkabrufe deaktivieren; fehlende Symbole, Abweichungen, Timeouts und Debuggerfehler sichtbar machen. |
| CD-03 | P1 | Diagnoseerfassung und Berichte (z. B. core-collect, core-analysis-report): begrenzte reproduzierbare menschenlesbare und bei Bedarf strukturierte Berichte mit Herkunft, Versionen, beobachteten Fakten, Einschränkungen, Hypothesen und Folgeschritten. Keine unbelegte Fehlerursache oder Namenskollision mit core-report. |
| CD-04 | P2 | Betreiberseitig gestartete Erkennung, Platzbedarf, Aufbewahrungsinventar und Archivierungs-/Bereinigungsvorschau. Kopieren, Archivieren oder Löschen erfordern gesondert autorisierten Operationsvertrag, private Rechte und sichere Pfad-/Identitätsprüfung. Kein permanenter Watcher; Statistik und Ähnlichkeitsgruppen optional später. |
| CD-05 | P2 | Moderner Linux-Adapter für systemd-coredump/coredumpctl: lesende Metadaten, bei begründetem Bedarf ausdrücklich autorisierter lokaler Export; Aufbewahrung, fehlende Tools und Systeme ohne systemd berücksichtigen. Dump-Konfiguration nicht ändern. Native Abnahme erforderlich. |
| CD-06 | P2 | Verwandte Anwendungsdiagnose: vorhandene Prozess-/Logwerkzeuge zuerst prüfen; begrenzte Binäranalyse (nm, objdump, readelf); separat abgegrenzte Prozessinspektion (pmap, lsof) und Live-Tracing (strace, truss, ktrace). Profiling, Leak-Analyse und Live-Attach erfordern eigene Datenschutz-/Freigabegrenzen. |
| CD-07 | P3 optional | Kernel-Crash-Analyse (kdump, crash, kgdb) als getrenntes späteres Design-/Laborpaket. Keine automatische Crash-Injektion, Kernel-Konfiguration oder Live-Kernel-Debugging. Memory-Forensik außerhalb des initialen Scopes. |

Historische Recherchekandidaten: adb/dbx, Solaris coreadm/mdb/pstack, AIX dbx, HP-UX adb/gdb und BSD gdb/lldb. Verfügbarkeit ist versionsabhängig; keine bestätigte Plattformunterstützung ableiten. Native Abnahme zunächst in isolierter Debian-Linux-Wegwerf-VM; andere Unix-Adapter erst bei tatsächlich prüfbaren Tools, Formaten und Umgebungen.

**Sicherheits- und Datenschutzanforderungen:**

- Core-Dateien, speicherbasierte Texte, Backtraces, Pfade, Umgebungsdaten und Debuggerausgaben sind potenziell vertraulich und nicht vertrauenswürdig. Keine Kundendumps oder sensiblen Rohberichte committen, nichts automatisch übertragen, keine standardmäßige strings-Vollanalyse oder unnötige Speicherinhalte erfassen. Synthetische geheimnisfreie Fixtures nutzen; sensible Werte und Identifikatoren vor autorisierter Weitergabe schwärzen; Schwärzung beweist keine Anonymität.
- Standardmäßig nur ausdrücklich gewählte, autorisierte Eingaben lesend untersuchen. Kein standardmäßiger breiter Hostscan, Root-Eskalation, Live-Attach, sysctl-/ulimit-Änderung, Crash-Erzeugung, Dienständerung, Paketinstallation, Löschen oder automatischer Upload. Ausdrücklich angeforderte lokale Berichte erfordern private Verzeichnisse, restriktive Rechte und kein Überschreiben fremder Dateien.
- Nicht vertrauenswürdige Dumps, Executables und Symbole mit gepflegten vertrauenswürdigen Werkzeugen isoliert ohne Root, möglichst in einer Wegwerfumgebung ohne Netzwerk und Host-Geheimnisse analysieren. Debugger-Startskripte, Auto-Loading und automatische Symbol-Downloads deaktivieren; übergebenes Programm/Inferior nicht ausführen. Vertrauenswürdige Toolpfade und Argumentlisten statt Shell-Interpolation; Pfade und Dateiidentität prüfen, unsichere Links/Spezialdateien ablehnen, Zeit/Ressourcen/Ausgabe begrenzen und Fehler ehrlich ausweisen. Debugger-Flags allein sind keine Sandbox.
- Autorisierte Nachweise erhalten: gegebenenfalls Identität/Hash, Build-ID oder ausdrücklich unbekannt/abweichend, Zeitpunkte, Versionen, Grenzen und Beweiskette dokumentieren. Originale nicht verändern. Nachweise privat nach freigegebener Aufbewahrungsregel speichern. Ein Stacktrace allein beweist keine Fehlerursache.

**Abnahme und nächster Slice:** Zunächst CD-01 gesondert freigeben; bestehende Verträge/Tests prüfen, Überschneidungen ermitteln und Formate, Abhängigkeiten, Exit-Codes sowie minimale Änderung spezifizieren. Jeder weitere Slice braucht positive/negative Offline-Tests, DE/EN-Kommandodoku, passende Manpages, gegebenenfalls Installer-/CLI-Prüfungen und commitgenaue Nachweise. Je nach Scope falsche Kandidaten, fehlerhafte/abgeschnittene Dumps, ungewöhnliche Pfade, unsichere Links/Spezialdateien, fehlende Debugger/Symbole, unpassende Executables, feindliches Auto-Loading, Timeouts/Ausgabegrenzen und unvollständige/geschwärzte Berichte testen. Ein selbst entwickeltes kleines Testprogramm darf synthetische Abstürze nur in einer gesondert freigegebenen Wegwerf-VM ohne echte Geheimnisse und mit begrenztem Plattenverbrauch erzeugen. Mock-Tests, SKIPs und nicht unterstützte Plattformen von nativen GDB-/systemd-Nachweisen trennen. Nur bereinigte Beispielberichte veröffentlichen; bestätigte Beobachtungen, Hypothesen und belegte Ursachen unterscheiden. Dienstleistungsreife erfordert eigene Praxisfälle und Freigabe. Dieser Planungsnachtrag schließt kein bestehendes RG-Gate.

## 3. Prüfungen, Testprotokolle und Release-Nachweise

Gemäß [CONTRIBUTING.md](../CONTRIBUTING.md) in einem unprivilegierten Checkout und mit Wegwerf-Staging testen; Produktivsysteme schützen. Längere lokale Testläufe gleichzeitig anzeigen und vollständig protokollieren, ohne den Fehlerstatus in einer Pipeline zu verdecken:

```bash
mkdir -p .test-logs
# .test-logs/ lokal in .git/info/exclude oder im Repository in .gitignore ausschließen.
set -o pipefail
make test 2>&1 | tee ".test-logs/make-test-$(date +%Y%m%d-%H%M%S).log"
```

Den tatsächlichen Exit-Status zusammen mit Commit und Umgebung dokumentieren. `.test-logs/` enthält lokale Nachweise; vollständige Logs, Zugangsdaten und private Hostinformationen nicht committen. Weitere gezielte Prüfungen sind `make check`, `make release-gap-audit`, `make shellcheck`, gegebenenfalls Integrationstests sowie Staging-Installation/-Deinstallation. `make test` ersetzt keine echte privilegierte oder native Abnahme. Die CI-Protokolle sind zusätzlich über GitHub Actions verfügbar; Terminal-Scrollback ist kein dauerhaftes Protokoll.

## 4. Technischer Detailreview und Paketverträge (7. November 2026)

Die folgenden Erkenntnisse stammen aus dem zweiten Fortsetzungsreview bei Commit `337b7cf` und sind als **datierte Nachweise** erhalten. Inventar, Reproduktionen, Quellengrenzen und offene Punkte bleiben wertvoll. **Die aktuelle Reihenfolge und P0/P1-Bedeutung bestimmt die produktorientierte Tabelle oben**, nicht der frühere Buchvollständigkeitsplan. FR2-01 ist optionale Forschung; neue Funktionen hängen nicht von der Fertigstellung der Buchmatrix ab.

**Erstellt:** 7. November 2026. **Status:** versionierte Fortsetzungsplanung auf Basis einer erneuten Bestandsprüfung; keine Produktfreigabe und keine pauschale Implementierungsfreigabe für alle aufgeführten Funktionen.

### 1. Zweck, Geltung und Ausgangspunkt

Diese zweite Roadmap ergänzt die kapitelorientierte Planung und trennt vier Fragen:

1. Welche Aufgaben des Buches sind durch heutige Werkzeuge fachlich abgedeckt?
2. Welche Funktionen fehlen oder wurden bewusst enger umgesetzt?
3. Welche Fehler und Dokumentationswidersprüche wurden tatsächlich gefunden?
4. Welche Praxis-, Wiederherstellungs- und Release-Nachweise fehlen noch?

Das Referenzwerk ist **David N. Blank-Edelman, Perl for System Administration, O'Reilly, erste Ausgabe Juli 2000, ISBN 1-56592-609-9**. Die zweite Ausgabe unter dem Titel *Automating System Administration with Perl* wurde nicht vollständig geprüft und ist kein stillschweigend eingeschlossener Anforderungskatalog.

Die frühere Kapitelplanung und ihre historischen Abschnitte sind in Abschnitt 5 dieser gemeinsamen Roadmap erhalten. Die hier dokumentierten Befunde sind eine jüngere, datierte Prüfung. Bestehende CLI-Verträge, Sicherheitsgrenzen und Release-Gap-Definitionen werden dadurch nicht aufgehoben. Kennungen `FR2-*` sind neue Planungskennungen, keine rückwirkende Umbenennung von M9 oder M10.

**Quellenstand:** `main` bei der Prüfung: `337b7cff34c2818921d1df023f3c5e2d386301c8`; zugehöriger Tree: `c2b953e454b80014e59322f2cd2f56840351b9ef`. Vor späteren Änderungen HEAD und CI erneut prüfen. Diese Dokumentation verändert keine Laufzeitfunktion und schließt kein Release-Gate.

### 2. Quellen und Grenzen der Prüfung

#### 2.1 Quellenrangfolge

- Aktueller Code, Testfälle und GitHub-Metadaten für einen bestimmten Commit.
- Gültige Verträge in Guides, Manpages, Makefile und CI.
- Originales Buchinhaltsverzeichnis und zugängliche Verlagsabschnitte.
- Datierte Betreiberprotokolle mit erkennbarer Umgebung und Herkunft.
- Historische Roadmaps und Chat-Zusammenfassungen als ergänzender Kontext.

Bei Widersprüchen den konkreten Befund dokumentieren; keine Quelle allein wegen ihres Datums ungeprüft zur Wahrheit erklären. Ein älterer Betreiberbericht kann weiterhin ein gültiger Teilnachweis sein, ohne den heutigen Commit vollständig abzunehmen.

#### 2.2 Prüfumfang und ausdrücklich nicht bewiesene Eigenschaften

Alle 334 versionierten Dateien des Ausgangscommits wurden abgerufen und ihr Inhalt gegen die Git-Blob-SHAs verglichen; keine Abweichung. Programme, Module, Tests und Dokumentation wurden inventarisiert und auf fachliche Gegenstücke untersucht. Das ist keine vollständige formale Sicherheitsprüfung jeder Codezeile und kein Vergleich jedes ursprünglichen Buchlistings.

Die Buchbewertung beruht auf dem ausführlichen Verlagsinhaltsverzeichnis und zugänglichen Abschnitten. Unterpunktgenaue Anforderungen, Alternativverfahren und mögliche bewusste Ausschlüsse müssen in FR2-01 nachgetragen werden. Aus einer fehlenden Erwähnung im README allein wurde keine fehlende Funktion abgeleitet.

Die temporären Prüfkopien waren kein vollständiger Git-Checkout. Deshalb war die lokale Git-Index-Prüfung nicht Teil der unten genannten Testausführung. Der Inhalt war anhand der Blob-SHAs verifiziert; Git-Dateimodi wurden aus dem Tree übernommen. Das ersetzt keine spätere Prüfung eines echten Checkouts.

#### 2.3 Verbindliche Evidenzbegriffe

| Begriff | Bedeutung |
| --- | --- |
| Code-bestätigt | Verhalten/Fehlen anhand benannter Implementierung und Schnittstelle festgestellt |
| Lokal reproduziert | Im isolierten temporären Prüfbaum tatsächlich ausgeführt; Umgebung und Methode benennen |
| CI-bestätigt | Erfolgreicher konkreter Lauf für genau den genannten SHA |
| Betreiberbericht | Von einem Menschen berichtete Praxis; nicht automatisch unabhängig wiederholt |
| Geplant | Noch nicht implementiert oder abgenommen |
| Nicht nachgewiesen | Ausreichender Beleg fehlt in den geprüften Quellen; keine Behauptung, es habe nie einen Test gegeben |
| Ausgeschlossen | Begründeter, versionierter Scope-Beschluss mit verantwortlicher Entscheidung |

### 3. Baseline und tatsächlich ausgeführte Prüfungen

| Merkmal | Stand am Ausgangscommit |
| --- | --- |
| Installierbare Kommandos | 52 in `bin/`, 2 in `sbin/` |
| Laufzeitmodule | 15 unter `lib/SASD/Freeware/` |
| Interne Installermodule | 3 unter `tools/lib/SASD/Freeware/` |
| Manpages | 54 |
| Perl-Offlinetestdateien | 48 `tests/test_*.t`; zusätzlich zwei Shelltestdateien und optionale Integration |
| Statisches Release-Audit | `PASS=288`, `GAP=0`, `MANUAL=7` |
| Vollständige Staging-Installation | 257 verwaltete Dateien |
| Main-CI | [Run 42174570467](https://github.com/SASD-Sysadmin/freeware/actions/runs/42174570467), `completed/success`, Ubuntu und macOS |

Lokal erfolgreich ausgeführt wurden `make check`, `make release-gap-audit`, eine vollständige temporäre DESTDIR-Installation sowie:

```sh
prove tests/test_cli_contracts.t tests/test_installation.t \
  tests/test_installation_concurrency.t tests/test_installation_interruption.t \
  tests/test_installation_rollback.t tests/test_release_gap_audit.t \
  tests/test_documentation.t tests/test_m9_documentation.t
```

**Ergebnis vor dieser Dokumentationsänderung:** acht Dateien, 1.664 Prüfungen, `PASS`. Tests liefen in einer isolierten Root-User-Namespace-Umgebung mit temporären Dateien; es wurden nur die benannten geeigneten Suiten ausgewählt. Eine nichtprivilegierte UID ließ sich dort nicht starten. **Die vollständige `make test`-Suite, lokale Git-Index-Prüfung, ShellCheck und native Integration wurden in dieser Prüfung nicht ausgeführt.** Die Main-CI deckte die dort konfigurierten Prüfungen separat ab. Spätere Dokumentationslinks erhöhen möglicherweise Testzahlen; die historische Zahl ist kein Sollwert.

In der macOS-CI wird LDAPS ausdrücklich übersprungen; ein erfolgreicher kombinierter Integrationsschritt bedeutet dort keine LDAPS-Abnahme. Container- und Parserprüfungen beweisen keinen nativen Kernel-/Firewallbetrieb.

### 4. Buchabdeckung: Unterschiede nach Kapiteln

| Kapitel | Heutige fachliche Gegenstücke | Fehlend, enger umgesetzt oder noch abzugleichen |
| --- | --- | --- |
| 1 – Einführung | CLI-/Sicherheits-/Entwicklungsregeln | Prinzipien kapitelübergreifend prüfen; kein eigenes Programm als Abschlusskriterium erforderlich |
| 2 – Dateisysteme | Inventare, Rechte, Links, Quotas, Belegung, Inhaltsintegrität; zusätzliche EOL-Konvertierung | Historische plattformspezifische Verfahren und Quota-Alternativen nicht vollständig übertragen; moderne Unix-/Linux-Abdeckung weit, Listing-Abgleich offen |
| 3 – Benutzerkonten | Konten/Gruppen/Homes; `user-create`, `group-create`, `password-lock` unter Linux | Zusammenhängendes Kontensystem mit zentralem Datenbestand, XML, Verarbeitungsskripten, Anlage/Löschung und Windows-Verwaltung fehlt |
| 4 – Benutzeraktivität | Sessions, Prozesse, Linux-Anmeldehistorie | Datei-/Netzwerkoperationsverfolgung, weitergehende Prozesssteuerung, vollständige Plattformadapter fehlen |
| 5 – Namensdienste | Hosts-Lint, DNS-Abfrage, NSS, Resolver, begrenzte NIS-Diagnose | Hosts-/DNS-Konfigurationsgenerierung aus zentralen Daten, Generierungsprüfungen und zugehöriger Versionsablauf fehlen; NIS+/WINS nicht verwaltet |
| 6 – Directory Services | Anonyme LDAPS-Root-DSE und statische TLS-Konfiguration | Allgemeine authentifizierte LDAP-Suche, LDIF-Import/Änderungen, Anlegen/Löschen/Umbenennen/Attributänderungen fehlen; Finger, WHOIS und ADSI fehlen |
| 7 – SQL | Lesende Diagnose für PostgreSQL/MySQL/MariaDB, begrenzter Storage-Bericht | DBI-/ODBC-Beispiele und umfassendere Verwaltungsabläufe nicht übertragen; Sybase/MS-SQL-Anbindung und dortige Login-/Dokumentationsaufgaben fehlen |
| 8 – E-Mail | STARTTLS-Diagnose, Postfix-Queue und statische Konfiguration | Administrativer Mailversand, Bündelung/Drosselung, Eingang/Mailbox-/MIME-Verarbeitung sowie Spam-/Blacklist-/Support-Abläufe fehlen |
| 9 – Logs | Strukturierte Zählungen und Normalisierung, Dateisicherung mit `rotate` | Zustandsbehaftete Verarbeitung, weitergehende Datenbankhistorisierung und Ringpuffer fehlen; Dateisnapshots sind keine vollständige Rotation aktiver Logs |
| 10 – Sicherheit/Netzwerk | Inhaltsbaseline, SUID/SSH, TCP, Interfaces/Routen/Listener, Firewallauszüge | SNMP, Paketmitschnitt/-auswertung, Baseline-Vergleich von Netzwerkdiensten und weitergehende Korrelation fehlen |
| Anhänge A–E | Teilweise Grundlagen in heutigen Guides | RCS-, LDAP-, XML-, SQL- und SNMP-Tutorials noch nicht als abgedeckt bewerten; Lernmaterial braucht nicht für jeden Abschnitt ein eigenes CLI |

#### 4.1 Fachliche Gleichwertigkeit statt bloßer Modulgleichheit

Native SQL-Clients statt DBI sind eine Architekturentscheidung, kein automatischer Fehler. Entsprechendes gilt für eigene Traversierung statt bestimmter Buchmodule. Bewertet wird der administrative Anwendungsfall mit Grenzen und Nachweisen, nicht das Vorkommen eines Modulnamens.

ACL-/Mountübersichten, PostgreSQL-Storage, Oracle-Anbindung, vollständige Firewallbewertung und moderne Linux-Verteilungsnachweise sind Projektideen beziehungsweise Erweiterungen. Sie dürfen nicht ohne Buchbeleg zu ursprünglichen Pflichtanforderungen erklärt werden. Insbesondere nennt das geprüfte SQL-Inhaltsverzeichnis MySQL, Sybase und Microsoft SQL Server; Oracle ist daraus nicht als Pflicht abzuleiten.

#### 4.2 Historische und sicherheitsrelevante Themen

Windows NT/2000, klassisches Mac OS, ADSI, NIS+, WINS und RCS sind keine automatisch zu implementierenden modernen Produktziele. Für jedes Thema eine Entscheidung `modernisieren`, `übernehmen`, `verschieben` oder `ausschließen` mit Begründung dokumentieren. Finger/WHOIS, Paketmitschnitt, LDAP-Schreibpfade und Benutzerdatenverarbeitung benötigen zusätzlich konkrete Nutzungs-/Datenschutzgrenzen. Ein Scope-Ausschluss ist keine erfolgreiche Implementierung.

### 5. Bestätigte Befunde und Abgrenzungen

| ID | Befund / Nachweis | Erforderliche Folgerung |
| --- | --- | --- |
| FR2-F01 | Uninstall löscht nach Preflight sequenziell; deterministischer Fehler bei zweiter Löschung ließ erste Datei fehlen, zweite und Manifest bestehen. Wiederholung verweigerte mit `installed file changed or missing; refusing: bin/alpha`. Siehe `tools/installation.pl`, Uninstall-Zweig. | Wiederanlauf-/Recovery-Vertrag entwerfen und regressionsprüfen; kein pauschales Entfernen fehlender Manifestzeilen |
| FR2-F02 | README nennt Perl 5.8 pauschal; `bin/file-integrity` nutzt `//`, andere Werkzeuge benötigen neuere APIs/Module. | Geprüfte Mindestversion und Abhängigkeiten pro unterstützt ausgeliefertem Umfang bestimmen |
| FR2-F03 | `mail-probe` unterstützt weder IPv6 noch implizites SMTPS/465; Guides bestätigen dies. | Funktionslücke, keine bloß fehlende Abnahme; Erweiterung oder ausdrücklichen Scope-Ausschluss planen |
| FR2-F04 | Vollständiges Staging installierte 257 Dateien, aber keine `LICENSE` unter dem Präfix. Installer-Auswahl enthält sie nicht. | Ausgelieferten Lizenz-/Hinweisumfang prüfen; Einbeziehung muss Manifest, Upgrade und Uninstall berücksichtigen |
| FR2-F05 | Keine ausdrückliche Nennung von Autor, Verlag oder Buchtitel in der repositoryweiten Suche vor diesem Slice; keine unterpunktgenaue Zuordnung. | Herkunft und fachliche Zuordnung dokumentieren; tatsächliche Codeübernahmen getrennt prüfen |
| FR2-F06 | Audit erzeugt sieben MANUAL-Zeilen bedingungslos. | Nicht als sieben gescheiterte oder nachweislich nie ausgeführte Tests ausgeben |
| FR2-F07 | Historische Planung enthält überholte Bestandszahlen und nächste Schritte. | Datierte Historie erhalten, aktuelle Fortsetzung deutlich verlinken; keine alte Empfehlung ungeprüft ausführen |

#### 5.1 Reproduktionsvertrag zu FR2-F01

Das Review verwendete ausschließlich eine temporäre Quelle und ein temporäres DESTDIR. Die Quelle enthielt `bin/alpha` und `bin/beta` als ausführbare reguläre Dateien sowie die vom Installer erwarteten leeren Abschnittsverzeichnisse. Nach erfolgreicher Installation wurde im separaten Perl-Prozess `CORE::GLOBAL::unlink` vor Laden des Installers überschrieben: für `bin/beta` wurde ein Fehler ausgelöst, für andere Pfade an `CORE::unlink` delegiert. Wegen `FindBin` im Wrapper wurde `tools/lib` explizit zum Modulpfad hinzugefügt.

Vor dem Wiederholungsversuch wurden unabhängig Dateiexistenz und Manifest erfasst: alpha fehlte, beta und Manifest waren vorhanden. Anschließend scheiterte der normale Uninstall-Start bereits im Preflight an alpha. Eine künftige Regression soll diesen Vertrag als isolierten Test abbilden, nicht die Produktimplementierung mit einem Produktions-Fault-Injection-Schalter versehen. Dies ist keine Simulation eines Stromausfalls, kein echter SIGKILL und keine native VM-Abnahme.

#### 5.2 Bekannte Grenzen sind nicht automatisch neue Defekte

- Installer: kooperativer Lock, keine Sperre fremder Schreiber; kein fsync-/Stromausfallprotokoll, keine atomare Crash-Recovery.
- `text-eol-normalize`: eingeschränkte Metadatenübernahme; Inode/Zeiten ändern sich; ACLs/Xattrs und gleichzeitige Schreiber brauchen ausdrücklichen Scope.
- `file-integrity`: Inhaltsprüfsummen, keine vollständige Metadaten- oder signierte Vertrauenskette.
- Firewallberichte: begrenzte quellenspezifische Aussagen, kein Beweis wirksamen Gesamtschutzes.
- `password-lock`: sperrt Passwortauthentifizierung, entzieht keine SSH-Schlüssel oder laufenden Sitzungen.
- Netzwerkdiensteinventar: Listener/UDP-Bindungen, keine PID-/Benutzer-/Programmzuordnung oder vollständige Verbindungshistorie.

### 6. Abnahmeregister: vorhandene und fehlende Belege

Die Definitionen RG-01 bis RG-10 bleiben in [RELEASE-GAPS.de.md](RELEASE-GAPS.de.md). Dieses Dokument schließt sie nicht. Die sieben MANUAL-Kategorien des Skripts sind nicht eins zu eins die zehn RG-Kennungen.

| Bereich | Nachweisstand beim Review | Noch erforderlich |
| --- | --- | --- |
| Aktuelle CI | Passender Main-Lauf und beide Job-/Schrittstatus geprüft | Für jeden künftigen Release-Commit neu zuordnen; macOS-LDAP-SKIP erhalten |
| Statische Dokumentation | 54 Manpages, Einzelguides vorhanden; Audit GAP=0 | Semantische Qualität, Versionen und laufender Link-/Indexabgleich |
| RG-01 Konten/Quotas | Vorschau-/Negativ-/Mocktests; keine abgeschlossene native VM-Abnahme in geprüften Quellen | Separate Freigabe, isolierte Snapshot-VM, echte Apply-Schritte, unabhängiger Zustand und Restore |
| RG-04 Installer | Offline-Abbruch/Rollback/Konkurrenztests; WSL-Teilnachweise in Betreiberübergabe; neuer F01-Befund | Uninstall-Recovery, echter Abbruch in geeigneter VM, geprüfter Rückweg; Teilbelege anerkennen |
| RG-05 Plattformen | Ubuntu/macOS-CI und synthetische/optionale Containerverfahren | Native Tests nur für tatsächlich beanspruchte Plattform-/Funktionskombinationen |
| RG-06 Dienste | Offline-/Loopback-Tests; dokumentierter begrenzter Postfix-Praxistest | Produktnahe SQL-/LDAP-/Mail-/Firewall-Nachweise entsprechend Releaseumfang |
| RG-02 Artefakte | Kein GitHub Release bei erneuter Abfrage; vollständiger Tagbestand nicht verifiziert | Sauberer festgelegter Tag/Commit, Versionskonsistenz, Archiv und unabhängige SHA-256-Wiederholung |
| RG-03 Freigabeakte | Kein abgeschlossener Gesamtbeleg in geprüften Quellen | Umfang, Commit, Nachweise, Abweichungen, Rückweg und verantwortliche Freigabe |
| RG-09 Abhängigkeiten/Hinweise | F02/F04/F05 festgestellt | Laufzeitmatrix, Herkunft und ausgelieferte Lizenzhinweise prüfen |

**Postfix-Teilnachweis:** [MAIL-ACCEPTANCE.de.md](MAIL-ACCEPTANCE.de.md) dokumentiert am 20.10.2026 auf Debian 12/Postfix 3.7.11 eine leere Queue, STARTTLS mit Test-CA und Ablehnung einer unbekannten CA. Gefüllte Queue und wirksame master.cf-Overrides sind nicht fachlich abgenommen. IPv6/465 sind nicht implementiert, nicht bloß ungeprüft.

**WSL-Teilnachweis:** Die beigefügte Betreiberübergabe berichtet für SHA `337b7cf` 39 Staging-PASS, Installation/Reinstall von 257 Dateien, Manipulationsverweigerung, Hashprüfungen sowie Uninstall mit Erhalt einer fremden Datei. Nicht unabhängig wiederholt. Archiv-SHA laut Übergabe: `d3c676a8ed84aa8dff7f58ae5bcd2fc581d2e700205a3ac9f42c1d4da9cf8f9e`. Archivinhalt und Wiederherstellbarkeit wurden im Review nicht geprüft. Keine vollständigen privaten Betreiberlogs ins öffentliche Repository übernehmen.

### 7. Geordnete Arbeitspakete

P0 bezeichnet Sicherheit und Evidenz für den gewählten Releaseumfang; die historische Buchmatrix ist optionale Forschung; nicht alle späteren Buchergänzungen sind Releaseblocker. Kein Paket legitimiert nebenbei produktive Systemänderungen.

| Paket | Priorität | Umfang / Liefergegenstand | Abhängigkeit und Abschluss |
| --- | --- | --- | --- |
| **FR2-00** | Planung abgeschlossen | Zusammengeführte DE/EN-Roadmap, Root-AGENTS und Navigation | Dokumentationsprüfungen; keine Laufzeitänderung und kein Gate automatisch schließen |
| **FR2-01** | P3 optionale Forschung | Unterpunktgenaue Buch-/Projekt-Abdeckungsmatrix nur auf ausdrücklichen Auftrag | Entscheidungen über moderne Entsprechung und Ausschlüsse; alle relevanten Unterpunkte erhalten Status, Quelle, Code, Test und Akzeptanz |
| **FR2-02** | P0 Qualität | Perl-/Modul-/Client-Mindestversionen korrigieren (F02) | Keine beliebige Versionsanhebung; saubere Testumgebung für gewählte Untergrenze, beide Sprachen und Fehlerfälle konsistent |
| **FR2-03** | P0 Sicherheit | Uninstall-Fehlerzustand und Recovery-Vertrag (F01) | Zuerst isolierte Regression; neue Strategie schützt fremde/veränderte Daten, Manifest, Backups und Lock; Recovery-Nachweise |
| **FR2-04** | P0 Herkunft | Buchhinweis, tatsächliche Übernahmen und ausgelieferte Lizenzhinweise (F04/F05) | Rechte prüfen, nicht aus Buchbesitz ableiten; falls LICENSE installiert wird: Manifest-/Upgrade-/Konflikt-/Uninstalltests |
| **FR2-05** | P0 Evidenz | Versionierte Nachweisstruktur und Quellenzuordnung | Bestehende Standards prüfen; WSL als Teilnachweis erfassen; Audit-MANUAL-Semantik korrekt erklären |
| **FR2-06** | P0 Abnahme | RG-01/RG-04 in geeigneter Snapshot-VM und RG-02/RG-03 für festgelegten Umfang | Erst 02–05 soweit relevant; getrennte Betreiberfreigaben; bewusste Ausschlüsse versionieren; Release separat autorisieren |
| **FR2-10** | P1 Nutzen | Hosts-/DNS-Generierung, zunächst nur in Ausgabeverzeichnis | Nach auftragsbezogener Scope-Entscheidung; kanonisches Datenmodell, deterministische Ausgabe, semantische Prüfung; kein automatisches Schreiben nach /etc oder Reload |
| **FR2-11** | P1 Nutzen | LDAP allgemein lesend, danach getrennt schreibend | Nach auftragsbezogener Scope-Entscheidung; Bind-/TLS-/Filter-/Secret-Vertrag; Suchphase vor Schreibphase; reale Labore für Änderungen |
| **FR2-12** | P1 Nutzen | Administrativer Mailversand mit Drosselung/Deduplizierung | Nach auftragsbezogener Scope-Entscheidung; getrennt von mail-probe; nur lokaler Test-Sink, keine echten Empfänger in Tests |
| **FR2-13** | P1 Nutzen | Zustandsbehaftete Logs und Service-Baselinevergleich | Nach auftragsbezogener Scope-Entscheidung; stabile Zustandsformate, atomische Publikation, Sperren, verlässliche Zeit-/Dublettenregeln |
| **FR2-14** | P1 Nutzen | SNMP zunächst lesend | Nach auftragsbezogener Scope-Entscheidung; SNMPv3 Auth/Privacy als Ziel, geschützte Secrets, Timeouts und begrenzte OID-/Walk-Mengen |
| **FR2-20** | P2 Ausbau | Kontenlebenszyklus und optional zentrale Datenhaltung | Nach auftragsbezogener Scope-Entscheidung und RG-01-Vertrag; Import-/Planmodell vor Schreibpfad; Löschung und Datenaufbewahrung gesondert entscheiden |
| **FR2-21** | P2 Ausbau | SQL-Umfang und zusätzliche Engines | Fachlichen Bedarf wählen; PostgreSQL-Storage/Sybase/MS-SQL getrennte Slices; kein Modulwechsel ohne Nutzen |
| **FR2-22** | P2 Ausbau | Mail-Eingang/MIME/Mailbox und Support-Abläufe | Lokale Fixtures, Größen-/Encoding-/Datenschutzgrenzen; keine ungefragte Postfachverbindung |
| **FR2-23** | P2 Ausbau | IPv6 und implizites SMTPS in mail-probe | Getrennte Protokollpfade und positive/negative TLS-Tests; keine Abschwächung bestehender Prüfung |
| **FR2-24** | P2 Ausbau | Mount/ACL/Storage und moderne native Adapter | Projektanforderung belegen; Plattform-/Metadatenmatrix, native Abnahme, lesender Start |
| **FR2-25** | P2 optional | Datei-/Netzwerkoperationsverfolgung und Paketmitschnitt | Nur begründeter Auftrag; Berechtigungen, Datenminimierung, Limits und isolierte Labore vorher definieren |
| **FR2-30** | P3 Entscheidung | Historische Plattformen/Protokolle und Anhänge | Übernahme/Modernisierung/Ausschluss pro Thema; keine pauschale Buchkopie |

#### 7.1 Empfohlene Ausführung

1. FR2-03 ist der nächste technische Sicherheitsslice nach grüner Eingangs-CI und mit isolierter Regression. FR2-01 bleibt optionale Forschung und ist keine Voraussetzung.
2. FR2-02 und FR2-04 getrennt nach dem abgegrenzten FR2-03 bearbeiten, sofern kein belegter Blocker die Reihenfolge ändert. Daraus folgt kein Auftrag zur Agentendelegation.
3. FR2-05 strukturiert die vorhandenen Belege; FR2-06 behandelt echte verbleibende manuelle Gates. Verfügbare sichere Arbeiten weiterführen, wenn gerade keine VM verfügbar ist.
4. Nach funktionsbezogener Scope-Entscheidung zunächst FR2-10, dann lesendes FR2-11 und FR2-12 erwägen; FR2-13/14 nach konkretem Administrationsnutzen einordnen.
5. P2/P3-Pakete erst nach Bedarf und getrenntem Auftrag. Ein bewusst kleiner Releaseumfang kann früher freigegeben werden; Buchvollständigkeit darf daraus nicht abgeleitet werden.

Ein Runtime-Fix darf nach dieser Planung nicht ohne neue CI-Eingangsprüfung beginnen. Diese Roadmap setzt keinen Termin, erstellt keine Tags und beschließt keine .deb-/ .rpm-Paketierung. Paketformate bleiben spätere Entscheidungen.

### 8. Verbindliche Paketverträge

#### FR2-01: optionale Buch-Abdeckungsmatrix

Nur bei ausdrücklich beauftragter Recherche pro Zeile mindestens: ID, Ausgabe/Kapitel/Unterabschnitt, Quelle, administrativer Anwendungsfall, gewünschte heutige Entsprechung, vorhandene Implementierung, Tests, Plattformgrenzen, Nebenwirkungen, Status, Entscheidung und verbleibender Nachweis. Zustände: `nicht bewertet`, `teilweise`, `implementiert`, `abgenommen`, `zurückgestellt`, `ausgeschlossen`. Implementierung und Abnahme getrennt führen. Keine Prozentangabe ohne definierten Nenner; keine Gesamtfertigmeldung allein aus vertretenen Kapitelüberschriften.

#### FR2-03: Recovery

Fehler vor erster Löschung, nach mindestens einer Löschung, beim Manifest und beim Cleanup prüfen. Strategie darf transaktionale Sicherung oder dokumentiertes resumierbares Verfahren sein; Entscheidung in einem kurzen ADR begründen. Tests für veränderte/fremde Dateien, fehlende Dateien, erneuten Aufruf, konkurrierende Prozesse und Rechtefehler. Keine automatischen Vermutungen aus einer unvollständigen Installation; keine Backups/Lockdateien zum Entsperren löschen. Das spätere native Abbruchlabor bleibt ein gesonderter Nachweis.

#### FR2-10 bis FR2-14: neue produktive Funktionen

Vor Code: klarer Zweck, Scope, Beispielausgabe, Exit-Codes, Abhängigkeiten, Nichtziele und Teststrategie. Trennung von CLI, Beschaffung/Backend, reinem Parser/Modell und Präsentation soweit sinnvoll. Datenformate versionieren, Secrets nicht in argv oder Logs, Netzwerkziele ausdrücklich wählen, Laufzeiten/Mengen begrenzen. Keine unaufgeforderten Änderungen an DNS, LDAP, Mail oder Überwachungszielen.

### 9. Abschlusskriterien pro Slice und für die Fortsetzung

Jeder Slice braucht einen kleinen nachvollziehbaren Diff, passende positive/negative Tests, konsistente DE/EN-Guides/Manpages bei CLI-Änderungen, aktualisierten Changelog und Evidenzgrenzen. `make test` gemäß CONTRIBUTING in geeignetem nichtprivilegiertem Checkout; weitere Tests nach betroffenem Verhalten. Nicht ausführbare Markdown-Dateien im Git-Index (`100644`) und ausführbare Programme (`100755`) kontrollieren.

Für einen Release nur den tatsächlich freigegebenen Umfang abnehmen; RG-P0 schließen oder begründeten verantwortlichen Scope-Ausschluss dokumentieren. Fehlende Native-Nachweise nicht durch Fixtures umetikettieren. Für die Aussage einer abgeschlossenen modernen Buchumsetzung müssen zusätzlich alle relevanten Matrixzeilen abgenommen oder ausdrücklich ausgeschlossen sein und die Ausschlüsse sichtbar zur Aussage gehören.

### 10. Quellen und Pflege

- [Originalbuch und ausführlicher Inhalt](https://www.oreilly.com/library/view/perl-for-system/1565926099/)
- [Kontensystem](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch03s03.html), [DNS](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch05s03.html), [LDAP](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch06s04.html), [Mail](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch08.html), [Sicherheit/Netzwerk](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch10.html)
- [Geprüfter Ausgangscommit](https://github.com/SASD-Sysadmin/freeware/commit/337b7cff34c2818921d1df023f3c5e2d386301c8)
- [Release Engineering](RELEASE-ENGINEERING.de.md), [Sicherheit privilegierter Aktionen](PRIVILEGED-SAFETY.de.md), [Plattformen](PLATFORMS.de.md), [Tests](TESTING.de.md), [Entwicklung](DEVELOPMENT.de.md)

Neue Erkenntnisse unter stabilen FR2-Kennungen ergänzen. Korrekturen als solche benennen und EN/DE synchron halten. Historische Testzahlen nicht als aktuelle Ergebnisse weiterreichen. Diese Planung ist eine überprüfbare Grundlage, keine Garantie, dass bei einer einmaligen Prüfung sämtliche Fehler entdeckt wurden.

## 5. Historische Kapitelplanung und frühere Prüfung (Oktober 2026)

Der folgende Teil stammt aus der ursprünglichen `ROADMAP.de.md`. Er bleibt als Prüf-/Geschichtsnachweis erhalten, ist aber **kein** aktueller Implementierungsauftrag. Die Oktober-2026-Bestandsaufnahme mit 30 Programmen und der damalige nächste Schritt beziehen sich nur auf den jeweils angegebenen alten Commit. Sie dürfen nicht ungeprüft auf November 2026 übertragen werden.

**M9 Release-Gap-Analyse (29. Oktober 2026):** Das [Release-Gap-Register](RELEASE-GAPS.de.md) erfasst 54 Programme und priorisiert Freigabenachweise, native/privilegierte Abnahmen sowie Dokumentationslücken. Dies ist keine Release-Ankündigung.

**M9.2 Dokumentationsabdeckung:** Sieben bestehende Programme erhalten
jeweils eine englische und deutsche Einzelanleitung sowie direkte
README-Verweise. Die statische Dokumentationslücke ist damit bearbeitet;
manuelle VM-, Plattform- und Dienstabnahmen bleiben weiterhin offen.

### Historische kapitelorientierte Planung (14. Oktober 2026)

**Damals geltendes Ziel (heute keine verbindliche Produktanforderung):** Die Werkzeuge zu den Buchkapiteln 2–10 systematisch ergänzen.
Der frühere technische Review (weiter unten) ist eine historische Bestandsaufnahme,
**nicht** mehr die aktuelle Meilensteinreihenfolge. Der Installer aus M3 Teil 1 ist
implementiert; Release-Artefakte und eine Veröffentlichung bleiben bewusst zurückgestellt.
Ein Kapitel gilt erst als abgeschlossen, wenn Anforderungen, Plattformgrenzen,
DE/EN-Anleitungen, Manpages und negative/positive Tests geprüft wurden.

| Kapitel | Bereits verfügbare Schwerpunkte | Noch zu bearbeiten | Status |
| --- | --- | --- | --- |
| **2 – Filesystem** | Inventar, Berechtigungen, Links, Quotas, Integrität, `text-eol-normalize` für kontrollierte Textimporte | Mounts, ACLs, Storage-Analyse und native EOL-Praxistests offen | Gut ausgebaut, offen |
| **3 – User Accounts** | Konten, Gruppen, Home-Audit, eingeschränkte Verwaltung | Privilegierte VM-Abnahme, weitere Abdeckungsprüfung | Gut ausgebaut, offen |
| **4 – User Activity** | `session-report`, `process-report`; `login-audit` (Linux `last`/`lastb`) | macOS-Anmeldehistorie, Zuordnung und Vollständigkeit prüfen | In Arbeit |
| **5 – TCP/IP Name Services** | Hosts, DNS, NSS, Resolver | Abschlussprüfung und sinnvolle Ergänzungen | Gut ausgebaut, offen |
| **6 – Directory Services** | LDAPS/NIS-Diagnose, TLS-Konfigurationsaudit | Funktions-/Plattformgrenzen und offene Aufgaben prüfen | Teilweise |
| **7 – SQL Administration** | `db-probe` (M5.1), `db-health` (M5.2), `db-activity` (M5.3) für PostgreSQL/MySQL/MariaDB; MariaDB-/MySQL-`db-storage` (M5.4) | PostgreSQL-Storage, Oracle/SQL Server, MySQL-Sperrgraph, Wachstumsmessungen und echte übergreifende Integrationstests | In Arbeit |
| **8 – Electronic Mail** | `mail-probe` (M6.1), `mail-queue` (M6.2), `mail-config-audit` (M6.3), Offline-Workflow (M6.4); [manueller Teil-Praxistest](MAIL-ACCEPTANCE.de.md) auf Debian 12/Postfix 3.7.11 am 20.10.2026 | Wirksame Service-Overrides, gefüllte Queue, isolierte VM, IPv6/465 und andere Plattformen offen | Technischer Umfang M6 umgesetzt, Betriebslücken offen |
| **9 – Log Files** | `log-summary` (Text), `journal-summary` (M7.1 JSONL), `syslog-summary` (M7.2 Syslog-Struktur), `ssh-auth-summary` (M7.3 offline SSHD), `auth-event-summary` (M7.4 offline sudo/su/PAM), `log-summary-normalize` (M7.5 prüfbare JSONL-Zählberichte) | Native Adapter, weitere PAM-Dienste, macOS Unified Log, echte Ereigniskorrelation und plattformbezogene Vollständigkeitsprüfung | In Arbeit |
| **10 – Security and Network Monitoring** | SSH-, SUID-, Integritäts- und TCP-Prüfungen; `network-interface-report` (M8.1); `network-route-report` (M8.2); `network-service-report` (M8.3); `firewall-config-audit` (M8.4.1 Linux, M8.4.2 vorläufig BSD PF/IPFW/NPF und M8.4.3 vorläufig Solaris PF/IPFilter/SMF; M8.4.5 Linux-firewalld-Laufzeit-/Permanent-Zonen) | Native BSD-/Solaris-/Linux-Distributionsabnahme und Erweiterungen für HP-UX/IRIX, vollständige Firewall-Regelbewertung, Prozesszuordnung, Policy Routing, erweiterte Next-Hops und native Plattformabnahme | M8 in Arbeit |

**Historisch geplante Reihenfolge:** M4 User Activity (zunächst aktuelle Sessions/Prozesse,
danach Anmeldehistorie), M5 SQL, M6 Mail, M7 Logs, M8 Sicherheit und Netzwerk,
M9 Kapitel-Lücken und plattformbezogene Qualitätsabnahme, M10 Release-Artefakte.
Diese Reihenfolge ist eine Arbeitsplanung, keine Aussage über Produktreife oder Termine.

**Kapitel 2 – Zeilenenden:** `text-eol-normalize` erkennt CRLF und wandelt
fertig übertragene Textdateien nur auf ausdrücklichen Wunsch nach LF um.
Lesender Standard, Erweiterungs-Whitelist, Binärdateiprüfung, Hardlink-/Symlink-
Schutz und temporäre Datei im selben Verzeichnis sind offline getestet.
ACLs/Xattrs, Inode, Zeitstempel, gleichzeitige Schreibzugriffe und native
Cron-/WSL-/andere Plattformabnahmen bleiben Einschränkungen bzw. offene Tests.
Siehe [Anleitung](commands/text-eol-normalize.de.md).

**M8.5 Linux-Abnahme:** M8.5.1 führt `linux-platform-report` und Parser-Fixtures
für Debian, Ubuntu, Arch, AlmaLinux und Rocky Linux ein. Native Paketmanager-
und Firewall-Tests, distributionsspezifische CI und VM-Abnahme sind **offen**.
Siehe [Abnahmematrix](commands/linux-platform-acceptance.de.md).

**M8.5.2:** `linux-distro-matrix` ergänzt synthetische Tests, Host-ID-
Nachweise und optionale Containerprüfungen mit festem Image-Digest. Native
Firewall-/MAC-, Paketmanager-, distributionsspezifische CI- und VM-Abnahmen
sind weiterhin **offen**. Siehe [Protokoll](commands/linux-distro-acceptance.de.md).

**M8.5.3:** `linux-container-acceptance` ergänzt optionale, mit Digest festgelegte
Container-Prüfungen für Distributions-ID, Werkzeuge, Offline-Tests, Installation
und Kommando-Smoke-Checks. Echte Image-Testläufe, distributionsspezifische
Nachweise und native Kernel-/Firewall-/MAC-VM-Abnahmen bleiben **offen**.
Siehe [Container-Protokoll](commands/linux-container-acceptance-protocol.de.md).

**M8.5.3a:** `linux-container-evidence-audit` prüft die JSONL-Einzelnachweise
und erstellt eine vollständige Übersicht für fünf Distributionen.
Echte Image-Testläufe und native VM-Abnahmen bleiben **offen**. Siehe
[Anleitung](commands/linux-container-evidence-audit.de.md).


**M4 Teil 1 – Prüfumfang:** `session-report` nutzt `who`, `process-report` nutzt
`ps`; beide sind lesend, brauchen keine Root-Rechte und unterstützen
synthetische Eingaben über `--input`. Ergebnisse sind Momentaufnahmen:
keine umfassende Anmelde-/Prozesshistorie und keine garantierte
Container-/Remote-Sicht. Tests dürfen keine realen Benutzer verändern.
Siehe [Session-Anleitung](commands/session-report.de.md) und
[Prozess-Anleitung](commands/process-report.de.md).

### Historischer technischer Review (Stand 13. Oktober 2026)

Repository: https://github.com/SASD-Sysadmin/freeware
Untersuchter main-Commit: `f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb`
Bestandsstichtag: 2026-10-13


> **Status:** Technische Bewertung und Planungsdokument, bereits im Repository versioniert. Geprüft wurden Repository-Baum, README, Changelog, Plattform- und Testdokumente, CI, Makefile sowie ausgewählte Implementierungen. Alle Risikobewertungen sind Engineering-Empfehlungen; nicht jeder denkbare Fehler wurde reproduziert.

### 1. Verifizierter Bestand

- **30 ausführbare Programme:** 28 unter `bin/`, 2 unter `sbin/`.
- **30 Manpages:** 28 unter `man/man1/`, 2 unter `man/man8/`.
- **50 Kommandodokumente** in `docs/commands/`: 25 englische und 25 deutsche; einige fassen mehrere Kommandos zusammen.
- **3 Perl-Module:** `Account.pm`, `External.pm`, `Walk.pm`.
- **Tests:** 12 Perl-Testsuiten, 1 Bash-Testskript, 1 optionale DNS-/LDAPS-Integrationssuite.
- **CI:** Ubuntu und macOS bestehen auf dem geprüften Merge-Commit die verpflichtenden Prüfungen. Ubuntu testet echte DNS- und LDAPS-Clients, macOS verpflichtend DNS; macOS-LDAPS wird explizit übersprungen.
- **Projektstatus:** MIT-Lizenz, Changelog unter `Unreleased`; keine veröffentlichten GitHub Releases bei der Abfrage.

#### Legende für Nebenwirkungen

`R` nur lokale Daten lesen; `N` lesende Prüfung mit Netzwerk-/Namensdienstzugriff; `W` schreibt Dateien nur in einer bestimmten Betriebsart bzw. bestimmungsgemäß; `P` privilegierte Änderung erst nach expliziter Bestätigung. Die Legende ist eine vereinfachte Betriebscharakterisierung, keine Garantie bei Systemfehlern oder missbräuchlicher Ausführung.

### 2. Vollständiges Kommando-Inventar

| Bereich | Kommando | Gegenwärtige Funktion | Verhalten |
|---|---|---|---|
| Filesystem | [`core-report`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/core-report) | Core-Dump-ähnliche Dateien und Größen | `R` |
| Filesystem | [`path-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/path-audit) | Pfadlängen prüfen | `R` |
| Filesystem | [`link-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/link-audit) | Defekte und zyklische symbolische Links | `R` |
| Filesystem | [`owner-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/owner-audit) | Unaufgelöste UID/GID feststellen | `R` |
| Filesystem | [`permission-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/permission-audit) | Weltweit beschreibbare Einträge finden | `R` |
| Filesystem | [`fs-report`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/fs-report) | Verzeichnisse und Dateigrößen erfassen | `R` |
| Filesystem | [`largefiles`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/largefiles) | Große Dateien finden | `R` |
| Filesystem | [`fs-usage`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/fs-usage) | Dateisystembelegung und Schwellwerte | `R` |
| Filesystem | [`suid-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/suid-audit) | SUID-/SGID-Dateien inventarisieren | `R` |
| Filesystem | [`file-integrity`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/file-integrity) | SHA-256-Baseline erzeugen/prüfen | `W*` |
| Identity | [`account-inventory`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/account-inventory) | Lokale/NSS-Konten erfassen | `R` |
| Identity | [`group-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/group-audit) | Gruppendatei validieren | `R` |
| Identity | [`home-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/home-audit) | Home-Verzeichnis-Metadaten prüfen | `R` |
| Identity | [`account-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/account-audit) | Kontodatei strukturell prüfen | `R` |
| Identity | [`account-manage`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/sbin/account-manage) | Linux Benutzer/Gruppen anlegen, Passwort sperren | `P` |
| Network | [`hosts-lint`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/hosts-lint) | Hosts-Datei strukturell prüfen | `R` |
| Network | [`nss-lookup`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/nss-lookup) | Benutzer/Gruppen einzeln über NSS auflösen | `R` |
| Network | [`host-resolve`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/host-resolve) | Vorwärts-/Rückwärtsauflösung über Systemresolver | `N` |
| Network | [`ldap-probe`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/ldap-probe) | Anonyme LDAPS-Root-DSE-Abfrage | `N` |
| Network | [`nsswitch-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/nsswitch-audit) | NSS-Konfigurationssyntax überprüfen | `R` |
| Network | [`dns-query`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/dns-query) | Direkte DNS-Abfrage mit dig | `N` |
| Network | [`nis-probe`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/nis-probe) | Lokale NIS/YP-Bindung prüfen | `N` |
| Network | [`ldap-config-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/ldap-config-audit) | OpenLDAP-TLS-Clientkonfiguration statisch prüfen | `R` |
| Network | [`tcp-check`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/tcp-check) | TCP-Erreichbarkeit testen | `N` |
| Quotas | [`quota-report`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/quota-report) | Quota-Berichte ausgeben | `R` |
| Quotas | [`quota-status`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/quota-status) | Linux-Quota-Aktivierung lesen | `R` |
| Quotas | [`quota-set`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/sbin/quota-set) | Quota-Grenzen unter Linux setzen | `P` |
| Logs/SSH | [`log-summary`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/log-summary) | Logs nach Schweregrad zählen | `R` |
| Logs/SSH | [`ssh-key-audit`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/ssh-key-audit) | OpenSSH authorized_keys prüfen | `R` |
| Backup | [`rotate`](https://github.com/SASD-Sysadmin/freeware/blob/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb/bin/rotate) | Zehn Sicherungsgenerationen einer Datei | `W` |

**Hinweis:** `file-integrity` ist in der Prüfart lesend und schreibt nur mit `--init` eine neue Baseline. `rotate` schreibt Sicherungsdateien. `account-manage` und `quota-set` verwenden gesonderte Apply-/Bestätigungsmodi; ihr sicherer Einsatz mit erhöhten Rechten muss getrennt betrachtet werden.

### 3. Abdeckungsbewertung nach Aufgabenfeldern

| Feld | Derzeitiger Stand | Sichtbare Lücke | Priorität |
|---|---|---|---|
| Dateisystem/Audit | Umfangreiches lesendes Inventar, Quotas, SHA-256-Baseline | Keine systematische Auswertung von Mounts, ACLs, Laufwerksgesundheit; SHA-256-Baseline kein Manipulationsschutz | P2 |
| Konten/Identitäten | Lokale Dateien, NSS, Homes, eingeschränkte Linux-Änderungen | Kein produktionsnaher privilegierter Integrationstest; keine umfassende LDAP-/AD-Verwaltung beabsichtigt | P0 |
| Namensdienste/Netzwerk | DNS, Systemresolver, NSS, LDAPS, NIS und TCP | Keine Übersicht über Interfaces, Routen, Firewallregeln; macOS LDAPS in CI nicht verpflichtend | P1/P2 |
| Prozesse/Dienste | TCP-Portprüfung | Keine Prozess-/Dienstinventur, kein Statusvergleich | P2 |
| Logs/Monitoring | Einfache Schweregradzählung, TCP und FS-Schwellen | Keine strukturierte Journal-/Syslog-Auswertung, keine historisierte Zustandsprüfung | P2 |
| Software/Updates | Nicht abgedeckt | Paketzustand, offene Updates, Vertrauens-/Signaturprüfung | P3 |
| Sicherung/Wiederherstellung | `rotate` für Einzeldateien | Keine vollständige Backup-/Restore-Pipeline; Rotationssequenz nicht transaktional | P1/P3 |
| Plattformen | Ubuntu-/macOS-CI; Debian/WSL lokal | Keine bestätigte FreeBSD-/OpenBSD-Kompatibilität oder reale Quota-/Account-Mutationsprüfung | P0/P3 |

### 4. Priorisierter Arbeitsplan

#### P0 – Vor der ersten als stabil beworbenen Version

1. **Wahrheitsgetreue Test-/Supportmatrix:** Dokumentation mit der CI abgleichen. Konkreter Befund: `docs/TESTING.de.md` erweckt den Eindruck, macOS-LDAPS werde bei vorhandenem Client zusätzlich geprüft; `.github/workflows/ci.yml` setzt derzeit `SASD_SKIP_LDAP_INTEGRATION=1` für macOS. Den Widerspruch korrigieren, nicht die Zertifikatsprüfung schwächen.
2. **Privilegierte Änderungsprogramme gezielt absichern:** Für `account-manage` und `quota-set` isolierte Linux-VM-Labore mit Snapshot, klarer Vorher-/Nachher-Prüfung, Rückbau, Nebenwirkungsprotokoll und bewusstem Opt-in definieren. Nicht blind auf dem Host oder in WSL echte Benutzer/Quotas verändern. Zunächst Testplan und Risikoanalyse, erst dann ausführbare Labore.
3. **Sicherheits- und Rückgabeverhalten dokumentieren:** Die Risiken privilegierter Programme in `SECURITY.md` explizit ergänzen; zwischen Lesestatus, Feststellung, Aufruffehler und fehlender Voraussetzung unterscheiden. Bestehende Sonderfälle wie `tcp-check --nagios` erhalten.
4. **Fehlersituationen nicht kaschieren:** Fehlende optionale Clients und bewusst übersprungene Tests in CI verständlich deklarieren; schreibende Pfade nur nach getrennter Freigabe.

**Abnahmekriterien P0:** Wahrheitsgemäße Matrix; geprüfte Dokumentationsverweise; nachweisbarer Plan für privilegierte Labore; keine stillen SKIPs bei verpflichtenden CI-Schritten; unveränderte sichere Standardmodi.

#### P1 – Pflege, CLI-Konventionen und Distribution

1. **CLI-Vertrag prüfen:** `--help`, `--version`, stderr, Exit-Codes, Maschinenformat/NUL-Modi; ältere Programme wie `rotate`, `file-integrity`, `ssh-key-audit` passen nicht durchgängig zum neueren Standard. Keine blinden Breaking Changes.
2. **Releasefähige Installation:** Versions-/Installationsmanifest für Paketinhalt; sichere Upgrade- und Uninstall-Semantik, damit nach Änderungen der Dateiliste keine alten installierten Dateien zurückbleiben. `DESTDIR`, `PREFIX`, Dateimodi und `man`-Integration regressionsprüfen.
3. **Qualitätsgates:** ShellCheck für Shell-Code ergänzen; fokussierte CI-Sicherheitsprüfung der Installationsdateiliste und Dokumentationslinks; Abhängigkeiten/Perl-Mindestversion pro Kommando deklarieren.
4. **Reproduzierbare Freigabe:** konsistente Versionskennzeichnung, Changelog bereinigen, Release-Checkliste und erste signierte/verifizierbare Quellcodefreigabe erwägen. Frühestens danach eine `v0.1.0`-Kennzeichnung für den klar definierten Umfang.

**Abnahmekriterien P1:** `make test`, Pflichtintegration, staged install/uninstall und neue Vertragsprüfungen grün; Release-Artefakt reproduzierbar; Supportmatrix benannt.

#### P2 – Neue Funktionen nur nach Abschluss der Basis

Empfohlene Reihenfolge (lesend und modular; **noch keine Implementierungsfreigabe**):

1. **Host- und Prozessinventur**: OS, Kernel, Last, Prozesse, Ressourcen – mit explizitem Hinweis, wenn `/proc` oder native Schnittstellen fehlen.
2. **Dienstezustand**: bestandsorientierte Statusabfrage für systemd unter Linux; erst später native macOS-/BSD-Backends. WSL ohne systemd muss sauber als eingeschränkt erkannt werden.
3. **Mount-/Storage-Überblick**: Mountpunkte, Dateisysteme, Quellen und nur verlässlich identifizierbare Zustandswerte.
4. **Netzwerkgrundlagen**: Interfaces, Adressen, Routen und reine Sicht auf lokale Konfiguration, nicht unerlaubtes Scannen.
5. **Logdiagnose**: optional lesender Journal-/Syslog-Adapter, begrenzte Datenmengen und Datenschutz.

Jedes neue Kommando: Definition des Zwecks, Abgrenzung zu OS-Bordmitteln, DE/EN-Anleitung, Manpage, Testmatrix, positive/negative Tests, Exit-Codes und Sicherheitshinweise **vor** dem Code.

#### P3 – Später und bewusst außerhalb der ersten Freigabe

- FreeBSD/OpenBSD-Betrieb und CI mit nativen Backends (PF, rc, pkg) getrennt von Linux-/macOS-Funktionen.
- Paket- und Updateprüfungen; Hardware-/SMART-/RAID-Health mit klar dokumentierten Abhängigkeiten.
- Wiederherstellbare Backup-Automatisierung mit unabhängigen Restore-Proben, Verschlüsselung und Off-Host-Kopien.
- Privilegierte schreibende Netzwerk-/Firewalloperationen erst mit gesondertem Sicherheitskonzept.

### 5. Konkrete nächste Meilensteine

| Reihenfolge | Meilenstein | Inhalt | Definition of Done |
|---|---|---|---|
| M0 | Bestandsaufnahme | Dieses Inventar und Prioritäten | 30 Programme zugeordnet; offene Risiken benannt |
| M1 | `quality-contracts` | Konsistenz von CLI, Dokumentation, Matrix und CI-SKIPs | Vertragstests grün, DE/EN synchron |
| M2 | `privileged-safety` | VM-Testplan und abgesicherte Apply-Regressionen | Snapshot-/Rollback-Anleitung; keine Tests am Produktivhost |
| M3 | `release-engineering` | Versions-/Installationsmanifest, Updates, Freigabeablauf | Reproduzierbare Install-/Uninstall-Prüfungen; RC möglich |
| M4 | `host-observability` | Maximal 1–2 fokussierte neue Lesewerkzeuge | Eigenständiger Scope, Cross-Platform-Fallback, Tests und Doku |
| M5 | `bsd-platforms` | BSD-Matrix nach Verfügbarkeit geeigneter Runner/VMs | Unterstützte Features ausdrücklich ausgewiesen |

Das war die Empfehlung der Oktober-2026-Analyse, nicht die aktuelle Arbeitsreihenfolge. Die aktuellen Produktprioritäten stehen in Abschnitt 2.

### 6. Nicht als erledigt bewertete Eigenschaften

- Grün unter Ubuntu/macOS bedeutet **nicht**, dass Quota- und Benutzeränderungen bereits auf echten Produktionssystemen geprüft wurden.
- Der lokale LDAP-Mock ist ein reduzierter Protokoll-Testdienst, kein OpenLDAP-Server.
- Die aktuelle Konfiguration garantiert noch keine Unterstützung von Solaris, FreeBSD oder OpenBSD.
- `file-integrity` ist keine gegen privilegierte Manipulation geschützte Ende-zu-Ende-Integritätslösung.
- Der Changelog steht auf `Unreleased`; keine voreilige Aussage über veröffentlichte `v1.0`.

### 7. Unmittelbarer nächster Schritt

Ohne Änderung an `main` die Aufgaben für **M1 (`quality-contracts`)** präzisieren und anschließend als kleinen, reviewbaren Feature-Branch bearbeiten. Bestehende Schnittstellen nur mit Migrationshinweisen ändern. Nach dem Push wie bisher Ubuntu- und macOS-CI prüfen; erst dann mergen.

### 8. Geprüfte Quellen

- [Repository und vollständiger Code](https://github.com/SASD-Sysadmin/freeware/tree/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb)
- [README.de.md](../README.de.md), [CHANGELOG.md](../CHANGELOG.md)
- [Entwicklungsrichtlinien](DEVELOPMENT.de.md), [Plattformen](PLATFORMS.de.md), [Integrationstests](TESTING.de.md), [Rückgabecodes](EXIT-CODES.de.md)
- [Makefile](../Makefile), [CI-Konfiguration](../.github/workflows/ci.yml), [Sicherheitsrichtlinie](../SECURITY.md)
- [GitHub-Actions-Hauptbranch-Lauf #13](https://github.com/SASD-Sysadmin/freeware/actions/runs/38394032369)

---

**Pflegeregel:** Nur `docs/ROADMAP.md` und `docs/ROADMAP.de.md` sind maßgebliche Roadmaps. Wesentliche Entscheidungen in beiden Sprachen pflegen. Historische Daten als datierte Abschnitte erhalten, nicht in neuen Fortsetzungsdateien. Release-Entscheidungen erfordern weiterhin gesonderte Evidenz und Autorisierung.
