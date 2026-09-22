<#
    Runs one probe with a SQL snapshot either side, and prints the delta.
    The delta is the evidence; the screen is only a hint.

    The container is taken from $env:BC_CREDS so the snapshots, the browser and the
    oracle all address the same container - see the parallel-tours note in README.md.
#>
param(
    [Parameter(Mandatory)][string] $ProbeId,
    [string] $ContainerName
)

$ErrorActionPreference = 'Stop'

if (-not $ContainerName) {
    if (-not $env:BC_CREDS) {
        throw 'Pass -ContainerName, or set $env:BC_CREDS to this tour''s bc-credentials.json.'
    }
    $ContainerName = (Get-Content $env:BC_CREDS -Raw | ConvertFrom-Json).containerName
}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$snap = Join-Path $here 'Get-CustomerSnapshot.ps1'

$before = & $snap -ContainerName $ContainerName -Label "$ProbeId-before" 6>$null

Push-Location $here
$nodeOut = & node probes.js $ProbeId 2>&1
$exit = $LASTEXITCODE
Pop-Location

$after = & $snap -ContainerName $ContainerName -Label "$ProbeId-after" 6>$null

[pscustomobject]@{
    Probe            = $ProbeId
    Container        = $ContainerName
    NodeExit         = $exit
    NodeOutput       = ($nodeOut | Out-String).Trim()
    Customers        = "$($before.Customers) -> $($after.Customers)"
    dCustomers       = $after.Customers - $before.Customers
    BlankName        = "$($before.BlankName) -> $($after.BlankName)"
    dBlankName       = $after.BlankName - $before.BlankName
    CustLastNoUsed   = "'$($before.CustLastNoUsed)' -> '$($after.CustLastNoUsed)'"
    NoConsumed       = ($before.CustLastNoUsed -ne $after.CustLastNoUsed)
} | Format-List
