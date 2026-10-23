# SASD Freeware – Bestandsaufnahme und priorisierte Roadmap

## Aktuelle kapitelorientierte Planung (14. Oktober 2026)

**Ziel:** Die Werkzeuge zu den Buchkapiteln 2–10 systematisch ergänzen.
Der frühere technische Review (weiter unten) ist eine historische Bestandsaufnahme,
**nicht** mehr die aktuelle Meilensteinreihenfolge. Der Installer aus M3 Teil 1 ist
implementiert; Release-Artefakte und eine Veröffentlichung bleiben bewusst zurückgestellt.
Ein Kapitel gilt erst als abgeschlossen, wenn Anforderungen, Plattformgrenzen,
DE/EN-Anleitungen, Manpages und negative/positive Tests geprüft wurden.

| Kapitel | Bereits verfügbare Schwerpunkte | Noch zu bearbeiten | Status |
| --- | --- | --- | --- |
| **2 – Filesystem** | Inventar, Berechtigungen, Links, Quotas, Integrität | Mounts, ACLs und Storage-Analyse bewerten | Gut ausgebaut, offen |
| **3 – User Accounts** | Konten, Gruppen, Home-Audit, eingeschränkte Verwaltung | Privilegierte VM-Abnahme, weitere Abdeckungsprüfung | Gut ausgebaut, offen |
| **4 – User Activity** | `session-report`, `process-report`; `login-audit` (Linux `last`/`lastb`) | macOS-Anmeldehistorie, Zuordnung und Vollständigkeit prüfen | In Arbeit |
| **5 – TCP/IP Name Services** | Hosts, DNS, NSS, Resolver | Abschlussprüfung und sinnvolle Ergänzungen | Gut ausgebaut, offen |
| **6 – Directory Services** | LDAPS/NIS-Diagnose, TLS-Konfigurationsaudit | Funktions-/Plattformgrenzen und offene Aufgaben prüfen | Teilweise |
| **7 – SQL Administration** | `db-probe` (M5.1), `db-health` (M5.2), `db-activity` (M5.3) für PostgreSQL/MySQL/MariaDB; MariaDB-/MySQL-`db-storage` (M5.4) | PostgreSQL-Storage, Oracle/SQL Server, MySQL-Sperrgraph, Wachstumsmessungen und echte übergreifende Integrationstests | In Arbeit |
| **8 – Electronic Mail** | `mail-probe` (M6.1), `mail-queue` (M6.2), `mail-config-audit` (M6.3), Offline-Workflow (M6.4); [manueller Teil-Praxistest](MAIL-ACCEPTANCE.de.md) auf Debian 12/Postfix 3.7.11 am 20.10.2026 | Wirksame Service-Overrides, gefüllte Queue, isolierte VM, IPv6/465 und andere Plattformen offen | Technischer Umfang M6 umgesetzt, Betriebslücken offen |
| **9 – Log Files** | `log-summary` (Text), `journal-summary` (M7.1 JSONL), `syslog-summary` (M7.2 Syslog-Struktur), `ssh-auth-summary` (M7.3 offline SSHD), `auth-event-summary` (M7.4 offline sudo/su/PAM), `log-summary-normalize` (M7.5 prüfbare JSONL-Zählberichte) | Native Adapter, weitere PAM-Dienste, macOS Unified Log, echte Ereigniskorrelation und plattformbezogene Vollständigkeitsprüfung | In Arbeit |
| **10 – Security and Network Monitoring** | SSH-, SUID-, Integritäts- und TCP-Prüfungen; `network-interface-report` (M8.1); `network-route-report` (M8.2); `network-service-report` (M8.3); `firewall-config-audit` (M8.4.1 begrenzte Linux-UFW/nftables/iptables-Quellenprüfung) | Firewall-Adapter für BSD/Solaris/HP-UX/IRIX, vollständige Firewall-Regelbewertung, Prozesszuordnung, Policy Routing, erweiterte Next-Hops und native Plattformabnahme | M8 in Arbeit |

**Geplante Reihenfolge:** M4 User Activity (zunächst aktuelle Sessions/Prozesse,
danach Anmeldehistorie), M5 SQL, M6 Mail, M7 Logs, M8 Sicherheit und Netzwerk,
M9 Kapitel-Lücken und plattformbezogene Qualitätsabnahme, M10 Release-Artefakte.
Diese Reihenfolge ist eine Arbeitsplanung, keine Aussage über Produktreife oder Termine.

**M4 Teil 1 – Prüfumfang:** `session-report` nutzt `who`, `process-report` nutzt
`ps`; beide sind lesend, brauchen keine Root-Rechte und unterstützen
synthetische Eingaben über `--input`. Ergebnisse sind Momentaufnahmen:
keine umfassende Anmelde-/Prozesshistorie und keine garantierte
Container-/Remote-Sicht. Tests dürfen keine realen Benutzer verändern.
Siehe [Session-Anleitung](commands/session-report.de.md) und
[Prozess-Anleitung](commands/process-report.de.md).

## Historischer technischer Review (Stand 13. Oktober 2026)

Repository: https://github.com/SASD-Sysadmin/freeware
Untersuchter main-Commit: `f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb`
Bestandsstichtag: 2026-10-13


> **Status:** Technische Bewertung und Planungsdokument, bereits im Repository versioniert. Geprüft wurden Repository-Baum, README, Changelog, Plattform- und Testdokumente, CI, Makefile sowie ausgewählte Implementierungen. Alle Risikobewertungen sind Engineering-Empfehlungen; nicht jeder denkbare Fehler wurde reproduziert.

## 1. Verifizierter Bestand

- **30 ausführbare Programme:** 28 unter `bin/`, 2 unter `sbin/`.
- **30 Manpages:** 28 unter `man/man1/`, 2 unter `man/man8/`.
- **50 Kommandodokumente** in `docs/commands/`: 25 englische und 25 deutsche; einige fassen mehrere Kommandos zusammen.
- **3 Perl-Module:** `Account.pm`, `External.pm`, `Walk.pm`.
- **Tests:** 12 Perl-Testsuiten, 1 Bash-Testskript, 1 optionale DNS-/LDAPS-Integrationssuite.
- **CI:** Ubuntu und macOS bestehen auf dem geprüften Merge-Commit die verpflichtenden Prüfungen. Ubuntu testet echte DNS- und LDAPS-Clients, macOS verpflichtend DNS; macOS-LDAPS wird explizit übersprungen.
- **Projektstatus:** MIT-Lizenz, Changelog unter `Unreleased`; keine veröffentlichten GitHub Releases bei der Abfrage.

### Legende für Nebenwirkungen

`R` nur lokale Daten lesen; `N` lesende Prüfung mit Netzwerk-/Namensdienstzugriff; `W` schreibt Dateien nur in einer bestimmten Betriebsart bzw. bestimmungsgemäß; `P` privilegierte Änderung erst nach expliziter Bestätigung. Die Legende ist eine vereinfachte Betriebscharakterisierung, keine Garantie bei Systemfehlern oder missbräuchlicher Ausführung.

## 2. Vollständiges Kommando-Inventar

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

## 3. Abdeckungsbewertung nach Aufgabenfeldern

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

## 4. Priorisierter Arbeitsplan

### P0 – Vor der ersten als stabil beworbenen Version

1. **Wahrheitsgetreue Test-/Supportmatrix:** Dokumentation mit der CI abgleichen. Konkreter Befund: `docs/TESTING.de.md` erweckt den Eindruck, macOS-LDAPS werde bei vorhandenem Client zusätzlich geprüft; `.github/workflows/ci.yml` setzt derzeit `SASD_SKIP_LDAP_INTEGRATION=1` für macOS. Den Widerspruch korrigieren, nicht die Zertifikatsprüfung schwächen.
2. **Privilegierte Änderungsprogramme gezielt absichern:** Für `account-manage` und `quota-set` isolierte Linux-VM-Labore mit Snapshot, klarer Vorher-/Nachher-Prüfung, Rückbau, Nebenwirkungsprotokoll und bewusstem Opt-in definieren. Nicht blind auf dem Host oder in WSL echte Benutzer/Quotas verändern. Zunächst Testplan und Risikoanalyse, erst dann ausführbare Labore.
3. **Sicherheits- und Rückgabeverhalten dokumentieren:** Die Risiken privilegierter Programme in `SECURITY.md` explizit ergänzen; zwischen Lesestatus, Feststellung, Aufruffehler und fehlender Voraussetzung unterscheiden. Bestehende Sonderfälle wie `tcp-check --nagios` erhalten.
4. **Fehlersituationen nicht kaschieren:** Fehlende optionale Clients und bewusst übersprungene Tests in CI verständlich deklarieren; schreibende Pfade nur nach getrennter Freigabe.

**Abnahmekriterien P0:** Wahrheitsgemäße Matrix; geprüfte Dokumentationsverweise; nachweisbarer Plan für privilegierte Labore; keine stillen SKIPs bei verpflichtenden CI-Schritten; unveränderte sichere Standardmodi.

### P1 – Pflege, CLI-Konventionen und Distribution

1. **CLI-Vertrag prüfen:** `--help`, `--version`, stderr, Exit-Codes, Maschinenformat/NUL-Modi; ältere Programme wie `rotate`, `file-integrity`, `ssh-key-audit` passen nicht durchgängig zum neueren Standard. Keine blinden Breaking Changes.
2. **Releasefähige Installation:** Versions-/Installationsmanifest für Paketinhalt; sichere Upgrade- und Uninstall-Semantik, damit nach Änderungen der Dateiliste keine alten installierten Dateien zurückbleiben. `DESTDIR`, `PREFIX`, Dateimodi und `man`-Integration regressionsprüfen.
3. **Qualitätsgates:** ShellCheck für Shell-Code ergänzen; fokussierte CI-Sicherheitsprüfung der Installationsdateiliste und Dokumentationslinks; Abhängigkeiten/Perl-Mindestversion pro Kommando deklarieren.
4. **Reproduzierbare Freigabe:** konsistente Versionskennzeichnung, Changelog bereinigen, Release-Checkliste und erste signierte/verifizierbare Quellcodefreigabe erwägen. Frühestens danach eine `v0.1.0`-Kennzeichnung für den klar definierten Umfang.

**Abnahmekriterien P1:** `make test`, Pflichtintegration, staged install/uninstall und neue Vertragsprüfungen grün; Release-Artefakt reproduzierbar; Supportmatrix benannt.

### P2 – Neue Funktionen nur nach Abschluss der Basis

Empfohlene Reihenfolge (lesend und modular; **noch keine Implementierungsfreigabe**):

1. **Host- und Prozessinventur**: OS, Kernel, Last, Prozesse, Ressourcen – mit explizitem Hinweis, wenn `/proc` oder native Schnittstellen fehlen.
2. **Dienstezustand**: bestandsorientierte Statusabfrage für systemd unter Linux; erst später native macOS-/BSD-Backends. WSL ohne systemd muss sauber als eingeschränkt erkannt werden.
3. **Mount-/Storage-Überblick**: Mountpunkte, Dateisysteme, Quellen und nur verlässlich identifizierbare Zustandswerte.
4. **Netzwerkgrundlagen**: Interfaces, Adressen, Routen und reine Sicht auf lokale Konfiguration, nicht unerlaubtes Scannen.
5. **Logdiagnose**: optional lesender Journal-/Syslog-Adapter, begrenzte Datenmengen und Datenschutz.

Jedes neue Kommando: Definition des Zwecks, Abgrenzung zu OS-Bordmitteln, DE/EN-Anleitung, Manpage, Testmatrix, positive/negative Tests, Exit-Codes und Sicherheitshinweise **vor** dem Code.

### P3 – Später und bewusst außerhalb der ersten Freigabe

- FreeBSD/OpenBSD-Betrieb und CI mit nativen Backends (PF, rc, pkg) getrennt von Linux-/macOS-Funktionen.
- Paket- und Updateprüfungen; Hardware-/SMART-/RAID-Health mit klar dokumentierten Abhängigkeiten.
- Wiederherstellbare Backup-Automatisierung mit unabhängigen Restore-Proben, Verschlüsselung und Off-Host-Kopien.
- Privilegierte schreibende Netzwerk-/Firewalloperationen erst mit gesondertem Sicherheitskonzept.

## 5. Konkrete nächste Meilensteine

| Reihenfolge | Meilenstein | Inhalt | Definition of Done |
|---|---|---|---|
| M0 | Bestandsaufnahme | Dieses Inventar und Prioritäten | 30 Programme zugeordnet; offene Risiken benannt |
| M1 | `quality-contracts` | Konsistenz von CLI, Dokumentation, Matrix und CI-SKIPs | Vertragstests grün, DE/EN synchron |
| M2 | `privileged-safety` | VM-Testplan und abgesicherte Apply-Regressionen | Snapshot-/Rollback-Anleitung; keine Tests am Produktivhost |
| M3 | `release-engineering` | Versions-/Installationsmanifest, Updates, Freigabeablauf | Reproduzierbare Install-/Uninstall-Prüfungen; RC möglich |
| M4 | `host-observability` | Maximal 1–2 fokussierte neue Lesewerkzeuge | Eigenständiger Scope, Cross-Platform-Fallback, Tests und Doku |
| M5 | `bsd-platforms` | BSD-Matrix nach Verfügbarkeit geeigneter Runner/VMs | Unterstützte Features ausdrücklich ausgewiesen |

Diese Reihenfolge minimiert Regressionsrisiko; sie ist **keine Zusage eines festen Fertigstellungstermins**. M0 ist mit dieser Analyse abgeschlossen. M1 sollte die nächste Code-Arbeit sein, keine neue Feature-Liste.

## 6. Nicht als erledigt bewertete Eigenschaften

- Grün unter Ubuntu/macOS bedeutet **nicht**, dass Quota- und Benutzeränderungen bereits auf echten Produktionssystemen geprüft wurden.
- Der lokale LDAP-Mock ist ein reduzierter Protokoll-Testdienst, kein OpenLDAP-Server.
- Die aktuelle Konfiguration garantiert noch keine Unterstützung von Solaris, FreeBSD oder OpenBSD.
- `file-integrity` ist keine gegen privilegierte Manipulation geschützte Ende-zu-Ende-Integritätslösung.
- Der Changelog steht auf `Unreleased`; keine voreilige Aussage über veröffentlichte `v1.0`.

## 7. Unmittelbarer nächster Schritt

Ohne Änderung an `main` die Aufgaben für **M1 (`quality-contracts`)** präzisieren und anschließend als kleinen, reviewbaren Feature-Branch bearbeiten. Bestehende Schnittstellen nur mit Migrationshinweisen ändern. Nach dem Push wie bisher Ubuntu- und macOS-CI prüfen; erst dann mergen.

## 8. Geprüfte Quellen

- [Repository und vollständiger Code](https://github.com/SASD-Sysadmin/freeware/tree/f618e42b77b48ac6905b8a5e8b6f75af4a0db8eb)
- [README.de.md](../README.de.md), [CHANGELOG.md](../CHANGELOG.md)
- [Entwicklungsrichtlinien](DEVELOPMENT.de.md), [Plattformen](PLATFORMS.de.md), [Integrationstests](TESTING.de.md), [Rückgabecodes](EXIT-CODES.de.md)
- [Makefile](../Makefile), [CI-Konfiguration](../.github/workflows/ci.yml), [Sicherheitsrichtlinie](../SECURITY.md)
- [GitHub-Actions-Hauptbranch-Lauf #13](https://github.com/SASD-Sysadmin/freeware/actions/runs/38394032369)
