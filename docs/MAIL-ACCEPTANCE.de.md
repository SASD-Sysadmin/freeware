# M6.4 – Electronic Mail: Integration und Abnahme

[English](MAIL-ACCEPTANCE.md) · [Roadmap](ROADMAP.de.md) · [Mail-Programme](../README.de.md)

## Ziel und Prüfgrenzen

M6.4 prüft die **Zusammenarbeit und die Grenzen** von drei unabhängig
aufrufbaren Diagnoseprogrammen. Es handelt sich weder um einen kombinierten
MTA-Sicherheitsscan noch um eine pauschale Sicherheitszertifizierung.

| Werkzeug | Offline-Vertrag | Reale Abnahme |
| --- | --- | --- |
| `mail-config-audit` | Statische `main.cf`/`master.cf`-Befunde und Hinweise; keine Konfigurationswerte in der Ausgabe | Echte lesbare Postfix-Dateien, Abgleich mit wirksamen Defaults und Overrides |
| `mail-queue` | JSONL-Queue-Aggregate, Negativfälle, keine Adressen/Queue-IDs | Lokales `postqueue -j` mit Postfix **3.1+**, normale Zugriffsrechte |
| `mail-probe` | Reproduzierbare Loopback-SMTP-/TLS-Tests in `test_mail_probe.t` | Eigener SMTP-Testdienst mit STARTTLS, korrektem Zertifikat und Hostnamen |

Alle normalen Tests sind **offline**: Sie benötigen weder Postfix noch
Root-Rechte, echte Benutzerkonten oder öffentliche Mailserver. Der zusätzliche
Integrationstest `tests/test_mail_workflow.t` testet gemeinsame Rückgabecodes,
Datenschutz, TSV-/NUL-Berichte und Sicherheitsgrenzen. Die TLS-Fixtures
benötigen `IO::Socket::SSL` und `openssl`; `test_mail_probe.t` kennzeichnet
fehlende Voraussetzungen gegebenenfalls ausdrücklich als `SKIP`. Ein SKIP
ist **kein positiver TLS-Abnahmenachweis**.

```sh
make test
prove -v tests/test_mail_workflow.t
prove -v tests/test_mail_probe.t
make shellcheck
```

## Reale Abnahme – nur in einer eigenen Testumgebung

Eine **separat eingerichtete Postfix-VM** (z. B. Debian) ist für den
abschließenden Praxisnachweis sinnvoll, aber **keine Voraussetzung**, um den
M6.4-Offline-Test zu entwickeln und in die CI aufzunehmen. Nicht direkt auf
einem produktiven Mailserver mit fremden Nachrichten testen. Keine E-Mails
versenden, keine Warteschlange spülen und keine Konfigurationen ändern.

1. **Umgebung protokollieren:** OS/Version, Perl-Version, Postfix-Version
   (`postconf -h mail_version`), ob `IO::Socket::SSL`/OpenSSL vorhanden sind,
   sowie die geprüften SASD-Commit-IDs. Kein Passwort und keine Adresse
   in die Testdokumentation übernehmen.
2. **Textprüfung:** Mit entsprechendem rein lesendem Zugriff ausführen:

   ```sh
   ./bin/mail-config-audit --main /etc/postfix/main.cf --master /etc/postfix/master.cf
   ```

   `ISSUE` erfordert Prüfung; `NOTE` markiert eingeschränkte Beweiskraft.
   Die Rückgabecodes `0`, `1`, `2`, `3` unterscheiden Erfolg, Befund,
   Aufruffehler und fehlende Voraussetzungen.
3. **Wirksame Konfiguration separat nachvollziehen:** Die Administratorin
   oder der Administrator prüft **lokal**, ohne Veröffentlichung der Ausgabe:
   `postconf -n`, `postconf -M` und `postconf -P`. Diese Leseabfragen können
   sensible Parameter, Servernamen und Zugriffsinformationen enthalten.
   Service-Overrides, `mynetworks`, Relay-Grenzen, AUTH und TLS ausdrücklich
   nachkontrollieren. Der statische SASD-Parser löst Defaults, Variablen
   und Tabellen **nicht** auf.
4. **Queue-Probe:** Nur auf einer vom Administrator kontrollierten
   Postfix-3.1+-Instanz:

   ```sh
   ./bin/mail-queue --timeout 10
   ```

   `postqueue -j` ist eine nichtatomare Momentaufnahme. `deferred`, `hold`
   oder unbekannte Queues ergeben Status 1 und sind **nicht automatisch**
   ein Datenschutz- oder Sicherheitsvorfall. Keine Rohdaten aus
   `postqueue -j` auf GitHub oder in Tickets einstellen.
5. **TLS-Probe:** Nur gegen den eigenen STARTTLS-Testdienst. Mit einem
   Hostnamen prüfen, der im Zertifikat steht. Bei einer eigenen Test-CA
   kann `--ca-file` verwendet werden:

   ```sh
   ./bin/mail-probe --host localhost --port 1587 --ca-file /ABSOLUTER/PFAD/ca.pem
   ```

   Dies ist ein **Beispiel**, kein installierter Testdienst. Es wird weder
   SMTP-AUTH noch eine Nachricht gesendet. Fehlende/ungültige Zertifikate
   müssen eine Negativprüfung auslösen, niemals ein TLS-Fallback.
6. **Ergebnisse festhalten:** Für jedes Werkzeug Erfolg/Negativfall,
   Exitcode, Plattform, Versionsstand und beobachtete Einschränkungen
   notieren. Keine privaten Konfigurationswerte, Zertifikatsschlüssel,
   Empfängeradressen oder Queue-IDs ablegen.

## Abnahmematrix

| Nachweis | Ubuntu-CI | macOS-CI | Native Postfix-Test-VM |
| --- | --- | --- | --- |
| Perl-Syntax, CLI-Verträge, Offline-Fixtures | verpflichtend | verpflichtend | optionaler Gegencheck |
| Workflow-Test ohne Netzwerk | verpflichtend | verpflichtend | optionaler Gegencheck |
| Zertifikatsgeprüfte SMTP-TLS-Loopback-Fixtures | verpflichtend, wenn Abhängigkeiten vorhanden | explizites SKIP bei fehlenden Abhängigkeiten möglich | gesonderte native Abnahme |
| `postqueue -j` mit echter Postfix-Queue | nicht Bestandteil der CI | nicht Bestandteil der CI | **noch offen** |
| `main.cf`/`master.cf` und wirksame Overrides | synthetisch | synthetisch | **noch offen** |
| IPv6 und implizites SMTPS (Port 465) | **nicht implementiert** | **nicht implementiert** | nicht durch M6.4 nachträglich unterstützt |

**M6.4-Offline-Integration gilt als erreicht**, wenn alle verpflichtenden
CI-Prüfungen auf Ubuntu/macOS grün sind und die Dokumentation konsistent ist.
**Eine vollständige produktionsnahe Mail-Abnahme bleibt offen**, bis echte
Postfix-/TLS-Prüfungen separat durchgeführt und dokumentiert wurden. Kapitel 8
darf durch Offline-Tests allein nicht als vollständig betrieblich abgenommen
dargestellt werden.

## Dokumentierter Praxistest am 20. Oktober 2026

Der Betreiber führte die folgenden **manuellen** Prüfungen auf `dev102`
(Debian 12, Postfix 3.7.11; kein isolierter VM-Lauf) mit der M6.4-Implementierung
auf `main` (`6ff3ab3`) aus. Die Postfix-Instanz lauschte nur auf
`127.0.0.1:25` und wurde nach den Tests gestoppt.

| Nachweis | Beobachtung | Ergebnis |
| --- | --- | --- |
| Statisches `main.cf`/`master.cf`-Audit | 0 ISSUEs, 3 NOTEs | Exit `0` |
| Reale `postqueue -j`-Abfrage | leere Queue, TOTAL 0/0/0 | Exit `0` |
| SMTP STARTTLS mit eigener gültiger Test-CA | `verified-starttls`, `localhost:25` | Exit `0` |
| SMTP STARTTLS ohne Vertrauen in diese CA | Zertifikatsprüfung schlug fehl, kein Downgrade | Exit `1` |
| Zustand nach dem Test | kein Listener mehr auf TCP/25 | erfolgreich gestoppt |

Diese Ergebnisse belegen die getesteten **Teilpfade**: Sie beweisen weder
die Auswertung einer tatsächlich gefüllten Postfix-Queue noch die Sicherheit
der wirksamen Relay-/TLS-Konfiguration. Insbesondere blieb der erkannte
`master.cf`-Service-Override bei den drei NOTEs; `postconf -n`, `-M` und `-P`
wurden hier nicht als fachlich bewertete Gegenprüfung dokumentiert. Die
TLS-Negativprobe belegte die Ablehnung der unbekannten Test-CA, nicht jeden
denkbaren Zertifikatsfehler. IPv6, implizites SMTPS/465 und weitere
Plattformen wurden nicht praktisch abgenommen.

**Betriebshinweis:** Die Laborinstallation ersetzte auf `dev102` Exim4 durch
Postfix. Der lokale SMTP-Dienst wurde gestoppt, eine dauerhafte Entscheidung
über MTA und Autostart ist separat nötig. Eine künftige abschließende Prüfung
soll in einer isolierten VM erfolgen und keine echten Nachrichten verwenden.
Die Laborzertifikate und privaten Schlüssel gehören nicht ins Repository.

## Offizielle Referenzen

- [postqueue(1) – `-j` und nichtatomare Queue-Informationen](https://www.postfix.org/postqueue.1.html)
- [postconf(1) – lesende Ausgabe, `-M`, `-P`](https://www.postfix.org/postconf.1.html)
- [master(5) – Service-Konfiguration und Overrides](https://www.postfix.org/master.5.html)
- [Postfix SMTPD Access Controls](https://www.postfix.org/SMTPD_ACCESS_README.html)
