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

`bin/` enthält allgemeine Kommandos, `sbin/` administrative Programme; `lib/` und `lib64/` enthalten Hilfsbibliotheken. Englisch- und deutschsprachige Bedienungsanleitungen stehen in `docu/`, Manpages in `man/man1/` oder `man/man8/`, Tests in `tests/` und Wartungsinformationen in `docs/`.

## Tests und Veröffentlichung

Neue Programme erhalten reproduzierbare Offline-Tests für gültige und fehlerhafte Eingaben, Grenzfälle und besondere Dateinamen. `make test` verändert weder Benutzerkonten noch `/etc`, DNS, NIS oder laufende Dienste. Privilegierte und schreibende Operationen werden getrennt auf isolierten Systemen geprüft. `make install PREFIX=... DESTDIR=...` ermöglicht eine Testinstallation ohne Systemveränderung. Getestete Plattformen werden von lediglich vorgesehenen Plattformen unterschieden. Vor dem Commit sind Änderungen und Ausführungsrechte zu kontrollieren.

Eine lokale ZIP-Datei ist kein veröffentlichter Stand. Erst eingecheckte, dokumentierte und erfolgreich getestete Programme können als veröffentlicht bezeichnet werden.
