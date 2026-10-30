# `tcp-check` — Einzelne IPv4-TCP-Verbindung prüfen

**Deutsch** · [English](tcp-check.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/tcp-check.1) · [Quellcode](../../bin/tcp-check)

## Zweck und Einsatzbereich

Versucht **eine TCP-Verbindung** zu einem IPv4-Endpunkt mit Perls `IO::Socket::INET` und schließt den Socket danach. **Kein** TLS, keine Zertifikatskontrolle, Anmeldung, Anwendungsanfrage, Portbereichssuche oder Nachweis einer gesunden Anwendung.

## Verhalten und geprüfte Eigenschaften

Host kann eine IPv4-Adresse oder über IPv4 auflösbarer Name sein. `--port` erlaubt 1–65535, `--timeout` ganzzahlig 1–30 Sekunden (Standard 3). Gemessen wird die Verbindungsdauer; DNS-Auflösung und OS-Verhalten können über den Timeout hinausgehen. Nur ausdrücklich berechtigte Endpunkte prüfen.

## Aufruf und Optionen

```text
tcp-check --help
```

| Option | Bedeutung |
| --- | --- |
| `--host HOST` | Erforderlicher IPv4-Endpunkt oder Hostname. |
| `--port PORT` | Port als ganze Zahl 1–65535. |
| `--timeout SECONDS` | Verbindungstimeout ganzzahlig 1–30 (Standard 3). |
| `--nagios` | Nagios-kompatible Fehlerrückgabecodes. |
| `--help`, `--version` | Metadaten ohne Socket-Zugriff. |

## Praktisches Beispiel

```sh
# Berechtigter Loopback-Test: Ergebnis hängt vom echten Listener ab.
./bin/tcp-check --host 127.0.0.1 --port 22 --timeout 3
# Derselbe Endpunkt mit Nagios-Rückgabecodes.
./bin/tcp-check --host 127.0.0.1 --port 22 --nagios
```

Ohne Dienst an TCP/22 ist eine Ablehnung normal. Es werden keine Authentifizierungsdaten übertragen.

## Ausgabe und Rückgabewerte

`OK: HOST:PORT TCP connection succeeded in N.NNN s` bzw. `CRITICAL: HOST:PORT TCP connection failed (...)`. Die Ausgabe beschreibt **nur den TCP-Verbindungsaufbau**, nicht die Anwendung.

Normal: `0` Verbindung, `1` Verbindungsfehler, `2` falsche Parameter. Mit `--nagios`: `0` OK, `2` CRITICAL bei Verbindungsfehler, `3` UNKNOWN bei falschem Aufruf (sofern `--nagios` erkannt ist). Es gibt keine WARNING-Schwelle.

## Grenzen, Sicherheit und Portabilität

IPv6 wird nicht unterstützt. TCP-Erfolg bestätigt weder TLS noch HTTP, SMTP, Zugangsdaten oder Dienstbereitschaft. Lokale Firewalls, DNS und Resolver beeinflussen die Ergebnisse; native Plattformprüfung erforderlich. Keine höheren Rechte oder externen Kommandozeilenclients nötig. **Kein** Portscanner.

## Weiterführende Informationen

[`host-resolve`](host-resolve.de.md) · [Plattformen](../PLATFORMS.de.md) · [Sammelanleitung](automation-tools.de.md)
