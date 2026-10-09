$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')
Import-Module (Join-Path $PSScriptRoot 'Artifacts.psm1')
Assert-ExpandedApiDispatch
$plan = Get-ExpandedApiPlan -InventoryPath (Join-Path $PSScriptRoot 'routing-inventory.json')
$all = @()
$page = 1
do {
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/BCApps/actions/runs/$($env:GITHUB_RUN_ID)/artifacts?per_page=100&page=$page" `
        -Headers @{ Authorization = "Bearer $env:GH_TOKEN"; Accept = 'application/vnd.github+json' }
    $all += @($response.artifacts); $page++
} while ($response.artifacts.Count -eq 100)
$results = @()
$errors = @()
$reference = @{}
foreach ($cell in $plan.cells) {
    foreach ($lane in $cell.lanes) {
        $name = "expanded-evidence-$($cell.country)-$($cell.configuration.id)-$($lane.id)-$($env:GITHUB_RUN_ID)"
        $classification = 'missing-or-invalid-evidence'
        try {
            $match = @($all | Where-Object name -CEQ $name)
            if ($match.Count -ne 1) { throw 'Missing or duplicate evidence archive.' }
            $directory = Join-Path $env:GITHUB_WORKSPACE "audit-$($cell.country)-$($cell.configuration.id)-$($lane.id)"
            $null = Save-ExpandedArtifact -Id $match[0].id -Digest $match[0].digest.Substring(7) -Directory $directory
            $report = Get-Content (Join-Path $directory 'lane-evidence.json') -Raw | ConvertFrom-Json
            $classification = if ($report.evidence.originalFailures -gt 0) { 'original-test-failure' } else { 'setup-reset-resource-or-cohort-invalid' }
            if (-not $report.qualified) { throw 'Original lane did not qualify.' }
            Assert-ExpandedApiEvidence -Evidence $report.evidence -Cell @{
                identity = $cell.identity; country = $cell.country; configuration = $cell.configuration; lanes = @($lane)
            }
            $key = "$($cell.country)/$($lane.id)"
            $comparison = [ordered]@{
                registry = $report.evidence.registryId; registryDigest = $report.evidence.registrySha256
                packages = $report.evidence.packageManifest
                inventory = Get-ExpandedCohortSignature -Cases $report.evidence.lanes[0].discovered
            } | ConvertTo-Json -Depth 40 -Compress
            if ($reference.ContainsKey($key) -and $reference[$key] -cne $comparison) {
                throw 'Topology arms have different packages, compiled selectors, cases or skip states.'
            }
            $reference[$key] = $comparison
            $performance = Get-Content (Join-Path $directory 'performance.json') -Raw | ConvertFrom-Json
            $results += @{ identity = $cell.identity; lane = $lane.id; qualified = $true; artifactId = $match[0].id
                totalMilliseconds = $performance.totalMilliseconds; setupMilliseconds = $performance.setupMilliseconds
                resetMilliseconds = $performance.summedResetMilliseconds
                summedCodeunitMilliseconds = $performance.summedCodeunitMilliseconds
                runner = $performance.actualRunner; host = $performance.actualHost }
        } catch {
            $errors += @{ identity = $cell.identity; lane = $lane.id; classification = $classification; error = $_.Exception.Message }
        }
    }
}
$null = New-Item -ItemType Directory -Path 'expanded-audit'
$cells = @(foreach ($cell in $plan.cells) {
    $lanes = @($results | Where-Object identity -CEQ $cell.identity)
    @{ identity = $cell.identity; complete = ($lanes.Count -eq $cell.lanes.Count)
        queueExcludedLaneSumMilliseconds = ($lanes | Measure-Object totalMilliseconds -Sum).Sum
        note = 'Sum of sequential lane assigned-runner totals, excluding inter-lane queues and uploads; not end-to-end workflow wall time.' }
})
@{ run = $env:GITHUB_RUN_ID; head = $env:GITHUB_SHA; results = $results; errors = $errors
    buildResult = $env:BC_EXPANDED_BUILD_RESULT; registryResult = $env:BC_EXPANDED_REGISTRY_RESULT
    trialsResult = $env:BC_EXPANDED_TRIALS_RESULT
    setupInvalid = ($env:BC_EXPANDED_BUILD_RESULT -ne 'success' -or $env:BC_EXPANDED_REGISTRY_RESULT -ne 'success')
    complete = ($errors.Count -eq 0); uncoveredVariants = $plan.uncoveredVariants
    cells = $cells
    allCountriesTested = $false; repetitions = 1; statisticalStabilityEstablished = $false } |
    ConvertTo-Json -Depth 30 | Set-Content 'expanded-audit\comparison.json'
if ($errors.Count) { throw "$($errors.Count) expanded diagnostic lanes failed qualification; originals remain failures." }
