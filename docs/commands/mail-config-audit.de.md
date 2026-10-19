# mail-config-audit — statisches Postfix-Konfigurationsaudit (M6.3)

[English](mail-config-audit.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/mail-config-audit.1)

`mail-config-audit` untersucht die Textkonfigurationen `main.cf` und optional
`master.cf` **ausschließlich lesend**. Weder Postfix noch `postconf` werden
ausgeführt. Das Programm verändert keine Konfigurationen oder Nachrichten.

**Wichtig:** Geprüft werden ausdrücklich gesetzte Parameter, **nicht die
tatsächlich wirksame Gesamtkonfiguration**. Postfix-Standardwerte,
Parameterersetzungen, Lookup-Tabellen und Dienst-Overrides können das
Laufzeitverhalten beeinflussen. Ein Ergebnis ohne ISSUE ist **kein
Nachweis**, dass der Mailserver sicher oder kein offenes Relay ist.

## Beispiele

```sh
./bin/mail-config-audit --main /etc/postfix/main.cf --master /etc/postfix/master.cf
./bin/mail-config-audit --main /absoluter/pfad/zur/main.cf
./bin/mail-config-audit --main /absoluter/pfad/zur/main.cf --null
```

Ohne `--main` wird `/etc/postfix/main.cf` verwendet. `--master` ist
optional. Zulässig sind lesbare reguläre Dateien mit absolutem Pfad,
keine symbolischen Links. Root-Rechte sind nicht erforderlich, sofern
die Dateien lesbar sind. `--null` gibt pro Befund vier NUL-abgeschlossene
Felder und einen zusammenfassenden Datensatz aus.

Die Standardausgabe ist tabulatorgetrennt:

```text
LEVEL  SOURCE  LINE  CODE
ISSUE  main    4     mynetworks-matches-all-addresses
NOTE   master  0     master-cf-not-inspected
Issues: 1
Notes: 2
```

Dies ist lediglich ein Beispiel, kein echter Systemscan. `SOURCE` ist
`main` oder `master`. Dateipfade, Parameterwerte, Passwörter, Hostnamen,
E-Mail-Adressen und rohe Client-Meldungen werden **niemals ausgegeben**.
Zeilennummer 0 kennzeichnet einen allgemeinen Prüfhintergrund.

## Prüfumfang

| Art | Befund | Bedeutung |
| --- | --- | --- |
| ISSUE | `mynetworks` enthält ausdrücklich `0.0.0.0/0`, `0/0` oder `::/0` | Sehr weit gefasste vertrauenswürdige Netzwerke. |
| ISSUE | Unbedingtes `permit` vor `reject_unauth_destination` oder `defer_unauth_destination` | Auffällige Reihenfolge in einer ausdrücklich gesetzten Relay-Regelliste. |
| ISSUE | SMTPD-SASL aktiviert, aber weder TLS-only-AUTH noch global verpflichtendes SMTPD-TLS eindeutig gesetzt | Klartext-Authentifizierung könnte möglich sein; dienstspezifische Schutzmaßnahmen bleiben unberücksichtigt. |
| ISSUE | Doppelte Parameter, ungültige Zuweisung, alleinstehende Fortsetzungszeile | Fehlerhafte beziehungsweise zu prüfende Textkonfiguration. |
| NOTE | Implizite/leere Relay-Regeln, Variablen, Tabellen oder komplexe Freigaben | Wirksame Relay-Kontrolle lässt sich statisch nicht sicher bestimmen. |
| NOTE | `mynetworks_style=subnet`, explizit abgeschaltetes TLS, VRFY aktiv | Administrativer Prüfhinweis, nicht zwingend eine Schwachstelle. |
| NOTE | Fehlende `master.cf`, `-o`-Overrides oder nicht verstandene Master-Syntax | Dienstkonfiguration muss separat geprüft werden. |

`main.cf` wird über `name = wert` und Fortsetzungszeilen geparst.
Die vollständige Postfix-Grammatik für `master.cf` wird **nicht**
implementiert. Erkannte `-o`-Dienst-Overrides werden als Prüfhinweis
ausgewiesen. Beispielsweise kann ein Submission-Dienst globale
SASL-/TLS-Parameter sicher überschreiben. Daher ist ein main.cf-SASL-
Hinweis keine Behauptung, dass ein öffentlich erreichbarer Dienst
unsichere Anmeldung erlaubt.

**Port 25 darf nicht pauschal verpflichtendes TLS vorgeschrieben werden.**
Opportunistisches TLS ist für Internet-MX-Systeme üblich. Seit Postfix
2.10 ist `smtpd_relay_restrictions` die zentrale Trennung der Relay-
Kontrolle; ältere und explizit abweichende Konfigurationen müssen auch
`smtpd_recipient_restrictions` berücksichtigen.

## Grenzen und Rückgabewerte

- Je Datei höchstens 2 MiB, 10.000 Zeilen und 16 KiB pro physischer Zeile.
  Bei unvollständiger oder ungültiger Eingabe erscheint **kein Teilbericht**.
- Relative Pfade, Symlinks, Steuerzeichen und verdächtige Punkt-Pfadteile
  werden abgewiesen. Es werden keine Shell-Kommandos ausgeführt.
- `0`: Prüfung abgeschlossen, keine nachgewiesenen statischen ISSUEs;
  **kein** Gütesiegel für Postfix im Produktivbetrieb.
- `1`: mindestens ein statischer ISSUE-Befund.
- `2`: fehlerhafte Aufrufparameter.
- `3`: fehlende, unlesbare, übergroße oder ungültige Eingabe bzw. Laufzeitfehler.
- Postfix-Defaults, Parameterauflösung, Maps, tatsächliche TLS-Zertifikate,
  aktive Dienste, Service-Overrides und Netzwerkzugriff werden nicht
  abschließend geprüft. Das Programm garantiert keine vollständige
  Open-Relay-Erkennung.

Referenzen: [Postfix-Zugriffskontrolle](https://www.postfix.org/SMTPD_ACCESS_README.html),
[postconf(5)](https://www.postfix.org/postconf.5.html),
[postconf(1)](https://www.postfix.org/postconf.1.html),
[SASL](https://www.postfix.org/SASL_README.html).
