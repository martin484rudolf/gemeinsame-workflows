---
name: review-durchfuehren
beschreibung: Review eines PRs nach den festen Kriterien aus Mistral-1/AGENTS.md.
wann_verwenden: Immer wenn ein PR eines anderen Agenten oder von Martin zur Prüfung vorliegt.
---

# Review durchführen

## Ziel

Einheitliche, nachvollziehbare PR-Reviews. Jeder Review-Punkt ist konkret und
wird vom Implementer adressiert oder begründet abgelehnt.

## Voraussetzungen

- PR-Nummer und Repo bekannt.
- `AGENTS.md` des Repos gelesen (Labels, Branch-Konventionen, Kommunikationsregeln).

## Schritte

1. PR und zugehöriges Issue lesen; `mode:*`-Label beachten.
2. Branch lokal auschecken, Änderungen im Diff vollständig lesen.
3. Prüfen:
   - Erfüllt der PR das Issue (Ziel, Abgrenzung, Akzeptanzkriterien)?
   - Kleinste sinnvolle Änderung, keine unrelated Edits, keine Secrets?
   - Keine personenbezogenen Daten (Volt-KI-Regel 1)?
   - Keine Chat-Protokolle in Commits oder Dateien?
   - Passen Naming, Stil und Fehlerbehandlung zum Umfeld?
4. Verifizierung selbst ausführen (Tests, Lint, Build) statt nur zu glauben.
5. Ergebnis als PR-Review: pro Punkt ein Kommentar; Approval erst wenn keine
   blockierenden Punkte offen sind.
6. Bei Meinungsverschiedenheiten ohne Einigung: Kommentar mit Label `human`
   markieren, weitere Arbeit stoppen (Eskalationsregel in `AGENTS.md`).

## Grenzen

- Kein Merge ohne Approval; kein Force-Push nach Review-Beginn.
- Der Reviewer ändert nichts selbst am Branch des Implementers.
