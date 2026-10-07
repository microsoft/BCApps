param([hashtable]$Parameters)
$ErrorActionPreference = 'Stop'
if ($env:GITHUB_REPOSITORY -ne 'microsoft/BCApps' -or
    $env:GITHUB_REF -ne 'refs/heads/features/646383-sql-api-worker-warmup-comparison' -or
    $env:BC_SQL_API_EXPERIMENT -notin @('control', 'workerwarmup', 'navreadiness') -or
    $env:GITHUB_EVENT_NAME -ne 'workflow_dispatch' -or $env:GITHUB_RUN_ATTEMPT -ne '1' -or
    $env:BC_SQL_PILOT_ARM -ne 'control' -or -not $env:BC_SQL_PILOT_OUTPUT -or
    $env:BC_SQL_PILOT_COUNTRY -notin @('W1', 'DE') -or $env:BC_SQL_PILOT_TRIAL -notmatch '^[1-5]$' -or
    $env:GITHUB_RUN_ID -notmatch '^\d{1,20}$') {
    throw 'Refusing SQL pilot outside its disposable manually dispatched CI job.'
}
$expectedName = "bcbuildprojectsTestApps$($env:BC_SQL_PILOT_COUNTRY)Trial$($env:BC_SQL_PILOT_TRIAL)$($env:BC_SQL_API_EXPERIMENT)$($env:GITHUB_RUN_ID)"
if ($Parameters.ContainerName -ne $expectedName -or (Test-BcContainer -containerName $expectedName)) {
    throw 'Pilot container name is unexpected or already exists. No replacement is authorized.'
}
if ($Parameters.memoryLimit -ne '16G' -or -not $Parameters.multitenant) { throw 'Original 16G multitenant container configuration is required.' }
$module = Get-Module BcContainerHelper -ErrorAction Stop
$helperVersion = & $module { $bcContainerHelperVersion }
if ($helperVersion -ne '6.1.19-preview2811389') { throw "Wrong BCH version: $helperVersion" }
$settings = $env:Settings | ConvertFrom-Json
if ($settings.country -ne $env:BC_SQL_PILOT_COUNTRY -or $settings.testType -ne 'IntegrationTest' -or
    $settings.numberOfTenantsForTesting -ne 4 -or $settings.companyName -ne 'My Company' -or
    -not $settings.enableCleanTestCodeunitExecution -or $settings.enableTaskScheduler) {
    throw 'Effective country Integration settings differ from the predeclared experiment.'
}
if (-not (Get-Command New-BcContainer).Parameters.ContainsKey('useGenericImage')) {
    throw 'Exact BCH does not expose the supported generic-image parameter.'
}
$Parameters.useGenericImage = 'mcr.microsoft.com/businesscentral@sha256:c899d12093ad7bbdbfd08ccc0e6294e0f98c682c7e35db4ecfbca345fb068492'
if ($Parameters.platformArtifactUrl -ne 'https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/platform/30.0.55665.0/platform') {
    throw 'Platform artifact is not the pinned source platform.'
}
@{
    container = $expectedName; runId = $env:GITHUB_RUN_ID; arm = $env:BC_SQL_PILOT_ARM
    country = $env:BC_SQL_PILOT_COUNTRY; trial = $env:BC_SQL_PILOT_TRIAL
    experiment = $env:BC_SQL_API_EXPERIMENT
    helperVersion = $helperVersion; image = $Parameters.useGenericImage
    imageGenericTag = '1.0.2.128'; platform = '30.0.55665.0'
    hostOS = [Environment]::OSVersion.Version.ToString()
    registeredUtc = [DateTime]::UtcNow.ToString('o')
} | ConvertTo-Json | Set-Content (Join-Path $env:BC_SQL_PILOT_OUTPUT 'container-ownership.json') -Encoding UTF8
