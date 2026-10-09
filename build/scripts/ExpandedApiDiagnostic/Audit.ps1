$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')
Import-Module (Join-Path $PSScriptRoot 'Artifacts.psm1')
Import-Module (Join-Path $PSScriptRoot 'Reuse.psm1')
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
            Assert-ExpandedAdoptionReceipt -Receipt $report.evidence.adoption
            $policy = Get-ExpandedReusePolicy
            if ([string]$report.evidence.registryId -cne $policy.registryId -or
                $report.evidence.registrySha256 -cne $policy.registryDigest -or
                $report.evidence.packageManifest.runId -cne $policy.runId -or
                $report.evidence.packageManifest.sourceHead -cne $policy.sourceHead -or
                $report.evidence.packageManifest.attempt -ne 1 -or
                $report.evidence.packageManifest.country -cne $cell.country -or
                $report.evidence.packageManifest.sourceTree -cne $policy.sourceTree -or
                $report.evidence.packageManifest.overlaySha256 -cne $policy.overlaySha256) {
                throw 'Lane did not preserve approved producer provenance.'
            }
            Assert-ExpandedApiEvidence -Evidence $report.evidence -Cell @{
                identity = $cell.identity; country = $cell.country; configuration = $cell.configuration; lanes = @($lane)
            }
            $installation = Assert-ExpandedInstalledInventory -Files $report.evidence.packageManifest.files `
                -Installed $report.evidence.installation.installed
            if ((@($installation.excluded.path | Sort-Object) -join '|') -cne
                (@($report.evidence.installation.excluded.path | Sort-Object) -join '|') -or
                (@($installation.required.path | Sort-Object) -join '|') -cne
                (@($report.evidence.installation.required.path | Sort-Object) -join '|')) {
                throw 'Runtime installation inventory differs from the shared publication policy.'
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
    compiledThisRun = $false; producer = (Get-ExpandedReusePolicy)
    mode = 'sealed-producer-reuse'; registryResult = $env:BC_EXPANDED_REGISTRY_RESULT
    trialsResult = $env:BC_EXPANDED_TRIALS_RESULT
    setupInvalid = ($env:BC_EXPANDED_REGISTRY_RESULT -ne 'success' -or
        @($errors | Where-Object classification -NE 'original-test-failure').Count -gt 0)
    complete = ($errors.Count -eq 0 -and $env:BC_EXPANDED_REGISTRY_RESULT -eq 'success' -and $env:BC_EXPANDED_TRIALS_RESULT -eq 'success')
    uncoveredVariants = $plan.uncoveredVariants
    cells = $cells
    allCountriesTested = $false; repetitions = 1; statisticalStabilityEstablished = $false } |
    ConvertTo-Json -Depth 30 | Set-Content 'expanded-audit\comparison.json'
if ($errors.Count -or $env:BC_EXPANDED_REGISTRY_RESULT -ne 'success' -or $env:BC_EXPANDED_TRIALS_RESULT -ne 'success') {
    throw "$($errors.Count) expanded diagnostic lanes failed qualification or adoption/trials failed; originals remain failures."
}
