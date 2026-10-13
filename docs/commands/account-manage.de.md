# account-manage

[English](account-manage.md) · [Projekt](../../README.de.md)

`account-manage` ist eine bewusst eng begrenzte Verwaltung **lokaler Linux-Konten**. **Unter macOS und anderen Nicht-Linux-Systemen wird auch die Vorschau ausdrücklich verweigert (Exitstatus 3)**, statt nicht anwendbare Linux-Befehle für Directory-Services-Konten vorzuschlagen. Standardmäßig wird ausschließlich eine Vorschau erzeugt. Änderungen brauchen **beide** Schalter `--apply --confirm-apply` und Root-Rechte. **NIS, NIS+, LDAP, FreeIPA und Active Directory werden nicht verwaltet.**

## Aktionen und Beispiele

```sh
./sbin/account-manage --action user-create --name newoperator
./sbin/account-manage --action group-create --name appteam
./sbin/account-manage --action password-lock --name oldoperator

# Erst prüfen, dann ausdrücklich auf einem Testsystem anwenden:
sudo ./sbin/account-manage --action group-create --name appteam --apply --confirm-apply
```

| Aktion | Linux-Systembefehl | Bedeutung |
|---|---|---|
| `user-create` | `useradd -m -- NAME` | **Lokales** Konto mit Home-Verzeichnis anlegen; Standardwerte für UID, Shell und Gruppe ergeben sich aus der Systemkonfiguration. |
| `group-create` | `groupadd -- NAME` | **Lokale** Gruppe entsprechend den Systemvorgaben anlegen. |
| `password-lock` | `usermod -L -- NAME` | Das **Passwort** sperren. **SSH-Schlüssel, aktive Sitzungen, Dienste und Tokens bleiben davon unberührt.** Nur für lokale, nicht-systemische Benutzer. |

Die Namen müssen kurz und einfach sein (kleingeschriebene Linux-Namen). Root und das Sperren von Systemkonten sind ausgeschlossen. Vorhandene lokale oder über NSS auflösbare Namen werden bei Neuanlage abgelehnt. Bei fehlerhaften lokalen Kontendateien oder historischen NIS-Kompatibilitätseinträgen werden **alle Änderungen verweigert**. Eine negative NSS-Abfrage beweist aber **nicht**, dass ein Name in sämtlichen entfernten Identitätsdiensten frei ist.

## Sicherheit und Voraussetzungen

- Die Vorschau führt keinen nativen Verwaltungsbefehl aus; sie liest die lokalen Kontendateien und fragt NSS ab.
- Tatsächliche Änderungen sind **nur unter Linux** mit geeigneten shadow-utils (`useradd`, `groupadd`, `usermod`) vorgesehen. Fehlende Programme führen zu einer klaren Fehlermeldung.
- Vor dem Ausführen werden geschützte, reguläre und Root-gehörende `/etc/passwd`- und `/etc/group`-Dateien sowie der Eigentümer- und Rechtestatus des Programmwegs kontrolliert. Der Aufruf verwendet kein Shell-Parsing.
- Änderungen sind **nicht transaktional**. Ein nativer Befehl könnte trotz Fehlschlag bereits Teile verändert haben. Deshalb Hostzustand unabhängig nachprüfen und produktive Systeme nicht ohne vorherige Prüfung verändern.
- Keine frei wählbaren UIDs/GIDs, Passwortwerte, Änderungen an `/etc/shadow`, Löschaktionen oder Beendigung laufender Sitzungen. Die automatisierten Tests führen **keine echten Änderungen an Systemkonten** durch; dafür wird eine isolierte Linux-VM benötigt.

## Rückgabewerte

`0`: Vorschau oder nativer Befehl erfolgreich (keine unabhängige Bestätigung des Endzustands); `2`: Parameterfehler oder fehlende Bestätigung; `3`: fehlende oder unsichere Voraussetzungen, unbekannte Identität, nicht unterstütztes System oder Fehler im nativen Befehl.
