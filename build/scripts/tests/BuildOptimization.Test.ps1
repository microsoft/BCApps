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
        It "returns the E-Document Core change as affecting the full connector/test/demo-data set" {
            $affected = Get-AffectedApps -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $baseFolder -Graph $graph
            # E-Document Core fans out to every connector, country demo-data, format and test app that depends on it.
            # Derive the expected set from the graph (E-Document Core + all transitive dependents) so the
            # assertion stays correct when new E-Document apps are added or removed.
            $edocCoreId = 'e1d97edc-c239-46b4-8d84-6368bdf67c8b'
            $expectedIds = [System.Collections.Generic.HashSet[string]]::new()
            $bfsQueue = [System.Collections.Generic.Queue[string]]::new()
            $bfsQueue.Enqueue($edocCoreId)
            while ($bfsQueue.Count -gt 0) {
                $current = $bfsQueue.Dequeue()
                if ($expectedIds.Contains($current)) { continue }
                [void]$expectedIds.Add($current)
                foreach ($dep in $graph[$current].Dependents) {
                    if (-not $expectedIds.Contains($dep)) { $bfsQueue.Enqueue($dep) }
                }
            }
            $affected.Count | Should -Be $expectedIds.Count
            $affected | Should -Contain $edocCoreId
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

    Context "Compiled app ownership" {
        BeforeAll {
            $script:createdAlGoModule = -not (Get-Module DetermineProjectsToBuild)
            if ($script:createdAlGoModule) {
                New-Module -Name DetermineProjectsToBuild -ScriptBlock {
                    function ReadSettings {
                        param($baseFolder, $project, $buildMode)
                        $null = $baseFolder, $project, $buildMode
                        throw 'AL-Go settings must be mocked in unit tests.'
                    }
                    function ResolveProjectFolders {
                        param($baseFolder, $project, $projectSettings)
                        $null = $baseFolder, $project, $projectSettings
                        throw 'AL-Go folder resolution must be mocked in unit tests.'
                    }
                    Export-ModuleMember -Function @()
                } | Import-Module
            }
            $script:compiledRoots = @(
                'src\System Application\App', 'src\System Application\Test',
                'src\Apps\W1\EDocument\App', 'src\Apps\W1\EDocument\Test'
            ) | ForEach-Object { Join-Path $baseFolder $_ }
            $script:compiledGraph = Get-AppDependencyGraph -BaseFolder $baseFolder -AppFolders $script:compiledRoots
        }

        AfterAll {
            if ($script:createdAlGoModule) { Remove-Module DetermineProjectsToBuild }
        }

        It "follows projectsToTest and delegates effective country settings and folder resolution to AL-Go" {
            Mock -ModuleName DetermineProjectsToBuild ReadSettings {
                $settings = @{ appFolders = @(); testFolders = @(); bcptTestFolders = @(); projectsToTest = @() }
                $json = Get-Content (Join-Path $baseFolder "$project\.AL-Go\settings.json") -Raw | ConvertFrom-Json
                foreach ($key in @('appFolders', 'testFolders', 'bcptTestFolders', 'projectsToTest')) {
                    if ($json.PSObject.Properties.Name -contains $key) { $settings[$key] = $json.$key }
                }
                return $settings
            }
            Mock -ModuleName DetermineProjectsToBuild ResolveProjectFolders { }
            InModuleScope BuildOptimization -Parameters @{ Root = $baseFolder } {
                $roots = @(Get-CompiledAppFolders -BaseFolder $Root -Project 'build/projects/Test Apps DE')
                $roots | Should -Contain (Join-Path $Root 'src\System Application\Test')
                $roots | Should -Not -Contain (Join-Path $Root 'src\System Application\Test\Email')
                $countryGraph = Get-AppDependencyGraph -BaseFolder $Root -AppFolders $roots
                $countryGraph['0d60b215-6ee1-4789-8e53-866cfa50c23c'].Name | Should -Be 'System Application Test'
            }
            Should -Invoke -ModuleName DetermineProjectsToBuild ReadSettings -Times 1 -ParameterFilter { $project -eq 'build/projects/Apps DE' }
            Should -Invoke -ModuleName DetermineProjectsToBuild ResolveProjectFolders -Times 1 -Exactly -ParameterFilter { $project -eq 'build/projects/Apps DE' }
        }

        It "maps an Email test change to the compiled aggregate, not its nested component manifest" {
            $id = Get-AppForFile -FilePath 'src/System Application/Test/Email/Changed.al' -BaseFolder $baseFolder -Graph $script:compiledGraph
            $script:compiledGraph[$id].Name | Should -Be 'System Application Test'
        }

        It "includes compiled dependents of a component app change" {
            $affected = Get-AffectedApps -ChangedFiles @('src/System Application/App/Email/Changed.al') `
                -BaseFolder $baseFolder -Graph $script:compiledGraph
            $names = @($affected | ForEach-Object { $script:compiledGraph[$_].Name })
            $names | Should -Contain 'System Application'
            $names | Should -Contain 'System Application Test'
        }

        It "keeps ordinary extension ownership and observes root path boundaries" {
            Get-AppForFile -FilePath 'src/Apps/W1/EDocument/App/src/Changed.al' -BaseFolder $baseFolder -Graph $script:compiledGraph |
                Should -Be 'e1d97edc-c239-46b4-8d84-6368bdf67c8b'
            Get-AppForFile -FilePath 'src/System Application/Application/Changed.al' -BaseFolder $baseFolder -Graph $script:compiledGraph |
                Should -BeNullOrEmpty
        }

        It "uses a component root only when it is declared in the compilation graph" {
            $moduleGraph = Get-AppDependencyGraph -BaseFolder $baseFolder `
                -AppFolders @($script:compiledRoots + (Join-Path $baseFolder 'src\System Application\App\Email'))
            Get-AppForFile -FilePath 'src/System Application/App/Email/Changed.al' -BaseFolder $baseFolder -Graph $moduleGraph |
                Should -Be '9c4a2cf2-be3a-4aa3-833b-99a5ffd11f25'
        }

        It "does not silently overwrite duplicate compiled app identities" {
            { Get-AppDependencyGraph -BaseFolder $baseFolder -AppFolders @($script:compiledRoots[0], $script:compiledRoots[0]) } |
                Should -Throw '*Compiled app ID*occurs in both*'
        }

        It "uses the active compilation graph in the churn proposal" {
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedDisabled = $env:BUILD_OPTIMIZATION_DISABLED
            Mock -ModuleName BuildOptimization Get-ChangedFilesForCI { @('src/System Application/Test/Email/Changed.al') }
            Mock -ModuleName BuildOptimization Get-CompiledAppFolders { $script:compiledRoots }
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'pull_request'
                $env:BUILD_OPTIMIZATION_DISABLED = $null
                $result = Get-AffectedAppNames -BaseFolder $baseFolder -Project 'build/projects/Test Apps DE'
                $result.RunAll | Should -BeFalse
                $result.AppNames | Should -Contain 'System Application Test'
                $result.AppNames | Should -Not -Contain 'Email Test'
                Should -Invoke -ModuleName BuildOptimization Get-CompiledAppFolders -Times 1 -ParameterFilter {
                    $Project -eq 'build/projects/Test Apps DE'
                }
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:BUILD_OPTIMIZATION_DISABLED = $savedDisabled
            }
        }
    }

    Context "Initialize-GitCommit" {
        It "returns only a boolean when fetch exits with <ExitCode> and writes stdout" -ForEach @(
            @{ ExitCode = 0; Expected = $true }
            @{ ExitCode = 128; Expected = $false }
        ) {
            InModuleScope BuildOptimization -Parameters @{ ExitCode = $ExitCode; Expected = $Expected } {
                Mock git {
                    $global:LASTEXITCODE = 128
                    if ($args -contains 'fetch') {
                        $global:LASTEXITCODE = $ExitCode
                        'fetch output'
                    }
                }
                $result = Initialize-GitCommit -CommitSha ('a' * 40)
                $result | Should -BeOfType [bool]
                $result | Should -Be $Expected
            }
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

                $result = @(Get-ChangedFilesForCI)
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

                $result = @(Get-ChangedFilesForCI)
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -BeGreaterOrEqual 1
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:GITHUB_EVENT_PATH = $savedEventPath
                if ($tempFile) { Remove-Item $tempFile -ErrorAction SilentlyContinue }
            }
        }

        It "compares a depth-one PR merge checkout with merge comparison <UseMerge>" -ForEach @(
            @{ UseMerge = $false }, @{ UseMerge = $true }
        ) {
            $source = Join-Path $TestDrive "merge-source-$UseMerge"
            $checkout = Join-Path $TestDrive "merge-checkout-$UseMerge"
            git init --quiet $source
            git -C $source -c user.name=Test -c user.email=test@example.com commit --quiet --allow-empty -m initial
            git -C $source checkout --quiet -b feature
            Set-Content (Join-Path $source 'feature.txt') 'feature change'
            git -C $source add .
            git -C $source -c user.name=Test -c user.email=test@example.com commit --quiet -m feature
            $headSha = git -C $source rev-parse HEAD
            git -C $source checkout --quiet -b target HEAD~1
            Set-Content (Join-Path $source 'target.txt') 'target change'
            git -C $source add .
            git -C $source -c user.name=Test -c user.email=test@example.com commit --quiet -m target
            $baseSha = git -C $source rev-parse HEAD
            git -C $source -c user.name=Test -c user.email=test@example.com merge --quiet --no-ff feature -m merge
            $mergeSha = git -C $source rev-parse HEAD
            git clone --quiet --depth=1 ([uri]$source).AbsoluteUri $checkout
            $LASTEXITCODE | Should -Be 0
            git -C $checkout rev-parse --is-shallow-repository | Should -Be 'true'
            git -C $checkout cat-file -e "$headSha^{commit}" 2>$null
            $LASTEXITCODE | Should -Not -Be 0

            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedEventPath = $env:GITHUB_EVENT_PATH
            $savedSha = $env:GITHUB_SHA
            $eventFile = Join-Path $TestDrive 'merge-event.json'
            $eventBase = if ($UseMerge) { git -C $source rev-parse "$baseSha~1" } else { $baseSha }
            @{ pull_request = @{ base = @{ sha = $eventBase }; head = @{ sha = $headSha } } } |
                ConvertTo-Json -Depth 5 | Set-Content $eventFile
            New-Item -ItemType Directory -Path (Join-Path $checkout 'build') | Out-Null
            Push-Location (Join-Path $checkout 'build')
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'pull_request'
                $env:GITHUB_EVENT_PATH = $eventFile
                $env:GITHUB_SHA = $mergeSha
                $result = @(Get-ChangedFilesForCI -CompareWithPullRequestMerge:$UseMerge)
                $result | Should -Contain 'feature.txt'
                if ($UseMerge) {
                    $result | Should -Not -Contain 'target.txt'
                    $result.Count | Should -Be 1
                    git cat-file -e "$baseSha^{commit}"
                    $LASTEXITCODE | Should -Be 0
                    git cat-file -e "$headSha^{commit}" 2>$null
                    $LASTEXITCODE | Should -Not -Be 0
                } else {
                    $result | Should -Contain 'target.txt'
                    $result.Count | Should -Be 2
                }
            } finally {
                Pop-Location
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:GITHUB_EVENT_PATH = $savedEventPath
                $env:GITHUB_SHA = $savedSha
            }
        }

        It "includes both rename owners and a moved-out full-build path only for impact analysis" {
            $repo = Join-Path $TestDrive 'renames'
            git init --quiet $repo
            git -C $repo config diff.renames true
            foreach ($folder in @('src\First', 'src\Second', '.github', 'docs')) {
                New-Item -ItemType Directory -Path (Join-Path $repo $folder) -Force | Out-Null
            }
            foreach ($name in @('First', 'Second')) {
                @{ id = $name; name = $name; dependencies = @() } | ConvertTo-Json |
                    Set-Content (Join-Path $repo "src\$name\app.json")
            }
            Set-Content (Join-Path $repo 'src\First\Code.al') 'unchanged AL content'
            Set-Content (Join-Path $repo '.github\config.json') '{"unchanged":true}'
            git -C $repo add .
            git -C $repo -c user.name=Test -c user.email=test@example.com commit --quiet -m initial
            $baseSha = git -C $repo rev-parse HEAD
            git -C $repo mv src/First/Code.al src/Second/Code.al
            git -C $repo mv .github/config.json docs/config.json
            Set-Content (Join-Path $repo 'src\Second\New.al') 'new AL content'
            git -C $repo add .
            git -C $repo -c user.name=Test -c user.email=test@example.com commit --quiet -m rename
            $headSha = git -C $repo rev-parse HEAD
            $eventFile = Join-Path $TestDrive 'rename-event.json'
            @{ before = $baseSha; after = $headSha } | ConvertTo-Json | Set-Content $eventFile
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedEventPath = $env:GITHUB_EVENT_PATH
            Push-Location $repo
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'push'
                $env:GITHUB_EVENT_PATH = $eventFile
                $files = @(Get-ChangedFilesForCI -CompareWithPullRequestMerge)
                $files | Should -Contain 'src/First/Code.al'
                $files | Should -Contain 'src/Second/Code.al'
                $files | Should -Contain '.github/config.json'
                Test-FullBuildPatternsMatch -ChangedFiles $files -BaseFolder $baseFolder | Should -BeTrue
                $renameGraph = Get-AppDependencyGraph -BaseFolder $repo -AppFolders @(
                    (Join-Path $repo 'src\First'), (Join-Path $repo 'src\Second')
                )
                $affected = @(Get-AffectedApps -ChangedFiles $files -BaseFolder $repo -Graph $renameGraph)
                $affected | Should -Contain 'first'
                $affected | Should -Contain 'second'
                @(Get-ChangedFilesForCI -DiffFilter A -CompareFromMergeBase -RequireChangeDetection) |
                    Should -Be @('src/Second/New.al')
            } finally {
                Pop-Location
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:GITHUB_EVENT_PATH = $savedEventPath
            }
        }

        It "rejects an unverified tested merge: <Case>" -ForEach @(
            @{ Case = 'missing workflow SHA'; WorkflowSha = ''; Parents = @('a', 'b') }
            @{ Case = 'checkout mismatch'; WorkflowSha = 'd' * 40; Parents = @('a', 'b') }
            @{ Case = 'non-merge'; WorkflowSha = 'c' * 40; Parents = @('a') }
            @{ Case = 'wrong PR head'; WorkflowSha = 'c' * 40; Parents = @('a', 'd') }
            @{ Case = 'more than two parents'; WorkflowSha = 'c' * 40; Parents = @('a', 'b', 'd') }
        ) {
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedEventPath = $env:GITHUB_EVENT_PATH
            $savedSha = $env:GITHUB_SHA
            $eventFile = Join-Path $TestDrive 'invalid-merge-event.json'
            @{ pull_request = @{ base = @{ sha = 'a' * 40 }; head = @{ sha = 'b' * 40 } } } |
                ConvertTo-Json -Depth 5 | Set-Content $eventFile
            Mock -ModuleName BuildOptimization git -MockWith ({
                $global:LASTEXITCODE = 0
                if ($args -contains 'rev-parse') { return 'c' * 40 }
                if ($args -contains '-p') {
                    foreach ($parent in $Parents) { "parent $($parent * 40)" }
                    ''
                    "parent $('b' * 40)"
                }
            }.GetNewClosure())
            Mock -ModuleName BuildOptimization Write-Host { }
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'pull_request'
                $env:GITHUB_EVENT_PATH = $eventFile
                $env:GITHUB_SHA = $WorkflowSha
                Get-ChangedFilesForCI -CompareWithPullRequestMerge | Should -BeNullOrEmpty
                Should -Invoke -ModuleName BuildOptimization Write-Host -Times 1 -ParameterFilter {
                    $Object -like '*Could not verify the checked-out PR merge*'
                }
                { Get-ChangedFilesForCI -CompareWithPullRequestMerge -RequireChangeDetection } |
                    Should -Throw '*Could not verify the checked-out PR merge*'
                Should -Invoke -ModuleName BuildOptimization git -Times 0 -ParameterFilter {
                    $args -contains 'diff' -or $args -contains 'fetch'
                }
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:GITHUB_EVENT_PATH = $savedEventPath
                $env:GITHUB_SHA = $savedSha
            }
        }

        It "preserves event endpoints for <EventName> when merge comparison is requested" -ForEach @(
            @{ EventName = 'push' }, @{ EventName = 'merge_group' }, @{ EventName = 'pull_request_target' }
        ) {
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedEventPath = $env:GITHUB_EVENT_PATH
            $eventFile = Join-Path $TestDrive 'other-event.json'
            @{
                before = 'a' * 40; after = 'b' * 40
                merge_group = @{ base_sha = 'a' * 40; head_sha = 'b' * 40 }
                pull_request = @{ base = @{ sha = 'a' * 40 }; head = @{ sha = 'b' * 40 } }
            } | ConvertTo-Json -Depth 5 | Set-Content $eventFile
            Mock -ModuleName BuildOptimization git {
                $global:LASTEXITCODE = 0
                if ($args -contains 'diff') { 'changed.al' }
            }
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = $EventName
                $env:GITHUB_EVENT_PATH = $eventFile
                @(Get-ChangedFilesForCI -CompareWithPullRequestMerge) | Should -Be @('changed.al')
                Should -Invoke -ModuleName BuildOptimization git -Times 1 -ParameterFilter {
                    $args -contains 'diff' -and $args -contains ('a' * 40) -and $args -contains ('b' * 40)
                }
                Should -Invoke -ModuleName BuildOptimization git -Times 0 -ParameterFilter { $args -contains 'rev-parse' }
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:GITHUB_EVENT_PATH = $savedEventPath
            }
        }

        It "rejects combining merge comparison modes" {
            { Get-ChangedFilesForCI -CompareWithPullRequestMerge -CompareFromMergeBase } |
                Should -Throw '*cannot be combined*'
        }

        It "reports <Failure> failure without returning diagnostic text as changed files" -ForEach @(
            @{ Failure = 'fetch'; ExpectedMessage = '*Could not fetch commit*exitCode=128*' }
            @{ Failure = 'diff'; ExpectedMessage = '*Git diff failed*exitCode=128*fatal: bad object*' }
        ) {
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedEventPath = $env:GITHUB_EVENT_PATH
            $eventFile = Join-Path $TestDrive 'failed-git-event.json'
            @{ pull_request = @{ base = @{ sha = 'a' * 40 }; head = @{ sha = 'b' * 40 } } } |
                ConvertTo-Json -Depth 5 | Set-Content $eventFile
            Mock -ModuleName BuildOptimization git -MockWith ({
                $global:LASTEXITCODE = 0
                if ($Failure -eq 'fetch' -or $args -contains 'diff') {
                    $global:LASTEXITCODE = 128
                    if ($args -contains 'diff') { Write-Error 'fatal: bad object' -ErrorAction Continue }
                }
            }.GetNewClosure())
            Mock -ModuleName BuildOptimization Write-Host { }
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'pull_request'
                $env:GITHUB_EVENT_PATH = $eventFile
                Get-ChangedFilesForCI | Should -BeNullOrEmpty
                Should -Invoke -ModuleName BuildOptimization Write-Host -Times 1 -ParameterFilter {
                    $Object -like $ExpectedMessage
                }
                { Get-ChangedFilesForCI -RequireChangeDetection } | Should -Throw $ExpectedMessage
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:GITHUB_EVENT_PATH = $savedEventPath
            }
        }

        It "returns only paths when a successful diff writes a diagnostic to stderr" {
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedEventPath = $env:GITHUB_EVENT_PATH
            $eventFile = Join-Path $TestDrive 'git-warning-event.json'
            @{ pull_request = @{ base = @{ sha = 'a' * 40 }; head = @{ sha = 'b' * 40 } } } |
                ConvertTo-Json -Depth 5 | Set-Content $eventFile
            Mock -ModuleName BuildOptimization git {
                $global:LASTEXITCODE = 0
                if ($args -contains 'diff') {
                    Write-Error 'warning: exhaustive rename detection was skipped' -ErrorAction Continue
                    'src/Apps/Example/Changed.al'
                }
            }
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'pull_request'
                $env:GITHUB_EVENT_PATH = $eventFile
                @(Get-ChangedFilesForCI) | Should -Be @('src/Apps/Example/Changed.al')
            } finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:GITHUB_EVENT_PATH = $savedEventPath
            }
        }

        It "returns only newly added files when the A diff filter is requested" {
            $savedActions = $env:GITHUB_ACTIONS
            $savedEvent = $env:GITHUB_EVENT_NAME
            $savedEventPath = $env:GITHUB_EVENT_PATH
            $tempFile = [System.IO.Path]::GetTempFileName()
            try {
                $env:GITHUB_ACTIONS = 'true'
                $env:GITHUB_EVENT_NAME = 'pull_request'
                @{
                    pull_request = @{
                        base = @{ sha = 'base-sha' }
                        head = @{ sha = 'head-sha' }
                    }
                } | ConvertTo-Json -Depth 5 | Set-Content $tempFile
                $env:GITHUB_EVENT_PATH = $tempFile
                Mock -ModuleName BuildOptimization git {
                    $global:LASTEXITCODE = 0
                    if ($args -contains 'merge-base') {
                        return 'merge-base-sha'
                    }
                    if ($args -contains '--diff-filter=A') {
                        return 'src/Apps/W1/Example/App/Added.al'
                    }
                }

                $result = @(Get-ChangedFilesForCI -DiffFilter 'A' -CompareFromMergeBase -RequireChangeDetection)

                $result | Should -Be @('src/Apps/W1/Example/App/Added.al')
            }
            finally {
                $env:GITHUB_ACTIONS = $savedActions
                $env:GITHUB_EVENT_NAME = $savedEvent
                $env:GITHUB_EVENT_PATH = $savedEventPath
                Remove-Item $tempFile -ErrorAction SilentlyContinue
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

        It "RunTestsInBcContainer scripts delegate to Invoke-PerProjectTestRun, not relative path resolution" {
            $scripts = Get-ChildItem -Path (Resolve-Path "$PSScriptRoot\..\..\projects").Path -Recurse -Filter 'RunTestsInBcContainer.ps1'
            $scripts.Count | Should -BeGreaterOrEqual 4

            foreach ($script in $scripts) {
                $content = Get-Content $script.FullName -Raw
                $content | Should -Match 'Invoke-PerProjectTestRun' -Because "$($script.FullName) must delegate to Invoke-PerProjectTestRun, which resolves repo root via Get-BaseFolder"
                $content | Should -Not -Match '\$baseFolder\s*=.*Join-Path.*\$PSScriptRoot' -Because "$($script.FullName) must not compute baseFolder via relative path"
            }

            # The shared module that the per-project scripts delegate to must use Get-BaseFolder for repo root
            $module = Get-Content (Resolve-Path "$PSScriptRoot\..\ParallelTestExecution.psm1").Path -Raw
            $module | Should -Match 'Get-BaseFolder' -Because 'ParallelTestExecution.psm1 must resolve repo root via Get-BaseFolder'
        }
    }

    Context "Mandatory NewObjects test selection" {
        BeforeEach {
            $script:savedActions = $env:GITHUB_ACTIONS
            $script:savedEvent = $env:GITHUB_EVENT_NAME
            $script:savedDisabled = $env:BUILD_OPTIMIZATION_DISABLED
            $env:GITHUB_ACTIONS = 'true'
            $env:GITHUB_EVENT_NAME = 'pull_request'
            $env:BUILD_OPTIMIZATION_DISABLED = $null
            Mock -ModuleName BuildOptimization Get-ChangedFilesForCI { @('src/Apps/Example/code.al') }
            Mock -ModuleName BuildOptimization Get-AppDependencyGraph {
                @{
                    unrelated = [PSCustomObject]@{ Name = 'Unrelated App' }
                    newobjects = [PSCustomObject]@{ Name = 'Tests-NewObjects-Internal' }
                    unaffected = [PSCustomObject]@{ Name = 'Unaffected Tests' }
                }
            }
            Mock -ModuleName BuildOptimization Get-AffectedApps { @('unrelated') }
        }

        AfterEach {
            $env:GITHUB_ACTIONS = $script:savedActions
            $env:GITHUB_EVENT_NAME = $script:savedEvent
            $env:BUILD_OPTIMIZATION_DISABLED = $script:savedDisabled
        }

        It "retains NewObjects for an unrelated app change without selecting other unaffected tests" {
            $result = Get-AffectedAppNames -BaseFolder $baseFolder
            $result.RunAll | Should -BeFalse
            $result.AppNames.Count | Should -Be 2
            $result.AppNames | Should -Contain 'Unrelated App'
            $result.AppNames | Should -Contain 'Tests-NewObjects-Internal'
            $result.AppNames | Should -Not -Contain 'Unaffected Tests'
        }

        It "does not duplicate NewObjects when already affected" {
            Mock -ModuleName BuildOptimization Get-AffectedApps { @('unrelated', 'newobjects') }
            $result = Get-AffectedAppNames -BaseFolder $baseFolder
            $result.RunAll | Should -BeFalse
            @($result.AppNames | Where-Object { $_ -eq 'Tests-NewObjects-Internal' }).Count | Should -Be 1
        }

        It "never skips NewObjects through the shared helper or its cached result" {
            $cache = Join-Path $TestDrive 'mandatory-newobjects.json'
            Test-ShouldSkipTestApp -AppName 'Tests-NewObjects-Internal' -BaseFolder $baseFolder -CacheFile $cache |
                Should -BeFalse
            Test-ShouldSkipTestApp -AppName 'Tests-NewObjects-Internal' -BaseFolder $baseFolder -CacheFile $cache |
                Should -BeFalse
            Should -Invoke -ModuleName BuildOptimization Get-AffectedApps -Times 1 -Exactly
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
