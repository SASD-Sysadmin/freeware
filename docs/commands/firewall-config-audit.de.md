# `firewall-config-audit` – lesende Linux-/BSD-Firewall-Inventarisierung (M8.4.1/M8.4.2)

## Ziel und Sicherheitskonzept

Das Werkzeug liest **genau eine ausdrücklich gewählte Firewall-Quelle** und
erstellt daraus eine eng begrenzte Bestandsaufnahme. Die Kommandozeile
`bin/firewall-config-audit` ist für die Erfassung und Ausgabe zuständig; das
reine Perl-Modul `lib/SASD/Freeware/FirewallAudit.pm` interpretiert die Linux-Formate.
Das separate Modul `lib/SASD/Freeware/FirewallBSD.pm` verarbeitet BSD-Ausgaben
unter denselben Eingabe- und Ausgabegrenzen. Das Modul führt selbst keinerlei
Systembefehle aus.

**Es werden keine Firewall-Regeln hinzugefügt, gelöscht, aktiviert, gespeichert,
neu geladen oder verändert.** Auch `sudo` wird nicht ausgeführt. Für die
Einsicht in Kernelregeln können Berechtigungen erforderlich sein. Ein
Berechtigungsfehler führt zu Exit-Code 3, niemals zu einem angeblichen
Firewall-Status `INACTIVE`.

## Getrennte Linux- und BSD-Quellen

| Option `--source` | Erfassung | Aussagebereich |
| --- | --- | --- |
| `ufw-config` | `/etc/ufw/ufw.conf` | `configuration`: UFW-Boot-Einstellung `ENABLED` oder `DISABLED` |
| `ufw-status` | `ufw status verbose` | `runtime`: UFW-Verwaltungsstatus `ACTIVE` oder `INACTIVE`; Anzahl angezeigter Regeln |
| `nft-json` | `nft --json list ruleset` | `runtime`: vorgefundene Tabellen/Ketten, Richtlinien und Anzahl von Regelobjekten |
| `iptables-save` | `iptables-save` | `runtime`: IPv4-Ketten, Richtlinien und Anzahl der `-A`-Regeln |
| `ip6tables-save` | `ip6tables-save` | `runtime`: Entsprechende Daten für IPv6 |
| `pf-info` | `pfctl -s info` (OpenBSD/FreeBSD) | `runtime`: gemeldeter PF-Status `ACTIVE`/`INACTIVE` |
| `pf-rules` | `pfctl -s rules` (OpenBSD/FreeBSD) | `runtime`: `PARTIAL`-Zählung des Hauptregelsatzes und der Anchor-Verweise |
| `ipfw-list` | `ipfw list` (FreeBSD) | `runtime`: `PARTIAL`-Zählung nummerierter statischer Regeln |
| `npf-show` | `npfctl show` (NetBSD) | Separat: `runtime` `ACTIVE`/`INACTIVE` und `configuration` `LOADED`/`EMPTY` |

Die Quellen werden **nicht** zu einer gemeinsamen Zahl addiert. UFW verwaltet
Netfilter, und `iptables-nft` kann dieselben Kernelregeln wie `nftables`
anzeigen. `iptables-save` allein beweist nicht, ob das Legacy- oder
nft-Kompatibilitätsbackend verwendet wird.

**Wichtig:** `ENABLED=yes` ist nicht gleichbedeutend mit geladenen Regeln.
`ufw status inactive` bedeutet nicht, dass das gesamte System ohne Firewall
arbeitet. `OBSERVED` bedeutet nur, dass wir eine auswertbare Momentaufnahme
gelesen haben – keineswegs, dass der Host sicher oder der Filter aktiv ist.
Eine Kettenrichtlinie wird angezeigt, aber nicht zu einer garantierten
Netzwerkentscheidung umgedeutet.

## Beispiele

```sh
bin/firewall-config-audit --source ufw-config
bin/firewall-config-audit --source ufw-status
bin/firewall-config-audit --source nft-json
bin/firewall-config-audit --source iptables-save
bin/firewall-config-audit --source ip6tables-save
# Nur auf dem jeweils passenden BSD-System:
bin/firewall-config-audit --source pf-info
bin/firewall-config-audit --source pf-rules
bin/firewall-config-audit --source ipfw-list
bin/firewall-config-audit --source npf-show

# Gespeicherte Ausgabe untersuchen (auch auf anderen Unix-Systemen):
bin/firewall-config-audit --source nft-json --input /pfad/nft-export.json
bin/firewall-config-audit --source ufw-config --input /pfad/ufw.conf
bin/firewall-config-audit --source iptables-save --input - --null
bin/firewall-config-audit --source pf-info --input /pfad/pf-info.txt
```

Ohne `--input` erfolgen Linux-Abfragen nur unter Linux, PF-Abfragen nur
unter OpenBSD/FreeBSD, IPFW unter FreeBSD und NPF unter NetBSD.
Die native BSD-Kompatibilität muss auf echten BSD-Systemen noch abgenommen
werden; Offline-Tests auf Ubuntu/macOS ersetzen diese Prüfung nicht. Die
gewählte Quelle wird **niemals automatisch erraten**. Offline-Dateien müssen
gewöhnliche lesbare Dateien sein; symbolische Links werden abgewiesen.
`--input -` liest die Standardeingabe.

## Architektur

1. **Erfassung:** ausschließlich fest vorgegebene absolute Programmpfade,
   unveränderliche Leseparameter oder eine geprüfte Konfigurationsdatei.
   Kein Aufruf über eine Shell, kein `sudo`, keine Schreiboperation.
2. **Grenzen:** maximal 8 MiB Eingabedaten, zusätzlich begrenzte Zeilen,
   Objekte und JSON-Verschachtelungstiefe. Fehlende oder widersprüchliche
   Eingaben werden abgewiesen.
3. **Getrennte Parser:** UFW-Konfiguration, UFW-Laufzeitstatus, nftables-JSON
   sowie IPv4/IPv6-iptables-save bleiben verschiedene Formate. BSD hat
   zusätzliche, eigenständige Parser in `FirewallBSD.pm`.
4. **Datensparsame Ausgabe:** keine einzelnen Regeln, IP-Adressen, Kommentare,
   Geheimnisse oder Eingabepfade. Die Ausgabe beginnt **erst nach vollständig
   erfolgreicher Prüfung**.

Das TSV-Format hat acht Spalten, getrennt durch Tabulatoren:

```text
ENGINE  SCOPE  STATE  FAMILY  TABLE  CHAIN  POLICY  RULES
```

`ENGINE` beschreibt die Quelle (`ufw`, `nftables`, `iptables`, `ip6tables`,
`pf`, `ipfw`, `npf`).
`SCOPE` unterscheidet `configuration` und `runtime`. `STATE` ist bei UFW
`ENABLED`/`DISABLED` oder `ACTIVE`/`INACTIVE`, bei Kernelmomentaufnahmen
`OBSERVED`. `FAMILY`, `TABLE`, `CHAIN` und `POLICY` enthalten nur validierte
Strukturangaben. `RULES` zählt je nach Quelle die angezeigten UFW-Regeln,
iptables-`-A`-Zeilen oder nftables-Regelobjekte. Diese Zahlen sind
quellenübergreifend **nicht direkt vergleichbar**. `-` kennzeichnet eine
nicht verfügbare oder nicht anwendbare Eigenschaft.

Mit `--null` werden acht NUL-terminierte Felder pro Datensatz ausgegeben,
ohne Tabellenkopf.

## Beispiele für Offline-Eingaben

`ufw-config`:

```text
ENABLED=yes
LOGLEVEL=low
```

`ufw-status`:

```text
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
```

`nft-json`:

```json
{"nftables":[
  {"table":{"family":"inet","name":"filter"}},
  {"chain":{"family":"inet","table":"filter","name":"input","type":"filter","hook":"input","prio":0,"policy":"drop"}},
  {"rule":{"family":"inet","table":"filter","chain":"input","expr":[]}}
]}
```

`iptables-save`:

```text
*filter
:INPUT DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -p tcp --dport 22 -j ACCEPT
COMMIT
```

Text-Snapshots benötigen einen abschließenden Zeilenumbruch. Doppelte
Kettendeklarationen, unbekannte Objekttypen, verwaiste Regeln, abgeschnittene
Tabellen und unzulässige Steuerzeichen werden verworfen – ohne Teilausgabe.

## Exit-Codes und Grenzen

| Code | Bedeutung |
| --- | --- |
| `0` | Gewählte Quelle vollständig und gültig gelesen; auch ein leerer Regelsatz ist zulässig |
| `2` | Ungültige Optionen oder fehlende/ungültige Quelle |
| `3` | Fehlendes Programm, verweigerter Zugriff, fehlerhafte, zu große oder unvollständige Daten |

Bei Fehlern werden keine vertraulichen Eingaben oder Pfade ausgegeben.
Wir prüfen **keine vollständige Netzwerkerreichbarkeit**, keine Wirksamkeit
aller Regeln, keine parallelen Netzwerk-Namensräume und keine Compliance.
Konfiguration und Kernel können auseinanderlaufen; Aufnahmen aus getrennten
Aufrufen sind nicht atomar.

## Testen und Erweiterbarkeit

```sh
perl -c bin/firewall-config-audit
perl -c lib/SASD/Freeware/FirewallAudit.pm
prove -v tests/test_firewall_config_audit.t
prove -v tests/test_firewall_bsd_audit.t
perl -c lib/SASD/Freeware/FirewallBSD.pm
make test
make shellcheck
```

Die Regressionstests arbeiten mit synthetischen, vollständig offline
verarbeiteten Daten und benötigen keine Root-Rechte. Native Prüfdaten sollten
später in isolierten Linux-Testsystemen gesammelt werden.

M8.4.2 stellt erste, bewusst eng begrenzte BSD-Adapter für PF (OpenBSD/
FreeBSD), IPFW (FreeBSD) und NPF (NetBSD) bereit. Native Abnahmetests
stehen noch aus. Solaris PF/IPFilter, HP-UX IPFilter und SGI IRIX `ipfilterd`
bleiben geplant; fremde Firewalls werden nicht nach Linux-Art interpretiert.

## M8.4.2 – Bedeutung der BSD-Ausgaben

* **PF:** `pf-info` liest nur `Status: Enabled` beziehungsweise `Disabled`.
  `pf-rules` zählt Filterregeln (`pass`, `block`, `match`) und Anchor-Verweise
  getrennt im **Hauptregelsatz**; Anchor-Inhalte sowie NAT-/RDR-Regeln,
  Tabellen und andere Filter bleiben unberücksichtigt. Deshalb `PARTIAL`.
* **IPFW:** `ipfw-list` zählt die nummerierten statischen Zeilen einschließlich
  der Standardregel 65535. Dynamische Zustände, deaktivierte Regelsets und
  Kernel-Aktivität werden nicht vollständig erfasst; daher stets `PARTIAL`.
* **NPF:** `npf-show` meldet den Laufzeitstatus und den Ladezustand der
  Konfiguration **in zwei separaten Zeilen**. `ACTIVE` bei leerer Konfiguration
  ist möglich. Die vollständige NPF-Regelsyntax wird nicht nachgebildet;
  deshalb geben wir keine erfundenen Regelanzahlen aus.

Weder `ACTIVE` noch `PARTIAL` belegen die wirksame Absicherung des gesamten
Hosts. Die Erfassung führt keine schreibenden Kommandos aus, gibt keine IPs
oder Regeln aus und bricht bei unvollständigen Daten ohne Teilausgabe ab.
Für produktiven Einsatz sind Tests in isolierten BSD-VMs erforderlich.

## Referenzen

- [UFW-Manpage](https://manpages.debian.org/ufw/ufw.8.en.html)
- [nftables-Regelwerk-Export](https://wiki.nftables.org/wiki-nftables/index.php/Operations_at_ruleset_level)
- [iptables-save](https://manpages.debian.org/iptables/iptables-save.8.en.html)

- [OpenBSD pfctl(8)](https://man.openbsd.org/pfctl)
- [FreeBSD Firewall-/IPFW-Handbuch](https://docs.freebsd.org/de/books/handbook/firewalls/)
- [NetBSD npfctl(8)](https://man.netbsd.org/NetBSD-9.5/npfctl.8)


## M8.4.3 – Oracle Solaris (vorläufig)

Für die getrennten **Solaris-PF-/IPFilter-/SMF-Quellen**, die festen
Leseaufrufe, Datenschutzgrenzen und spätere native Abnahme siehe
[Solaris-Abnahme](firewall-solaris-acceptance.de.md).
