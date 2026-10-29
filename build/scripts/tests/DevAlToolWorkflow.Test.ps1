$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

Describe 'Temporary dev AlTool workflow preparation' {
    BeforeAll {
        $script:repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
        $script:workflowPath = Join-Path $script:repositoryRoot '.github\workflows\_BuildALGoProject.yaml'
        $script:workflow = Get-Content -LiteralPath $script:workflowPath -Raw
        $script:prepareStepName = '- name: Prepare temporary dev AlTool'
        $script:runTestsStepName = '- name: Run Tests'
        $script:prepareStepIndex = $script:workflow.IndexOf(
            $script:prepareStepName,
            [System.StringComparison]::Ordinal
        )
        $script:runTestsStepIndex = $script:workflow.IndexOf(
            $script:runTestsStepName,
            [System.StringComparison]::Ordinal
        )
        $script:signStepIndex = $script:workflow.IndexOf(
            '- name: Sign',
            [System.StringComparison]::Ordinal
        )
        $script:prepareStep = $script:workflow.Substring(
            $script:prepareStepIndex,
            $script:runTestsStepIndex - $script:prepareStepIndex
        )
        $script:runTestsStep = $script:workflow.Substring(
            $script:runTestsStepIndex,
            $script:signStepIndex - $script:runTestsStepIndex
        )
    }

    It 'places the preparation step immediately before Run Tests' {
        $script:prepareStepIndex | Should -BeGreaterThan -1
        $script:runTestsStepIndex | Should -BeGreaterThan $script:prepareStepIndex
        $stepsBetween = [regex]::Matches(
            $script:prepareStep,
            '(?m)^\s*-\s+name:\s+'
        )
        $stepsBetween.Count | Should -Be 1
    }

    It 'limits the preparation step to separate Integration and Uncategorized test modes' {
        $script:prepareStep | Should -Match ([regex]::Escape(
            "steps.DetermineBuildProject.outputs.BuildIt == 'True'"
        ))
        $script:prepareStep | Should -Match ([regex]::Escape(
            "env.runTestsInSeparateAction == 'True'"
        ))
        $script:prepareStep | Should -Match ([regex]::Escape(
            "inputs.buildMode == 'IntegrationTests'"
        ))
        $script:prepareStep | Should -Match ([regex]::Escape(
            "inputs.buildMode == 'UncategorizedTests'"
        ))
        $script:prepareStep | Should -Not -Match 'LegacyTests'
    }

    It 'verifies the bundle hash and exact executable version' {
        $script:prepareStep | Should -Match ([regex]::Escape(
            'build\tools\altool-dev-net10.zip'
        ))
        $script:prepareStep | Should -Match 'Get-FileHash.+SHA256'
        $script:prepareStep | Should -Match 'F1B264A3D3F8D90CAD31C5FE1596E33A4CAF359D07B7944B8136C4CC795AA817'
        $script:prepareStep | Should -Match ([regex]::Escape(
            '30.0.0.0+14ef6c5c8aeb5bfd12b3ebf7b413750cb7ac8369'
        ))
        $script:prepareStep | Should -Match ([regex]::Escape('& $alToolPath --version'))
        $script:prepareStep | Should -Match '\$versionExitCode\s+-ne\s+0'
        $script:prepareStep | Should -Match '\$actualVersion\s+-ne\s+\$expectedVersion'
    }

    It 'extracts under RUNNER_TEMP and exports the validated AlToolPath' {
        $script:prepareStep | Should -Match ([regex]::Escape(
            "Join-Path `$env:RUNNER_TEMP 'altool-dev-net10'"
        ))
        $script:prepareStep | Should -Match 'Expand-Archive'
        $script:prepareStep | Should -Match ([regex]::Escape(
            "Join-Path `$destination 'altool.exe'"
        ))
        $script:prepareStep | Should -Match ([regex]::Escape(
            'Add-Content -Encoding UTF8 -Path $env:GITHUB_ENV -Value "AlToolPath=$alToolPath"'
        ))
    }

    It 'exposes only downloaded regular apps to the Run Tests dev coverage path' {
        $script:runTestsStep | Should -Match ([regex]::Escape(
            '_devAlToolCoverageAppsJson: ''${{ steps.DownloadProjectDependencies.outputs.DownloadedApps }}'''
        ))
        $script:runTestsStep | Should -Not -Match '_devAlToolCoverageAppsJson:.*DownloadedTestApps'
    }
}
