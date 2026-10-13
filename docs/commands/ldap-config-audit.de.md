# ldap-config-audit — Prüfung der OpenLDAP-Client-TLS-Konfiguration

[English](ldap-config-audit.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/ldap-config-audit.1)

Prüft **ausschließlich lesend** eine OpenLDAP-`ldap.conf`-Textdatei. Voreinstellung: `/etc/ldap/ldap.conf` unter Linux und `/etc/openldap/ldap.conf` unter macOS; mit `--file` überschreibbar. Warnt bei `TLS_REQCERT never`, `allow` oder `try`, doppelten beziehungsweise unbekannten `TLS_REQCERT`-Werten und fehlerhaften Zeilen. `ldap://` wird nur als **Hinweis** gemeldet: StartTLS könnte separat aktiviert sein, was aus dieser Datei allein **nicht verlässlich erkennbar** ist.

**Konfigurationswerte werden niemals ausgegeben**, da sie interne Servernamen, DNs und gegebenenfalls Zugangsdaten enthalten können. `INCLUDE` wird **nicht verfolgt** und muss separat geprüft werden. Benutzerdateien (LDAPRC), Umgebungsvariablen, Anwendungseinstellungen und tatsächlich wirksame Zertifikatsprüfungen sind **nicht** Gegenstand der Analyse. `ldap-probe` kann ergänzend einen anonymen LDAPS-Test durchführen.

## Beispiele

```sh
./bin/ldap-config-audit
./bin/ldap-config-audit --file /etc/ldap/ldap.conf
```

## Grenzen und Rückgabewerte

KEIN Compliance-Nachweis; keine Include-Auswertung, NSS-Verbindung oder TLS-Aushandlung.

Exit `0`: keine Befunde/Erfolg; `1`: Strukturfehler, DNS-/NIS-Fehler oder fehlende Antwort; `2`: ungültige Parameter; `3`: Datei oder Client fehlt, nicht unterstützte Voreinstellung oder unerwarteter Fehler. Fehlende Clients dürfen **nicht** als fehlerfreie Konfiguration ausgelegt werden.
