# M8.4.3 – Solaris-Firewall-Adapter: Betrieb und spätere Abnahme

## Ziel und Plattformgrenzen

`firewall-config-audit` unterstützt nun **vorläufige, ausschließlich lesende**
Firewall-Bestandsaufnahmen für Oracle Solaris. In unserer CI stehen keine
Solaris-Systeme zur Verfügung; die automatisierten Tests verwenden
synthetische Daten unter Linux/macOS. **Die native Solaris-Funktion gilt
bis zu einer echten Systemabnahme ausdrücklich als unbestätigt.**

Die Solaris-Version ist entscheidend:

- **Solaris 10 und 11.0–11.2:** IPFilter (`ipfstat`) mit SMF-Dienstverwaltung.
- **Solaris 11.3:** IPFilter und PF als alternative, nicht parallel zu
  aktivierende Firewall-Systeme.
- **Solaris 11.4:** PF ersetzt IPFilter; IPFilter steht nicht mehr bereit.

Das Werkzeug wählt kein Backend automatisch aus. Es gibt keine Aussage
„Host ist geschützt“ oder „Firewall ist aktiv“ aus der bloßen Existenz eines
Regelsatzes ab. `svcs` meldet **Dienstzustände**, nicht die tatsächliche
Wirksamkeit im Kernel. Gerade `degraded` kann bei Solaris PF eine
Standard-/Fallback-Konfiguration anzeigen und darf nicht als `ACTIVE`
fehlinterpretiert werden.

## Quellen und feste, ausschließlich lesende Befehle

| `--source` | Nativer Befehl (nur SunOS) | Bedeutung |
| --- | --- | --- |
| `solaris-pf-service` | `svcs -H -o state svc:/network/firewall:default` | PF-Dienstzustand (`service`) |
| `solaris-pf-rules` | `pfctl -sr` | PF-Hauptregelwerk und Anchor-Verweise (`PARTIAL`) |
| `solaris-ipf-service` | `svcs -H -o state svc:/network/ipfilter:default` | IPFilter-Dienstzustand (`service`) |
| `solaris-ipf-rules4` | `ipfstat -io` | Aktive IPv4-Ein-/Ausgangsregeln (`PARTIAL`) |
| `solaris-ipf-rules6` | `ipfstat -6io` | Aktive IPv6-Ein-/Ausgangsregeln (`PARTIAL`) |

Es sind ausschließlich diese festen Leseaufrufe zugelassen. **Kein `sudo`,
`svcadm`, `ipf -f`, `pfctl -f`, `pfctl -e` oder Regel-Neuladen.** Fehlende
Programme oder fehlende Rechte ergeben Exit-Code 3 ohne Teilausgabe.
Dass IPFilter unter Solaris 11.4 fehlt, ist keine Aussage über den Status
von PF oder den Schutz des Systems.

Das Werkzeug führt Quellen nicht zusammen und ruft keine Shell mit
frei übergebenen Parametern auf. `--input DATEI` verarbeitet gespeicherte
Momentaufnahmen plattformunabhängig und ohne Root-Rechte.

## Beispiele

```sh
bin/firewall-config-audit --source solaris-pf-service
bin/firewall-config-audit --source solaris-pf-rules
bin/firewall-config-audit --source solaris-ipf-service
bin/firewall-config-audit --source solaris-ipf-rules4
bin/firewall-config-audit --source solaris-ipf-rules6

# Gespeicherte Prüfdaten offline auswerten:
bin/firewall-config-audit --source solaris-pf-service --input ./svcs-state.txt
bin/firewall-config-audit --source solaris-ipf-rules4 --input ./ipfstat-ipv4.txt
```

Bei nativen Regelabfragen können besondere Leserechte erforderlich sein.
`ipfstat -io` beziehungsweise `-6io` fragen die **aktiven** Regelwerke ab.
Das große `-I` würde dagegen zum **inaktiven** Staging-Regelwerk wechseln
und wird bewusst nicht verwendet.

## Berichtsmodell und Einschränkungen

Das vorhandene Acht-Felder-Schema bleibt bestehen:
`ENGINE, SCOPE, STATE, FAMILY, TABLE, CHAIN, POLICY, RULES`.
Ausgabe standardmäßig als TSV oder mit `--null` in NUL-Feldterminierung.

- `pf` bzw. `ipfilter` beschreibt die Quelle. `service` und `runtime`
  unterscheiden Dienstzustand und ausgelesenen Laufzeitregelsatz.
- SMF-Zustände werden als `ONLINE`, `OFFLINE`, `DISABLED`, `DEGRADED`,
  `MAINTENANCE`, `UNINITIALIZED`, `LEGACY_RUN` ausgegeben.
- `PARTIAL` kennzeichnet **nur gezählte, erkannte Zeilen** eines
  Hauptregelwerks. PF-Ankerinhalte werden nicht rekursiv ermittelt;
  IPFilter-NAT, Pools und inaktive Regelsätze fehlen ebenfalls.
- Einzelregeln, IP-Adressen, Schnittstellen, Kommentare und Dateipfade
  werden nicht ausgegeben.

Null Regeln beweisen nicht, dass keine Firewall existiert; einige Regeln
beweisen nicht, dass gefiltert wird. Die Zahlen dürfen nicht mit
Linux- oder BSD-Regeln zu einer vermeintlichen Gesamtzahl addiert werden.

## Spätere echte Systemabnahme (verschoben, nicht gestrichen)

1. Auf einem nicht produktiven Solaris 10/11.2 den Zustand des Dienstes
   `svc:/network/ipfilter:default` und die Ausgaben von `ipfstat -io`
   sowie nach Möglichkeit `ipfstat -6io` erfassen und vergleichen.
2. Unter Solaris 11.3 IPFilter und PF **getrennt** überprüfen; für einen
   Test keines der Systeme aktivieren oder Regeln neu laden.
3. Unter Solaris 11.4 PF-Dienst und `pfctl -sr` prüfen. Insbesondere
   `degraded`, `online` und `disabled` unterscheiden. Fehlendes IPFilter
   ist **kein** Beleg für „Firewall inaktiv“.
4. Tatsächliche Ausgabevarianten, Rechte und Leerdarstellungen prüfen.
   Falls notwendig Parser nur anhand **anonymisierter** Testdaten anpassen
   und zusätzliche Regressionstests erstellen.
5. Danach erneut alle Tests, ShellCheck, Installations-/Deinstallations-
   und Ubuntu-/macOS-CI-Prüfungen ausführen.

### Dokumentation von Oracle

- [Solaris 11.4 PF-Verwaltung](https://docs.oracle.com/cd/E37838_01/html/E60993/pftask-pfctl.html)
- [Solaris 11.4 PF-Überwachung](https://docs.oracle.com/cd/E37838_01/html/E60993/pftask-mon.html)
- [Abgekündigte Solaris-11-Funktionen](https://www.oracle.com/solaris/technologies/end-of-feature-notices-solaris11.html)
- [IPFilter – aktives Regelwerk](https://docs.oracle.com/cd/E19120-01/open.solaris/819-3000/eubbd/index.html)
- [Solaris 11.3 IPFilter/IPv6](https://docs.oracle.com/cd/E53394_01/pdf/E54829.pdf)
