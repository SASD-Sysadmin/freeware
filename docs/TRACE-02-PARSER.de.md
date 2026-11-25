# TRACE-02-Parserreferenz

Status: im TRACE-02-Slice implementiert und mit Fixtures geprüft. Dies ist ein
interner Bibliotheksvertrag, kein öffentliches JSON-/JSONL-Schema und keine
native `strace`-Abnahme.

## API

`SASD::Freeware::Trace::Reader` verarbeitet ein ausdrücklich übergebenes
binäres Filehandle. `open_file($path)` akzeptiert nur eine vorhandene reguläre,
nicht symbolische Datei; `new(fh => \*STDIN)` ist die Grenze für stdin und Tests.
`next_record` liefert `line` mit Text und 1-basierter `line_no` oder
`truncated`, `invalid`, `error` und `eof`. Abgewiesene Datensätze enthalten nur
eine sichere Diagnose, niemals ihren Rohinhalt.

`SASD::Freeware::Trace::Strace` erhält einen Reader:

```perl
my $parser = SASD::Freeware::Trace::Strace->new(
    reader => $reader, max_pending => 1024,
);
while (my $event = $parser->next_event) { ... }
```

Ereignisse sind gebundene `SASD::Freeware::Trace::Event`-Hashes. `as_hash`
liefert eine flache Kopie für spätere interne Verbraucher. In diesem Slice gibt
es keine öffentliche maschinenlesbare Serialisierung.

## Ereignisvertrag

`type` ist `syscall`, `signal`, `process_exit`, `malformed`, `unsupported`,
`incomplete` oder `reader_error`. Jedes Ereignis trägt `platform` (`linux`),
`source_format` (`strace-text`) und `source_lines`.

Systemaufrufereignisse können Systemaufrufname, begrenzte Argumentdarstellung,
Rückgabe, errno, Fehlertext, Laufzeit, Ressourcennotation, Zeitstempel,
Zeitformat, `trace_id`, `pid_kind` und Fortsetzungsstatus enthalten. Fehlende
Werte fehlen; sie werden nicht mit null ersetzt. Laufzeit ist die mit `-T`
gedruckte Aufrufdauer, nicht CPU- oder Gesamtlaufzeit. Zeitstempel bleiben als
exakte Zeichenketten mit `tt` oder `ttt` erhalten; symbolische Rückgaben bleiben
symbolisch.

Numerische Präfixe und `[pid N]` werden als `trace_id` mit
`pid_kind => pid-or-tid` erhalten. Eine sichere PID-/TID-Bedeutung wird nicht
erfunden. Ein unpräfixierter Einzelstream nutzt intern `stream:1` nur für die
Fortsetzungszuordnung und gibt diese Identität nicht aus.

## Unterstützte Syntax und Grenzen

Unterstützt werden klassische einzeilige Aufrufe, unbekannte Systemaufrufnamen,
verschachtelte runde/eckige/geschweifte Klammern, zitierte/escaped Texte,
`-tt`-/`-ttt`-Zeitstempel, `-T`, übliche PID-Präfixe, Signale, normales und
signalbedingtes Ende, Restart-Aufrufe sowie begrenzte opake `-y`/`-yy`-Notationen.
Ein `unfinished` wird nur bei gleicher Stream-/Trace-Identität und gleichem
Systemaufrufnamen zusammengeführt. Beide Quellzeilen bleiben erhalten; das
zusammengeführte Ereignis wird einmal ausgegeben.

Nicht passende Resumes, doppelte unfinished-Identitäten, überschrittene
Pending-Grenzen und offene Aufrufe am Dateiende werden als `incomplete`
sichtbar. Fehlerhafte oder unbekannte Datensätze stoppen spätere Datensätze
nicht. `strace -c`/`-C`-Tabellen, nicht belegte Zeilenformen, allgemeine
Mehrzeiligkeit, separate `-ff`-Dateien und binäre Traceformate werden nicht
unterstützt und nie als normale Systemaufrufe interpretiert.

## Grenzen und Sicherheit

Standardmäßig gelten 65.536 Bytes Zeilenlänge, 4.096-Byte-Lesevorgänge und ein
1-MiB-Verwerfungsbudget für eine überlange Zeile. Beim Lesen wird nur das
begrenzte Präfix gehalten; die vollständige feindliche Zeile wird nie zuerst
alloziert. CRLF und die letzte Zeile ohne LF sind zulässig. NUL sowie C0-/DEL-
Steuerzeichen (außer Tab) werden abgewiesen. Der Parser hält höchstens 1.024
offene Aufrufe und begrenzt Argument-/Diagnosetext auf 4.096 Bytes.

Trace-Daten sind nicht vertrauenswürdig und möglicherweise geheim. Die
Bibliothek nutzt kein Netzwerk, keine Shell, keine Auswertung, keine Ausführung,
keine Privilegien und verändert die Quelle nicht. Verbraucher müssen
Argumentausgaben minimieren und Ausgaben privat halten.

`tests/test_trace_parser.t` prüft synthetisch offline einfache, historische und
unbekannte Namen, Zeiten, Laufzeiten, Fehler, Signale, Enden, verschachtelte
Syntax, unfinished/resumed, fehlerhafte/überlange Eingaben, NUL/Steuerzeichen,
CRLF, exakte Zeilenreferenzen und 10.000 Zeilen. Dies ist keine native
strace-Abnahme. TRACE-03 darf den Ereignisstrom begrenzt aggregieren und muss
diese Unterscheidungen erhalten.
