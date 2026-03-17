Describe "BuildOptimization" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\BuildOptimization.psm1" -Force
        $baseFolder = (Resolve-Path "$PSScriptRoot\..\..\..").Path
        $graph = Get-AppDependencyGraph -BaseFolder $baseFolder
    }

    Context "Get-AppDependencyGraph" {
        It "builds a graph with the expected number of nodes" {
            $graph.Count | Should -BeGreaterOrEqual 300
        }

        It "includes System Application node" {
            $sysAppId = '63ca2fa4-4f03-4f2b-a480-172fef340d3f'
            $graph.ContainsKey($sysAppId) | Should -BeTrue
            $graph[$sysAppId].Name | Should -Be 'System Application'
        }

        It "includes E-Document Core with correct reverse edges" {
            $edocId = 'e1d97edc-c239-46b4-8d84-6368bdf67c8b'
            $graph[$edocId].Dependents.Count | Should -BeGreaterOrEqual 5
            $dependentNames = $graph[$edocId].Dependents | ForEach-Object { $graph[$_].Name }
            $dependentNames | Should -Contain 'E-Document Core Tests'
            $dependentNames | Should -Contain 'E-Document Connector - Avalara'
        }

        It "builds correct forward edges for Avalara connector" {
            $avalaraNode = $graph.Values | Where-Object { $_.Name -eq 'E-Document Connector - Avalara' }
            $avalaraNode | Should -Not -BeNullOrEmpty
            $avalaraNode.Dependencies | Should -Contain 'e1d97edc-c239-46b4-8d84-6368bdf67c8b'
        }
    }

    Context "Get-AppForFile" {
        It "maps E-Document Core file" {
            $result = Get-AppForFile -FilePath 'src/Apps/W1/EDocument/App/src/SomeFile.al' -BaseFolder $baseFolder
            $result | Should -Be 'e1d97edc-c239-46b4-8d84-6368bdf67c8b'
        }

        It "maps Email module file" {
            $result = Get-AppForFile -FilePath 'src/System Application/App/Email/src/SomeFile.al' -BaseFolder $baseFolder
            $result | Should -Be '9c4a2cf2-be3a-4aa3-833b-99a5ffd11f25'
        }

        It "returns null for non-app file" {
            $result = Get-AppForFile -FilePath 'build/scripts/BuildOptimization.psm1' -BaseFolder $baseFolder
            $result | Should -BeNullOrEmpty
        }

        It "handles absolute paths" {
            $absPath = Join-Path $baseFolder 'src/Apps/W1/EDocument/App/src/SomeFile.al'
            $result = Get-AppForFile -FilePath $absPath -BaseFolder $baseFolder
            $result | Should -Be 'e1d97edc-c239-46b4-8d84-6368bdf67c8b'
        }
    }

    Context "Get-AffectedApps" {
        It "returns 9 affected apps for E-Document Core change" {
            $affected = Get-AffectedApps -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $baseFolder -Graph $graph
            $affected.Count | Should -Be 9
            $affected | Should -Contain 'e1d97edc-c239-46b4-8d84-6368bdf67c8b'
        }

        It "includes all connectors and tests for E-Document Core change" {
            $affected = Get-AffectedApps -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $baseFolder -Graph $graph
            $affectedNames = $affected | ForEach-Object { $graph[$_].Name }
            $affectedNames | Should -Contain 'E-Document Core Tests'
            $affectedNames | Should -Contain 'E-Document Core Demo Data'
            $affectedNames | Should -Contain 'E-Document Connector - Avalara'
            $affectedNames | Should -Contain 'E-Document Connector - Avalara Tests'
            $affectedNames | Should -Contain 'E-Document Connector - Continia'
            $affectedNames | Should -Contain 'E-Document Connector - Continia Tests'
        }

        It "returns all apps when an unmapped src/ file is present" {
            $affected = Get-AffectedApps -ChangedFiles @('src/rulesets/ruleset.json') -BaseFolder $baseFolder -Graph $graph
            $affected.Count | Should -Be $graph.Count
        }

        It "ignores non-src unmapped files" {
            $affected = Get-AffectedApps -ChangedFiles @(
                'build/scripts/SomeNewScript.ps1',
                'src/Apps/W1/EDocument/App/src/SomeFile.al'
            ) -BaseFolder $baseFolder -Graph $graph
            $affected.Count | Should -BeLessThan $graph.Count
            $affectedNames = $affected | ForEach-Object { $graph[$_].Name }
            $affectedNames | Should -Contain 'E-Document Core'
        }

        It "handles multiple changed files" {
            $affected = Get-AffectedApps -ChangedFiles @(
                'src/Apps/W1/EDocument/App/src/SomeFile.al',
                'src/Apps/W1/EDocument/Test/src/SomeTest.al'
            ) -BaseFolder $baseFolder -Graph $graph
            $affectedNames = $affected | ForEach-Object { $graph[$_].Name }
            $affectedNames | Should -Contain 'E-Document Core'
            $affectedNames | Should -Contain 'E-Document Core Tests'
        }
    }

    Context "Get-ChangedFilesForCI" {
        It "returns null when not in CI" {
            $saved = $env:GITHUB_ACTIONS
            try {
                $env:GITHUB_ACTIONS = $null
                Get-ChangedFilesForCI | Should -BeNullOrEmpty
            } finally {
                $env:GITHUB_ACTIONS = $saved
            }
        }

        It "returns null for workflow_dispatch" {
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'workflow_dispatch'
                Get-ChangedFilesForCI | Should -BeNullOrEmpty
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
            }
        }
    }

    Context "Test-FullBuildPatternsMatch" {
        It "returns true when a changed file matches build/* pattern" {
            $result = Test-FullBuildPatternsMatch -ChangedFiles @('build/scripts/RunTestsInBcContainer.ps1') -BaseFolder $baseFolder
            $result | Should -BeTrue
        }

        It "returns true when a changed file matches src/rulesets/* pattern" {
            $result = Test-FullBuildPatternsMatch -ChangedFiles @('src/rulesets/ruleset.json') -BaseFolder $baseFolder
            $result | Should -BeTrue
        }

        It "returns true when a changed file matches an exact workflow pattern" {
            $result = Test-FullBuildPatternsMatch -ChangedFiles @('.github/workflows/PullRequestHandler.yaml') -BaseFolder $baseFolder
            $result | Should -BeTrue
        }

        It "returns false when no changed files match any pattern" {
            $result = Test-FullBuildPatternsMatch -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $baseFolder
            $result | Should -BeFalse
        }

        It "returns false for non-matching top-level files" {
            $result = Test-FullBuildPatternsMatch -ChangedFiles @('README.md', '.gitignore') -BaseFolder $baseFolder
            $result | Should -BeFalse
        }

        It "returns true when only one of multiple files matches" {
            $result = Test-FullBuildPatternsMatch -ChangedFiles @(
                'src/Apps/W1/EDocument/App/src/SomeFile.al',
                'build/scripts/SomeNewScript.ps1'
            ) -BaseFolder $baseFolder
            $result | Should -BeTrue
        }

        It "handles backslash paths by normalizing to forward slashes" {
            $result = Test-FullBuildPatternsMatch -ChangedFiles @('build\scripts\RunTestsInBcContainer.ps1') -BaseFolder $baseFolder
            $result | Should -BeTrue
        }

        It "returns false when settings file is missing" {
            $result = Test-FullBuildPatternsMatch -ChangedFiles @('build/scripts/foo.ps1') -BaseFolder 'C:\nonexistent\path'
            $result | Should -BeFalse
        }
    }

    Context "Test-ShouldSkipTestApp" {
        It "returns false when not in CI" {
            $saved = $env:GITHUB_ACTIONS
            try {
                $env:GITHUB_ACTIONS = $null
                Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder | Should -BeFalse
            } finally {
                $env:GITHUB_ACTIONS = $saved
            }
        }

        It "returns false for workflow_dispatch" {
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'workflow_dispatch'
                Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder | Should -BeFalse
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
            }
        }

        It "returns false when BUILD_OPTIMIZATION_DISABLED is true" {
            $savedDisabled = $env:BUILD_OPTIMIZATION_DISABLED
            $savedActions = $env:GITHUB_ACTIONS
            try {
                $env:BUILD_OPTIMIZATION_DISABLED = 'true'
                $env:GITHUB_ACTIONS = 'true'
                Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder | Should -BeFalse
            } finally {
                $env:BUILD_OPTIMIZATION_DISABLED = $savedDisabled
                $env:GITHUB_ACTIONS = $savedActions
            }
        }

        It "returns false when changed files match fullBuildPatterns" {
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedDisabled = $env:BUILD_OPTIMIZATION_DISABLED
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'pull_request'
                $env:BUILD_OPTIMIZATION_DISABLED = $null
                Mock -ModuleName BuildOptimization Get-ChangedFilesForCI { return @('build/scripts/SomeScript.ps1') }
                Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder | Should -BeFalse
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:BUILD_OPTIMIZATION_DISABLED = $savedDisabled
            }
        }

        It "returns true (skip) when changed files affect only E-Document and AppName is Shopify" {
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedDisabled = $env:BUILD_OPTIMIZATION_DISABLED
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'pull_request'
                $env:BUILD_OPTIMIZATION_DISABLED = $null
                Mock -ModuleName BuildOptimization Get-ChangedFilesForCI {
                    return @('src/Apps/W1/EDocument/App/src/SomeFile.al')
                }
                Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder | Should -BeTrue
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:BUILD_OPTIMIZATION_DISABLED = $savedDisabled
            }
        }
    }
}
