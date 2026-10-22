# network-interface-report (M8.1)

**Kapitel 10 – Sicherheit und Netzwerküberwachung.** Lesende Bestandsaufnahme von Netzwerkschnittstellen und IP-Adressen unter Linux sowie für macOS-artige `ifconfig`-Ausgaben.

## Zweck und Architektur

`network-interface-report` inventarisiert Schnittstellennamen, Schnittstellenindizes (soweit vorhanden), Betriebszustände, IPv4-/IPv6-Adressen, CIDR-Präfixe und Ethernet-MAC-Adressen. Das Programm **ändert keine Netzwerkkonfiguration**, baut keine Verbindung auf und prüft weder die Erreichbarkeit eines Gateways noch die Qualität einer Internetverbindung.

Die Architektur trennt drei Aufgaben:

1. **Betriebssystem-Anbindung (`bin/network-interface-report`):** Auswahl eines vertrauenswürdigen absoluten Programmpfads, Aufruf ohne Shell, begrenztes Einlesen und Kontrolle des Rückgabestatus.
2. **Validierung (`lib/SASD/Freeware/NetworkInterfaces.pm`):** ein von Betriebssystemaufrufen unabhängiger Perl-Parser mit Prüfung von Schnittstellennamen, IP-Adressen, Präfixen, Netzmasken, MAC-Adressen und Mengengrenzen.
3. **Ausgabe (Hauptprogramm):** feste TSV- oder NUL-Datensätze erst nach erfolgreicher vollständiger Prüfung.

So können wir weitere Betriebssystem-Backends später ergänzen, ohne die Ausgabestruktur umzubauen. Bewusst haben saubere Architektur und verständlich kommentierter Quellcode Vorrang vor einer frühen Leistungsoptimierung.

## Voraussetzungen

- Perl 5 mit den Kernmodulen `Getopt::Long`, `FindBin`, `JSON::PP` und `Socket` (mit `inet_pton`) sowie der mitgelieferten SASD-Bibliothek.
- Linux: `ip -j address show`, ausgeführt ausschließlich über einen festen Systempfad (`/usr/sbin/ip`, `/sbin/ip`, `/usr/bin/ip`, `/bin/ip`). Falls `ip` fehlt, meldet das Programm einen Fehler und erfindet keinen leeren Bericht.
- macOS beziehungsweise BSD-Familie: `ifconfig -a` unter `/sbin/ifconfig` oder `/usr/sbin/ifconfig`. Derzeit sind repräsentative macOS-Testdaten geprüft; **native BSD-Praxistests stehen noch aus**.
- Offline-Dateien lassen sich auf jeder Plattform mittels `--input` und `--format` auswerten.

## Beispiele

```sh
./bin/network-interface-report
./bin/network-interface-report --family inet
./bin/network-interface-report --family inet6
./bin/network-interface-report --input ./snapshot-ip.json --format ip-json
./bin/network-interface-report --input ./snapshot-ifconfig.txt --format ifconfig
./bin/network-interface-report --input ./snapshot-ifconfig.txt --null
```

Die Ausgabe enthält sieben Spalten:

| Spalte | Bedeutung |
| --- | --- |
| `INTERFACE` | Name der Schnittstelle, z. B. `en0` oder `enp0s3` |
| `INDEX` | Schnittstellenindex unter Linux; sonst `-` |
| `STATE` | Vereinfachter Betriebszustand (`UP`, `DOWN`, `UNKNOWN` usw.) |
| `FAMILY` | `inet`, `inet6` oder `-` ohne passende Adresse |
| `ADDRESS` | IPv4-/IPv6-Adresse oder `-` |
| `PREFIX` | CIDR-Präfixlänge oder `-` |
| `MAC` | Ethernet-Hardwareadresse oder `-` |

Pro IP-Adresse erscheint eine Zeile. Ohne Adresse der gewählten Familie bleibt die Schnittstelle als Platzhalter erhalten. Im NUL-Modus bestehen alle Zeilen aus **sieben nullterminierten Feldern**, ohne Tabellenüberschrift. IPv6-Zonenangaben, beispielsweise `%en0`, bleiben erhalten. Ein `status: inactive` in `ifconfig` hat Vorrang vor einem vorhandenen `UP`-Flag; dies ist dennoch kein umfassender Funktionstest der Verbindung.

## Sicherheit und Grenzen

- Maximal **8 MiB Eingabe**, **512 Schnittstellen** und **4.096 Adressdatensätze**; Textzeilen höchstens 128 KiB. Keine Teilausgabe bei Fehlern.
- Dateieingaben müssen reguläre, lesbare Dateien ohne symbolische Links sein; nach dem Öffnen wird die Dateiidentität kontrolliert.
- Fehlerhafte oder unvollständige IP-Datensätze werden abgewiesen; unbekannte ergänzende `ifconfig`-Informationen bleiben unbeachtet. Es handelt sich nicht um einen universellen Parser sämtlicher Herstellerformate.
- Der native Aufruf verwendet feste Programmpfade und übergibt Argumente direkt, **ohne Shell**.
- Achtung Datenschutz: IP- und MAC-Adressen sind absichtlich Teil des Inventars. Berichte deshalb wie vertrauliche Netzwerkdokumentation behandeln. Fehlermeldungen geben weder beliebige Quelldaten noch Eingabepfade aus.
- Momentaufnahmen sind nicht atomar: Schnittstellen können sich während oder nach der Erfassung ändern.
- Die Offline-Tests sind kein Nachweis für einen vollständig getesteten macOS- oder BSD-Livebetrieb.

## Rückgabecodes

| Code | Bedeutung |
| --- | --- |
| `0` | Gesamte Momentaufnahme erfolgreich ausgewertet. |
| `2` | Ungültige Kommandozeile oder unpassendes angegebenes natives Format. |
| `3` | Fehlendes Systemwerkzeug, misslungener nativer Aufruf, unlesbare oder fehlerhafte Eingabe oder Grenzwertüberschreitung; keine Ausgabe auf stdout. |

## Tests

```sh
perl -c bin/network-interface-report
perl -c lib/SASD/Freeware/NetworkInterfaces.pm
prove -v tests/test_network_interface_report.t
make test
make shellcheck
```

Die automatischen Offline-Tests verwenden synthetische Linux-JSON- und macOS-`ifconfig`-Ausgaben; außerdem prüfen sie Fehleingaben, Schnittstellen ohne Adressen, Filter, NUL-Datensätze und Sicherheitseigenschaften. Ubuntu-/macOS-CI prüft darüber hinaus die Installation und Deinstallation der Dateien. Native Tests auf macOS sowie FreeBSD/OpenBSD sind weitere Aufgaben und dürfen nicht als abgeschlossen dargestellt werden.
