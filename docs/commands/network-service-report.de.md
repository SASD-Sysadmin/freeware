# `network-service-report` — lokale Socket-Inventarisierung (M8.3)

## Ziel und Architektur

Das lesende Werkzeug erfasst **lokal lauschende TCP-Sockets** und **unverbundene,
lokal gebundene UDP-Sockets**. Es scannt keine entfernten Hosts, öffnet keine
Netzwerkverbindungen, verändert keine Firewallregeln und überprüft keine
Erreichbarkeit. Auch eine Bindung an `0.0.0.0` oder `::` beweist keine externe
Zugänglichkeit: Firewall, Namespaces, Routing und NAT spielen ebenfalls mit.

Wir trennen die Verantwortlichkeiten bewusst:

1. `bin/network-service-report`: Kommandozeile, begrenztes Einlesen, sicherer
   Dateizugriff, native Befehle mit festen absoluten Pfaden (ohne Shell) und
   Ausgabe.
2. `lib/SASD/Freeware/NetworkServices.pm`: **reiner Parser**, ohne Dateizugriff
   oder Netzwerkoperationen; er validiert vollständig die `ss`- bzw.
   macOS/BSD-`netstat`-Ausgaben und übersetzt sie in ein einheitliches Modell.
3. `tests/test_network_service_report.t`: Offline-Regressionen mit gültigen,
   ungültigen und absichtlich manipulierten Testdaten.

Wie bei M8.1/M8.2 bestehen keine Laufzeitabhängigkeiten zu anderen Netzwerk-
Reports. Eine mögliche spätere Prozesszuordnung gehört in einen gesonderten
Adapter; Namen oder PIDs werden nicht geraten.

## Bedienung

```sh
bin/network-service-report
bin/network-service-report --protocol tcp
bin/network-service-report --protocol udp --family inet6
bin/network-service-report --input /tmp/ss.snapshot --format ss
bin/network-service-report --input /tmp/netstat.snapshot --format netstat --null
bin/network-service-report --input - --format ss
```

`--input` liest eine gewöhnliche, lesbare Datei (keine Symlinks) oder mit `-`
von STDIN. Ohne `--input` verwendet das Programm einen unveränderlichen,
rein lesenden Systemaufruf. `--format auto` erkennt nur den Textcontainer;
Adressfamilien werden nicht anhand von Vermutungen zugewiesen.

## Plattformen und Grenzen

- **Linux:** `ss -H -n -l -t -u`, als Programm über festen absoluten Pfad.
  Auswertung von TCP `LISTEN` und UDP `UNCONN`; aufgebaute TCP-Verbindungen
  und verbundene UDP-Sockets werden nicht inventarisiert.
- **macOS/BSD:** `netstat -an`. Ausgewertet werden `tcp4`, `tcp6`, `udp4`,
  `udp6` aus der Internet-Socket-Tabelle. Die Kopfzeilen sind verpflichtend;
  UNIX-Domain-Sockets und andere Netzwerkzustände bleiben außen vor.
  FreeBSD/OpenBSD/NetBSD/DragonFly benötigen zusätzliche native Abnahmetests.
- Keine Administratorrechte erforderlich; allerdings kann die Sichtbarkeit
  ohne besondere Berechtigungen eingeschränkt sein. Andere Netzwerk-
  Namespaces oder Container werden nicht automatisch erfasst.
- **Keine PID, kein Benutzer und kein Programmname** in M8.3. Auch eine
  Dienstprüfung, Firewallanalyse, Erreichbarkeitsprüfung oder vollständige
  Momentaufnahme des gesamten Systems wird nicht behauptet.

## Beispiel-Testdaten

Linux `ss`:

```text
tcp LISTEN 0 128 127.0.0.1:22 0.0.0.0:*
tcp LISTEN 0 4096 [::1]:443 [::]:*
udp UNCONN 0 0 0.0.0.0:5353 0.0.0.0:*
```

macOS `netstat -an`:

```text
Active Internet connections (including servers)
Proto Recv-Q Send-Q Local Address Foreign Address (state)
tcp4 0 0 127.0.0.1.22 *.* LISTEN
tcp6 0 0 ::1.443 *.* LISTEN
udp4 0 0 *.5353 *.*
```

Beim `netstat`-Format trennt ein Punkt Adresse und Port, auch bei IPv6.
Das `4`/`6` im Protokollfeld liefert die Adressfamilie. Bei `ss` kann `*:8080`
zusammen mit `*:*` **nicht** eindeutig IPv4/IPv6 zugeordnet werden. Dann
meldet der Parser `unknown`. Ein Familienfilter blendet solche Datensätze
aus, anstatt eine Familie zu erfinden.

## Stabiles Ausgabeformat

Sieben TSV-Spalten (tatsächlich durch TAB getrennt):

```text
FAMILY  PROTOCOL  LOCAL_ADDRESS  LOCAL_PORT  STATE  PEER_ADDRESS  PEER_PORT
```

`FAMILY`: `inet`, `inet6` oder `unknown`; `PROTOCOL`: `tcp` / `udp`.
**TCP `LISTEN`** bedeutet lokal lauschend, **UDP `BOUND`** lediglich gebunden
und unverbunden; ein UDP-Socket wird nicht fälschlich als lauschender
TCP-Dienst bezeichnet. `*` ist ein Platzhalter und keine Gegenstellenadresse.
IPv6-Zonen wie `%en0` bleiben erhalten. `--null` gibt sieben NUL-terminierte
Felder je Datensatz ohne Kopfzeile aus.

Vollständige Validierung geschieht **vor der ersten Ausgabe**; auch durch
Familien- oder Protokollfilter ausgeblendete Datensätze werden geprüft.
Ungültige Adressen, Ports, Steuercodes und unvollständige Datensätze führen
zum Abbruch ohne Teilausgabe. Obergrenzen: 8 MiB Eingabe, 8192 physische
Zeilen, 65536 Bytes je Zeile und 4096 Ergebniszeilen. Meldungen enthalten
weder ungeprüfte Rohdaten noch Pfadnamen.

## Rückgabecodes und Tests

| Code | Bedeutung |
| --- | --- |
| `0` | Vollständig geprüfter Snapshot; auch keine Sockets ist gültig |
| `2` | Ungültige Optionen oder nicht passendes natives Format |
| `3` | Backend-/Dateifehler oder beschädigter, unvollständiger oder zu großer Snapshot |

```sh
perl -c bin/network-service-report
perl -c lib/SASD/Freeware/NetworkServices.pm
prove -v tests/test_network_service_report.t
make test
make shellcheck
```

Die Offline-Tests ersetzen keine echten macOS-/BSD-Praxistests. Das Programm
gibt sensible Netzwerkinformationen aus; Berichte entsprechend schützen.
Zusätzliche Plattformversionen, Process-Owner-Ermittlung und unabhängige
Erreichbarkeitstests sind spätere Aufgaben.
