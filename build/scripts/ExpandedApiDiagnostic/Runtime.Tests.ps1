BeforeAll {
    $script:root = $PSScriptRoot
    $script:fixture = Join-Path $root ".runtime-$([guid]::NewGuid().ToString('N'))"
    $null = New-Item -ItemType Directory -Path $fixture
    $script:helperPath = Join-Path $fixture 'BcContainerHelper.psm1'
    # In-process and child-process fake BCH. These tests execute orchestration,
    # files, transcripts and jobs, never an AL compiler, SQL command or NST.
    Set-Content $helperPath @'
$bcContainerHelperVersion = '6.1.19-preview2811389'
$script:remaining = $true
function Test-BcContainer { param($containerName) $script:remaining }
function Remove-BcContainer { param($containerName) $script:remaining = $false }
function Get-BcContainerServerConfiguration { param($ContainerName) @{Multitenant='true';DatabaseName='app'} }
function Get-BcContainerEventLog { param($containerName,[switch]$doNotOpen) Join-Path $env:GITHUB_WORKSPACE 'fake.evtx' }
function Get-BcContainerAppInfo {
    param($containerName,$tenant,[switch]$tenantSpecificProperties)
    $p = Get-Content (Join-Path $env:GITHUB_WORKSPACE 'expanded-api-output\packages.json') -Raw | ConvertFrom-Json
    foreach($f in $p.files) {
        if($f.appName -in @('Library - No Transactions','Prevent Metadata Updates Library') -or $f.appName -eq $env:BC_EXPANDED_TEST_MISSING_APP){continue}
        [pscustomobject]@{ AppId=$f.appId;Name=$f.appName;Version=$f.version;Publisher='Microsoft';IsInstalled=$true }
    }
}
function Invoke-ScriptInBcContainer {
    param($containerName,$useSession,$scriptblock,$argumentList)
    if ($argumentList -and $argumentList.Tenant) {
        return @{ startedUtc=[DateTime]::UtcNow.ToString('o');completedUtc=[DateTime]::UtcNow.ToString('o')
            elapsedMilliseconds=1;before=@{name=$argumentList.Previous};after=@{name=$argumentList.Destination};state='Operational' }
    }
    if ($scriptblock.ToString().Contains('ALTER DATABASE [default-test-template]')) { return '11111111-1111-1111-1111-111111111111' }
    if ($scriptblock.ToString().Contains('Get-NAVTenant')) {
        @{Id='default';DatabaseName='default';State='Operational'}
        foreach($n in 2..4 | Where-Object {$_ -le [int]$env:BC_SQL_TENANT_COUNT}) { @{Id="tenant$n";DatabaseName="tenant$n";State='Operational'} }
    } elseif ($scriptblock.ToString().Contains('Get-Process')) { '30.0.55665.0' }
}
function Get-TestsFromBcContainer {
    param($containerName,$tenant,$companyName,$credential,$testSuite,$extensionId,$testCodeunit,$testType,$requiredTestIsolation,$disabledTests)
    if ($requiredTestIsolation -ne 'Disabled') { [pscustomobject]@{Id='148018';Name='IRS fixture';Tests=@('First')} }
}
function Run-TestsInBcContainer {
    param($containerName,$tenant,$companyName,$credential,$testSuite,$extensionId,$testCodeunit,$testType,$testCodeunitRange,
        $requiredTestIsolation,$disabledTests,$JUnitResultFileName,$testRunnerCodeunitId,$appName,
        $returnTrueIfAllPassed,$renewClientContextBetweenTests,$interactionTimeout)
    $failure = if($env:BC_EXPANDED_TEST_FAIL -eq '1') {'<failure message="original fixture failure"/>'}else{''}
    if($extensionId -or $testType -or $requiredTestIsolation -or $testCodeunitRange -ne $testCodeunit){throw 'Worker broadened its verified exact CU selection'}
    Set-Content $JUnitResultFileName "<testsuites><testsuite name='$testCodeunit IRS fixture'><testcase name='First' time='0.001'>$failure</testcase></testsuite></testsuites>"
    return ($env:BC_EXPANDED_TEST_FAIL -ne '1')
}
Export-ModuleMember -Function *
'@
    $script:environment = @{}
    foreach ($key in @('GITHUB_WORKSPACE','GITHUB_REPOSITORY','GITHUB_REF','GITHUB_EVENT_NAME','GITHUB_RUN_ATTEMPT',
        'GITHUB_RUN_ID','GITHUB_SHA','BC_EXPANDED_COUNTRY','BC_EXPANDED_CONFIG','BC_EXPANDED_LANE',
        'BC_SQL_TENANT_COUNT','BC_SQL_PILOT_ARM','BC_SQL_API_EXPERIMENT','BC_SQL_PILOT_OUTPUT','BC_EXPANDED_PHASE',
        'BC_EXPANDED_TEST_FAIL','BC_EXPANDED_TEST_MISSING_APP','BcContainerHelperPath')) {
        $environment[$key] = [Environment]::GetEnvironmentVariable($key)
    }
    $env:GITHUB_WORKSPACE=$fixture; $env:GITHUB_REPOSITORY='microsoft/BCApps'
    $env:GITHUB_REF='refs/heads/features/653393-expanded-api-helper-scope';$env:GITHUB_EVENT_NAME='workflow_dispatch'
    $env:GITHUB_RUN_ATTEMPT='1';$env:GITHUB_RUN_ID='999';$env:GITHUB_SHA='a'*40
    $env:BC_EXPANDED_COUNTRY='CA';$env:BC_EXPANDED_CONFIG='m2w2';$env:BC_EXPANDED_LANE='UncategorizedTests'
    $env:BcContainerHelperPath=$helperPath
    Set-Content (Join-Path $fixture 'fake.evtx') 'fake event fixture'
}
AfterAll {
    Remove-Module BcContainerHelper -ErrorAction SilentlyContinue
    foreach ($key in $environment.Keys) { [Environment]::SetEnvironmentVariable($key,$environment[$key]) }
    Remove-Item $fixture -Recurse -Force
}

Describe 'Real orchestration with fake external services' {
    BeforeEach {
        $env:BC_EXPANDED_CONFIG = if ($topology) { $topology } else { 'm2w2' }
        Remove-Module Producer,Lifecycle,TenantCount,BcContainerHelper -ErrorAction SilentlyContinue
        Import-Module (Join-Path $root 'Producer.psm1') -Force
        Import-Module (Join-Path $root 'Context.psm1') -Force
        $script:context=Get-ExpandedContext
        $output=$context.output
        if(Test-Path $output){Remove-Item $output -Recurse -Force}
        $null=New-Item -ItemType Directory -Path $output
        $env:BC_EXPANDED_TEST_FAIL='0'
        $env:BC_EXPANDED_TEST_MISSING_APP=''
        @{
            ticks=[Diagnostics.Stopwatch]::GetTimestamp()-100000;frequency=[Diagnostics.Stopwatch]::Frequency
            runner='fixture-runner';host='fixture-host'
        }|ConvertTo-Json|Set-Content (Join-Path $output 'clock.json')
        @{run='999';sourceHead=('a'*40);identity=$context.cell.identity;lane=$context.lane.id;container=$context.container} |
            ConvertTo-Json | Set-Content (Join-Path $output 'ownership.json')
        @{files=@(
            @{path='TestApps\Microsoft_IRS Forms Tests_30.0.1.0.app';appId='8d52df0b-add3-4e9b-aac5-f11107cba919';appName='IRS Forms Tests';version='30.0.1.0'},
            @{path='Apps\Microsoft_Test Runner_30.0.1.0.app';appId='23de40a6-dfe8-4f80-80db-d70f83ce8caf';appName='Test Runner';version='30.0.1.0'},
            @{path='Apps\Microsoft_Library - No Transactions_30.0.1.0.app';appId='fixture-no-transactions';appName='Library - No Transactions';version='30.0.1.0'},
            @{path='Apps\Microsoft_Prevent Metadata Updates Library_30.0.1.0.app';appId='fixture-prevent-metadata';appName='Prevent Metadata Updates Library';version='30.0.1.0'}
        )} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $output 'packages.json')
        @{transportVerified=$true;packageFilesVerified=$true;registryId='123';registrySha256=('b'*64)} |
            ConvertTo-Json | Set-Content (Join-Path $output 'transport-proof.json')
        @{verifiedGenericImage=$context.pins.image;actualContainerImageId='fixture-image';memoryBytes=$context.pins.memoryBytes;genericLayerPrefixVerified=$true} |
            ConvertTo-Json | Set-Content (Join-Path $output 'docker.json')
        @{host=@{cpuLoadPercent=1};errors=@()}|ConvertTo-Json -Depth 4|Set-Content (Join-Path $output 'setup-resource.json')
        @{container=@{errors=@()};errors=@()}|ConvertTo-Json -Depth 4|Set-Content (Join-Path $output 'container-setup-resource.json')
        Mock Get-ExpandedDisabledTest -ModuleName Producer { @() }
        Mock Start-SqlTenantSampler -ModuleName Producer { [pscustomobject]@{Id=123;State='Running'} }
        Mock Stop-SqlTenantSampler -ModuleName Producer {
            @{measurementComplete=$true;sampleCount=2}|ConvertTo-Json|Set-Content (Join-Path $Directory 'resource-status.json')
        }
        $script:parameters=@{containerName=$context.container;tenant='default';companyName=$context.lane.settings.company
            JUnitResultFileName=(Join-Path $output 'pipeline.xml')}
    }
    It 'runs discovery, protected resets, a real worker process, raw originals, cleanup and qualification for <topology>' -ForEach @(
        @{topology='m1w1'}, @{topology='m2w2'}, @{topology='m4w3'}
    ) {
        Invoke-ExpandedLane -Parameters $parameters | Should -BeTrue
        & (Join-Path $root 'Finalize.ps1')
        $report=Get-Content (Join-Path $context.output 'lane-evidence.json') -Raw|ConvertFrom-Json
        $report.qualified|Should -BeTrue
        $report.evidence.ownedCleanupVerified|Should -BeTrue
        $report.evidence.lanes[0].discovered[0].runner|Should -Be '130450'
        @($report.evidence.lanes[0].results).Count|Should -Be 1
        $report.evidence.packageManifest.files.Count|Should -Be 4
        $report.evidence.installation.excluded.Count|Should -Be 2
        $report.evidence.installation.required.Count|Should -Be 2
        $report.evidence.installation.installed.Count|Should -Be 2
        $report.evidence.installation.excluded.appName|Should -Contain 'Library - No Transactions'
        $report.evidence.installation.excluded.appName|Should -Contain 'Prevent Metadata Updates Library'
        $reset=@(Get-Content (Join-Path $context.output 'reset-timeline.jsonl')|ForEach-Object {$_|ConvertFrom-Json}|Where-Object phase -EQ reset-complete)
        $reset.Count|Should -Be 2
        $reset[0].plan.Tenant|Should -Be default
        $reset[1].plan.Tenant|Should -Be $context.cell.configuration.workers[0]
        (Test-BcContainer -containerName $context.container)|Should -BeFalse
    }
    It 'preserves an original test failure, never retries it, and still removes the owned container' {
        $env:BC_EXPANDED_TEST_FAIL='1'
        Invoke-ExpandedLane -Parameters $parameters | Should -BeFalse
        { & (Join-Path $root 'Finalize.ps1') } | Should -Throw '*did not qualify*'
        $attempts=@(Get-Content (Join-Path $context.output 'original-attempts.jsonl')|ForEach-Object {$_|ConvertFrom-Json})
        $attempts.Count|Should -Be 1
        $attempts[0].passed|Should -BeFalse
        $report=Get-Content (Join-Path $context.output 'lane-evidence.json') -Raw|ConvertFrom-Json
        $report.qualified|Should -BeFalse
        $report.evidence.originalFailures|Should -Be 1
        (Test-BcContainer -containerName $context.container)|Should -BeFalse
        @(Get-ChildItem (Join-Path $context.output 'cases') -Recurse -Filter original-failures.json).Count|Should -Be 1
    }
    It 'restores discovery in finally and cleans up even when discovery fails' {
        Mock Get-ExpandedWorkItem -ModuleName Producer { throw 'fixture discovery failure' }
        {Invoke-ExpandedLane -Parameters $parameters}|Should -Throw '*fixture discovery failure*'
        $reset=@(Get-Content (Join-Path $context.output 'reset-timeline.jsonl')|ForEach-Object {$_|ConvertFrom-Json}|Where-Object phase -EQ reset-complete)
        $reset.Count|Should -Be 1
        { & (Join-Path $root 'Finalize.ps1') } | Should -Throw
        (Test-BcContainer -containerName $context.container)|Should -BeFalse
        Test-Path (Join-Path $context.output 'cleanup.json')|Should -BeTrue
    }
    It 'does not qualify incomplete resource measurements even after passing cases and cleanup' {
        Mock Stop-SqlTenantSampler -ModuleName Producer {
            @{measurementComplete=$false;sampleCount=1}|ConvertTo-Json|Set-Content (Join-Path $Directory 'resource-status.json')
        }
        Invoke-ExpandedLane -Parameters $parameters|Should -BeTrue
        { & (Join-Path $root 'Finalize.ps1') }|Should -Throw '*resourceEvidenceComplete*'
        (Test-BcContainer -containerName $context.container)|Should -BeFalse
        (Get-Content (Join-Path $context.output 'lane-evidence.json') -Raw|ConvertFrom-Json).qualified|Should -BeFalse
    }
    It 'rejects a missing required installed package before discovery despite standard library exclusions' {
        $env:BC_EXPANDED_TEST_MISSING_APP='IRS Forms Tests'
        {Invoke-ExpandedLane -Parameters $parameters}|Should -Throw '*Installed package/version mismatch for IRS Forms Tests*'
        Test-Path (Join-Path $context.output 'discovery.jsonl')|Should -BeFalse
        { & (Join-Path $root 'Finalize.ps1') }|Should -Throw
        (Test-BcContainer -containerName $context.container)|Should -BeFalse
    }
}
