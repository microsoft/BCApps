$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

Describe 'Temporary dev AlTool workflow preparation' {
    BeforeAll {
        $script:repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
        $script:workflowPath = Join-Path $script:repositoryRoot '.github\workflows\_BuildALGoProject.yaml'
        $script:workflow = Get-Content -LiteralPath $script:workflowPath -Raw
        $script:cicdWorkflowPath = Join-Path $script:repositoryRoot '.github\workflows\CICD.yaml'
        $script:cicdWorkflow = Get-Content -LiteralPath $script:cicdWorkflowPath -Raw
        $script:experimentalAlGoRef = 'spetersen-microsoft-separate-test-action-cc-experimental'
        $script:oldAlGoRef = 'spetersen/separateTestActionCodeCoverage'
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
        $script:expectedHash = '29D0700C1A225EC5655E8FB2913CE795FC5D19EDE56BC14EACFDB05D9F90EE78'
        $script:previousHash = '7C960402DA33DC071DB1C814F1A7301B525B7FADB7B3250E89E87C6E9016DC0D'
        $script:expectedSize = 19757579
        $script:expectedVersion = '30.0.0.0+14ef6c5c8aeb5bfd12b3ebf7b413750cb7ac8369'
        $script:requiredAnalyzerFiles = @(
            'Microsoft.Dynamics.Nav.Analyzers.Common.dll'
            'Microsoft.Dynamics.Nav.CodeCop.dll'
            'Microsoft.Dynamics.Nav.AppSourceCop.dll'
            'Microsoft.Dynamics.Nav.PerTenantExtensionCop.dll'
            'Microsoft.Dynamics.Nav.UICop.dll'
        )
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
        $actualHash = (Get-FileHash -LiteralPath $script:devAlToolBundlePath -Algorithm SHA256).Hash
        $actualHash | Should -Be $script:expectedHash
        $actualHash | Should -Not -Be $script:previousHash
        (Get-Item -LiteralPath $script:devAlToolBundlePath).Length |
            Should -Be $script:expectedSize

        foreach ($prepareStep in @($script:compilePrepareStep, $script:testPrepareStep)) {
            $prepareStep | Should -Match ([regex]::Escape(
                'build\tools\altool-dev-net10.zip'
            ))
            $prepareStep | Should -Match 'Get-FileHash.+SHA256'
            $prepareStep | Should -Match $script:expectedHash
            $prepareStep | Should -Not -Match $script:previousHash
            $prepareStep | Should -Match ([regex]::Escape($script:expectedVersion))
            $prepareStep | Should -Match ([regex]::Escape('& $alToolPath --version'))
            $prepareStep | Should -Match '\$versionExitCode\s+-ne\s+0'
            $prepareStep | Should -Match '\$actualVersion\s+-ne\s+\$expectedVersion'
            $exportIndex = $prepareStep.IndexOf(
                'Add-Content -Encoding UTF8 -Path $env:GITHUB_ENV -Value "AlToolPath=$alToolPath"'
            )
            $exportIndex | Should -BeGreaterThan 0
            foreach ($requiredAnalyzerFile in $script:requiredAnalyzerFiles) {
                $requiredFileIndex = $prepareStep.IndexOf($requiredAnalyzerFile)
                $requiredFileIndex | Should -BeGreaterThan 0
                $requiredFileIndex | Should -BeLessThan $exportIndex
            }
            $prepareStep | Should -Match 'foreach\s*\(\$requiredFile\s+in\s+\$requiredFiles\)'
            $prepareStep | Should -Match 'Test-Path\s+-LiteralPath\s+\$requiredPath\s+-PathType\s+Leaf'
        }
    }

    It 'contains the complete generated-code compiler payload' {
        $extractPath = Join-Path $TestDrive 'altool-generatecode'
        Expand-Archive -LiteralPath $script:devAlToolBundlePath -DestinationPath $extractPath -Force
        $alToolPath = Join-Path $extractPath 'altool.exe'
        Test-Path -LiteralPath $alToolPath -PathType Leaf | Should -BeTrue
        @(Get-ChildItem -LiteralPath $extractPath -File -Recurse).Count | Should -Be 137
        @(Get-ChildItem -LiteralPath $extractPath -File -Recurse -Filter '*.pdb').Count |
            Should -Be 0
        foreach ($requiredAnalyzerFile in $script:requiredAnalyzerFiles) {
            Test-Path -LiteralPath (Join-Path $extractPath $requiredAnalyzerFile) -PathType Leaf |
                Should -BeTrue
        }

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
            "uses: spetersenms/AL-Go/Actions/CompileApps@$($script:experimentalAlGoRef)"
        ))
        $script:compileStep | Should -Not -Match '(?m)^\s+AlToolPath:'
    }

    It 'uses the experimental AL-Go branch consistently for the dispatched run' {
        foreach ($workflowContent in @($script:cicdWorkflow, $script:workflow)) {
            $actionReferences = @(
                [regex]::Matches(
                    $workflowContent,
                    'spetersenms/AL-Go/Actions/[^@\s]+@([^\s]+)'
                )
            )
            $actionReferences.Count | Should -BeGreaterThan 0
            @(
                $actionReferences |
                    Where-Object { $_.Groups[1].Value -ne $script:experimentalAlGoRef }
            ).Count | Should -Be 0
            $workflowContent | Should -Not -Match ([regex]::Escape($script:oldAlGoRef))
        }
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
