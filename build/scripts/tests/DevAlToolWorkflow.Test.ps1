$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

Describe 'Temporary dev AlTool workflow preparation' {
    BeforeAll {
        $script:repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
        $script:workflowPath = Join-Path $script:repositoryRoot '.github\workflows\_BuildALGoProject.yaml'
        $script:workflow = Get-Content -LiteralPath $script:workflowPath -Raw
        $script:compilePrepareMatch = [regex]::Match(
            $script:workflow,
            '(?m)^\s*-\s+name:\s+Prepare temporary dev AlTool for Compile Apps\s*$'
        )
        $script:testPrepareMatch = [regex]::Match(
            $script:workflow,
            '(?m)^\s*-\s+name:\s+Prepare temporary dev AlTool\s*$'
        )
        $script:compileStepMatch = [regex]::Match(
            $script:workflow,
            '(?m)^\s*-\s+name:\s+Compile Apps\s*$'
        )
        $script:runTestsStepMatch = [regex]::Match(
            $script:workflow,
            '(?m)^\s*-\s+name:\s+Run Tests\s*$'
        )
        $script:signStepMatch = [regex]::Match(
            $script:workflow,
            '(?m)^\s*-\s+name:\s+Sign\s*$'
        )
        $script:compilePrepareStep = $script:workflow.Substring(
            $script:compilePrepareMatch.Index,
            $script:compileStepMatch.Index - $script:compilePrepareMatch.Index
        )
        $script:compileStep = $script:workflow.Substring(
            $script:compileStepMatch.Index,
            $script:testPrepareMatch.Index - $script:compileStepMatch.Index
        )
        $script:testPrepareStep = $script:workflow.Substring(
            $script:testPrepareMatch.Index,
            $script:runTestsStepMatch.Index - $script:testPrepareMatch.Index
        )
        $script:runTestsStep = $script:workflow.Substring(
            $script:runTestsStepMatch.Index,
            $script:signStepMatch.Index - $script:runTestsStepMatch.Index
        )
        $script:appsW1SettingsPath = Join-Path $script:repositoryRoot (
            'build\projects\Apps W1\.AL-Go\settings.json'
        )
        $script:testAppsW1SettingsPath = Join-Path $script:repositoryRoot (
            'build\projects\Test Apps W1\.AL-Go\settings.json'
        )
        $script:cicdSettingsPath = Join-Path $script:repositoryRoot (
            '.github\CICD.settings.json'
        )
        $script:devAlToolBundlePath = Join-Path $script:repositoryRoot (
            'build\tools\altool-dev-net10.zip'
        )
        $script:appsW1Settings = Get-Content -LiteralPath $script:appsW1SettingsPath -Raw |
            ConvertFrom-Json
        $script:testAppsW1Settings = Get-Content -LiteralPath $script:testAppsW1SettingsPath -Raw |
            ConvertFrom-Json
        $script:cicdSettings = Get-Content -LiteralPath $script:cicdSettingsPath -Raw |
            ConvertFrom-Json
        $script:expectedHash = 'C6346A93D2E074F1BB656F8834FFAC2E33CF07983CB44E0705A8366D84D4D3BF'
        $script:expectedVersion = '30.0.0.0+14ef6c5c8aeb5bfd12b3ebf7b413750cb7ac8369'
    }

    It 'places generated-code preparation immediately before Compile Apps' {
        $script:compilePrepareMatch.Success | Should -BeTrue
        $script:compileStepMatch.Index | Should -BeGreaterThan $script:compilePrepareMatch.Index
        [regex]::Matches(
            $script:compilePrepareStep,
            '(?m)^\s*-\s+name:\s+'
        ).Count | Should -Be 1
        $script:compilePrepareStep | Should -Match ([regex]::Escape(
            "steps.DetermineBuildProject.outputs.BuildIt == 'True'"
        ))
        $script:compilePrepareStep | Should -Match ([regex]::Escape(
            'fromJson(env.workspaceCompilation).generateCode == true'
        ))
        $script:compilePrepareStep | Should -Not -Match 'IntegrationTests|UncategorizedTests'
    }

    It 'preserves separate Integration and Uncategorized test preparation' {
        $script:testPrepareMatch.Success | Should -BeTrue
        $script:runTestsStepMatch.Index | Should -BeGreaterThan $script:testPrepareMatch.Index
        [regex]::Matches(
            $script:testPrepareStep,
            '(?m)^\s*-\s+name:\s+'
        ).Count | Should -Be 1
        $script:testPrepareStep | Should -Match ([regex]::Escape(
            "env.runTestsInSeparateAction == 'True'"
        ))
        $script:testPrepareStep | Should -Match ([regex]::Escape(
            "inputs.buildMode == 'IntegrationTests'"
        ))
        $script:testPrepareStep | Should -Match ([regex]::Escape(
            "inputs.buildMode == 'UncategorizedTests'"
        ))
        $script:testPrepareStep | Should -Not -Match 'LegacyTests'
    }

    It 'enables compiler-generated code only in the Apps W1 project settings' {
        $script:appsW1Settings.workspaceCompilation.generateCode | Should -BeTrue

        $otherGeneratedCodeSettings = @(
            Get-ChildItem -LiteralPath (
                Join-Path $script:repositoryRoot 'build\projects'
            ) -Filter settings.json -File -Recurse |
                Where-Object {
                    $_.FullName -ne $script:appsW1SettingsPath -and
                    (Get-Content -LiteralPath $_.FullName -Raw) -match '"generateCode"\s*:'
                }
        )
        $otherGeneratedCodeSettings.Count | Should -Be 0
    }

    It 'restricts the dispatched CICD project matrix to W1 Apps and Test Apps' {
        $dispatchSettings = @(
            $script:cicdSettings.conditionalSettings |
                Where-Object { @($_.triggers) -contains 'workflow_dispatch' }
        )
        $dispatchSettings.Count | Should -Be 1
        @($dispatchSettings[0].settings.projects) | Should -Be @(
            'build\projects\Apps W1',
            'build\projects\Test Apps W1'
        )
        @($dispatchSettings[0].settings.projects | Where-Object {
            $_ -match 'Apps (AT|AU|BE|CA|CH|CZ|DE|DK|ES|FI|FR|GB|IN|IS|IT|MX|NL|NO|NZ|RU|SE|US)$'
        }).Count | Should -Be 0
    }

    It 'retains only the two W1 coverage test dimensions' {
        @($script:testAppsW1Settings.projectsToTest) | Should -Be @(
            'build/projects/Apps W1'
        )
        @($script:testAppsW1Settings.overwriteSettings) | Should -Contain 'buildModes'
        @($script:testAppsW1Settings.buildModes) | Should -Be @(
            'IntegrationTests',
            'UncategorizedTests'
        )
        @($script:testAppsW1Settings.buildModes | Where-Object {
            $_ -like 'LegacyTests*'
        }).Count | Should -Be 0
    }

    It 'pins the checked-in bundle hash and exact executable version in both preparation steps' {
        (Get-FileHash -LiteralPath $script:devAlToolBundlePath -Algorithm SHA256).Hash |
            Should -Be $script:expectedHash

        foreach ($prepareStep in @($script:compilePrepareStep, $script:testPrepareStep)) {
            $prepareStep | Should -Match ([regex]::Escape(
                'build\tools\altool-dev-net10.zip'
            ))
            $prepareStep | Should -Match 'Get-FileHash.+SHA256'
            $prepareStep | Should -Match $script:expectedHash
            $prepareStep | Should -Match ([regex]::Escape($script:expectedVersion))
            $prepareStep | Should -Match ([regex]::Escape('& $alToolPath --version'))
            $prepareStep | Should -Match '\$versionExitCode\s+-ne\s+0'
            $prepareStep | Should -Match '\$actualVersion\s+-ne\s+\$expectedVersion'
        }
    }

    It 'advertises compiler-generated code in the checked-in AlTool bundle' {
        $extractPath = Join-Path $TestDrive 'altool-generatecode'
        Expand-Archive -LiteralPath $script:devAlToolBundlePath -DestinationPath $extractPath -Force
        $alToolPath = Join-Path $extractPath 'altool.exe'
        Test-Path -LiteralPath $alToolPath -PathType Leaf | Should -BeTrue

        $helpOutput = @(& $alToolPath workspace compile --help 2>&1)
        $LASTEXITCODE | Should -Be 0
        ($helpOutput | ForEach-Object { "$_" }) -join [Environment]::NewLine |
            Should -Match '(?i)--generatecode\b'
    }

    It 'exports the explicit AlTool path before workspace compilation' {
        $script:compilePrepareMatch.Index | Should -BeLessThan $script:compileStepMatch.Index
        $script:compilePrepareStep | Should -Match 'Expand-Archive'
        $script:compilePrepareStep | Should -Match ([regex]::Escape(
            "Join-Path `$env:RUNNER_TEMP 'altool-dev-net10'"
        ))
        $script:compilePrepareStep | Should -Match ([regex]::Escape(
            'Add-Content -Encoding UTF8 -Path $env:GITHUB_ENV -Value "AlToolPath=$alToolPath"'
        ))
        $script:compileStep | Should -Match ([regex]::Escape(
            'uses: spetersenms/AL-Go/Actions/CompileApps@spetersen/separateTestActionCodeCoverage'
        ))
        $script:compileStep | Should -Not -Match '(?m)^\s+AlToolPath:'
    }

    It 'retains validated test-time extraction and AlToolPath export' {
        $script:testPrepareStep | Should -Match 'Expand-Archive'
        $script:testPrepareStep | Should -Match ([regex]::Escape(
            "Join-Path `$env:RUNNER_TEMP 'altool-dev-net10'"
        ))
        $script:testPrepareStep | Should -Match ([regex]::Escape(
            'Add-Content -Encoding UTF8 -Path $env:GITHUB_ENV -Value "AlToolPath=$alToolPath"'
        ))
    }

    It 'exposes only downloaded regular apps to the Run Tests dev coverage path' {
        $script:runTestsStep | Should -Match ([regex]::Escape(
            '_devAlToolCoverageAppsJson: ''${{ steps.DownloadProjectDependencies.outputs.DownloadedApps }}'''
        ))
        $script:runTestsStep | Should -Not -Match '_devAlToolCoverageAppsJson:.*DownloadedTestApps'
    }

    It 'reuses ordinary downloaded Apps bytes without a coverage-package build step' {
        $script:workflow | Should -Not -Match '(?m)^\s*-\s+name:\s+.*coverage.*app.*build'
        $script:runTestsStep | Should -Not -Match 'Copy-Item|Move-Item|workspace\s+compile'
        $script:runTestsStep | Should -Match ([regex]::Escape(
            '_devAlToolCoverageAppsJson: ''${{ steps.DownloadProjectDependencies.outputs.DownloadedApps }}'''
        ))
    }
}
