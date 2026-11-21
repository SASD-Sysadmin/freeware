# Perl-Laufzeit und Kommando-Abhängigkeiten – FR2-02

[English](PERL-COMPATIBILITY.md) · [Projekt](../README.de.md) · [Plattformen](PLATFORMS.de.md) · [Tests](TESTING.de.md) · [Freigabelücken](RELEASE-GAPS.de.md)

**Nachweisdatum:** 18.11.2026; Dokumentation erstellt am 21.11.2026. **Geprüfter Quellstand:** `b1960f4d0dda11e736fe71829953cfb5e4398c63` (`main`). Dies ist ein vom Betreiber bereitgestellter lokaler Testnachweis, keine unabhängig attestierte CI-Evidenz. Wir dokumentieren eine *erfolgreich getestete Laufzeit*, keine universelle Perl-Mindestversion.

## 1. Kompatibilitätsaussage und Grenzen

- **Älteste bislang mit vollständiger Testsuite positiv geprüfte Perl-Version:** **Perl 5.14.4** unter Debian Linux in WSL2 (x86_64, Linux `5.15.167.4-microsoft-standard-WSL2`). `make test` endete mit Status **0**, mit dem privaten Interpreter Perl 5.14.4 und dessen `prove` (TAP::Harness 3.23).
- **Offline-Regression:** 49 Perl-Testdateien, 6.146 gemeldete TAP-Testfälle, **keine Fehler**, **10 ausdrücklich übersprungene** Fälle; außerdem bestanden beide Bash-Testgruppen zur Rotation. SKIPs sind keine ausgeführten Abnahmetests. Der Quellbestand wurde nicht verändert.
- **CLI-/Syntaxinventur:** 74 Perl-Quelldateien und 53 Perl-CLI-Einstiegspunkte, nach Reparatur des *Testinterpreters* **0** Syntax-, Hilfe- oder Versionsfehler.
- **Release-Gap-Inventur:** `PASS=288`, `GAP=0`, `MANUAL=7`. Alle sieben manuellen Freigabeprüfungen bleiben offen. Ein grünes statisches Audit ist keine Produktions- oder Releasefreigabe.
- **Weitere Laufzeit:** Ein lokales Perl-5.36.0-Audit bestand ebenfalls; die konkreten Laufzeitnachweise gelten nur für die tatsächlich ausgeführten Prüfungen.
- **Nicht nachgewiesen:** Perl 5.8, 5.10, 5.12, 5.14.0–5.14.3, jede nachfolgende Perl-Version, jede Unix-Variante, sämtliche Native-Client-Versionen oder produktive Sicherheitsfreigabe. **5.14.4 ist keine theoretisch bewiesene allgemeine Mindestversion und keine Empfehlung für Produktion.** Perl 5.14 ist abgekündigt; produktiv ist eine gepflegte Perl-Version einzusetzen.

Die bisherige pauschale Angabe „Perl ab 5.8“ wird aus den aktuellen READMEs entfernt. Der in ausgelieferten Quellen verwendete Operator `//` setzt mindestens Perl 5.10 voraus. Hinzu kommen konkrete Anforderungen an `JSON::PP` und die `Socket`-Resolver-APIs. Die historische Einführung einzelner Merkmale beweist noch keine Funktionsfähigkeit der gesamten Sammlung mit älteren Interpretern.

## 2. Perl-Module und Funktionsvoraussetzungen

| Voraussetzung | Bereich | Anforderung oder Befund | Nachweisgrenze |
| --- | --- | --- | --- |
| Perl 5 und mitgelieferte `SASD::Freeware::*`-Module | Ausgelieferte Perl-Programme | Zum Programm passende Bibliotheken unter `lib/`; einzelne kopierte Skripte sind keine vollständige Installation | Vollständige Offline-Suite auf einem Debian-/WSL2-System mit 5.14.4 bestanden |
| `strict`, `warnings`, `Getopt::Long`, `File::*`, `Digest::SHA`, `Errno`, `Fcntl` und weitere Standardmodule | Je nach Programm und Installer | Müssen in der verwendeten Laufzeit tatsächlich vorhanden und funktionsfähig sein | Syntax-, CLI-, Installer- und Fixture-Tests unter repariertem 5.14.4 bestanden |
| `JSON::PP` | JSON-Auswertung, insbesondere `mail-queue` und Linux-JSON-Funktionen | Erforderlich für entsprechende Betriebsarten; im getesteten Perl 5.14.4 enthalten (`2.27105`) | Daraus folgt keine Vollständigkeitsgarantie aller fremden Perl-Installationen |
| `Socket`-Resolver und IPv6 | `host-resolve`, DNS- und Netzwerkhelfer | Je nach Aufruf `getaddrinfo`, `getnameinfo`, `inet_pton`, `AF_INET6` | Importe bestanden; tatsächliches Resolver-Verhalten ist systemabhängig |
| `IO::Socket::SSL >= 2.009` | Verifiziertes STARTTLS von `mail-probe` | **Zusätzliches, nicht zum Perl-Kern gehörendes Modul**; bei Fehlen sicher abbrechen, nie Zertifikats-/Hostnamenprüfung abschalten | Geprüft mit `IO::Socket::SSL 2.099` und `Net::SSLeay 1.96` |
| `Net::SSLeay`, OpenSSL | TLS-Unterbau | Modul- und Bibliotheksversionen müssen zusammenpassen; keine pauschale Mindestversion bewiesen | Geprüft mit `Net::SSLeay 1.96` und OpenSSL 3.0.22 |

Das historische Test-Perl 5.14.4 enthielt zunächst eine fehlerhaft generierte `Errno.pm`: Die Konstanten `ENOENT`, `ENOTDIR`, `ELOOP`, `EEXIST`, `EWOULDBLOCK` und `EAGAIN` wurden nicht exportiert. Betroffen waren `link-audit`, `InstallLock.pm` sowie mittelbar `installation.pl`. **`Fcntl::O_NOFOLLOW` und `Fcntl::S_ISLNK` waren dagegen vorhanden.** Der historische Interpreter wurde mit `-O0 -fwrapv -fno-strict-aliasing` gebaut. Für die private Testinstallation erhielt `Errno_pm.PL` beim Generieren der Fehlerwerte die Präprozessoroption `-P`; anschließend wurde nur dort die neu erzeugte `Errno.pm` installiert. **Kein SASD-Programm und keine Sicherheitsprüfung wurden abgeschwächt.** Dies beschreibt eine historische Testumgebungs-Reparatur, keine Anleitung zur produktiven Perl-Installation.

Der einfache Importscanner meldete außerdem `administrative`, obwohl der Begriff nur aus dem Hilfetext `may require administrative permissions` in `bin/quota-report` stammte. Das ist ein Fehlalarm, kein fehlendes Modul. Das nun versionierte `tools/fr2-02-compat-audit.sh` grenzt die Texterkennung ein; es ist weiterhin kein vollständiger Perl-Parser.

## 3. Native Clients: nur für die jeweilige Funktion

Soweit nicht ausdrücklich genannt, sind **keine** minimalen Client-Versionen nachgewiesen. Das Vorhandensein einer ausführbaren Datei belegt weder kompatible Ausgaben noch ausreichende Rechte, Host-Funktionen oder eine produktive Freigabe.

| Kommando / Zweck | Native Programme | Anforderungsgrenze |
| --- | --- | --- |
| `fs-usage` | POSIX-kompatibles `df` | Dateisystemstatistik; Ausgabe systemabhängig |
| `quota-report` | Je nach Betriebsart `quota` oder `repquota` | Lesend; Quotas und Berechtigungen sind hostspezifisch |
| `quota-status` / `quota-set` | Linux `quotaon -p` / `setquota` | Statusabfrage gegenüber ausdrücklich freizugebendem Schreibvorgang; separate VM-Abnahme erforderlich |
| `dns-query`, `ldap-probe`, `nis-probe` | `dig`, `ldapsearch`, `ypwhich` | Nur für den jeweiligen Live-Aufruf; LDAP-Zertifikatsprüfung bleibt zwingend |
| `db-probe`, `db-health`, `db-activity` | Je nach Engine `psql`, `mysql` oder `mariadb` | Echte SQL-Clients; TLS, Rechte und Server-Kompatibilität gesondert prüfen |
| `db-storage` | `mysql` oder `mariadb` | PostgreSQL ist für dieses Kommando nicht implementiert |
| `mail-queue` | Live-Abfrage mit `postqueue -j` aus **Postfix >= 3.1** | `JSON::PP` zum Parsen; Offline-Tests benötigen keinen Postfix |
| `network-interface-report`, `network-route-report`, `network-service-report` | Linux `ip`/`ss`; macOS/BSD `ifconfig`/`netstat` je Kommando | Betriebssystem- und Ausgabeformatabhängigkeit; `netstat` ist keine allgemeine Linux-Voraussetzung |
| `firewall-config-audit` | Ausgewählte native Linux-/BSD-/Solaris-Werkzeuge (`nft`, `iptables-save`, `pfctl` usw.) | Nur für nativen Modus; eingelesene Text-/JSON-Fixtures brauchen die entsprechende Firewall nicht |
| `linux-distro-matrix`, `linux-container-acceptance` | `docker` oder `podman` **nur bei optionalem Containerbetrieb** | Offline-/Planungsmodus ohne Engine; keine native Zertifizierung |
| `rotate` | Bash und übliche Dateisystemwerkzeuge | **Benötigt kein Perl** |

Native Versionsuntergrenzen, abgesehen von der bestehenden Postfix-Angabe, sind **noch nicht verifiziert**. Fehlendes `quota`, `pfctl`, `docker` usw. unter Debian/WSL2 ist kein Fehler für davon unabhängige Offline-Funktionen. Maßgeblich sind die einzelnen Kommandoanleitungen und deren Sicherheitsgrenzen.

## 4. Prüfwerkzeuge und Wiederholung

Der Betreiber verwendete einen privaten Perl-Interpreter unter `~/tmp/fr2-02/perl-5.14.4-wrapv/bin/perl`, private CPAN-Module unter `~/tmp/fr2-02/perl514-tls/lib/perl5` und OpenSSL 3.0.22. Das Perl-5.14.4-Quellarchiv wurde per SHA-256 geprüft. Buildflags und die `Errno`-Reparatur sind nachvollziehbar; **nicht** dokumentiert sind verifizierte Prüfsummen für sämtliche CPAN-Distributionen, Compiler und Bibliotheken. Dies ist eine nachvollziehbare Vorgehensbeschreibung, **kein bitgenau reproduzierbarer Build**.

Aus einem sauberen Checkout und mit dem *bereits vorbereiteten* historischen Interpreter und dessen TLS-Modulen:

```bash
prefix="$HOME/tmp/fr2-02/perl-5.14.4-wrapv"
modules="$HOME/tmp/fr2-02/perl514-tls"
(
    set -euo pipefail
    export PATH="$prefix/bin:$PATH"
    export PERL5LIB="$modules/lib/perl5"
    unset PERL5OPT
    test "$(command -v perl)" = "$prefix/bin/perl"
    test "$(command -v prove)" = "$prefix/bin/prove"
    perl -e 'printf "Perl %vd\n", $^V'
    perl -MJSON::PP -MSocket=getaddrinfo,getnameinfo,inet_pton,AF_INET6 -e 'print "Standard-API-Importe OK\n"'
    perl -MIO::Socket::SSL -e 'IO::Socket::SSL->VERSION(2.009); print "Verifizierte TLS-Abhängigkeit OK\n"'
    bash tools/fr2-02-compat-audit.sh . "$prefix/bin/perl" "$HOME/tmp/.test-logs"
    make test
    make release-gap-audit
)
```

`make test` ruft Shell-Tests, Syntaxprüfungen und einzelne `prove`-Testdateien auf. Unterprozesse können sich zusätzlich nach Shebang oder `PATH` richten; ein künftiger Testhärtungs-Schritt kann jeden Kindinterpreter ausdrücklich aufzeichnen und erzwingen. Die Ausgabe beweist nicht die Ausführung jedes nativen Betriebsweges. Vollständige Logs und lokale Rechnerdetails bleiben **außerhalb von Git** und sind vor Weitergabe auf vertrauliche Daten zu prüfen.

**Noch offen:** CI-Lauf für den endgültigen Dokumentationscommit, native OS-/Laufzeit-Matrix, freigegebene privilegierte Tests in Wegwerf-VMs, Native-Client-Versionsprüfungen, Drittanbieter-Lizenzhinweise und formale Releasefreigabe. Siehe [Freigabelücken](RELEASE-GAPS.de.md) für die sieben offenen `MANUAL`-Gates.
