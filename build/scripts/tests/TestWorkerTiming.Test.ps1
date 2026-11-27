Describe 'BCApps test worker timing' {
    BeforeAll {
        $scripts = Split-Path $PSScriptRoot
        $timingModule = Import-Module (Join-Path $scripts 'ParallelTestExecution.psm1') -PassThru -Force
        $fixture = Join-Path (Convert-Path $TestDrive) 'worker'
        New-Item -ItemType Directory -Path $fixture, (Join-Path $fixture 'TestTolerance') | Out-Null
        $wrapperPath = Join-Path $fixture 'RunTestsInBcContainer.ps1'
        Copy-Item (Join-Path $scripts 'RunTestsInBcContainer.ps1') $wrapperPath
        Set-Content (Join-Path $fixture 'EnlistmentHelperFunctions.psm1') ''
        Set-Content (Join-Path $fixture 'ParallelTestExecution.psm1') @'
function Get-DisabledTestsForApp {
    param($AppName)
    if ($env:BCAPPS_TIMING_CASE -eq 'setup-then-helper-error') { ConvertFrom-Json '{' }
    @()
}
function Test-TransientTestFailure { param($Output) $false }
'@
        Set-Content (Join-Path $fixture 'TestTolerance\TestTolerance.psm1') @'
function Get-ToleranceBranch { 'main' }
function Receive-UnstableTestsArtifact {
    param($Branch, $OutputDirectory)
    if ($env:BCAPPS_TIMING_CASE -eq 'download-error') { throw 'download-error-sensitive-sentinel' }
    return 'artifact-url-sensitive-sentinel'
}
function Test-ShouldTolerateFailures {
    param($TestResultsPath, $UnstableTestsPath)
    return $env:BCAPPS_TIMING_CASE -eq 'tolerated'
}
'@
        $helperPath = Join-Path $fixture 'BcContainerHelper.psm1'
        Set-Content $helperPath @'
Start-Sleep -Milliseconds 150
function Start-Transcript {
    param($Path, [switch]$Force)
    $text = if ($env:BCAPPS_TIMING_CASE -in @('cancelled', 'tolerated', 'download-error')) {
        'ERROR DIALOG: transcript-sensitive-sentinel'
    } else {
        'transcript-sensitive-sentinel'
    }
    Set-Content -LiteralPath $Path -Value $text
}
function Stop-Transcript {}
function Run-TestsInBcContainer {
    param($appName, $extensionId, $tenant, $disabledTests, $renewClientContextBetweenTests, $JUnitResultFileName, $credential)
    if ($env:BCAPPS_TIMING_CASE -in @('helper-error', 'timing-has-race-text', 'setup-then-helper-error')) { throw 'helper-error-sensitive-sentinel' }
    return $true
}
'@
        Import-Module $helperPath -Force -DisableNameChecking
        if ((Get-Module BcContainerHelper | Select-Object -First 1).Path -ne $helperPath) {
            throw 'The worker test must use the stub BcContainerHelper module.'
        }
    }

    AfterAll {
        Remove-Module BcContainerHelper -ErrorAction SilentlyContinue
    }

    It 'correlates a normal scheduler wait, worker timestamps observed before replay, and collection' {
        $records = & $timingModule {
            param($wrapperPath, $resultDirectory)
            $state = [pscustomobject]@{ jobs = @(); retried = @{}; hasFailures = $false }
            $timing = New-TestWorkerTiming -AppName 'Timing Tests' -ItemType app -DispatchKind normal
            $tenant = Wait-ForTestDispatchTenant -State $state -Tenants @('tenant2') -Timing $timing
            Start-TestAppDispatch -Parameters @{
                JUnitResultFileName = Join-Path $resultDirectory 'results-sensitive-sentinel.xml'
                credential = 'credential-sensitive-sentinel'
            } -AppName 'Timing Tests' -AppId 'timing-tests-id' -Tenant $tenant -ScriptPath $wrapperPath `
                -TestType Legacy -State $state -Timing $timing
            $job = Get-Job -Id $state.jobs[0].jobId
            try {
                Wait-Job $job -Timeout 45 | Out-Null
                [DateTime]::UtcNow
                Start-Sleep -Milliseconds 150
                Get-FreeTenants -state $state -tenants @('tenant2')
            } finally {
                if (Get-Job -Id $job.Id -ErrorAction SilentlyContinue) { Remove-Job $job -Force }
            }
        } $wrapperPath $fixture 6>&1

        $lines = @($records | ForEach-Object { "$_" } | Where-Object { $_ -like 'BCAppsTestTiming *' })
        $events = @($lines | ForEach-Object { $_.Substring('BCAppsTestTiming '.Length) | ConvertFrom-Json })
        ($events.event -join ',') | Should Be 'tenant-wait,dispatch,job-launch,collection-start,worker-start,worker-helper-import,worker-wrapper-imports,worker-setup,transcript-start,helper-call,transcript-diagnostics,tolerance,worker-finish,collected'
        @($events.dispatchId | Select-Object -Unique).Count | Should Be 1
        $events[0].dispatchId | Should Match '^[a-f0-9]{32}$'
        @($events.app | Select-Object -Unique) -join ',' | Should Be 'Timing Tests'
        @($events.tenant | Select-Object -Unique) -join ',' | Should Be 'tenant2'
        @($events.dispatchKind | Select-Object -Unique) -join ',' | Should Be 'normal'
        @($events.itemType | Select-Object -Unique) -join ',' | Should Be 'app'
        $workerStart = $events | Where-Object event -eq 'worker-start'
        $helperImport = $events | Where-Object event -eq 'worker-helper-import'
        $jobLaunch = $events | Where-Object event -eq 'job-launch'
        $workerFinish = $events | Where-Object event -eq 'worker-finish'
        $collectionStart = $events | Where-Object event -eq 'collection-start'
        $collected = $events | Where-Object event -eq 'collected'
        ($workerStart.pid -ne $PID) | Should Be $true
        $collected.pid | Should Be $PID
        $jobLaunch.pid | Should Be $PID
        ($jobLaunch.elapsedMs -ge 0) | Should Be $true
        ($helperImport.elapsedMs -ge 100) | Should Be $true
        $beforeReceive = $records | Where-Object { $_ -is [DateTime] }
        ([DateTimeOffset]$workerFinish.utc -le $beforeReceive) | Should Be $true
        ([DateTimeOffset]$collectionStart.utc -gt $beforeReceive) | Should Be $true
        ([DateTimeOffset]$collected.utc -ge [DateTimeOffset]$collectionStart.utc) | Should Be $true
        $workerFinish.outcome | Should Be 'passed'
        $collected.outcome | Should Be 'passed'
        $collected.jobState | Should Be 'Completed'
        @($records | Where-Object { $_ -is [string] -and $_ -eq 'tenant2' }).Count | Should Be 1
        ($lines -join "`n") | Should Not Match 'sensitive-sentinel'
    }

    It 'keeps the existing test outcome for worker case <Case>' -TestCases @(
        @{ Case = 'cancelled'; IsPr = $false; JobOutcome = 'Failed'; HelperOutcome = 'passed'; DiagnosticOutcome = 'cancelled'; DownloadOutcome = ''; ToleranceOutcome = 'skipped'; WorkerOutcome = 'failed' }
        @{ Case = 'tolerated'; IsPr = $true; JobOutcome = 'Passed'; HelperOutcome = 'passed'; DiagnosticOutcome = 'cancelled'; DownloadOutcome = 'completed'; ToleranceOutcome = 'tolerated'; WorkerOutcome = 'passed' }
        @{ Case = 'download-error'; IsPr = $true; JobOutcome = 'Failed'; HelperOutcome = 'passed'; DiagnosticOutcome = 'cancelled'; DownloadOutcome = 'error'; ToleranceOutcome = ''; WorkerOutcome = 'error' }
        @{ Case = 'helper-error'; IsPr = $false; JobOutcome = 'Failed'; HelperOutcome = 'error'; DiagnosticOutcome = 'completed'; DownloadOutcome = ''; ToleranceOutcome = 'skipped'; WorkerOutcome = 'failed' }
        @{ Case = 'timing-has-race-text'; IsPr = $false; JobOutcome = 'Failed'; HelperOutcome = 'error'; DiagnosticOutcome = 'completed'; DownloadOutcome = ''; ToleranceOutcome = 'skipped'; WorkerOutcome = 'failed' }
        @{ Case = 'setup-then-helper-error'; IsPr = $false; JobOutcome = 'Failed'; HelperOutcome = 'error'; DiagnosticOutcome = 'completed'; DownloadOutcome = ''; ToleranceOutcome = 'skipped'; WorkerOutcome = 'failed' }
    ) {
        param($Case, $IsPr, $JobOutcome, $HelperOutcome, $DiagnosticOutcome, $DownloadOutcome, $ToleranceOutcome, $WorkerOutcome)
        $previousCase = $env:BCAPPS_TIMING_CASE
        $previousEvent = $env:GITHUB_EVENT_NAME
        try {
            $env:BCAPPS_TIMING_CASE = $Case
            $env:GITHUB_EVENT_NAME = if ($IsPr) { 'pull_request' } else { 'push' }
            $appName = if ($Case -eq 'timing-has-race-text') { 'Cannot open page 130455' } else { 'Timing Tests' }
            $records = & $timingModule {
                param($wrapperPath, $resultDirectory, $appName)
                $timing = New-TestWorkerTiming -AppName $appName -ItemType app -DispatchKind rerun
                $job = Start-TestJob -parameters @{
                    appName = $appName
                    JUnitResultFileName = Join-Path $resultDirectory 'results-sensitive-sentinel.xml'
                } -tenant tenant2 -scriptPath $wrapperPath -testType Legacy -Timing $timing
                try {
                    Wait-Job $job -Timeout 45 | Out-Null
                    if ($env:BCAPPS_TIMING_CASE -eq 'setup-then-helper-error') { $ErrorActionPreference = 'Stop' }
                    Receive-TestJobResult -Entry @{ appName = $appName; tenant = 'tenant2'; timing = $timing } -Job $job -Retried @{}
                } finally {
                    if (Get-Job -Id $job.Id -ErrorAction SilentlyContinue) { Remove-Job $job -Force }
                }
            } $wrapperPath $fixture $appName 6>&1
        } finally {
            $env:BCAPPS_TIMING_CASE = $previousCase
            $env:GITHUB_EVENT_NAME = $previousEvent
        }

        ($records | Where-Object { $_.PSObject.Properties['JobState'] }).Outcome | Should Be $JobOutcome
        $lines = @($records | ForEach-Object { "$_" } | Where-Object { $_ -like 'BCAppsTestTiming *' })
        $events = @($lines | ForEach-Object { $_.Substring('BCAppsTestTiming '.Length) | ConvertFrom-Json })
        ($events | Where-Object event -eq 'helper-call').outcome | Should Be $HelperOutcome
        ($events | Where-Object event -eq 'transcript-diagnostics').outcome | Should Be $DiagnosticOutcome
        [string]($events | Where-Object event -eq 'unstable-tests-download').outcome | Should Be $DownloadOutcome
        [string]($events | Where-Object event -eq 'tolerance').outcome | Should Be $ToleranceOutcome
        ($events | Where-Object event -eq 'worker-finish').outcome | Should Be $WorkerOutcome
        ($lines -join "`n") | Should Not Match 'sensitive-sentinel'
    }
}
