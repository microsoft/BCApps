$ErrorActionPreference = 'Stop'
$base = 'c4953dceffe02a017adad34973e1955017bf5d20'
if ($env:GITHUB_REPOSITORY -ne 'microsoft/BCApps' -or
    $env:GITHUB_REF -ne 'refs/heads/features/646383-sql-api-worker-warmup-comparison' -or
    $env:BC_SQL_API_EXPERIMENT -notin @('control', 'workerwarmup', 'navreadiness') -or
    $env:GITHUB_EVENT_NAME -ne 'workflow_dispatch' -or $env:GITHUB_RUN_ATTEMPT -ne '1' -or
    $env:BC_SQL_PILOT_ARM -ne 'control' -or $env:BC_SQL_PILOT_COUNTRY -notin @('W1', 'DE') -or
    $env:BC_SQL_PILOT_TRIAL -notmatch '^[1-5]$' -or $env:GITHUB_RUN_ID -notmatch '^\d{1,20}$') {
    throw 'This diagnostic is restricted to its explicitly dispatched disposable CI branch, attempt one.'
}
git merge-base --is-ancestor $base HEAD
if ($LASTEXITCODE -ne 0) { throw 'PR2 base is not an ancestor.' }
git diff --exit-code $base HEAD -- src
if ($LASTEXITCODE -ne 0) { throw 'AL/package source differs from the pinned compiled PR2 source.' }

$project = "build\projects\Test Apps $($env:BC_SQL_PILOT_COUNTRY)"
$trialProject = "$project Trial$($env:BC_SQL_PILOT_TRIAL)$($env:BC_SQL_API_EXPERIMENT)"
if (Test-Path $trialProject) { throw 'Trial project must not already exist.' }
# AL-Go derives its container name from the project path. Preserve wrapper depth and country settings.
Copy-Item $project $trialProject -Recurse
"artifact=https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/sandbox/30.0.55683.0/$($env:BC_SQL_PILOT_COUNTRY.ToLowerInvariant())" |
    Add-Content $env:GITHUB_OUTPUT
$output = Join-Path $env:GITHUB_WORKSPACE 'sql-reset-pilot-output'
New-Item -ItemType Directory $output -Force | Out-Null
"BC_SQL_PILOT_OUTPUT=$output" | Add-Content $env:GITHUB_ENV
@{ phase = 'package-preflight'; arm = $env:BC_SQL_PILOT_ARM; run = $env:GITHUB_RUN_ID; utc = [DateTime]::UtcNow.ToString('o') } |
    ConvertTo-Json | Set-Content (Join-Path $output 'start.json') -Encoding UTF8
Import-Module (Join-Path $PSScriptRoot 'Comparison.psm1') -Force
$replacement = $null
if ($env:BC_SQL_COMPARISON_REPLACEMENT -and $env:BC_SQL_COMPARISON_REPLACEMENT -ne 'null') { throw 'This protocol prepares originals only.' }
$expectedSnapshotRun = '37634358042'
$expectedSnapshotArtifact = if ($env:BC_SQL_PILOT_COUNTRY -eq 'W1') { '11487493885' } else { '11486874993' }
if ($env:BC_SQL_COMPARISON_PACKAGE_ARTIFACT -ne $expectedSnapshotArtifact) { throw 'Unexpected preserved country snapshot ID.' }
if ($env:BC_SQL_COMPARISON_PACKAGE_RUN -ne $expectedSnapshotRun) { throw 'Snapshot source run differs from original/replacement provenance.' }
$snapshotDirectory = Join-Path $env:GITHUB_WORKSPACE 'sql-api-package-snapshot'
$snapshotProof = @(Save-SqlComparisonSnapshot -ArtifactId $env:BC_SQL_COMPARISON_PACKAGE_ARTIFACT `
    -RunId $expectedSnapshotRun -HeadSha '0227094059f2f26f3fcb1b7f85a3285c17e78b8e' -Country $env:BC_SQL_PILOT_COUNTRY -Directory $snapshotDirectory)
$snapshotProof | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $output 'original-artifact-proof.json')
$artifacts = @(
    @{ Kind = 'apps'; Id = 11374170356; Digest = '683343673e6efeb7699734b250d2ee5004d2d83fe08e57f324c4c645c09612db' },
    @{ Kind = 'tests'; Id = 11374145359; Digest = 'f75ce06920437328e5d79a5512eddcc2425624bb696c339c108478c83554171d' }
)
if ($env:BC_SQL_PILOT_COUNTRY -eq 'DE') {
    $artifacts = @(
        @{ Kind = 'apps'; Id = 11376415128; Digest = '409af00bb5e6922224626f94a4d4f5625f4a9bf13b9398e84cc101a41a313dd5' },
        @{ Kind = 'tests'; Id = 11375174896; Digest = '4e1edde77089e0b586679b168f11123a8181a99c63c3a82b42323503340a5d3b' }
    )
}
$manifest = @()
foreach ($artifact in $artifacts) {
    $metadata = @($snapshotProof | Where-Object { $_.pin.id -eq [string]$artifact.Id })[0].metadata
    if ($metadata.expired -or $metadata.workflow_run.id -ne 37372848860 -or
        $metadata.workflow_run.head_sha -ne $base -or $metadata.digest -ne "sha256:$($artifact.Digest)") {
        throw 'Exact artifact provenance/digest check failed; no moving-build fallback is permitted.'
    }
    $destination = Join-Path $env:GITHUB_WORKSPACE "sql-reset-pilot-packages\$($artifact.Kind)"
    New-Item -ItemType Directory $destination -Force | Out-Null
    $zip = Join-Path $snapshotDirectory "$($artifact.Id).zip"
    if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $artifact.Digest) { throw 'Artifact archive hash mismatch.' }
    Expand-Archive $zip $destination
    $files = @(Get-ChildItem $destination -Filter '*.app' -Recurse -File | Sort-Object FullName)
    if ($files.Count -eq 0) { throw 'Pinned artifact contains no app packages.' }
    $list = Join-Path $destination 'packages.json'
    ConvertTo-Json -InputObject @($files.FullName) | Set-Content $list -Encoding UTF8
    "$($artifact.Kind)=$list" | Add-Content $env:GITHUB_OUTPUT
    $manifest += @{
        artifactId = $artifact.Id; sourceRun = 37372848860; sourceHead = $base
        kind = $artifact.Kind; archiveSha256 = $artifact.Digest
        files = @($files | ForEach-Object { @{ name = $_.Name; sha256 = (Get-FileHash $_.FullName).Hash } })
    }
}
@{
    experimentHead = $env:GITHUB_SHA; run = $env:GITHUB_RUN_ID; arm = $env:BC_SQL_PILOT_ARM
    experiment = $env:BC_SQL_API_EXPERIMENT; sharedBaseline = '0227094059f2f26f3fcb1b7f85a3285c17e78b8e'
    warmupSource = $base; historicalWarmupReference = 'fcc1776c6b165199dd66e4227675b1cc31da7a8f'
    trialIdentity = "$($env:BC_SQL_API_EXPERIMENT)/$($env:BC_SQL_PILOT_COUNTRY)/$($env:BC_SQL_PILOT_TRIAL)"
    replacementOf = $replacement
    packageSnapshot = @{ runId = $expectedSnapshotRun; artifactId = $env:BC_SQL_COMPARISON_PACKAGE_ARTIFACT }
    country = $env:BC_SQL_PILOT_COUNTRY; trial = $env:BC_SQL_PILOT_TRIAL; project = $trialProject
    warmup = $(if ($env:BC_SQL_API_EXPERIMENT -eq 'control') { 'none' } else { 'Existing first-app Invoke-WarmupDispatch on each worker after every remount; System Application Test Library, original IntegrationTest runner parameters, empty tests allowed' })
    emptyWarmupTestsAllowed = $true; warmupReadinessGuarantee = $false
    extraDefaultWarmup = $false
    companiesProbe = $(if ($env:BC_SQL_API_EXPERIMENT -eq 'navreadiness') { 'per-restored-worker-single-attempt' } else { 'none' })
    companiesProbeMaximumAttempts = $(if ($env:BC_SQL_API_EXPERIMENT -eq 'navreadiness') { 1 } else { 0 })
    companiesProbeTimeoutSeconds = 60; companiesProbeRetryDelaySeconds = 0
    serialPostMountSeconds = $(if ($env:BC_SQL_API_EXPERIMENT -eq 'navreadiness') { 30 } else { 0 })
    preTestSeconds = $(if ($env:BC_SQL_API_EXPERIMENT -eq 'navreadiness') { 30 } else { 0 })
    additionalDisabledTests = @()
    warmupRetries = 0; maximumEvidenceGatedRetriesPerCodeunit = 0
    expectedCohortCases = 253; expectedExistingSkips = 19; mountedTenants = 4; cleanWorkers = 3
    genericTestRetries = 0; schedulerRetries = 0; ciRetries = 0
    budgetMinutes = 120; startedUtc = [DateTime]::UtcNow.ToString('o')
    artifacts = $manifest
} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $output 'provenance.json') -Encoding UTF8
