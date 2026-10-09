BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Contract.psm1') -Force
    $script:plan = Get-ExpandedApiPlan -InventoryPath (Join-Path $PSScriptRoot 'routing-inventory.json')
    function New-Case {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
            Justification = 'Pure in-memory test fixture; does not change system state.')]
        [CmdletBinding()]
        param([string]$Name = 'First', [bool]$Skipped = $false)
        [pscustomobject]@{
            country = 'W1'; lane = 'Default'; appId = '8b6f7477-3589-44b7-b84f-d87f09bc764e'
            codeunitId = '139701'; method = $Name; skipped = $Skipped
            status = $(if ($Skipped) { 'Skipped' } else { 'Passed' })
        }
    }
}

Describe 'Bounded expanded diagnostic plan' {
    It 'never advertises an executable or runtime-verified successor' {
        $plan.executionReady | Should -BeFalse
        $plan.runtimeVerified | Should -BeFalse
        $plan.status | Should -Be 'DRAFT_BLOCKED_NOT_EXECUTABLE'
        $plan.blockedBy.Count | Should -Be 4
    }
    It 'preserves six primary cells and six explicit IRS-only supplements' {
        @($plan.cells).Count | Should -Be 12
        @($plan.cells | Where-Object comparison -EQ primary).Count | Should -Be 6
        @($plan.cells.identity | Sort-Object -Unique).Count | Should -Be 12
        foreach ($cell in $plan.cells | Where-Object comparison -EQ primary) {
            @($cell.lanes).Count | Should -Be 5
            @($cell.lanes.routes).Count | Should -Be 159
        }
        foreach ($cell in $plan.cells | Where-Object comparison -EQ IRS-only-supplement) {
            @($cell.lanes).Count | Should -Be 1
            $cell.lanes[0].id | Should -Be 'UncategorizedTests'
            $cell.lanes[0].routes[0].appName | Should -Be 'IRS Forms Tests'
        }
    }
    It 'compares two candidates with the four-mount three-worker baseline, not four workers' {
        $plan.maxParallel | Should -Be 2
        foreach ($country in @('W1', 'DE', 'CA', 'US')) {
            $cells = @($plan.cells | Where-Object country -EQ $country)
            ($cells.configuration.id -join ',') | Should -Be 'm1w1,m2w2,m4w3'
            $cells[2].configuration.mounts.Count | Should -Be 4
            $cells[2].configuration.workers.Count | Should -Be 3
            $cells[2].configuration.workers | Should -Not -Contain 'default'
            @($cells.sharedPackageKey | Sort-Object -Unique).Count | Should -Be 1
        }
    }
    It 'keeps three typed API modes and explicit legacy selection without an isolation filter' {
        foreach ($app in @('_Exclude_APIV1_ Tests', '_Exclude_APIV2_ Tests')) {
            $lanes = @($plan.cells[0].lanes | Where-Object { $app -in $_.routes.appName })
            ($lanes.id -join ',') | Should -Be 'Default,IntegrationTests,UncategorizedTests'
        }
        foreach ($lane in $plan.cells[0].lanes | Where-Object id -Like 'Legacy*') {
            $lane.discovery | Should -Be 'explicit-app-and-codeunit-without-testType-filter'
            $lane.settings.company | Should -Be 'CRONUS International Ltd.'
        }
        $plan.cells[0].lanes[0].settings.company | Should -Be 'Empty Company'
        $plan.cells[0].lanes[1].settings.company | Should -Be 'My Company'
        $plan.cells[0].lanes[2].settings.taskScheduler | Should -BeTrue
    }
    It 'does not claim seven unselected localization variants or all countries' {
        $plan.plannedSourceVariants | Should -Be 160
        @($plan.uncoveredVariants).Count | Should -Be 7
        $plan.allCountriesCovered | Should -BeFalse
        $plan.uncoveredVariants.path | Should -Contain 'src/Layers/NA/Tests/Prepayment/ERMPrepaymentII.Codeunit.al'
    }
    It 'retains the old exact runtime rather than the unpublished platform fix' {
        $plan.pins.platform | Should -Be '30.0.55665.0'
        $plan.pins.helper | Should -Be '6.1.19-preview2811389'
        $plan.pins.image | Should -Match '@sha256:[a-f0-9]{64}$'
    }
    It 'does not add ordinary CI or old producer entry points' {
        $workflow = Get-Content (Join-Path $PSScriptRoot '..\..\..\.github\workflows\SqlApiExpandedDiagnostic.yaml') -Raw
        $workflow | Should -Match 'workflow_dispatch:'
        $workflow | Should -Not -Match '(?m)^\s+(push|pull_request|schedule):'
        $workflow | Should -Not -Match 'RunPipeline|Run-Tests|CICD\.yaml|SqlApiComparisonBatch'
        $workflow | Should -Match 'if: always\(\)'
    }
}

Describe 'Exact runtime cohorts' {
    It 'accepts exact passing names and intentional pre-existing skips' {
        $cases = @((New-Case), (New-Case -Name ExistingSkip -Skipped $true))
        { Assert-ExpandedApiCohort -Discovered $cases -Results $cases } | Should -Not -Throw
    }
    It 'rejects missing or truncated results' {
        { Assert-ExpandedApiCohort -Discovered @((New-Case), (New-Case Second)) -Results @((New-Case)) } | Should -Throw '*truncated*'
    }
    It 'rejects duplicate discovery identities' {
        $cases = @((New-Case), (New-Case))
        { Assert-ExpandedApiCohort -Discovered $cases -Results $cases } | Should -Throw '*Duplicate discovery*'
    }
    It 'rejects duplicate result identities' {
        { Assert-ExpandedApiCohort -Discovered @((New-Case), (New-Case Second)) -Results @((New-Case), (New-Case)) } | Should -Throw '*duplicate result*'
    }
    It 'rejects newly skipped tests, even when totals match' {
        { Assert-ExpandedApiCohort -Discovered @((New-Case)) -Results @((New-Case -Skipped $true)) } | Should -Throw '*skip state*'
    }
    It 'rejects original failure and error results' -ForEach @('Failed', 'Error') {
        $case = New-Case
        $case.status = $_
        { Assert-ExpandedApiCohort -Discovered @((New-Case)) -Results @($case) } | Should -Throw '*Original test failures*'
    }
    It 'rejects unknown, mis-cased or cross-country results' -ForEach @('unknown', 'passed', 'WrongCountry') {
        $case = New-Case
        if ($_ -eq 'WrongCountry') { $case.country = 'DE' } else { $case.status = $_ }
        { Assert-ExpandedApiCohort -Discovered @((New-Case)) -Results @($case) } | Should -Throw
    }
    It 'rejects string-shaped discovery skip flags' {
        $case = New-Case
        $case.skipped = 'false'
        { Assert-ExpandedApiCohort -Discovered @($case) -Results @((New-Case)) } | Should -Throw '*Boolean*'
    }
}

Describe 'Manual diagnostic identity' {
    BeforeEach {
        $script:savedEnvironment = @{}
        $identity = @{
            GITHUB_REPOSITORY = 'microsoft/BCApps'
            GITHUB_REF = 'refs/heads/features/653393-expanded-api-diagnostic'
            GITHUB_EVENT_NAME = 'workflow_dispatch'
            GITHUB_RUN_ATTEMPT = '1'
            GITHUB_RUN_ID = '999'
        }
        foreach ($key in $identity.Keys) {
            $savedEnvironment[$key] = [Environment]::GetEnvironmentVariable($key)
            [Environment]::SetEnvironmentVariable($key, $identity[$key])
        }
    }
    AfterEach {
        foreach ($key in $savedEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key, $savedEnvironment[$key]) }
    }
    It 'allows only the original explicit draft identity' {
        { Assert-ExpandedApiDispatch } | Should -Not -Throw
    }
    It 'rejects forks, old branches, push, reruns and malformed run ids' -ForEach @(
        @{ key = 'GITHUB_REPOSITORY'; value = 'other/BCApps' },
        @{ key = 'GITHUB_REF'; value = 'refs/heads/features/646383-sql-api-tenant-count-comparison' },
        @{ key = 'GITHUB_EVENT_NAME'; value = 'push' },
        @{ key = 'GITHUB_RUN_ATTEMPT'; value = '2' },
        @{ key = 'GITHUB_RUN_ID'; value = '../999' }
    ) {
        [Environment]::SetEnvironmentVariable($key, $value)
        { Assert-ExpandedApiDispatch } | Should -Throw '*exact opt-in branch*'
    }
}

Describe 'New shared package contract' {
    BeforeAll {
        $script:fixture = Join-Path $PSScriptRoot ".validation-$([guid]::NewGuid().ToString('N'))"
        $null = New-Item -ItemType Directory -Path (Join-Path $fixture 'Apps'), (Join-Path $fixture 'TestApps')
        [IO.File]::WriteAllText((Join-Path $fixture 'Apps\a.app'), 'app fixture')
        [IO.File]::WriteAllText((Join-Path $fixture 'TestApps\t.app'), 'test fixture')
        function New-Manifest {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
                Justification = 'Pure in-memory test fixture; does not change system state.')]
            [CmdletBinding()]
            param()
            @{
                country = 'W1'; runId = '999'; sourceHead = ('a' * 40); sourceTree = ('b' * 40)
                freshCompilation = $true; attempt = 1; pins = Get-ExpandedApiPinSet
                artifacts = @(
                    @{ kind = 'Apps'; id = '111'; sha256 = ('c' * 64); expired = $false },
                    @{ kind = 'TestApps'; id = '112'; sha256 = ('d' * 64); expired = $false }
                )
                files = @(foreach ($path in @('Apps\a.app', 'TestApps\t.app')) {
                    @{ path = $path; sha256 = (Get-FileHash (Join-Path $fixture $path)).Hash.ToLowerInvariant()
                        bytes = (Get-Item (Join-Path $fixture $path)).Length }
                })
            }
        }
        function Test-Manifest($Manifest) {
            Assert-ExpandedApiPackageManifest -Manifest $Manifest -Country W1 -RunId 999 `
                -SourceHead ('a' * 40) -SourceTree ('b' * 40) -PackageDirectory $fixture
        }
    }
    AfterAll { Remove-Item -LiteralPath $fixture -Recurse -Force }
    It 'accepts a complete sealed new compilation contract' {
        { Test-Manifest (New-Manifest) } | Should -Not -Throw
    }
    It 'rejects historical package provenance or source drift' -ForEach @('sourceHead', 'sourceTree', 'runId', 'country') {
        $manifest = New-Manifest
        $manifest[$_] = '37372848860'
        { Test-Manifest $manifest } | Should -Throw '*new shared compilation*'
    }
    It 'rejects missing fresh-compilation proof' {
        $manifest = New-Manifest
        $manifest.freshCompilation = $false
        { Test-Manifest $manifest } | Should -Throw
    }
    It 'rejects truthy strings instead of explicit compilation and expiry booleans' -ForEach @('compilation', 'expiry') {
        $manifest = New-Manifest
        if ($_ -eq 'compilation') { $manifest.freshCompilation = 'true' } else { $manifest.artifacts[0].expired = 'false' }
        { Test-Manifest $manifest } | Should -Throw
    }
    It 'rejects actual bytes different from the manifest' {
        $manifest = New-Manifest
        $manifest.files[0].sha256 = 'e' * 64
        { Test-Manifest $manifest } | Should -Throw '*bytes differ*'
    }
    It 'rejects path traversal or duplicate file names' -ForEach @('Apps\..\a.app', 'Apps\a.app') {
        $manifest = New-Manifest
        $manifest.files[1].path = $_
        { Test-Manifest $manifest } | Should -Throw '*Invalid or duplicate*'
    }
    It 'rejects duplicate or expired artifacts' -ForEach @('duplicate', 'expired') {
        $manifest = New-Manifest
        if ($_ -eq 'duplicate') { $manifest.artifacts[1].id = '111' } else { $manifest.artifacts[0].expired = $true }
        { Test-Manifest $manifest } | Should -Throw
    }
    It 'rejects floating or changed runtime pins' {
        $manifest = New-Manifest
        $manifest.pins.platform = 'latest'
        { Test-Manifest $manifest } | Should -Throw '*pin drift*'
    }
}

Describe 'Source overlay safeguards' {
    It 'is hash sealed and contains only inert source changes' {
        $proof = Get-Content (Join-Path $PSScriptRoot 'source-overlay.json') -Raw | ConvertFrom-Json
        $proof.base | Should -Be '97c2f034e7a32eb3bbb7efb1a1e893ea06ac121b'
        $proof.compiled | Should -BeFalse
        $proof.files.Count | Should -Be 178
        @($proof.files | Where-Object { -not $_.StartsWith('src/') }).Count | Should -Be 0
        (Get-FileHash (Join-Path $PSScriptRoot 'source-overlay.patch')).Hash.ToLowerInvariant() | Should -Be $proof.overlaySha256
        ($proof.skipPreservation | Where-Object path -Like '*Expense_Agent*').retainedEntries | Should -Be 9
        ($proof.skipPreservation | Where-Object path -Like '*_Exclude_APIV2*').retainedEntries | Should -Be 1
    }
}

Describe 'Actual runtime evidence contract' {
    BeforeAll {
        $script:cell = @{
            identity = 'W1/m1w1/1'; country = 'W1'; configuration = $plan.cells[0].configuration
            lanes = @(@{
                id = 'Default'; settings = @{ company = 'Empty Company'; testType = 'UnitTest' }
                routes = @(@{ appId = '8b6f7477-3589-44b7-b84f-d87f09bc764e'; codeunit = '139701' })
            })
        }
        function New-Evidence {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
                Justification = 'Pure in-memory test fixture; does not change system state.')]
            [CmdletBinding()]
            param()
            $pins = Get-ExpandedApiPinSet
            @{
                identity = 'W1/m1w1/1'; attempt = 1; originalFailures = 0; retries = 0; warmups = 0; probes = 0
                actualNstVersion = $pins.platform; actualImage = $pins.image; actualMemoryBytes = $pins.memoryBytes
                mounts = @('default'); workers = @('default')
                originalFailuresPersisted = $true; artifactTransportVerified = $true; packageManifestVerified = $true
                ownedCleanupVerified = $true; resourceEvidenceComplete = $true; phaseEvidenceComplete = $true
                runnerInventoryComplete = $true; templateFrozenBeforeDiscovery = $true; templateDetachedReadOnly = $true
                discoveryRestoredInFinally = $true
                lanes = @(@{
                    id = 'Default'; company = 'Empty Company'; testType = 'UnitTest'
                    discovered = @((New-Case)); results = @((New-Case))
                })
            }
        }
    }
    It 'accepts a complete synthetic original and exact topology' {
        { Assert-ExpandedApiEvidence -Evidence (New-Evidence) -Cell $cell } | Should -Not -Throw
    }
    It 'rejects every missing mandatory evidence flag' -ForEach @(
        'originalFailuresPersisted', 'artifactTransportVerified', 'packageManifestVerified',
        'ownedCleanupVerified', 'resourceEvidenceComplete', 'phaseEvidenceComplete',
        'runnerInventoryComplete', 'templateFrozenBeforeDiscovery', 'templateDetachedReadOnly',
        'discoveryRestoredInFinally'
    ) {
        $evidence = New-Evidence
        $evidence[$_] = $false
        { Assert-ExpandedApiEvidence -Evidence $evidence -Cell $cell } | Should -Throw '*Missing fail-closed*'
    }
    It 'rejects original failure, any retry, warmup or probe' -ForEach @('originalFailures', 'retries', 'warmups', 'probes') {
        $evidence = New-Evidence
        $evidence[$_] = 1
        { Assert-ExpandedApiEvidence -Evidence $evidence -Cell $cell } | Should -Throw '*do not qualify*'
    }
    It 'rejects pin claims in place of the actual NST version' {
        $evidence = New-Evidence
        $evidence.actualNstVersion = '30.0.47167.0'
        { Assert-ExpandedApiEvidence -Evidence $evidence -Cell $cell } | Should -Throw
    }
    It 'rejects an unreserved baseline default worker' {
        $evidence = New-Evidence
        $evidence.workers = @('default', 'tenant2')
        { Assert-ExpandedApiEvidence -Evidence $evidence -Cell $cell } | Should -Throw '*topology*'
    }
    It 'rejects omitted lanes and codeunits' -ForEach @('lane', 'codeunit') {
        $evidence = New-Evidence
        if ($_ -eq 'lane') { $evidence.lanes = @() } else { $evidence.lanes[0].discovered[0].codeunitId = '139999' }
        { Assert-ExpandedApiEvidence -Evidence $evidence -Cell $cell } | Should -Throw
    }
    It 'rejects using an Integration company for Unit tests' {
        $evidence = New-Evidence
        $evidence.lanes[0].company = 'My Company'
        { Assert-ExpandedApiEvidence -Evidence $evidence -Cell $cell } | Should -Throw '*company*'
    }
}
