param([Parameter(Mandatory)][string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1') -Force
Assert-ExpandedApiDispatch
$null = New-Item -ItemType Directory -Path $OutputDirectory -Force
$plan = Get-ExpandedApiPlan -InventoryPath (Join-Path $PSScriptRoot 'routing-inventory.json')
$plan | ConvertTo-Json -Depth 30 | Set-Content (Join-Path $OutputDirectory 'plan.json') -Encoding utf8
$matrix = @{ include = @($plan.cells | ForEach-Object {
    @{ country = $_.country; config = $_.configuration.id; lanes = @($_.lanes.id) }
}) }
"matrix=$($matrix | ConvertTo-Json -Depth 8 -Compress)" | Add-Content $env:GITHUB_OUTPUT
