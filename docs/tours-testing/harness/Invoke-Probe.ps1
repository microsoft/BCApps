<#
    Runs one probe with a SQL snapshot either side, and prints the delta.
    The delta is the evidence; the screen is only a hint.

    ⚠️ Snapshot IDENTITIES, not counts (tours §5.5). A count delta cannot tell correct
    behaviour from a defect: "one fewer supply record than before" looks identical whether
    the run rightly declined to create one or destroyed an existing one. So -Query must
    select primary keys, statuses and key dates, and rows are compared by identity: this
    script reports which rows APPEARED, DISAPPEARED and CHANGED - never how many there are.

    The container is taken from $env:BC_CREDS so the snapshots, the browser and the
    oracle all address the same container - see the parallel-tours note in README.md.

    .EXAMPLE
    # Name the records the probe is allowed to touch, then run it.
    .\Invoke-Probe.ps1 -Script .\fa.js -ProbeId post-disposal -KeyColumn Id -Query @'
    SELECT [Entry No_] AS Id, [FA No_], [FA Posting Type], [Amount]
    FROM   [CRONUS International Ltd_$FA Ledger Entry$<guid>]
    '@

    .EXAMPLE
    # No browser step - capture before/after around something done by hand.
    .\Invoke-Probe.ps1 -QueryFile .\oracle.sql -KeyColumn Id -Manual
#>
param(
    # The oracle. Select identities, not COUNT(*).
    [Parameter(Mandatory, ParameterSetName = 'Inline')][string] $Query,
    [Parameter(Mandatory, ParameterSetName = 'File')][string]   $QueryFile,

    # Column holding the row identity. Used to diff before/after by name.
    [string] $KeyColumn = 'Id',

    # The probe to run between the snapshots: node <Script> <ProbeId>.
    [string] $Script,
    [string] $ProbeId,

    # Take the two snapshots around a manual action instead of a script.
    [switch] $Manual,

    [string] $ContainerName
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $ContainerName) {
    if (-not $env:BC_CREDS) {
        throw 'Pass -ContainerName, or set $env:BC_CREDS to this tour''s credentials json.'
    }
    $ContainerName = (Get-Content $env:BC_CREDS -Raw | ConvertFrom-Json).containerName
}

if ($QueryFile) { $Query = Get-Content $QueryFile -Raw }

function Get-Snapshot {
    $rows = & (Join-Path $here 'Invoke-BcSql.ps1') -Query $Query -ContainerName $ContainerName
    $map = [ordered]@{}
    foreach ($r in $rows) {
        if ($null -eq $r) { continue }
        if (-not $r.PSObject.Properties[$KeyColumn]) {
            throw "-KeyColumn '$KeyColumn' is not in the result set. Columns: " +
                  (($r.PSObject.Properties.Name) -join ', ')
        }
        $map["$($r.$KeyColumn)"] = (($r.PSObject.Properties |
            Where-Object Name -ne $KeyColumn |
            ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '; ')
    }
    return $map
}

$before = Get-Snapshot
Write-Host "before: $($before.Count) row(s)" -ForegroundColor DarkGray

$nodeOut = ''
$exit = $null
if ($Manual) {
    Read-Host 'Perform the action now, then press Enter to take the AFTER snapshot' | Out-Null
} elseif ($Script) {
    Push-Location $here
    try {
        $nodeOut = & node $Script $ProbeId 2>&1
        $exit = $LASTEXITCODE
    } finally { Pop-Location }
} else {
    throw 'Pass -Script (with -ProbeId), or -Manual.'
}

$after = Get-Snapshot
Write-Host "after:  $($after.Count) row(s)" -ForegroundColor DarkGray

$appeared    = @($after.Keys  | Where-Object { -not $before.Contains($_) })
$disappeared = @($before.Keys | Where-Object { -not $after.Contains($_) })
$changed     = @($after.Keys  | Where-Object { $before.Contains($_) -and $before[$_] -ne $after[$_] })

if ($nodeOut) { Write-Host "`n--- probe output ---`n$(($nodeOut | Out-String).Trim())" }

Write-Host "`n--- delta by identity ---" -ForegroundColor Cyan
if (-not ($appeared.Count -or $disappeared.Count -or $changed.Count)) {
    Write-Host 'NOTHING CHANGED.' -ForegroundColor Yellow
    Write-Host 'An absence is not a result until a control has produced a presence (tours §5.3, §5.7).'
}
foreach ($k in $disappeared) { Write-Host "GONE      $k  ($($before[$k]))" -ForegroundColor Red }
foreach ($k in $appeared)    { Write-Host "NEW       $k  ($($after[$k]))"  -ForegroundColor Green }
foreach ($k in $changed)     { Write-Host "CHANGED   $k`n          was ($($before[$k]))`n          now ($($after[$k]))" -ForegroundColor Yellow }

[pscustomobject]@{
    Container   = $ContainerName
    Probe       = if ($Manual) { '(manual)' } else { "$Script $ProbeId" }
    NodeExit    = $exit
    Appeared    = $appeared
    Disappeared = $disappeared
    Changed     = $changed
}
