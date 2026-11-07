# Skills

Werkzeugneutrale Fähigkeits-Anweisungen für Claude Code, Vibe (Mistral) und
Open WebUI – gepflegt an einer Stelle, genutzt von allen. Konzept angelehnt an
die Skills von Claude Code: pro Skill ein Ordner mit einer `SKILL.md`, die
Beschreibung genügt für die Auswahl, der volle Inhalt wird erst bei Bedarf
gelesen (progressive disclosure).

## Aufbau

```
skills/
  <skill-name>/
    SKILL.md      Pflicht: name, beschreibung, wann verwenden, Schritte
```

Neue Skills entstehen aus `VORLAGE.md` (Kopie als `skills/<name>/SKILL.md`).

## Prozess: Anlage

1. **Issue** im Repo `martin484rudolf/Mistral-1` mit der Issue-Vorlage
   „Agent-Auftrag" (Labels `agent:*`, `mode:*` Pflicht). Das Issue beschreibt
   Ziel und Abgrenzung des Skills.
2. **Anlegen**: Der zuständige Agent kopiert `VORLAGE.md` nach
   `skills/<name>/SKILL.md`, füllt sie aus und committet auf einem Branch
   gemäß Branch-Konvention (`claude/<slug>` oder `vibe/<slug>`).
3. **Draft-PR** mit Verweis auf das Issue (`Closes #<nummer>`).
4. **Review**: Immer der andere Agent (Default-Regel aus `Mistral-1/AGENTS.md`).
   Geprüft wird vor allem: Ist der Skill werkzeugneutral? Enthält er keine
   personenbezogenen Daten, keine Secrets, keine Chat-Protokolle?
5. **Merge** erst nach Approval.

## Prozess: Pflege

- Jede Änderung an einem Skill läuft wie die Anlage über Issue + PR – nie als
  Direktcommit auf `main`.
- Veraltete Skills werden nicht still gelöscht: Issue anlegen, im PR entfernen,
  Grund im Issue dokumentieren (passt zur Volt-KI-Regel 5).
- Skills enthalten kein Wissen, das woanders besser aufgehoben ist:
  Projektwissen gehört ins wissen-Repo (`~/wissen`), Regeln in die
  `CLAUDE.md`/`AGENTS.md` der jeweiligen Repos. Ein Skill beschreibt nur
  *wie* etwas wiederholt getan wird.
- Zustand ist jederzeit aus den offenen Issues/PRs ablesbar.

## Einbindung der Werkzeuge

| Werkzeug | Einbindung |
|---|---|
| Claude Code | Liest `skills/<name>/SKILL.md` direkt aus dem Klon; `CLAUDE.md` der Projekte verweist darauf (verweisen, nicht kopieren) |
| Vibe (Cloud) | Liest den gespiegelten Klon in der Sitzung; gleiche Dateien, gleicher Stand |
| Open WebUI | Optional: Skills als Knowledge-Sammlung pflegen und im Chat per `#` zuschalten (Sync wie in `lokale-modelle/docs/open-webui/05-gemeinsame-wissensquelle.md`) |

Vor der Spiegelung/Cloud-Nutzung gilt Volt-KI-Regel 1: keine personenbezogenen
Daten; im Zweifel Martin fragen.
