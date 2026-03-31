Describe "BuildOptimization" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1" -Force
        Import-Module "$PSScriptRoot\..\BuildOptimization.psm1" -Force
        $baseFolder = Get-BaseFolder
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

        It "returns null when event payload file is missing" {
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedEventPath = $env:GITHUB_EVENT_PATH
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'pull_request'
                $env:GITHUB_EVENT_PATH = 'C:\nonexistent\event.json'
                Get-ChangedFilesForCI | Should -BeNullOrEmpty
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:GITHUB_EVENT_PATH = $savedEventPath
            }
        }

        It "returns null for unsupported event type" {
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedEventPath = $env:GITHUB_EVENT_PATH
            $tempFile = $null
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'schedule'
                $tempFile = [System.IO.Path]::GetTempFileName()
                Set-Content $tempFile -Value '{}'
                $env:GITHUB_EVENT_PATH = $tempFile
                Get-ChangedFilesForCI | Should -BeNullOrEmpty
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:GITHUB_EVENT_PATH = $savedEventPath
                if ($tempFile) { Remove-Item $tempFile -ErrorAction SilentlyContinue }
            }
        }

        It "returns changed files using real commits from pull_request event payload" {
            $baseSha = (git rev-parse --verify HEAD~1 2>$null)
            if (-not $baseSha -or $LASTEXITCODE -ne 0) {
                Set-ItResult -Skipped -Because 'shallow clone has no parent commit'
                return
            }
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedEventPath = $env:GITHUB_EVENT_PATH
            $tempFile = $null
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'pull_request'

                $headSha = (git rev-parse HEAD)

                $tempFile = [System.IO.Path]::GetTempFileName()
                @{
                    pull_request = @{
                        base = @{ sha = $baseSha }
                        head = @{ sha = $headSha }
                    }
                } | ConvertTo-Json -Depth 5 | Set-Content $tempFile
                $env:GITHUB_EVENT_PATH = $tempFile

                $result = Get-ChangedFilesForCI
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -BeGreaterOrEqual 1
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:GITHUB_EVENT_PATH = $savedEventPath
                if ($tempFile) { Remove-Item $tempFile -ErrorAction SilentlyContinue }
            }
        }

        It "returns changed files for push event using before/after SHAs" {
            $baseSha = (git rev-parse --verify HEAD~1 2>$null)
            if (-not $baseSha -or $LASTEXITCODE -ne 0) {
                Set-ItResult -Skipped -Because 'shallow clone has no parent commit'
                return
            }
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedEventPath = $env:GITHUB_EVENT_PATH
            $tempFile = $null
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'push'

                $headSha = (git rev-parse HEAD)

                $tempFile = [System.IO.Path]::GetTempFileName()
                @{
                    before = $baseSha
                    after = $headSha
                } | ConvertTo-Json -Depth 5 | Set-Content $tempFile
                $env:GITHUB_EVENT_PATH = $tempFile

                $result = Get-ChangedFilesForCI
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -BeGreaterOrEqual 1
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:GITHUB_EVENT_PATH = $savedEventPath
                if ($tempFile) { Remove-Item $tempFile -ErrorAction SilentlyContinue }
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

    Context "BaseFolder must be repo root, not build/" {
        It "graph is empty when BaseFolder points to build/ instead of repo root" {
            # The old RunTestsInBcContainer.ps1 code computed BaseFolder as:
            #   Join-Path $PSScriptRoot "../../.." from .AL-Go/ → resolves to build/
            # This is wrong because app.json files live under src/ at the repo root.
            $buildFolder = (Resolve-Path "$PSScriptRoot\..\..").Path  # build/
            $wrongGraph = Get-AppDependencyGraph -BaseFolder $buildFolder
            $wrongGraph.Count | Should -Be 0 -Because 'build/ contains no app.json files; BaseFolder must be the repo root'
        }

        It "affected apps returns empty array with wrong BaseFolder, causing silent full-build" {
            $buildFolder = (Resolve-Path "$PSScriptRoot\..\..").Path  # build/
            $wrongGraph = Get-AppDependencyGraph -BaseFolder $buildFolder

            $changedFiles = @(
                'src/Apps/W1/EDocument/App/src/Processing/Import/FinishDraft/EDocCreatePurchaseInvoice.Codeunit.al'
            )
            $affected = Get-AffectedApps -ChangedFiles $changedFiles -BaseFolder $buildFolder -Graph $wrongGraph

            # With wrong BaseFolder: graph is empty, unmapped src/ file returns @($Graph.Keys) = @()
            # PowerShell unwraps empty arrays to $null through the pipeline, so wrap in @()
            # Then 0 >= 0 is true, so Get-AffectedAppNames treats this as "full build"
            # even though zero apps were actually identified
            @($affected).Count | Should -Be 0 -Because 'empty graph means no apps can be found'
            @($affected).Count -ge @($wrongGraph.Keys).Count | Should -BeTrue -Because 'this is the condition that triggers the false full-build (0 >= 0)'
        }

        It "correct BaseFolder (repo root) finds apps for the same changed files" {
            $changedFiles = @(
                'src/Apps/W1/EDocument/App/src/Processing/Import/FinishDraft/EDocCreatePurchaseInvoice.Codeunit.al'
            )
            $affected = Get-AffectedApps -ChangedFiles $changedFiles -BaseFolder $baseFolder -Graph $graph
            $affected.Count | Should -BeGreaterThan 0 -Because 'repo root BaseFolder correctly maps EDocument files to apps'
            $affectedNames = $affected | ForEach-Object { $graph[$_].Name }
            $affectedNames | Should -Contain 'E-Document Core'
        }

        It "RunTestsInBcContainer scripts use Get-BaseFolder, not relative path resolution" {
            $scripts = Get-ChildItem -Path (Resolve-Path "$PSScriptRoot\..\..\projects").Path -Recurse -Filter 'RunTestsInBcContainer.ps1'
            $scripts.Count | Should -BeGreaterOrEqual 4

            foreach ($script in $scripts) {
                $content = Get-Content $script.FullName -Raw
                $content | Should -Match 'Get-BaseFolder' -Because "$($script.FullName) must use Get-BaseFolder for repo root"
                $content | Should -Not -Match '\$baseFolder\s*=.*Join-Path.*\$PSScriptRoot' -Because "$($script.FullName) must not compute baseFolder via relative path"
            }
        }
    }

    Context "Test-ShouldSkipTestApp" {
        BeforeAll {
            $cacheFile = Join-Path ([System.IO.Path]::GetTempPath()) "BuildOptimization_Test_$([System.Guid]::NewGuid()).json"
        }
        BeforeEach {
            Remove-Item $cacheFile -ErrorAction SilentlyContinue
        }
        AfterAll {
            Remove-Item $cacheFile -ErrorAction SilentlyContinue
        }

        It "returns false when not in CI" {
            $saved = $env:GITHUB_ACTIONS
            try {
                $env:GITHUB_ACTIONS = $null
                Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder -CacheFile $cacheFile | Should -BeFalse
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
                Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder -CacheFile $cacheFile | Should -BeFalse
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
                Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder -CacheFile $cacheFile | Should -BeFalse
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
                Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder -CacheFile $cacheFile | Should -BeFalse
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
                Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder -CacheFile $cacheFile | Should -BeTrue
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:BUILD_OPTIMIZATION_DISABLED = $savedDisabled
            }
        }

        It "reads from cache file on second call without recomputing" {
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
                # First call computes and writes cache file
                Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder -CacheFile $cacheFile | Should -BeTrue
                Test-Path $cacheFile | Should -BeTrue
                # Second call reads from cache — Get-ChangedFilesForCI not called again
                Test-ShouldSkipTestApp -AppName 'E-Document Core' -BaseFolder $baseFolder -CacheFile $cacheFile | Should -BeFalse
                Should -Invoke -ModuleName BuildOptimization Get-ChangedFilesForCI -Times 1 -Exactly
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:BUILD_OPTIMIZATION_DISABLED = $savedDisabled
            }
        }
    }
}
