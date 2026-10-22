# `network-route-report` – Lesende Routing-Inventarisierung (M8.2)

## Aufgabe und Architektur

M8.2 erfasst **Momentaufnahmen** der IPv4- und IPv6-Routingtabellen, ohne
Routen einzurichten, zu löschen oder zu ändern. Das Programm benötigt keine
Administratorrechte und baut keine Netzwerkverbindung zu fremden Systemen
auf. Ein vorhandener Eintrag beweist **nicht**, dass ein bestimmtes Paket
über die Route weitergeleitet wird. Zwischen den getrennten IPv4- und
IPv6-Abfragen kann sich die Konfiguration verändern; wir behaupten daher
keine atomare Gesamtsicht.

Die Kommandozeile `bin/network-route-report` übernimmt Parameter,
Betriebssystemaufrufe, sichere Dateieingabe, Größenbegrenzung und Ausgabe.
Das unabhängige Modul `lib/SASD/Freeware/NetworkRoutes.pm` prüft die gesamte
Eingabe ohne Betriebssystemzugriffe. Linux- und macOS/BSD-Parser sind
getrennt implementiert. Die Struktur knüpft an M8.1 an, ohne beide
Werkzeuge fest miteinander zu koppeln.

## Aufruf

```sh
bin/network-route-report
bin/network-route-report --family inet6
bin/network-route-report --input /pfad/linux-routen.json --format ip-json
bin/network-route-report --input /pfad/routes.netstat --format netstat --null
bin/network-route-report --input - --format ip-json --family inet
```

Parameter: `--family all|inet|inet6` (Standard `all`),
`--format auto|ip-json|netstat`, `--input DATEI|-`, `--null`, `--help` und
`--version`. `--input -` liest stdin; Dateipfade dürfen keine symbolischen
Links sein. Das Ausgabeformat `--null` trennt die acht Felder pro Route
mit NUL und enthält keine Kopfzeile.

## Native Adapter und unterstützte Eingaben

- **Linux:** `ip -j -4 route show table all` und
  `ip -j -6 route show table all`, jeweils mit festem absolutem Programmpfad.
- **macOS/BSD:** `netstat -rn -f inet` und `netstat -rn -f inet6`. Die
  Familie wird anhand der Überschriften `Internet:` und `Internet6:` erfasst.
  Unterschiede zwischen einzelnen BSD-Versionen müssen vor einer
  vollständigen Plattformfreigabe praktisch geprüft werden.
- Es werden weder Shell-Befehle zusammengesetzt noch Konfigurationsänderungen
  durchgeführt. Policy Routing, VRFs, Netzwerk-Namensräume sowie
  Kernel-Routingentscheidungen sind noch nicht Gegenstand von M8.2.

Eine gespeicherte Linux-Doppelaufnahme verwendet genau ein JSON-Objekt mit
zwei Arrays `inet` und `inet6`, beispielsweise:

```json
{
  "inet": [{"dst":"default","gateway":"192.0.2.1","dev":"eth0","metric":100}],
  "inet6": [{"dst":"default","gateway":"fe80::1%eth0","dev":"eth0"}]
}
```

Ein einzelnes JSON-Array darf ausschließlich zusammen mit `--family inet`
oder `--family inet6` eingelesen werden, weil sonst `default` nicht
eindeutig wäre. Native Linux-Abfragen werden intern zusammengeführt.

Eine gespeicherte macOS/BSD-Aufnahme enthält die Abschnitte `Internet:` und
`Internet6:` mit Spalten `Destination Gateway Flags ... Netif`.
Bei `--family all` sind beide Abschnitte erforderlich; selbst leere Tabellen
müssen vollständig gekennzeichnet sein. Die Textdatei muss mit Zeilenumbruch
enden. Unvollständige/mehrdeutige oder ungewöhnliche, noch nicht
unterstützte Routen werden **abgewiesen**, nicht heimlich ignoriert.

## Ausgabe

Die TSV-Spalten lauten:

`FAMILY`, `DESTINATION`, `GATEWAY`, `INTERFACE`, `TABLE`, `METRIC`, `TYPE`,
`FLAGS`.

Die Felder enthalten die Adressfamilie, das Ziel bzw. `default`, den
Gateway-/Link-Referenzwert, die Schnittstelle sowie – soweit bekannt –
Routing-Tabelle, Metrik, Typ und Flags. Der Platzhalter `-` bedeutet
**nicht überliefert**, keinesfalls automatisch `0`. Eine Link-Referenz
`link#4` ist kein IP-Gateway; IPv6-Zonen wie `%en0` bleiben erhalten.
Routinginformationen sind sensible Infrastruktur-Metadaten und sollten
nur bewusst weitergegeben werden.

**Grenzen:** Multi-Path-/ECMP-Routen, Linux-`nhid`, `via` und
Encapsulation haben noch keine ausreichende Darstellung und werden deshalb
zurückgewiesen. Abgekürzte BSD-Zielnetze wie `127` oder `10/8` bleiben als genau solche
Rohwerte erhalten und werden nicht willkürlich in CIDR umgedeutet. Eingaben sind auf insgesamt 8 MiB,
8192 Routen und endliche Zeilenlängen begrenzt. Eine vollständige
Live-Abnahme auf macOS/BSD steht aus.

## Rückgabecodes und Test

| Code | Bedeutung |
| --- | --- |
| `0` | Vollständige, gültige Momentaufnahme (auch ohne Einträge) |
| `2` | Ungültige Optionen oder ungeeigneter nativer Formatwunsch |
| `3` | Programm/Datei nicht verfügbar, Backend-Fehler oder ungültige/unvollständige Aufnahme |

Bei Fehlern werden weder eine unvollständige Tabelle noch rohe Eingaben,
private Dateipfade oder Diagnosewerte ausgegeben. Der Parser prüft **alle**
Datensätze, bevor er ein Ergebnis freigibt.

```sh
perl -c bin/network-route-report
perl -c lib/SASD/Freeware/NetworkRoutes.pm
prove -v tests/test_network_route_report.t
make test
make shellcheck
```

Die Offline-Regressionen decken IPv4/IPv6, Default-Gateways,
Link-Referenzen, IPv6-Zonen, schadhafte Eingaben, Symlinks, Größenlimits und
NUL-Ausgabe ab. Die GitHub-CI kontrolliert Installation/Deinstallation auf
Ubuntu und macOS. Echte Systemausgaben bleiben gesonderte Abnahmekriterien.
