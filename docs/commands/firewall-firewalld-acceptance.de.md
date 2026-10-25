# firewalld – M8.4.5 Linux-Abnahme und Grenzen

## Umfang und Sicherheit

`firewall-config-audit` unterstützt vier ausdrücklich wählbare firewalld-
Quellen. Die Ausgabe ist ein **lesendes Inventar der Verwaltungsebene**,
keine Aussage zur tatsächlich durchgesetzten Paketfilterung, zur Erreichbarkeit
oder zur Sicherheit des Hosts. Regeln aus `nftables`, `iptables` und firewalld
können sich auf dieselben Kernelobjekte beziehen und dürfen nicht addiert werden.

Die CLI startet `firewall-cmd` ausschließlich über festgelegte absolute Pfade
mit unveränderlichen Leseoptionen. Kein `sudo`, keine Shell, kein `--reload`,
keine Änderungen an Regeln und kein `--runtime-to-permanent`. Fehlende
Berechtigungen, unbekannte Ausgaben und fehlende Backends führen zu Exit 3,
**ohne** eine irreführende Teilausgabe.

| `--source` | Lesender Befehl | Aussage |
| --- | --- | --- |
| `firewalld-state` | `firewall-cmd --state` | Zustand des Daemons, `RUNNING` ist kein Sicherheitsbeleg |
| `firewalld-active-zones` | `firewall-cmd --get-active-zones` | Gebundene Zonennamen (`BOUND`) oder `NONE_BOUND`, ohne Schnittstellen und Quellnetze |
| `firewalld-runtime-zones` | `firewall-cmd --list-all-zones` | Laufzeit, `PARTIAL`, ausschließlich Anzahl angezeigter Rich Rules pro Zone |
| `firewalld-permanent-zones` | `firewall-cmd --permanent --list-all-zones` | Gespeicherte Konfiguration, `PARTIAL`, keine Aussage zur aktuellen Kernelwirkung |

Die Spalte `RULES` enthält bei den beiden Zonenabfragen **nur die Zahl der
angezeigten Rich Rules**. Dienste, Ports, Direct Rules, Weiterleitungen,
Policies, nftables-Kernelregeln und Container-Netzwerke werden nicht mitgezählt.
Auch null Rich Rules bedeutet **nicht**, dass keine Filterung erfolgt.
`NONE_BOUND` bedeutet lediglich, dass keine aktiven Schnittstellen-/Quell-
Zuordnungen angezeigt wurden. Die Standardzone kann trotzdem gelten.

## Beispiele

```sh
bin/firewall-config-audit --source firewalld-state
bin/firewall-config-audit --source firewalld-active-zones
bin/firewall-config-audit --source firewalld-runtime-zones
bin/firewall-config-audit --source firewalld-permanent-zones

# Replay ohne Systemzugriff:
bin/firewall-config-audit --source firewalld-runtime-zones --input zones.txt
```

TSV und `--null` behalten acht Felder bei:
`ENGINE`, `SCOPE`, `STATE`, `FAMILY`, `TABLE`, `CHAIN`, `POLICY`, `RULES`.
Nur validierte Zonennamen, normalisierte Ziele und Zahlen werden ausgegeben;
keine IP-Adressen, Schnittstellen, Ports oder Rich-Rule-Inhalte.

## Aufbau und Testgrenzen

`FirewallFirewalld.pm` enthält die eigenständigen Perl-Parser ohne Dateizugriff,
Shell- oder Systemaufrufe. Die CLI trennt Erfassung, Größenbegrenzung, vollständige
Validierung und Ausgabe. Die Eingabe ist auf 8 MiB, 16.384 Zeilen und begrenzte
Feldlängen beschränkt. Fremde Textformate werden ausdrücklich zurückgewiesen.
Die Runtime- und Permanent-Quellen sind nicht transaktional gemeinsam lesbar.

Für die **spätere native Abnahme** sind vorgesehen: Debian, Ubuntu LTS,
Arch Linux, AlmaLinux, Rocky Linux, Fedora, openSUSE und ergänzend Alpine.
Dabei vergleichen wir jeweils die echte Ausgabe von `firewall-cmd` mit dem
SASD-Bericht. Bitte keine Firewall-Regeln auf einem produktiven oder remote
erreichbaren Host verändern, um Tests zu erzwingen. Sanitisierte Prüfdaten,
Versionen und Exit-Codes dokumentieren, aber keine internen Netze veröffentlichen.

**Abnahmestatus:** Synthetische Offline-Tests vorhanden; eine reale Abnahme
auf Arch/AlmaLinux/RockyLinux wird noch nicht behauptet.

Dokumentation des Herstellers:
https://firewalld.org/documentation/man-pages/firewall-cmd.html
https://firewalld.org/documentation/configuration/runtime-versus-permanent.html
