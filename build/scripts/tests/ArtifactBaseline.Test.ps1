Describe "ArtifactBaseline" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1" -Force
        Import-Module "$PSScriptRoot\..\BuildOptimization.psm1" -Force
        Import-Module "$PSScriptRoot\..\ArtifactBaseline.psm1" -Force

        $script:baseFolder = Get-BaseFolder
        $script:testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "ArtifactBaselineTests_$([guid]::NewGuid().ToString('N'))"
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null

        function New-ArtifactFolder {
            param([hashtable] $Manifest)
            $folder = Join-Path $script:testRoot ([guid]::NewGuid().ToString('N'))
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
            if ($null -ne $Manifest) {
                $Manifest | ConvertTo-Json | Set-Content -Path (Join-Path $folder 'manifest.json') -Encoding UTF8
            }
            return $folder
        }
    }

    AfterAll {
        if (Test-Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Get-ArtifactBaselineCommit" {
        AfterEach {
            $env:BCAPPS_ARTIFACT_BASELINE_COMMIT = $null
        }

        It "reads the documented manifest property" {
            $folder = New-ArtifactFolder -Manifest @{
                country = 'W1'; version = '29.0.53000.0'
                bcAppsCommit = '2b72269851ab0c2e2f9d4d8e0e0a1b2c3d4e5f60'
            }
            $manifest = Get-ArtifactManifest -ArtifactFolder $folder
            Get-ArtifactBaselineCommit -Manifest $manifest | Should -Be '2b72269851ab0c2e2f9d4d8e0e0a1b2c3d4e5f60'
        }

        It "accepts the alternative property spellings" {
            foreach ($property in @('bcAppsCommitSha', 'applicationCommit', 'sourceCommit')) {
                $manifest = [PSCustomObject]@{ $property = 'AABBCCDDEEFF00112233445566778899AABBCCDD' }
                Get-ArtifactBaselineCommit -Manifest $manifest | Should -Be 'aabbccddeeff00112233445566778899aabbccdd'
            }
        }

        It "ignores a value that is not a full SHA" {
            $manifest = [PSCustomObject]@{ bcAppsCommit = 'main' }
            Get-ArtifactBaselineCommit -Manifest $manifest | Should -BeNullOrEmpty
        }

        It "returns nothing when the manifest has no commit" {
            $folder = New-ArtifactFolder -Manifest @{ country = 'W1'; version = '29.0.53000.0' }
            $manifest = Get-ArtifactManifest -ArtifactFolder $folder
            Get-ArtifactBaselineCommit -Manifest $manifest | Should -BeNullOrEmpty
        }

        It "returns nothing when there is no manifest at all" {
            $folder = New-ArtifactFolder -Manifest $null
            Get-ArtifactManifest -ArtifactFolder $folder | Should -BeNullOrEmpty
            Get-ArtifactBaselineCommit -Manifest $null | Should -BeNullOrEmpty
        }

        It "can be overridden by the environment for testing" {
            $env:BCAPPS_ARTIFACT_BASELINE_COMMIT = '1111111111111111111111111111111111111111'
            $manifest = [PSCustomObject]@{ bcAppsCommit = '2222222222222222222222222222222222222222' }
            Get-ArtifactBaselineCommit -Manifest $manifest | Should -Be '1111111111111111111111111111111111111111'
        }
    }

    Context "Test-CommitAvailable" {
        It "finds a commit that exists in this clone" {
            $head = (git -C $script:baseFolder rev-parse HEAD).Trim()
            Test-CommitAvailable -Sha $head -BaseFolder $script:baseFolder | Should -BeTrue
        }

        It "does not find a commit that does not exist" {
            Test-CommitAvailable -Sha '0000000000000000000000000000000000000001' -BaseFolder $script:baseFolder | Should -BeFalse
        }
    }

    Context "Get-ChangedFilesSinceCommit" {
        It "lists the files changed between two commits" {
            $head = (git -C $script:baseFolder rev-parse HEAD).Trim()
            $previous = (git -C $script:baseFolder rev-parse 'HEAD~1').Trim()
            $files = Get-ChangedFilesSinceCommit -BaselineCommit $previous -HeadSha $head -BaseFolder $script:baseFolder
            $files | Should -Not -BeNullOrEmpty
        }

        It "returns nothing when the commit cannot be diffed" {
            $files = Get-ChangedFilesSinceCommit -BaselineCommit '0000000000000000000000000000000000000001' -HeadSha 'HEAD' -BaseFolder $script:baseFolder
            $files | Should -BeNullOrEmpty
        }
    }

    Context "Get-ChangedAppNames" {
        BeforeAll {
            $script:graph = Get-AppDependencyGraph -BaseFolder $script:baseFolder
        }

        It "maps an app change to the app and its dependents" {
            $result = Get-ChangedAppNames -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $script:baseFolder -Graph $script:graph
            $result.IsUsable | Should -BeTrue
            $result.ChangedAppNames | Should -Contain 'E-Document Core'
            $result.ChangedAppNames | Should -Contain 'E-Document Core Tests'
            $result.ChangedAppNames | Should -Contain 'E-Document Connector - Avalara'
            $result.ChangedAppNames.Count | Should -BeLessThan $script:graph.Count
            $result.KnownAppNames | Should -Contain 'Base Application'
            $result.KnownAppNames.Count | Should -BeGreaterThan $result.ChangedAppNames.Count
        }

        It "reuses everything when only unrelated files changed" {
            $result = Get-ChangedAppNames -ChangedFiles @('README.md') -BaseFolder $script:baseFolder -Graph $script:graph
            $result.IsUsable | Should -BeTrue
            $result.ChangedAppNames.Count | Should -Be 0
        }

        It "reports no changes for an empty diff and still lists the known apps" {
            $result = Get-ChangedAppNames -ChangedFiles @() -BaseFolder $script:baseFolder -Graph $script:graph
            $result.IsUsable | Should -BeTrue
            $result.ChangedAppNames.Count | Should -Be 0
            $result.KnownAppNames | Should -Contain 'Base Application'
        }

        It "gives up when a fullBuildPattern matches" {
            $result = Get-ChangedAppNames -ChangedFiles @('build/scripts/NewBcContainer.ps1') -BaseFolder $script:baseFolder -Graph $script:graph
            $result.IsUsable | Should -BeFalse
            $result.Reason | Should -Match 'fullBuildPatterns'
        }

        It "gives up when an unmapped src file changed (full build fallback)" {
            $result = Get-ChangedAppNames -ChangedFiles @('src/SomeUnmappedFile.al') -BaseFolder $script:baseFolder -Graph $script:graph
            $result.IsUsable | Should -BeFalse
            $result.Reason | Should -Match 'apps are affected'
        }

        It "gives up when more than the allowed ratio of apps changed" {
            $result = Get-ChangedAppNames -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $script:baseFolder -Graph $script:graph -MaxChangedRatio 0.01
            $result.IsUsable | Should -BeFalse
            $result.Reason | Should -Match 'more than the'
        }
    }

    Context "Get-AppNameFromAppFile" {
        It "extracts the app name from the AL-Go file name convention" {
            Get-AppNameFromAppFile -Path 'C:\x\Microsoft_Tests-Local_29.0.2147483647.78225.app' | Should -Be 'Tests-Local'
        }

        It "handles names with underscores" {
            Get-AppNameFromAppFile -Path 'Microsoft__Exclude_APIV1_ Tests_29.0.1.0.app' | Should -Be '_Exclude_APIV1_ Tests'
        }

        It "returns nothing for a file that does not follow the convention" {
            Get-AppNameFromAppFile -Path 'SomeApp.app' | Should -BeNullOrEmpty
        }
    }

    Context "Get-AppsToUnpublish" {
        BeforeAll {
            $script:installed = @(
                [PSCustomObject]@{ Name = 'Tests-Local' }
                [PSCustomObject]@{ Name = 'E-Document Core' }
                [PSCustomObject]@{ Name = 'Base Application' }
                [PSCustomObject]@{ Name = 'AMC Banking 365 Fundamentals' }
            )
            $script:known = @('Tests-Local', 'E-Document Core', 'Base Application')
        }

        It "removes only the changed apps" {
            $result = @(Get-AppsToUnpublish -InstalledApps $script:installed -ChangedAppNames @('E-Document Core'))
            $result.Count | Should -Be 1
            $result[0].Name | Should -Be 'E-Document Core'
        }

        It "removes nothing when nothing changed" {
            (@(Get-AppsToUnpublish -InstalledApps $script:installed -ChangedAppNames @())).Count | Should -Be 0
        }

        It "matches app names case-insensitively" {
            $result = @(Get-AppsToUnpublish -InstalledApps $script:installed -ChangedAppNames @('base application'))
            $result.Count | Should -Be 1
            $result[0].Name | Should -Be 'Base Application'
        }

        It "preserves the given (DependenciesLast) order" {
            $result = @(Get-AppsToUnpublish -InstalledApps $script:installed -ChangedAppNames @('Base Application', 'Tests-Local'))
            $result[0].Name | Should -Be 'Tests-Local'
            $result[1].Name | Should -Be 'Base Application'
        }

        It "also removes apps this repository does not produce" {
            $result = @(Get-AppsToUnpublish -InstalledApps $script:installed -ChangedAppNames @() -KnownAppNames $script:known)
            $result.Count | Should -Be 1
            $result[0].Name | Should -Be 'AMC Banking 365 Fundamentals'
        }

        It "combines changed apps and unknown apps" {
            $result = @(Get-AppsToUnpublish -InstalledApps $script:installed -ChangedAppNames @('Tests-Local') -KnownAppNames $script:known)
            @($result | ForEach-Object { $_.Name }) | Should -Be @('Tests-Local', 'AMC Banking 365 Fundamentals')
        }
    }

    Context "Test-ShouldPublishAppFile" {
        BeforeAll {
            $script:containerApps = @('Base Application', 'E-Document Core', 'Tests-Local')
            $script:changed = @('E-Document Core')
        }

        It "publishes a changed app" {
            Test-ShouldPublishAppFile -AppFile 'Microsoft_E-Document Core_29.0.1.1.app' -ChangedAppNames $script:changed -ContainerAppNames $script:containerApps | Should -BeTrue
        }

        It "skips an unchanged app that the artifact already published" {
            Test-ShouldPublishAppFile -AppFile 'Microsoft_Base Application_29.0.1.1.app' -ChangedAppNames $script:changed -ContainerAppNames $script:containerApps | Should -BeFalse
        }

        It "publishes an app the container does not have" {
            Test-ShouldPublishAppFile -AppFile 'Microsoft_Brand New App_29.0.1.1.app' -ChangedAppNames $script:changed -ContainerAppNames $script:containerApps | Should -BeTrue
        }

        It "publishes when the file name convention is unknown" {
            Test-ShouldPublishAppFile -AppFile 'weird.app' -ChangedAppNames $script:changed -ContainerAppNames $script:containerApps | Should -BeTrue
        }
    }

    Context "Get-ArtifactFolder" {
        It "resolves the artifact url against the artifacts cache" {
            $cache = Join-Path $script:testRoot 'artifactcache'
            $artifact = Join-Path $cache 'sandbox\29.0.53000.0\base'
            New-Item -Path $artifact -ItemType Directory -Force | Out-Null

            Get-ArtifactFolder -ArtifactUrl 'https://bcinsider.example/sandbox/29.0.53000.0/base?sv=1&sig=x' -ArtifactsCacheFolder $cache |
                Should -Be $artifact
        }

        It "returns nothing for an artifact that is not cached (and does not download)" {
            $cache = Join-Path $script:testRoot 'artifactcache'
            Get-ArtifactFolder -ArtifactUrl 'https://bcinsider.example/sandbox/0.0.0.0/nowhere' -ArtifactsCacheFolder $cache |
                Should -BeNullOrEmpty
        }
    }

    Context "Resolve-ArtifactBaseline guards" {
        It "is not usable for a non-Default build mode" {
            $result = Resolve-ArtifactBaseline -ArtifactUrl 'https://x/sandbox/29.0.53000.0/w1' -BaseFolder $script:baseFolder -BuildMode 'Clean'
            $result.IsUsable | Should -BeFalse
            $result.Reason | Should -Match 'Build mode'
        }

        It "is not usable when disabled by environment" {
            $env:BCAPPS_ARTIFACT_BASELINE = 'disabled'
            try {
                $result = Resolve-ArtifactBaseline -ArtifactUrl 'https://x/sandbox/29.0.53000.0/w1' -BaseFolder $script:baseFolder
                $result.IsUsable | Should -BeFalse
                $result.Reason | Should -Match 'Disabled'
            }
            finally {
                $env:BCAPPS_ARTIFACT_BASELINE = $null
            }
        }

        It "is not usable when the artifact folder cannot be found" {
            $result = Resolve-ArtifactBaseline -ArtifactUrl 'https://x/sandbox/0.0.0.0/nowhere' -BaseFolder $script:baseFolder
            $result.IsUsable | Should -BeFalse
            $result.Reason | Should -Match 'artifact folder'
        }
    }

    Context "Build state" {
        BeforeAll {
            $script:originalRunnerTemp = $env:RUNNER_TEMP
            $env:RUNNER_TEMP = Join-Path $script:testRoot 'runner-temp'
            New-Item -Path $env:RUNNER_TEMP -ItemType Directory -Force | Out-Null
        }

        AfterAll {
            $env:RUNNER_TEMP = $script:originalRunnerTemp
        }

        It "round-trips the state between hook invocations" {
            Clear-ArtifactBaselineState
            Get-ArtifactBaselineState | Should -BeNullOrEmpty

            Set-ArtifactBaselineState -State @{
                IsUsable = $true; Reason = 'ok'; BaselineCommit = 'abc'
                ChangedAppNames = @('A', 'B'); ContainerAppNames = @('A', 'B', 'C')
            } | Out-Null

            $state = Get-ArtifactBaselineState
            $state.IsUsable | Should -BeTrue
            $state.BaselineCommit | Should -Be 'abc'
            @($state.ChangedAppNames).Count | Should -Be 2
            @($state.ContainerAppNames).Count | Should -Be 3

            Clear-ArtifactBaselineState
            Get-ArtifactBaselineState | Should -BeNullOrEmpty
        }
    }
}
