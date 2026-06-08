Import-Module (Join-Path $PSScriptRoot "EnlistmentHelperFunctions.psm1" -Resolve)

# ALAppBuild.psm1 expects $env:INETROOT to point at the repo root and uses Write-Log
# internally. Set both up before importing so its functions work in CI runners that don't
# have the full NAV build environment configured.
if ([string]::IsNullOrEmpty($env:INETROOT)) {
    $env:INETROOT = Get-BaseFolder
}
if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    function global:Write-Log {
        param([Parameter(Position = 0)][string]$Message, [string]$ForegroundColor)
        Write-Host $Message
    }
}
Import-Module (Join-Path $PSScriptRoot "ALAppBuild.psm1" -Resolve)

<#
.SYNOPSIS
    Returns the cached parallel-test-run result for a container, or $null if no run has finished.
.DESCRIPTION
    The first call into Invoke-ParallelTestExecution dispatches every test app in parallel,
    waits for completion, and persists the final result to a state file in $env:RUNNER_TEMP
    (cleaned up between jobs by GitHub Actions). Subsequent invocations from the per-project
    override should short-circuit using this helper to avoid redoing the work.
.OUTPUTS
    [bool] cached final result if dispatch completed; $null if no state file or not yet finished.
#>
function Get-CachedTestRunResult {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName
    )

    $tempDir = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { $env:TEMP }
    $stateFile = Join-Path $tempDir "parallelTests_$ContainerName.json"
    if (-not (Test-Path $stateFile)) { return $null }

    try {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        if ($state.completed) {
            return [bool]$state.finalResult
        }
    } catch {
        Write-Host "WARNING: Failed to parse state file '$stateFile' ($($_.Exception.Message))."
    }
    return $null
}

<#
.SYNOPSIS
    Returns the names of test apps that are both expected for a country and installed in the container.
.DESCRIPTION
    Combines the project metadata in build/projects.json (via Get-ApplicationGroup) with
    Get-BcContainerAppInfo so we only ever try to dispatch apps that actually exist in the
    container. The country defaults to "w1" when unset or set to the repo-level "base" sentinel.
#>
function Get-InstalledTestAppNames {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [string]$Tenant,
        [string]$Country
    )

    if ([string]::IsNullOrWhiteSpace($Country) -or $Country -eq "base") { $Country = "w1" }

    $allTestAppNames = @(
        Get-ApplicationGroup -GroupName "All" -CountryCode $Country -SkipLanguagePacks |
        Where-Object { $_.IsTest } |
        Select-Object -ExpandProperty ApplicationName
    )

    $installedAppNames = @(
        Get-BcContainerAppInfo -containerName $ContainerName -tenant $Tenant -tenantSpecificProperties |
        Where-Object { $_.IsInstalled } |
        Select-Object -ExpandProperty Name
    )

    return @($allTestAppNames | Where-Object { $_ -in $installedAppNames })
}

<#
.SYNOPSIS
    Filters and orders installed test apps according to the bucket configuration in TestConfiguration.json.
.DESCRIPTION
    For TestType=Legacy: returns apps in the named LegacyTests-Bucket{N}, ordered as listed.
    For non-Legacy: returns apps NOT in any LegacyTests-* bucket (order doesn't matter).
.OUTPUTS
    [string[]] Ordered list of app names to dispatch (possibly empty).
#>
function Get-AppNamesForBucket {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$InstalledTestAppNames,
        [Parameter(Mandatory=$true)]
        [string]$TestType,
        [int]$BucketNumber = 0
    )

    $testConfigPath = Join-Path (Get-BaseFolder) "build/scripts/TestConfiguration.json"
    if (-not (Test-Path $testConfigPath)) {
        return @($InstalledTestAppNames)
    }
    $testConfig = Get-Content $testConfigPath -Raw | ConvertFrom-Json

    if ($TestType -eq "Legacy") {
        $bucketOrder = @($testConfig."LegacyTests-Bucket$BucketNumber")
        return @($bucketOrder | Where-Object { $_ -in $InstalledTestAppNames })
    }

    $allLegacyTestApps = @()
    foreach ($prop in $testConfig.PSObject.Properties.Name) {
        if ($prop -like "LegacyTests-*") { $allLegacyTestApps += $testConfig.$prop }
    }
    return @($InstalledTestAppNames | Where-Object { $_ -notin $allLegacyTestApps })
}

<#
.SYNOPSIS
    Gets the list of operational tenants in a BC container.
.PARAMETER containerName
    Name of the BC container to query.
.OUTPUTS
    [string[]] Array of tenant IDs that are in Operational state.
#>
function Get-AvailableBcTenants {
    param(
        [Parameter(Mandatory=$true)]
        [string]$containerName
    )

    $tenants = Invoke-ScriptInBcContainer -containerName $containerName -scriptblock {
        Get-NavTenant $ServerInstance | Where-Object { $_.State -eq "Operational" } | ForEach-Object { $_.Id }
    }
    return @($tenants)
}

<#
.SYNOPSIS
    Merges multiple test result XML files into a single file.
.DESCRIPTION
    Supports both JUnit (<testsuites>/<testsuite>) and XUnit (<assemblies>/<assembly>) formats.
    Uses the first file as the base and appends test elements from remaining files.
.PARAMETER targetFile
    Path to the merged output file.
.PARAMETER sourceFiles
    Array of paths to per-tenant result files to merge.
#>
function Merge-TestResultFiles {
    param(
        [Parameter(Mandatory=$true)]
        [string]$targetFile,
        [Parameter(Mandatory=$true)]
        [string[]]$sourceFiles
    )

    $existingFiles = @($sourceFiles | Where-Object { Test-Path $_ })
    if ($existingFiles.Count -eq 0) {
        Write-Host "No test result files to merge"
        return
    }

    # Start with the first file as the base
    Copy-Item $existingFiles[0] $targetFile -Force
    Write-Host "Base result file: $($existingFiles[0])"

    if ($existingFiles.Count -eq 1) { return }

    # Merge remaining files into the base
    $baseXml = [xml](Get-Content $targetFile -Raw)

    foreach ($file in ($existingFiles | Select-Object -Skip 1)) {
        Write-Host "Merging results from: $file"
        $additionalXml = [xml](Get-Content $file -Raw)

        # JUnit format: root is <testsuites>, children are <testsuite>
        $junitSuites = $additionalXml.SelectNodes("//testsuites/testsuite")
        if ($junitSuites -and $junitSuites.Count -gt 0) {
            $targetNode = $baseXml.SelectSingleNode("//testsuites")
            foreach ($suite in $junitSuites) {
                $imported = $baseXml.ImportNode($suite, $true)
                $targetNode.AppendChild($imported) | Out-Null
            }
            continue
        }

        # XUnit format: root is <assemblies>, children are <assembly>
        $xunitAssemblies = $additionalXml.SelectNodes("//assemblies/assembly")
        if ($xunitAssemblies -and $xunitAssemblies.Count -gt 0) {
            $targetNode = $baseXml.SelectSingleNode("//assemblies")
            foreach ($assembly in $xunitAssemblies) {
                $imported = $baseXml.ImportNode($assembly, $true)
                $targetNode.AppendChild($imported) | Out-Null
            }
            continue
        }

        Write-Host "WARNING: Unrecognized test result format in $file, skipping"
    }

    $baseXml.Save($targetFile)
    Write-Host "Merged $($existingFiles.Count) result files into $targetFile"
}

<#
.SYNOPSIS
    Collects finished jobs and returns tenants that are not currently busy.
.PARAMETER state
    The parallel execution state object containing the jobs array.
.PARAMETER tenants
    Array of all tenant IDs to check availability for.
.OUTPUTS
    [string[]] Array of tenant IDs that are not running a test job.
#>
function Get-FreeTenants {
    param($state, $tenants)

    $terminalStates = @("Completed", "Failed", "Stopped")

    $busyTenants = @()
    $remainingJobs = @()
    foreach ($entry in $state.jobs) {
        $job = Get-Job -Id $entry.jobId -ErrorAction SilentlyContinue
        if (-not $job) {
            continue
        }
        if ($job.State -notin $terminalStates) {
            # Still running, queued (NotStarted), or paused (Blocked/Suspended) — keep it
            $busyTenants += $entry.tenant
            $remainingJobs += $entry
        } else {
            # Terminal state — collect output (all streams) and clean up. Wrap in try/catch
            # because Receive-Job rethrows any unhandled exception from the job (e.g. our
            # "Test execution failed" throw); we want to record the failure and keep dispatching.
            try {
                Receive-Job -Job $job *>&1 | ForEach-Object { Write-Host $_ }
            } catch {
                Write-Host "  (job emitted terminating error: $($_.Exception.Message))"
            }
            if ($job.State -eq "Failed" -or $job.State -eq "Stopped") {
                Write-Host "Tests FAILED for $($entry.appName) on $($entry.tenant) (job state: $($job.State))"
                $state.hasFailures = $true
            }
            Remove-Job -Job $job -Force
        }
    }
    $state.jobs = @($remainingJobs)

    return @($tenants | Where-Object { $_ -notin $busyTenants })
}

<#
.SYNOPSIS
    Waits until at least one tenant is free, then returns its ID.
.PARAMETER state
    The parallel execution state object.
.PARAMETER tenants
    Array of all tenant IDs.
.OUTPUTS
    [string] The first available tenant ID.
#>
function Wait-ForFreeTenant {
    param(
        $state,
        $tenants,
        [int]$timeoutSeconds = 7200,
        [int]$pollIntervalSeconds = 10
    )

    $waited = 0
    while ($waited -lt $timeoutSeconds) {
        $available = @(Get-FreeTenants -state $state -tenants $tenants)
        if ($available) {
            return $available[0]
        }
        Start-Sleep -Seconds $pollIntervalSeconds
        $waited += $pollIntervalSeconds
    }

    throw "Wait-ForFreeTenant: timed out after $timeoutSeconds seconds waiting for a free tenant. Running jobs: $($state.jobs | ForEach-Object { "$($_.appName) on $($_.tenant)" } | Out-String)"
}

<#
.SYNOPSIS
    Starts a background job to run tests for a single app on a specific tenant.
.PARAMETER parameters
    The original test parameters hashtable from Run-AlPipeline.
.PARAMETER tenant
    The tenant ID to run tests on.
.PARAMETER scriptPath
    Path to RunTestsInBcContainer.ps1.
.PARAMETER testType
    The test type (Legacy, UnitTest, etc.)
.OUTPUTS
    [System.Management.Automation.Job] The background job object.
#>
function Start-TestJob {
    param(
        [Hashtable]$parameters,
        [string]$tenant,
        [string]$scriptPath,
        [string]$testType
    )

    $jobParams = $parameters.Clone()
    $jobParams["tenant"] = $tenant

    # Give each tenant its own result file to avoid write conflicts
    foreach ($resultKey in @("XUnitResultFileName", "JUnitResultFileName")) {
        if ($jobParams.ContainsKey($resultKey) -and $jobParams[$resultKey]) {
            $origFile = $jobParams[$resultKey]
            $dir = [System.IO.Path]::GetDirectoryName($origFile)
            $name = [System.IO.Path]::GetFileNameWithoutExtension($origFile)
            $ext = [System.IO.Path]::GetExtension($origFile)
            $jobParams[$resultKey] = Join-Path $dir "$name-$tenant$ext"
        }
    }

    # Resolve BCH module path from the currently loaded module
    $bchModule = Get-Module BcContainerHelper | Select-Object -First 1
    $bchModulePath = if ($bchModule) { $bchModule.Path } else { "BcContainerHelper" }

    return Start-Job -ScriptBlock {
        param($params, $scriptPath, $testType, $bchPath)
        Import-Module $bchPath
        # Background jobs run a single app sequentially. Pass an empty $AppNamesToTest so the
        # shared script skips the parallel dispatch branch and falls through to running this
        # one app's tests directly.
        $passed = . $scriptPath -parameters $params -TestType $testType -AppNamesToTest @()
        if (-not $passed) { throw "Test execution failed" }
    } -ArgumentList $jobParams, $scriptPath, $testType, $bchModulePath
}

<#
.SYNOPSIS
    Waits for all tracked test jobs to complete and returns whether all passed.
.PARAMETER state
    The parallel execution state object containing the jobs array.
.OUTPUTS
    [bool] True if all jobs passed, false if any failed.
#>
function Wait-ForAllTestJobs {
    param($state)

    $allPassed = $true
    foreach ($entry in $state.jobs) {
        $pendingJob = Get-Job -Id $entry.jobId -ErrorAction SilentlyContinue
        if ($pendingJob) {
            Write-Host "Waiting for '$($entry.appName)' on '$($entry.tenant)'..."
            Wait-Job -Job $pendingJob | Out-Null

            # Capture and display job output (all streams, including errors). Wrap because
            # Receive-Job rethrows terminating errors from the job; we want to keep waiting
            # for the rest.
            try {
                Receive-Job -Job $pendingJob *>&1 | ForEach-Object { Write-Host $_ }
            } catch {
                Write-Host "  (job emitted terminating error: $($_.Exception.Message))"
            }

            if ($pendingJob.State -eq "Failed" -or $pendingJob.State -eq "Stopped") {
                Write-Host "Tests FAILED for $($entry.appName) on $($entry.tenant) (job state: $($pendingJob.State))"
                $allPassed = $false
            }
            Remove-Job -Job $pendingJob -Force
        }
    }
    return $allPassed
}

<#
.SYNOPSIS
    Merges per-tenant test result files into the single file expected by Run-AlPipeline.
.PARAMETER parameters
    The original test parameters hashtable (contains the expected result file paths).
.PARAMETER tenants
    Array of tenant IDs whose result files should be merged.
#>
function Merge-TenantTestResults {
    param(
        [Hashtable]$parameters,
        [string[]]$tenants
    )

    foreach ($resultKey in @("XUnitResultFileName", "JUnitResultFileName")) {
        if ($parameters.ContainsKey($resultKey) -and $parameters[$resultKey]) {
            $origFile = $parameters[$resultKey]
            $dir = [System.IO.Path]::GetDirectoryName($origFile)
            $name = [System.IO.Path]::GetFileNameWithoutExtension($origFile)
            $ext = [System.IO.Path]::GetExtension($origFile)

            $tenantFiles = @($tenants | ForEach-Object { Join-Path $dir "$name-$_$ext" })
            Merge-TestResultFiles -targetFile $origFile -sourceFiles $tenantFiles

            # Clean up per-tenant files
            $tenantFiles | Where-Object { Test-Path $_ } | ForEach-Object { Remove-Item $_ -Force }
        }
    }
}

<#
.SYNOPSIS
    Dispatches test apps in parallel across all available tenants in a BC container.
.DESCRIPTION
    Walks $appNamesToTest in order, dispatching each app onto a free tenant via background jobs.
    Waits for all jobs to complete, merges per-tenant result files, and returns whether all
    passed. The result is cached to a state file so subsequent calls (from the per-project
    override on the same job) can short-circuit.
.PARAMETER parameters
    Test parameters from Run-AlPipeline (containerName, tenant, credential, etc.). Mutated per
    job to set appName.
.PARAMETER scriptPath
    Path to the RunTestsInBcContainer.ps1 script to invoke in each background job.
.PARAMETER testType
    The test type (Legacy, UnitTest, etc.).
.PARAMETER appNamesToTest
    Ordered list of app names to dispatch. Each must be installed in the container.
.OUTPUTS
    [bool] True if every dispatched app passed; false if any failed.
#>
function Invoke-ParallelTestExecution {
    param(
        [Parameter(Mandatory=$true)]
        [Hashtable]$parameters,
        [Parameter(Mandatory=$true)]
        [string]$scriptPath,
        [Parameter(Mandatory=$true)]
        [string]$testType,
        [Parameter(Mandatory=$true)]
        [string[]]$appNamesToTest
    )

    # GitHub Actions provides a per-job temp directory ($RUNNER_TEMP) that is cleaned up between
    # jobs, so a stale state file from a previous run cannot corrupt the current run. Fall back
    # to $env:TEMP for local execution outside of CI.
    $tempDir = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { $env:TEMP }
    $stateFile = Join-Path $tempDir "parallelTests_$($parameters.containerName).json"

    # Short-circuit ONLY when a previous call ran to completion (wait+merge done). The
    # 'dispatched' flag is set before the foreach starts; if the call crashed mid-flight we must
    # NOT cache its half-baked result as success.
    if (Test-Path $stateFile) {
        try {
            $existing = Get-Content $stateFile -Raw | ConvertFrom-Json
            if ($existing.completed) {
                return [bool]$existing.finalResult
            }
        } catch {
            Write-Host "WARNING: Failed to parse state file '$stateFile' ($($_.Exception.Message)). Continuing fresh."
        }
    }

    $tenants = @(Get-AvailableBcTenants -containerName $parameters.containerName)
    Write-Host "Available tenants: $($tenants -join ', ')"

    # Build a name -> appId map so we can set extensionId per dispatch. Run-TestsInBcContainer
    # selects which app's tests to run via extensionId; appName is just descriptive. Without
    # this every job would re-run whichever extensionId Run-AlPipeline put on the parent's
    # $parameters.
    $appIdByName = @{}
    Get-BcContainerAppInfo -containerName $parameters.containerName -tenant $parameters.tenant -tenantSpecificProperties |
        Where-Object { $_.IsInstalled } |
        ForEach-Object { $appIdByName[$_.Name] = $_.AppId }

    # dispatched=true marks "we started the foreach" - lets concurrent reads notice an in-flight
    # run. completed=false stays false until wait+merge finish; only then is finalResult valid.
    $state = [PSCustomObject]@{ jobs = @(); dispatched = $true; completed = $false; finalResult = $false; hasFailures = $false }
    $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Force

    foreach ($appName in $appNamesToTest) {
        $appId = $appIdByName[$appName]
        if (-not $appId) {
            Write-Host "WARNING: Could not resolve appId for '$appName'; skipping"
            $state.hasFailures = $true
            continue
        }

        $tenant = Wait-ForFreeTenant -state $state -tenants $tenants
        Write-Host "Dispatching '$appName' (extensionId $appId) on tenant '$tenant' in background"

        $appParams = $parameters.Clone()
        $appParams["appName"] = $appName
        $appParams["extensionId"] = $appId
        $appParams.Remove("ReRun") | Out-Null

        $job = Start-TestJob -parameters $appParams -tenant $tenant -scriptPath $scriptPath -testType $testType
        $state.jobs = @($state.jobs) + @([PSCustomObject]@{ jobId = $job.Id; tenant = $tenant; appName = $appName })
    }

    Write-Host "All $($appNamesToTest.Count) apps dispatched. Waiting for completion..."
    $allPassed = Wait-ForAllTestJobs -state $state

    if ($state.hasFailures) {
        $allPassed = $false
    }

    Merge-TenantTestResults -parameters $parameters -tenants $tenants

    # Persist final result and mark complete so subsequent override invocations short-circuit
    # to this value (and not the placeholder we wrote before dispatch).
    $state.finalResult = $allPassed
    $state.completed = $true
    $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Force

    return $allPassed
}

<#
.SYNOPSIS
    Per-project Run-AlPipeline test override: dispatches the project's test apps in parallel
    across the container's tenants and caches the result for subsequent override invocations.
.DESCRIPTION
    Run-AlPipeline calls the per-project RunTestsInBcContainer.ps1 once per test app. The first
    call computes the bucket's app list and dispatches them all in parallel; subsequent calls in
    the same job short-circuit on the cached final result. Returns the cached result if there
    are no apps to run for the project's testType.
.PARAMETER parameters
    The Run-AlPipeline parameters hashtable (containerName, tenant, credential, etc.).
.OUTPUTS
    [bool] $true if all dispatched apps passed; $false otherwise.
#>
function Invoke-PerProjectTestRun {
    param(
        [Parameter(Mandatory=$true)]
        [Hashtable]$parameters
    )

    $cached = Get-CachedTestRunResult -ContainerName $parameters.containerName
    if ($null -ne $cached) { return $cached }

    $testType = Get-ALGoSetting -Key "testType"
    $country = Get-ALGoSetting -Key "country"
    $bucketNumber = if ($testType -eq "Legacy") { Get-ALGoSetting -Key "bucketNumber" } else { 0 }

    $installed = Get-InstalledTestAppNames -ContainerName $parameters.containerName -Tenant $parameters.tenant -Country $country
    $appNamesToTest = Get-AppNamesForBucket -InstalledTestAppNames $installed -TestType $testType -BucketNumber $bucketNumber

    if ($appNamesToTest.Count -eq 0) {
        Write-Host "No test apps to run for testType '$testType' in this project."
        return $true
    }

    Write-Host "Test apps to dispatch ($($appNamesToTest.Count)): $($appNamesToTest -join ', ')"

    $parameters["returnTrueIfAllPassed"] = $true
    $script = Join-Path $PSScriptRoot "RunTestsInBcContainer.ps1" -Resolve
    return (. $script -parameters $parameters -TestType $testType -AppNamesToTest $appNamesToTest)
}

Export-ModuleMember -Function Invoke-ParallelTestExecution, Get-AvailableBcTenants, Get-CachedTestRunResult, Get-InstalledTestAppNames, Get-AppNamesForBucket, Invoke-PerProjectTestRun
