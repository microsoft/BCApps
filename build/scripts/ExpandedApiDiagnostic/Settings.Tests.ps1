[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Pester transfers discovery variables into parameterized test data.')]
param()
BeforeDiscovery {
    Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')
    $settingsCases = @(foreach ($cell in (Get-ExpandedApiPlan -InventoryPath (Join-Path $PSScriptRoot 'routing-inventory.json')).cells) {
        foreach ($lane in $cell.lanes) { @{ country = $cell.country; config = $cell.configuration.id; laneId = $lane.id } }
    })
}
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Settings.psm1') -Force
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    $script:fixture = Join-Path $PSScriptRoot ".settings-$([guid]::NewGuid().ToString('N'))"
    $null = New-Item -ItemType Directory -Path $fixture
    $script:pinnedSource = $env:BC_EXPANDED_ALGO_SOURCE
    if (-not $pinnedSource) { throw 'Set BC_EXPANDED_ALGO_SOURCE to the immutable local AL-Go91b96 checkout; tests never download it.' }
    $head = git -C $pinnedSource rev-parse HEAD
    if ($LASTEXITCODE -ne 0 -or $head -cne '91b96c2b294be6f823277dafe6f03350abfb9d23') { throw 'Wrong pinned AL-Go consumer checkout.' }
    $dirty = git -C $pinnedSource status --porcelain --untracked-files=all
    if ($LASTEXITCODE -ne 0 -or $dirty) { throw 'Pinned AL-Go source must be immutable and clean.' }
    Import-Module (Join-Path $pinnedSource 'Actions\.Modules\ReadSettings.psm1') -Force
    $script:plan = Get-ExpandedApiPlan -InventoryPath (Join-Path $PSScriptRoot 'routing-inventory.json')
}
AfterAll {
    if ($fixture -and (Test-Path $fixture)) { Remove-Item $fixture -Recurse -Force }
    Remove-Module ReadSettings -ErrorAction SilentlyContinue
}

Describe 'Real generator and immutable AL-Go91b96 GetSettingsObject/ReadSettings' {
    It 'generates and consumes <country>/<config>/<laneId> without casing collisions or routing drift' -ForEach $settingsCases {
        $base = Join-Path $fixture "$country-$config-$laneId"
        $project = "build\projects\Expanded $country $config $laneId"
        $null = New-Item -ItemType Directory -Path (Join-Path $base '.github'), (Join-Path $base "$project\.AL-Go")
        Copy-Item (Join-Path $repoRoot '.github\*.json') (Join-Path $base '.github')
        $repo = Set-ExpandedRepoSettings -Path (Join-Path $base '.github\AL-Go-Settings.json') -Country $country -Kind Lane
        $path = Join-Path $base "$project\.AL-Go\settings.json"
        Copy-Item (Join-Path $repoRoot "build\projects\Test Apps $country\.AL-Go\settings.json") $path
        $cell = @($plan.cells | Where-Object { $_.country -ceq $country -and $_.configuration.id -ceq $config })[0]
        $lane = @($cell.lanes | Where-Object id -CEQ $laneId)[0]
        Set-ExpandedProjectSettings -Path $path -Country $country -Kind Lane -Artifact $repo.artifact -Context @{ cell = $cell; lane = $lane }
        $json = Get-Content $path -Raw
        $parsed = $json | ConvertFrom-Json
        @($parsed.PSObject.Properties.Name | Where-Object { $_ -ieq 'conditionalSettings' }).Count | Should -Be 1
        $parsed.PSObject.Properties.Name | Should -Contain 'conditionalSettings'
        $parsed.conditionalSettings.Count | Should -Be 0
        # ReadSettings invokes its nested GetSettingsObject with the plain parser.
        $actual = ReadSettings -baseFolder $base -repoName 'microsoft/BCApps' -project $project -buildMode $laneId `
            -workflowName 'CI/CD' -userName 'fixture' -branchName 'features/653393-expanded-api-reuse-successor' `
            -trigger workflow_dispatch -orgSettingsVariableValue '' -repoSettingsVariableValue '' -environmentSettingsVariableValue ''
        $actual.country | Should -BeExactly $country.ToLowerInvariant()
        $actual.numberOfTenantsForTesting | Should -Be $cell.configuration.mounts.Count
        $actual.testType | Should -BeExactly $lane.settings.testType
        $actual.companyName | Should -BeExactly $lane.settings.company
        $actual.enableTaskScheduler | Should -Be $lane.settings.taskScheduler
        $actual.bcContainerHelperVersion | Should -BeExactly (Get-ExpandedApiPinSet).helper
        $actual.artifact | Should -BeExactly $repo.artifact
        $actual.appFolders.Count | Should -Be 0
        $actual.testFolders.Count | Should -Be 0
        $actual.maxTestAppReruns | Should -Be 0
        $actual.workspaceCompilation.enabled | Should -BeFalse
        $actual.useCompilerFolder | Should -BeFalse
        $actual.doNotPublishApps | Should -BeFalse
        if ($laneId -like 'LegacyTestsBucket*') { $actual.bucketNumber | Should -Be $lane.settings.bucket }
        if ($laneId -eq 'LegacyTestsBucket1') { $actual.additionalDemoDataTypes -join ',' | Should -Be 'Standard,Evaluation' }
    }
    It 'covers exactly 39 lane combinations in 15 cells' {
        @($plan.cells).Count | Should -Be 15
        @($plan.cells.lanes).Count | Should -Be 39
    }
    It 'rejects ambiguous or conflicting duplicates before overwriting the source' -ForEach @(
        '{"ConditionalSettings":[],"conditionalSettings":[]}',
        '{"ConditionalSettings":[],"conditionalSettings":[{"settings":{"country":"xx"}}]}',
        '{"conditionalSettings":[],"conditionalSettings":[]}',
        '{"workspaceCompilation":{"enabled":true,"Enabled":false}}'
    ) {
        $path = Join-Path $fixture 'invalid.json'
        Set-Content $path $_
        $before = (Get-FileHash $path).Hash
        { Read-ExpandedSettings -Path $path } | Should -Throw '*Ambiguous settings key*'
        (Get-FileHash $path).Hash | Should -Be $before
    }
    It 'reproduces the original duplicate-casing failure through the real pinned consumer' {
        $base = Join-Path $fixture 'original-failure'
        $null = New-Item -ItemType Directory -Path (Join-Path $base '.AL-Go')
        Set-Content (Join-Path $base '.AL-Go\settings.json') '{"ConditionalSettings":[],"conditionalSettings":[]}'
        { ReadSettings -baseFolder $base -repoName 'microsoft/BCApps' -project '.' -workflowName '' `
            -orgSettingsVariableValue '' -repoSettingsVariableValue '' -environmentSettingsVariableValue '' } |
            Should -Throw '*different casing*'
    }
    It 'validates output with the plain consumer parser before writing' {
        $path = Join-Path $fixture 'not-emitted.json'
        $bad = '{"ConditionalSettings":[],"conditionalSettings":[]}' | ConvertFrom-Json -AsHashtable
        { Write-ExpandedSettings -Settings $bad -Path $path } | Should -Throw
        Test-Path $path | Should -BeFalse
    }
}
