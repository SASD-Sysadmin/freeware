# Integrationstests (Linux und macOS)

[English](TESTING.md) · [Projekt](../README.de.md) · [Rückgabecodes](EXIT-CODES.de.md)

## Testebenen

1. `make test`: **schnelle Offline- und Regressionstests** für Perl, Bash, Dokumentation und simulierte Clients. Es werden weder Konten, `/etc` noch Systemdienste verändert.
2. `make integration-test`: **optionale lokale Netzwerk-Integrationstests**. Ein DNS- und – falls die Voraussetzungen vorhanden sind – ein LDAPS-Testdienst werden ausschließlich auf Loopback gestartet. Unsere SASD-Programme verwenden dabei die echten `dig`- und `ldapsearch`-Clients. Zufällige unprivilegierte Ports, ein kurzlebiges TLS-Testzertifikat, keine Root-Rechte, keine externen Ziele und keine Zugangsdaten.
3. GitHub Actions: Unter Ubuntu werden `dnsutils` und `ldap-utils` installiert; **beide** Integrationsprüfungen sind verpflichtend. Unter macOS ist **DNS verpflichtend**; LDAPS wird in der CI derzeit bewusst übersprungen, unabhängig von vorhandenen Clients. Reguläre Tests sowie Probeinstallation und -deinstallation laufen auf beiden Systemen.

Die Testdienste aus `tests/integration/local_servers.py` liefern **feste, reduzierte DNS- und LDAP-Protokollantworten**; sie ersetzen **keinen vollständigen BIND- oder OpenLDAP-Server**. Dadurch prüfen wir tatsächlich UDP, TLS, LDAP-Clientkommunikation und Rückgabewerte, jedoch nicht sämtliche Eigenschaften produktiver Verzeichnisdienste.

## Lokaler Aufruf

Integration benötigt Python 3 und Perl-Standardmodule. Für DNS ist `dig` erforderlich; für LDAPS werden `ldapsearch` und `openssl` benötigt. Unter Debian/Ubuntu zum Beispiel:

```sh
sudo apt-get install dnsutils ldap-utils openssl
make test
make integration-test
```

Auf macOS ist `dig` üblicherweise vorhanden. Fehlen optionale Programme, zeigt die Testsuite den betreffenden Fall als **`SKIP`** an. Wenn das Fehlen stattdessen zum Abbruch führen soll:

```sh
SASD_REQUIRE_DNS_INTEGRATION=1 SASD_REQUIRE_LDAP_INTEGRATION=1 make integration-test
```

Die Testdienste lauschen nur auf `127.0.0.1`; ein Internetzugang ist nicht erforderlich. Das kurzlebige Zertifikat umfasst `localhost`, `127.0.0.1` und den lokalen Rechnernamen, da OpenLDAP-Clients Loopback-Verbindungen teilweise kanonisieren. Zertifikat und privater Schlüssel werden nach dem Test gelöscht. Python wird **nur für die Tests** verwendet, nicht für die installierten Perl-Programme; CPAN-Downloads sind nicht nötig.

## Geprüfte Situationen

- IPv4- und IPv6-Datensätze (A und AAAA) von einem echten lokalen UDP-DNS-Dienst.
- `NXDOMAIN` und `NOERROR` ohne Antwort (Exit 1).
- Ungültiger DNS-Port wird schon vor dem Clientaufruf abgewiesen (Exit 2).
- TLS-Verbindung mit vertrauenswürdigem Testzertifikat, anonymer LDAP-Bind und Root-DSE-Abfrage.
- Nicht vertrauenswürdiges TLS-Zertifikat wird auch bei extern gesetztem `LDAPTLS_REQCERT=never` abgewiesen.
- `ldap://` wird vor einem Verbindungsaufbau abgewiesen.

Ein grüner CI-Lauf sollte nicht nur `make test`, sondern ausdrücklich auch die Integrationstests enthalten. Bei Problemen Client-Verfügbarkeit, Fehlermeldungen, Zertifikat und den lokalen Listener prüfen. **Zertifikatsprüfung niemals zum Reparieren eines Tests deaktivieren.**

## Schnittstellen- und Repository-Verträge

`make test` umfasst außerdem `tests/test_cli_contracts.t` (`--help` und
`--version` für jedes ausführbare Programm) und
`tests/test_repository_contracts.t` (Markdown-Format, nicht ersetzte
Link-Platzhalter und Dateirechte im Git-Index). `make shellcheck` ist lokal
optional, im Ubuntu-CI-Job jedoch verpflichtend.
