# Herzschlag — heartbeat.ps1
# Praeft offene PRs und Issues in allen GitHub-Repos des Kontos und pingt bei Bedarf.
# Laeuft per Task Scheduler (Standard: 1h). Stille = alles gut.

[CmdletBinding()]
param(
    [switch]$now
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- Konfiguration

$configPath = Join-Path $HOME '.vibe\heartbeat-config.json'
$defaults = @{
    repos              = @()                # leer = alle Repos des Kontos
    prReviewHours      = 24                # PR wartet auf Review
    prFeedbackHours    = 12                # Review-Feedback unbeantwortet
    mergeStaleHours    = 2                 # PR approved aber unmerged (Merge-Stau)
    prApprovedHours    = 24                # Fallback: approved, kein Merge, sanfterer Ping
    issueTriagerHours  = 12                # Issue ohne Assignee
    blockedHours       = 48                # Issue mit Label 'blocked' ohne Update
    staleDays          = 7                 # ab hier nur noch weekly + stale-Label
    maxPings           = 3                 # danach stale, kein Ping mehr
    dryRun             = $true             # true = nur loggen, nichts posten
    logPath            = (Join-Path $HOME '.vibe\heartbeat.log')
    pingMarker         = '<!-- heartbeat-ping -->'
    staleLabel         = 'stale'
}

$config = $defaults
if (Test-Path $configPath) {
    $userCfg = Get-Content $configPath -Raw | ConvertFrom-Json
    foreach ($prop in $userCfg.PSObject.Properties) {
        $config[$prop.Name] = $prop.Value
    }
}

function Write-Log([string]$msg) {
    $line = "{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    Add-Content -Path $config.logPath -Value $line
}

function Get-RepoList() {
    if ($config.repos -and $config.repos.Count -gt 0) { return $config.repos }
    $out = gh repo list --limit 200 --json nameWithOwner | ConvertFrom-Json
    return $out | ForEach-Object { $_.nameWithOwner }
}

function Get-PingCount([string]$repo, [string]$number, [string]$kind) {
    # Zaehlt eigene Herzschlag-Kommentare (via Suche auf Comment-Autor 'app' / eigener Login)
    $login = gh api user --jq .login 2>$null
    if (-not $login) { return 0 }
    $q = "repo:$repo $kind:$number commenter:$login `"$($config.pingMarker)`""
    $json = gh api -X GET search/issues -f q=$q -f per_page=100 --jq .total_count 2>$null
    if ($json -match '^\d+$') { return [int]$json }
    return 0
}

function Send-Ping([string]$repo, [string]$number, [string]$kind, [string]$message) {
    $count = Get-PingCount $repo $number $kind
    if ($count -ge $config.maxPings) {
        if (-not $config.dryRun) {
            gh issue edit $number --repo $repo --add-label $config.staleLabel 2>$null | Out-Null
        }
        Write-Log "ESKALATION: $repo#$number nach $count Pings als '$($config.staleLabel)' markiert (kein weiterer Ping)."
        return
    }
    $body = "$($config.pingMarker)`n$message"
    if ($config.dryRun) {
        Write-Log "DRY-RUN (wuerde pingen): $repo#$number — $message"
    } else {
        gh issue comment $number --repo $repo --body $body | Out-Null
        Write-Log "PING: $repo#$number — $message"
    }
}

# ---------------------------------------------------------------- Herzschlag

Write-Log "=== Herzschlag start (dryRun=$($config.dryRun)) ==="

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Log "FEHLER: gh CLI nicht gefunden. Installation noetig."
    exit 1
}

$nowUtc = [DateTime]::UtcNow
$repos = Get-RepoList
$pings = 0
$checked = 0
$statusItems = @()

foreach ($repo in $repos) {
    # ---- Pull Requests
    $prs = gh pr list --repo $repo --state open --json number,title,updatedAt,reviewDecision,labels | ConvertFrom-Json
    foreach ($pr in $prs) {
        $checked++
        $ageH = ($nowUtc - [DateTime]::Parse($pr.updatedAt).ToUniversalTime()).TotalHours

        if ($pr.reviewDecision -eq 'APPROVED') {
            # Merge-Stau: freigegeben (Approve) aber unmerged — beim naechsten Schlag melden
            if ($ageH -ge $config.prApprovedHours) {
                Send-Ping $repo $pr.number 'pr' ("Herzschlag: PR #$($pr.number) ist seit $([math]::Round($ageH,1)) h freigegeben (approved) und wartet auf Merge (Web-UI).")
                $statusItems += [ordered]@{ type='pr'; kind='wartet-auf-merge'; repo=$repo; number=$pr.number; title=$pr.title; ageHours=[math]::Round($ageH,1) }
                $pings++
                continue
            }
            if ($ageH -ge $config.mergeStaleHours) {
                Send-Ping $repo $pr.number 'pr' ("Herzschlag: PR #$($pr.number) ist freigegeben und wartet seit $([math]::Round($ageH,1)) h auf Merge (Web-UI).")
                $statusItems += [ordered]@{ type='pr'; kind='wartet-auf-merge'; repo=$repo; number=$pr.number; title=$pr.title; ageHours=[math]::Round($ageH,1) }
                $pings++
                continue
            }
        }
        if ($pr.reviewDecision -eq 'REVIEW_REQUIRED' -and $ageH -ge $config.prReviewHours) {
            Send-Ping $repo $pr.number 'pr' ("Herzschlag: PR #$($pr.number) ($($pr.title)) wartet seit $([math]::Round($ageH,1)) h auf Review.")
            $statusItems += [ordered]@{ type='pr'; kind='wartet-auf-review'; repo=$repo; number=$pr.number; title=$pr.title; ageHours=[math]::Round($ageH,1) }
            $pings++
            continue
        }
        if ($pr.reviewDecision -eq 'CHANGES_REQUESTED' -and $ageH -ge $config.prFeedbackHours) {
            Send-Ping $repo $pr.number 'pr' ("Herzschlag: Review-Feedback an PR #$($pr.number) ist seit $([math]::Round($ageH,1)) h unbeantwortet.")
            $statusItems += [ordered]@{ type='pr'; kind='feedback-unbeantwortet'; repo=$repo; number=$pr.number; title=$pr.title; ageHours=[math]::Round($ageH,1) }
            $pings++
            continue
        }
        if ($ageH -ge ($config.staleDays * 24) -and -not ($pr.labels | Where-Object { $_.name -eq $config.staleLabel })) {
            Send-Ping $repo $pr.number 'pr' ("Herzschlag: PR #$($pr.number) ist seit $([math]::Round($ageH / 24,1)) Tagen inaktiv.")
            $statusItems += [ordered]@{ type='pr'; kind='stale'; repo=$repo; number=$pr.number; title=$pr.title; ageHours=[math]::Round($ageH,1) }
            $pings++
        }
    }

    # ---- Issues
    $issues = gh issue list --repo $repo --state open --json number,title,updatedAt,assignees,labels | ConvertFrom-Json
    foreach ($issue in $issues) {
        $checked++
        $ageH = ($nowUtc - [DateTime]::Parse($issue.updatedAt).ToUniversalTime()).TotalHours
        $isStale = $issue.labels | Where-Object { $_.name -eq $config.staleLabel }
        $isBlocked = $issue.labels | Where-Object { $_.name -eq 'blocked' }

        if ($isBlocked -and $ageH -ge $config.blockedHours -and -not $isStale) {
            Send-Ping $repo $issue.number 'issue' ("Herzschlag: Issue #$($issue.number) ($($issue.title)) ist blockiert und seit $([math]::Round($ageH,1)) h unbearbeitet.")
            $statusItems += [ordered]@{ type='issue'; kind='blockiert'; repo=$repo; number=$issue.number; title=$issue.title; ageHours=[math]::Round($ageH,1) }
            $pings++
            continue
        }
        if (-not $issue.assignees -and $ageH -ge $config.issueTriagerHours -and -not $isStale) {
            Send-Ping $repo $issue.number 'issue' ("Herzschlag: Issue #$($issue.number) ist seit $([math]::Round($ageH,1)) h untriaged (kein Assignee).")
            $statusItems += [ordered]@{ type='issue'; kind='untriaged'; repo=$repo; number=$issue.number; title=$issue.title; ageHours=[math]::Round($ageH,1) }
            $pings++
            continue
        }
        if ($ageH -ge ($config.staleDays * 24) -and -not $isStale) {
            Send-Ping $repo $issue.number 'issue' ("Herzschlag: Issue #$($issue.number) ist seit $([math]::Round($ageH / 24,1)) Tagen inaktiv.")
            $statusItems += [ordered]@{ type='issue'; kind='stale'; repo=$repo; number=$issue.number; title=$issue.title; ageHours=[math]::Round($ageH,1) }
            $pings++
        }
    }
}

Write-Log "=== Herzschlag fertig: $checked PRs/Issues geprueft, $pings Regel-Treffer ==="

# ------------------------------------------------------- Status-JSON fuer die Tafel (cockpit-tafel.html)

$status = [ordered]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    checked     = $checked
    pings       = $pings
    items       = $statusItems
}
$statusJson = $status | ConvertTo-Json -Depth 5
Set-Content -Path (Join-Path $HOME '.vibe\heartbeat-status.json') -Value $statusJson -Encoding ascii
Write-Log "Status-JSON aktualisiert: $HOME\.vibe\heartbeat-status.json"
