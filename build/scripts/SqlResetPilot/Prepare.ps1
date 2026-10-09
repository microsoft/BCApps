$ErrorActionPreference = 'Stop'
$base = 'c4953dceffe02a017adad34973e1955017bf5d20'
Import-Module (Join-Path $PSScriptRoot 'PlatformUptake.psm1') -Force
Assert-SqlPlatformUptakeContext -Cell
$uptake = Get-SqlPlatformUptake
git merge-base --is-ancestor $base HEAD
if ($LASTEXITCODE -ne 0) { throw 'PR2 base is not an ancestor.' }
git diff --exit-code $base HEAD -- src
if ($LASTEXITCODE -ne 0) { throw 'AL/package source differs from the pinned compiled PR2 source.' }

$project = "build\projects\Test Apps $($env:BC_SQL_PILOT_COUNTRY)"
$trialProject = "$project Uptake$($env:BC_SQL_PILOT_TRIAL)$($env:BC_SQL_API_EXPERIMENT)"
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
$expectedSnapshotRun = $uptake.originalSnapshotRun
if ($env:BC_SQL_COMPARISON_REPLACEMENT -and $env:BC_SQL_COMPARISON_REPLACEMENT -ne 'null') {
    throw 'No replacement trials are authorized.'
}
$snapshotDirectory = Join-Path $env:GITHUB_WORKSPACE 'sql-api-package-snapshot'
$snapshotProof = @(Save-SqlPlatformUptakeSnapshot -Country $env:BC_SQL_PILOT_COUNTRY -Directory $snapshotDirectory)
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
    $packageFiles = @($files | ForEach-Object { @{ name = $_.Name; sha256 = (Get-FileHash $_.FullName).Hash } })
    Assert-SqlPlatformUptakePackageSet -Country $env:BC_SQL_PILOT_COUNTRY -Kind $artifact.Kind -Files $packageFiles
    $manifest += @{
        artifactId = $artifact.Id; sourceRun = 37372848860; sourceHead = $base
        kind = $artifact.Kind; archiveSha256 = $artifact.Digest
        files = $packageFiles
    }
}
@{
    experimentHead = $env:GITHUB_SHA; run = $env:GITHUB_RUN_ID; arm = $env:BC_SQL_PILOT_ARM
    experiment = $env:BC_SQL_API_EXPERIMENT; sharedBaseline = 'fbd7ec46c636ee5f9d940cb81e5abbc1df90f055'
    probeAndWarmupBaseline = 'fcc1776c6b165199dd66e4227675b1cc31da7a8f'
    trialIdentity = "$($env:BC_SQL_API_EXPERIMENT)/$($env:BC_SQL_PILOT_COUNTRY)/$($env:BC_SQL_PILOT_TRIAL)"
    platformUptake = $uptake
    replacementOf = $null
    packageSnapshot = @{ runId = $expectedSnapshotRun; artifactId = @($uptake.snapshots | Where-Object country -eq $env:BC_SQL_PILOT_COUNTRY)[0].id }
    country = $env:BC_SQL_PILOT_COUNTRY; trial = $env:BC_SQL_PILOT_TRIAL; project = $trialProject
    warmup = $(if ($env:BC_SQL_API_EXPERIMENT -eq 'control') { 'none' } else { 'original-first-app-before-clean-lane' })
    companiesProbe = $(if ($env:BC_SQL_API_EXPERIMENT -eq 'control') { 'none' } else { 'per-restored-worker-single-attempt' })
    companiesProbeMaximumAttempts = 1; companiesProbeTimeoutSeconds = 60; companiesProbeRetryDelaySeconds = 0
    additionalDisabledTests = @()
    warmupRetries = 0; maximumEvidenceGatedRetriesPerCodeunit = $(if ($env:BC_SQL_API_EXPERIMENT -eq 'retry') { 1 } else { 0 })
    genericTestRetries = 0; schedulerRetries = 0; ciRetries = 0
    budgetMinutes = 120; startedUtc = [DateTime]::UtcNow.ToString('o')
    artifacts = $manifest
} | ConvertTo-Json -Depth 15 | Set-Content (Join-Path $output 'provenance.json') -Encoding UTF8
