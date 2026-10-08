$ErrorActionPreference = 'Stop'
if ($env:GITHUB_REPOSITORY -ne 'microsoft/BCApps' -or
    $env:GITHUB_REF -ne 'refs/heads/features/646383-sql-api-tenant-count-comparison' -or
    $env:GITHUB_EVENT_NAME -ne 'workflow_dispatch' -or $env:GITHUB_RUN_ATTEMPT -ne '1' -or
    $env:GITHUB_RUN_ID -notmatch '^\d{1,20}$' -or $env:GITHUB_SHA -notmatch '^[0-9a-f]{40}$') {
    throw 'Only the exact original tenant-count diagnostic dispatch is permitted.'
}
Import-Module (Join-Path $PSScriptRoot 'TenantCount.psm1') -Force
$cells = @(Get-SqlTenantCell)
$directory = Join-Path $env:GITHUB_WORKSPACE '.sql-api-tenant-plan'
$null = New-Item -ItemType Directory -Path $directory -Force
$artifacts = @(
    @{ country = 'W1'; id = '11487493885'; digest = '09be1c12a5fe014fd2c1e0a6ab075e809f5693a9294dc8aa949c53961d1b50bd' }
    @{ country = 'DE'; id = '11486874993'; digest = '786e121028e19304a94fcf86da7d40326701a5a19631adbcaf3302dac9abb5ac' }
)
$proof = @()
foreach ($artifact in $artifacts) {
    $text = gh api "repos/microsoft/BCApps/actions/artifacts/$($artifact.id)"
    if ($LASTEXITCODE -ne 0) { throw 'Pinned preserved snapshot unavailable.' }
    $metadata = $text | ConvertFrom-Json
    if ($metadata.expired -or $metadata.workflow_run.id -ne 37634358042 -or
        $metadata.workflow_run.head_sha -ne '0227094059f2f26f3fcb1b7f85a3285c17e78b8e' -or
        $metadata.name -ne "sql-api-comparison-packages-$($artifact.country)-37634358042" -or
        $metadata.digest -ne "sha256:$($artifact.digest)") { throw 'Pinned preserved snapshot provenance drift.' }
    $proof += @{ pin = $artifact; metadata = $metadata }
}
$manifest = @{
    runId = $env:GITHUB_RUN_ID; headSha = $env:GITHUB_SHA; branch = $env:GITHUB_REF
    event = $env:GITHUB_EVENT_NAME; runAttempt = 1; replacementOf = $null
    cells = $cells; originalCells = 20; exploratory = $true
    mountedTenants = @(1, 2); workersEqualMountedTenants = $true
    controlReference = @{ runId = '37634358042'; arm = 'control'; mountedTenants = 4; workers = 3 }
    warmup = $false; companiesProbe = $false; sqlRetry = $false; additionalDisabledTests = @()
    sourceSha = 'c4953dceffe02a017adad34973e1955017bf5d20'; template = 'detached-read-only-before-discovery'
    concurrencyGroup = 'sql-api-646383-tenant-count-comparison'; maxParallel = 2
    scheduling = 'Independent of original300: original6 + tenant-count2 + readiness2 = authorized total10'
    schedulingSupersedesRunId = '37695638367'; schedulingOnlySuccessor = $true; testRerun = $false
    timingCaveats = @('Later execution temporal bias', '1/2 actual workers versus reserved-default 3-worker reference',
        'Resource sampling and detached read-only-template preparation are new harness instrumentation')
}
$manifest | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $directory 'matrix-manifest.json')
$proof | ConvertTo-Json -Depth 15 | Set-Content (Join-Path $directory 'artifact-proof.json')
"matrix=$(@{include=$cells} | ConvertTo-Json -Depth 5 -Compress)" | Add-Content $env:GITHUB_OUTPUT
