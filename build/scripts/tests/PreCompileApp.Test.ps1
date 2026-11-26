[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'parameters', Justification = 'Pester shares the compilation parameters between BeforeEach and test scopes.')]
param()

Describe 'PreCompileApp workspace baseline' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../EnlistmentHelperFunctions.psm1" -DisableNameChecking
        Import-Module "$PSScriptRoot/../GuardingV2ExtensionsHelper.psm1" -DisableNameChecking

        function CompileAppsInWorkspace {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'The mock compiler signature must match the hook parameters.')]
            param($WorkspaceFile, $PackageCachePath, $OutFolder, $PreprocessorSymbols, $Analyzers, $CustomAnalyzers, $MaxCpuCount, $Ruleset)
            throw 'The compiler must be mocked in these hook tests.'
        }
    }

    BeforeEach {
        $savedEnvironment = @{}
        foreach ($name in @('CI', '_project', 'BaselineWorkflowRunId')) {
            $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
        }
        $env:CI = 'true'
        $env:_project = 'Apps W1'
        $env:BaselineWorkflowRunId = '0'
        $cache = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $output = Join-Path $cache '.buildartifacts/Apps'
        New-Item -ItemType Directory -Path $output -Force | Out-Null
        $parameters = @{
            WorkspaceFile = 'apps.code-workspace'
            PackageCachePath = $cache
            OutFolder = $output
            PreprocessorSymbols = @('CLEAN30')
            Analyzers = @('CodeCop', 'AppSourceCop', 'UICop')
            CustomAnalyzers = @('custom.dll')
            MaxCpuCount = 4
            Ruleset = 'base.ruleset.json'
        }

        Mock Get-BuildMode { 'Clean' }
        Mock Enable-BreakingChangesCheckForWorkspace {}
        Mock CompileAppsInWorkspace {
            $app = Join-Path $OutFolder 'Publisher_App_1.0.0.0.app'
            New-Item -Path $app -ItemType File -Force | Out-Null
            $app
        }
    }

    AfterEach {
        foreach ($name in $savedEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name])
        }
    }

    It 'disables analyzers only for the temporary symbol baseline and retains the actual Clean gate' {
        & "$PSScriptRoot/../PreCompileApp.ps1" -appType app -parameters ([ref]$parameters)

        Should -Invoke CompileAppsInWorkspace -Times 1 -Exactly -ParameterFilter {
            @($Analyzers).Count -eq 0 -and @($CustomAnalyzers).Count -eq 0 -and
            @($PreprocessorSymbols).Count -eq 0 -and $OutFolder -eq $cache -and
            $PackageCachePath -eq $cache -and $MaxCpuCount -eq 4 -and
            $Ruleset -eq 'base.ruleset.json' -and $WorkspaceFile -eq 'apps.code-workspace'
        }
        $parameters.Analyzers | Should -Be @('CodeCop', 'AppSourceCop', 'UICop')
        $parameters.CustomAnalyzers | Should -Be @('custom.dll')
        $parameters.PreprocessorSymbols | Should -Be @('CLEAN30')
        $parameters.OutFolder | Should -Be $output
        Test-Path (Join-Path $cache 'Publisher_App_1.0.0.0_clean.app') | Should -BeTrue
        Should -Invoke Enable-BreakingChangesCheckForWorkspace -Times 1 -Exactly -ParameterFilter {
            $BuildMode -eq 'Clean' -and $AppSymbolsFolder -eq $cache
        }
    }

    It 'preserves compiler failures and does not continue to the breaking-change setup' {
        Mock CompileAppsInWorkspace { throw 'baseline compiler failed' }

        { & "$PSScriptRoot/../PreCompileApp.ps1" -appType app -parameters ([ref]$parameters) } | Should -Throw '*baseline compiler failed*'

        Should -Invoke Enable-BreakingChangesCheckForWorkspace -Times 0
    }

    It 'does not add baseline compilation to Default app builds' {
        Mock Get-BuildMode { 'Default' }

        & "$PSScriptRoot/../PreCompileApp.ps1" -appType app -parameters ([ref]$parameters)

        Should -Invoke CompileAppsInWorkspace -Times 0
        Should -Invoke Enable-BreakingChangesCheckForWorkspace -Times 1 -Exactly
        $parameters.Analyzers | Should -Be @('CodeCop', 'AppSourceCop', 'UICop')
    }

    It 'does not change test-app analyzer parameters' {
        & "$PSScriptRoot/../PreCompileApp.ps1" -appType testApp -parameters ([ref]$parameters)

        Should -Invoke CompileAppsInWorkspace -Times 0
        Should -Invoke Enable-BreakingChangesCheckForWorkspace -Times 0
        $parameters.Analyzers | Should -Be @('CodeCop', 'AppSourceCop', 'UICop')
        $parameters.CustomAnalyzers | Should -Be @('custom.dll')
    }
}
