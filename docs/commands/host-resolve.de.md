# host-resolve — Diagnose der System-Namensauflösung

[English](host-resolve.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/host-resolve.1)

`host-resolve` benutzt `Socket::getaddrinfo` und `Socket::getnameinfo`, um Hostnamen und IP-Adressen über den **Resolver des Betriebssystems** aufzulösen. Dieser kann `/etc/hosts`, lokale Caches, mDNS, DNS oder andere Dienste verwenden. Das Programm ist **kein direkter DNS-Protokolltest** und sagt nicht, welcher DNS-Server geantwortet hat. Es verändert keine Einstellungen.

## Beispiele

```sh
./bin/host-resolve --name localhost
./bin/host-resolve --name example.org --family ipv4
./bin/host-resolve --name example.org --family ipv6
./bin/host-resolve --address 127.0.0.1
./bin/host-resolve --address ::1
./bin/host-resolve --name localhost --null > addresses.bin
```

Genau eine Option `--name HOST` oder `--address IP` ist erforderlich. Die Vorwärtsauflösung unterstützt `--family any|ipv4|ipv6` (Vorgabe `any`). Bei der Rückwärtsauflösung ist **eine numerische IPv4- oder IPv6-Adresse** erforderlich; ohne ermittelten Namen gilt die Abfrage als fehlgeschlagen (`NI_NAMEREQD`). `--family` ist bei Rückwärtsabfragen nicht erlaubt. Doppelte Adressen werden zusammengefasst. Eingaben dürfen keine Leer- oder Steuerzeichen enthalten und sind auf 253 Bytes begrenzt. Die Ausführung kann Namensdienst-Netzwerkverkehr und Zeitüberschreitungen auslösen.

## Ausgabe und Rückgabecodes

Spalten: `DIRECTION FAMILY ADDRESS NAME`, Tabulatoren und maskierte Sonderzeichen. `--null` liefert vier unveränderte NUL-getrennte Felder pro Zeile ohne Zusammenfassung. Ob IPv4/IPv6 verfügbar ist, hängt von der Systemkonfiguration ab.

- `0`: mindestens ein Ergebnis; `1`: keine Auflösung oder kein Rückwärtsname; `2`: ungültige Optionen; `3`: interner Konvertierungsfehler.

Perl mit `Socket::getaddrinfo` und `Socket::getnameinfo` ist erforderlich (gewöhnlich **Perl 5.14 oder neuer**). Weder CPAN-Pakete noch `dig`/`nslookup` werden gebraucht. Auf älteren Unix-Perl-Installationen kann bereits das Laden von Socket scheitern.
