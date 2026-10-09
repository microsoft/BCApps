$discoveryArm = $env:BC_SQL_PILOT_ARM
try {
    $env:BC_SQL_PILOT_ARM = 'control'
    Import-Module (Join-Path $PSScriptRoot '..\ParallelTestExecution.psm1') -Force
} finally { $env:BC_SQL_PILOT_ARM = $discoveryArm }
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'PlatformUptake.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot 'Comparison.psm1') -Force
    Import-Module powershell-yaml
    $script:root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
}

Describe 'Fixed-platform canonical manifest and immutable control protocol' {
    It 'pins official build resource rather than publisher source' {
        $pin = Get-SqlPlatformUptake
        $pin.runtime | Should -Be '30.0.56092.0'
        $pin.publication.fixCommit | Should -Be '7a4d33b8848c5795474eb6d517724e3ae5043baf'
        $pin.publication.officialBuild | Should -Be 2860912
        $pin.publication.actualResourceBuild | Should -Be $pin.publication.officialBuild
        $pin.publication.actualResourceVersion | Should -Be $pin.runtime
        $pin.publication.publisherRun | Should -Be 2861912
        $pin.publication.publisherSelfSourceIsNotBinaryProvenance | Should -BeTrue
    }
    It 'preserves all four original application archive pins' {
        $pin = Get-SqlPlatformUptake
        $pin.applicationArtifacts.Count | Should -Be 4
        foreach ($original in Get-SqlComparisonArtifact) {
            $artifact = @($pin.applicationArtifacts | Where-Object id -eq $original.id)
            $artifact.Count | Should -Be 1
            $artifact[0].digest | Should -Be $original.digest
            $artifact[0].country | Should -Be $original.country
            $artifact[0].compiledPackageSetSha256 | Should -Match '^[0-9a-f]{64}$'
        }
    }
    It 'has only ten distinct original control cells and the unchanged cohort' {
        $cells = @(Get-SqlPlatformUptakeCell)
        $cells.Count | Should -Be 10
        @($cells | Where-Object experiment -ne 'control').Count | Should -Be 0
        @($cells | ForEach-Object { "$($_.country)/$($_.trial)" } | Select-Object -Unique).Count | Should -Be 10
        foreach ($country in @('W1', 'DE')) {
            (@($cells | Where-Object country -eq $country).trial -join ',') | Should -Be '1,2,3,4,5'
        }
        $plan = (Get-SqlPlatformUptake).trialPlan
        $plan.codeunits.Count | Should -Be 21
        $plan.cases | Should -Be 253
        $plan.expectedPass | Should -Be 234
        $plan.existingSkip | Should -Be 19
        $plan.mountedTenants | Should -Be 4
        $plan.workers | Should -Be 3
        $plan.retries | Should -Be 0
        $plan.addedSkips | Should -Be 0
        $plan.warmup | Should -BeFalse
        $plan.companiesProbe | Should -BeFalse
        $plan.readinessWait | Should -BeFalse
    }
    It 'updates every executable runtime guard, not just Packages.json' {
        (Get-Content (Join-Path $script:root 'build\Packages.json') -Raw | ConvertFrom-Json).BCPlatform.Version | Should -Be '30.0.56092.0'
        $preflight = Get-Content (Join-Path $PSScriptRoot 'ContainerPreflight.ps1') -Raw
        $preflight | Should -Match ([regex]::Escape('/platform/30.0.56092.0/platform'))
        $preflight | Should -Match "platform = '30.0.56092.0'"
        $container = Get-Content (Join-Path $script:root 'build\scripts\NewBcContainer.ps1') -Raw
        $container | Should -Match ([regex]::Escape("'^30\.0\.56092\.0(?:\s|$)'"))
        $container | Should -Match 'runtime-preflight.json'
        foreach ($source in @($preflight, $container)) {
            $source | Should -Not -Match '55665'
        }
    }
    It 'rejects the old installed NST file version, not just the artifact URL' {
        $tokens = $null; $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root 'build\scripts\NewBcContainer.ps1'), [ref]$tokens, [ref]$errors)
        $guard = $ast.Find({ param($node)
            $node -is [Management.Automation.Language.IfStatementAst] -and
            $node.Clauses[0].Item1.Extent.Text -like '*runtime.nst*'
        }, $true)
        $guard | Should -Not -BeNullOrEmpty
        $check = [scriptblock]::Create($guard.Extent.Text)
        $runtime = @{ nst = @(@{ version = '30.0.56092.0' }) }
        { & $check } | Should -Not -Throw
        foreach ($version in @('30.0.55665.0', '28.0.56092.0', '30.0.56092.01', '')) {
            $runtime = @{ nst = @(@{ version = $version }) }
            { & $check } | Should -Throw '*Installed NST*'
        }
        $runtime = @{ nst = @() }
        { & $check } | Should -Throw '*Installed NST*'
    }
    It 'preserves original source, fixtures, auth, settings and lifecycle byte-for-byte' {
        $paths = @('src', 'build/projects', 'build/scripts/ApiTestCredential.psm1',
            'build/scripts/SqlResetPilot/Lifecycle.psm1', 'build/scripts/RunTests.ps1',
            'build/scripts/SqlApiTestRetry.psm1')
        $diff = & git -C $script:root diff 0227094059f2f26f3fcb1b7f85a3285c17e78b8e -- @paths
        $LASTEXITCODE | Should -Be 0
        $diff | Should -BeNullOrEmpty
    }
}

Describe 'Parsed workflow capacity and no automatic fanout' {
    BeforeAll {
        $script:workflow = Get-Content (Join-Path $script:root '.github\workflows\CICD.yaml') -Raw | ConvertFrom-Yaml
        $script:batch = Get-Content (Join-Path $script:root '.github\workflows\SqlApiComparisonBatch.yaml') -Raw | ConvertFrom-Yaml
    }
    It 'permits manual authorization only and never ordinary CI' {
        @($script:workflow.on.Keys).Count | Should -Be 1
        $script:workflow.on.Contains('workflow_dispatch') | Should -BeTrue
        $script:workflow.jobs.Count | Should -Be 6
        foreach ($gate in @($script:workflow.jobs.Plan.if, $script:batch.jobs.Pilot.if)) {
            $gate | Should -Match "github.repository == 'microsoft/BCApps'"
            $gate | Should -Match "github.event_name == 'workflow_dispatch'"
            $gate | Should -Match "github.ref == 'refs/heads/features/653457-sql-platform-fix-uptake'"
            $gate | Should -Match 'github.run_attempt == 1'
            $gate | Should -Match "inputs.authorization == 'AB653457-fixed-platform-original-control-10'"
        }
        $pr = Get-Content (Join-Path $script:root '.github\workflows\PullRequestHandler.yaml') -Raw | ConvertFrom-Yaml
        $pr.jobs.Initialization.if | Should -Match "github.head_ref != 'features/653457-sql-platform-fix-uptake'"
    }
    It 'serializes all five pairs with an aggregate maximum of two cells' {
        $script:batch.jobs.Pilot.strategy.'max-parallel' | Should -Be 2
        $script:batch.jobs.Pilot.strategy.'fail-fast' | Should -BeFalse
        $script:workflow.concurrency.'cancel-in-progress' | Should -BeFalse
        $script:workflow.jobs.Batch01.needs | Should -Be 'Plan'
        foreach ($index in 2..5) {
            $job = $script:workflow.jobs[('Batch{0:00}' -f $index)]
            ($job.needs -join ',') | Should -Be ('Plan,Batch{0:00}' -f ($index - 1))
            $job.if | Should -Be "always() && !cancelled() && needs.Plan.result == 'success'"
        }
        foreach ($index in 1..5) {
            $job = $script:workflow.jobs[('Batch{0:00}' -f $index)]
            $job.with.matrix | Should -Be ('${{ needs.Plan.outputs.batch' + ('{0:00}' -f $index) + ' }}')
        }
    }
    It 'retains always-run owned cleanup and raw event/result uploads' {
        $steps = $script:batch.jobs.Pilot.steps
        @($steps | Where-Object { $_.run -like '*Finalize.ps1*' })[0].if | Should -Be 'always()'
        $upload = @($steps | Where-Object { $_.uses -like 'actions/upload-artifact@*' })[0]
        $upload.if | Should -Be 'always()'
        $upload.with.path | Should -Match '\.buildartifacts/\*\*/\*\.evtx'
        $upload.with.path | Should -Match 'Uptake'
        $script:batch.jobs.Pilot.env.BC_SQL_PILOT_ARM | Should -Be 'control'
    }
}

Describe 'Exact authorized cell context' {
    BeforeEach {
        $script:saved = @{}
        $values = @{
            GITHUB_REPOSITORY = 'microsoft/BCApps'; GITHUB_REF = 'refs/heads/features/653457-sql-platform-fix-uptake'
            GITHUB_EVENT_NAME = 'workflow_dispatch'; GITHUB_RUN_ATTEMPT = '1'; GITHUB_RUN_ID = '123'
            GITHUB_SHA = ('a' * 40); BC_SQL_UPTAKE_AUTHORIZATION = 'AB653457-fixed-platform-original-control-10'
            BC_SQL_PILOT_ARM = 'control'; BC_SQL_API_EXPERIMENT = 'control'; BC_SQL_PILOT_COUNTRY = 'W1'; BC_SQL_PILOT_TRIAL = '1'
        }
        foreach ($envName in $values.Keys) {
            $script:saved[$envName] = [Environment]::GetEnvironmentVariable($envName)
            [Environment]::SetEnvironmentVariable($envName, $values[$envName])
        }
    }
    AfterEach {
        foreach ($envName in $script:saved.Keys) { [Environment]::SetEnvironmentVariable($envName, $script:saved[$envName]) }
    }
    It 'accepts exactly the ten selected cells' {
        foreach ($cell in Get-SqlPlatformUptakeCell) {
            $env:BC_SQL_PILOT_COUNTRY = $cell.country
            $env:BC_SQL_PILOT_TRIAL = [string]$cell.trial
            { Assert-SqlPlatformUptakeContext -Cell } | Should -Not -Throw
        }
    }
    It 'runs the planner to emit only five sequential country-pair matrices' {
        $oldWorkspace = $env:GITHUB_WORKSPACE; $oldOutput = $env:GITHUB_OUTPUT
        try {
            $env:GITHUB_WORKSPACE = $TestDrive
            $env:GITHUB_OUTPUT = Join-Path $TestDrive 'uptake-planner-output.txt'
            if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
            Mock Import-Module {}
            Mock Save-SqlPlatformUptakeSnapshot { @{ country = $Country; verified = $true } }
            Mock git { $global:LASTEXITCODE = 0 }
            & (Join-Path $PSScriptRoot 'PlanPlatformUptake.ps1')
            $outputs = @(Get-Content $env:GITHUB_OUTPUT)
            $outputs.Count | Should -Be 5
            foreach ($index in 1..5) {
                $parts = $outputs[$index - 1] -split '=', 2
                $parts[0] | Should -Be ('batch{0:00}' -f $index)
                $matrix = $parts[1] | ConvertFrom-Json
                $matrix.include.Count | Should -Be 2
                ($matrix.include.country -join ',') | Should -Be 'W1,DE'
                ($matrix.include.trial -join ',') | Should -Be "$index,$index"
                ($matrix.include.experiment -join ',') | Should -Be 'control,control'
            }
            $manifest = Get-Content (Join-Path $TestDrive '.sql-api-comparison-plan\matrix-manifest.json') -Raw | ConvertFrom-Json
            $manifest.originalCellCount | Should -Be 10
            $manifest.globalContainerLimit | Should -Be 2
            $manifest.provenance.publication.actualResourceBuild | Should -Be 2860912
            Should -Invoke Save-SqlPlatformUptakeSnapshot -Times 2 -Exactly
        } finally { $env:GITHUB_WORKSPACE = $oldWorkspace; $env:GITHUB_OUTPUT = $oldOutput }
    }
    InModuleScope ParallelTestExecution {
        It 'selects original control with no warmup, companies probe, or SQL retry' {
            Test-SqlApiExperiment | Should -BeTrue
            Test-SqlApiWarmupEnabled | Should -BeFalse
            $state = [PSCustomObject]@{
                jobs = @(); hasFailures = $false; transient = @(); retried = @{}; retryTenant = @{}; sqlRetryEvidence = @{}
            }
            Register-TestJobOutcome ([PSCustomObject]@{ Outcome = 'SqlPoolRetry' }) $state
            $state.hasFailures | Should -BeTrue
            $state.transient.Count | Should -Be 0
            Mock Reset-BcTestTenant {}
            Mock Invoke-SqlPilotCompaniesProbe { throw 'Probe forbidden.' }
            Mock Start-RequiredDisabledDispatch {}
            Mock Wait-ForAllTestJobs {}
            $parameters = @{ containerName = 'owned'; companyName = 'My Company'; credential = [PSCredential]::Empty }
            $item = [PSCustomObject]@{ Key = 'app::148318'; AppName = 'app'; CodeunitId = '148318'; TestCount = 3 }
            Invoke-RequiredDisabledTestExecution $parameters @($item) @([PSCustomObject]@{ Id = 'tenant2'; DatabaseName = 'tenant2' }) `
                'default-test-template' 'runner.ps1' 'IntegrationTest' | Should -BeTrue
            Should -Invoke Reset-BcTestTenant -Times 1 -Exactly
            Should -Invoke Invoke-SqlPilotCompaniesProbe -Times 0
            Should -Invoke Start-RequiredDisabledDispatch -Times 1 -Exactly
        }
        It 'fails closed instead of entering legacy warmup for invalid uptake authorization or arm' {
            $env:BC_SQL_UPTAKE_AUTHORIZATION = ''
            { Test-SqlApiWarmupEnabled } | Should -Throw '*refusing warmup fallback*'
            $env:BC_SQL_UPTAKE_AUTHORIZATION = 'AB653457-fixed-platform-original-control-10'
            foreach ($arm in @('warmup', 'retry')) {
                $env:BC_SQL_API_EXPERIMENT = $arm
                Test-SqlApiExperiment | Should -BeFalse
                { Test-SqlApiWarmupEnabled } | Should -Throw '*refusing warmup fallback*'
            }
        }
    }
    It 'rejects <Key>=<Value>' -ForEach @(
        @{ Key = 'GITHUB_REF'; Value = 'refs/heads/features/646383-sql-api-300-trial-comparison' }
        @{ Key = 'GITHUB_EVENT_NAME'; Value = 'pull_request' }
        @{ Key = 'GITHUB_RUN_ATTEMPT'; Value = '2' }
        @{ Key = 'BC_SQL_UPTAKE_AUTHORIZATION'; Value = '' }
        @{ Key = 'GITHUB_REPOSITORY'; Value = 'other/BCApps' }
        @{ Key = 'BC_SQL_API_EXPERIMENT'; Value = 'warmup' }
        @{ Key = 'BC_SQL_API_EXPERIMENT'; Value = 'retry' }
        @{ Key = 'BC_SQL_PILOT_ARM'; Value = 'fresh' }
        @{ Key = 'BC_SQL_PILOT_TRIAL'; Value = '6' }
        @{ Key = 'BC_SQL_PILOT_TRIAL'; Value = '01' }
        @{ Key = 'BC_SQL_PILOT_COUNTRY'; Value = 'US' }
    ) {
        [Environment]::SetEnvironmentVariable($Key, $Value)
        { Assert-SqlPlatformUptakeContext -Cell } | Should -Throw
    }
}

Describe 'Compiled package and transport fail-closed checks' {
    It 'rejects changed compiled package hashes or missing packages' {
        { Assert-SqlPlatformUptakePackageSet -Country W1 -Kind apps -Files @(@{ name = 'modified.app'; sha256 = ('a' * 64) }) } | Should -Throw
        { Assert-SqlPlatformUptakePackageSet -Country DE -Kind tests -Files @() } | Should -Throw
    }
    It 'rejects a snapshot whose immutable ID has the wrong transport digest before downloading' {
        $old = $env:GH_TOKEN
        try {
            $env:GH_TOKEN = 'synthetic'
            Mock Invoke-RestMethod -ModuleName PlatformUptake { @{ id = '11487493885'; digest = 'sha256:wrong' } }
            Mock Invoke-WebRequest -ModuleName PlatformUptake { throw 'Download must not occur.' }
            { Save-SqlPlatformUptakeSnapshot -Country W1 -Directory $TestDrive } | Should -Throw '*ID/digest differs*'
            Should -Invoke Invoke-WebRequest -ModuleName PlatformUptake -Times 0
        } finally { $env:GH_TOKEN = $old }
    }
}
