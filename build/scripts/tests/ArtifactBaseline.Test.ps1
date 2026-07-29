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

        function New-ContainerApp {
            param([string] $Name, [string] $Publisher = 'Microsoft')
            return [PSCustomObject]@{ Name = $Name; Publisher = $Publisher }
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
            $env:GITHUB_ACTIONS = $null
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
            Get-ArtifactBaselineCommit -Manifest ([PSCustomObject]@{ bcAppsCommit = 'main' }) | Should -BeNullOrEmpty
        }

        It "returns nothing when the manifest has no commit" {
            $folder = New-ArtifactFolder -Manifest @{ country = 'W1'; version = '29.0.53000.0' }
            Get-ArtifactBaselineCommit -Manifest (Get-ArtifactManifest -ArtifactFolder $folder) | Should -BeNullOrEmpty
        }

        It "returns nothing when there is no manifest at all" {
            $folder = New-ArtifactFolder -Manifest $null
            Get-ArtifactManifest -ArtifactFolder $folder | Should -BeNullOrEmpty
            Get-ArtifactBaselineCommit -Manifest $null | Should -BeNullOrEmpty
        }

        It "can be overridden by the environment locally" {
            $env:BCAPPS_ARTIFACT_BASELINE_COMMIT = '1111111111111111111111111111111111111111'
            $manifest = [PSCustomObject]@{ bcAppsCommit = '2222222222222222222222222222222222222222' }
            Get-ArtifactBaselineCommit -Manifest $manifest | Should -Be '1111111111111111111111111111111111111111'
        }

        It "ignores the environment override in CI so the manifest is the only source of truth" {
            $env:BCAPPS_ARTIFACT_BASELINE_COMMIT = '1111111111111111111111111111111111111111'
            $env:GITHUB_ACTIONS = 'true'
            $manifest = [PSCustomObject]@{ bcAppsCommit = '2222222222222222222222222222222222222222' }
            Get-ArtifactBaselineCommit -Manifest $manifest | Should -Be '2222222222222222222222222222222222222222'
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

        It "falls back to the BcContainerHelper config variable when no cache folder is given" {
            $cache = Join-Path $script:testRoot 'configcache'
            $artifact = Join-Path $cache 'sandbox\29.0.53000.0\base'
            New-Item -Path $artifact -ItemType Directory -Force | Out-Null

            # BcContainerHelper publishes this into the session; the module must find it without
            # being told where the cache is.
            New-Variable -Name bcContainerHelperConfig -Scope Global -Value ([PSCustomObject]@{ bcartifactsCacheFolder = $cache }) -Force
            try {
                Get-ArtifactFolder -ArtifactUrl 'https://bcinsider.example/sandbox/29.0.53000.0/base' | Should -Be $artifact
            }
            finally {
                Remove-Variable -Name bcContainerHelperConfig -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It "returns nothing for an artifact that is not cached (and does not download)" {
            $cache = Join-Path $script:testRoot 'artifactcache'
            Get-ArtifactFolder -ArtifactUrl 'https://bcinsider.example/sandbox/0.0.0.0/nowhere' -ArtifactsCacheFolder $cache |
                Should -BeNullOrEmpty
        }
    }

    Context "Test-BuildModeChangesCompilation" {
        It "rejects the build mode that sets preprocessor symbols" {
            Test-BuildModeChangesCompilation -BuildMode 'Clean' -BaseFolder $script:baseFolder | Should -BeTrue
        }

        It "allows the build modes the test projects actually use" {
            # Regression guard: an earlier version only allowed 'Default', which no container
            # project ever builds in, so the whole feature was a no-op.
            foreach ($mode in @('IntegrationTests', 'UncategorizedTests', 'LegacyTestsBucket1', 'LegacyTestsBucket2')) {
                Test-BuildModeChangesCompilation -BuildMode $mode -BaseFolder $script:baseFolder | Should -BeFalse -Because "$mode does not change compilation"
            }
        }

        It "allows Default and an empty build mode" {
            Test-BuildModeChangesCompilation -BuildMode 'Default' -BaseFolder $script:baseFolder | Should -BeFalse
            Test-BuildModeChangesCompilation -BuildMode '' -BaseFolder $script:baseFolder | Should -BeFalse
        }
    }

    Context "Test-CommitAvailable / Get-ChangedFilesSinceCommit" {
        It "finds a commit that exists in this clone" {
            $head = (git -C $script:baseFolder rev-parse HEAD).Trim()
            Test-CommitAvailable -Sha $head -BaseFolder $script:baseFolder | Should -BeTrue
        }

        It "does not find an unknown commit, and does not fetch into a complete clone" {
            # A complete clone must not be shallow-ified by the lookup.
            $wasShallow = (git -C $script:baseFolder rev-parse --is-shallow-repository).Trim()
            Test-CommitAvailable -Sha '0000000000000000000000000000000000000001' -BaseFolder $script:baseFolder | Should -BeFalse
            (git -C $script:baseFolder rev-parse --is-shallow-repository).Trim() | Should -Be $wasShallow
        }

        It "lists the files changed between two commits" {
            $head = (git -C $script:baseFolder rev-parse HEAD).Trim()
            $previous = (git -C $script:baseFolder rev-parse 'HEAD~1').Trim()
            $files = Get-ChangedFilesSinceCommit -BaselineCommit $previous -HeadSha $head -BaseFolder $script:baseFolder
            @($files).Count | Should -BeGreaterThan 0
        }

        It "returns an empty array (not null) when nothing changed" {
            $head = (git -C $script:baseFolder rev-parse HEAD).Trim()
            $files = Get-ChangedFilesSinceCommit -BaselineCommit $head -HeadSha $head -BaseFolder $script:baseFolder
            # The distinction matters: $null means "the diff failed" and disables reuse.
            $null -eq $files | Should -BeFalse
            @($files).Count | Should -Be 0
        }

        It "returns null when the diff cannot be produced" {
            $files = Get-ChangedFilesSinceCommit -BaselineCommit '0000000000000000000000000000000000000001' -HeadSha 'HEAD' -BaseFolder $script:baseFolder
            $null -eq $files | Should -BeTrue
        }
    }

    Context "Get-ChangedAppNames" {
        BeforeAll {
            $script:graph = Get-AppDependencyGraph -BaseFolder $script:baseFolder
        }

        It "maps an app change to the app and its dependents" {
            $result = Get-ChangedAppNames -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $script:baseFolder -Graph $script:graph
            $result.IsUsable | Should -BeTrue
            $result.ChangedApps | Should -Contain 'Microsoft_E-Document Core'
            $result.ChangedApps | Should -Contain 'Microsoft_E-Document Core Tests'
            $result.ChangedApps.Count | Should -BeLessThan $script:graph.Count
            $result.KnownApps | Should -Contain 'Microsoft_Base Application'
        }

        It "reuses everything when only unrelated files changed" {
            $result = Get-ChangedAppNames -ChangedFiles @('README.md') -BaseFolder $script:baseFolder -Graph $script:graph
            $result.IsUsable | Should -BeTrue
            $result.ChangedApps.Count | Should -Be 0
        }

        It "reports no changes for an empty diff and still lists the known apps" {
            $result = Get-ChangedAppNames -ChangedFiles @() -BaseFolder $script:baseFolder -Graph $script:graph
            $result.IsUsable | Should -BeTrue
            $result.ChangedApps.Count | Should -Be 0
            $result.KnownApps | Should -Contain 'Microsoft_Base Application'
        }

        It "gives up when a fullBuildPattern matches" {
            $result = Get-ChangedAppNames -ChangedFiles @('build/scripts/NewBcContainer.ps1') -BaseFolder $script:baseFolder -Graph $script:graph
            $result.IsUsable | Should -BeFalse
            $result.Reason | Should -Match 'fullBuildPatterns'
        }

        It "gives up when settings that change compilation are touched" {
            # These match no fullBuildPattern and map to no app, but they change preprocessor
            # symbols, analyzers or which apps a project builds.
            foreach ($file in @('.github/AL-Go-Settings.json', 'build/projects/Test Apps W1/.AL-Go/settings.json')) {
                $result = Get-ChangedAppNames -ChangedFiles @($file) -BaseFolder $script:baseFolder -Graph $script:graph
                $result.IsUsable | Should -BeFalse -Because "$file can change how apps are compiled"
            }
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

    Context "Get-AppFileIdentity / Get-AppKey" {
        It "extracts publisher, name and version from the AL-Go file name convention" {
            $identity = Get-AppFileIdentity -Path 'C:\x\Microsoft_Tests-Local_29.0.2147483647.78225.app'
            $identity.Publisher | Should -Be 'Microsoft'
            $identity.Name | Should -Be 'Tests-Local'
            $identity.Version | Should -Be '29.0.2147483647.78225'
            $identity.Key | Should -Be 'Microsoft_Tests-Local'
        }

        It "handles names containing underscores" {
            (Get-AppFileIdentity -Path 'Microsoft__Exclude_APIV1_ Tests_29.0.1.0.app').Name | Should -Be '_Exclude_APIV1_ Tests'
        }

        It "returns nothing for a file that does not follow the convention" {
            Get-AppFileIdentity -Path 'SomeApp.app' | Should -BeNullOrEmpty
        }

        It "keys on publisher and name, because names are not unique in this repo" {
            Get-AppKey -Publisher 'Microsoft' -Name 'Tests-Local' | Should -Be 'Microsoft_Tests-Local'
            Get-AppKey -Publisher 'Contoso' -Name 'Tests-Local' | Should -Not -Be 'Microsoft_Tests-Local'
        }
    }

    Context "Split-ContainerApps" {
        BeforeAll {
            $script:installed = @(
                New-ContainerApp 'Tests-Local'
                New-ContainerApp 'E-Document Core'
                New-ContainerApp 'Base Application'
                New-ContainerApp 'Prevent Metadata Updates Library'
                New-ContainerApp 'Third Party Thing' -Publisher 'Contoso'
            )
            $script:known = @(
                'Microsoft_Tests-Local', 'Microsoft_E-Document Core', 'Microsoft_Base Application',
                'Microsoft_Prevent Metadata Updates Library'
            )
        }

        It "keeps unchanged apps and unpublishes changed ones" {
            $split = Split-ContainerApps -InstalledApps $script:installed -ChangedApps @('Microsoft_E-Document Core') -KnownApps $script:known
            @($split.ToUnpublish | ForEach-Object { $_.Name }) | Should -Contain 'E-Document Core'
            @($split.ToKeep | ForEach-Object { $_.Name }) | Should -Contain 'Base Application'
            @($split.ToKeep | ForEach-Object { $_.Name }) | Should -Contain 'Tests-Local'
        }

        It "always unpublishes apps that must never be in a test container" {
            $split = Split-ContainerApps -InstalledApps $script:installed -ChangedApps @() -KnownApps $script:known
            @($split.ToKeep | ForEach-Object { $_.Name }) | Should -Not -Contain 'Prevent Metadata Updates Library'
            @($split.ToUnpublish | ForEach-Object { $_.Name }) | Should -Contain 'Prevent Metadata Updates Library'
        }

        It "unpublishes apps this repository does not produce" {
            $split = Split-ContainerApps -InstalledApps $script:installed -ChangedApps @() -KnownApps $script:known
            @($split.ToUnpublish | ForEach-Object { $_.Name }) | Should -Contain 'Third Party Thing'
        }

        It "does not confuse apps that share a name but differ in publisher" {
            $installed = @(New-ContainerApp 'Tests-Local' -Publisher 'Contoso')
            $split = Split-ContainerApps -InstalledApps $installed -ChangedApps @() -KnownApps @('Microsoft_Tests-Local')
            @($split.ToKeep).Count | Should -Be 0
            @($split.ToUnpublish).Count | Should -Be 1
        }

        It "keeps nothing when everything changed" {
            $changed = @($script:installed | ForEach-Object { Get-AppKey -Publisher $_.Publisher -Name $_.Name })
            $split = Split-ContainerApps -InstalledApps $script:installed -ChangedApps $changed -KnownApps $script:known
            @($split.ToKeep).Count | Should -Be 0
            @($split.ToUnpublish).Count | Should -Be $script:installed.Count
        }

        It "handles an empty container" {
            $split = Split-ContainerApps -InstalledApps @() -ChangedApps @() -KnownApps $script:known
            @($split.ToKeep).Count | Should -Be 0
            @($split.ToUnpublish).Count | Should -Be 0
        }
    }

    Context "Test-ShouldPublishAppFile" {
        BeforeAll {
            $script:retained = @('Microsoft_Base Application', 'Microsoft_E-Document Core', 'Microsoft_Tests-Local')
            $script:changed = @('Microsoft_E-Document Core')
        }

        It "publishes a changed app even when it is retained" {
            Test-ShouldPublishAppFile -AppFile 'Microsoft_E-Document Core_29.0.1.1.app' -ChangedApps $script:changed -RetainedApps $script:retained | Should -BeTrue
        }

        It "skips an unchanged app the artifact already published" {
            Test-ShouldPublishAppFile -AppFile 'Microsoft_Base Application_29.0.1.1.app' -ChangedApps $script:changed -RetainedApps $script:retained | Should -BeFalse
        }

        It "publishes an app the container does not hold" {
            Test-ShouldPublishAppFile -AppFile 'Microsoft_Brand New App_29.0.1.1.app' -ChangedApps $script:changed -RetainedApps $script:retained | Should -BeTrue
        }

        It "publishes an app from a different publisher with the same name" {
            Test-ShouldPublishAppFile -AppFile 'Contoso_Base Application_29.0.1.1.app' -ChangedApps $script:changed -RetainedApps $script:retained | Should -BeTrue
        }

        It "publishes when the file name convention is unknown" {
            Test-ShouldPublishAppFile -AppFile 'weird.app' -ChangedApps $script:changed -RetainedApps $script:retained | Should -BeTrue
        }
    }

    Context "Resolve-ArtifactBaseline" {
        BeforeAll {
            $script:cache = Join-Path $script:testRoot 'resolvecache'
            $script:artifact = Join-Path $script:cache 'sandbox\29.0.53000.0\base'
            New-Item -Path $script:artifact -ItemType Directory -Force | Out-Null
            $script:artifactUrl = 'https://bcinsider.example/sandbox/29.0.53000.0/base'
            $script:head = (git -C $script:baseFolder rev-parse HEAD).Trim()
        }

        BeforeEach {
            New-Variable -Name bcContainerHelperConfig -Scope Global -Value ([PSCustomObject]@{ bcartifactsCacheFolder = $script:cache }) -Force
        }

        AfterEach {
            Remove-Variable -Name bcContainerHelperConfig -Scope Global -ErrorAction SilentlyContinue
            $env:BCAPPS_ARTIFACT_BASELINE = $null
        }

        It "resolves end to end when the artifact was built from this very commit" {
            @{ country = 'W1'; version = '29.0.53000.0'; bcAppsCommit = $script:head } |
                ConvertTo-Json | Set-Content -Path (Join-Path $script:artifact 'manifest.json') -Encoding UTF8

            $result = Resolve-ArtifactBaseline -ArtifactUrl $script:artifactUrl -BaseFolder $script:baseFolder -BuildMode 'IntegrationTests'

            $result.IsUsable | Should -BeTrue
            $result.BaselineCommit | Should -Be $script:head
            $result.ChangedApps.Count | Should -Be 0
            $result.KnownApps.Count | Should -BeGreaterThan 300
        }

        It "is not usable for a build mode that changes compilation" {
            $result = Resolve-ArtifactBaseline -ArtifactUrl $script:artifactUrl -BaseFolder $script:baseFolder -BuildMode 'Clean'
            $result.IsUsable | Should -BeFalse
            $result.Reason | Should -Match 'preprocessor'
        }

        It "is not usable when disabled by environment" {
            $env:BCAPPS_ARTIFACT_BASELINE = 'disabled'
            $result = Resolve-ArtifactBaseline -ArtifactUrl $script:artifactUrl -BaseFolder $script:baseFolder
            $result.IsUsable | Should -BeFalse
            $result.Reason | Should -Match 'Disabled'
        }

        It "is not usable when the manifest carries no commit" {
            @{ country = 'W1'; version = '29.0.53000.0' } |
                ConvertTo-Json | Set-Content -Path (Join-Path $script:artifact 'manifest.json') -Encoding UTF8
            $result = Resolve-ArtifactBaseline -ArtifactUrl $script:artifactUrl -BaseFolder $script:baseFolder
            $result.IsUsable | Should -BeFalse
            $result.Reason | Should -Match 'does not carry a BCApps commit'
        }

        It "is not usable when the commit is unknown to this clone" {
            @{ country = 'W1'; bcAppsCommit = '0000000000000000000000000000000000000001' } |
                ConvertTo-Json | Set-Content -Path (Join-Path $script:artifact 'manifest.json') -Encoding UTF8
            $result = Resolve-ArtifactBaseline -ArtifactUrl $script:artifactUrl -BaseFolder $script:baseFolder
            $result.IsUsable | Should -BeFalse
            $result.Reason | Should -Match 'not reachable'
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
            $env:GITHUB_RUN_ID = $null
            $env:GITHUB_RUN_ATTEMPT = $null
        }

        BeforeEach {
            Clear-ArtifactBaselineState
            $env:GITHUB_RUN_ID = '1000'
            $env:GITHUB_RUN_ATTEMPT = '1'
        }

        It "round-trips the state between hook invocations" {
            Set-ArtifactBaselineState -ContainerName 'bcbuild' -State @{
                IsUsable = $true; Reason = 'ok'; ChangedApps = @('Microsoft_A'); RetainedApps = @('Microsoft_B', 'Microsoft_C')
            } | Out-Null

            $state = Get-ArtifactBaselineState -ContainerName 'bcbuild'
            $state.IsUsable | Should -BeTrue
            @($state.ChangedApps).Count | Should -Be 1
            @($state.RetainedApps).Count | Should -Be 2
        }

        It "ignores state written for a different container" {
            Set-ArtifactBaselineState -ContainerName 'bcbuild' -State @{ IsUsable = $true; RetainedApps = @() } | Out-Null
            Get-ArtifactBaselineState -ContainerName 'someothercontainer' | Should -BeNullOrEmpty
        }

        It "ignores state from a previous run on the same runner" {
            Set-ArtifactBaselineState -ContainerName 'bcbuild' -State @{ IsUsable = $true; RetainedApps = @() } | Out-Null
            $env:GITHUB_RUN_ID = '1001'
            Get-ArtifactBaselineState -ContainerName 'bcbuild' | Should -BeNullOrEmpty
        }

        It "ignores state from a re-run of the same workflow run" {
            Set-ArtifactBaselineState -ContainerName 'bcbuild' -State @{ IsUsable = $true; RetainedApps = @() } | Out-Null
            $env:GITHUB_RUN_ATTEMPT = '2'
            Get-ArtifactBaselineState -ContainerName 'bcbuild' | Should -BeNullOrEmpty
        }

        It "returns nothing when there is no state" {
            Get-ArtifactBaselineState -ContainerName 'bcbuild' | Should -BeNullOrEmpty
        }
    }

    Context "Exclusion list" {
        It "is shared with the publish hook so both agree" {
            $never = Get-AppsNeverInContainer
            $never | Should -Contain 'Library - No Transactions'
            $never | Should -Contain 'Prevent Metadata Updates Library'
        }

        It "covers apps that this repository actually produces" {
            # If these were not repo apps they would be unpublished anyway; the point of the
            # shared list is that they ARE repo apps and would otherwise look reusable.
            $graph = Get-AppDependencyGraph -BaseFolder $script:baseFolder
            $names = @($graph.Values | ForEach-Object { $_.Name })
            foreach ($app in (Get-AppsNeverInContainer)) {
                $names | Should -Contain $app
            }
        }
    }
}
