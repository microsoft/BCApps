<#
    Runs one Cancelled Bus probe with a SQL snapshot either side, and prints the delta.
    The delta is the evidence; the screen is only a hint.
#>
param(
    [Parameter(Mandatory)][string] $ProbeId,
    [string] $ContainerName = 'BCApps-Tours'
)

$ErrorActionPreference = 'Stop'
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
    NodeExit         = $exit
    NodeOutput       = ($nodeOut | Out-String).Trim()
    Customers        = "$($before.Customers) -> $($after.Customers)"
    dCustomers       = $after.Customers - $before.Customers
    BlankName        = "$($before.BlankName) -> $($after.BlankName)"
    dBlankName       = $after.BlankName - $before.BlankName
    CustLastNoUsed   = "'$($before.CustLastNoUsed)' -> '$($after.CustLastNoUsed)'"
    NoConsumed       = ($before.CustLastNoUsed -ne $after.CustLastNoUsed)
} | Format-List
