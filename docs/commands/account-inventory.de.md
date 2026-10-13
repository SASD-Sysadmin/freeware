# account-inventory

[English](account-inventory.md) · [Projekt](../../README.de.md)

`account-inventory` gibt Benutzer- und Gruppeninformationen aus einer ausdrücklich gewählten Quelle aus: **lokale Dateien** oder die **NSS-Aufzählung** des Systems. Es verändert keine Konten oder Verzeichnisse.

## Beispiele

```sh
./bin/account-inventory
./bin/account-inventory --kind users
./bin/account-inventory --source nss --kind groups
./bin/account-inventory --source local --passwd-file ./passwd.sample --group-file ./group.sample
./bin/account-inventory --kind users --null > inventory.bin
```

## Quellen und Grenzen

- **`--source local` (Voreinstellung):** liest `/etc/passwd` und `/etc/group` beziehungsweise die mit `--passwd-file` und `--group-file` angegebenen Dateien. Damit erfasst man nur die lokale Textdatenbank.
- **`--source nss`:** verwendet `getpwent` und `getgrent`. Je nach NSS-Konfiguration können Ergebnisse aus lokalen Dateien, NIS, LDAP oder anderen Quellen kommen. **Eine vollständige Aufzählung ist nicht garantiert**; manche Quellen erlauben nur Einzelabfragen. Das Programm implementiert keine eigenen NIS-, NIS+- oder LDAP-Protokolle.
- Mit `+` oder `-` beginnende historische NIS-Kompatibilitätseinträge werden gemeldet und übersprungen. Fehlerhafte lokale Datensätze führen zu Exitstatus 1.
- Externe Dateipfade sind nur zusammen mit `--source local` vorgesehen.

## Ausgabe

Tabulatorgetrennt: `TYPE NAME UID GID HOME SHELL MEMBERS`; nicht anwendbare Felder bleiben leer. Steuerzeichen werden in der lesbaren Ausgabe als `\xHH` dargestellt. `--null` liefert je Eintrag sieben unveränderte, NUL-getrennte Felder ohne Kopfzeile oder Zusammenfassung. Kontoübersichten können vertrauliche Strukturinformationen enthalten.

## Voraussetzungen und Rückgabewerte

Perl 5, Kernmodule `Getopt::Long` und `FindBin` sowie das mitgelieferte Modul `SASD::Freeware::Account`. Keine CPAN-Abhängigkeiten. Exitstatus 0: Abfrage beendet; 1: ungültige lokale Datensätze; 2: Parameterfehler; 3: Datei oder Bibliothek nicht verfügbar. Exitstatus 0 im NSS-Modus garantiert **keine Vollständigkeit**.
