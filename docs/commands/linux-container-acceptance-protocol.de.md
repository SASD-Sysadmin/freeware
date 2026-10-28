# M8.5.3 – Protokoll für Container-Abnahmen

[English](linux-container-acceptance-protocol.md) · [Runner-Anleitung](linux-container-acceptance.de.md)

Dies ist eine **Prüfvorschrift**, kein Nachweis bereits durchgeführter
Container- oder VM-Tests. Für jede Distribution sollen Git-Commit, genauer
Image-Digest, Engine-Version, Host-Kernel, Datum und die unveränderte
JSONL-Ausgabe archiviert werden. Fehler mit Reproduktionsschritten erfassen;
SKIP niemals als bestandene Prüfung deklarieren.

| Zielsystem | Offline-Parser | Echte Container-Abnahme | Native VM-Abnahme |
| --- | --- | --- | --- |
| Debian | Synthetische Tests | Offen | Offen |
| Ubuntu | Synthetische Tests | Offen | Offen |
| Arch Linux | Synthetische Tests | Offen | Offen |
| AlmaLinux | Synthetische Tests | Offen | Offen |
| Rocky Linux | Synthetische Tests | Offen | Offen |

Der Runner lädt keine Images herunter. Die Image-Bereitstellung erfolgt
separat durch einen Bediener. `IDENTITY`, `TOOLCHAIN`, `TEST`, `INSTALL` und
`SMOKE` bleiben getrennt dokumentiert. Host-Firewall- und MAC-Abnahmen dürfen
nicht aus Container-Ergebnissen abgeleitet werden. Tests an produktiven
Firewall-Systemen sind hierfür nicht vorgesehen.
