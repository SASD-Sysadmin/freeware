# dns-query — Direkte DNS-Protokollabfrage

[English](dns-query.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/dns-query.1)

Verwendet den optionalen **`dig`**-Client für direkte DNS-Abfragen, unabhängig von `/etc/hosts` und der üblichen `getaddrinfo`-Auflösung. Vergleiche mit `host-resolve`, das gezielt den **System-Resolver** prüft. `--server` akzeptiert ausschließlich numerische IPv4-/IPv6-Adressen. Erfolg wird nur bei `NOERROR` **mit mindestens einem Antwortdatensatz** gemeldet. `NXDOMAIN`, `SERVFAIL` und leere `NOERROR`-Antworten liefern Exit 1. Die Antwort ist auf 128 KiB begrenzt; Terminal-Steuerzeichen werden maskiert.

DNS-Anfragen können das Netzwerk verlassen. Klassisches DNS über `dig` ist gewöhnlich **unverschlüsselt**; eine **DNSSEC-Validierung findet nicht statt**. `--timeout` begrenzt die Client-Wartezeit, zusätzlich gilt eine gesamte Sicherheitsfrist. `dig` kann fehlen. Keine privaten Hostnamen an öffentliche DNS-Server senden.

Mit `--port 1..65535` lässt sich optional der UDP-Zielport angeben (Standard: 53). Das ist vor allem für isolierte Testserver und definierte DNS-Testumgebungen sinnvoll; `/etc/resolv.conf` wird nicht verändert.

## Beispiele

```sh
./bin/dns-query --name good.test --server 127.0.0.1 --port 1053  # nur wenn ein lokaler DNS-Testserver läuft
./bin/dns-query --name example.org --type A
./bin/dns-query --name example.org --type MX --server 192.0.2.53
./bin/dns-query --name 1.0.0.127.in-addr.arpa --type PTR
```

## Grenzen und Rückgabewerte

Siehe [Rückgabecode-Konvention](../EXIT-CODES.de.md) und [Integrationstests](../TESTING.de.md).

Nur A/AAAA/MX/TXT/NS/PTR/CNAME/SOA/SRV/CAA; kein AXFR und keine beliebigen dig-Optionen.

Exit `0`: keine Befunde/Erfolg; `1`: Strukturfehler, DNS-/NIS-Fehler oder fehlende Antwort; `2`: ungültige Parameter; `3`: Datei oder Client fehlt, nicht unterstützte Voreinstellung oder unerwarteter Fehler. Fehlende Clients dürfen **nicht** als fehlerfreie Konfiguration ausgelegt werden.
