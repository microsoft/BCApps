$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Context.psm1')
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')
$context = Get-ExpandedContext
$ownershipPath = Join-Path $context.output 'ownership.json'
$cleanupVerified = $false
$cleanupStart = [Diagnostics.Stopwatch]::GetTimestamp()
$cleanupUtc = [DateTime]::UtcNow.ToString('o')
if (Test-Path $ownershipPath) {
    $owner = Get-Content $ownershipPath -Raw | ConvertFrom-Json
    if ($owner.run -cne $env:GITHUB_RUN_ID -or $owner.sourceHead -cne $env:GITHUB_SHA -or
        $owner.identity -cne $context.cell.identity -or $owner.lane -cne $context.lane.id -or
        $owner.container -ne $context.container) { throw 'Refusing cleanup of foreign ownership.' }
    Import-ExpandedHelper
    try {
        if (Test-BcContainer -containerName $context.container) {
            $events = Get-BcContainerEventLog -containerName $context.container -doNotOpen
            Copy-Item $events (Join-Path $context.output 'final-container.evtx')
        }
    } finally {
        if (Test-BcContainer -containerName $context.container) { Remove-BcContainer -containerName $context.container }
        $cleanupVerified = -not (Test-BcContainer -containerName $context.container)
        @{ run = $env:GITHUB_RUN_ID; identity = $context.cell.identity; lane = $context.lane.id
            container = $context.container; containerRemaining = -not $cleanupVerified } |
            ConvertTo-Json | Set-Content (Join-Path $context.output 'cleanup.json')
        Write-ExpandedPhase -Name cleanup -StartedTicks $cleanupStart -StartedUtc $cleanupUtc -Completed $cleanupVerified -Directory $context.output
    }
}
$clock = Get-Content (Join-Path $context.output 'clock.json') -Raw | ConvertFrom-Json
$ended = [Diagnostics.Stopwatch]::GetTimestamp()
$phases = @(Get-Content (Join-Path $context.output 'phases.jsonl') | ForEach-Object { $_ | ConvertFrom-Json })
$execution = @($phases | Where-Object phase -EQ 'execution-including-template-discovery-resets')
$resets = @(Get-Content (Join-Path $context.output 'reset-timeline.jsonl') | ForEach-Object { $_ | ConvertFrom-Json })
$resetStarts = @($resets | Where-Object phase -EQ 'reset-start')
$resetEnds = @($resets | Where-Object phase -EQ 'reset-complete')
$outcome = Get-Content (Join-Path $context.output 'lane-outcome.json') -Raw | ConvertFrom-Json
if ($outcome.runId -cne $env:GITHUB_RUN_ID -or $outcome.sourceHead -cne $env:GITHUB_SHA -or
    $outcome.identity -cne $context.cell.identity -or $outcome.lane -cne $context.lane.id) { throw 'Foreign lane outcome.' }
$resource = Get-Content (Join-Path $context.output 'resource-status.json') -Raw | ConvertFrom-Json
$setupResource = Get-Content (Join-Path $context.output 'setup-resource.json') -Raw | ConvertFrom-Json
$containerSetupResource = Get-Content (Join-Path $context.output 'container-setup-resource.json') -Raw | ConvertFrom-Json
$runtime = Get-Content (Join-Path $context.output 'runner-inventory.json') -Raw | ConvertFrom-Json
$docker = Get-Content (Join-Path $context.output 'docker.json') -Raw | ConvertFrom-Json
$template = Get-Content (Join-Path $context.output 'template.json') -Raw | ConvertFrom-Json
$transport = Get-Content (Join-Path $context.output 'transport-proof.json') -Raw | ConvertFrom-Json
$attempts = @(Get-Content (Join-Path $context.output 'original-attempts.jsonl') | ForEach-Object { $_ | ConvertFrom-Json })
$cuCount = @($outcome.discovered | ForEach-Object { "$($_.appId)/$($_.codeunitId)" } | Sort-Object -Unique).Count
$phaseValid = $execution.Count -eq 1 -and $clock.ticks -gt 0 -and
    $clock.frequency -eq [Diagnostics.Stopwatch]::Frequency -and
    $execution[0].startedTicks -gt $clock.ticks -and $ended -gt $execution[0].endedTicks -and
    @($phases | Where-Object { -not $_.completed -or $_.endedTicks -lt $_.startedTicks }).Count -eq 0
$resetWall = $null
if ($resetStarts.Count -eq $resetEnds.Count) {
    $resetWall = 0.0
    for ($i = 0; $i -lt $resetStarts.Count; $i++) {
        if ($resetStarts[$i].plan.Tenant -ne $resetEnds[$i].plan.Tenant -or
            $resetStarts[$i].plan.Generation -ne $resetEnds[$i].plan.Generation -or
            $resetEnds[$i].ticks -lt $resetStarts[$i].ticks) { throw 'Reset timing pairs differ.' }
        $resetWall += ($resetEnds[$i].ticks - $resetStarts[$i].ticks) * 1000.0 / $resetStarts[$i].frequency
    }
}
@{
    totalMilliseconds = ($ended - $clock.ticks) * 1000.0 / $clock.frequency
    setupMilliseconds = $(if ($execution.Count -eq 1) { ($execution[0].startedTicks - $clock.ticks) * 1000.0 / $clock.frequency } else { $null })
    phases = $phases; completedResetCount = $resetEnds.Count
    summedResetMilliseconds = ($resetEnds.observation | Measure-Object elapsedMilliseconds -Sum).Sum
    resetWallUnionMilliseconds = $resetWall
    pipelineFinalizationAndExportMilliseconds = $(if ($execution.Count -eq 1) { ($cleanupStart - $execution[0].endedTicks) * 1000.0 / $clock.frequency } else { $null })
    codeunitAttempts = $attempts
    summedCodeunitMilliseconds = (@($attempts | ForEach-Object { ($_.collectedTicks - $_.dispatchStartedTicks) * 1000.0 / $_.frequency }) | Measure-Object -Sum).Sum
    summedWorkerExecutionMilliseconds = (@($attempts | ForEach-Object { ($_.endedTicks - $_.startedTicks) * 1000.0 / $_.frequency }) | Measure-Object -Sum).Sum
    caseTimes = @($outcome.results | Select-Object country, lane, appId, codeunitId, method, seconds, status)
    timingDefinition = 'Assigned-runner pre-checkout through owned cleanup; queue and upload excluded. Execution includes inventory, sampling, template/discovery/resets/tests and sampler/event export. Discovery includes its finally reset. Reset operation sum excludes host IPC; resetWallUnion is the sum of serialized host reset intervals within this lane. Different cells overlap. CU dispatch-through-collection includes startup and batch-drain waiting; worker execution excludes startup. Both are summed overlapping work, not wall time. XML is AL case time, not HTTP latency.'
    actualRunner = $clock.runner; actualHost = $clock.host; complete = $phaseValid
} | ConvertTo-Json -Depth 15 | Set-Content (Join-Path $context.output 'performance.json')
$evidence = @{
    identity = $context.cell.identity; attempt = 1; originalFailures = $outcome.originalFailures
    retries = 0; warmups = 0; probes = 0; actualNstVersion = $runtime.nstVersion
    actualImage = $docker.verifiedGenericImage; actualContainerImageId = $docker.actualContainerImageId
    actualMemoryBytes = $docker.memoryBytes; mounts = @($runtime.mounts.Id | Sort-Object)
    workers = @($runtime.workers); originalFailuresPersisted = ($attempts.Count -eq $cuCount -and
        @($attempts | Where-Object { $_.attempt -ne 1 -or -not $_.passed }).Count -eq 0)
    artifactTransportVerified = $transport.transportVerified; packageManifestVerified = $transport.packageFilesVerified
    ownedCleanupVerified = $cleanupVerified
    resourceEvidenceComplete = ($resource.measurementComplete -and $null -ne $setupResource.host -and
        $setupResource.errors.Count -eq 0 -and $null -ne $containerSetupResource.container -and
        $containerSetupResource.errors.Count -eq 0 -and $containerSetupResource.container.errors.Count -eq 0)
    phaseEvidenceComplete = $phaseValid
    runnerInventoryComplete = ($runtime.installed.Count -gt 0 -and $runtime.multitenant -and
        $runtime.applicationDatabase -and $runtime.applicationDatabase -notin $runtime.mounts.Id)
    templateFrozenBeforeDiscovery = $template.frozenBeforeDiscovery
    templateDetachedReadOnly = ($template.detached -and $template.readOnly)
    discoveryRestoredInFinally = ($resetStarts.Count -eq $cuCount + 1 -and $resetEnds.Count -eq $resetStarts.Count -and
        $resetEnds[0].plan.Tenant -eq 'default' -and
        @($resetEnds | Where-Object { $_.plan.TemplateIdentity -ne $template.serviceBrokerGuid }).Count -eq 0)
    lanes = @($outcome); registryId = $transport.registryId; registrySha256 = $transport.registrySha256
    packageManifest = (Get-Content (Join-Path $context.output 'packages.json') -Raw | ConvertFrom-Json)
    installation = $runtime.installation
}
$singleLaneCell = @{ identity = $context.cell.identity; country = $context.cell.country
    configuration = $context.cell.configuration; lanes = @($context.lane) }
$qualified = $false
try {
    if (-not $outcome.completed -or -not $outcome.passed -or -not $docker.genericLayerPrefixVerified) { throw 'Original lane execution did not qualify.' }
    Assert-ExpandedApiEvidence -Evidence $evidence -Cell $singleLaneCell
    $qualified = $true
} finally {
    @{ qualified = $qualified; evidence = $evidence } | ConvertTo-Json -Depth 40 |
        Set-Content (Join-Path $context.output 'lane-evidence.json')
}
