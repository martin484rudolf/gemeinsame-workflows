# Herzschlag (Heartbeat)

Ein Bash-Skript fuer den Keller-Rechner (Debian, Benutzer `vibe`, F4r/F3e), das
regelmaessig prueft, ob in den Koppel-Repos etwas offen und liegen geblieben
ist – wie ein Herzschlag im Kreis, damit nichts vergessen wird. Es laeuft per
systemd-Timer (Standard: 1 h), unabhaengig von GitHub-Actions-Kontingenten.

Der Herzschlag schlaegt im Takt, aber er **pingt nur bei Bedarf**:
Still = alles gut. Jeder Ping nennt genau eine konkrete naechste Handlung,
mit Drossel (maximal `maxPings` pro Punkt, danach Stille-Modus).

## Funktionsweise

```
systemd-Timer (OnCalendar=hourly, Persistent=true)
  └─ heartbeat.sh (User: vibe)
       ├─ Quittungs-Check im Handshake-Klon (Script aus Handshake PR #44)
       │    └─ offene Uebergaben ohne Quittung -> Log
       ├─ gh pr list   (je Repo, Zustand: offen)
       ├─ gh issue list (je Repo, Labels agent:vibe / agent:both)
       └─ Regeln pruefen -> Log; bei Bedarf GitHub-Kommentar als Ping
```

- **Konfiguration:** `~/.config/vibe/heartbeat-config.json`
  (Vorlage: `heartbeat-config.beispiel.json`)
- **Log:** `~/.local/state/vibe/heartbeat.log`
- **Zustand (Drossel):** `~/.local/state/vibe/heartbeat-state.json`
- **Voraussetzung:** `gh` CLI eingerichtet und angemeldet (Issue #38) und ein
  Klon des Handshake-Repos unter `~/Handshake` (oder `~/handshake`).

## Regeln (konfigurierbar)

| Situation | Ping nach | Standard |
|---|---|---|
| Offener PR ohne Abschluss (Review/Merge haengt) | `prReviewHours` | 24 h |
| Offenes Issue mit Label `agent:vibe` oder `agent:both` | `issueHours` | 12 h |
| Offene Uebergabe ohne Quittung (Quittungs-Check) | nur Log (Info) | – |
| Drossel | `maxPings`, danach still | 3 |

`dryRun: true` (Standard) loggt nur und postet nichts – erst nach dem Test
auf `false` setzen.

## Installation auf dem Keller (Claude Code lokal mit Martin, Freigabe je Schritt)

1. Repo nach `~/gemeinsame-workflows` klonen (Benutzer `vibe`).
2. `mkdir -p ~/.config/vibe && cp heartbeat/heartbeat-config.beispiel.json ~/.config/vibe/heartbeat-config.json`
3. Testlauf: `bash ~/gemeinsame-workflows/heartbeat/heartbeat.sh && tail -20 ~/.local/state/vibe/heartbeat.log`
   (Standard `dryRun: true` – es wird nur geloggt.)
4. Timer einrichten (als martin, mit sudo):
   `sudo install -m 644 heartbeat/systemd/vibe-heartbeat.{service,timer} /etc/systemd/system/`
   `sudo systemctl daemon-reload && sudo systemctl enable --now vibe-heartbeat.timer`
5. Pruefen: `systemctl list-timers | grep heartbeat`; nach einer Stunde
   `tail -20 ~/.local/state/vibe/heartbeat.log`.
6. Erst nach ein paar guten Testlaeufen `dryRun` auf `false` setzen
   (dann pingt der Herzschlag wirklich als GitHub-Kommentar).

## Grenzen (offen gesagt)

- Der Herzschlag sieht nur GitHub (PRs, Issues, Quittungen). Was nur lokal
  liegt (z. B. ungepushte Branches), sieht er nicht.
- Er weckt noch keine Sitzung: Bis der Bote (M4) steht, stoesst weiterhin
  Martin an; der Ping zeigt nur, *was* ansteht.
- Kein Token im Skript; es nutzt die bestehende gh-Anmeldung des Benutzers
  `vibe`. Verarbeitet werden nur Repo-Namen, Nummern, Titel und Zeitstempel.
