# `mail-probe` – SMTP-Erreichbarkeit und geprüftes STARTTLS (M6.1)

[English](mail-probe.md) · [Roadmap](../ROADMAP.de.md) · [Rückgabecodes](../EXIT-CODES.de.md)

`mail-probe` ist eine **rein lesende SMTP-Protokolldiagnose** (Kapitel 8).
Das Programm öffnet eine TCP-Verbindung, prüft das `220`-Banner, sendet
festes EHLO, validiert die mehrzeilige `250`-Antwort und erwartet STARTTLS.
Nach STARTTLS wird **das Zertifikat einschließlich Servername** verifiziert.
Erst danach wird EHLO innerhalb des TLS-Kanals wiederholt. Angezeigt werden
die Fähigkeiten des abgesicherten Kanals. Ein offener Port oder ein einfacher
SMTP-Banner gelten niemals als erfolgreiche Sicherheitsprüfung.

## Aufruf

```sh
./bin/mail-probe --host mail.example.org
./bin/mail-probe --host mail.example.org --port 587 --timeout 5
./bin/mail-probe --host mail.example.org --null
# Nur für eigene Testumgebungen mit separater CA-Vertrauensregel:
./bin/mail-probe --host localhost --port 1587 --ca-file /absoluter/pfad/ca.pem
```

`--host` ist Pflicht. M6.1 akzeptiert ASCII-DNS-Namen einschließlich IDNA
A-Labels und IPv4-Adressen, **noch kein IPv6**. Standardport **587**;
`--timeout` 1–30 Sekunden (Vorgabe 5), zusätzliche globale Laufzeitgrenze.
`--ca-file` akzeptiert nur lesbare absolute reguläre PEM-Dateien ohne Symlink.
Ohne eigene CA-Datei gilt die Trust-Konfiguration des TLS-Providers. Eigene
Serverzertifikate dürfen nicht gedankenlos zu produktiven Vertrauensankern
werden. `--null` liefert exakt vier NUL-terminierte Felder: Host, Port,
`verified-starttls`, kommagetrennte Fähigkeiten nach TLS. Normal ist eine
TSV-Kopfzeile plus Datenzeile.

Voraussetzung ist Perl sowie **IO::Socket::SSL >= 2.009** und eine
funktionsfähige SSL-/CA-Umgebung. `IO::Socket::SSL` gehört **nicht** zum
Perl-Kern; es muss über die vertrauenswürdige Paketverwaltung vorhanden sein.
Es gibt keinen automatischen Download. Die Offline-TLS-Tests brauchen
zusätzlich `openssl`, um kurzlebige Testzertifikate zu erzeugen.
Das eigentliche Programm ruft `openssl` nicht auf.

## Rückgabecodes und Sicherheit

| Code | Bedeutung |
| --- | --- |
| 0 | Vollständiger SMTP-Dialog und Zertifikat-/Namensprüfung erfolgreich. |
| 1 | SMTP-Ziel negativ, Ablehnung, STARTTLS fehlt oder TLS-Prüfung fehlgeschlagen. |
| 2 | Ungültiger Aufruf bzw. nicht unterstützte Host-Schreibweise. |
| 3 | Fehlende/unsichere Voraussetzung, Timeout, unvollständige oder fehlerhafte SMTP-Daten. |

Das Programm sendet ausschließlich `EHLO sasd-probe.invalid` und `STARTTLS`.
Kein AUTH, kein MAIL FROM, RCPT TO, DATA, kein Passwort, keine Queue-Aktion,
keine Konfigurationsänderung. Keine unverschlüsselte Ausweichverbindung, keine
Abschaltung der Zertifikatsprüfung und noch kein implizites SMTPS/465.
Eingangszeilen, Antwortanzahl und Gesamtumfang sind begrenzt; Steuer- und
Binärdaten werden nicht ans Terminal übernommen. Aussagen über Mailzustellung,
Relay-Policy, DKIM/SPF/DMARC oder die gesamte MTA-Gesundheit sind ausdrücklich
**nicht** Teil des Ergebnisses.

## Tests ohne produktiven Mailserver

```sh
perl -c bin/mail-probe
prove tests/test_mail_probe.t
make test
```

Die Tests verwenden nur lokale SMTP-Server auf `127.0.0.1` mit temporären
TLS-Zertifikaten. Es wird keine Mail verschickt und kein öffentlicher Server
abgesucht. IPv6, SMTPS/465, andere MTAs und produktive Integrationstests
bleiben separat offen. Unter macOS die Perl-TLS-Modulvoraussetzung ausdrücklich
prüfen statt ihr Vorhandensein anzunehmen.
