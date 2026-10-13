# Rückgabecodes der Namensdienst-Diagnoseprogramme

[English](EXIT-CODES.md) · [Projekt](../README.de.md) · [Integrationstests](TESTING.de.md)

Die Namensdienst-Kommandos verwenden **einheitliche Diagnose-Rückgabecodes**. Ein negatives Prüfergebnis ist etwas anderes als eine Prüfung, die mangels Voraussetzungen gar nicht ausgeführt werden konnte.

| Code | Bedeutung | Beispiele |
| --- | --- | --- |
| **0** | Die Prüfung wurde erfolgreich ohne Befund durchgeführt. | DNS-Antwort vorhanden; NSS-Konfiguration strukturell korrekt. |
| **1** | Die Prüfung wurde durchgeführt, ergab aber einen Fehler oder Befund. | `NXDOMAIN`, `NOERROR` ohne Antwort, keine NIS-Bindung, abgewiesene LDAPS-Verbindung. |
| **2** | Ungültiger oder unvollständiger Aufruf. | Unbekannte Option, ungültige UID, fehlerhafte Serveradresse oder DNS-Port außerhalb des gültigen Bereichs. |
| **3** | Fehlende Voraussetzung oder unerwarteter Ausführungs-/Protokollfehler. | `dig` fehlt; Konfigurationsdatei unlesbar; fehlerhafte bzw. übergroße Clientantwort. |

Dies gilt für `nss-lookup`, `host-resolve`, `ldap-probe`, `nsswitch-audit`, `dns-query`, `nis-probe` und `ldap-config-audit`. Andere Kommandos (besonders `tcp-check --nagios`) haben teilweise ausdrücklich abweichende Codes. **0 bedeutet bei einem Kommando niemals „optionale Prüfung stillschweigend übersprungen“.** Übersprungene optionale **Testfälle** erscheinen dagegen explizit als `SKIP`.

## Auswertung in Skripten

Den Status differenziert behandeln:

```sh
./bin/dns-query --name good.test --server 127.0.0.1 --port 1053
status=$?
case "$status" in
    0) echo "DNS erfolgreich" ;;
    1) echo "DNS-Fehler oder keine Antwort" ;;
    2) echo "Ungültiger Programmaufruf" ;;
    3) echo "Prüfung nicht möglich: Voraussetzung oder Protokollfehler" ;;
    *) echo "Unerwarteter Status: $status" ;;
esac
```

Eine DNS-Antwort beweist weder Vertrauenswürdigkeit noch DNSSEC-Validierung. System-Resolver und direkte DNS-Abfrage sind getrennte Prüfungen. Eine anonyme LDAP-Root-DSE-Abfrage testet keine Anmeldung mit Benutzerkonto.
