Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')
Import-Module (Join-Path $PSScriptRoot 'Context.psm1')
Import-Module (Join-Path $PSScriptRoot 'Lifecycle.psm1')
Import-Module (Join-Path $PSScriptRoot 'TenantResources.psm1')

function Get-ExpandedCommandParameter {
    param([hashtable]$Parameters, [string]$Command)
    $supported = (Get-Command $Command -ErrorAction Stop).Parameters
    $result = @{}
    foreach ($key in $Parameters.Keys) {
        if ($supported.ContainsKey($key)) { $result[$key] = $Parameters[$key] }
    }
    foreach ($key in @('ReRun', 'restartContainerAndRetry', 'testFunction', 'testCodeunitRange',
        'testCodeunit', 'testType', 'testRunnerCodeunitId', 'requiredTestIsolation', 'appName',
        'extensionId', 'AppendToJUnitResultFile', 'AppendToXUnitResultFile', 'XUnitResultFileName')) {
        $result.Remove($key)
    }
    $result.testSuite = 'DEFAULT'
    $result.tenant = 'default'
    return $result
}

function Get-ExpandedDisabledTest {
    param([string]$AppName)
    $folder = Join-Path $env:GITHUB_WORKSPACE "src\DisabledTests\$($AppName.Replace(' ', '_'))"
    if (Test-Path $folder) {
        @(Get-ChildItem $folder -Filter '*.json' -File | ForEach-Object {
            Get-Content $_.FullName -Raw | ConvertFrom-Json
        })
    }
}

function ConvertTo-ExpandedCodeunit {
    param([array]$Raw)
    foreach ($entry in $Raw) {
        if ($entry -is [string]) { throw 'Unexpected string instead of structured BCH discovery.' }
        if ($entry.PSObject.Properties.Name -contains 'Codeunits' -or
            ($entry -is [hashtable] -and $entry.ContainsKey('Codeunits'))) { @($entry.Codeunits) } else { $entry }
    }
}

function Get-ExpandedWorkItem {
    param([hashtable]$Parameters, $Context)
    $items = @()
    $base = Get-ExpandedCommandParameter -Parameters $Parameters -Command Get-TestsFromBcContainer
    $base.disabledTests = @()
    foreach ($group in @($Context.lane.routes | Group-Object appId)) {
        $routes = @($group.Group | Sort-Object codeunit)
        $base.extensionId = $group.Name
        $base.testCodeunit = '*'
        $disabled = @(Get-ExpandedDisabledTest -AppName $routes[0].appName)
        $partitions = @{}
        # None on the extension selector means compiled None OR Codeunit; both use
        # the normal runner. This is not inferred from the source's omitted property.
        foreach ($isolation in @('None', 'Disabled')) {
            $selection = $base.Clone()
            $selection.testType = if ($Context.lane.settings.testType -eq 'Legacy') { 'UnitTest' } else { $Context.lane.settings.testType }
            $selection.requiredTestIsolation = $isolation
            $raw = @(ConvertTo-ExpandedCodeunit -Raw @(Get-TestsFromBcContainer @selection))
            $selection.disabledTests = $disabled
            $enabled = @(ConvertTo-ExpandedCodeunit -Raw @(Get-TestsFromBcContainer @selection))
            $partitions[$isolation] = @{ all = $raw; enabled = $enabled }
            @{ appId = $group.Name; selectorType = $selection.testType; compiledIsolationSelector = $isolation
                all = @($raw | Where-Object { [int]$_.Id -in $routes.codeunit })
                enabled = @($enabled | Where-Object { [int]$_.Id -in $routes.codeunit }) } |
                ConvertTo-Json -Depth 20 -Compress | Add-Content (Join-Path $Context.output 'discovery.jsonl')
        }
        $untyped = @()
        if ($Context.lane.settings.testType -eq 'Legacy') {
            # Legacy execution is explicitly selected by app/CU without a type or
            # isolation filter. Typed queries above only prove the compiled runner.
            $untyped = @(ConvertTo-ExpandedCodeunit -Raw @(Get-TestsFromBcContainer @base))
        }
        foreach ($route in $routes) {
            $classified = @(foreach ($isolation in @('None', 'Disabled')) {
                foreach ($cu in @($partitions[$isolation].all | Where-Object { [int]$_.Id -eq $route.codeunit })) {
                    @{ cu = $cu; isolation = $isolation }
                }
            })
            if ($classified.Count -ne 1 -or @($classified[0].cu.Tests).Count -eq 0) {
                throw "Compiled selector omitted or ambiguously classified CU $($route.codeunit)."
            }
            $match = $classified[0]
            $names = @($match.cu.Tests)
            if ($Context.lane.settings.testType -eq 'Legacy') {
                $legacy = @($untyped | Where-Object { [int]$_.Id -eq $route.codeunit })
                if ($legacy.Count -ne 1 -or
                    ((@($legacy[0].Tests | Sort-Object) -join '|') -cne (@($names | Sort-Object) -join '|'))) {
                    throw 'Untyped Legacy coverage does not equal compiled runner classification.'
                }
            }
            $enabledCu = @($partitions[$match.isolation].enabled | Where-Object { [int]$_.Id -eq $route.codeunit })
            if ($enabledCu.Count -gt 1) { throw 'Duplicate enabled codeunit.' }
            $enabledNames = if ($enabledCu.Count) { @($enabledCu[0].Tests) } else { @() }
            if (@($enabledNames | Where-Object { $_ -cnotin $names }).Count -or
                @($names | Sort-Object -Unique).Count -ne $names.Count) { throw 'Malformed runtime method inventory.' }
            $runner = if ($match.isolation -eq 'Disabled') { '130451' } else { '130450' }
            $cases = @(foreach ($name in $names) {
                @{ country = $Context.cell.country; lane = $Context.lane.id; appId = $route.appId
                    appName = $route.appName; codeunitId = [string]$route.codeunit; codeunitName = $match.cu.Name
                    method = [string]$name; skipped = ($name -cnotin $enabledNames)
                    skipBasis = 'Actual test-tool selection with unchanged reviewed disabled manifests'
                    compiledIsolationSelector = $match.isolation; runner = $runner }
            })
            $items += @{ appId = $route.appId; appName = $route.appName; codeunitId = [string]$route.codeunit
                codeunitName = $match.cu.Name; runner = $runner; isolation = $match.isolation
                testType = $Context.lane.settings.testType; cases = $cases; disabledTests = $disabled }
        }
    }
    return $items
}

function ConvertFrom-ExpandedJUnit {
    param([string]$Path, $Item, $Context)
    [xml]$xml = Get-Content -LiteralPath $Path -Raw
    $suites = @($xml.SelectNodes('/testsuites/testsuite | /testsuite'))
    if ($suites.Count -ne 1 -or ($suites[0].GetAttribute('name') -split ' ', 2)[0] -cne $Item.codeunitId) {
        throw 'Foreign, duplicate or missing original JUnit codeunit suite.'
    }
    $nodes = @($suites[0].SelectNodes('testcase'))
    foreach ($node in $nodes) {
        $status = if ($node.SelectSingleNode('failure | error') -or $node.GetAttribute('result') -eq 'Fail') { 'Failed' } elseif ($node.SelectSingleNode('skipped')) { 'Skipped' } else { 'Passed' }
        @{
            country = $Context.cell.country; lane = $Context.lane.id; appId = $Item.appId
            codeunitId = $Item.codeunitId; method = $node.GetAttribute('name'); status = $status
            suite = $node.ParentNode.GetAttribute('name'); seconds = $node.GetAttribute('time')
        }
    }
}

function Invoke-ExpandedLane {
    param([hashtable]$Parameters)
    $context = Get-ExpandedContext
    $outcomePath = Join-Path $context.output 'lane-outcome.json'
    if (Test-Path $outcomePath) {
        $cached = Get-Content $outcomePath -Raw | ConvertFrom-Json
        if ($cached.identity -cne $context.cell.identity -or $cached.lane -cne $context.lane.id -or
            $cached.runId -cne $env:GITHUB_RUN_ID -or $cached.sourceHead -cne $env:GITHUB_SHA) { throw 'Foreign lane cache.' }
        return ($cached.completed -and $cached.passed)
    }
    if ($Parameters.containerName -ne $context.container -or -not $Parameters.JUnitResultFileName) {
        throw 'Unexpected test callback identity or missing raw JUnit destination.'
    }
    Import-ExpandedHelper -RequiredCommands @{
        'Get-TestsFromBcContainer' = @('testType', 'requiredTestIsolation')
        'Run-TestsInBcContainer' = @('testCodeunitRange', 'testRunnerCodeunitId')
        'Get-BcContainerServerConfiguration' = @('containerName')
    }
    $env:BC_SQL_TENANT_COUNT = [string]$context.cell.configuration.mounts.Count
    $env:BC_SQL_PILOT_ARM = 'control'
    $env:BC_SQL_API_EXPERIMENT = 'control'
    $env:BC_SQL_PILOT_OUTPUT = $context.output
    $started = [Diagnostics.Stopwatch]::GetTimestamp()
    $utc = [DateTime]::UtcNow.ToString('o')
    $sampler = $null
    $jobs = @()
    $allResults = @()
    $items = @()
    $completed = $false
    $passed = $true
    try {
        $serverConfiguration = Get-BcContainerServerConfiguration -ContainerName $context.container
        if ($serverConfiguration.Multitenant -ne 'true' -or -not $serverConfiguration.DatabaseName -or
            $serverConfiguration.DatabaseName -in $context.cell.configuration.mounts) {
            throw 'All configurations require an actual multitenant NST and a separate application database.'
        }
        $tenants = @(Invoke-ScriptInBcContainer -containerName $context.container -useSession $false -scriptblock {
            @(Get-NAVTenant -ServerInstance $ServerInstance | ForEach-Object {
                @{ Id = [string]$_.Id; DatabaseName = [string]$_.DatabaseName; State = [string]$_.State }
            })
        })
        if ((@($tenants.Id | Sort-Object) -join '|') -cne
            (@($context.cell.configuration.mounts | Sort-Object) -join '|') -or
            @($tenants | Where-Object { $_.State -ne 'Operational' -or $_.DatabaseName -ne $_.Id }).Count) {
            throw 'Actual mounted tenant mapping does not match the declared healthy topology.'
        }
        $actualVersion = @(Invoke-ScriptInBcContainer -containerName $context.container -useSession $false -scriptblock {
            Get-Process 'Microsoft.Dynamics.Nav.Server' -ErrorAction Stop | ForEach-Object { $_.FileVersion }
        } | Sort-Object -Unique)
        if ($actualVersion.Count -ne 1 -or $actualVersion[0] -cne $context.pins.platform) { throw 'Actual NST executable version differs from the pin.' }
        $installed = @(Get-BcContainerAppInfo -containerName $context.container -tenant default -tenantSpecificProperties | Where-Object IsInstalled)
        $manifest = Get-Content (Join-Path $context.output 'packages.json') -Raw | ConvertFrom-Json
        $installation = Assert-ExpandedInstalledInventory -Files $manifest.files -Installed $installed
        if (-not @($manifest.files | Where-Object appName -EQ 'Test Runner').Count) { throw 'Compiled runner package missing.' }
        @{ nstVersion = $actualVersion[0]; multitenant = $true; applicationDatabase = $serverConfiguration.DatabaseName
            installed = @($installed | Select-Object AppId, Name, Version, Publisher)
            packages = $manifest.files; installation = $installation
            mounts = $tenants; workers = $context.cell.configuration.workers
            helperVersion = $context.pins.helper; shellVersion = $PSVersionTable.PSVersion.ToString() } |
            ConvertTo-Json -Depth 25 | Set-Content (Join-Path $context.output 'runner-inventory.json')
        $sampler = Start-SqlTenantSampler -ContainerName $context.container -Directory $context.output
        Initialize-SqlResetPilot -ContainerName $context.container -TenantInfo $tenants -Arm control `
            -RunId $env:GITHUB_RUN_ID -OutputDirectory $context.output -TenantCount $tenants.Count
        $phase = [Diagnostics.Stopwatch]::GetTimestamp(); $phaseUtc = [DateTime]::UtcNow.ToString('o')
        Invoke-ScriptInBcContainer -containerName $context.container -useSession $false -scriptblock {
            if (Test-NAVDatabase -DatabaseName 'default-test-template') { throw 'Template already exists.' }
            Copy-NAVDatabase -SourceDatabaseName default -DestinationDatabaseName 'default-test-template' -DatabaseServer '.' | Out-Null
        }
        Protect-SqlPilotTemplate -ContainerName $context.container -TemplateDatabaseName 'default-test-template'
        Write-ExpandedPhase -Name template -StartedTicks $phase -StartedUtc $phaseUtc -Completed $true -Directory $context.output
        $phase = [Diagnostics.Stopwatch]::GetTimestamp(); $phaseUtc = [DateTime]::UtcNow.ToString('o')
        $env:BC_EXPANDED_PHASE = 'discovery'
        try {
            $items = @(Get-ExpandedWorkItem -Parameters $Parameters -Context $context)
        } finally {
            Invoke-SqlPilotReset -ContainerName $context.container -Tenant default -DatabaseName default -TemplateDatabaseName 'default-test-template'
            Write-ExpandedPhase -Name discovery-including-finally-reset -StartedTicks $phase -StartedUtc $phaseUtc -Completed ($items.Count -gt 0) -Directory $context.output
            $env:BC_EXPANDED_PHASE = 'execution'
        }
        ConvertTo-Json -InputObject @($items | ForEach-Object { $_.cases }) -Depth 15 | Set-Content (Join-Path $context.output 'case-inventory.json')
        $base = Get-ExpandedCommandParameter -Parameters $Parameters -Command Run-TestsInBcContainer
        if (-not (Get-Command Run-TestsInBcContainer).Parameters.ContainsKey('testCodeunitRange')) {
            throw 'Pinned helper lacks explicit codeunit-range loading.'
        }
        $helperPath = (Get-Module BcContainerHelper).Path
        $caseRoot = Join-Path $context.output 'cases'
        $null = New-Item -ItemType Directory -Path $caseRoot -Force
        $workers = @($context.cell.configuration.workers)
        for ($offset = 0; $offset -lt $items.Count; $offset += $workers.Count) {
            $batch = @($items | Select-Object -Skip $offset -First $workers.Count)
            # Match the qualified producer: all batch resets finish before dispatch.
            for ($i = 0; $i -lt $batch.Count; $i++) {
                Invoke-SqlPilotReset -ContainerName $context.container -Tenant $workers[$i] -DatabaseName $workers[$i] -TemplateDatabaseName 'default-test-template'
            }
            $jobs = @()
            for ($i = 0; $i -lt $batch.Count; $i++) {
                $item = $batch[$i]
                $p = $base.Clone()
                $p.tenant = $workers[$i]; $p.appName = $item.appName
                $p.testCodeunit = $item.codeunitId; $p.testRunnerCodeunitId = $item.runner
                # Loading the extension/type again would execute other CUs' OnRun
                # triggers on this freshly reset worker. Discovery already proved
                # app ownership, type, runner and exact methods; load only this CU.
                $p.testCodeunitRange = $item.codeunitId
                $p.disabledTests = $item.disabledTests; $p.returnTrueIfAllPassed = $true
                $p.renewClientContextBetweenTests = $true
                $p.interactionTimeout = [TimeSpan]::FromMinutes(30)
                $p.JUnitResultFileName = Join-Path (Split-Path $Parameters.JUnitResultFileName -Parent) "Expanded-$($item.appId)-$($item.codeunitId)-$($workers[$i]).xml"
                $directory = Join-Path $caseRoot "$($item.appId)-$($item.codeunitId)"
                $null = New-Item -ItemType Directory -Path $directory
                $dispatchTicks = [Diagnostics.Stopwatch]::GetTimestamp()
                $job = Start-Job -FilePath (Join-Path $PSScriptRoot 'RunCase.ps1') -ArgumentList $p, $helperPath, $directory
                $jobs += @{ job = $job; item = $item; parameters = $p; directory = $directory; dispatchTicks = $dispatchTicks }
                Start-Sleep -Seconds 1
            }
            foreach ($entry in $jobs) {
                $null = Wait-Job -Job $entry.job
                Receive-Job -Job $entry.job -ErrorAction Continue *>&1 |
                    Out-File (Join-Path $entry.directory 'worker.log')
                # Persist the original attempt before interpreting XML or aggregate state.
                $receipt = Get-Content (Join-Path $entry.directory 'original-attempt.json') -Raw | ConvertFrom-Json
                if ($receipt.runId -cne $env:GITHUB_RUN_ID -or $receipt.sourceHead -cne $env:GITHUB_SHA -or
                    $receipt.container -ne $context.container -or $receipt.codeunitId -cne $entry.item.codeunitId) {
                    throw 'Original worker receipt belongs to another execution.'
                }
                $receipt | Add-Member dispatchStartedTicks $entry.dispatchTicks
                $receipt | Add-Member collectedTicks ([Diagnostics.Stopwatch]::GetTimestamp())
                $receipt | ConvertTo-Json -Depth 10 -Compress | Add-Content (Join-Path $context.output 'original-attempts.jsonl')
                if (-not $receipt.passed -or $entry.job.State -ne 'Completed') { $passed = $false }
                $results = @(ConvertFrom-ExpandedJUnit -Path (Join-Path $entry.directory 'original.xml') -Item $entry.item -Context $context)
                ConvertTo-Json -InputObject @($results | Where-Object status -EQ Failed) -Depth 10 |
                    Set-Content (Join-Path $entry.directory 'original-failures.json')
                $allResults += $results
                try { Assert-ExpandedApiCohort -Discovered $entry.item.cases -Results $results } catch { $passed = $false }
                Remove-Job -Job $entry.job
                $jobs = @($jobs | Where-Object { $_.job.Id -ne $entry.job.Id })
            }
            $jobs = @()
        }
        $completed = $true
    } catch {
        $passed = $false
        @{ utc = [DateTime]::UtcNow.ToString('o'); errorType = $_.Exception.GetType().FullName
            message = 'Lane failed; inspect preserved worker, discovery, reset and pipeline evidence.' } |
            ConvertTo-Json | Set-Content (Join-Path $context.output 'lane-error.json')
        throw
    } finally {
        foreach ($entry in $jobs) {
            if ($entry.job.State -eq 'Running') { Stop-Job -Job $entry.job }
            Receive-Job -Job $entry.job -ErrorAction Continue *>&1 | Out-File (Join-Path $entry.directory 'drained-worker.log')
            Remove-Job -Job $entry.job -Force
        }
        if ($sampler) { Stop-SqlTenantSampler -Job $sampler -ContainerName $context.container -Directory $context.output }
        if (Test-BcContainer -containerName $context.container) {
            $events = Get-BcContainerEventLog -containerName $context.container -doNotOpen
            Copy-Item $events (Join-Path $context.output 'original-container.evtx')
        }
        Write-ExpandedPhase -Name execution-including-template-discovery-resets -StartedTicks $started -StartedUtc $utc -Completed $completed -Directory $context.output
        @{ identity = $context.cell.identity; lane = $context.lane.id; id = $context.lane.id
            runId = $env:GITHUB_RUN_ID; sourceHead = $env:GITHUB_SHA; completed = $completed; passed = ($passed -and $completed)
            discovered = @($items | ForEach-Object { $_.cases }); results = $allResults; originalFailures = @($allResults | Where-Object status -EQ Failed).Count
            company = $context.lane.settings.company; testType = $context.lane.settings.testType } |
            ConvertTo-Json -Depth 20 | Set-Content $outcomePath
    }
    return $passed
}

Export-ModuleMember -Function Get-ExpandedCommandParameter, Get-ExpandedDisabledTest, ConvertTo-ExpandedCodeunit,
    Get-ExpandedWorkItem, ConvertFrom-ExpandedJUnit, Invoke-ExpandedLane
