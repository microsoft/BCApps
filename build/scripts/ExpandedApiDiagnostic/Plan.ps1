param([Parameter(Mandatory)][string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1') -Force
Assert-ExpandedApiDispatch
$null = New-Item -ItemType Directory -Path $OutputDirectory -Force
$plan = Get-ExpandedApiPlan -InventoryPath (Join-Path $PSScriptRoot 'routing-inventory.json')
$plan | ConvertTo-Json -Depth 30 | Set-Content (Join-Path $OutputDirectory 'plan.json') -Encoding utf8
if (-not $plan.executionReady) {
    throw 'DRAFT BLOCKED: plan preserved. Shared compiler and all-lane producer integration require review; no containers or test jobs are authorized by this workflow.'
}
