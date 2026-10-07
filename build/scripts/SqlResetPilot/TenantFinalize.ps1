$ErrorActionPreference = 'Stop'
$output = Join-Path $env:GITHUB_WORKSPACE 'sql-reset-pilot-output'
$ownershipPath = Join-Path $output 'container-ownership.json'
if (-not (Test-Path $ownershipPath)) {
    Write-Output 'No owned container was registered; no container deletion is authorized.'
    return
}
$ownership = Get-Content $ownershipPath -Raw | ConvertFrom-Json
Import-Module (Join-Path $PSScriptRoot 'TenantCount.psm1') -Force
if (-not (Test-SqlTenantExperiment) -or $ownership.tenantCount -ne [int]$env:BC_SQL_TENANT_COUNT) {
    throw 'Cleanup tenant-count identity mismatch.'
}
if ($ownership.runId -ne $env:GITHUB_RUN_ID -or $ownership.arm -ne $env:BC_SQL_PILOT_ARM -or
    $env:BC_SQL_API_EXPERIMENT -notin @('control', 'warmup', 'retry') -or $ownership.experiment -ne $env:BC_SQL_API_EXPERIMENT -or
    $env:BC_SQL_PILOT_COUNTRY -notin @('W1', 'DE') -or $env:BC_SQL_PILOT_TRIAL -notmatch '^(?:[1-9]|[1-4][0-9]|50)$' -or
    $ownership.country -ne $env:BC_SQL_PILOT_COUNTRY -or $ownership.trial -ne $env:BC_SQL_PILOT_TRIAL -or
    $ownership.container -ne (Get-SqlTenantContainerName)) {
    throw 'Cleanup ownership mismatch.'
}
Import-Module (Join-Path (Split-Path $env:BcContainerHelperPath -Parent) 'BcContainerHelper.psm1') -ErrorAction Stop
try {
    if (Test-BcContainer -containerName $ownership.container) {
        $events = Get-BcContainerEventLog -containerName $ownership.container -doNotOpen
        Copy-Item $events (Join-Path $output 'final-container.evtx')
    }
    $project = Join-Path $env:GITHUB_WORKSPACE "build\projects\Test Apps $($env:BC_SQL_PILOT_COUNTRY) Trial$($env:BC_SQL_PILOT_TRIAL)t$($env:BC_SQL_TENANT_COUNT)"
    $resultLocations = @{
        'project-root' = $project
        'buildartifacts' = Join-Path $project '.buildartifacts'
    }
    foreach ($label in $resultLocations.Keys) {
        if (Test-Path $resultLocations[$label]) {
            $destination = Join-Path $output "clean-results\$label"
            New-Item -ItemType Directory -Path $destination -Force | Out-Null
            Get-ChildItem $resultLocations[$label] -Filter 'TestResults*.xml' -File |
                Copy-Item -Destination $destination
        }
    }
} finally {
    if (Test-BcContainer -containerName $ownership.container) {
        Remove-BcContainer -containerName $ownership.container
    }
    @{ completedUtc = [DateTime]::UtcNow.ToString('o'); containerRemaining = (Test-BcContainer -containerName $ownership.container) } |
        ConvertTo-Json | Set-Content (Join-Path $output 'cleanup.json') -Encoding UTF8
}
if (Test-BcContainer -containerName $ownership.container) { throw 'Owned container teardown did not complete.' }
