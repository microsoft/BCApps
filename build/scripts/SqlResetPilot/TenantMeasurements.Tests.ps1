Describe 'Tenant-count performance persistence' {
    BeforeEach {
        $script:savedWorkspace=$env:GITHUB_WORKSPACE
        $env:GITHUB_WORKSPACE=$TestDrive
        $script:directory=Join-Path $TestDrive 'sql-reset-pilot-output'
        New-Item -ItemType Directory $script:directory -Force | Out-Null
    }
    AfterEach { $env:GITHUB_WORKSPACE=$script:savedWorkspace }
    It 'marks missing evidence incomplete instead of zero-duration success' {
        & (Join-Path $PSScriptRoot 'TenantMeasurements.ps1') -Phase Finish
        $result=Get-Content (Join-Path $script:directory 'performance.json') -Raw | ConvertFrom-Json
        $result.measurementComplete | Should -BeFalse
        $result.totalMilliseconds | Should -BeNullOrEmpty
        $result.measurementErrors.Count | Should -BeGreaterThan 0
    }
    It 'persists full case timings, target coverage and measured phases separately' {
        $clock=[Diagnostics.Stopwatch]::GetTimestamp()
        @{ticks=$clock-10000;frequency=[Diagnostics.Stopwatch]::Frequency;utc=[datetime]::UtcNow.ToString('o')}|
            ConvertTo-Json | Set-Content (Join-Path $script:directory 'cell-clock.json')
        @{phase='execution-including-discovery-template-resets';elapsedMilliseconds=100;startedTicks=$clock;
            startedUtc=[datetime]::UtcNow.ToString('o');completed=$true}|
            ConvertTo-Json -Compress | Set-Content (Join-Path $script:directory 'phase-timing.jsonl')
        @{phase='reset-complete';observation=@{elapsedMilliseconds=30}}|
            ConvertTo-Json -Compress | Set-Content (Join-Path $script:directory 'reset-timeline.jsonl')
        @{measurementComplete=$true}|ConvertTo-Json|Set-Content (Join-Path $script:directory 'resource-status.json')
        $cases='<testcase name="CapabilitiesProjectsEnabledViaAPI" time="0.125" />'
        foreach($index in 1..252){$cases+="<testcase name=`"Case$index`" time=`"0.1`" />"}
        "<testsuites><testsuite name=`"148318 Capabilities`">$cases</testsuite></testsuites>"|
            Set-Content (Join-Path $script:directory 'final-junit.xml')
        & (Join-Path $PSScriptRoot 'TenantMeasurements.ps1') -Phase Finish
        $result=Get-Content (Join-Path $script:directory 'performance.json') -Raw | ConvertFrom-Json
        $result.measurementComplete | Should -BeTrue
        $result.executionMilliseconds | Should -Be 100
        $result.resetMilliseconds | Should -Be 30
        $result.cases.Count | Should -Be 253
        $result.apiTargetCases.Count | Should -Be 1
        $result.apiTargetCases[0].seconds | Should -Be '0.125'
        $result.setupMilliseconds | Should -BeGreaterOrEqual 0
        $result.totalMilliseconds | Should -BeGreaterOrEqual 0
    }
}
