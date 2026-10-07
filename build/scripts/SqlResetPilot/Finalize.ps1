$ErrorActionPreference = 'Stop'
$output = Join-Path $env:GITHUB_WORKSPACE 'sql-reset-pilot-output'
$ownershipPath = Join-Path $output 'container-ownership.json'
if (-not (Test-Path $ownershipPath)) {
    Write-Host 'No owned container was registered; no container deletion is authorized.'
    return
}
$ownership = Get-Content $ownershipPath -Raw | ConvertFrom-Json
if ($ownership.runId -ne $env:GITHUB_RUN_ID -or $ownership.arm -ne $env:BC_SQL_PILOT_ARM -or
    $ownership.container -ne "bcbuildprojectsTestAppsW1$($env:GITHUB_RUN_ID)") {
    throw 'Cleanup ownership mismatch.'
}
Import-Module (Join-Path (Split-Path $env:BcContainerHelperPath -Parent) 'BcContainerHelper.psm1') -ErrorAction Stop
try {
    if (Test-BcContainer -containerName $ownership.container) {
        $events = Get-BcContainerEventLog -containerName $ownership.container -doNotOpen
        Copy-Item $events (Join-Path $output 'final-container.evtx')
    }
    $project = Join-Path $env:GITHUB_WORKSPACE 'build\projects\Test Apps W1'
    Get-ChildItem $project -Filter 'TestResults*.xml' -File | Copy-Item -Destination $output
} finally {
    if (Test-BcContainer -containerName $ownership.container) {
        Remove-BcContainer -containerName $ownership.container
    }
    @{ completedUtc = [DateTime]::UtcNow.ToString('o'); containerRemaining = (Test-BcContainer -containerName $ownership.container) } |
        ConvertTo-Json | Set-Content (Join-Path $output 'cleanup.json') -Encoding UTF8
}
if (Test-BcContainer -containerName $ownership.container) { throw 'Owned container teardown did not complete.' }
