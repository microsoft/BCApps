$ErrorActionPreference = 'Stop'
if ($env:GITHUB_REPOSITORY -ne 'microsoft/BCApps' -or
    $env:GITHUB_REF -ne 'refs/heads/features/646383-sql-api-worker-warmup-comparison' -or
    $env:GITHUB_EVENT_NAME -ne 'workflow_dispatch' -or $env:GITHUB_RUN_ATTEMPT -ne '1' -or
    $env:GITHUB_RUN_ID -notmatch '^\d{1,20}$' -or $env:GITHUB_SHA -notmatch '^[0-9a-f]{40}$') {
    throw 'Only the exact manual worker comparison may be planned.'
}
Import-Module (Join-Path $PSScriptRoot 'WorkerWarmup.psm1') -Force
$cells = @(Get-WorkerWarmupCell)
$directory = Join-Path $env:GITHUB_WORKSPACE '.sql-api-worker-plan'
$null = New-Item -ItemType Directory -Path $directory -Force
$proof = @()
foreach ($pin in @(
    @{ country = 'W1'; id = '11487493885'; digest = '09be1c12a5fe014fd2c1e0a6ab075e809f5693a9294dc8aa949c53961d1b50bd' },
    @{ country = 'DE'; id = '11486874993'; digest = '786e121028e19304a94fcf86da7d40326701a5a19631adbcaf3302dac9abb5ac' }
)) {
    $text = gh api "repos/microsoft/BCApps/actions/artifacts/$($pin.id)"
    if ($LASTEXITCODE) { throw 'Preserved package metadata unavailable.' }
    $metadata = $text | ConvertFrom-Json
    if ($metadata.expired -or $metadata.workflow_run.id -ne 37634358042 -or
        $metadata.workflow_run.head_sha -ne '0227094059f2f26f3fcb1b7f85a3285c17e78b8e' -or
        $metadata.name -ne "sql-api-comparison-packages-$($pin.country)-37634358042" -or
        $metadata.digest -ne "sha256:$($pin.digest)" -or [datetime]$metadata.expires_at -le [datetime]::UtcNow) {
        throw 'Exact preserved snapshot expired or changed; never substitute or rebuild.'
    }
    $proof += @{ pin = $pin; metadata = $metadata; checkedUtc = [datetime]::UtcNow.ToString('o') }
}
$proof | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $directory 'artifact-proof.json')
@{
    headSha = $env:GITHUB_SHA; runId = $env:GITHUB_RUN_ID; originalCells = $cells; replacementOf = $null
    sourceSha = 'c4953dceffe02a017adad34973e1955017bf5d20'; sharedBaseline = '0227094059f2f26f3fcb1b7f85a3285c17e78b8e'
    count = 30; exploratory = $true; mountedTenants = 4; workers = 3; maxParallel = 6
    operation = 'Existing Invoke-WarmupDispatch on each remounted worker'
    app = 'System Application Test Library (original ordered first app)'
    runner = 'Original RunTestsInBcContainer.ps1 IntegrationTest parameters, unchanged'
    emptyWarmupTestsAllowed = $true; warmupReadinessGuarantee = $false
    navReadiness = 'Serial postmount 30s, same app warmup, one authenticated tenant companies GET (60s timeout), pretest 30s'
    limitation = 'NAV-inspired, not Toolkit page149042/two-API preflight; compound treatment, not a SQL readiness guarantee'
    expectedWarmupsPerCompleteCandidate = 22; expectedCohortCases = 253; expectedExistingSkips = 19
    additionalDisabledTests = @(); extraDefaultWarmup = $false; companiesProbeArm = 'navreadiness'; retries = 0
    concurrencyGroup = 'sql-api-646383-300-trial-comparison'
} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $directory 'matrix-manifest.json')
"matrix=$(@{ include = $cells } | ConvertTo-Json -Depth 5 -Compress)" | Add-Content $env:GITHUB_OUTPUT
