$ErrorActionPreference = 'Stop'
if ($env:GITHUB_REPOSITORY -ne 'microsoft/BCApps' -or
    $env:GITHUB_REF -ne 'refs/heads/features/646383-sql-api-300-trial-comparison' -or
    $env:GITHUB_EVENT_NAME -ne 'workflow_dispatch' -or $env:GITHUB_RUN_ATTEMPT -ne '1' -or
    $env:GITHUB_RUN_ID -notmatch '^\d{1,20}$' -or $env:GITHUB_SHA -notmatch '^[0-9a-f]{40}$') {
    throw 'Comparison planning is restricted to the exact manual diagnostic branch, attempt one.'
}
Import-Module (Join-Path $PSScriptRoot 'Comparison.psm1') -Force
function Read-GitHubJson([string]$Path) {
    $text = & gh api $Path
    if ($LASTEXITCODE -ne 0) { throw "GitHub metadata unavailable for $Path; refusing to schedule." }
    $text | ConvertFrom-Json
}
$cells = @(Get-SqlComparisonCell -Mode $env:COMPARISON_MODE -Arm $env:REPLACEMENT_ARM `
    -Country $env:REPLACEMENT_COUNTRY -Trial $env:REPLACEMENT_TRIAL)
$replacement = $null
$directory = Join-Path $env:GITHUB_WORKSPACE '.sql-api-comparison-plan'
$null = New-Item -ItemType Directory -Path $directory -Force
if ($env:COMPARISON_MODE -eq 'replacement') {
    if ($env:ORIGINAL_RUN -notmatch '^\d{1,20}$' -or $env:ORIGINAL_JOB -notmatch '^\d{1,20}$') {
        throw 'Replacement requires explicit original run and job IDs.'
    }
    $run = Read-GitHubJson "repos/microsoft/BCApps/actions/runs/$env:ORIGINAL_RUN"
    $job = Read-GitHubJson "repos/microsoft/BCApps/actions/jobs/$env:ORIGINAL_JOB"
    if ($job.check_run_url -notmatch '^https://api\.github\.com/repos/microsoft/BCApps/check-runs/(\d+)$') {
        throw 'Unexpected check-run URL.'
    }
    $annotations = @(Read-GitHubJson "repos/microsoft/BCApps/check-runs/$($Matches[1])/annotations?per_page=100")
    $replacement = Assert-SqlComparisonReplacement -Run $run -Job $job -Annotations $annotations `
        -Cell $cells[0] -ExpectedSha $env:GITHUB_SHA
} elseif ($env:ORIGINAL_RUN -or $env:ORIGINAL_JOB) {
    throw 'Original schedule cannot specify previous runs or jobs.'
}
$proof = @()
if ($replacement) {
    $artifacts = Read-GitHubJson "repos/microsoft/BCApps/actions/runs/$env:ORIGINAL_RUN/artifacts?per_page=100&name=sql-api-comparison-packages-$($env:REPLACEMENT_COUNTRY)-$env:ORIGINAL_RUN"
    $snapshot = @($artifacts.artifacts)
    if ($snapshot.Count -ne 1) { throw 'Expected exactly one original comparison country snapshot.' }
    $proof = @(Save-SqlComparisonSnapshot -ArtifactId $snapshot[0].id -RunId $env:ORIGINAL_RUN `
        -HeadSha $env:GITHUB_SHA -Country $env:REPLACEMENT_COUNTRY -Directory (Join-Path $directory $env:REPLACEMENT_COUNTRY))
    "w1Package=$(if ($env:REPLACEMENT_COUNTRY -eq 'W1') { $snapshot[0].id } else { '0' })" | Add-Content $env:GITHUB_OUTPUT
    "dePackage=$(if ($env:REPLACEMENT_COUNTRY -eq 'DE') { $snapshot[0].id } else { '0' })" | Add-Content $env:GITHUB_OUTPUT
    "packageRun=$env:ORIGINAL_RUN" | Add-Content $env:GITHUB_OUTPUT
} else {
    if (-not $env:GH_TOKEN) { throw 'Actions credential is required to preserve immutable source archives.' }
    $headers = @{ Authorization = "Bearer $env:GH_TOKEN"; Accept = 'application/vnd.github+json' }
    foreach ($pin in Get-SqlComparisonArtifact) {
        $metadata = Read-GitHubJson "repos/microsoft/BCApps/actions/artifacts/$($pin.id)"
        if ($metadata.expired -or $metadata.workflow_run.id -ne 37372848860 -or
            $metadata.workflow_run.head_sha -ne 'c4953dceffe02a017adad34973e1955017bf5d20' -or
            $metadata.digest -ne "sha256:$($pin.digest)") {
            throw "Pinned artifact $($pin.id) is expired or differs; no fallback permitted."
        }
        $destination = Join-Path $directory $pin.country
        $null = New-Item -ItemType Directory -Path $destination -Force
        $zip = Join-Path $destination "$($pin.id).zip"
        Invoke-WebRequest "https://api.github.com/repos/microsoft/BCApps/actions/artifacts/$($pin.id)/zip" `
            -Headers $headers -OutFile $zip -UseBasicParsing
        if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $pin.digest) { throw 'Source archive hash mismatch.' }
        $proof += @{ pin = $pin; metadata = $metadata; verifiedUtc = [datetime]::UtcNow.ToString('o') }
    }
    foreach ($country in @('W1', 'DE')) {
        $countryProof = @($proof | Where-Object { $_.pin.country -eq $country })
        ConvertTo-Json -InputObject $countryProof -Depth 12 |
            Set-Content (Join-Path $directory "$country\artifact-proof.json") -Encoding utf8
        $null = Assert-SqlComparisonSnapshot -Directory (Join-Path $directory $country) -Country $country
    }
    "packageRun=$env:GITHUB_RUN_ID" | Add-Content $env:GITHUB_OUTPUT
}
$manifest = @{
    run = $env:GITHUB_RUN_ID; head = $env:GITHUB_SHA; mode = $env:COMPARISON_MODE
    createdUtc = [datetime]::UtcNow.ToString('o'); originalCellCount = $(if ($replacement) { 0 } else { $cells.Count })
    replacementOf = $replacement; cells = $cells; globalContainerLimit = 6
    packagePolicy = 'Original ZIP bytes and source metadata preserved in immutable 14-day country snapshots; SHA256 verified on every download. No rebuild or package substitution.'
    batchCount = $(if ($replacement) { 1 } else { 10 }); cellsPerOriginalBatch = 30
    expectedCompleteCohort = @{ codeunits = 21; cases = 253; skipped = 19; addedExclusions = 0 }
    outcomePolicy = 'Original first-attempt failures, retries, final failures and communication-invalid jobs remain distinct; never count skipped/cancelled/incomplete jobs as passes.'
}
$manifest | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $directory 'matrix-manifest.json') -Encoding utf8
ConvertTo-Json -InputObject @($proof) -Depth 12 | Set-Content (Join-Path $directory 'artifact-proof.json') -Encoding utf8
"mode=$env:COMPARISON_MODE" | Add-Content $env:GITHUB_OUTPUT
"replacement=$(ConvertTo-Json -InputObject $replacement -Depth 8 -Compress)" | Add-Content $env:GITHUB_OUTPUT
foreach ($batch in 1..10) {
    $selected = @($cells | Select-Object -Skip (($batch - 1) * 30) -First 30)
    $matrix = @{ include = $selected } | ConvertTo-Json -Depth 6 -Compress
    "batch$($batch.ToString('00'))=$matrix" | Add-Content $env:GITHUB_OUTPUT
}
Write-Output "Validated $($cells.Count) distinct scheduled cells; global container limit six. No automatic communication replacements."
