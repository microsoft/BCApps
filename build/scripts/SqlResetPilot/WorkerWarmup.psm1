function Test-WorkerWarmupExperiment {
    return ($env:GITHUB_REPOSITORY -eq 'microsoft/BCApps' -and
        $env:GITHUB_REF -eq 'refs/heads/features/646383-sql-api-worker-warmup-comparison' -and
        $env:GITHUB_EVENT_NAME -eq 'workflow_dispatch' -and $env:GITHUB_RUN_ATTEMPT -eq '1' -and
        $env:BC_SQL_PILOT_ARM -eq 'control' -and $env:BC_SQL_API_EXPERIMENT -in @('control', 'workerwarmup', 'navreadiness') -and
        $env:BC_SQL_PILOT_COUNTRY -in @('W1', 'DE') -and $env:BC_SQL_PILOT_TRIAL -match '^[1-5]$' -and
        $env:GITHUB_RUN_ID -match '^\d{1,20}$')
}

function Get-WorkerWarmupCell {
    foreach ($trial in 1..5) {
        $countries = if ($trial % 2) { @('W1', 'DE') } else { @('DE', 'W1') }
        $arms = if ($trial % 2) { @('control', 'workerwarmup', 'navreadiness') } else { @('navreadiness', 'workerwarmup', 'control') }
        foreach ($country in $countries) {
            foreach ($arm in $arms) {
                [PSCustomObject]@{ experiment = $arm; country = $country; trial = $trial }
            }
        }
    }
}

function Initialize-WorkerWarmup {
    param(
        [hashtable]$Parameters, [hashtable]$AppIdByName, [string[]]$AppNames,
        [string[]]$Tenants, [string]$ScriptPath, [string]$TestType,
        [Parameter(Mandatory)][scriptblock]$WarmupAction,
        [Parameter(Mandatory)][scriptblock]$ProbeAction
    )
    if (-not (Test-WorkerWarmupExperiment) -or $Parameters.companyName -ne 'My Company' -or
        $Parameters.tenant -ne 'default' -or -not $Parameters.JUnitResultFileName -or
        $Parameters.credential -isnot [PSCredential] -or $TestType -ne 'IntegrationTest' -or
        $AppNames.Count -le 1 -or $AppNames[0] -ne 'System Application Test Library' -or
        @($Tenants | Sort-Object -Unique).Count -ne 4 -or
        (Compare-Object @('default', 'tenant2', 'tenant3', 'tenant4') @($Tenants | Sort-Object)) -or
        $Parameters.containerName -ne "bcbuildprojectsTestApps$($env:BC_SQL_PILOT_COUNTRY)Trial$($env:BC_SQL_PILOT_TRIAL)$($env:BC_SQL_API_EXPERIMENT)$($env:GITHUB_RUN_ID)") {
        throw 'Worker warmup requires the exact original first app, company, tenants and owned container.'
    }
    $appId = [string]$AppIdByName[$AppNames[0]]
    if ($appId -notmatch '^[0-9a-fA-F-]{36}$') { throw 'Pinned first warmup app must already be installed in every arm.' }
    $script:workerWarmup = @{
        Parameters = $Parameters.Clone(); AppIdByName = $AppIdByName.Clone(); AppNames = @($AppNames)
        Tenants = @($Tenants); ScriptPath = $ScriptPath; TestType = $TestType
        WarmupAction = $WarmupAction; ProbeAction = $ProbeAction; Ready = @{}; PostMount = @{}
        StartedUtc = [datetime]::UtcNow.ToString('o')
    }
    @{
        startedUtc = $script:workerWarmup.StartedUtc; startedTicks = [Diagnostics.Stopwatch]::GetTimestamp()
        frequency = [Diagnostics.Stopwatch]::Frequency
        boundary = 'After mounted-tenant/app inventory, before clean discovery'
        appName = $AppNames[0]; appId = $appId; testType = $TestType
        operation = 'Existing first-app Invoke-WarmupDispatch; empty XML is acceptable'
        inheritedBehavior = 'Same app runner/client behavior and 5s dispatch spacing; no added session or test retries'
    } | ConvertTo-Json | Set-Content (Join-Path $env:BC_SQL_PILOT_OUTPUT 'worker-execution-start.json')
}

function Get-WorkerWarmupReset {
    param([string]$Tenant)
    if ($Tenant -notin @('tenant2', 'tenant3', 'tenant4')) { throw 'Only the three owned secondary workers are eligible.' }
    $records = @(Get-Content (Join-Path $env:BC_SQL_PILOT_OUTPUT 'reset-timeline.jsonl') -ErrorAction Stop |
        ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.plan.Tenant -eq $Tenant })
    if (-not $records.Count -or $records[-1].phase -ne 'reset-complete' -or
        $records[-1].plan.Destination -ne $Tenant -or $records[-1].plan.Generation -lt 1 -or
        $records[-1].plan.Template -notin @('default', 'default-test-template')) {
        throw 'No complete owned pristine remount is available for this worker.'
    }
    return $records[-1]
}

function Invoke-WorkerReadinessPhase {
    param([hashtable]$Record, [string]$Phase, [scriptblock]$Action)
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $observation = @{ phase = $Phase; startedUtc = [datetime]::UtcNow.ToString('o'); passed = $false }
    try {
        & $Action | Out-Null
        $observation.passed = $true
    } catch {
        $Record.failedPhase = $Phase
        $Record.failureCategory = 'readiness_failure'
        $observation.errorType = $_.Exception.GetType().FullName
        throw
    } finally {
        $observation.completedUtc = [datetime]::UtcNow.ToString('o')
        $observation.elapsedMilliseconds = $watch.Elapsed.TotalMilliseconds
        $Record.phases += $observation
    }
}

function Invoke-WorkerPostMountDelay {
    param([string]$Tenant)
    if (-not (Test-WorkerWarmupExperiment) -or -not $script:workerWarmup) { throw 'Worker warmup was not initialized.' }
    $reset = Get-WorkerWarmupReset $Tenant
    $record = @{
        tenant = $Tenant; generation = $reset.plan.Generation; resetCompletedUtc = $reset.utc
        experiment = $env:BC_SQL_API_EXPERIMENT; phases = @(); passed = $false
        seconds = $(if ($env:BC_SQL_API_EXPERIMENT -eq 'navreadiness') { 30 } else { 0 })
    }
    $path = Join-Path $env:BC_SQL_PILOT_OUTPUT "worker-postmount-$Tenant-g$($reset.plan.Generation).json"
    if (Test-Path $path) { throw 'A remount may receive postmount pacing only once.' }
    try {
        if ($record.seconds) {
            Invoke-WorkerReadinessPhase $record 'postmount-delay' { Start-Sleep -Seconds 30 }
        }
        $record.passed = $true
        $script:workerWarmup.PostMount[$Tenant] = $record
    } finally { $record | ConvertTo-Json -Depth 8 | Set-Content $path }
}

function Invoke-WorkerRemountWarmup {
    param([string]$Tenant, [int]$NextCodeunitId = 0)
    if (-not (Test-WorkerWarmupExperiment) -or -not $script:workerWarmup) { throw 'Worker warmup was not initialized.' }
    $reset = Get-WorkerWarmupReset -Tenant $Tenant
    if (($NextCodeunitId -eq 0) -ne ($reset.plan.Template -eq 'default')) { throw 'Remount purpose differs from its protected template.' }
    $postMount = $script:workerWarmup.PostMount[$Tenant]
    if (-not $postMount -or -not $postMount.passed -or $postMount.generation -ne $reset.plan.Generation) {
        throw 'Warmup requires the matching completed serial postmount phase.'
    }
    $identity = "$Tenant-g$($reset.plan.Generation)-cu$NextCodeunitId"
    $directory = Join-Path $env:BC_SQL_PILOT_OUTPUT "worker-warmup\$identity"
    if (Test-Path $directory) { throw 'A remount may be warmed at most once; evidence cannot be replaced.' }
    $null = New-Item -ItemType Directory -Path $directory -Force
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $record = @{
        identity = $identity; tenant = $Tenant; generation = $reset.plan.Generation; nextCodeunit = $NextCodeunitId
        resetCompletedUtc = $reset.utc; template = $reset.plan.Template; startedUtc = [datetime]::UtcNow.ToString('o')
        experiment = $env:BC_SQL_API_EXPERIMENT; executed = $false; executionAttempted = $false; passed = $false
        app = $script:workerWarmup.AppNames[0]; appId = $script:workerWarmup.AppIdByName[$script:workerWarmup.AppNames[0]]
        testType = $script:workerWarmup.TestType; emptyWarmupTestsAllowed = $true; readinessGuarantee = $false
        operation = 'Existing first-app dispatch'; attempts = 0; probeAttempts = 0; phases = @(); postMount = $postMount
    }
    try {
        if ($env:BC_SQL_API_EXPERIMENT -ne 'control') {
            $record.attempts = 1
            $record.executionAttempted = $true
            Invoke-WorkerReadinessPhase $record 'app-warmup' {
                & $script:workerWarmup.WarmupAction $script:workerWarmup $Tenant $directory
            }
            $record.executed = $true
            if ($env:BC_SQL_API_EXPERIMENT -eq 'navreadiness') {
                $record.probeAttempts = 1
                Invoke-WorkerReadinessPhase $record 'companies-probe' {
                    & $script:workerWarmup.ProbeAction $script:workerWarmup.Parameters $Tenant
                }
                Invoke-WorkerReadinessPhase $record 'pretest-delay' { Start-Sleep -Seconds 30 }
            }
        } else { $record.operation = 'none (paired control)' }
        $record.passed = $true
        $script:workerWarmup.Ready[$Tenant] = @{ Generation = $reset.plan.Generation; Codeunit = $NextCodeunitId; Consumed = $false }
    } finally {
        $record.completedUtc = [datetime]::UtcNow.ToString('o')
        $record.elapsedMilliseconds = $watch.Elapsed.TotalMilliseconds
        $record | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $directory 'warmup.json')
    }
}

function Assert-WorkerWarmupReady {
    param([string]$Tenant, [int]$CodeunitId)
    $reset = Get-WorkerWarmupReset -Tenant $Tenant
    $ready = $script:workerWarmup.Ready[$Tenant]
    if (-not $ready -or $ready.Consumed -or $ready.Generation -ne $reset.plan.Generation -or $ready.Codeunit -ne $CodeunitId) {
        throw 'Codeunit dispatch has no matching successful single-attempt remount preflight.'
    }
    $ready.Consumed = $true
    @{ tenant = $Tenant; generation = $ready.Generation; codeunit = $CodeunitId; utc = [datetime]::UtcNow.ToString('o') } |
        ConvertTo-Json -Compress | Add-Content (Join-Path $env:BC_SQL_PILOT_OUTPUT 'worker-dispatches.jsonl')
}

function Test-WorkerWarmupComplete {
    $records = @(Get-ChildItem (Join-Path $env:BC_SQL_PILOT_OUTPUT 'worker-warmup') -Filter warmup.json -Recurse -File |
        ForEach-Object { Get-Content $_.FullName -Raw | ConvertFrom-Json })
    $expected = @(0,139700,139702,139703,139706,139725,139726,139732,139739,139742,139745,139802,139803,139806,139826,139832,139854,139972,139780,148315,148318,148343)
    $selectionMatches = -not (Compare-Object @($expected | Sort-Object) @($records.nextCodeunit | Sort-Object))
    $bad = @($records | Where-Object {
        -not $_.passed -or
        ($env:BC_SQL_API_EXPERIMENT -ne 'control' -and (-not $_.executed -or $_.attempts -ne 1)) -or
        ($env:BC_SQL_API_EXPERIMENT -eq 'navreadiness' -and $_.probeAttempts -ne 1) -or
        ($env:BC_SQL_API_EXPERIMENT -ne 'navreadiness' -and $_.probeAttempts -ne 0) -or
        ($env:BC_SQL_API_EXPERIMENT -eq 'control' -and ($_.executed -or $_.attempts -ne 0))
    })
    return ($records.Count -eq 22 -and $selectionMatches -and $bad.Count -eq 0)
}
