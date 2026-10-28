# linux-container-acceptance – M8.5.3

[English](linux-container-acceptance.md) · [Matrix](linux-distro-matrix.de.md) · [Abnahmeprotokoll](linux-container-acceptance-protocol.de.md)

## Zweck und Grenzen

Der Runner prüft fünf Linux-Kennungen: `debian`, `ubuntu`, `arch`,
`almalinux`, `rocky`. Die Ergebnisse werden **einzeln** erfasst. Der
Standardmodus PLAN verwendet **keinen** Docker-/Podman-Daemon; alle fünf
Prüfschritte je Distribution erhalten `SKIP/NOT_EXECUTED`.

| Schritt | Prüfung | Aussage von PASS |
| --- | --- | --- |
| `IDENTITY` | `linux-platform-report` | Exakte `ID` stimmt; `ID_LIKE` allein genügt nicht |
| `TOOLCHAIN` | Perl, make, prove, bash, git, mktemp | Werkzeuge vorhanden |
| `TEST` | `make test` | Repository-Tests erfolgreich |
| `INSTALL` | Installieren/deinstallieren unter `/tmp` | Manifest-Lebenszyklus erfolgreich |
| `SMOKE` | Ausgewählte SASD-Kommandos | Start und einfacher Aufruf erfolgreich |

Fehlende Werkzeuge und nicht vorhandene Images ergeben `SKIP`, keine
vorgetäuschten Erfolge. Fehlgeschlagene Tests ergeben `FAIL`. Bei
`--require-complete` führen auch übersprungene Prüfungen zu einem
nicht erfolgreichen Exitcode.

## Ausführung

```sh
# Sicherer, rein lesender Plan ohne Daemonkontakt:
bin/linux-container-acceptance

# Plan als JSON Lines:
bin/linux-container-acceptance --format jsonl

# Optional: konkretes, vorher geprüftes und lokal verfügbares Image angeben.
# Den Digest durch einen ECHTEN bekannten Image-Digest ersetzen.
bin/linux-container-acceptance --run --engine podman \
  --target debian \
  --image 'debian=docker.io/library/debian@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' \
  --require-complete --format jsonl
```

**Der Digest im Beispiel ist nur ein Platzhalter.** Das Programm lädt keine
Images herunter und installiert keine Abhängigkeiten. Es verwendet nur
`image inspect` und `run --pull=never`. Die Bereitstellung geeigneter Images
ist eine separate, vorher genehmigte Handlung.

Die Container sind ohne Netzwerk, ohne Linux-Capabilities und ohne
Privilegienerhöhung konfiguriert. Das Repository ist ausschließlich lesbar
unter `/workspace` eingebunden; `/tmp` ist ein temporäres Container-Dateisystem.
UID/GID 65534, Ressourcenlimits, ein festes ENTRYPOINT und ein äußerer
Zeitbegrenzer reduzieren Risiken. **Der Zugriff auf den Docker-Daemon kann
selbst hochprivilegiert sein.** Rootless Podman oder isolierte Testsysteme
sind vorzuziehen.

Wenn der Client wegen eines Timeouts beendet wird, gegebenenfalls verbleibende
Container manuell kontrollieren. Nicht alle Rootless-Systeme können die
Ressourcenlimits anwenden; solche Fehler dürfen nicht durch weniger strenge
Sicherheitseinstellungen kaschiert werden.

## Ausgabe und Exitcodes

TSV: `TARGET STAGE MODE STATUS REASON`; optional JSONL mit Schema
`sasd.container-acceptance.v1`. `0`: kein FAIL, SKIP erlaubt. `1`: FAIL.
`2`: ungültige Optionen. `4`: SKIP bei `--require-complete`.

**Keine Host-/VM-Abnahme:** Container-Prüfungen beweisen weder die Funktion
der Host-Firewall noch systemd, SELinux, AppArmor, Kernel-Kompatibilität,
Paketmanagement oder die vollständige Linux-V1.0-Tauglichkeit. Diese Fragen
bleiben Gegenstand der nativen VM-Tests (M8.5.4).
