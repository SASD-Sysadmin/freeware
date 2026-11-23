# SASD Freeware – Verbindliche Lizenzstrategie (FR2-04 / FR2-05)

[English](LICENSE-STRATEGY.md) · [Herkunftsnachweise](LICENSE-PROVENANCE.de.md) · [Release-Evidenz](RELEASE-EVIDENCE.de.md) · [Projekt](../README.de.md)

**Entscheidungsdatum:** 23. November 2026. **Entscheidung:** vom Projektverantwortlichen im Entwicklungsdialog festgelegt. **Technischer Ausgangsstand:** `SASD-Sysadmin/freeware` bei `686a86b88317c15a6be0413a3278e32d069dbd75`. Diese Datei dokumentiert eine Produktstrategie, keine bereits wirksame Umlizenzierung, Rechteübertragung oder Unternehmensfreigabe.

## 1. Beschlossene Aufteilung

| Bereich | Lizenz | Bedeutung |
| --- | --- | --- |
| Persönliche Entwicklung und Beta; derzeit `SASD-Sysadmin/freeware` | **MIT** | Die öffentliche Quellfassung und ihre Beiträge bleiben unter der bestehenden `LICENSE` und `CONTRIBUTING.md` MIT-lizenziert. |
| Spätere offizielle Produktveröffentlichung in einer **getrennten** GitHub-Organisation `SASDGMBH` | **GNU AGPL-3.0-only** | Die auszuliefernde Produktfassung soll unter der ausdrücklich versionsgebundenen AGPL 3.0 stehen. Der entsprechende Repository-/Release-Stand muss erst erstellt, überprüft und separat freigegeben werden. |

**`AGPL-3.0-only`**, nicht `AGPL-3.0-or-later`, ist die festgelegte Kennung. Die Strategie ist entschieden; offen sind die rechtliche und technische Ausführung sowie die konkrete Release-Abnahme.

Das gegenwärtige GitHub-Repository heißt **`SASD-Sysadmin/freeware`**. Es wird durch diese Absicht weder in `Robin-Goerlach/freeware` umbenannt noch an `SASDGMBH` übertragen. Es ist **kein AGPL-Release**.

## 2. Unveränderliche Grenzen

1. Frühere MIT-Veröffentlichungen und die von Empfängern erworbenen MIT-Rechte werden durch einen späteren AGPL-Release **nicht rückwirkend aufgehoben**.
2. Derselbe neue Code, der weiterhin öffentlich unter MIT erscheint, bleibt auch aus dieser Quelle MIT-nutzbar. Wenn neue SASDGMBH-Weiterentwicklungen nur unter AGPL verteilt werden sollen, dürfen diese nicht gleichzeitig vollständig als MIT-Code in der Beta-Quelle veröffentlicht werden. Eine organisatorische Trennung ist vorab festzulegen.
3. Vor AGPL-Veröffentlichung sind Rechtsinhaber, Verfügungsbefugnis, tatsächliche Drittübernahmen, erhaltene MIT-/Fremdhinweise, vollständiger AGPL-Lizenztext und die Übereinstimmung von SPDX, `LICENSE`, Paketinhalt und Dokumentation zu prüfen. Die bloße GitHub-Organisation beweist keine Rechtekette.
4. Beiträge, die unter MIT eingingen, begründen dadurch **keine exklusive Urheberrechtsübertragung** und keine automatische Befugnis zur zusätzlichen proprietären Lizenz. MIT-Bestandteile können unter den maßgeblichen Bedingungen in ein AGPL-Gesamtwerk übernommen werden, ihre erforderlichen Hinweise bleiben erhalten.
5. Ein Account-Wechsel ist keine Lizenzumstellung. Ein zukünftiges SASDGMBH-Repository benötigt eine eigene bewusst vorbereitete Quellfassung, eindeutige Lizenzkennzeichnungen und eine dokumentierte Freigabeentscheidung. **Keine automatische Massenänderung** der bestehenden MIT-SPDX-Header.
6. AGPL lässt kommerzielle Nutzung unter ihren Bedingungen zu. Ihre Netzwerkpflichten sind bei reinen Offline-CLI-Werkzeugen nicht automatisch gleich bedeutsam wie bei Netzwerkdiensten.

## 3. Ausführung und Prüfgrenzen

- **Jetzt:** MIT in `SASD-Sysadmin/freeware` unverändert lassen; Quellen, Tests und MIT-Lizenzbeilage sind mit den FR2-04a/b-Arbeitspaketen dokumentiert und geprüft.
- **Vor SASDGMBH-Veröffentlichung:** Identität und Vertretungsbefugnis des Unternehmens sowie den Umfang der Nutzungsrechte nachweisen; mögliche Beiträge Dritter und Dokumentationsübernahmen durchsehen; Quell- und Binärumfang abstimmen; vollständige AGPL-3.0-only-Lizenz und ggf. erhaltene MIT-/NOTICE-Texte beilegen; SPDX prüfen.
- **Dann:** Geprüften Release-Kandidaten unter der künftigen Organisation erstellen, Tag/Commit/Quellarchiv/Checksummen und CI auf genau diesen Stand beziehen; erst nach den noch offenen P0-Release-Abnahmen veröffentlichen.
- **Kein Automatismus:** Dieses Dokument autorisiert weder das Anlegen noch das Pushen eines neuen SASDGMBH-Repositories, einen Lizenzwechsel im MIT-Beta-Repository, einen Produktivtest oder einen Release.

## 4. Entscheidung versus Abnahme

| Frage | Status am 23.11.2026 |
| --- | --- |
| MIT für das aktuelle Entwicklungs-/Beta-Repository | **ENTSCHEIDUNG GETROFFEN**; derzeit umgesetzt |
| AGPL-3.0-only für die getrennte spätere SASDGMBH-Produktfassung | **ENTSCHEIDUNG GETROFFEN**; noch nicht technisch veröffentlicht |
| Eigentums-/Nutzungsrechte und tatsächliche Drittherkunft für AGPL | **NACHWEIS OFFEN** |
| Eigener AGPL-Payload, SPDX, Lizenztexte, NOTICE und Prüfung | **UMSETZUNG OFFEN** |
| Freigabe des konkreten offiziellen Release-Commits | **ABNAHME OFFEN** |

**Primärquellen:** [bestehende MIT-Lizenz](../LICENSE), [AGPL v3](https://www.gnu.org/licenses/agpl-3.0.html), [SPDX AGPL-3.0-only](https://spdx.org/licenses/AGPL-3.0-only). Diese technische Dokumentation ersetzt keine juristische Einzelfallprüfung der Rechtekette.
