using module .\Backport.psm1

Describe 'Extensibility backport policy' {
    InModuleScope Backport {
        BeforeAll {
            function New-TestSource {
                param([string[]] $Labels = @('event-request'), [string] $Merged = '2026-10-18T12:00:00Z')
                @{
                    number = 42; title = 'Expose an event'; merged_at = $Merged; updated_at = $Merged
                    base = @{ ref = 'main'; repo = @{ full_name = 'microsoft/BCApps' } }
                    merge_commit_sha = 'a' * 40
                    labels = @($Labels | ForEach-Object { @{ name = $_; color = 'ffffff'; description = '' } })
                }
            }
        }

        It 'accepts either allowed category or both, with unrelated labels' -ForEach @(
            @{ labels = @('event-request') }
            @{ labels = @('request-for-external') }
            @{ labels = @('event-request', 'request-for-external', 'Team: Finance', 'approved') }
        ) {
            Test-BackportCategory $labels | Should -BeTrue
        }

        It 'rejects other or mixed request categories and generated backports' -ForEach @(
            @{ labels = @('enum-request') }
            @{ labels = @('event-request', 'enum-request') }
            @{ labels = @('event-request', 'extensibility-enhancement') }
            @{ labels = @('request-for-external', 'extensibility-bug') }
            @{ labels = @('event-request', 'another-request') }
            @{ labels = @('event-request', 'ext-backporting') }
            @{ labels = @('Team: Finance') }
        ) {
            Test-BackportCategory $labels | Should -BeFalse
        }

        It 'uses a rolling seven-day inclusive cutoff and has no November cutoff' {
            $now = [DateTimeOffset]'2026-10-19T12:00:00Z'
            Test-BackportAutomaticSource (New-TestSource -Merged '2026-10-12T12:00:00Z') $now | Should -BeTrue
            Test-BackportAutomaticSource (New-TestSource -Merged '2026-10-12T11:59:59Z') $now | Should -BeFalse
            Test-BackportAutomaticSource (New-TestSource -Merged '2026-10-19T12:00:01Z') $now | Should -BeFalse
        }

        It 'rejects unmerged PRs and release-targeted PRs' {
            $source = New-TestSource
            $source.merged_at = $null
            Test-BackportAutomaticSource $source | Should -BeFalse
            $source = New-TestSource
            $source.base.ref = 'releases/29.x'
            Test-BackportAutomaticSource $source | Should -BeFalse
        }

        It 'excludes processed original main PRs carrying ext-backporting' {
            $source = New-TestSource @('event-request', 'ext-backporting')
            Test-BackportAutomaticSource $source ([DateTimeOffset]'2026-10-19T12:00:00Z') | Should -BeFalse
        }

        It 'selects the highest numerical .x branch, not a patch release or lexical maximum' {
            Get-BackportLatestTarget @('releases/9.x', 'releases/29.9', 'releases/29.x',
                'releases/30.x-preview', 'main', 'releases/28.x') | Should -Be 'releases/29.x'
        }

        It 'supports an existing release override and refuses missing or malformed targets' {
            Get-BackportLatestTarget @('releases/28.x', 'releases/29.x') 'releases/28.x' | Should -Be 'releases/28.x'
            { Get-BackportLatestTarget @('releases/29.x') 'releases/30.x' } | Should -Throw
            { Get-BackportLatestTarget @('main') } | Should -Throw
            { Assert-BackportTarget 'releases/29.1' } | Should -Throw
        }

        It 'unions labels from every main issue and excludes only the readiness guard' {
            $issues = @(
                @{ labels = @{ nodes = @(@{ name = 'event-request' }, @{ name = 'Team: Finance' }, @{ name = 'ext-ready-to-implement' }) } }
                @{ labels = @{ nodes = @(@{ name = 'request-for-external' }, @{ name = 'Team: Finance' }, @{ name = 'approved' }) } }
            )
            $labels = @(Get-BackportLabels -Issues $issues -PrLabels @(@{ name = 'unrelated-pr-label' }))
            @($labels.name).Count | Should -Be 5
            $labels.name | Should -Contain 'ext-backporting'
            $labels.name | Should -Contain 'event-request'
            $labels.name | Should -Contain 'request-for-external'
            $labels.name | Should -Contain 'approved'
            $labels.name | Should -Not -Contain 'ext-ready-to-implement'
            $labels.name | Should -Not -Contain 'unrelated-pr-label'
        }

        It 'uses source PR labels only when there are no linked main issues' {
            $labels = @(Get-BackportLabels -Issues @() -PrLabels @(
                @{ name = 'event-request' }, @{ name = 'ext-ready-to-implement' }
            ))
            $labels.name | Should -Contain 'event-request'
            $labels.name | Should -Contain 'ext-backporting'
            $labels.name | Should -Not -Contain 'ext-ready-to-implement'
        }

        It 'pins an existing request to its original release after a new release appears' {
            $source = New-TestSource
            $tracking = @{ body = Get-BackportMarker 42 'releases/29.x' $source.merge_commit_sha }
            Get-BackportPinnedTarget $source $tracking 'releases/30.x' | Should -Be 'releases/29.x'
        }

        It 'retains target identity from an interrupted issue-creation intent' {
            $source = New-TestSource @('event-request', 'ext-backport-pending:29.x')
            Get-BackportPinnedTarget $source $null 'releases/30.x' | Should -Be 'releases/29.x'
        }

        It 'rejects changed source identities and multiple target states' {
            $source = New-TestSource
            $tracking = @{ body = Get-BackportMarker 42 'releases/29.x' ('b' * 40) }
            { Get-BackportPinnedTarget $source $tracking 'releases/30.x' } | Should -Throw
            $source = New-TestSource @('event-request', 'ext-backport-created:29.x', 'ext-backport-created:30.x')
            { Get-BackportPinnedTarget $source $null 'releases/30.x' } | Should -Throw
        }

        It 'rejects ambiguous markers and ignores ordinary issue bodies' {
            Read-BackportMarker 'A normal issue' | Should -BeNullOrEmpty
            $marker = Get-BackportMarker 42 'releases/29.x' ('a' * 40)
            { Read-BackportMarker "$marker`n$marker" } | Should -Throw
        }

        It 'includes the main PR, all main issues, and only closes the new backport issue' {
            $state = @{
                repository = 'microsoft/BCApps'; source_pr = 42; target = 'releases/29.x'; source_sha = 'a' * 40
                issues = @(@{ url = 'https://github.com/microsoft/BCApps/issues/10' },
                    @{ url = 'https://github.com/microsoft/BCApps/issues/11' })
                result = @{ outcome = 'applied' }
            }
            $body = Get-BackportBody $state 99
            $body | Should -Match 'https://github.com/microsoft/BCApps/pull/42'
            $body | Should -Match 'https://github.com/microsoft/BCApps/issues/10'
            $body | Should -Match 'https://github.com/microsoft/BCApps/issues/11'
            $body | Should -Match 'Fixes microsoft/BCApps#99'
            $body | Should -Not -Match 'Fixes microsoft/BCApps#1[01]'
        }

        It 'rejects non-source paths, symlinks, executable files and traversal' -ForEach @(
            @{ path = '.github/workflows/evil.yml'; old = '100644'; new = '100644' }
            @{ path = 'src/../file.al'; old = '100644'; new = '100644' }
            @{ path = 'src/link'; old = '000000'; new = '120000' }
            @{ path = 'src/tool'; old = '000000'; new = '100755' }
            @{ path = 'src/.git/config'; old = '100644'; new = '100644' }
        ) {
            $raw = ":$old $new $('a' * 40) $('b' * 40) M$([char]0)$path$([char]0)"
            { Assert-BackportPaths $raw } | Should -Throw
        }

        It 'accepts normal src paths including spaces and multiple file types' {
            $raw = ":100644 100644 $('a' * 40) $('b' * 40) M$([char]0)src/My App/Foo.al$([char]0)"
            $raw += ":000000 100644 $('0' * 40) $('c' * 40) A$([char]0)src/My App/data.json$([char]0)"
            @(Assert-BackportPaths $raw).Count | Should -Be 2
        }
    }
}

Describe 'Backport discovery and recovery' {
    InModuleScope Backport {
        BeforeEach {
            Mock Get-BackportApiPages { @(@{ name = 'main' }, @{ name = 'releases/29.x' }) }
        }

        It 'allows a manual PR regardless of category and age and validates its numeric input' {
            Mock Invoke-BackportApi { throw 'Manual discovery must not run the automatic PR query.' }
            $requests = @(Find-ExtRequestBackport microsoft/BCApps -SourcePr '42')
            $requests.Count | Should -Be 1
            $requests[0].source_pr | Should -Be 42
            { Find-ExtRequestBackport microsoft/BCApps -SourcePr '42;whoami' } | Should -Throw
            Should -Invoke Invoke-BackportApi -Times 0
        }

        It 'paginates discovery without a search index or a 1000-result search cap' {
            Mock Invoke-BackportApi {
                if ($Path -like '*page=1') {
                    return @(1..100 | ForEach-Object {
                        @{ merged_at = $null; updated_at = [DateTimeOffset]::UtcNow.ToString('o'); base = @{ ref = 'main' } }
                    })
                }
                return @(@{
                    number = 42; merged_at = [DateTimeOffset]::UtcNow.AddDays(-1).ToString('o')
                    updated_at = [DateTimeOffset]::UtcNow.ToString('o'); base = @{ ref = 'main' }
                    labels = @(@{ name = 'event-request' })
                })
            }
            $requests = @(Find-ExtRequestBackport microsoft/BCApps)
            $requests.Count | Should -Be 1
            $requests[0].source_pr | Should -Be 42
            Should -Invoke Invoke-BackportApi -Times 2
        }

        It 'does not rediscover a processed source PR in the seven-day window' {
            Mock Invoke-BackportApi {
                @(
                    @{
                        number = 42; merged_at = [DateTimeOffset]::UtcNow.AddDays(-1).ToString('o')
                        updated_at = [DateTimeOffset]::UtcNow.ToString('o'); base = @{ ref = 'main' }
                        labels = @(@{ name = 'event-request' }, @{ name = 'ext-backporting' })
                    }
                    @{
                        number = 43; merged_at = [DateTimeOffset]::UtcNow.AddDays(-1).ToString('o')
                        updated_at = [DateTimeOffset]::UtcNow.ToString('o'); base = @{ ref = 'main' }
                        labels = @(@{ name = 'request-for-external' })
                    }
                )
            }
            $requests = @(Find-ExtRequestBackport microsoft/BCApps)
            $requests.Count | Should -Be 1
            $requests[0].source_pr | Should -Be 43
        }

        It 'marks the original PR as processed only after a durable outcome' -ForEach @(
            @{ status = 'created' }
            @{ status = 'merged' }
            @{ status = 'needs-attention' }
            @{ status = 'already-present' }
        ) {
            Mock Ensure-BackportLabels {}
            Mock Invoke-BackportApi {}
            Add-BackportStatus microsoft/BCApps 42 $status 'releases/29.x'
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                $Path -eq 'repos/microsoft/BCApps/issues/42/labels' -and $Method -eq 'POST' -and
                $Body.labels -contains 'ext-backporting' -and $Body.labels.Count -eq 2
            }
            Should -Invoke Ensure-BackportLabels -Times 1 -ParameterFilter {
                @($Labels | Where-Object name -eq 'ext-backporting').Count -eq 1
            }
        }

        It 'does not hide unfinished issue or PR creation from automatic recovery' -ForEach @(
            @{ status = 'pending' }
            @{ status = 'publishing' }
        ) {
            Mock Ensure-BackportLabels {}
            Mock Invoke-BackportApi {}
            Add-BackportStatus microsoft/BCApps 42 $status 'releases/29.x'
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                $Path -eq 'repos/microsoft/BCApps/issues/42/labels' -and
                $Body.labels -notcontains 'ext-backporting' -and $Body.labels.Count -eq 1
            }
        }

        It 'refuses manually selected unmerged PRs too' {
            Mock Invoke-BackportApi { @{ merged_at = $null; base = @{ ref = 'main' } } }
            { Get-BackportSource microsoft/BCApps 42 } | Should -Throw
        }

        It 'refuses objects created by another actor or pointing at another branch' {
            $state = @{ repository = 'microsoft/BCApps'; source_pr = 42; target = 'releases/29.x'; source_sha = 'a' * 40 }
            $object = @{ body = Get-BackportMarker 42 'releases/29.x' ('a' * 40); user = @{ login = 'someone' } }
            { Assert-BackportObject $object $state 'test-app[bot]' } | Should -Throw
            $object.user.login = 'test-app[bot]'
            $object.head = @{ ref = 'wrong'; repo = @{ full_name = 'microsoft/BCApps' } }
            $object.base = @{ ref = 'releases/29.x'; repo = @{ full_name = 'microsoft/BCApps' } }
            { Assert-BackportObject $object $state 'test-app[bot]' } | Should -Throw
        }

        It 'repairs labels and links for an existing PR instead of creating another issue or PR' {
            $marker = Get-BackportMarker 42 'releases/29.x' ('a' * 40)
            $state = @{
                repository = 'microsoft/BCApps'; source_pr = 42; target = 'releases/29.x'; source_sha = 'a' * 40
                labels = @(@{ name = 'event-request' }, @{ name = 'ext-backporting' })
            }
            $tracking = @{ number = 100; body = $marker; user = @{ login = 'test-app[bot]' }; state = 'open'; html_url = 'issue-url' }
            $pull = @{
                number = 101; body = $marker; user = @{ login = 'test-app[bot]' }; merged_at = $null
                head = @{ ref = 'bc-extrequest-backport/pr-42/29.x'; repo = @{ full_name = 'microsoft/BCApps' } }
                base = @{ ref = 'releases/29.x'; repo = @{ full_name = 'microsoft/BCApps' } }
                state = 'open'; html_url = 'pr-url'
            }
            Mock Ensure-BackportLabels {}
            Mock Add-BackportStatus {}
            Mock Remove-BackportIntents {}
            Mock Invoke-BackportApi {}
            Complete-BackportPull $state $tracking $pull 'test-app[bot]'
            Should -Invoke Invoke-BackportApi -Times 2 -ParameterFilter { $Path -like '*/labels' -and $Method -eq 'POST' }
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Path -match '/(issues|pulls)$' -and $Method -eq 'POST' }
            Should -Invoke Add-BackportStatus -Times 1 -ParameterFilter { $Status -eq 'created' }
        }

        It 'closes the tracking issue and marks the original PR when a backport merges' {
            $marker = Get-BackportMarker 42 'releases/29.x' ('a' * 40)
            $state = @{ repository = 'microsoft/BCApps'; source_pr = 42; target = 'releases/29.x'; source_sha = 'a' * 40 }
            $tracking = @{
                number = 100; body = "$marker`nBackport PR: pr-url"; user = @{ login = 'test-app[bot]' }
                state = 'open'; html_url = 'issue-url'; labels = @(@{ name = 'ext-backporting' })
            }
            $pull = @{
                number = 101; body = $marker; user = @{ login = 'test-app[bot]' }; merged_at = '2026-10-19T00:00:00Z'
                head = @{ ref = 'bc-extrequest-backport/pr-42/29.x'; repo = @{ full_name = 'microsoft/BCApps' } }
                base = @{ ref = 'releases/29.x'; repo = @{ full_name = 'microsoft/BCApps' } }
                state = 'closed'; html_url = 'pr-url'
            }
            Mock Ensure-BackportLabels {}
            Mock Add-BackportStatus {}
            Mock Remove-BackportIntents {}
            Mock Invoke-BackportApi {}
            Complete-BackportPull $state $tracking $pull 'test-app[bot]'
            Should -Invoke Add-BackportStatus -Times 1 -ParameterFilter { $Status -eq 'merged' }
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Body.state -eq 'closed' }
        }
    }
}

Describe 'Native Git backport integration' {
    InModuleScope Backport {
        BeforeEach {
            $script:directory = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $null = New-Item -ItemType Directory $directory
            $null = Invoke-BackportGit $directory @('init', '--quiet')
            [IO.File]::WriteAllText((Join-Path $directory '.git/empty-config'), '')
            $null = New-Item -ItemType Directory (Join-Path $directory 'src')
            [IO.File]::WriteAllText((Join-Path $directory 'src/Foo.al'), "base`n")
            $null = Invoke-BackportGit $directory @('add', 'src/Foo.al')
            $null = Invoke-BackportGit $directory @('commit', '--quiet', '-m', 'base')
            $script:base = (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim()
            [IO.File]::WriteAllText((Join-Path $directory 'src/Foo.al'), "source`n")
            $null = Invoke-BackportGit $directory @('commit', '--quiet', '-am', 'source')
            $script:source = (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim()
        }

        It 'backports the complete squash commit onto the pinned target with cherry-pick provenance' {
            $result = Invoke-BackportApply $directory $source $base
            $result.outcome | Should -Be 'applied'
            (Invoke-BackportGit $directory @('rev-parse', 'HEAD^')).text.Trim() | Should -Be $base
            (Invoke-BackportGit $directory @('show', 'HEAD:src/Foo.al')).text | Should -Be "source`n"
            (Invoke-BackportGit $directory @('log', '-1', '--format=%B')).text | Should -Match "cherry picked from commit $source"
        }

        It 'proves an already-applied patch instead of creating an empty PR' {
            $result = Invoke-BackportApply $directory $source $source
            $result.outcome | Should -Be 'already-present'
        }

        It 'recomputes exactly the same commit when publication is interrupted' {
            $first = Invoke-BackportApply $directory $source $base
            Start-Sleep -Milliseconds 1100
            $second = Invoke-BackportApply $directory $source $base
            $second.commit | Should -Be $first.commit
            $second.tree | Should -Be $first.tree
        }

        It 'reports a conflict without leaving a partial backport commit' {
            $null = Invoke-BackportGit $directory @('checkout', '--detach', $base)
            [IO.File]::WriteAllText((Join-Path $directory 'src/Foo.al'), "release-only`n")
            $null = Invoke-BackportGit $directory @('commit', '--quiet', '-am', 'release')
            $target = (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim()
            $result = Invoke-BackportApply $directory $source $target
            $result.outcome | Should -Be 'conflict'
            (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim() | Should -Be $target
            (Invoke-BackportGit $directory @('show', 'HEAD:src/Foo.al')).text | Should -Be "release-only`n"
        }

        It 'does not run repository hooks' {
            $hook = Join-Path $directory '.git/hooks/post-checkout'
            [IO.File]::WriteAllText($hook, "#!/bin/sh`ntouch ran-hook`n")
            if (-not $IsWindows) {
                & chmod +x $hook
                if ($LASTEXITCODE -ne 0) { throw 'Could not make the test hook executable.' }
            }
            $result = Invoke-BackportApply $directory $source $base
            $result.outcome | Should -Be 'applied'
            Test-Path (Join-Path $directory 'ran-hook') | Should -BeFalse
        }
    }

    Describe 'Backport publication contract' {
        InModuleScope Backport {
            BeforeEach {
                $script:statePath = Join-Path $TestDrive 'state.json'
                $script:source = @{
                    number = 42; title = 'Expose an event'; merged_at = '2020-01-01T00:00:00Z'
                    base = @{ ref = 'main'; repo = @{ full_name = 'microsoft/BCApps' } }
                    merge_commit_sha = 'a' * 40; labels = @(@{ name = 'enum-request' })
                }
                $script:state = @{
                    schema = 1; repository = 'microsoft/BCApps'; source_pr = 42; source_sha = 'a' * 40
                    target = 'releases/29.x'; manual = $true; source_title = 'Expose an event'
                    result = @{ outcome = 'applied'; commit = 'b' * 40; tree = 'c' * 40; target_sha = 'd' * 40 }
                }
                $script:tracking = $null
                $script:pull = $null
                $script:issues = @(@{
                    number = 10; url = 'https://github.com/microsoft/BCApps/issues/10'
                    labels = @{ nodes = @(
                        @{ name = 'enum-request'; color = 'ffffff'; description = '' }
                        @{ name = 'Team: SCM'; color = 'ffffff'; description = '' }
                        @{ name = 'ext-ready-to-implement'; color = 'ffffff'; description = '' }
                    ) }
                })
                Mock Get-BackportSource { $script:source }
                Mock Get-BackportSourceIssues { $script:issues }
                Mock Get-BackportTracking { $script:tracking }
                Mock Get-BackportPull { $script:pull }
                Mock Ensure-BackportLabels {}
                Mock Add-BackportStatus {}
                Mock Remove-BackportIntents {}
                Mock Invoke-BackportGit {
                    switch ($Arguments -join ' ') {
                        'rev-parse HEAD' { return @{ text = 'b' * 40 } }
                        'rev-parse HEAD^{tree}' { return @{ text = 'c' * 40 } }
                        'rev-parse HEAD^' { return @{ text = 'd' * 40 } }
                        default {
                            if ($Arguments[0] -eq 'ls-remote') { return @{ text = "$('b' * 40)`trefs/heads/bc-extrequest-backport/pr-42/29.x" } }
                            throw "Unexpected Git invocation: $($Arguments -join ' ')"
                        }
                    }
                }
                Mock Invoke-BackportApi {
                    if ([string]::IsNullOrEmpty($Method)) { $Method = 'GET' }
                    if ($Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues') {
                        $script:tracking = @{
                            number = 100; title = $Body.title; body = $Body.body; state = 'open'; labels = @()
                            user = @{ login = 'test-app[bot]' }; html_url = 'https://github.com/microsoft/BCApps/issues/100'
                        }
                        return $script:tracking
                    }
                    if ($Method -eq 'GET' -and $Path -eq 'repos/microsoft/BCApps/issues/100') { return $script:tracking }
                    if ($Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls') {
                        $script:pull = @{
                            number = 101; body = $Body.body; draft = $Body.draft; merged_at = $null; state = 'open'
                            user = @{ login = 'test-app[bot]' }; html_url = 'https://github.com/microsoft/BCApps/pull/101'
                            head = @{ sha = 'b' * 40; ref = $Body.head; repo = @{ full_name = 'microsoft/BCApps' } }
                            base = @{ ref = $Body.base; repo = @{ full_name = 'microsoft/BCApps' } }
                        }
                        return $script:pull
                    }
                    if ($Method -eq 'GET' -and $Path -eq 'repos/microsoft/BCApps/pulls/101') { return $script:pull }
                    if ($Path -like '*/compare/*' -and $Method -eq 'GET') { return @{ status = 'ahead' } }
                    if ($Method -eq 'POST' -and $Path -match '/issues/(100|101)/labels$') { return }
                    if ($Method -eq 'PATCH' -and $Path -eq 'repos/microsoft/BCApps/issues/100') { return }
                    throw "Unexpected API invocation: $Method $Path"
                }
            }

            It 'publishes a Task and draft PR for a manual old PR with a normally excluded category' {
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                Publish-ExtRequestBackport $statePath 'test-app[bot]'
                Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues' -and
                    $Body.type -eq 'Task' -and $Body.labels -contains 'ext-backporting' -and
                    $Body.labels -contains 'Team: SCM' -and $Body.labels -contains 'enum-request' -and
                    $Body.labels -notcontains 'ext-ready-to-implement'
                }
                Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' -and
                    $Body.draft -and $Body.base -eq 'releases/29.x' -and
                    $Body.head -eq 'bc-extrequest-backport/pr-42/29.x' -and
                    $Body.body.Contains('https://github.com/microsoft/BCApps/pull/42') -and
                    $Body.body.Contains('https://github.com/microsoft/BCApps/issues/10') -and
                    $Body.body.Contains('Fixes microsoft/BCApps#100')
                }
                Should -Invoke Add-BackportStatus -Times 1 -ParameterFilter { $Status -eq 'pending' }
                Should -Invoke Add-BackportStatus -Times 1 -ParameterFilter { $Status -eq 'publishing' }
                Should -Invoke Add-BackportStatus -Times 1 -ParameterFilter { $Status -eq 'created' }
            }

            It 'creates the tracking issue on a conflict but publishes no branch or PR' {
                $state.result.outcome = 'conflict'
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                Publish-ExtRequestBackport $statePath 'test-app[bot]'
                Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues' }
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' }
                Should -Invoke Invoke-BackportGit -Times 0
                Should -Invoke Add-BackportStatus -Times 1 -ParameterFilter { $Status -eq 'needs-attention' }
            }

            It 'closes an already-present tracking issue without creating an empty PR' {
                $state.result.outcome = 'already-present'
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                Publish-ExtRequestBackport $statePath 'test-app[bot]'
                Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'PATCH' -and $Body.state -eq 'closed' }
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' }
            }

            It 'does not repeat an uncertain tracking-issue POST' {
                $source.labels += @{ name = 'ext-backport-pending:29.x' }
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                { Publish-ExtRequestBackport $statePath 'test-app[bot]' } | Should -Throw '*prior backport state*'
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues' }
            }

            It 'does not recreate processed work whose tracking issue is missing, even manually' {
                $source.labels += @{ name = 'ext-backporting' }
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                { Publish-ExtRequestBackport $statePath 'test-app[bot]' } | Should -Throw '*prior backport state*'
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues'
                }
            }

            It 'does not repeat an uncertain release-PR POST' {
                $source.labels += @{ name = 'ext-backport-publishing:29.x' }
                $script:tracking = @{
                    number = 100; body = Get-BackportMarker 42 'releases/29.x' ('a' * 40); state = 'open'
                    user = @{ login = 'test-app[bot]' }
                }
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                { Publish-ExtRequestBackport $statePath 'test-app[bot]' } | Should -Throw '*previous PR creation is unconfirmed*'
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' }
            }

            It 'refuses changed automatic source categories before any writes' {
                $state.manual = $false
                $source.merged_at = [DateTimeOffset]::UtcNow.AddHours(-1).ToString('o')
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                { Publish-ExtRequestBackport $statePath 'test-app[bot]' } | Should -Throw '*eligibility changed*'
                Should -Invoke Invoke-BackportApi -Times 0
            }

            It 'does not overwrite an existing branch with different content' {
                Mock Invoke-BackportGit {
                    switch ($Arguments -join ' ') {
                        'rev-parse HEAD' { return @{ text = 'b' * 40 } }
                        'rev-parse HEAD^{tree}' { return @{ text = 'c' * 40 } }
                        'rev-parse HEAD^' { return @{ text = 'd' * 40 } }
                        default { return @{ text = "$('e' * 40)`trefs/heads/bc-extrequest-backport/pr-42/29.x" } }
                    }
                }
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                { Publish-ExtRequestBackport $statePath 'test-app[bot]' } | Should -Throw '*never overwrite*'
                Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Path -eq 'repos/microsoft/BCApps/pulls' -and $Method -eq 'POST' }
            }
        }
    }
}
