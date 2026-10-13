# Plattformunterstützung und Grenzen

[English](PLATFORMS.md) · [Projekt](../README.de.md)

SASD Freeware wird mit GitHub Actions unter Ubuntu Linux und macOS getestet. **Bestandene Tests bestätigen das geprüfte Verhalten, nicht die vollständige Unterstützung aller Betriebssystemfunktionen.** Die Testmatrix steht in `.github/workflows/ci.yml`.

| Bereich | Linux | macOS | Einschränkung |
| --- | --- | --- | --- |
| Lesende Dateisysteminventare und Prüfungen | Automatisierte Tests | Automatisierte Tests | APFS-ACLs, TCC/Datenschutz und Snapshots werden nicht geprüft; gesperrte Verzeichnisse können unvollständige Berichte liefern. |
| `rotate`, Dateiintegrität, SSH/Hosts, TCP und Logs | Automatisierte Tests | Automatisierte Tests | Pfade, Rechte und native Werkzeuge am Zielsystem prüfen. |
| `fs-usage`, `quota-report` | Systembefehle erforderlich | Systembefehle erforderlich | `df`, `quota` und `repquota` unterscheiden sich nach Betriebssystem. |
| `account-inventory` | Standardmäßig lokale Dateien; NSS wählbar | Standardmäßig NSS; lokale Textdateien wählbar | NSS-Aufzählung ist nicht zwingend vollständig; Einzelauflösung kann funktionieren, obwohl Konten in der Liste fehlen. |
| `home-audit` | Standardmäßig lokale Dateien; UID ab 1000 | Standardmäßig NSS; UID ab 500 | UID-Bereiche sind Richtlinien. macOS-ACLs und Datenschutzregeln werden nicht berücksichtigt. |
| `group-audit` / `account-audit` | Unix-Textdateien | Nur Unix-Textdateien | `/etc/passwd` und `/etc/group` sind unter macOS keine vollständige Open-Directory-Datenbank. |
| `account-manage` | Nur Linux; standardmäßig Vorschau und abgesicherte Änderungen | Nicht unterstützt, auch keine Vorschau | Keine direkte Verwaltung von Directory Services/LDAP/NIS. |
| `quota-status`, schreibendes `quota-set` | Nur Linux | Nicht unterstützt | Benötigt Linux `quotaon -p`, `setquota` und `/proc`. |

## Ungefährliche Plausibilitätsprüfungen unter macOS

```sh
make test
./bin/account-inventory --kind users
./bin/account-inventory --source nss --kind groups
./bin/home-audit
./bin/link-audit "$HOME"
./bin/permission-audit "$HOME"
./sbin/account-manage --action group-create --name example_group  # Exit 3: Linux-only
```

Für echte lokale macOS-Kontenverwaltung kommen native Werkzeuge wie `dscl` und `sysadminctl` infrage. Diese werden hier noch nicht als Verwaltungsbackend angeboten. Schreibende Programme sollten vor dem Einsatz auf produktiven Systemen isoliert geprüft werden. Zugriffsfehler dürfen nicht als Nullbefunde ausgegeben werden. Die Installation unter `/usr/freeware` wurde noch nicht für sämtliche Varianten des System Integrity Protection geprüft.
