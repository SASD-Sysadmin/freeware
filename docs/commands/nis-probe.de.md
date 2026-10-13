# nis-probe — Diagnose der lokalen NIS-/YP-Bindung

[English](nis-probe.md) · [Projekt](../../README.de.md) · [Manpage](../../man/man1/nis-probe.1)

Fragt über den optionalen **`ypwhich`**-Client ab, an welchen NIS-Server der **lokale Rechner** gebunden ist. Die Domäne kann angegeben oder die Systemvorgabe genutzt werden. **Passwort-, Gruppen- und andere NIS-Maps werden weder abgefragt noch aufgelistet.** Das Ergebnis bestätigt weder eine funktionierende Kontenauflösung über NSS noch die Sicherheit des Servers.

NIS ist ein Altprotokoll ohne zeitgemäße Garantien für Vertraulichkeit und Authentisierung. Diese Prüfung ist eine **Hilfe für Fehlersuche und Migration**, keine Empfehlung für neue NIS-Installationen. Auf manchen macOS-Systemen fehlt `ypwhich`; dies wird als fehlende Voraussetzung gemeldet. Die Abfrage kann NIS-Netzverkehr erzeugen.

## Beispiele

```sh
./bin/nis-probe
./bin/nis-probe --domain legacy.example --timeout 3
```

## Grenzen und Rückgabewerte

Nur Bindungsstatus, keine Map-Namen, Passwörter oder Kontendaten.

Exit `0`: keine Befunde/Erfolg; `1`: Strukturfehler, DNS-/NIS-Fehler oder fehlende Antwort; `2`: ungültige Parameter; `3`: Datei oder Client fehlt, nicht unterstützte Voreinstellung oder unerwarteter Fehler. Fehlende Clients dürfen **nicht** als fehlerfreie Konfiguration ausgelegt werden.
