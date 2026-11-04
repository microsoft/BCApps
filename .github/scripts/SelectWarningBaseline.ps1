# The PA working branch has an Apps-complete CI/CD run whose unrelated unit tests
# failed. AL-Go returns baseline ID 0 for that run and then tries to download run 0.
# Accept it ONLY as a warning-comparison baseline, after verifying all Apps outputs.
param(
    [Parameter(Mandatory)][string] $BaselineRunId,
    [string] $BaselineSHA
)
$ErrorActionPreference = 'Stop'
if ($BaselineRunId -ne '0') {
    # Windows PowerShell 5.1 writes a BOM with Out-File -Encoding utf8; GitHub output files require plain UTF-8/ASCII.
    Add-Content -Encoding Ascii -Path $env:GITHUB_OUTPUT -Value "BaselineWorkflowRunId=$BaselineRunId"
    Add-Content -Encoding Ascii -Path $env:GITHUB_OUTPUT -Value "BaselineWorkflowSHA=$BaselineSHA"
    exit 0
}

$runId = 41605001075
$sha = 'b33db2a8d3cd206853f3309be93995a8daff6cec'
if ($env:GITHUB_REPOSITORY -ne 'microsoft/BCApps' -or $env:GITHUB_BASE_REF -ne 'features/pav2-0000') {
    throw 'The PA warning baseline fallback is only for the PAV2-based BCApps PR.'
}
$headers = @{ Authorization = "Bearer $env:GITHUB_TOKEN"; Accept = 'application/vnd.github+json'; 'X-GitHub-Api-Version' = '2022-11-28' }
$api = "https://api.github.com/repos/$env:GITHUB_REPOSITORY/actions/runs/$runId"
$run = Invoke-RestMethod -Headers $headers -Uri $api
if ($run.head_sha -ne $sha -or $run.head_branch -ne $env:GITHUB_BASE_REF -or $run.status -ne 'completed') {
    throw 'Pinned PAV2 warning baseline identity changed.'
}
# actions/checkout is shallow by default; use GitHub's compare API instead of local merge-base.
$comparison = Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$env:GITHUB_REPOSITORY/compare/$sha...$env:GITHUB_SHA"
if ($comparison.status -notin @('ahead', 'identical') -or $comparison.behind_by -ne 0) {
    throw 'Pinned warning baseline is not an ancestor of the PR merge commit.'
}

function Get-AllPages([string] $uri, [string] $property) {
    $items = @()
    for ($page = 1; $page -le 100; $page++) {
        $result = Invoke-RestMethod -Headers $headers -Uri "${uri}?per_page=100&page=$page"
        $batch = @($result.$property)
        $items += $batch
        if ($batch.Count -lt 100) { return $items }
    }
    throw "Too many pages of $property"
}
$jobs = Get-AllPages "$api/jobs" 'jobs'
$artifacts = Get-AllPages "$api/artifacts" 'artifacts'
$projects = @('AT','AU','BE','CA','CH','CZ','DE','DK','ES','FI','FR','GB','IN','IS','IT','MX','NL','NO','NZ','RU','SE','US','W1') | ForEach-Object { "Apps $_" }
$projects += 'System Application Modules'
foreach ($project in $projects) {
    $expectedJob = "Build $project (Default) / $project (Default)"
    if (@($jobs | Where-Object { $_.name -eq $expectedJob -and $_.conclusion -eq 'success' }).Count -ne 1) {
        throw "Missing successful baseline Apps job: $expectedJob"
    }
    $expectedArtifact = "build_projects_$project-features_pav2-0000-BuildOutput-"
    if (@($artifacts | Where-Object { $_.name.StartsWith($expectedArtifact) -and -not $_.expired }).Count -ne 1) {
        throw "Missing unexpired baseline BuildOutput artifact: $project"
    }
}
"Validated $($projects.Count) successful Apps builds and their BuildOutput artifacts in failed CI run $runId (unit tests are NOT considered passing)."
Add-Content -Encoding Ascii -Path $env:GITHUB_OUTPUT -Value "BaselineWorkflowRunId=$runId"
Add-Content -Encoding Ascii -Path $env:GITHUB_OUTPUT -Value "BaselineWorkflowSHA=$sha"
