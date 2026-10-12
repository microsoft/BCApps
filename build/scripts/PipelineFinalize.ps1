$ErrorActionPreference = 'Stop'

# This hook is success-only. Failures/cancellation rely on normal container teardown,
# not guaranteed after runner loss. CI credentials are per-run; other callers may differ.
if (-not $env:BCAppsApiTestPasswordPath) {
    return
}

Write-Host 'API test credential cleanup (PipelineFinalize).'
& (Join-Path $PSScriptRoot 'Remove-ApiTestPassword.ps1') `
    -ContainerName $env:BCAppsApiTestPasswordContainer -FilePath $env:BCAppsApiTestPasswordPath
$env:BCAppsApiTestPasswordPath = $null
$env:BCAppsApiTestPasswordContainer = $null
