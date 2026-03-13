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

        It "includes E-Document Core node" {
            $edocId = 'e1d97edc-c239-46b4-8d84-6368bdf67c8b'
            $graph.ContainsKey($edocId) | Should -BeTrue
            $graph[$edocId].Name | Should -Be 'E-Document Core'
        }

        It "builds correct forward edges for Avalara connector" {
            $avalaraNode = $graph.Values | Where-Object { $_.Name -eq 'E-Document Connector - Avalara' }
            $avalaraNode | Should -Not -BeNullOrEmpty
            $avalaraNode.Dependencies | Should -Contain 'e1d97edc-c239-46b4-8d84-6368bdf67c8b'
        }

        It "builds correct reverse edges for E-Document Core" {
            $edocId = 'e1d97edc-c239-46b4-8d84-6368bdf67c8b'
            $edocDependents = $graph[$edocId].Dependents
            $edocDependents.Count | Should -BeGreaterOrEqual 5
            # Should include the connectors and tests
            $dependentNames = $edocDependents | ForEach-Object { $graph[$_].Name }
            $dependentNames | Should -Contain 'E-Document Core Tests'
            $dependentNames | Should -Contain 'E-Document Connector - Avalara'
        }

        It "System Application has dependents (it is depended upon)" {
            $sysAppId = '63ca2fa4-4f03-4f2b-a480-172fef340d3f'
            $graph[$sysAppId].Dependents.Count | Should -BeGreaterOrEqual 1
        }
    }

    Context "Get-AppForFile" {
        It "maps a file inside E-Document Core to the correct app" {
            $result = Get-AppForFile -FilePath 'src/Apps/W1/EDocument/App/src/SomeFile.al' -BaseFolder $baseFolder
            $result | Should -Be 'e1d97edc-c239-46b4-8d84-6368bdf67c8b'
        }

        It "maps a file inside System Application Email module" {
            $result = Get-AppForFile -FilePath 'src/System Application/App/Email/src/SomeFile.al' -BaseFolder $baseFolder
            $result | Should -Be '9c4a2cf2-be3a-4aa3-833b-99a5ffd11f25'
        }

        It "returns null for a file outside any app" {
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
            $affected = Get-AffectedApps -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $baseFolder
            $affected.Count | Should -Be 9
            # Should include E-Document Core itself
            $affected | Should -Contain 'e1d97edc-c239-46b4-8d84-6368bdf67c8b'
        }

        It "includes all connectors and tests for E-Document Core change" {
            $affected = Get-AffectedApps -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $baseFolder
            $affectedNames = $affected | ForEach-Object { $graph[$_].Name }
            $affectedNames | Should -Contain 'E-Document Core Tests'
            $affectedNames | Should -Contain 'E-Document Core Demo Data'
            $affectedNames | Should -Contain 'E-Document Connector - Avalara'
            $affectedNames | Should -Contain 'E-Document Connector - Avalara Tests'
            $affectedNames | Should -Contain 'E-Document Connector - Continia'
            $affectedNames | Should -Contain 'E-Document Connector - Continia Tests'
        }

        It "Email change includes upstream dependencies and System Application" {
            $affected = Get-AffectedApps -ChangedFiles @('src/System Application/App/Email/src/SomeFile.al') -BaseFolder $baseFolder
            $affectedNames = $affected | ForEach-Object { $graph[$_].Name }
            # Downstream: direct dependents
            $affectedNames | Should -Contain 'Email'
            $affectedNames | Should -Contain 'Email Test'
            $affectedNames | Should -Contain 'Email Test Library'
            # Upstream: Email's dependencies
            $affectedNames | Should -Contain 'BLOB Storage'
            $affectedNames | Should -Contain 'Telemetry'
            # System Application umbrella included because a module is affected
            $affectedNames | Should -Contain 'System Application'
            # Total should be substantial (Email + 2 dependents + ~46 upstream deps + System App)
            $affected.Count | Should -BeGreaterThan 20
        }

        It "returns all apps when an unmapped src/ file is present" {
            $affected = Get-AffectedApps -ChangedFiles @('src/rulesets/ruleset.json') -BaseFolder $baseFolder
            $affected.Count | Should -Be $graph.Count
        }

        It "ignores non-src unmapped files (build scripts, workflows)" {
            $affected = Get-AffectedApps -ChangedFiles @(
                'build/scripts/SomeNewScript.ps1',
                'src/Apps/W1/EDocument/App/src/SomeFile.al'
            ) -BaseFolder $baseFolder
            $affected.Count | Should -BeLessThan $graph.Count
            $affectedNames = $affected | ForEach-Object { $graph[$_].Name }
            $affectedNames | Should -Contain 'E-Document Core'
        }

        It "handles multiple changed files" {
            $affected = Get-AffectedApps -ChangedFiles @(
                'src/Apps/W1/EDocument/App/src/SomeFile.al',
                'src/Apps/W1/EDocument/Test/src/SomeTest.al'
            ) -BaseFolder $baseFolder
            $affectedNames = $affected | ForEach-Object { $graph[$_].Name }
            $affectedNames | Should -Contain 'E-Document Core'
            $affectedNames | Should -Contain 'E-Document Core Tests'
        }
    }

    Context "Get-FilteredProjectSettings" {
        It "returns filtered settings for E-Document Core change" {
            $filtered = Get-FilteredProjectSettings -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $baseFolder
            $filtered.Count | Should -BeGreaterOrEqual 1
            $w1Key = 'build/projects/Apps (W1)'
            $filtered.ContainsKey($w1Key) | Should -BeTrue
        }

        It "E-Document Core change produces correct app folders" {
            $filtered = Get-FilteredProjectSettings -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $baseFolder
            $w1Key = 'build/projects/Apps (W1)'
            $appFolders = $filtered[$w1Key].appFolders
            $appFolders.Count | Should -Be 4
            $appFolders | Should -Contain '../../../src/Apps/W1/EDocument/App'
            $appFolders | Should -Contain '../../../src/Apps/W1/EDocumentConnectors/Avalara/App'
            $appFolders | Should -Contain '../../../src/Apps/W1/EDocumentConnectors/Continia/App'
            $appFolders | Should -Contain '../../../src/Apps/W1/EDocumentConnectors/ForNAV/App'
        }

        It "E-Document Core change produces correct test folders" {
            $filtered = Get-FilteredProjectSettings -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $baseFolder
            $w1Key = 'build/projects/Apps (W1)'
            $testFolders = $filtered[$w1Key].testFolders
            $testFolders.Count | Should -Be 5
            $testFolders | Should -Contain '../../../src/Apps/W1/EDocument/Test'
            $testFolders | Should -Contain '../../../src/Apps/W1/EDocument/Demo Data'
        }

        It "Subscription Billing change pulls in Power BI Reports (compilation closure)" {
            $filtered = Get-FilteredProjectSettings -ChangedFiles @('src/Apps/W1/Subscription Billing/App/src/SomeFile.al') -BaseFolder $baseFolder
            $w1Key = 'build/projects/Apps (W1)'
            $filtered.ContainsKey($w1Key) | Should -BeTrue
            $appFolders = $filtered[$w1Key].appFolders
            $appFolders | Should -Contain '../../../src/Apps/W1/PowerBIReports/App'
            $appFolders | Should -Contain '../../../src/Apps/W1/Subscription Billing/App'
        }

        It "Email change produces filtered settings for System Application projects" {
            $filtered = Get-FilteredProjectSettings -ChangedFiles @('src/System Application/App/Email/src/SomeFile.al') -BaseFolder $baseFolder
            # System Application project should be affected (umbrella)
            $sysAppKey = 'build/projects/System Application'
            $filtered.ContainsKey($sysAppKey) | Should -BeTrue
            # System Application Modules should be affected
            $modulesKey = 'build/projects/System Application Modules'
            $filtered.ContainsKey($modulesKey) | Should -BeTrue
            $filtered[$modulesKey].appFolders.Count | Should -BeGreaterThan 10
        }

        It "non-app files only (build scripts) produce empty result" {
            $filtered = Get-FilteredProjectSettings -ChangedFiles @('build/scripts/SomeNewScript.ps1') -BaseFolder $baseFolder
            # No app files changed, so no projects are affected
            $filtered.Count | Should -Be 0
        }

        It "relative paths use forward slashes" {
            $filtered = Get-FilteredProjectSettings -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $baseFolder
            $w1Key = 'build/projects/Apps (W1)'
            foreach ($f in $filtered[$w1Key].appFolders) {
                $f | Should -Not -Match '\\'
            }
        }
    }

    Context "Get-ChangedFilesForCI" {
        It "returns null when not in CI environment" {
            $savedGitHubActions = $env:GITHUB_ACTIONS
            try {
                $env:GITHUB_ACTIONS = $null
                $result = Get-ChangedFilesForCI
                $result | Should -BeNullOrEmpty
            } finally {
                $env:GITHUB_ACTIONS = $savedGitHubActions
            }
        }

        It "returns null for workflow_dispatch" {
            $savedGitHubActions = $env:GITHUB_ACTIONS
            $savedEventName = $env:GITHUB_EVENT_NAME
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'workflow_dispatch'
                $result = Get-ChangedFilesForCI
                $result | Should -BeNullOrEmpty
            } finally {
                $env:GITHUB_ACTIONS = $savedGitHubActions
                $env:GITHUB_EVENT_NAME = $savedEventName
            }
        }
    }

    Context "Test-ShouldSkipTestApp" {
        It "returns false when not in CI environment" {
            $savedGitHubActions = $env:GITHUB_ACTIONS
            try {
                $env:GITHUB_ACTIONS = $null
                $result = Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder
                $result | Should -BeFalse
            } finally {
                $env:GITHUB_ACTIONS = $savedGitHubActions
            }
        }

        It "returns false for workflow_dispatch" {
            $savedGitHubActions = $env:GITHUB_ACTIONS
            $savedEventName = $env:GITHUB_EVENT_NAME
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'workflow_dispatch'
                $result = Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder
                $result | Should -BeFalse
            } finally {
                $env:GITHUB_ACTIONS = $savedGitHubActions
                $env:GITHUB_EVENT_NAME = $savedEventName
            }
        }

        It "returns false when BUILD_OPTIMIZATION_DISABLED is true" {
            $savedDisabled = $env:BUILD_OPTIMIZATION_DISABLED
            $savedGitHubActions = $env:GITHUB_ACTIONS
            try {
                $env:BUILD_OPTIMIZATION_DISABLED = 'true'
                $env:GITHUB_ACTIONS = 'true'
                $result = Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder
                $result | Should -BeFalse
            } finally {
                $env:BUILD_OPTIMIZATION_DISABLED = $savedDisabled
                $env:GITHUB_ACTIONS = $savedGitHubActions
            }
        }

        It "reads from cache file when it exists" {
            $savedGitHubActions = $env:GITHUB_ACTIONS
            $savedEventName = $env:GITHUB_EVENT_NAME
            $savedRunnerTemp = $env:RUNNER_TEMP
            $tempDir = Join-Path $env:TEMP "build-opt-test-$(Get-Random)"
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'pull_request'
                $env:RUNNER_TEMP = $tempDir

                # Write a cache file with known affected apps
                $cache = [PSCustomObject]@{
                    skipEnabled = $true
                    affectedAppNames = @('E-Document Core', 'E-Document Core Tests')
                }
                $cache | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $tempDir 'build-optimization-cache.json') -Encoding UTF8

                # Affected app should NOT be skipped
                $result = Test-ShouldSkipTestApp -AppName 'E-Document Core Tests' -BaseFolder $baseFolder
                $result | Should -BeFalse

                # Unaffected app SHOULD be skipped
                $result = Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder
                $result | Should -BeTrue
            } finally {
                $env:GITHUB_ACTIONS = $savedGitHubActions
                $env:GITHUB_EVENT_NAME = $savedEventName
                $env:RUNNER_TEMP = $savedRunnerTemp
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "performs case-insensitive app name matching" {
            $savedGitHubActions = $env:GITHUB_ACTIONS
            $savedEventName = $env:GITHUB_EVENT_NAME
            $savedRunnerTemp = $env:RUNNER_TEMP
            $tempDir = Join-Path $env:TEMP "build-opt-test-$(Get-Random)"
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'pull_request'
                $env:RUNNER_TEMP = $tempDir

                $cache = [PSCustomObject]@{
                    skipEnabled = $true
                    affectedAppNames = @('E-Document Core Tests')
                }
                $cache | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $tempDir 'build-optimization-cache.json') -Encoding UTF8

                # Case-insensitive match should work
                $result = Test-ShouldSkipTestApp -AppName 'e-document core tests' -BaseFolder $baseFolder
                $result | Should -BeFalse
            } finally {
                $env:GITHUB_ACTIONS = $savedGitHubActions
                $env:GITHUB_EVENT_NAME = $savedEventName
                $env:RUNNER_TEMP = $savedRunnerTemp
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "returns false when cache says skipEnabled is false" {
            $savedGitHubActions = $env:GITHUB_ACTIONS
            $savedEventName = $env:GITHUB_EVENT_NAME
            $savedRunnerTemp = $env:RUNNER_TEMP
            $tempDir = Join-Path $env:TEMP "build-opt-test-$(Get-Random)"
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'pull_request'
                $env:RUNNER_TEMP = $tempDir

                $cache = [PSCustomObject]@{
                    skipEnabled = $false
                    affectedAppNames = @()
                }
                $cache | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $tempDir 'build-optimization-cache.json') -Encoding UTF8

                # Even unrelated app should not be skipped when skipEnabled is false
                $result = Test-ShouldSkipTestApp -AppName 'Shopify' -BaseFolder $baseFolder
                $result | Should -BeFalse
            } finally {
                $env:GITHUB_ACTIONS = $savedGitHubActions
                $env:GITHUB_EVENT_NAME = $savedEventName
                $env:RUNNER_TEMP = $savedRunnerTemp
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
