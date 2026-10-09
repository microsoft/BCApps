$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'PlatformUptake.psm1') -Force
Assert-SqlPlatformUptakeContext
$pin = Get-SqlPlatformUptake
git merge-base --is-ancestor $pin.comparisonBase HEAD
if ($LASTEXITCODE -ne 0) { throw 'Original comparison commit must remain an ancestor.' }
git diff --exit-code $pin.applicationSource HEAD -- src
if ($LASTEXITCODE -ne 0) { throw 'Application source differs from compiled PR2.' }
if ((Get-Content (Join-Path $PSScriptRoot '..\..\Packages.json') -Raw | ConvertFrom-Json).BCPlatform.Version -ne $pin.runtime) {
    throw 'BCPlatform.Version differs from the published fixed runtime.'
}
$directory = Join-Path $env:GITHUB_WORKSPACE '.sql-api-comparison-plan'
$null = New-Item -ItemType Directory -Path $directory -Force
$proof = @()
foreach ($country in @('W1', 'DE')) {
    $proof += @(Save-SqlPlatformUptakeSnapshot -Country $country -Directory (Join-Path $directory $country))
}
$cells = @(Get-SqlPlatformUptakeCell)
@{
    provenance = $pin; run = $env:GITHUB_RUN_ID; head = $env:GITHUB_SHA
    createdUtc = [datetime]::UtcNow.ToString('o'); cells = $cells
    originalCellCount = 10; globalContainerLimit = 2; batchCount = 5; cellsPerOriginalBatch = 2
    outcomePolicy = 'Original first attempts only. Incomplete, skipped, cancelled and communication-invalid trials are never passes. No replacements or reruns.'
} | ConvertTo-Json -Depth 15 | Set-Content (Join-Path $directory 'matrix-manifest.json') -Encoding utf8
ConvertTo-Json -InputObject $proof -Depth 12 | Set-Content (Join-Path $directory 'artifact-proof.json') -Encoding utf8
foreach ($batch in 1..5) {
    $matrix = @{ include = @($cells | Select-Object -Skip (($batch - 1) * 2) -First 2) } | ConvertTo-Json -Depth 6 -Compress
    "batch$($batch.ToString('00'))=$matrix" | Add-Content $env:GITHUB_OUTPUT
}
Write-Output 'Validated ten original control cells in five sequential W1/DE pairs; maximum two containers.'
