---
name: fehler-melden
beschreibung: Ablauf, wenn in einer Sitzung etwas schiefgelaufen ist.
wann_verwenden: Bei Fehlern, Fehlbedienung oder Verstößen gegen die KI-Regeln.
---

# Fehler melden

## Ziel

Volt-KI-Regel 5 umsetzen: sofort stoppen, nichts still aufräumen, Martin
informieren, nichts eigenmächtig aus der Git-Historie löschen.

## Voraussetzungen

Keine; der Skill gilt ausdrücklich auch, wenn gerade nichts anderes erreichbar
ist.

## Schritte

1. **Sofort stoppen** – keine weiteren Verarbeitungsschritte, keine weiteren
   Commits oder Pushes.
2. **Nichts still aufräumen** – nichts löschen, umbenennen oder umschreiben,
   auch nicht, um den Fehler zu verbergen.
3. **Lage festhalten** – was passiert ist, in welcher Datei/Zeile, welcher
   Kategorie (nur Pfad und Kategorie, nie Inhalte bei personenbezogenen
   Daten, Regel 1).
4. **Martin informieren** – im laufenden Chat melden; betrifft ein Repo
   zusätzlich ein Issue mit Label `human` und eine genaue Beschreibung ohne
   sensible Inhalte.
5. **Abwarten** – keine Aufräum- oder Fixarbeit ohne Martins Entscheidung;
   die Entscheidung wird im Issue dokumentiert.

## Grenzen

- Kein eigenmächtiges Entfernen aus der Git-Historie.
- Kein Fix „im Vorbeigehen", auch wenn er einfach erscheint.
