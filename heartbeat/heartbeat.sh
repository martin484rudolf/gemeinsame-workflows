#!/usr/bin/env bash
# Herzschlag (heartbeat.sh) – Debian-Ausgabe fuer den Keller (Benutzer: vibe).
# Praeft offene PRs und Issues in den Koppel-Repos und pingt bei Bedarf.
# Laeuft per systemd-Timer (Standard: 1h). Still = alles gut.
# Konfiguration: ~/.config/vibe/heartbeat-config.json
# Log: ~/.local/state/vibe/heartbeat.log   Zustand: .../heartbeat-state.json
set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/vibe/heartbeat-config.json"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/vibe"
STATE="$STATE_DIR/heartbeat-state.json"
LOG="$STATE_DIR/heartbeat.log"

mkdir -p "$STATE_DIR"; touch "$LOG"
export HB_CONFIG="$CONFIG" HB_STATE="$STATE" HB_MARKER='<!-- heartbeat-ping -->'

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"; }

# --- 1) Quittungs-Check im Handshake-Klon (Info, kein Ping)
for HS in "$HOME/Handshake" "$HOME/handshake" "/srv/vibe/Handshake"; do
  if [ -x "$HS/scripts/quittungs-check.sh" ]; then
    if OUT=$(bash "$HS/scripts/quittungs-check.sh" 2>/dev/null); then
      OFFEN=$(printf '%s\n' "$OUT" | grep -c '^  - ' || true)
      if [ "$OFFEN" -gt 0 ]; then
        log "Quittungs-Check: $OFFEN offene Uebergabe(n) ohne Quittung:"
        printf '%s\n' "$OUT" | grep '^  - ' >> "$LOG" || true
      else
        log "Beat ok (Quittungs-Check: alles quittiert)"
      fi
    else
      log "Quittungs-Check FEHLER, siehe Skript-Ausgabe im Log"
      printf '%s\n' "$OUT" >> "$LOG" || true
    fi
    break
  fi
done

# --- 2) Offene PRs und Issues je Repo (Regeln, Ping mit Drossel)
python3 - >> "$LOG" <<'PY'
import json, os, subprocess
from datetime import datetime, timezone

cfg = {"repos": ["martin484rudolf/Handshake"], "prReviewHours": 24,
       "issueHours": 12, "maxPings": 3, "dryRun": True, "labels": ["agent:vibe", "agent:both"]}
p = os.environ.get("HB_CONFIG", "")
if p and os.path.exists(p):
    cfg.update(json.load(open(p, encoding="utf-8")))

state_p = os.environ.get("HB_STATE", "")
state = {}
if state_p and os.path.exists(state_p):
    state = json.load(open(state_p, encoding="utf-8"))
now = datetime.now(timezone.utc)
marker = os.environ.get("HB_MARKER", "<!-- heartbeat-ping -->")

def gh(*args):
    r = subprocess.run(["gh", *args], capture_output=True, text=True, timeout=60)
    return r.stdout if r.returncode == 0 else "[]"

def age_h(iso):
    try:
        return (now - datetime.fromisoformat(iso.replace("Z", "+00:00"))).total_seconds() / 3600
    except Exception:
        return 0

def marker_count(repo, kind, num):
    out = gh(kind, "view", str(num), "-R", repo, "--json", "comments", "-q",
             f"[.comments[].body] | map(select(contains(\"heartbeat-ping\"))) | length")
    try:
        return int(out.strip() or 0)
    except Exception:
        return 0

def ping(repo, kind, num, text):
    key = f"{repo}#{kind}{num}"
    st = state.setdefault(key, {"count": marker_count(repo, kind, num)})
    if st["count"] >= cfg["maxPings"]:
        print(f"  {key}: maxPings erreicht, Stille-Modus")
        return
    if cfg["dryRun"]:
        print(f"  DRYRUN wuerde pingen: {key}: {text}")
        return
    r = subprocess.run(["gh", kind, "comment", str(num), "-R", repo,
                        "--body", f"{text}\n{marker}"], capture_output=True, text=True, timeout=60)
    if r.returncode == 0:
        st["count"] += 1
        print(f"  PING {key}: {text}")
    else:
        print(f"  FEHLER beim Ping {key}: {r.stderr.strip()[:200]}")
    state[key] = st

for repo in cfg["repos"]:
    for pr in json.loads(gh("pr", "list", "-R", repo, "--state", "open",
                            "--limit", "50", "--json", "number,title,updatedAt")):
        h = age_h(pr.get("updatedAt", ""))
        if h >= cfg["prReviewHours"]:
            ping(repo, "pr", pr["number"],
                  f"Herzschlag: PR #{pr['number']} ({pr['title'][:60]}) ist seit {int(h)} h offen – bitte ansehen.")
    for label in cfg["labels"]:
        for iss in json.loads(gh("issue", "list", "-R", repo, "--state", "open",
                                 "--label", label, "--limit", "50",
                                 "--json", "number,title,updatedAt")):
            h = age_h(iss.get("updatedAt", ""))
            if h >= cfg["issueHours"]:
                ping(repo, "issue", iss["number"],
                      f"Herzschlag: Issue #{iss['number']} ({iss['title'][:60]}, {label}) ist seit {int(h)} h offen – bitte ansehen.")

if state_p:
    json.dump(state, open(state_p, "w", encoding="utf-8"))
PY

log "Beat beendet"
