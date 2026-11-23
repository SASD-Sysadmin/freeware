# FR2-04 – Lizenz-, Urheberrechts- und Herkunftsprüfung

[English](LICENSE-PROVENANCE.md) · [Projekt](../README.de.md) · [Release-Lücken](RELEASE-GAPS.de.md) · [Roadmap](ROADMAP.de.md)

**Prüfdatum:** 22. November 2026. **Geprüfter GitHub-Stand:** `SASD-Sysadmin/freeware`, `main`, Commit `15e434799c7de424217c8dce7cff35af1af00e2f`. **Nachtrag 23. November 2026:** Der mit Commit `1f6f4f04c7068603527c3867773cc1766bf50a86` eingespielte FR2-04b-Fix installiert `LICENSE` als verwaltete Datei. Die zugehörigen lokalen Tests und die Ubuntu-/macOS-CI (`45128966544`) sind erfolgreich. Der nachstehende Befund A04 beschreibt ausdrücklich den älteren Stand `15e4347` und ist inzwischen behoben. **Status:** überprüfte statische Befunde und Entscheidungsvorlage; **keine rechtliche Freigabe, Lizenzänderung oder Release-Abnahme**. Die Urheberschaft und Rechtekette können durch Quellcode- und Git-Metadaten allein nicht bewiesen werden.

## 1. Lizenzstrategie und Entscheidungsschnittstelle

Für ein anderes SASD-Projekt (SASD-Editor-Toolbox) wurde die Trennung **persönliches Entwicklungs-/Beta-Repository unter MIT** und **späteres, getrenntes SASDGMBH-Produktiv-Repository unter AGPL-3.0-only** zuvor ausdrücklich erörtert. Das kann als **Vorschlag** für SASD Freeware dienen, ist aber noch keine dokumentierte und autorisierte Lizenzentscheidung für dieses Repository. Der aktuelle Quellstand liegt unter **`SASD-Sysadmin/freeware`** (nicht unter `Robin-Goerlach/freeware`).

Ein anderer GitHub-Account ändert die Lizenz nicht automatisch. Entscheidend sind die jeweilige **veröffentlichte Fassung, ihre tatsächlichen Lizenzhinweise, die Urheber-/Nutzungsrechte und die Verbreitungsbedingungen**. Bereits wirksam unter MIT veröffentlichte Fassungen bleiben ihren Empfängern unter MIT nutzbar. Eine später zusätzlich unter AGPL verbreitete identische Fassung nimmt ihnen diese Rechte nicht. Auch künftige Weiterentwicklungen, die weiterhin im öffentlichen MIT-Beta-Repository erscheinen, sind aus dieser Quelle weiterhin unter MIT verfügbar. Wer ausschließlich AGPL für neuen Code erreichen will, darf diesen neuen Code nicht zugleich vollständig und ohne weitere Grenzen unter MIT publizieren.

**AGPL-3.0-only** ist nicht dasselbe wie `AGPL-3.0-or-later`. Das spätere Produkt-Repository braucht einen ausdrücklichen, geprüften Lizenzentscheid. AGPL erlaubt kommerzielle Nutzung und Verteilung unter ihren Bedingungen; sie ist kein Verbot kommerzieller Nutzung. Für eine zusätzliche proprietäre/commercial Lizenz sind gesonderte Rechte an allen betreffenden Beiträgen erforderlich. Die Netzwerkklausel ist besonders für über das Netz bediente Programme relevant; ein klassisches Offline-CLI-Programm gewinnt dadurch nicht automatisch einen besonderen Schutz gegen jede Nutzung durch Dritte.

## 2. Konkrete Befunde am geprüften Stand

| ID | Status | Gegenstand | Nachweis / Konsequenz |
| --- | --- | --- | --- |
| FR2-04-A01 | BESTÄTIGT | Repository-Lizenz | `LICENSE` ist der vollständige MIT-Lizenztext; `README` und `AGENTS.md` bezeichnen das Projekt als MIT. Keine AGPL-Umstellung vorgenommen. |
| FR2-04-A02 | BESTÄTIGT | Rechtebezeichnung | Der Lizenztext nennt `Copyright (c) 2026 SASD-SysAdmin`. Das ist keine unabhängige Bestätigung, ob eine Privatperson oder die SASD GmbH die Rechte hält. |
| FR2-04-A03 | BESTÄTIGT | Quell-/Test-Kennzeichnung | **76** reguläre Dateien in `bin/`, `sbin/`, `lib/`, `tools/` (ohne `.gitkeep`) und **54** Dateien unter `tests/` wurden über die GitHub-Quelle auf `SPDX-License-Identifier: MIT` geprüft: **130/130 gekennzeichnet, keine abweichende SPDX-Kennung**. Eine Kennzeichnung beweist nicht die tatsächliche Urheberschaft. |
| FR2-04-A04 | BEHOBEN mit `1f6f4f0`; historischer Befund | Lizenztext im Installationsumfang | Der Installer des historischen Stands `15e4347` nahm Dateien nur aus `bin`, `sbin`, `lib/SASD/Freeware`, `man`, `docs/commands` und ausgewählten `docs/*.md` auf. Eine Aufnahme der Stammdatei `LICENSE` war damals nicht vorgesehen. Beim geprüften historischen Stand wurde der Lizenztext bei `make install` **nicht als eigenständige Datei ausgeliefert**. Dieser Mangel ist inzwischen in FR2-04b behoben; `PREFIX/LICENSE` wird in das SHA-256-Manifest aufgenommen und durch lokale Tests sowie Ubuntu-/macOS-CI geprüft. Die übrige Rechte- und Notice-Abnahme bleibt offen. |
| FR2-04-A05 | OFFEN – besonders für exklusive/kommerzielle Zweitlizenzierung | Contributor-Regel | `CONTRIBUTING.md` sagt ausdrücklich, Beiträge würden unter **MIT** verteilt. MIT-Beiträge können grundsätzlich unter Erhalt ihrer MIT-Hinweise in ein AGPL-lizenziertes Gesamtwerk einfließen; das begründet aber keine exklusive Übertragung von Urheberrechten oder eine eigenständige proprietäre Doppellizenzierungsbefugnis. |
| FR2-04-A06 | OFFEN – Rechteprüfung | Fremdcode und Herkunft | In den untersuchten 130 Code-/Testdateien keine fremde SPDX-Kennung entdeckt. Eine vollständige Drittquellen-, Ausschnitts-, generierte Code-, Medien- oder Commit-Herkunftsprüfung ist **damit nicht erbracht**; manuelles Quellen- und Historienreview bleibt erforderlich. |
| FR2-04-A07 | OFFEN – Rechtsträger | SASDGMBH-Rechtekette | Wer Rechtsträger und Lizenzgeber ist, welche Verträge/Arbeitsverhältnisse/Übertragungen bestehen und wer für einen GmbH-Release zeichnungsberechtigt ist, muss vor der Veröffentlichung dokumentiert werden. GitHub-Organisationszugehörigkeit genügt nicht. |
| FR2-04-A08 | BESTÄTIGT – separat offen | Release-Gates | FR2-02 hatte `PASS=288, GAP=0, MANUAL=7` im **statischen** Release-Audit. Diese sieben Gates sowie RG-09 bleiben durch FR2-04 offen. |

**Wichtig zur Severity:** „P0 für Distribution“ bedeutet in diesem Dokument eine Voraussetzung für eine Veröffentlichung des betroffenen Pakets, nicht die Behauptung, dass allein das Fehlen einer separaten Lizenzdatei automatisch in jedem denkbaren Einzelfall eine Rechtsverletzung beweist. Die Einhaltung der MIT-Bedingung erfordert die Mitgabe des Urheberrechts- und Erlaubnishinweises bei Kopien oder wesentlichen Teilen.

Die 341 Dateien aus der damaligen Git-Baumansicht umfassen außerdem Manpages, Dokumentation und Metadaten. Diese wurden **nicht** einzeln auf Textübernahmen und Fremdhinweise durchgeprüft. Für eine ergänzende statische Gesamtinventur steht `tools/fr2-04-provenance-audit.pl` bereit; auch dessen Ergebnisse sind nur eine Heuristik.

## 3. Empfohlene Freigabereihenfolge

1. **Rechteinhaberschaft verifizieren:** reale(s) Rechtssubjekt(e), Urheber, Rechte aus Tätigkeit/Verträgen, etwaige Mitarbeitende/Fremdbeiträge und Berechtigung des späteren Lizenzgebers dokumentieren. Nicht unbesehen die GitHub-Organisation als Rechteinhaber ausgeben.
2. **Quellen-/Abhängigkeitsinventur abschließen:** Git-Historie, Commit-Autoren, externe Codeausschnitte und abgeleitete Beispiele, vorhandene Notice-/Lizenzdateien, Git-Submodule und Distributionsinhalte prüfen. Extern ausgeführte Programme wie `openssl`, `dig`, `postqueue`, `docker` oder `perl` sind funktionale Abhängigkeiten; sie sind nicht automatisch kopierter oder gebündelter Quellcode.
3. **MIT-Lizenzbeilage in eigenem Slice absichern (ERLEDIGT am 23.11.2026):** `LICENSE` und erforderliche Hinweise explizit in den Manifest-Installationsumfang aufnehmen. Die Sicherheit des Installers darf dabei nicht gelockert werden. Mindestens Fresh-/Repeat-Install, Upgrade von bisherigem Manifest, fremde/geänderte Dateien, Uninstall, Rollback und Fehlereinspritzung im Wegwerf-`DESTDIR` prüfen; zusätzlich beide CI-Plattformen.
4. **Lizenzen getrennt beschließen:** Für das aktuelle Freeware-Repository **MIT beibehalten**, solange keine ausdrückliche Umstellung beschlossen ist. Für eine spätere SASDGMBH-Fassung `AGPL-3.0-only` nur nach Rechte- und Notice-Prüfung, mit vollständigem Lizenztext und konsistenten SPDX-/Copyright-Angaben. Fremde MIT-Hinweise nicht entfernen. Die Produktversionskennzeichnung und Git-Herkunft dokumentieren.
5. **Beta-/Release-Quellenstrategie festhalten:** Wird der identische fortlaufende Code ebenfalls unter MIT veröffentlicht, bleibt er auf diesem Weg frei unter MIT verwendbar. Bei einer wirklich AGPL-exklusiven Weiterentwicklung neue Änderungen künftig nur AGPL-lizenziert verbreiten und Entwicklung/Release entsprechend organisatorisch trennen (z.B. nichtöffentliches Entwicklungs-Repository oder getrennte Code-Zweige). Das verlangt eine bewusste Produktentscheidung.
6. **Optional kommerzielle Zweitlizenz:** Erst nach abgesicherter Rechtekette und einer passenden Contribution-/Lizenzierungsregel. AGPL-3.0-only selbst erlaubt weiterhin gewerbliche Nutzung.
7. **Formale Freigabe:** Lizenzinhalt, vollständiger Release-Payload, Copyrights, NOTICE, Installation/Deinstallation, OS-/CI-Nachweise, manuelle Release-Gates und eine verantwortliche Entscheidung kontrollieren. Kein Release oder Lizenzwechsel durch dieses Audit.

## 4. Reproduzierbare lokale Inventur

Das neue Programm ist **rein lesend**, benötigt Perl und dessen Standardmodule, verlangt kein `sudo` und ändert keine Dateien. Es prüft Metadaten und auffällige Textmuster, keine komplexe Lizenzkompatibilität oder Urheberschaft.

```bash
repo="$(git rev-parse --show-toplevel)"
perl tools/fr2-04-provenance-audit.pl --root "$repo" \
  > "$HOME/tmp/.test-logs/fr2-04-provenance.tsv"
cat "$HOME/tmp/.test-logs/fr2-04-provenance.tsv"

git log --format='%h %aN' --all  # nur Hinweise; Git-Identitäten sind keine Rechteübertragungsurkunden
```

`REVIEW` ist ein Prüfauftrag, kein automatisch bestätigter Rechtsmangel. `PASS` bestätigt lediglich die konkret benannte statische Bedingung. Der Gesamtscan liefert `SUMMARY`, **keine Freigabeentscheidung**. Rohprotokolle mit Namen, internen Dateien oder Pfaden nicht ungeprüft öffentlich committen.

## 5. Rechtsgrundlagen und hilfreiche Primärquellen

- MIT-Lizenzbedingung: der gegenwärtige Repository-Text [`../LICENSE`](../LICENSE).
- GNU AGPL v3, insbesondere §13: https://www.gnu.org/licenses/agpl-3.0.html
- GNU-Empfehlung zu Lizenzhinweisen in Quelltexten: https://www.gnu.org/licenses/gpl-howto.html
- GitHub Open Source Guide, Lizenzwechsel und bestehende MIT-Hinweise: https://opensource.guide/legal/
- GitHub, Repository-Lizenzierung: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository

Diese technische Analyse ist keine verbindliche individuelle Rechtsberatung. Die Rechtekette, genaue AGPL-Gestaltung und Veröffentlichung unter dem rechtlichen Träger sollten vor Freigabe juristisch überprüft werden.
