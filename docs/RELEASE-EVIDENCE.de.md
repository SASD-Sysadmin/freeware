# FR2-05 – Release-Evidenzregister und Abnahmeakte (Entwurf)

[English](RELEASE-EVIDENCE.md) · [Lizenzentscheidung](LICENSE-STRATEGY.de.md) · [Freigabelücken](RELEASE-GAPS.de.md) · [Release-Verfahren](RELEASE-ENGINEERING.de.md) · [Plattformen](PLATFORMS.de.md)

**Aufnahmedatum:** 23. November 2026. **Nachweisstand:** `SASD-Sysadmin/freeware` auf `main`, Git-Commit `686a86b88317c15a6be0413a3278e32d069dbd75`. **Status:** dokumentierte technische Teilnachweise – **kein freigegebener Release, kein RC-Tag, keine rechtliche oder privilegierte Abnahme**. Jeder nachfolgende Commit benötigt eine neue CI-Zuordnung; ältere Nachweise sind datiert zu verwenden.

## 1. Sichere Statusbegriffe

| Begriff | Bedeutung |
| --- | --- |
| `PASS (lokal)` | Im benannten Testkontext tatsächlich erfolgreich ausgeführt; nicht für andere Plattformen extrapolieren |
| `PASS (CI)` | Konkreter GitHub-Actions-Job auf dem angegebenen Commit erfolgreich |
| `TEILNACHWEIS` | Ein Teil der Bedingung geprüft, Gesamtgate noch offen |
| `MANUAL / OFFEN` | Externe Freigabe/Nachweis fehlt; **weder PASS noch FAIL** |
| `SKIP` | Ausdrücklich nicht durchgeführter Test, niemals stillschweigend bestanden |
| `NICHT FREIGEGEBEN` | Keine Signatur und keine belegte Produktfreigabeentscheidung |

## 2. Verifizierbare technische Teilnachweise

| ID | Commit / Umgebung | Ergebnis | Nachweis und Grenze |
| --- | --- | --- | --- |
| E-01 – historischer Perl-Lauf | `b1960f4`, Debian/WSL2, Perl **5.14.4** | **PASS (lokal)** | Operator-Protokoll vom 18.11.: 49 Perl-Testsuiten, 6.146 TAP-Fälle (10 SKIP), zwei Bash-Gruppen; 74 Quelldateien/53 CLI-Programme ohne Syntax-/Metadatenfehler. Perl-Mindestversion anderer Releases und andere Plattformen nicht belegt; [Perl-Matrix](PERL-COMPATIBILITY.de.md). |
| E-02 – FR2-02 Dokumentation | `15e434799c7de424217c8dce7cff35af1af00e2f` | **PASS (CI)** | [Actions `44950599429`](https://github.com/SASD-Sysadmin/freeware/actions/runs/44950599429); Ubuntu-/macOS-Jobs erfolgreich. |
| E-03 – FR2-04b Installer-Lizenz | `1f6f4f04c7068603527c3867773cc1766bf50a86` | **PASS (lokal und CI)** | 37 Lizenz-Regressionsfälle, insgesamt 226 gezielte TAP-Fälle (ein Darwin-SKIP), `make test` und [Actions `45128966544`](https://github.com/SASD-Sysadmin/freeware/actions/runs/45128966544). `LICENSE` ist SHA-256-verwalteter Installationsinhalt; keine privilegierte VM-Abnahme. |
| E-04 – FR2-04a Herkunft | `686a86b88317c15a6be0413a3278e32d069dbd75` | **PASS (lokal und CI für geprüfte Verträge)** | 18 gezielte Auditor-Tests lokal, `make test` und [Actions `45131942704`](https://github.com/SASD-Sysadmin/freeware/actions/runs/45131942704) erfolgreich unter Ubuntu und macOS. Statische SPDX-Analyse: 132/132 MIT, 4 weitere manuelle `REVIEW`, 2 `INFO`. Keine juristische Herkunftsbestätigung. |
| E-05 – Protokoll-/Native-Integration | `686a86b`, GitHub Actions | **PASS (CI im vorgesehenen Umfang)** | Ubuntu-Job: Offline-Regressionssuite, ShellCheck, Loopback-DNS/-LDAPS und Staging-Install/Uninstall erfolgreich; macOS-Job: Regression, dort vorgesehene DNS-Integration und Staging erfolgreich; macOS-LDAPS ist gemäß [Testmatrix](TESTING.de.md) ausdrücklich nicht verpflichtend. Keine produktionsnahen Dienste. |
| E-06 – statische Release-Inventur | Lokaler FR2-04a-Arbeitsbaum vor dem anschließenden Commit `686a86b` | **PASS für statischen Bestand** | `make release-gap-audit`: `PASS=288`, `GAP=0`, `MANUAL=7`. Die sieben MANUAL-Zeilen bleiben bestehen und verhindern keine erfolgreiche Inventur, aber eine unbelegte Freigabe. |
| E-07 – Git-Autorenmetadaten | Gesamte auf GitHub abgerufene Historie: 104 Commits | **TEILNACHWEIS** | Autorenfelder zeigen nur `Robin Goerlach` und `SASD-SysAdmin`; Namen, E-Mail und Commit-Metadaten belegen keine Urheber- oder Gesellschaftsrechte und keinen Ausschluss kopierter Inhalte. |
| E-08 – Lizenzstrategie | Projektentscheidung vom 23.11.2026 | **ENTSCHEIDUNG FESTGEHALTEN** | Entwicklungs-/Beta-Repository **MIT**; separate spätere `SASDGMBH`-Fassung **AGPL-3.0-only**. Rechts-, NOTICE- und Release-Umsetzung bleibt offen; [Strategie](LICENSE-STRATEGY.de.md). |

**Abnahme-Hinweis:** FR2-04a/b als **technische Entwicklungspakete abgeschlossen**; die manuelle Rechte-/Provenienzfreigabe (RG-09) ist **nicht** dadurch abgeschlossen. Für einen nach diesem Dokument folgenden Commit gelten die oben genannten CI-Erfolge als Nachweise der jeweiligen älteren SHAs, nicht als CI-Erfolg des neuen Commits.

## 3. Die sieben manuellen Release-Gates

| ID (entspricht Ausgabe `make release-gap-audit`) | Priorität | Vorhandene Evidenz | Fehlende Abnahme / nächste konkrete Aktion |
| --- | --- | --- | --- |
| `current-ci` | P0 | CI `45131942704` ist auf `686a86b` erfolgreich; umfasst Ubuntu-/macOS-Tests und die jeweilige Integration | Vor Release erforderliche Jobs auf **exaktem finalen Release-Commit** erneut erfolgreich nachweisen; CI-Protokolle zur Freigabeakte hinzufügen |
| `privileged-vm` | P0 | Offline-Tests für `account-manage` und `quota-set` | Nach **gesonderter Freigabe** in wegwerfbarer Snapshot-VM tatsächliches Apply, unabhängige Zustandsprüfung und geprüften Snapshot-Restore protokollieren |
| `staged-upgrade` | P0 | Install/Uninstall, Konflikt- und Fault-Injection-Regressionen, CI-Staging vorhanden | Fresh/Repeat/Upgrade/Conflict/Uninstall inklusive Recovery auf gesonderter sicherer Staging-/VM-Umgebung abnehmen; SIGKILL/Powerloss nicht behaupten |
| `artifact-provenance` | P0 | SHA-genaue CI- und Commit-Bezüge | Tag/Version abstimmen, unveränderten Tag-Checkout, reproduzierbares Quellarchiv und unabhängigen SHA-256-Abgleich nachweisen |
| `release-approval` | P0 | Risiko- und Gap-Register vorhanden | Freigabeumfang, Lizenz, abweichende Plattformen, Sicherheitsrisiken, Rollback und zeichnungsberechtigte Freigabe auf **konkretem Release-Commit** dokumentieren |
| `native-platforms` | P1 | Ubuntu/macOS-CI vorhanden | Nur tatsächlich native geprüfte Distributionen/Unix-Varianten zusagen; für weitergehende Aussagen echte Native-Tests durchführen oder Supportumfang begrenzen |
| `live-services` | P1 | Mock-Clients und Loopback-Integration für DNS/LDAP | Realistische Postfix-/SQL-/LDAP-/NIS-/Firewall-Umgebungen je ausdrücklich zugesagter Funktion testen oder als nicht nativ abgenommen kennzeichnen |

Diese Gates werden **nicht** durch Dokumentationsdateien, GitHub-Actions-Grün oder den Status `GAP=0` automatisch geschlossen. Ein späteres offiziell AGPL-lizenziertes SASDGMBH-Produkt benötigt darüber hinaus eine rechtlich geprüfte Rechtekette und einen eigenständigen Lizenz-/NOTICE-Release-Payload.

## 4. Nachweisformular für die nächste echte Abnahme

Für jeden Gate-Abschluss werden mindestens die folgenden Felder befüllt und unabhängig geprüft:

| Feld | Eintrag / Anforderung |
| --- | --- |
| Gate-ID / Prüfer | Genaue Gate-Kennung, benannte prüfende Rolle, Datum |
| Konkreter Git-Commit / Tag | Vollständiger SHA, Repository, Version, Betriebssystem und Tool-Versionen |
| Erwartetes Verhalten | Positive und negative Anforderungen einschließlich Sicherheitsgrenzen |
| Durchführung | Reproduzierbarer Aufruf, Testumgebung/VM, Snapshot-ID nur in privatem Protokoll |
| Beobachtetes Ergebnis | PASS / FAIL / SKIP / BLOCKED mit ausgeführter Fallzahl und Abweichungen |
| Nachweis | CI-URL, lokaler Dateiname und SHA-256; keine privaten Zugangsdaten/Hostdetails veröffentlichen |
| Recovery | Was wurde wiederhergestellt und wie unabhängig verifiziert? |
| Entscheidung | Ausdrückliche Freigabe oder Ablehnung, Datum, verantwortliche autorisierte Person |

## 5. Nächster sicherer Schritt

1. Dieses Register als **dokumentationsbezogenen** FR2-05-Zwischenstand committen und die CI für dessen neuen SHA prüfen.
2. Im Rahmen FR2-06 die Privilegien- und Staging-VM-Abnahme separat vorbereiten, nicht auf WSL oder einem Arbeitsrechner mit echten Konten/Quotas ausführen.
3. Für eine erste Veröffentlichung den **Supportumfang bewusst klein** halten; keine BSD-/Solaris-/Fünf-Distro-Zusage ohne konkrete Native-Tests.
4. Eine etwaige Veröffentlichung im `SASDGMBH`-Repository folgt der [beschlossenen getrennten AGPL-Strategie](LICENSE-STRATEGY.de.md), aber erst nach Rechte-/Notice-Prüfung und finaler Freigabe.
