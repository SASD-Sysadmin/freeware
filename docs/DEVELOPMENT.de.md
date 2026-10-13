# Entwicklungs- und Wartungsrichtlinien

## Ziel und Umfang

SASD Freeware stellt Kommandozeilenprogramme, Scripts und Bibliotheken für die Administration von Linux- und Unix-Systemen bereit. Die Werkzeuge sind auf zuverlässigen Betrieb, einfache Integration und langfristige Wartbarkeit ausgelegt.

## Wahl der Programmiersprache

Die Sprache richtet sich nach den betrieblichen Anforderungen des einzelnen Werkzeugs, nicht nach einer einheitlichen Vorgabe für das gesamte Repository.

- **POSIX-Shell (`sh`)** für kleine portable Programme, einfache Dateisystemaktionen und das Aufrufen anderer Prozesse.
- **Bash** für Shell-Administration, die Bash-Funktionen oder die Einbindung in bestehende Bash-Abläufe benötigt.
- **tcsh** für Abläufe der csh-Familie und systemspezifische Administration, wo tcsh sinnvoll ist; die Laufzeitvoraussetzung wird dokumentiert.
- **Perl** bevorzugt für umfangreichere Textverarbeitung, Berichte, Dateisystemanalysen, Datensätze, Netzwerkprogramme und portable Administrationswerkzeuge, wenn Shell-Code schwieriger wartbar wäre.
- **Python** nur bei einem konkreten Vorteil durch Bibliotheken oder Integration; keine automatische Alternative zu Perl.
- **C, C++ und andere Sprachen** bei Bedarf für native Schnittstellen, Leistung oder Systemintegration.

Funktionsfähige Programme werden nicht ohne technischen Anlass in eine andere Sprache übertragen.

## Programmschnittstellen

Jedes neue Kommando beschreibt Zweck, Aufruf, Parameter, Beispiele, Abhängigkeiten, Nebenwirkungen und Rückgabewerte. Neue Programme bieten `--help` und `--version`. Ausgaben sind vorhersehbar; Fehlermeldungen erscheinen auf stderr. Maschinenlesbare Ausgaben müssen auch besondere Dateinamen eindeutig übertragen können. Bestehende Schnittstellen bleiben bei Erweiterungen möglichst kompatibel.

Kurze, klare Befehlsnamen und verständliche Variablen verwenden. Wartbarkeit geht vor unnötiger Optimierung. Änderungen an Dateien und Systemkonfigurationen erfolgen nur mit ausdrücklichem Auftrag und minimal notwendigen Rechten. Ungültige Eingaben werden zurückgewiesen; schreibende Programme bieten nach Möglichkeit einen Prüfmodus wie `--dry-run`.

## Perl und Shell

Perl-Programme verwenden `strict`, `warnings`, lexikalische Variablen und geprüfte Dateioperationen. Standardmodule werden bevorzugt; Perl-Mindestversion und Fremdmodule sind anzugeben. Shell-Programme schützen Pfade durch korrektes Quoting und behandeln Dateinamen mit führenden Bindestrichen. GNU-/BSD-Unterschiede werden dokumentiert und vor Kompatibilitätsaussagen geprüft.

## Repository-Struktur

`bin/` enthält allgemeine Kommandos, `sbin/` administrative Programme; `lib/` und `lib64/` enthalten Hilfsbibliotheken. Englisch- und deutschsprachige Bedienungsanleitungen stehen in `docs/commands/`, Manpages in `man/man1/` oder `man/man8/`, Tests in `tests/` und Entwicklungs- und Wartungsrichtlinien in `docs/`.

## Tests und Veröffentlichung

Neue Programme erhalten reproduzierbare Offline-Tests für gültige und fehlerhafte Eingaben, Grenzfälle und besondere Dateinamen. `make test` verändert weder Benutzerkonten noch `/etc`, DNS, NIS oder laufende Dienste. Privilegierte und schreibende Operationen werden getrennt auf isolierten Systemen geprüft. `make install PREFIX=... DESTDIR=...` ermöglicht eine Testinstallation ohne Systemveränderung. Getestete Plattformen werden von lediglich vorgesehenen Plattformen unterschieden. Vor dem Commit sind Änderungen und Ausführungsrechte zu kontrollieren.

Eine lokale ZIP-Datei ist kein veröffentlichter Stand. Erst eingecheckte, dokumentierte und erfolgreich getestete Programme können als veröffentlicht bezeichnet werden.

Das optionale Ziel `make integration-test` prüft native DNS- und LDAPS-Clients gegen lokale Protokoll-Testdienste. `make test` bleibt unabhängig von Netzwerkdiensten. GitHub Actions erzwingt die dokumentierten Integrationsvoraussetzungen. Siehe [Integrationstests](TESTING.de.md) und [Rückgabecodes](EXIT-CODES.de.md).

## Qualitätsvertrag der Kommandozeilenschnittstellen

Alle 30 Programme unter `bin/` und `sbin/` unterstützen `--help` und
`--version`, ohne Systemdateien auszulesen, Zustände zu verändern,
Netzwerkverbindungen aufzubauen oder Root-Rechte zu benötigen. `--help`
gibt eine Aufrufhilfe auf stdout aus (Exitcode 0), `--version` gibt
`PROGRAMM MAJOR.MINOR.PATCH` gefolgt von einem Zeilenumbruch auf stdout aus
(Exitcode 0). Bei Erfolg bleibt stderr leer.

Diese **Metadatenoptionen** ersetzen keine Prüfung echter Programmaufrufe.
Ungültige Aufrufe bleiben Fehler; bereits vorhandene Rückgabecode-Konventionen
(etwa der Nagios-Modus) werden nicht verändert. Zusätzliche Optionen und
Detailausgaben der einzelnen Programme bleiben zulässig.

`make test` findet die ausführbaren Programme automatisch und prüft die
Schnittstellen, zugehörige Manpages, Leerzeichen am Ende von Markdown-Zeilen
und unaufgelöste Link-Platzhalter. In Git-Checkouts prüft es zusätzlich den
**Git-Index** auf nicht ausführbare Markdown-Dateien (`100644`). Dies ist
auch bei WSL/Windows-Mounts zuverlässig. Ohne `.git` entfällt die Indexprüfung.

`make shellcheck` analysiert das Bash-Programm und seine Tests und benötigt
ShellCheck. Ubuntu-CI installiert ShellCheck ausdrücklich; macOS-CI prüft
weiterhin Bash-Syntax und Regressionen ohne Homebrew-Voraussetzung.
