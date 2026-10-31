# Herzschlag (Heartbeat)

Ein PowerShell-Skript für Windows, das regelmäßig prüft, ob in den GitHub-Repos etwas offen und liegen geblieben ist — wie ein Herzschlag im Kreis, damit nichts vergessen wird. Es läuft auf einem eigenen PC (z. B. Keller-PC) per Task Scheduler im Takt von 1 Stunde (oder kürzer), unabhängig von GitHub-Actions-Kontingenten und ohne Cron-Drift.

Der Herzschlag schlägt im Takt, aber er **pingt nur bei Bedarf**: Still = alles gut. Jeder Ping nennt genau eine konkrete nächste Handlung.

## Funktionsweise

```
Task Scheduler (Standard: alle 60 Minuten)
  └─ heartbeat.ps1
       ├─ gh pr list   (alle Repos, Zustand: offen)
       ├─ gh issue list (alle Repos, Zustand: offen)
       ├─ Regeln prüfen (siehe unten)
       │    ├─ Regel erfüllt → GitHub-Kommentar als Ping
       │    └─ nichts offen → STILLE, nur Logeintrag "Beat ok"
       └─ Log nach %USERPROFILE%\.vibe\heartbeat.log
```

## Regeln (dynamisch, konfigurierbar)

| Situation | Ping nach | Kommentar-Text (Platzhalter) |
|---|---|---|
| Offener PR, wartet auf Review, kein Feedback | `prReviewHours` (Standard 24 h) | `Herzschlag: PR #<nr> wartet seit <x> h auf Review.` |
| Offener PR mit unbeantwortetem Review-Kommentar | `prFeedbackHours` (Standard 12 h) | `Herzschlag: Review-Feedback an PR #<nr> ist seit <x> h unbeantwortet.` |
| Offene Issue ohne Assignee/Label | `issueTriagerHours` (Standard 12 h) | `Herzschlag: Issue #<nr> ist seit <x> h untriaged (kein Assignee).` |
| Issue mit Label `blocked`, kein Update | `blockedHours` (Standard 48 h) | `Herzschlag: Issue #<nr> ist blockiert und seit <x> h unbearbeitet.` |
| PR/Issue länger als `staleDays` inaktiv | 1× wöchentlich, Label `stale` | Drossel statt Dauer-Ping (Alarm-Fatigue vermeiden) |
| Nichts offen | — | Kein Ping, nur stiller Logeintrag |

Eskalation: Nach `maxPings` (Standard 3) Herzschlägen ohne Reaktion wird nur noch das `stale`-Label gesetzt und nicht weiter gepingt. Die Sache geht zurück ins Backlog statt endlos zu piepen.

## Installation auf dem Keller-PC

Voraussetzungen: Windows 10/11, `gh` CLI installiert, einmalig `gh auth login`.

### 1. Skript ablegen

```powershell
mkdir $HOME\.vibe -Force
# heartbeat.ps1 nach %USERPROFILE%\.vibe\heartbeat.ps1 kopieren
```

### 2. Konfiguration

Optional: `%USERPROFILE%\.vibe\heartbeat-config.json` anlegen, um Repos und Schwellwerte anzupassen (siehe Tabelle oben). Ohne Datei gelten die Standardwerte und alle Repos des Kontos.

### 3. Task Scheduler-Aufgabe anlegen

PowerShell als Administrator:

```powershell
$action  = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoProfile -File $env:USERPROFILE\.vibe\heartbeat.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
Register-ScheduledTask -TaskName "Herzschlag" -Action $action -Trigger $trigger -Description "Praeft offene PRs/Issues in allen GitHub-Repos und pingt bei Bedarf"
```

Für einen 30-Minuten-Takt: `-RepetitionInterval (New-TimeSpan -Minutes 30)`.

### 4. Testbetrieb (empfohlen)

Erste Tage nur loggen, nichts posten — in `heartbeat-config.json` `"dryRun": true` setzen. Das Skript schreibt dann, was es pingen würde, nur ins Log. Danach `"dryRun": false` und der Herzschlag wird scharf geschaltet.

### 5. Manueller Sofort-Check

```powershell
pwsh -NoProfile -File $HOME\.vibe\heartbeat.ps1 -now
```

## Sicherheit & Rahmen

- Das Skript liest GitHub-Zustände und schreibt ausschließlich Kommentare auf Issues/PRs im eigenen Konto. Es ändert keinen Code.
- Es speichert keine Token (nutzt die bestehende `gh`-Authentifizierung).
- Keine personenbezogenen Daten: Es verarbeitet nur Repo-Namen, PR-/Issue-Nummern und Zeitstempel.
- Pings sind öffentlich sichtbare Kommentare (bei privaten Repos nur für Repo-Mitglieder).
