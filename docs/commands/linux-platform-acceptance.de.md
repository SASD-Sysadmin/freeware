# M8.5 Linux V1.0 – Abnahmematrix (in Arbeit)

**M8.5.1 hat noch keine Distribution nativ zertifiziert.** Die nachfolgende
Matrix beschreibt geplante Prüfungen. Ein erfolgreich ausgewertetes Fixture
ist kein Nachweis für einen echten Zielrechner.

| Zielsystem | Parser-Fixture | Native Installation | Systemwerkzeuge | Firewall-Abnahme | Status |
| --- | --- | --- | --- | --- | --- |
| Debian (Referenz) | Offline-Test | Offen | Offen | nftables/UFW offen | Offen |
| Ubuntu LTS | Offline-Test | Offen | Offen | UFW/nftables/AppArmor offen | Offen |
| Arch Linux | Offline-Test | Offen | Offen | nftables/firewalld bei Installation offen | Offen |
| AlmaLinux | Offline-Test | Offen | Offen | firewalld/SELinux offen | Offen |
| Rocky Linux | Offline-Test | Offen | Offen | firewalld/SELinux offen | Offen |

## Nachweise nach Prüfungsstufe

1. **Parser:** Synthetische Testdaten und negative Sicherheitstests.
2. **Container:** Perl-Abhängigkeiten, `make test`, gestufte Installation und
   Deinstallation. Ein Container beweist keine aktive Kernel-Firewall und
   keine funktionierende systemd-Dienstverwaltung.
3. **Isolierte VM:** Versionsstand, echte lesende Systembefehle, Dienststatus,
   Berechtigungsfehler, Installation/Deinstallation, Firewallzustand vorher/nachher.
4. **Abnahme:** nachvollziehbare Nachweise und klar aufgeführte offene Punkte
   pro Distributionsversion.

Images versioniert festhalten, keine produktiven Firewallregeln verändern.
Die `FAMILY`-Angabe von `linux-platform-report` darf nicht als Nachweis für
vorhandene Software oder wirksame Sicherheitsrichtlinien verwendet werden.
