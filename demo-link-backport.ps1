<#
.SYNOPSIS
    Demo script: simulates the link-backport-workitems workflow locally.
    Runs all parsing/resolve steps and optionally creates the ADO parent-child link.

.PARAMETER ReleasePR
    The release branch PR number (e.g., 7734)

.PARAMETER DryRun
    If set, skips the actual ADO API call and just shows what would happen.

.EXAMPLE
    .\demo-link-backport.ps1 -ReleasePR 7734 -DryRun
    .\demo-link-backport.ps1 -ReleasePR 7734
#>
param(
    [Parameter(Mandatory)]
    [int]$ReleasePR,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$repo = "microsoft/BCApps"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Backport Work Item Linker — Demo" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ── STEP 1: Fetch release PR and extract AB# + linked reference ──
Write-Host "[Step 1] Fetching PR #$ReleasePR description..." -ForegroundColor Yellow
$prBody = gh pr view $ReleasePR --repo $repo --json body --jq ".body"
if (-not $prBody) {
    Write-Host "  ERROR: Could not fetch PR #$ReleasePR" -ForegroundColor Red
    exit 1
}

$preview = if ($prBody.Length -gt 200) { $prBody.Substring(0, 200) + "..." } else { $prBody }
Write-Host "  PR Body (preview):`n  $preview" -ForegroundColor Gray

# Extract RELEASE_WI (AB#)
$releaseWIMatch = [regex]::Match($prBody, 'AB#(\d+)')
if (-not $releaseWIMatch.Success) {
    Write-Host "  ERROR: No AB# found in PR #$ReleasePR" -ForegroundColor Red
    exit 1
}
$releaseWI = $releaseWIMatch.Groups[1].Value
Write-Host "  RELEASE_WI = $releaseWI" -ForegroundColor Green

# Extract linked issue/PR reference (backport pattern or Fixes #)
$origRef = $null
$backportMatch = [regex]::Match($prBody, '(?i)backports?\s+(of\s+)?#(\d+)')
if ($backportMatch.Success) {
    $origRef = $backportMatch.Groups[2].Value
    Write-Host "  ORIG_REF = $origRef (from backport pattern)" -ForegroundColor Green
}
else {
    $fixesMatch = [regex]::Match($prBody, '(?i)(fix|fixes|fixed|close|closes|closed|resolve|resolves|resolved)\s+#(\d+)')
    if ($fixesMatch.Success) {
        $origRef = $fixesMatch.Groups[2].Value
        Write-Host "  ORIG_REF = $origRef (from Fixes # pattern)" -ForegroundColor Green
    }
}

if (-not $origRef) {
    Write-Host "  ERROR: No backport or issue reference found" -ForegroundColor Red
    exit 1
}

# ── STEP 2: Resolve master work item via timeline ──
Write-Host "`n[Step 2] Resolving master work item from #$origRef..." -ForegroundColor Yellow

# Try as PR first
$masterWI = $null
$origBody = gh pr view $origRef --repo $repo --json body --jq ".body" 2>$null
if ($origBody) {
    $match = [regex]::Match($origBody, 'AB#(\d+)')
    if ($match.Success) {
        $masterWI = $match.Groups[1].Value
        Write-Host "  Found AB#$masterWI directly on PR #$origRef" -ForegroundColor Green
    }
}

# If no AB# found, search timeline for linked PRs
if (-not $masterWI) {
    Write-Host "  No AB# on #$origRef directly. Searching issue timeline..." -ForegroundColor Gray
    $timelineRaw = gh api "/repos/$repo/issues/$origRef/timeline" --paginate -p "mockingbird" 2>$null
    $timelineJson = $timelineRaw | ConvertFrom-Json
    $candidatePRs = $timelineJson | Where-Object { $_.event -eq "cross-referenced" -and $_.source.issue.pull_request } | ForEach-Object { $_.source.issue.number } | Sort-Object -Unique
    if ($candidatePRs) {
        Write-Host "  Found cross-referenced PRs: $($candidatePRs -join ', ')" -ForegroundColor Gray

        foreach ($prNum in $candidatePRs) {
            Write-Host "  Checking PR #$prNum..." -ForegroundColor Gray
            $candidateBody = gh pr view $prNum --repo $repo --json body --jq ".body" 2>$null
            if ($candidateBody) {
                $match = [regex]::Match($candidateBody, 'AB#(\d+)')
                if ($match.Success -and $match.Groups[1].Value -ne $releaseWI) {
                    $masterWI = $match.Groups[1].Value
                    Write-Host "  Found AB#$masterWI on PR #$prNum" -ForegroundColor Green
                    break
                }
            }
        }
    }
}

if (-not $masterWI) {
    Write-Host "  ERROR: Could not resolve master work item" -ForegroundColor Red
    exit 1
}

if ($masterWI -eq $releaseWI) {
    Write-Host "  ERROR: Master and release work items are the same ($masterWI). Aborting." -ForegroundColor Red
    exit 1
}

# ── STEP 3: Summary and link ──
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " RESULT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Release PR:     #$ReleasePR" -ForegroundColor White
Write-Host "  Release WI:     AB#$releaseWI (child)" -ForegroundColor White
Write-Host "  Master WI:      AB#$masterWI (parent)" -ForegroundColor White
Write-Host "  ADO Link:       $releaseWI -> $masterWI (Parent-Child)" -ForegroundColor White
Write-Host "  ADO Child URL:  https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_workitems/edit/$releaseWI" -ForegroundColor Gray
Write-Host "  ADO Parent URL: https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_workitems/edit/$masterWI" -ForegroundColor Gray

if ($DryRun) {
    Write-Host "`n  [DRY RUN] Would call ADO REST API:" -ForegroundColor Yellow
    Write-Host "  PATCH https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_apis/wit/workitems/$releaseWI`?api-version=7.1" -ForegroundColor Yellow
    Write-Host '  Body: [{"op":"add","path":"/relations/-","value":{"rel":"System.LinkTypes.Hierarchy-Reverse","url":"https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_apis/wit/workItems/' + $masterWI + '"}}]' -ForegroundColor Yellow
    Write-Host "`n  Rerun without -DryRun to create the link." -ForegroundColor Gray
}
else {
    $pat = Read-Host "Enter ADO PAT (or press Enter to skip)"
    if (-not $pat) {
        Write-Host "  Skipped ADO API call." -ForegroundColor Yellow
    }
    else {
        $authHeader = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
        $adoBase = "https://dev.azure.com/dynamicssmb2/Dynamics%20SMB"

        # Check existing relations for idempotency
        $existingRels = Invoke-RestMethod -Uri "$adoBase/_apis/wit/workitems/$releaseWI`?`$expand=relations&api-version=7.1" `
            -Headers @{ Authorization = "Basic $authHeader" }

        $parentUrl = "$adoBase/_apis/wit/workItems/$masterWI"
        $alreadyLinked = $existingRels.relations | Where-Object { $_.rel -eq "System.LinkTypes.Hierarchy-Reverse" -and $_.url -eq $parentUrl }

        if ($alreadyLinked) {
            Write-Host "`n  Parent link already exists. Nothing to do." -ForegroundColor Yellow
        }
        else {
            $patchArray = @(
                @{
                    op    = "add"
                    path  = "/relations/-"
                    value = @{
                        rel        = "System.LinkTypes.Hierarchy-Reverse"
                        url        = $parentUrl
                        attributes = @{ comment = "Auto-linked by demo script: release #$releaseWI -> master #$masterWI" }
                    }
                }
            )
            # Force array serialization even for single element
            $patchBody = "[$( ($patchArray | ForEach-Object { $_ | ConvertTo-Json -Depth 5 -Compress }) -join ',' )]"

            $response = Invoke-RestMethod -Uri "$adoBase/_apis/wit/workitems/$releaseWI`?api-version=7.1" `
                -Method Patch `
                -Headers @{ Authorization = "Basic $authHeader" } `
                -ContentType "application/json-patch+json" `
                -Body ([System.Text.Encoding]::UTF8.GetBytes($patchBody))

            Write-Host "`n  LINKED! ADO #$releaseWI is now a child of #$masterWI" -ForegroundColor Green
        }
    }
}

Write-Host ""
