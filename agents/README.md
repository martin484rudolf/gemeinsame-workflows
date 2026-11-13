# Agenten-Profile

Profile für wiederverwendbare Agenten-Rollen. Sie beschreiben Rolle, Befugnisse
und Grenzen einer Rolle – werkzeugneutral, so dass Claude Code, Vibe (Mistral)
und (soweit sinnvoll) lokale Modelle dieselbe Rolle ausfüllen können. Ein Issue
mit passenden Labels instanziiert die Rolle; die Profile selbst enthalten kein
Wissen und keine Chat-Protokolle. Die Regeln und Labels aus
`Mistral-1/AGENTS.md` bleiben massgeblich; die Profile werden hier gepflegt,
weil Mistral-1 archiviert ist.

## Aufbau

```
agents/
  <rolle>.md    Pflicht: Rolle, Befugnisse, Grenzen, Ablauf
```

Neue Profile entstehen wie Skills über Issue + PR (siehe
`skills/README.md`); Änderungen genauso.

## Instanziierung

Ein Issue mit `agent:*`- und `mode:*`-Label legt fest, wer eine Rolle
ausfüllt. Bei `mode:review` füllt der `review:*`-Agent das Profil
`reviewer.md` aus. Der aktuelle Zustand bleibt jederzeit aus den Labels
ablesbar.
