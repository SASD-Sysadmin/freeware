# FR2-06a – Debian-KVM/libvirt: sichere Staging- und VM-Abnahme

[English](FR2-06-VM-ACCEPTANCE.md) · [Privilegierte Sicherheitsgrenzen](PRIVILEGED-SAFETY.de.md) · [Release-Evidenz](RELEASE-EVIDENCE.de.md) · [Abnahmeprotokoll](FR2-06-REPORT-TEMPLATE.de.md)

**Stand:** 23.11.2026. **Referenz:** `SASD-SysAdmin/freeware`, Commit `f25aa3f2f5c84911fa03d7b8a93daff06b736bef`, [Ubuntu-/macOS-CI 45139166377](https://github.com/SASD-Sysadmin/freeware/actions/runs/45139166377) erfolgreich. Das ist der **Ausgangsstand** vor FR2-06a. **Keine** formale Release-, VM-, Root- oder Wiederherstellungsabnahme. Nach jedem neuen Commit die CI-Zuordnung aktualisieren.

## 1. Strikte Trennung: automatisch versus manuell

| Modus | Ort | Erlaubt | Verboten / nicht belegt |
| --- | --- | --- | --- |
| A – `fr2-06a-staging-acceptance.sh` | normaler Benutzer in Entwicklungscheckout | Wegwerf-`DESTDIR`, private Quellkopie, Fresh/Repeat/Upgrade/Conflict/Tamper/Uninstall, lokale Logdateien | `sudo`, reale Benutzer/Quotas, VM-Eingriffe, automatischer Snapshot-Restore |
| B – VM-Plan und Vorschau | isolierter Debian-Gast | Lesen, `--help`, `--version`, identifizierte `account-manage`-/`quota-set`-Vorschauen | Keine `--apply`-Aufrufe, solange keine getrennte Bedienerfreigabe vorliegt |
| C – Einzelabnahme | gesondert freigegebener, rücksetzbarer Testgast | Je **eine** explizit autorisierte Änderung mit unabhängiger Zustandskontrolle | Kein automatisches Abarbeiten von Root-Befehlen, niemals auf Host/WSL/Produktivsystem |

Alle sieben `MANUAL`-Release-Gates bleiben beim Erstellen dieses Plans offen. Auch ein erfolgreicher Modus A schließt **weder** die echte Crash-/Snapshot-Recovery **noch** `privileged-vm` automatisch. Keine AGPL-Änderung; dieser Source-Track bleibt MIT. Die spätere getrennte `SASDGMBH`-Fassung bleibt `AGPL-3.0-only` gemäß [Lizenzstrategie](LICENSE-STRATEGY.de.md).

## 2. Zuerst: unprivilegierter Staging-Test (auch auf Debian/WSL ausführbar)

**Der Test ist absichtlich nicht für Root geeignet.** Er kopiert benötigte Repository-Verzeichnisse in ein von `mktemp` erzeugtes privates Verzeichnis und installiert ausschließlich unter `DESTDIR` in diesem Verzeichnis. Die einzige beabsichtigte Dateiänderung außerhalb des Wegwerfverzeichnisses ist die vom Bediener ausdrücklich selbst angelegte Logdatei durch `tee`.

```bash
cd "$(git rev-parse --show-toplevel)"
set -o pipefail
mkdir -p "$HOME/tmp/.test-logs"
bash tools/fr2-06a-staging-acceptance.sh --repo "$PWD" \
  2>&1 | tee "$HOME/tmp/.test-logs/fr2-06a-staging.log"
printf 'Result: %s\n' "$?"
```

Der Test muss ohne `sudo` ausgeführt werden. Er prüft: Fresh-Install und Lizenz-Manifest, Wiederholung, Blockierung einer fremden Datei, kontrolliertes Upgrade nur in der **Quellkopie**, Ablehnung modifizierter Installationsdaten, Simulation eines vorhandenen Transaktionsmarkers, sauberes Uninstall und Erhalt fremder Dateien und des dauerhaften Locks. `--keep` lässt das private Testverzeichnis nach dem Lauf stehen; nur für eine bewusste Fehleruntersuchung benutzen. Standardmäßig wird der Wegwerfbereich entfernt. **Nicht getestet:** echte Stromunterbrechung, SIGKILL, fsync-Dauerhaftigkeit, unsichere parallele Schreiber, Root-Installationen und Dateisystemausfälle.

**Abnahmeregel für Modus A:** Exit 0 und alle `PASS`; bei einem `FAIL` keine Übernahme in `PASS`, stattdessen Log mit SHA-256, Datum, Perl-Version und Basiscommit sichern. Das ist `staged-upgrade`-**Teilnachweis**, kein vollständiger manueller Release-Gate-Abschluss.

## 3. Host-Preflight: eine wirklich wegwerfbare KVM-VM nachweisen

**Nur auf dem KVM-Host, zunächst lesend**, mit einer ausdrücklich benannten Test-VM; keine Auto-Erkennung oder Benutzung produktiver Domains:

```bash
LAB_VM='sasd-freeware-lab'   # bewusst vom Betreiber auf die Test-VM ändern
virsh dominfo "$LAB_VM"
virsh domblklist "$LAB_VM" --details
virsh domiflist "$LAB_VM"
virsh snapshot-list "$LAB_VM" --tree
```

Prüfen und in einer *privaten* Akte protokollieren: Domain-UUID, OS/Kernel, Disk- und Firmwareformate, Netzwerk (isoliert, keine produktiven Vertrauensstellungen), Storage-Pool, Snapshot-/Backup-ID, Festplattenkette, freien Speicher, Rücksicherungsweg. `virsh dumpxml --inactive "$LAB_VM"` kann Details und Zugangsdaten enthalten: nur in einem geschützten lokalen Archiv, nicht öffentlich committen. Keine Domain anhand eines zufälligen Namens überschreiben.

**Snapshot-Strategie ist absichtlich nicht als blind kopierbarer Befehl formuliert.** Interne Snapshots, externe QCOW2-Overlays, UEFI/NVRAM und mehrere Platten haben unterschiedliche Restore-Eigenschaften. Die Anwendung `virsh snapshot-revert` ist nicht für jeden Snapshot-Typ ein zuverlässiger universeller Rückweg. Vor einer freigegebenen Schreibprüfung eine **offline konsistente, vollständig dokumentierte und unabhängig verifizierte Rückfallkopie/VM-Klon bzw. geeignete Snapshots aller Datenträger einschließlich NVRAM** erstellen. Tatsächlichen Restore an einem *separaten* Wegwerfstand einmal erproben. Ohne nachgewiesenen Restore lautet das Gate `BLOCKED`. Für Details: [libvirt `virsh`](https://libvirt.org/manpages/virsh.html) und [libvirt Snapshot-API](https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html).

**Stop-Kriterien:** Testgast nicht eindeutig, Hostnetz nicht sicher isoliert, produktive Benutzer/Daten vorhanden, Root-Dateisystem als Quota-Testziel, keine gesonderte Quota-Disk, fehlender geprüft rücksetzbarer Stand, unklare Storage-Backings, ungeprüfte Fremd-`sudo`-Rechte oder bestehende SSH-Verbindungen zu produktiven Zielen. Keine Änderung auf gut Glück.

## 4. Gast-Preflight: nur lesen und Vorschau ausführen

Im Debian-Testgast vor etwaigen Schreibversuchen:

```bash
uname -a
cat /etc/os-release
perl -e 'printf "Perl %vd\n", $^V'
findmnt -no TARGET,SOURCE,FSTYPE,OPTIONS /
findmnt -a               # isolierte Quota-Disk eindeutig identifizieren
command -v useradd groupadd usermod setquota quotaon repquota || true
getent passwd sasd_lab_u1 || true
getent group  sasd_lab_g1 || true
```

`getent` ist eine NSS-Sicht, kein Beweis für einen lokalen Datensatz; zusätzlich lokale `/etc/passwd` und `/etc/group` **lesend** und unter Datenschutzauflagen prüfen. Für `account-manage` sind nur die drei Aktionen `user-create`, `group-create`, `password-lock` vorgesehen. `user-create` verwendet das native Linux `useradd -m`; es kann ein Home-Verzeichnis erzeugen. `password-lock` sperrt **nur Passwortanmeldung**, nicht vorhandene SSH-Schlüssel oder Sitzungen.

Beispielhafte *ungefährliche Vorschau* nach Einrichten des Checkout im Gast (an realen Pfad anpassen):

```bash
./sbin/account-manage --action group-create --name sasd_lab_g1
./sbin/account-manage --action user-create  --name sasd_lab_u1
```

Für `quota-set` ist vor der Vorschau ein bereits vorhandener, **separater echter Mountpunkt** erforderlich; hier lediglich das Beispiel `$LAB_QUOTA_MOUNT` setzen. Auf `/` oder einem produktiven Mount sind keinerlei Schreibtests erlaubt. Die Vorschau verlangt einen existierenden per NSS auflösbaren Benutzer, zum Beispiel ein eigens im Gast vorbereiteter Testbenutzer, und alle vier Grenzwerte:

```bash
LAB_QUOTA_MOUNT='/mnt/sasd-quota-test'  # nur falls als SEPARATER Gast-Mount nachgewiesen
LAB_QUOTA_USER='sasd_lab_u1'           # muss vor der Vorschau bereits existieren
./sbin/quota-set --user "$LAB_QUOTA_USER" \
  --filesystem "$LAB_QUOTA_MOUNT" \
  --block-soft 4096 --block-hard 8192 \
  --inode-soft 100 --inode-hard 200
```

Die Blockwerte sind **KiB**, Inode-Werte Anzahl. `0` bedeutet unbegrenzt und erfordert beim späteren Apply zusätzlich `--allow-unlimited`. Der Quota-Backend-Aufruf erfolgt über `setquota` und verlangt die exakte Mountpunktauflösung. Fehlende Quota-Werkzeuge oder fehlende Quota-Aktivierung sind ein `BLOCKED`/`SKIP`-Befund, kein stillschweigender PASS.

## 5. Gesondert freigegebene privilegierte Einzeltests

**Diese Befehle werden durch keine gelieferte Datei automatisch gestartet.** Vor **jedem** realen Apply ist separat festzuhalten: freigegebene VM-UUID, Snapshotevidenz und verifizierter Rückweg, exakter Commit, benannte Testidentität, erwartete Änderung, unabhängige Kontrolle, Operator und ausdrückliche Zustimmung.

1. `account-manage`: Erst `group-create`, dann `user-create`, jeweils nur nach bestätigter Vorschau. Das Programm verlangt bei Änderungen `--apply --confirm-apply` **und** Root. UID/GID und lokale Datensätze unabhängig prüfen. `password-lock` erst am zuvor erzeugten Nicht-System-Testbenutzer erproben; Auswirkungen und **Nicht**-Auswirkungen auf SSH/Sitzungen dokumentieren. Nicht mit echten Identitäten testen.
2. `quota-set`: Separate eigens hierfür bereitgestellte Guest-Disk, genaue Mountpoint- und Quota-Unterstützung unabhängig belegen (`findmnt`, `quotaon -p`, `repquota`, `quota` soweit verfügbar). Anschließend **ein** freigegebenes `setquota`-Szenario mit vier expliziten Nicht-Null-Werten unter `--apply --confirm-apply` und anschließend unabhängige Backend-Inspektion. Kein automatisches `mkfs`, `mount`, `quotaon`, `setquota` oder Dateisystem-Umbau durch das Testpaket.
3. Negative Fälle: fehlende Bestätigung, ungültige Namen und Grenzen, Systemkonto/Root, kollidierende Namen, Quota-Soft größer Hard, unzulässiger Pfad und fehlende Backendprogramme in *sicherer Offline-Fixture*; niemals absichtlich echte `/etc`-Datenbanken beschädigen. Prüfer protokolliert tatsächlichen Exit-Code und unveränderten Ausgangszustand.
4. Wiederherstellung: Gast stoppen und nach **vorab freigegebenem** dokumentiertem Verfahren vollständig zum bekannten Stand zurückkehren (einschließlich separater Quota-Disk, Gastdefinition/NVRAM). Danach neu starten und unabhängig vergleichen: lokale Benutzereinträge, NSS, Gruppen, Homes, Quota-Records, Mounts und Testmarkierungen. Ein paar gelöschte Testkonten ersetzen **keinen** Snapshot-Restore-Nachweis.

**Erfolgskriterien:** Jede genehmigte Schreiboperation zeigt exakt die erwartete Änderung; alle Ablehnungen verändern nichts; jeder Test hat Vorher/Nachher-Protokolle und die Ausgangslage ist nach Restore unabhängig bestätigt. Ein nicht wiederherstellbarer Zustand ist `FAIL`, fehlende Freigabe/Umgebung ist `BLOCKED`. Das `privileged-vm`-Gate bleibt offen, bis diese Belege mit unabhängiger Freigabe wirklich vorliegen.

## 6. Belege und Gates

Die [Vorlage](FR2-06-REPORT-TEMPLATE.de.md) enthält eindeutige IDs, Exit-Codes, Log-SHA-256, Abweichungen und Freigabefelder. Lokale Rohlogs unter restriktiven Rechten ablegen, persönliche Nutzerdaten und Credentials aus öffentlichen Commits fernhalten. Exakter `git rev-parse HEAD` und `git status --porcelain` gehören zum Datensatz; auf der VM auch OS, Perl, Quota-Werkzeugversionen und Datenträger-/Mount-Grenzen.

- `staged-upgrade`: Modus A ist ein reproduzierbarer **Teilnachweis**; echte Snapshot-/Crash-Recovery bleibt offen.
- `privileged-vm`: derzeit **OFFEN**, bis manuelle, separat autorisierte Apply- und Restore-Prüfungen nachgewiesen sind.
- `current-ci`: bestanden auf Ausgangscommit `f25aa3f` ([45139166377](https://github.com/SASD-SysAdmin/freeware/actions/runs/45139166377)); für den FR2-06a-Commit und den späteren Release-Commit jeweils neu prüfen.
- `artifact-provenance`, `release-approval`, `native-platforms`, `live-services`: bleiben eigene Freigabegates und werden durch dieses Paket nicht geschlossen.

**Noch keine Veröffentlichung, kein Tag, keine AGPL-Umsetzung.** Der Test ist bewusst konservativ: lieber ein sichtbares `BLOCKED` als eine unbewiesene Sicherheit.
