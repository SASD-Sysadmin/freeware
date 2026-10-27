# `linux-distro-matrix` – Nachweisbare Linux-Distributionsprüfungen (M8.5.2)

## Was eine Prüfung belegt

Das lesende Abnahmeprogramm baut auf `linux-platform-report` (M8.5.1) auf.
Es unterscheidet fünf Zielsysteme: Debian, Ubuntu, Arch Linux, AlmaLinux und
Rocky Linux.

| Modus | Tatsächlich geprüft | Bedeutung von PASS |
| --- | --- | --- |
| `offline` (Standard) | Synthetische `os-release`-Testdaten | Der Parser erkennt dieses Muster |
| `host` | Nur der aktuell laufende Linux-Host | Der Host meldet die exakte Distributions-ID |
| `container` | Ein ausdrücklich gewähltes Container-Image | Perl-Report läuft im Container und dessen ID stimmt überein |

**Keine dieser Prüfungen ist eine native Firewall-, SELinux-/AppArmor-,
Paketmanager-, systemd- oder vollständige Linux-V1.0-Abnahme.** Dafür ist
das [gesonderte Abnahmeprotokoll](linux-distro-acceptance.de.md) vorgesehen.

## Bedienung

```sh
bin/linux-distro-matrix
bin/linux-distro-matrix --format jsonl
bin/linux-distro-matrix --mode host
bin/linux-distro-matrix --mode host --target debian --require-complete
bin/linux-distro-matrix --mode offline --target rocky
```

Ein fremdes Zielsystem auf einem einzelnen Host erhält `SKIP/NOT_THIS_HOST`.
Wenn die Linux-Hosterkennung scheitert, wird `FAIL/HOST_UNAVAILABLE` gemeldet.
Auf macOS werden native Linux-Hostprüfungen grundsätzlich übersprungen.

### Containerprüfung (nur nach ausdrücklicher Aktivierung)

Das Container-Image muss vorab separat bezogen, geprüft und lokal gespeichert
sein. **Der Runner lädt niemals selbst Images herunter und installiert kein
Perl.** Die Images benötigen `/bin/sh` und `perl` im Suchpfad. Zulässig sind
nur Image-Referenzen mit einem 64-stelligen SHA-256-Digest, keine Tags.

```sh
bin/linux-distro-matrix --mode container --engine podman \
  --target debian \
  --image "debian=docker.io/library/debian@sha256:YOUR_64_HEX_DIGEST" \
  --require-complete --format jsonl
```

Der Digest im Beispiel ist **ein Platzhalter** und muss durch eine tatsächlich
lokal verfügbare Referenz ersetzt werden. Zusätzlich Image, Digest,
Architektur, Hostkernel, Engine-Version und Datum protokollieren.

Container werden ohne Netzwerk, ohne Linux-Capabilities, ohne zusätzliche
Rechte, mit schreibgeschütztem Root-Dateisystem, UID/GID 65534,
Prozess-/Speichergrenzen und schreibgeschütztem Repository-Mount gestartet.
Fehlendes Perl erzeugt `SKIP/MISSING_PERL`; ein defekter Engine-Aufruf ist
`FAIL/ENGINE_FAILED`. Die Engine und ein fremdes Image können trotz dieser
Optionen Risiken für den Host bergen: Unbekannte Images nur in einer
separaten Test-VM verwenden. **SELinux nicht abschalten und keine
Quellverzeichnisse umetikettieren**, um fehlgeschlagene Mounts zu umgehen.

## Ergebnisse und Exit-Codes

TSV-Ausgabe (Standard):

`TARGET MODE STATUS OBSERVED_ID FAMILY EVIDENCE REASON`

JSON Lines (`--format jsonl`) hat das Schema `sasd.distro-matrix.v1`.
`PASS` bedeutet nur einen tatsächlich bestandenen Test **innerhalb des
ausgewiesenen Modus**; `FAIL` steht für einen Fehler oder eine falsche ID;
`SKIP` ist keine positive Abnahme.

Exit-Codes: `0` kein FAIL (SKIP möglich); `1` mindestens ein FAIL;
`2` falsche Parameter; `4` mindestens ein SKIP bei `--require-complete`.
Für Freigabekriterien immer `--require-complete` und die Modalität beachten.

Die Offline-Testdaten im Perl-Modul sind **synthetisch**. Paketmanager,
Firewallregeln, Zugriffsrechte, Dienste und Hostfunktionen werden in
M8.5.2 noch nicht nativ geprüft.

Lokale, netz- und containerfreie Regressionstests:

```sh
prove tests/test_linux_distro_matrix.t
```

Referenzen: [os-release](https://www.freedesktop.org/software/systemd/man/latest/os-release.html),
[Docker run](https://docs.docker.com/reference/cli/docker/container/run/).
