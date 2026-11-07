---
name: issue-uebernehmen
beschreibung: Ein Issue gemäß Agent-Konvention sauber übernehmen und abarbeiten.
wann_verwenden: Sobald ein Issue mit passendem agent:*-Label vorliegt und noch nicht geclaimt ist.
---

# Issue übernehmen

## Ziel

Keine Doppelarbeit, jederzeit sichtbarer Zustand, saubere Übergabe über
Branch und Draft-PR.

## Voraussetzungen

- Issue mit `agent:*`- und `mode:*`-Label vorhanden.
- Repo geklont, `AGENTS.md` gelesen.

## Schritte

1. Issue vollständig lesen; bei Unklarheiten im Issue nachfragen, nicht raten.
2. `/claim`-Kommentar im Issue, falls noch nicht geschehen.
3. Branch gemäß Konvention anlegen (`claude/<slug>` oder `vibe/<slug>`).
4. Umsetzen in sinnvollen Commits; Verifizierung (Tests, Lint, Build) laufen
   lassen und das Ergebnis für den PR notieren.
5. Früh Draft-PR öffnen mit `Closes #<nummer>` und ausgefüllter PR-Vorlage
   des Repos.
6. Nach Review-Punkten: Folge-Commits, kein Force-Push nach Review-Beginn.
7. Nach Merge: Issue schließen lassen, Ergebnis kurz im Issue dokumentieren.

## Grenzen

- Kein Arbeiten auf `main`, kein Claim von Issues, die bereits geclaimt sind.
- Bei Überschneidungen entscheidet der frühere `/claim`-Kommentar.
