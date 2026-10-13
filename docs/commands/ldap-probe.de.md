# ldap-probe — anonyme LDAPS-Root-DSE-Prüfung

[English](ldap-probe.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/ldap-probe.1)

`ldap-probe` ruft einen **optional installierten lokalen `ldapsearch`-Client** auf und liest ausschließlich den LDAP-Root-DSE-Eintrag. Angefordert werden `supportedLDAPVersion`, `namingContexts` und `defaultNamingContext` mittels Base-Scope-Suche und anonymer LDAPv3-Bindung. Das Programm nimmt keine Passwörter entgegen, listet keine Benutzer/Gruppen auf und ändert nichts am Verzeichnisdienst.

## Beispiele

```sh
./bin/ldap-probe --uri ldaps://directory.example.org
./bin/ldap-probe --uri ldaps://directory.example.org:636 --timeout 5
./bin/ldap-probe --uri 'ldaps://[2001:db8::10]:636'
```

**Nur Server prüfen, für die eine Berechtigung besteht.** Ein erfolgreich gelesener Root-DSE weist einen erreichbaren Dienst und die zurückgegebenen Attribute nach, **aber nicht**, dass NSS-Benutzerabfragen über LDAP funktionieren. Manche Server verweigern anonyme Root-DSE-Abfragen trotz funktionierender Anmeldung. Die Abfrage erzeugt Netzwerkverkehr zum Server.

## Sicherheit und Kompatibilität

- Zulässig sind nur `ldaps://HOST[:PORT]` oder eine geklammerte IPv6-Adresse. Nicht erlaubt: `ldap://`, Zugangsdaten, freie Suchfilter, Base-DN-Parameter, URL-Abfrageoptionen oder ein StartTLS-Downgrade.
- Die Argumente werden **ohne Shell** an den Client übergeben. Die feste Abfrage verwendet `-x`, `-s base`, `-b ''` und `(objectClass=*)`. Die Client-Netzwerkwartezeit beträgt **1–10 Sekunden** (Vorgabe 5); die Ausgabe ist auf 1 MiB begrenzt. Die Wartezeit muss nicht alle DNS- und TLS-Operationen insgesamt begrenzen.
- Für OpenLDAP setzt das Programm `LDAPTLS_REQCERT=demand`. Ein nicht vertrauenswürdiges Serverzertifikat soll die Prüfung fehlschlagen lassen. CA-Verwaltung und Hostnamenprüfung übernimmt weiterhin der Client. **Die Zertifikatsprüfung nicht für einen grünen Test deaktivieren.** Andere Client-Implementierungen können `-o nettimeout` möglicherweise nicht unterstützen.
- Die LDIF-Antwort ist lediglich Diagnosematerial und keine bestätigte Sicherheitskonfiguration. Steuerzeichen werden für eine sichere Terminalausgabe maskiert; eine leere Antwort gilt auch bei Client-Exitcode 0 als fehlgeschlagen. Die Antwort kann Informationen des Servers enthalten.

## Voraussetzungen und Rückgabecodes

Optionales `ldapsearch` in einem absoluten `PATH`-Verzeichnis, beispielsweise aus OpenLDAP-Clientpaketen. Keine CPAN-Abhängigkeiten. `0`: Client-Abfrage erfolgreich; `1`: LDAP-Abfrage fehlgeschlagen; `2`: ungültige URI/Option; `3`: fehlende Voraussetzung oder interner Fehler. Ein erfolgreicher Rückgabecode **beweist nicht**, dass LDAP-Anmeldung und NSS-Integration korrekt funktionieren.
