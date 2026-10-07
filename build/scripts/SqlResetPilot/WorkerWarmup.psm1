function Test-WorkerWarmupExperiment {
    return ($env:GITHUB_REPOSITORY -eq 'microsoft/BCApps' -and
        $env:GITHUB_REF -eq 'refs/heads/features/646383-sql-api-worker-warmup-comparison' -and
        $env:GITHUB_EVENT_NAME -eq 'workflow_dispatch' -and $env:GITHUB_RUN_ATTEMPT -eq '1' -and
        $env:BC_SQL_PILOT_ARM -eq 'control' -and $env:BC_SQL_API_EXPERIMENT -in @('control', 'workerwarmup') -and
        $env:BC_SQL_PILOT_COUNTRY -in @('W1', 'DE') -and $env:BC_SQL_PILOT_TRIAL -match '^[1-5]$' -and
        $env:GITHUB_RUN_ID -match '^\d{1,20}$')
}

function Get-WorkerWarmupCell {
    foreach ($trial in 1..5) {
        $countries = if ($trial % 2) { @('W1', 'DE') } else { @('DE', 'W1') }
        $arms = if ($trial % 2) { @('control', 'workerwarmup') } else { @('workerwarmup', 'control') }
        foreach ($country in $countries) {
            foreach ($arm in $arms) {
                [PSCustomObject]@{ experiment = $arm; country = $country; trial = $trial }
            }
        }
    }
}

function Initialize-WorkerWarmup {
    param([hashtable]$Parameters, [hashtable]$AppIdByName)
    if (-not (Test-WorkerWarmupExperiment) -or $Parameters.companyName -ne 'My Company' -or
        $Parameters.tenant -ne 'default' -or -not $Parameters.JUnitResultFileName -or
        $Parameters.credential -isnot [PSCredential] -or
        $Parameters.containerName -ne "bcbuildprojectsTestApps$($env:BC_SQL_PILOT_COUNTRY)Trial$($env:BC_SQL_PILOT_TRIAL)$($env:BC_SQL_API_EXPERIMENT)$($env:GITHUB_RUN_ID)") {
        throw 'Worker warmup requires the exact owned company/container and evidence configuration.'
    }
    $appId = [string]$AppIdByName['System Application Test']
    if ($appId -notmatch '^[0-9a-fA-F-]{36}$') { throw 'Pinned System Application Test must already be installed in both arms.' }
    $script:workerWarmup = @{
        Parameters = $Parameters.Clone(); AppId = $appId; Ready = @{}
        StartedUtc = [datetime]::UtcNow.ToString('o')
    }
    @{
        startedUtc = $script:workerWarmup.StartedUtc
        startedTicks = [Diagnostics.Stopwatch]::GetTimestamp()
        frequency = [Diagnostics.Stopwatch]::Frequency
        boundary = 'After mounted-tenant/app inventory, before clean discovery'
        appName = 'System Application Test'; appId = $appId
        codeunit = 135070; method = 'GetHostTest'; testRunner = 130450; isolation = 'Codeunit'
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

function Assert-WorkerWarmupResult {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw 'Warmup did not produce JUnit evidence.' }
    [xml]$xml = Get-Content $Path -Raw -ErrorAction Stop
    $suites = @($xml.SelectNodes('/testsuites/testsuite'))
    $cases = @($xml.SelectNodes('/testsuites/testsuite/testcase'))
    if ($suites.Count -ne 1 -or $cases.Count -ne 1 -or
        $xml.SelectNodes('//testcase').Count -ne 1 -or $xml.SelectNodes('//testsuite').Count -ne 1 -or
        $cases[0].GetAttribute('classname') -cne '135070 Uri Test' -or
        $cases[0].GetAttribute('name') -cne 'GetHostTest' -or
        $xml.SelectNodes('//failure | //error | //skipped').Count -ne 0 -or
        ($cases[0].HasAttribute('result') -and $cases[0].GetAttribute('result') -notin @('Success', 'Pass', 'Passed'))) {
        throw 'Warmup must execute exactly 135070 Uri Test.GetHostTest successfully, without skips.'
    }
    foreach ($attribute in @('failures', 'errors', 'skipped')) {
        if ($suites[0].HasAttribute($attribute) -and $suites[0].GetAttribute($attribute) -ne '0') {
            throw 'Warmup suite summary is not an unambiguous success.'
        }
    }
    return [string]$cases[0].GetAttribute('time')
}

function Invoke-WorkerWarmupTest {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseUsingScopeModifierInNewRunspaces', '',
        Justification = 'The child receives explicit ArgumentList values through its param block, not parent-scope variables.')]
    [CmdletBinding()]
    param([hashtable]$Parameters, [string]$LogPath)
    $helper = Get-Module BcContainerHelper -ErrorAction Stop | Select-Object -First 1
    $job = $null
    try {
        $job = Start-Job -ScriptBlock {
            param($helperPath, $selection)
            $ErrorActionPreference = 'Stop'
            Import-Module $helperPath -DisableNameChecking
            $passed = Run-TestsInBcContainer @selection
            if ($passed -ne $true) { throw 'Selected warmup method failed.' }
        } -ArgumentList $helper.Path, $Parameters
        $finished = Wait-Job -Job $job -Timeout 180
        if (-not $finished -or $job.State -ne 'Completed') { throw 'Warmup worker failed or exceeded its 180-second bound.' }
        Receive-Job -Job $job -ErrorAction Stop *>&1 | Out-String | Set-Content $LogPath
        if ((Get-Content $LogPath -Raw) -match 'ERROR DIALOG|database command was cancelled') {
            throw 'Warmup client reported cancellation.'
        }
    } finally {
        if ($job) {
            if ($job.State -in @('Running', 'NotStarted', 'Blocked')) { Stop-Job -Job $job }
            try {
                Receive-Job -Job $job -ErrorAction Continue *>&1 | Out-String | Add-Content $LogPath
            } finally { Remove-Job -Job $job -Force }
        }
    }
}

function Invoke-WorkerRemountWarmup {
    param([string]$Tenant, [int]$NextCodeunitId = 0)
    if (-not (Test-WorkerWarmupExperiment) -or -not $script:workerWarmup) { throw 'Worker warmup was not initialized.' }
    $reset = Get-WorkerWarmupReset -Tenant $Tenant
    if (($NextCodeunitId -eq 0) -ne ($reset.plan.Template -eq 'default')) { throw 'Remount purpose differs from its protected template.' }
    $identity = "$Tenant-g$($reset.plan.Generation)-cu$NextCodeunitId"
    $directory = Join-Path $env:BC_SQL_PILOT_OUTPUT "worker-warmup\$identity"
    if (Test-Path $directory) { throw 'A remount may be warmed at most once; evidence cannot be replaced.' }
    $null = New-Item -ItemType Directory -Path $directory -Force
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $record = @{
        identity = $identity; tenant = $Tenant; generation = $reset.plan.Generation; nextCodeunit = $NextCodeunitId
        resetCompletedUtc = $reset.utc; template = $reset.plan.Template; startedUtc = [datetime]::UtcNow.ToString('o')
        experiment = $env:BC_SQL_API_EXPERIMENT; executed = $false; executionAttempted = $false; passed = $false
        operation = '135070 Uri Test.GetHostTest'; runner = 130450; isolation = 'Codeunit'; attempts = 0
    }
    try {
        if ($env:BC_SQL_API_EXPERIMENT -eq 'workerwarmup') {
            $record.attempts = 1
            $record.executionAttempted = $true
            $source = $script:workerWarmup.Parameters
            $selection = @{}
            foreach ($key in @('containerName', 'credential', 'companyName', 'connectFromHost', 'usePublicDnsName', 'culture', 'timezone')) {
                if ($source.ContainsKey($key)) { $selection[$key] = $source[$key] }
            }
            # Keep runner output beneath the existing shared result root; copy it to separate audit evidence.
            $resultDirectory = Join-Path (Split-Path $source.JUnitResultFileName -Parent) "worker-warmup\$identity"
            if (Test-Path $resultDirectory) { throw 'Warmup result directory already exists.' }
            $null = New-Item -ItemType Directory -Path $resultDirectory -Force
            $selection.tenant = $Tenant
            $selection.extensionId = $script:workerWarmup.AppId
            $selection.testCodeunit = '135070'
            $selection.testFunction = 'GetHostTest'
            $selection.testSuite = 'WWARMUP'
            # The pinned method has no TestType/RequiredTestIsolation annotation.
            # Do not filter it out by inventing a category; the explicit runner provides isolation.
            $selection.testType = ''
            $selection.requiredTestIsolation = ''
            $selection.testRunnerCodeunitId = '130450'
            $selection.disabledTests = @()
            $selection.renewClientContextBetweenTests = $true
            $selection.returnTrueIfAllPassed = $true
            $selection.restartContainerAndRetry = $false
            $selection.JUnitResultFileName = Join-Path $resultDirectory 'Warmup.junit.xml'
            try {
                Invoke-WorkerWarmupTest -Parameters $selection -LogPath (Join-Path $directory 'worker.log')
            } finally {
                if (Test-Path $selection.JUnitResultFileName) {
                    Copy-Item $selection.JUnitResultFileName (Join-Path $directory 'Warmup.junit.xml')
                }
            }
            $record.caseSeconds = Assert-WorkerWarmupResult -Path (Join-Path $directory 'Warmup.junit.xml')
            $record.executed = $true
        } else {
            $record.operation = 'none (paired control)'
        }
        $record.passed = $true
        $script:workerWarmup.Ready[$Tenant] = @{ Generation = $reset.plan.Generation; Codeunit = $NextCodeunitId; Consumed = $false }
    } catch {
        $record.errorType = $_.Exception.GetType().FullName
        throw
    } finally {
        $record.completedUtc = [datetime]::UtcNow.ToString('o')
        $record.elapsedMilliseconds = $watch.Elapsed.TotalMilliseconds
        $record | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $directory 'warmup.json')
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
        ($env:BC_SQL_API_EXPERIMENT -eq 'workerwarmup' -and (-not $_.executed -or $_.attempts -ne 1)) -or
        ($env:BC_SQL_API_EXPERIMENT -eq 'control' -and ($_.executed -or $_.attempts -ne 0))
    })
    return ($records.Count -eq 22 -and $selectionMatches -and $bad.Count -eq 0)
}
