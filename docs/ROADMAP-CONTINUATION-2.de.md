# SASD Freeware – Zweite Fortsetzungs-Roadmap

[English](ROADMAP-CONTINUATION-2.md) · [Projekt](../README.de.md) · [Agentenregeln](AGENTS.md) · [Bisherige Roadmap](ROADMAP.de.md) · [Release-Gaps](RELEASE-GAPS.de.md)

**Erstellt:** 7. November 2026. **Status:** versionierte Fortsetzungsplanung auf Basis einer erneuten Bestandsprüfung; keine Produktfreigabe und keine pauschale Implementierungsfreigabe für alle aufgeführten Funktionen.

## 1. Zweck, Geltung und Ausgangspunkt

Diese zweite Roadmap ergänzt die kapitelorientierte Planung und trennt vier Fragen:

1. Welche Aufgaben des Buches sind durch heutige Werkzeuge fachlich abgedeckt?
2. Welche Funktionen fehlen oder wurden bewusst enger umgesetzt?
3. Welche Fehler und Dokumentationswidersprüche wurden tatsächlich gefunden?
4. Welche Praxis-, Wiederherstellungs- und Release-Nachweise fehlen noch?

Das Referenzwerk ist **David N. Blank-Edelman, Perl for System Administration, O'Reilly, erste Ausgabe Juli 2000, ISBN 1-56592-609-9**. Die zweite Ausgabe unter dem Titel *Automating System Administration with Perl* wurde nicht vollständig geprüft und ist kein stillschweigend eingeschlossener Anforderungskatalog.

Die ursprüngliche [Roadmap](ROADMAP.de.md) und ihre historischen Abschnitte bleiben erhalten. Für die in diesem Dokument erfassten Fortsetzungsarbeiten gilt dieses Dokument als jüngere Planung. Bestehende CLI-Verträge, Sicherheitsgrenzen und Release-Gap-Definitionen werden dadurch nicht aufgehoben. Kennungen `FR2-*` sind neue Planungskennungen, keine rückwirkende Umbenennung von M9 oder M10.

**Quellenstand:** `main` bei der Prüfung: `337b7cff34c2818921d1df023f3c5e2d386301c8`; zugehöriger Tree: `c2b953e454b80014e59322f2cd2f56840351b9ef`. Vor späteren Änderungen HEAD und CI erneut prüfen. Diese Dokumentation verändert keine Laufzeitfunktion und schließt kein Release-Gate.

## 2. Quellen und Grenzen der Prüfung

### 2.1 Quellenrangfolge

- Aktueller Code, Testfälle und GitHub-Metadaten für einen bestimmten Commit.
- Gültige Verträge in Guides, Manpages, Makefile und CI.
- Originales Buchinhaltsverzeichnis und zugängliche Verlagsabschnitte.
- Datierte Betreiberprotokolle mit erkennbarer Umgebung und Herkunft.
- Historische Roadmaps und Chat-Zusammenfassungen als ergänzender Kontext.

Bei Widersprüchen den konkreten Befund dokumentieren; keine Quelle allein wegen ihres Datums ungeprüft zur Wahrheit erklären. Ein älterer Betreiberbericht kann weiterhin ein gültiger Teilnachweis sein, ohne den heutigen Commit vollständig abzunehmen.

### 2.2 Prüfumfang und ausdrücklich nicht bewiesene Eigenschaften

Alle 334 versionierten Dateien des Ausgangscommits wurden abgerufen und ihr Inhalt gegen die Git-Blob-SHAs verglichen; keine Abweichung. Programme, Module, Tests und Dokumentation wurden inventarisiert und auf fachliche Gegenstücke untersucht. Das ist keine vollständige formale Sicherheitsprüfung jeder Codezeile und kein Vergleich jedes ursprünglichen Buchlistings.

Die Buchbewertung beruht auf dem ausführlichen Verlagsinhaltsverzeichnis und zugänglichen Abschnitten. Unterpunktgenaue Anforderungen, Alternativverfahren und mögliche bewusste Ausschlüsse müssen in FR2-01 nachgetragen werden. Aus einer fehlenden Erwähnung im README allein wurde keine fehlende Funktion abgeleitet.

Die temporären Prüfkopien waren kein vollständiger Git-Checkout. Deshalb war die lokale Git-Index-Prüfung nicht Teil der unten genannten Testausführung. Der Inhalt war anhand der Blob-SHAs verifiziert; Git-Dateimodi wurden aus dem Tree übernommen. Das ersetzt keine spätere Prüfung eines echten Checkouts.

### 2.3 Verbindliche Evidenzbegriffe

| Begriff | Bedeutung |
| --- | --- |
| Code-bestätigt | Verhalten/Fehlen anhand benannter Implementierung und Schnittstelle festgestellt |
| Lokal reproduziert | Im isolierten temporären Prüfbaum tatsächlich ausgeführt; Umgebung und Methode benennen |
| CI-bestätigt | Erfolgreicher konkreter Lauf für genau den genannten SHA |
| Betreiberbericht | Von einem Menschen berichtete Praxis; nicht automatisch unabhängig wiederholt |
| Geplant | Noch nicht implementiert oder abgenommen |
| Nicht nachgewiesen | Ausreichender Beleg fehlt in den geprüften Quellen; keine Behauptung, es habe nie einen Test gegeben |
| Ausgeschlossen | Begründeter, versionierter Scope-Beschluss mit verantwortlicher Entscheidung |

## 3. Baseline und tatsächlich ausgeführte Prüfungen

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

## 4. Buchabdeckung: Unterschiede nach Kapiteln

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

### 4.1 Fachliche Gleichwertigkeit statt bloßer Modulgleichheit

Native SQL-Clients statt DBI sind eine Architekturentscheidung, kein automatischer Fehler. Entsprechendes gilt für eigene Traversierung statt bestimmter Buchmodule. Bewertet wird der administrative Anwendungsfall mit Grenzen und Nachweisen, nicht das Vorkommen eines Modulnamens.

ACL-/Mountübersichten, PostgreSQL-Storage, Oracle-Anbindung, vollständige Firewallbewertung und moderne Linux-Verteilungsnachweise sind Projektideen beziehungsweise Erweiterungen. Sie dürfen nicht ohne Buchbeleg zu ursprünglichen Pflichtanforderungen erklärt werden. Insbesondere nennt das geprüfte SQL-Inhaltsverzeichnis MySQL, Sybase und Microsoft SQL Server; Oracle ist daraus nicht als Pflicht abzuleiten.

### 4.2 Historische und sicherheitsrelevante Themen

Windows NT/2000, klassisches Mac OS, ADSI, NIS+, WINS und RCS sind keine automatisch zu implementierenden modernen Produktziele. Für jedes Thema eine Entscheidung `modernisieren`, `übernehmen`, `verschieben` oder `ausschließen` mit Begründung dokumentieren. Finger/WHOIS, Paketmitschnitt, LDAP-Schreibpfade und Benutzerdatenverarbeitung benötigen zusätzlich konkrete Nutzungs-/Datenschutzgrenzen. Ein Scope-Ausschluss ist keine erfolgreiche Implementierung.

## 5. Bestätigte Befunde und Abgrenzungen

| ID | Befund / Nachweis | Erforderliche Folgerung |
| --- | --- | --- |
| FR2-F01 | Uninstall löscht nach Preflight sequenziell; deterministischer Fehler bei zweiter Löschung ließ erste Datei fehlen, zweite und Manifest bestehen. Wiederholung verweigerte mit `installed file changed or missing; refusing: bin/alpha`. Siehe `tools/installation.pl`, Uninstall-Zweig. | Wiederanlauf-/Recovery-Vertrag entwerfen und regressionsprüfen; kein pauschales Entfernen fehlender Manifestzeilen |
| FR2-F02 | README nennt Perl 5.8 pauschal; `bin/file-integrity` nutzt `//`, andere Werkzeuge benötigen neuere APIs/Module. | Geprüfte Mindestversion und Abhängigkeiten pro unterstützt ausgeliefertem Umfang bestimmen |
| FR2-F03 | `mail-probe` unterstützt weder IPv6 noch implizites SMTPS/465; Guides bestätigen dies. | Funktionslücke, keine bloß fehlende Abnahme; Erweiterung oder ausdrücklichen Scope-Ausschluss planen |
| FR2-F04 | Vollständiges Staging installierte 257 Dateien, aber keine `LICENSE` unter dem Präfix. Installer-Auswahl enthält sie nicht. | Ausgelieferten Lizenz-/Hinweisumfang prüfen; Einbeziehung muss Manifest, Upgrade und Uninstall berücksichtigen |
| FR2-F05 | Keine ausdrückliche Nennung von Autor, Verlag oder Buchtitel in der repositoryweiten Suche vor diesem Slice; keine unterpunktgenaue Zuordnung. | Herkunft und fachliche Zuordnung dokumentieren; tatsächliche Codeübernahmen getrennt prüfen |
| FR2-F06 | Audit erzeugt sieben MANUAL-Zeilen bedingungslos. | Nicht als sieben gescheiterte oder nachweislich nie ausgeführte Tests ausgeben |
| FR2-F07 | Historische Planung enthält überholte Bestandszahlen und nächste Schritte. | Datierte Historie erhalten, aktuelle Fortsetzung deutlich verlinken; keine alte Empfehlung ungeprüft ausführen |

### 5.1 Reproduktionsvertrag zu FR2-F01

Das Review verwendete ausschließlich eine temporäre Quelle und ein temporäres DESTDIR. Die Quelle enthielt `bin/alpha` und `bin/beta` als ausführbare reguläre Dateien sowie die vom Installer erwarteten leeren Abschnittsverzeichnisse. Nach erfolgreicher Installation wurde im separaten Perl-Prozess `CORE::GLOBAL::unlink` vor Laden des Installers überschrieben: für `bin/beta` wurde ein Fehler ausgelöst, für andere Pfade an `CORE::unlink` delegiert. Wegen `FindBin` im Wrapper wurde `tools/lib` explizit zum Modulpfad hinzugefügt.

Vor dem Wiederholungsversuch wurden unabhängig Dateiexistenz und Manifest erfasst: alpha fehlte, beta und Manifest waren vorhanden. Anschließend scheiterte der normale Uninstall-Start bereits im Preflight an alpha. Eine künftige Regression soll diesen Vertrag als isolierten Test abbilden, nicht die Produktimplementierung mit einem Produktions-Fault-Injection-Schalter versehen. Dies ist keine Simulation eines Stromausfalls, kein echter SIGKILL und keine native VM-Abnahme.

### 5.2 Bekannte Grenzen sind nicht automatisch neue Defekte

- Installer: kooperativer Lock, keine Sperre fremder Schreiber; kein fsync-/Stromausfallprotokoll, keine atomare Crash-Recovery.
- `text-eol-normalize`: eingeschränkte Metadatenübernahme; Inode/Zeiten ändern sich; ACLs/Xattrs und gleichzeitige Schreiber brauchen ausdrücklichen Scope.
- `file-integrity`: Inhaltsprüfsummen, keine vollständige Metadaten- oder signierte Vertrauenskette.
- Firewallberichte: begrenzte quellenspezifische Aussagen, kein Beweis wirksamen Gesamtschutzes.
- `password-lock`: sperrt Passwortauthentifizierung, entzieht keine SSH-Schlüssel oder laufenden Sitzungen.
- Netzwerkdiensteinventar: Listener/UDP-Bindungen, keine PID-/Benutzer-/Programmzuordnung oder vollständige Verbindungshistorie.

## 6. Abnahmeregister: vorhandene und fehlende Belege

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

## 7. Geordnete Arbeitspakete

P0 bedeutet hier Basisarbeit vor der ersten entsprechend beworbenen Freigabe; nicht alle späteren Buchergänzungen sind Releaseblocker. Kein Paket legitimiert nebenbei produktive Systemänderungen.

| Paket | Priorität | Umfang / Liefergegenstand | Abhängigkeit und Abschluss |
| --- | --- | --- | --- |
| **FR2-00** | P0 Planung | Diese DE/EN-Fortsetzung, Root-AGENTS und Navigation | Dokumentationsprüfungen; keine Laufzeitänderung und kein Gate automatisch schließen |
| **FR2-01** | P0 Scope | Unterpunktgenaue Buch-/Projekt-Abdeckungsmatrix | Entscheidungen über moderne Entsprechung und Ausschlüsse; alle relevanten Unterpunkte erhalten Status, Quelle, Code, Test und Akzeptanz |
| **FR2-02** | P0 Qualität | Perl-/Modul-/Client-Mindestversionen korrigieren (F02) | Keine beliebige Versionsanhebung; saubere Testumgebung für gewählte Untergrenze, beide Sprachen und Fehlerfälle konsistent |
| **FR2-03** | P0 Sicherheit | Uninstall-Fehlerzustand und Recovery-Vertrag (F01) | Zuerst isolierte Regression; neue Strategie schützt fremde/veränderte Daten, Manifest, Backups und Lock; Recovery-Nachweise |
| **FR2-04** | P0 Herkunft | Buchhinweis, tatsächliche Übernahmen und ausgelieferte Lizenzhinweise (F04/F05) | Rechte prüfen, nicht aus Buchbesitz ableiten; falls LICENSE installiert wird: Manifest-/Upgrade-/Konflikt-/Uninstalltests |
| **FR2-05** | P0 Evidenz | Versionierte Nachweisstruktur und Quellenzuordnung | Bestehende Standards prüfen; WSL als Teilnachweis erfassen; Audit-MANUAL-Semantik korrekt erklären |
| **FR2-06** | P0 Abnahme | RG-01/RG-04 in geeigneter Snapshot-VM und RG-02/RG-03 für festgelegten Umfang | Erst 02–05 soweit relevant; getrennte Betreiberfreigaben; bewusste Ausschlüsse versionieren; Release separat autorisieren |
| **FR2-10** | P1 Nutzen | Hosts-/DNS-Generierung, zunächst nur in Ausgabeverzeichnis | Nach 01; kanonisches Datenmodell, deterministische Ausgabe, semantische Prüfung; kein automatisches Schreiben nach /etc oder Reload |
| **FR2-11** | P1 Nutzen | LDAP allgemein lesend, danach getrennt schreibend | Nach 01; Bind-/TLS-/Filter-/Secret-Vertrag; Suchphase vor Schreibphase; reale Labore für Änderungen |
| **FR2-12** | P1 Nutzen | Administrativer Mailversand mit Drosselung/Deduplizierung | Nach 01; getrennt von mail-probe; nur lokaler Test-Sink, keine echten Empfänger in Tests |
| **FR2-13** | P1 Nutzen | Zustandsbehaftete Logs und Service-Baselinevergleich | Nach 01; stabile Zustandsformate, atomische Publikation, Sperren, verlässliche Zeit-/Dublettenregeln |
| **FR2-14** | P1 Nutzen | SNMP zunächst lesend | Nach 01; SNMPv3 Auth/Privacy als Ziel, geschützte Secrets, Timeouts und begrenzte OID-/Walk-Mengen |
| **FR2-20** | P2 Ausbau | Kontenlebenszyklus und optional zentrale Datenhaltung | Nach 01 und RG-01-Vertrag; Import-/Planmodell vor Schreibpfad; Löschung und Datenaufbewahrung gesondert entscheiden |
| **FR2-21** | P2 Ausbau | SQL-Umfang und zusätzliche Engines | Fachlichen Bedarf wählen; PostgreSQL-Storage/Sybase/MS-SQL getrennte Slices; kein Modulwechsel ohne Nutzen |
| **FR2-22** | P2 Ausbau | Mail-Eingang/MIME/Mailbox und Support-Abläufe | Lokale Fixtures, Größen-/Encoding-/Datenschutzgrenzen; keine ungefragte Postfachverbindung |
| **FR2-23** | P2 Ausbau | IPv6 und implizites SMTPS in mail-probe | Getrennte Protokollpfade und positive/negative TLS-Tests; keine Abschwächung bestehender Prüfung |
| **FR2-24** | P2 Ausbau | Mount/ACL/Storage und moderne native Adapter | Projektanforderung belegen; Plattform-/Metadatenmatrix, native Abnahme, lesender Start |
| **FR2-25** | P2 optional | Datei-/Netzwerkoperationsverfolgung und Paketmitschnitt | Nur begründeter Auftrag; Berechtigungen, Datenminimierung, Limits und isolierte Labore vorher definieren |
| **FR2-30** | P3 Entscheidung | Historische Plattformen/Protokolle und Anhänge | Übernahme/Modernisierung/Ausschluss pro Thema; keine pauschale Buchkopie |

### 7.1 Empfohlene Ausführung

1. FR2-01 als nächsten fachlichen Dokumentationsslice erstellen; parallel dazu keine ungeprüften Großfunktionen beginnen.
2. FR2-02, FR2-03 und FR2-04 jeweils getrennt entwickeln und prüfen. Sie dürfen technisch unabhängig bearbeitet werden; daraus folgt kein Auftrag zur Agentendelegation.
3. FR2-05 strukturiert die vorhandenen Belege; FR2-06 behandelt echte verbleibende manuelle Gates. Verfügbare sichere Arbeiten weiterführen, wenn gerade keine VM verfügbar ist.
4. Nach Scope-Entscheidung zunächst FR2-10, dann lesendes FR2-11 und FR2-12 erwägen; FR2-13/14 nach konkretem Administrationsnutzen einordnen.
5. P2/P3-Pakete erst nach Bedarf und getrenntem Auftrag. Ein bewusst kleiner Releaseumfang kann früher freigegeben werden; Buchvollständigkeit darf daraus nicht abgeleitet werden.

Ein Runtime-Fix darf nach dieser Planung nicht ohne neue CI-Eingangsprüfung beginnen. Diese Roadmap setzt keinen Termin, erstellt keine Tags und beschließt keine .deb-/ .rpm-Paketierung. Paketformate bleiben spätere Entscheidungen.

## 8. Verbindliche Paketverträge

### FR2-01: Abdeckungsmatrix

Pro Zeile mindestens: ID, Ausgabe/Kapitel/Unterabschnitt, Quelle, administrativer Anwendungsfall, gewünschte heutige Entsprechung, vorhandene Implementierung, Tests, Plattformgrenzen, Nebenwirkungen, Status, Entscheidung und verbleibender Nachweis. Zustände: `nicht bewertet`, `teilweise`, `implementiert`, `abgenommen`, `zurückgestellt`, `ausgeschlossen`. Implementierung und Abnahme getrennt führen. Keine Prozentangabe ohne definierten Nenner; keine Gesamtfertigmeldung allein aus vertretenen Kapitelüberschriften.

### FR2-03: Recovery

Fehler vor erster Löschung, nach mindestens einer Löschung, beim Manifest und beim Cleanup prüfen. Strategie darf transaktionale Sicherung oder dokumentiertes resumierbares Verfahren sein; Entscheidung in einem kurzen ADR begründen. Tests für veränderte/fremde Dateien, fehlende Dateien, erneuten Aufruf, konkurrierende Prozesse und Rechtefehler. Keine automatischen Vermutungen aus einer unvollständigen Installation; keine Backups/Lockdateien zum Entsperren löschen. Das spätere native Abbruchlabor bleibt ein gesonderter Nachweis.

### FR2-10 bis FR2-14: neue produktive Funktionen

Vor Code: klarer Zweck, Scope, Beispielausgabe, Exit-Codes, Abhängigkeiten, Nichtziele und Teststrategie. Trennung von CLI, Beschaffung/Backend, reinem Parser/Modell und Präsentation soweit sinnvoll. Datenformate versionieren, Secrets nicht in argv oder Logs, Netzwerkziele ausdrücklich wählen, Laufzeiten/Mengen begrenzen. Keine unaufgeforderten Änderungen an DNS, LDAP, Mail oder Überwachungszielen.

## 9. Abschlusskriterien pro Slice und für die Fortsetzung

Jeder Slice braucht einen kleinen nachvollziehbaren Diff, passende positive/negative Tests, konsistente DE/EN-Guides/Manpages bei CLI-Änderungen, aktualisierten Changelog und Evidenzgrenzen. `make test` gemäß CONTRIBUTING in geeignetem nichtprivilegiertem Checkout; weitere Tests nach betroffenem Verhalten. Nicht ausführbare Markdown-Dateien im Git-Index (`100644`) und ausführbare Programme (`100755`) kontrollieren.

Für einen Release nur den tatsächlich freigegebenen Umfang abnehmen; RG-P0 schließen oder begründeten verantwortlichen Scope-Ausschluss dokumentieren. Fehlende Native-Nachweise nicht durch Fixtures umetikettieren. Für die Aussage einer abgeschlossenen modernen Buchumsetzung müssen zusätzlich alle relevanten Matrixzeilen abgenommen oder ausdrücklich ausgeschlossen sein und die Ausschlüsse sichtbar zur Aussage gehören.

## 10. Quellen und Pflege

- [Originalbuch und ausführlicher Inhalt](https://www.oreilly.com/library/view/perl-for-system/1565926099/)
- [Kontensystem](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch03s03.html), [DNS](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch05s03.html), [LDAP](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch06s04.html), [Mail](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch08.html), [Sicherheit/Netzwerk](https://www.oreilly.com/library/view/perl-for-system/1565926099/ch10.html)
- [Geprüfter Ausgangscommit](https://github.com/SASD-Sysadmin/freeware/commit/337b7cff34c2818921d1df023f3c5e2d386301c8)
- [Release Engineering](RELEASE-ENGINEERING.de.md), [Sicherheit privilegierter Aktionen](PRIVILEGED-SAFETY.de.md), [Plattformen](PLATFORMS.de.md), [Tests](TESTING.de.md), [Entwicklung](DEVELOPMENT.de.md)

Neue Erkenntnisse unter stabilen FR2-Kennungen ergänzen. Korrekturen als solche benennen und EN/DE synchron halten. Historische Testzahlen nicht als aktuelle Ergebnisse weiterreichen. Diese Planung ist eine überprüfbare Grundlage, keine Garantie, dass bei einer einmaligen Prüfung sämtliche Fehler entdeckt wurden.
