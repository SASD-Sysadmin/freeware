# M8.5.2 – Abnahmeprotokoll für Linux-Distributionen

**Stand: vorbereitet, noch keine Plattformfreigabe.** Pro Test sind Modus,
Architektur, Datum, exakte Distributionsversion und Befehle zu protokollieren.
Synthetische Fixtures sind keine nativen Tests.

| Plattform | Parser-Fixture | Containerprüfung | Native VM | Firewall / SELinux / AppArmor |
| --- | --- | --- | --- | --- |
| Debian | M8.5.2 umgesetzt | Praxistest offen | Offen | Offen |
| Ubuntu | M8.5.2 umgesetzt | Praxistest offen | Offen | Offen |
| Arch Linux | M8.5.2 umgesetzt | Praxistest offen | Offen | Offen |
| AlmaLinux | M8.5.2 umgesetzt | Praxistest offen | Offen | Offen |
| Rocky Linux | M8.5.2 umgesetzt | Praxistest offen | Offen | Offen |

Empfohlener Ablauf in einer separaten, isolierten Test-VM:

1. `/etc/os-release`, Kernel, Architektur, Perl-Version, Paketmanager und
   SELinux-/AppArmor-Zustand dokumentieren.
2. `make test`, optional `make shellcheck` und Installationsprüfung **nur mit
   temporärem `DESTDIR`** durchführen. Nicht produktiv installieren.
3. `bin/linux-distro-matrix --mode host --target <genaue-ID>
   --require-complete --format jsonl` ausführen.
4. Optional: vorher geprüftes Container-Image mit Perl bereitstellen;
   Image-Digest protokollieren und Container-Modus gezielt aktivieren.
5. Native Firewall-/Mandatory-Access-Control-Abnahme nur in einer VM und
   mit den vorhandenen lesenden Firewall-Abnahmeleitfäden durchführen.
   **Niemals echte Firewallregeln für einen grünen Test verändern.**
6. PASS/FAIL/SKIP sowie Befehle, Toolversionen, Datum und Einschränkungen
   notieren. SKIP darf nicht als PASS gewertet werden.

Ein Debian-Test bestätigt nicht Ubuntu/Arch/Alma/Rocky. Ein Container-Test
bestätigt nicht automatisch den nativen Kernel, die Init-Umgebung,
Firewallfunktion oder SELinux/AppArmor. Für die Linux-V1.0-Freigabe sind
zusätzlich echte VM-Nachweise je Zielplattform erforderlich.
