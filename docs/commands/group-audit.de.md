# group-audit

[English](group-audit.md) · [Projekt](../../README.de.md)

`group-audit` überprüft den Aufbau einer lokalen Unix-Gruppendatei im Format `/etc/group`, ohne sie zu verändern. Es ist **keine** vollständige Gruppen- oder Berechtigungsprüfung über NSS, LDAP, NIS oder NIS+.

```sh
./bin/group-audit
./bin/group-audit --file ./group.sample
```

Geprüft werden vier durch Doppelpunkte getrennte Felder, einfache Gruppennamen und dezimale 32-Bit-GIDs. Das Werkzeug meldet doppelte Gruppennamen, gemeinsam verwendete GIDs, zusätzliche Gruppen mit GID 0, fehlerhafte Mitgliedernamen und doppelte Mitgliedschaften. Gemeinsame GIDs können beabsichtigt sein und sind deshalb Warnungen. Fehlerhafte Datensätze und Mitglieder führen zu Fehlern. Historische NIS-Kompatibilitätseinträge mit `+`/`-` werden ausdrücklich gemeldet und übersprungen. Mitglieder werden nicht auf Existenz in `/etc/passwd` geprüft, weil sie aus zentralen Namensdiensten stammen können.

Die Zusammenfassung zeigt Gruppen, eindeutige GIDs, Warnungen und Fehler. Exitstatus 0 ohne strukturelle Fehler, 1 bei fehlerhaften Datensätzen, 2 bei ungültigen Parametern und 3 bei fehlender Eingabedatei oder Bibliothek. Benötigt werden Perl-Kernmodule sowie `SASD::Freeware::Account`; Änderungen an Gruppen finden nicht statt.
