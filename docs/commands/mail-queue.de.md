# `mail-queue` – lesender Postfix-Queue-Bericht (M6.2)

[English](mail-queue.md) · [Projekt](../../README.de.md) · [Roadmap](../ROADMAP.de.md) · [Manpage](../../man/man1/mail-queue.1)

## Zweck und Voraussetzungen

`mail-queue` liefert einen begrenzten, **aggregierten Schnappschuss** der
lokalen Postfix-Mailwarteschlange. Es werden keine Queue-IDs, Absender- oder
Empfängeradressen, Nachrichteninhalte oder Zustellfehlermeldungen ausgegeben.
Das Programm führt ausschließlich `postqueue -j` aus, verfügbar ab
**Postfix 3.1**. Es verwendet weder `postqueue -f`/`-i` noch `postsuper`.
Mailversand, AUTH, Queue-Änderungen und Root-Rechte sind nicht vorgesehen.
Für die Abfrage gelten die normalen lokalen Postfix-Berechtigungen.

Voraussetzung ist Perl mit `JSON::PP` (bei aktuellen Perl-Installationen
üblicherweise enthalten). Es wird nichts aus CPAN nachinstalliert.
Mit `--input` können synthetische Testdaten ohne Postfix auf Linux und macOS
geprüft werden. Exim, Sendmail, ältere `mailq`-Textausgaben und entfernte
Mailwarteschlangen gehören nicht zu M6.2.

## Verwendung

```sh
# Lokale Postfix-Queue abfragen, ohne Zustellaktionen
./bin/mail-queue
./bin/mail-queue --timeout 8

# Explizites vertrauenswürdiges Postfix-Programm
./bin/mail-queue --client /usr/sbin/postqueue

# Offline-Bericht aus einer Testdatei; kein nativer Aufruf
./bin/mail-queue --input ./queue-fixture.jsonl

# Maschinenformat: vier NUL-terminierte Felder pro Datensatz
./bin/mail-queue --input ./queue-fixture.jsonl --null

./bin/mail-queue --help
./bin/mail-queue --version
```

`--timeout` akzeptiert 1–30 Sekunden (Standard 10) als Gesamtzeit für den
nativen Prozess. `--client` erfordert eine absolute ausführbare reguläre Datei
(keinen Symlink). Die automatische Suche ignoriert relative PATH-Komponenten.
`--client` und `--input` schließen sich aus. Die Eingabedatei muss lesbar,
regulär und darf kein Symlink sein.

Geerbte Umgebungsvariablen `MAIL_CONFIG` und `MAIL_VERBOSE` werden beim
nativen Aufruf entfernt, damit nicht unbemerkt eine andere Postfix-Instanz
abgefragt wird. Als `--client` nur ausdrücklich vertrauenswürdige Programme
angeben, keine unbekannten Skripte.

## Ausgabe und Bedeutung

```text
QUEUE       MESSAGES  BYTES  RECIPIENTS
maildrop    0         0      0
incoming    1         900    2
active      2         1800   2
deferred    1         700    1
hold        0         0      0
other       0         0      0
TOTAL       4         3400   5
```

Die echte Ausgabe ist tabulatorgetrennt; die sieben Zeilen haben eine feste
Reihenfolge. `BYTES` summiert Postfix-`message_size` (Nachrichtenkopf und
-inhalt), **nicht die Dateisystembelegung**. `RECIPIENTS` ist die Anzahl
verbleibender Empfängerobjekte, keine Zahl eindeutiger Mailadressen.
Unbekannte Queue-Typen werden datenschutzfreundlich als `other` gezählt.

Laut Postfix ist `postqueue -j` **keine atomare Momentaufnahme**. Während
sich die Warteschlange verändert, können Nachrichten doppelt gezählt oder
übersehen werden. Ein erfolgreicher Lauf ist daher kein transaktional
konsistentes Audit. Bei Größen- oder Mengenüberschreitungen wird kein
unvollständiger Gesamtwert als Erfolg ausgegeben.

## Rückgabecodes und Grenzen

| Code | Bedeutung |
| --- | --- |
| `0` | Vollständige Liste ausgewertet, keine Einträge in `deferred`, `hold` oder `other`; auch eine leere Queue. |
| `1` | Warteschlangenbefund (`deferred`, `hold`, `other`) oder nativer Postfix-Fehler; bei nativem Fehler ohne Bericht. |
| `2` | Fehlerhafte Parameter, insbesondere gleichzeitiges `--input`/`--client`. |
| `3` | Fehlende/unsichere Voraussetzung, Timeout, ungültige JSON-Lines-Daten, Größen-/Anzahlgrenze überschritten; keine Teilerfolge. |

Maximal **8 MiB** pro Abfrage, **64 KiB** pro JSON-Zeile und **20.000
Nachrichten**. Zahlen und Summen müssen als begrenzte nichtnegative
Ganzzahlen darstellbar sein. `--null` liefert exakt vier NUL-terminierte
Felder je Datensatz: Queue-Name, Nachrichtenzahl, Bytes, Empfängerzahl;
ohne Kopfzeile.

## Datenschutz, Sicherheit und Tests

Postfix-JSON kann private Mailadressen und Fehlermeldungen enthalten.
`mail-queue` prüft die nötigen Strukturen, veröffentlicht aber nur
Aggregatwerte. Native stderr-Ausgaben werden unterdrückt, stdout und
Prozesslaufzeit begrenzt. Der Aufruf verwendet eine Argumentliste ohne Shell.
Echte ungeschwärzte `postqueue -j`-Daten sollten nicht als öffentliche
Test-Fixtures gespeichert werden. Eine `--input`-Datei wird nur gelesen.

```sh
perl -c bin/mail-queue
prove tests/test_mail_queue.t
make test
make shellcheck
# CI prüft außerdem Installation/Deinstallation und bisherige Integrationstests.
```

Die automatischen Tests verwenden künstliche JSON-Lines- und Client-Daten.
**Eine echte Postfix-3.1+-Abnahme steht noch aus.** Erfolgreiche Ubuntu-/macOS-
CI beweist die Parser-/CLI-Funktion, nicht den Betrieb auf einem realen
Postfix-Mailserver.

Offizielle Dokumentation: [postqueue(1)](https://www.postfix.org/postqueue.1.html).
