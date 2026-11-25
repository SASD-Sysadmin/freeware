# Entwurf zur Systemaufrufanalyse (TRACE-01)

[English](TRACE-ANALYSIS-DESIGN.md) · [Roadmap](ROADMAP.de.md) · [Projekt](../README.de.md)

**Status:** Planungsnachweis für TRACE-01, 25. November 2026. Dieses Dokument spezifiziert einen Entwurf; es liefert weder Parser noch neues Kommando, nativen Adapter oder Releasezusicherung.

## 1. Ziel und Nichtziele

Die geplante Toolbox verarbeitet einen ausdrücklich angegebenen, gespeicherten Systemaufruf-Mitschnitt zu einem kleinen, reproduzierbaren und lesenden Diagnosebericht. Sie ist für Unix-Pipelines und die Übergabe eines Vorfalls gedacht, nicht als Ersatz für das aufzeichnende Tracing-Werkzeug.

Nichtziele für TRACE-01 und das erste MVP:

- kein Live-Attach, keine Aufzeichnung, Befehlsausführung, Debugger, GUI, Webdienst, Daemon, Datenbank, Upload oder automatische Reparatur;
- ein fehlgeschlagener oder langsamer Aufruf beweist keinen Anwendungsfehler;
- keine verlustfreie Universalrepräsentation aller Unix-Traceformate;
- keine Supportzusage für Solaris, AIX, BSD oder macOS;
- keine Änderung an `core-report` oder der CD-01–CD-07-Planung.

Die erste Implementierungsgrenze ist nach gesonderter Prüfung dieses Entwurfs TRACE-02–04 und TRACE-07. TRACE-01 selbst bleibt Dokumentation.

## 2. Vorhandener Repository-Stand

Das Repository ist eine Perl-/Shell-Sammlung mit Offline-Tests, ausdrücklichen Exit-Code-Konventionen und lesenden Standardaktionen. Relevante Wiederverwendung:

| Vorhandene Komponente | Entscheidung |
| --- | --- |
| `SASD::Freeware::External` | Sucht erlaubte native Helfer über absolute `PATH`-Einträge. Darf kein Shell-Auswerter werden. |
| `bin/process-report` | Muster für begrenzte Eingaben, explizite `ps`-Argumentvektoren, Fixture-Eingabe, fehlerhafte Datensätze und lesende Prozessberichte. |
| `bin/log-summary` | Kleine Streaming-Schleife und pipelinefähige Aggregation. Die freie Schweregradsuche ist kein Traceparser. |
| `SASD::Freeware::Walk` und Netzwerkmodule | Vorhandene Grenzen für spätere, tatsächlich benötigte Datei-/Native-Ausgaben; keine Kopplung an TRACE-02. |
| `bin/core-report` | Getrennte Kandidateninventur für Core-ähnliche Dateinamen. Keine Inhaltsprüfung und keine doppelte Trace-Suche. |
| `tests/test_cli_contracts.t`, `tests/test_repository_contracts.t` | Spätere Kommandos müssen Help/Version, Dokumentation, Dateimodi und Markdown-Verträge erhalten. |

Derzeit gibt es keine Bibliothek für Systemaufruf-Traces und kein Kommando für Capture oder Attach. `External.pm` ist nur ein Finder, keine Berechtigungs- oder Sandbox-Schicht.

## 3. Nachweis und Werkzeugvergleich

Geprüft am 25. November 2026. „Nicht verifiziert“ bedeutet, dass weder ein lokales Programm noch eine ausreichend maßgebliche, versionsbezogene Quelle vorlag; es ist keine Supportaussage.

| Werkzeug/Familie | Befund und Grenze | Entscheidung |
| --- | --- | --- |
| Linux `strace` | Linux-Tracer über ptrace. `-o` schreibt Text; `-f` verfolgt Kinder/Threads, `-ff` trennt Dateien; `-tt`/`-ttt` liefern Zeitstempel; `-T` Laufzeiten; `-y`/`-yy` gegebenenfalls Dateideskriptor-Ressourcen. Ausgabe kann Signale, unfinished/resumed sowie gekürzte/escapte Argumente enthalten. | Offiziell LGPL-2.1-or-later. Native Berechtigungs-, Kernel- und Laufzeiteinflüsse gehören zum Aufzeichner, nicht zum Offlineparser. |
| `strace-log-merge` | Offizielles strace-Hilfsprogramm für `strace -ff -tt`; es sortiert nach Textzeitstempel. Es beweist keine Kausalordnung und hilft ohne vergleichbare Zeitstempel nicht. | Mit strace gebündelt, LGPL-2.1-or-later. Optionales Bedienerwerkzeug, keine automatische Abhängigkeit. |
| `stracepy` | Python-Skripte für CSV und Dateisystemzusammenfassungen; laut Projekt auch Mehrthread-Eingaben. Eigene Laufzeit/Requirements liegen außerhalb der Perl-Standardlaufzeit. | Laut Repository MIT. Vergleichsmaterial, keine Abhängigkeit; Wartung und genaue Formatabdeckung später erneut prüfen. |
| `strace-analyzer` | Rust-Programm für Lese-/Schreib- und Dateisystemsummen. README begrenzt Eingaben auf eine bestimmte `-s0 -ff -o`-Form und unterstützt keine zeitgestützten Varianten oder mehrere Prozess-IDs in einer Datei. | Laut Repository GPL-3.0-or-later. Nützlicher Vergleich, aber keine Einbettung in das MIT-Repository. |
| `strace-tui` | Rust-TUI für verbreitete strace-Optionen, JSON-Ausgabe, Filter/Suche und Prozess-/Deskriptoransicht; Projekt nennt fehlende Filter/Exporte und Kürzungen. | Apache-2.0 oder MIT. Interaktive Ansicht liegt außerhalb des SASD-Kerns und brächte Rust/Cargo. |
| `strace-graph` | In dieser Prüfung wurde kein eindeutiges, maßgebliches Projekt mit exakter Version identifiziert. | Keine Fähigkeit oder Lizenz aus ähnlich benannten Projekten ableiten. Nur mit genauer Quelle erneut prüfen. |
| Solaris `truss` | Versionsabhängige Textformate, Zeit-/Delta-Zeit, Signale und teils User-Level-Trace. Keine Solaris-Laufzeit für native Prüfung vorhanden. | Nur Kandidat; Release, Beispiele und Privilegien vor Code festhalten. |
| AIX `truss` | IBM dokumentiert Systemaufrufe, Thread-IDs, Zeit-/Delta-Zeit, Signale und mögliche privilegierte Operationen; AIX-Namen und `Err#`-Formen sind eigenständig. | Nur Kandidat; nicht mit Solaris/Linux-Syntax gleichsetzen. |
| FreeBSD `truss` | FreeBSD-Handbuch dokumentiert einen nativen Tracer mit eigener Syntax. Keine Fixture und kein nativer Lauf vorhanden. | Nur Kandidat; unbekannte Felder und Versionsemantik bewahren. |
| FreeBSD/OpenBSD `ktrace`/`kdump` | `ktrace` schreibt einen Kernel-Mitschnitt, `kdump` rendert ihn. Binärformat und Vokabular unterscheiden sich von strace-Text. | Später vertrauenswürdiges `kdump` oder separat belegter Decoder; im MVP kein Binärdecoder. |
| macOS `dtruss` | DTrace-basiert, kann Aufrufe, Argumente, Rückgaben, errno und Zeiten zeigen. SIP, Entitlements, Version und Root-Anforderungen begrenzen es. | Capture außerhalb TRACE-01/MVP; später versions- und freigabebezogen. |

Geprüfte Quellen: [strace](https://github.com/strace/strace), [strace-Handbuch](https://man7.org/linux/man-pages/man1/strace.1.html), [strace-Lizenzhinweis](https://github.com/strace/strace/blob/master/Makefile.am), [stracepy](https://github.com/bmwcarit/stracepy), [strace-analyzer](https://github.com/wookietreiber/strace-analyzer), [strace-tui](https://github.com/Rodrigodd/strace-tui), [IBM AIX truss](https://www.ibm.com/docs/en/aix/7.1.0?topic=t-truss-command), [FreeBSD truss](https://man.freebsd.org/cgi/man.cgi?manpath=FreeBSD+13.4-RELEASE&query=truss&sektion=1) und [dtruss-Handbuch](https://man.freebsd.org/cgi/man.cgi?apropos=0&manpath=macOS+13.6.5&query=dtruss&sektion=1m). Solaris und OpenBSD bleiben hier nicht verifiziert. Alle genannten Programme fehlten im lokalen `PATH`; es wurde nichts installiert.

Der praktische SASD-Mehrwert ist daher ein kleiner, abhängigerkeitsarmer, begrenzter Offlineparser mit erklärbarem Bericht: Vorhandene Programme zeichnen oder visualisieren gut, liefern aber nicht den Perl-, Pipeline-, Sicherheits-, EN/DE- und Unsicherheitsvertrag dieses Repositories.

## 4. Architektur

Nach TRACE-01-Prüfung in kleinen Schichten implementieren:

1. `SASD::Freeware::Trace::Reader` — begrenzter Byte-/Zeilenleser für ausdrücklich angegebene reguläre Datei oder stdin; meldet Kürzung und verworfene Datensätze.
2. `SASD::Freeware::Trace::Strace` — Linux-Textadapter; liefert Events oder ausdrücklich `unknown`, `incomplete`, `malformed`, `unsupported`.
3. `SASD::Freeware::Trace::Event` — kleiner Konstruktor/Validator ohne Ergänzung fehlender Werte durch Vermutung.
4. `SASD::Freeware::Trace::Aggregate` — begrenzte Zähler und Top-N-Sichten nach Aufruf, errno, PID/TID und bekannter Ressource.
5. `SASD::Freeware::Trace::Rules` — reine, nachvollziehbare Befunde mit Zeilenbelegen und Evidenzklasse.
6. Erstes CLI, vermutlich `trace-report` oder `trace-summary`, nach Auswahl des Vertrags. Weitere Kommandos nur bei deutlich anderem Output-/Pipeline-Nutzen.

Keine zwölf dünnen Aliase. Eine erste Aufteilung kann kompakte Zusammenfassung/Bericht und später fokussierte Fehler-, Zeit- und Ressourcensichten umfassen. `trace-capture`, `trace-sanitize` und Vergleich sind eigene Freigabe-/Entwurfsslices.

Perl-Standardmodule, Dreiargument-`open`, Argumentvektoren und keine Shell-Interpolation verwenden. Der Parser sollte eine Filehandle-Abstraktion erhalten, damit Tests mit Scalar-Fixtures möglich sind, ohne die Produkt-Eingaberegeln zu verändern.

## 5. Kleines Ereignismodell

Ein Event ist ein Faktenrecord, keine Zusage, dass jeder Adapter jedes Feld liefern kann:

| Feld | Bedeutung und Fehlen |
| --- | --- |
| `schema` | Versionierte interne Schema-ID, nur mit dokumentiertem Maschinenvertrag. |
| `platform` | Beobachtete Adapterfamilie, zunächst `linux-strace`; nicht aus einem Namen erraten. |
| `source_format` | Variante wie `strace-text`, `strace-text-pid` oder `unknown`. |
| `source_line` | Begrenzte 1-basierte Eingabezeile als Beleg. |
| `pid`, `tid` | Nur aus validiert gedruckten IDs; PID nicht stillschweigend als TID verwenden. |
| `timestamp` | Zeit plus Präzision/Uhrform, wenn vorhanden; sonst unbekannt. |
| `syscall` | Gedruckter Name oder ausdrücklicher unbekannter Record. |
| `arguments` | Begrenzte, escapte Textdarstellung; nie auswerten. |
| `return_value` | Eindeutiges numerisches/symbolisches Ergebnis. |
| `errno` | Gedrucktes Symbol und optional Zahl; `ERESTART*` nicht automatisch als Endfehler werten. |
| `duration` | Nur gedruckte `-T`-Laufzeit; weder CPU- noch Gesamtlaufzeit. |
| `signal` | Separater Signalrecord. |
| `process_event` | fork/clone/exec/exit nur bei Beobachtung; keine Elternbeziehung aus Reihenfolge ableiten. |
| `fd/resource` | Pfad/Socket/Device nur bei belastbarer Quellinformation; Wiederverwendung und Prozessbezug offen halten. |
| `continuation` | `complete`, `unfinished`, `resumed`, `signal`, `unknown` oder `malformed`. |
| `confidence` | `observed`, `heuristic`, `corroborated` nur mit unabhängiger Evidenz. |

Unbekannte und fehlende Werte bleiben null/unbekannt. Keine erfundenen Zeitstempel, Laufzeiten, Eltern, Ressourcen-IDs oder Reihenfolgen.

## 6. Linux-V1-Formatvertrag

Zuerst einfache `strace -o trace.log`-Texte ohne erforderliche Zeit/Laufzeit, danach ausgewählte Kombinationen:

- normale Aufrufe und Ergebnisse;
- PID/TID-Präfixe aus `-f`/`-ff`;
- `-tt`/`-ttt` und `-T`;
- Signale, Prozessende sowie unfinished/resumed;
- `-y`/`-yy` zunächst nur als begrenzter, opaker Ressourcenbeleg.

`-c`/`-C` sind Aggregatsummen, keine Eventströme; sie werden abgewiesen oder als eigener nicht unterstützter Quelltyp behandelt. Separate `-ff`-Dateien benötigen einen eigenen Merge-Vertrag; eine Datei darf keine globale Reihenfolge vortäuschen.

Parsingregeln:

- verschachtelte Klammern, Anführungszeichen und Escapes ohne Auswertung behandeln;
- unfinished/resumed nur für dieselbe validierte PID/TID verbinden; unklare Paare sichtbar unvollständig lassen;
- Mehrzeiliges nur mit begrenzter Fortsetzungsregel und Zeilenbeleg akzeptieren;
- unbekannte Systemaufrufe und nicht unterstützte Syntax als Daten erhalten;
- NULs, Steuerzeichen, überlange Zeilen, ungültige Zahlen, offene Quotes und abgeschnittene Fortsetzungen zählen/ablehnen;
- große Dateien streamend, offene Aufrufe und Schlüsselanzahl begrenzen; alle Grenzen ausweisen;
- Terminalausgabe byte-sicher escapen und Maschinenformate eindeutig begrenzen.

Das Ende eines Traces mit offenem Aufruf ist kein zurückgegebener Fehler. `EINTR`, Restart-Marker und normale Nonblocking-Ergebnisse bleiben für die Diagnose sichtbar.

## 7. Diagnose-Regelkatalog

Jeder Befund enthält Zeilen, Kontext und eine Alternativerklärung; keine Reparatur und keine unbelegte Root-Cause.

| Signal | Vorsichtige Deutung |
| --- | --- |
| `ENOENT` | Fehlender Pfad oder erwartete Suche; relevant bei wiederholtem Pflichtpfad-Kontext. |
| `EACCES`, `EPERM` | Zugriffs-/Policy-Hinweis; Reproduktionsprivileg von tatsächlicher Ablehnung trennen. |
| `EAGAIN`, `EINTR`, `EINPROGRESS` | Häufig normale Wiederholung/Nonblocking/Signalbehandlung. |
| `ENOSPC`, `ENOMEM`, `EMFILE`, `EIO`, `EROFS` | Kontextabhängig starke Hinweise, gemeinsam mit Operation, Prozess und Umfeld. |
| `ECONNREFUSED`, `ETIMEDOUT` | Endpunkt-/Verfügbarkeits- oder Timeout-Hinweis, kein Beweis für entfernte Ursache. |

Lange `poll`, `select`, `futex`, `read` usw. können normale Wartezeiten sein. `-T` misst einzelne Aufrufe; parallele Aufrufe überlappen. Eine Slow-Call-Sicht darf daher nur „lange beobachtete Aufrufdauer“ sagen, nicht CPU-Engpass oder Hänger.

Befundklassen: `fact`, `normal-pattern`, `attention`, `hypothesis`, `corroborated`. TRACE-02 testet Parsing, TRACE-03/04 Regelbefunde mit positiven und negativen Fixtures.

## 8. CLI-, Datenschutz- und Sicherheitsvertrag

Das erste Kommando folgt den Repository-Regeln: `--help`/`--version` sind nebenwirkungsfrei; `--input FILE` oder `-` ist lesend; kein Hostscan/Capture; Diagnosen nach stderr; Ausgabe begrenzt und pipelinefähig. Vorgeschlagene Statuslogik: `0` vollständig/keine Befunde, `1` vollständig mit Befunden oder verworfenen Records, `2` Nutzungs-/Eingabefehler, `3` fehlende Voraussetzung/Ausführungsfehler. Vor TRACE-02 muss festgelegt werden, ob verworfene Records 1 oder 3 bedeuten; erst dann wäre `docs/EXIT-CODES.md` zu erweitern.

Trace-Inhalte sind nicht vertrauenswürdig und möglicherweise geheim. Reguläre Dateien und Symlink-Regeln prüfen, Quelle nicht überschreiben, Trace-Text nie ausführen, Argumentpuffer standardmäßig nicht ausgeben, Steuerzeichen escapen und private Exportziele ausdrücklich verlangen. Kein Netz, Upload, Symbol-Download, Privilegwechsel, ptrace-Policy-Wechsel oder Live-Attach.

## 9. Teststrategie

TRACE-02 braucht geheimefreie Fixtures für einfache/zeitgestempelte Varianten, PID/TID, `-T`, `-y`/`-yy`, `-ff`, verschachtelte und escapte Argumente, Signale, Exits, Restarts, unfinished/resumed, unbekannte/fehlende/abgeschnittene/malformed Records, NUL/Steuerzeichen, Größenlimits, Descriptor-Wiederverwendung und unklare Prozessbeziehungen. Große erzeugte Streams müssen Speicher-, Pending- und Ausgabelimits belegen. Regeln erhalten stabile Zeilenbelege und positive/negative Tests.

Fixture-Tests sind keine native Abnahme. TRACE-10 muss später exakte strace-Version, Kernel/Distribution, Flags, Sollbefunde und Grenzen in unprivilegierter Wegwerf-Umgebung dokumentieren. TRACE-11 benötigt je OS/Werkzeug eigene Evidenz. CI-Tests auf Ubuntu/macOS können Offline-Fixtures ausführen, aber keine ptrace-, Solaris-, AIX-, BSD- oder macOS-Trace-Unterstützung zertifizieren.

## 10. Offene Entscheidungen und Abnahmekriterien

Vor TRACE-02 offen: finaler Kommando- und Outputname, Schema, Zeilen-/Pending-Limits, Status bei malformed Input, konkrete Mehrzeilengrammatik, Descriptorannotation, Uhrbezeichnung und Bedarf eines JSONL-Formats.

TRACE-01 ist abgeschlossen, wenn dieser Entwurf zweisprachig geprüft ist, Quellen und Lizenzen verknüpft sind, Event- und Formatvertrag keine erfundenen Informationen erlauben, Sicherheitsgrenzen klar sind und TRACE-02 deterministische Fixture-/Native-Kriterien besitzt. Kein Release-Gate und keine Plattformunterstützung werden dadurch geschlossen.

## 11. Empfehlung für TRACE-02

Einen gemeinsamen streamenden Linux-Textleser und einen strace-Adapter in Perl mit Standardmodulen implementieren. Mit einfachem `-o` sowie PID/TID, Zeitstempeln, Laufzeit, Signalen und unfinished/resumed beginnen. Vor Summen zunächst Eventstrom und sichtbare Behandlung fehlerhafter/unbekannter/abgeschnittener Eingaben testen. Kein Capture und kein Nicht-Linux-Adapter in diesem Slice.
