using module .\Backport.psm1

Describe 'Shared milestone journal engine' {
    InModuleScope Backport {
        BeforeAll {
            $script:originalBackportGit = (Get-Command Invoke-BackportGit).ScriptBlock
            function New-MilestoneFixture {
                param([int] $Start = 42, [string] $Team = 'Team: Finance',
                    [string[]] $Outcomes = @('applied', 'conflict', 'already-present'), [string] $Mode = 'team')
                $release = @{ target = 'releases/29.x'; version = '29.1'; milestone_number = 1; milestone_title = 'Version 29.1' }
                $request = @{
                    mode = $Mode; team = $Team; target = $release.target; release = $release
                    batch_id = [string]$Start; reference_time = [DateTimeOffset]::UtcNow.ToString('o')
                    manual = $Mode -eq 'single'; source_prs = @(); sources = @()
                }
                $members = @()
                $tip = 'f' * 40
                for ($i = 0; $i -lt $Outcomes.Count; $i++) {
                    $number = $Start + $i
                    $sha = (Get-BackportDigest "source-$number").Substring(0, 40)
                    $request.source_prs += $number
                    $request.sources += @{ number = $number; sha = $sha; merged_at = [DateTimeOffset]::UtcNow.AddDays(-5 + $i).ToString('o') }
                    $labels = @(
                        @{ name = 'event-request'; color = 'ffffff'; description = '' }
                        @{ name = $Team; color = 'ffffff'; description = '' }
                        @{ name = 'Ownership: External'; color = 'ffffff'; description = '' }
                        @{ name = "feature-$Start"; color = 'ffffff'; description = '' }
                        @{ name = 'ext-backporting'; color = '5319E7'; description = '' }
                    )
                    $result = @{ outcome = $Outcomes[$i]; target_sha = $tip; commit = $null; tree = $null; paths = @("src/$number.al") }
                    if ($Outcomes[$i] -eq 'applied') {
                        $result.commit = (Get-BackportDigest "commit-$number").Substring(0, 40)
                        $result.tree = (Get-BackportDigest "tree-$number").Substring(0, 40)
                        $tip = $result.commit
                    }
                    $members += @{
                        schema = 1; repository = 'microsoft/BCApps'; source_pr = $number; source_sha = $sha
                        source_title = "Source $number"; main_team = $Team; manual = $request.manual
                        reference_time = $request.reference_time; target = $release.target; labels = $labels; result = $result
                        issues = @(@{
                            number = 10; url = 'https://github.com/microsoft/BCApps/issues/10'; title = 'Expose the requested event'
                            repository = @{ nameWithOwner = 'microsoft/BCApps' }; labels = @{ nodes = $labels[0..3] }
                        })
                    }
                }
                $request.key = if ($Mode -eq 'single') { "single-$Start" }
                    else { 'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $request)).Substring(0, 32) }
                $changed = @($members | Where-Object { $_.result.outcome -eq 'applied' })
                $cohort = @{
                    schema = 2; repository = 'microsoft/BCApps'; request = $request; members = $members
                    target_sha = 'f' * 40; head = $tip; tree = if ($changed.Count) { $changed[-1].result.tree } else { 'e' * 40 }
                }
                @{ schema = 3; repository = 'microsoft/BCApps'; release = $release; cohort = $cohort }
            }
            function Register-MilestoneSources([hashtable] $State) {
                foreach ($member in $State.cohort.members) {
                    $script:db.sources[[string]$member.source_pr] = @{
                        number = $member.source_pr; title = $member.source_title; merge_commit_sha = $member.source_sha
                        merged_at = @($State.cohort.request.sources | Where-Object number -eq $member.source_pr)[0].merged_at
                        updated_at = [DateTimeOffset]::UtcNow.ToString('o')
                        labels = @($member.labels | Where-Object { $_.name -ne 'ext-backporting' })
                        base = @{ ref = 'main'; repo = @{ full_name = 'microsoft/BCApps' } }; issues = $member.issues
                    }
                }
            }
            function Save-MilestoneFixture([hashtable] $State) {
                $State | ConvertTo-Json -Depth 80 | Set-Content -LiteralPath $script:statePath
            }
            function Select-MilestonePage([object[]] $Items, [string] $Path) {
                if ($Path -notmatch '(?:\?|&)page=([1-9][0-9]*)$') { throw 'Pagination was not specified.' }
                @($Items) | Select-Object -Skip (([int]$Matches[1] - 1) * 100) -First 100
            }
            function Add-MilestoneTracker([string] $Body, [string] $Status = 'open') {
                $script:db.issues['100'] = @{
                    number = 100; title = Get-BackportSharedTitle $script:state.release; body = $Body; state = $Status
                    user = @{ login = 'test-app[bot]' }; labels = @(@{ name = 'ext-backporting' })
                    milestone = $script:db.milestones[0]; html_url = 'https://github.com/microsoft/BCApps/issues/100'
                }
                $script:db.nextIssue = 101
            }
            function Use-ReadableBranchFixture {
                $script:db.remoteHeads = @{}
                Mock Invoke-BackportGit {
                    $prefix = 'refs/heads/'
                    if ($Arguments[0] -eq 'ls-remote') {
                        $branch = $Arguments[-1].Substring($prefix.Length)
                        $sha = $script:db.remoteHeads[$branch]
                        return @{ text = if ($sha) { "$sha`t$prefix$branch" } else { '' }; exit_code = 0 }
                    }
                    if ($Arguments[0] -eq 'push') {
                        $Arguments.Count | Should -Be 4
                        $Arguments[2] | Should -Be 'origin'
                        $sha, $ref = $Arguments[3].Split(':', 2)
                        $Arguments[1] | Should -BeExactly "--force-with-lease=$($ref):"
                        $branch = $ref.Substring($prefix.Length)
                        $script:db.remoteHeads.ContainsKey($branch) | Should -BeFalse
                        $script:db.remoteHeads[$branch] = $sha
                        return @{ text = ''; exit_code = 0 }
                    }
                    throw "Unexpected Git operation $($Arguments -join ' ')"
                }
                $script:state.cohort.branch = New-BackportCohortBranch microsoft/BCApps $TestDrive $script:state.cohort.request @()
                Save-MilestoneFixture $script:state
            }
        }
        BeforeEach {
            $script:statePath = Join-Path $TestDrive 'milestone.json'
            $script:db = @{
                issues = @{}; comments = @{}; pulls = @{}; sources = @{}
                nextIssue = 100; nextComment = 1000; nextPull = 200; version = '29.1'; writes = [Collections.Generic.List[object]]::new()
                milestones = @(@{ number = 1; title = 'Version 29.1'; state = 'open' },
                    @{ number = 2; title = 'Version 29.2'; state = 'open' }, @{ number = 3; title = 'Version 30.1'; state = 'open' })
            }
            $script:state = New-MilestoneFixture
            Register-MilestoneSources $state
            Save-MilestoneFixture $state
            Mock Ensure-BackportLabels {}
            Mock Assert-BackportPreparedBatch {}
            Mock Get-BackportSource {
                if (-not $script:db.sources.ContainsKey([string]$Number)) { throw "Unknown source $Number" }
                $script:db.sources[[string]$Number]
            }
            Mock Get-BackportSourceIssues { $script:db.sources[[string]$Number].issues }
            Mock Invoke-BackportGit {
                if ($Arguments[0] -eq 'ls-remote') { return @{ text = "$($script:state.cohort.head)`trefs/heads/backport" } }
                throw "Unexpected Git operation $($Arguments -join ' ')"
            }
            Mock Invoke-BackportApi {
                if (-not $Method) { $Method = 'GET' }
                if ($Method -ne 'GET') { $script:db.writes.Add(@{ path = $Path; method = $Method; body = $Body }) }
                if ($Method -eq 'GET' -and $Path -like '*/contents/.github/AL-Go-Settings.json?*') {
                    $json = ConvertTo-Json @{ repoVersion = $script:db.version }
                    return @{ encoding = 'base64'; content = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json)) }
                }
                if ($Method -eq 'GET' -and $Path -match '/milestones/(\d+)$') {
                    $number = [long]$Matches[1]
                    $found = @($script:db.milestones | Where-Object number -eq $number)
                    if ($found.Count -ne 1) { throw 'Missing milestone' }
                    return $found[0]
                }
                if ($Method -eq 'GET' -and $Path -match '/milestones\?') {
                    return Select-MilestonePage $script:db.milestones $Path
                }
                if ($Method -eq 'GET' -and $Path -match '/issues/comments/(\d+)$') { return $script:db.comments[[string]$Matches[1]] }
                if ($Method -eq 'PATCH' -and $Path -match '/issues/comments/(\d+)$') {
                    $script:db.comments[[string]$Matches[1]].body = $Body.body; return
                }
                if ($Path -match '/issues/(\d+)/comments(?:\?|$)') {
                    $number = [long]$Matches[1]
                    if ($Method -eq 'GET') {
                        return Select-MilestonePage @($script:db.comments.Values | Where-Object issue_number -eq $number | Sort-Object id) $Path
                    }
                    if ($Method -eq 'POST') {
                        $id = $script:db.nextComment++
                        $comment = @{ id = $id; issue_number = $number; body = $Body.body; user = @{ login = 'test-app[bot]' } }
                        $script:db.comments[[string]$id] = $comment
                        return $comment
                    }
                }
                if ($Method -eq 'GET' -and $Path -match '/issues\?') {
                    $items = @($script:db.issues.Values)
                    if ($Path -match 'milestone=(\d+)') {
                        $number = [long]$Matches[1]
                        $items = @($items | Where-Object { $null -ne $_.milestone -and $_.milestone.number -eq $number })
                    }
                    return Select-MilestonePage @($items | Sort-Object number) $Path
                }
                if ($Method -eq 'GET' -and $Path -match '/pulls\?') {
                    $head = (($Path -split 'head=', 2)[1] -split '&')[0]
                    $head = $head.Substring($head.IndexOf(':') + 1)
                    return Select-MilestonePage @($script:db.pulls.Values | Where-Object { $_.head.ref -ceq $head }) $Path
                }
                if ($Method -eq 'GET' -and $Path -match '/pulls/(\d+)$') { return $script:db.pulls[[string]$Matches[1]] }
                if ($Method -eq 'GET' -and $Path -match '/issues/(\d+)$') { return $script:db.issues[[string]$Matches[1]] }
                if ($Method -eq 'POST' -and $Path -match '/issues$') {
                    $number = $script:db.nextIssue++
                    $issue = @{
                        number = $number; title = $Body.title; body = $Body.body; state = 'open'
                        user = @{ login = 'test-app[bot]' }; labels = @($Body.labels | ForEach-Object { @{ name = $_ } })
                        milestone = @($script:db.milestones | Where-Object number -eq $Body.milestone)[0]
                        html_url = "https://github.com/microsoft/BCApps/issues/$number"
                    }
                    $script:db.issues[[string]$number] = $issue
                    return $issue
                }
                if ($Method -eq 'POST' -and $Path -match '/pulls$') {
                    $proof = Read-BackportJournalMarker $Body.body
                    $number = $script:db.nextPull++
                    $pull = @{
                        number = $number; title = $Body.title; body = $Body.body; state = 'open'; merged_at = $null; draft = $Body.draft
                        user = @{ login = 'test-app[bot]' }; milestone = $null; html_url = "https://github.com/microsoft/BCApps/pull/$number"
                        head = @{ ref = $Body.head; sha = $proof.cohort.head; repo = @{ full_name = 'microsoft/BCApps' } }
                        base = @{ ref = $Body.base; repo = @{ full_name = 'microsoft/BCApps' } }; labels = @()
                    }
                    $script:db.pulls[[string]$number] = $pull
                    return $pull
                }
                if ($Method -eq 'PATCH' -and $Path -match '/issues/(\d+)$') {
                    $number = [string]$Matches[1]
                    $object = if ($script:db.issues.ContainsKey($number)) { $script:db.issues[$number] } else { $script:db.pulls[$number] }
                    foreach ($key in $Body.Keys) {
                        if ($key -eq 'milestone') { $object.milestone = @($script:db.milestones | Where-Object number -eq $Body[$key])[0] }
                        elseif ($key -eq 'labels') { $object.labels = @($Body[$key] | ForEach-Object { @{ name = $_ } }) }
                        else { $object[$key] = $Body[$key] }
                    }
                    return
                }
                if ($Method -eq 'POST' -and $Path -match '/issues/(\d+)/labels$') {
                    $number = [string]$Matches[1]
                    if ($script:db.sources.ContainsKey($number)) {
                        if ($Body.labels.Count -ne 1 -or $Body.labels[0] -cne 'ext-backport-processed') { throw 'Unexpected original source label payload.' }
                        $script:db.sources[$number].labels += @{ name = 'ext-backport-processed' }
                    }
                    elseif ($script:db.pulls.ContainsKey($number)) {
                        $script:db.pulls[$number].labels = @($Body.labels | ForEach-Object { @{ name = $_ } })
                    }
                    else { throw 'Original issues must never be labeled.' }
                    return
                }
                throw "Unexpected API operation: $Method $Path"
            }
        }

        It 'names single requests from the original main PR, never its original issue' {
            $script:state = New-MilestoneFixture -Start 11166 -Mode single -Outcomes @('applied')
            Register-MilestoneSources $state
            Use-ReadableBranchFixture
            $state.cohort.branch | Should -BeExactly 'bc-extrequest-backport/backport_11166'
            Publish-ExtRequestBackport $statePath 'test-app[bot]'
            $pull = $db.pulls['200']
            $pull.head.ref | Should -BeExactly 'bc-extrequest-backport/backport_11166'
            $pull.head.ref | Should -Not -Match '10$'
            Assert-BackportMilestonePull $pull $state 'test-app[bot]'
            Should -Invoke Invoke-BackportApi -ParameterFilter {
                $Path -like '*/pulls?state=all&head=microsoft:bc-extrequest-backport/backport_11166&*'
            }
            Should -Invoke Invoke-BackportGit -Times 1 -ParameterFilter {
                $Arguments[0] -eq 'push' -and
                $Arguments[3] -ceq "$($script:state.cohort.head):refs/heads/bc-extrequest-backport/backport_11166"
            }
            $db.sources['11166'].labels.name | Should -Contain 'ext-backport-processed'
            @($db.writes | Where-Object path -eq 'repos/microsoft/BCApps/issues/10/labels').Count | Should -Be 0
        }

        It 'blocks the personal demo singleton alias after manual discovery bypasses the processed label' -ForEach @(
            @{ status = 'open' }, @{ status = 'closed' }
        ) {
            $script:state = New-MilestoneFixture -Start 11166 -Mode single -Outcomes @('applied')
            Register-MilestoneSources $state
            $db.sources['11166'].labels += @{ name = 'ext-backport-processed' }
            $db.issues['13146'] = @{
                number = 13146; title = '[Simulation] Personal backport demonstration'; state = $status
                body = '<!-- bc-extrequest-backport-personal:tracker:v3 demonstration -->'
                user = @{ login = 'personal-demo-author' }; milestone = $null; labels = @(@{ name = 'ext-backporting' })
            }
            $db.pulls['13147'] = @{
                number = 13147; title = '[Simulation] Backport #11166'; state = $status
                body = '<!-- bc-extrequest-backport-personal:journal:v3 demonstration -->'
                user = @{ login = 'personal-demo-author' }
                head = @{ ref = 'bc-extrequest-backport/single-11166'; sha = $state.cohort.head }
            }
            $personalBefore = ConvertTo-BackportCanonicalJson @($db.issues['13146'], $db.pulls['13147'])
            Mock Invoke-BackportApi { @(@{ name = 'releases/29.x' }) } -ParameterFilter {
                $Method -ne 'POST' -and $Path -like '*/branches?*'
            }
            $row = Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 11166 -BatchId 999
            $row.manual | Should -BeTrue
            $row.source_prs -join ',' | Should -BeExactly '11166'
            $row.ContainsKey('journal_id') | Should -BeFalse
            Use-ReadableBranchFixture
            $state.cohort.branch | Should -BeExactly 'bc-extrequest-backport/backport_11166'
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*legacy alias*foreign or unregistered*'
            (ConvertTo-BackportCanonicalJson @($db.issues['13146'], $db.pulls['13147'])) | Should -BeExactly $personalBefore
            $db.writes.Count | Should -Be 0
            $db.comments.Count | Should -Be 0
            $db.pulls.Count | Should -Be 1
            Should -Invoke Invoke-BackportApi -ParameterFilter {
                $Path -like '*/pulls?state=all&head=microsoft:bc-extrequest-backport/single-11166&*'
            }
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
        }

        It 'blocks open or closed native-v1 aliases regardless of foreign or unregistered App authorship' -ForEach @(
            @{ status = 'open'; author = 'human' }, @{ status = 'closed'; author = 'human' },
            @{ status = 'open'; author = 'test-app[bot]' }, @{ status = 'closed'; author = 'test-app[bot]' }
        ) {
            $script:state = New-MilestoneFixture -Start 11166 -Mode single -Outcomes @('applied')
            Register-MilestoneSources $state
            Use-ReadableBranchFixture
            $db.pulls['91'] = @{
                number = 91; title = 'Unregistered native backport'; state = $status
                body = Get-BackportBody $state.cohort.members[0]
                user = @{ login = $author }
                head = @{ ref = 'bc-extrequest-backport/pr-11166/29.x'; sha = $state.cohort.head }
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*legacy alias*foreign or unregistered*'
            $db.writes.Count | Should -Be 0
            $db.comments.Count | Should -Be 0
            $db.pulls.Count | Should -Be 1
            Should -Invoke Invoke-BackportApi -ParameterFilter {
                $Path -like '*/pulls?state=all&head=microsoft:bc-extrequest-backport/pr-11166/29.x&*'
            }
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
        }

        It 'fails safely on multiple old aliases or multiple PRs on either alias' -ForEach @(
            @{ kind = 'both' }, @{ kind = 'single-duplicates' }, @{ kind = 'native-duplicates' }
        ) {
            $script:state = New-MilestoneFixture -Mode single -Outcomes @('applied')
            Register-MilestoneSources $state
            Use-ReadableBranchFixture
            $first = if ($kind -eq 'native-duplicates') { 'bc-extrequest-backport/pr-42/29.x' }
                else { 'bc-extrequest-backport/single-42' }
            $second = if ($kind -eq 'both') { 'bc-extrequest-backport/pr-42/29.x' } else { $first }
            $db.pulls['90'] = @{ number = 90; state = 'open'; head = @{ ref = $first } }
            $db.pulls['91'] = @{ number = 91; state = 'closed'; head = @{ ref = $second } }
            $expectedError = switch ($kind) {
                'both' { '*Ambiguous legacy standalone backport PR aliases*' }
                'single-duplicates' { '*Multiple PRs for one batch branch*' }
                'native-duplicates' { '*Multiple backport PRs for the same branch*' }
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw $expectedError
            $db.writes.Count | Should -Be 0
            $db.comments.Count | Should -Be 0
            $db.pulls.Count | Should -Be 2
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
        }

        It 'blocks an old singleton alias for any member of a new readable team cohort' {
            Use-ReadableBranchFixture
            $db.pulls['91'] = @{
                number = 91; title = '[Simulation] Excluded source backport'; state = 'closed'
                head = @{ ref = 'bc-extrequest-backport/single-43' }; user = @{ login = 'human' }; body = ''
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*legacy alias*'
            $db.writes.Count | Should -Be 0
            $db.comments.Count | Should -Be 0
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
        }

        It 'rechecks legacy aliases when resuming a registered but unpublished readable cohort' {
            $script:state = New-MilestoneFixture -Mode single -Outcomes @('applied')
            Register-MilestoneSources $state
            Use-ReadableBranchFixture
            Mock Invoke-BackportGit { throw 'Interrupted push' } -ParameterFilter { $Arguments[0] -eq 'push' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Interrupted push*'
            $db.pulls['91'] = @{
                number = 91; title = '[Simulation] Personal backport'; state = 'closed'
                head = @{ ref = 'bc-extrequest-backport/single-42' }; user = @{ login = 'human' }; body = ''
            }
            $writes = $db.writes.Count
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*legacy alias*'
            $db.writes.Count | Should -Be $writes
            $db.pulls.Count | Should -Be 1
            Should -Invoke Invoke-BackportGit -Times 1 -ParameterFilter { $Arguments[0] -eq 'push' }
        }

        It 'does not adopt an App-authored singleton alias without its registered immutable cohort' {
            $script:state = New-MilestoneFixture -Mode single -Outcomes @('applied')
            Register-MilestoneSources $state
            Use-ReadableBranchFixture
            $db.pulls['91'] = @{
                number = 91; title = 'Unregistered App backport'; state = 'closed'
                head = @{ ref = 'bc-extrequest-backport/single-42' }; user = @{ login = 'test-app[bot]' }
                body = Get-BackportJournalMarker $state
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*foreign or unregistered*'
            $db.writes.Count | Should -Be 0
            $db.comments.Count | Should -Be 0
            $db.pulls.Count | Should -Be 1
        }

        It 'rechecks old aliases after push and stops before recording PR creation intent' {
            $script:state = New-MilestoneFixture -Mode single -Outcomes @('applied')
            Register-MilestoneSources $state
            Use-ReadableBranchFixture
            Mock Invoke-BackportGit {
                $script:db.remoteHeads[$script:state.cohort.branch] = $script:state.cohort.head
                $script:db.pulls['91'] = @{
                    number = 91; title = '[Simulation] Concurrent personal backport'; state = 'closed'
                    head = @{ ref = 'bc-extrequest-backport/single-42' }; user = @{ login = 'human' }; body = ''
                }
                return @{ text = ''; exit_code = 0 }
            } -ParameterFilter { $Arguments[0] -eq 'push' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*legacy alias*'
            $db.comments['1000'].body | Should -Match ':branch-intent:'
            $db.comments['1000'].body | Should -Not -Match ':publication-intent:'
            $db.pulls.Count | Should -Be 1
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/pulls' }
        }

        It 'normalizes actual team names to safe lowercase ASCII branch slugs' -ForEach @(
            @{ team = 'Team:SCM'; expected = 'scm' },
            @{ team = 'Team: Finance'; expected = 'finance' },
            @{ team = 'Team:   MiXeD CASE / & Fulfillment...'; expected = 'mixed-case-fulfillment' },
            @{ team = 'Team: --Client_UI::v2--'; expected = 'client-ui-v2' }
        ) {
            $script:state = New-MilestoneFixture -Team $team -Outcomes @('applied')
            $request = $state.cohort.request
            $request.reference_time = '2026-10-21T21:42:00Z'
            [void]$request.Remove('key')
            $request.key = 'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $request)).Substring(0, 32)
            Register-MilestoneSources $state
            Use-ReadableBranchFixture
            $state.cohort.branch | Should -BeExactly "bc-extrequest-backport/$expected-2026-10-21"
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.pulls['200'].head.ref | Should -BeExactly $state.cohort.branch
            Assert-BackportMilestonePull $db.pulls['200'] $state 'test-app[bot]'
            (Get-BackportSourceTeam $db.sources['42'] $state.cohort.members[0].issues microsoft/BCApps) | Should -BeExactly $team
        }

        It 'shares the Copenhagen title date across midnight and daylight-saving boundaries' -ForEach @(
            @{ clock = '2026-10-21T22:30:00Z'; expected = '2026-10-22' },
            @{ clock = '2026-01-31T23:30:00Z'; expected = '2026-02-01' },
            @{ clock = '2026-10-25T22:30:00Z'; expected = '2026-10-25' }
        ) {
            $request = $state.cohort.request
            $request.reference_time = $clock
            (Get-BackportBranchBase $request) | Should -BeExactly "bc-extrequest-backport/finance-$expected"
            Get-BackportTitle $state | Should -Match "till $expected$"
        }

        It 'rejects teams without a nonempty safe ASCII slug' -ForEach @(
            @{ team = 'Team: !!!' }, @{ team = 'Team: 中文' }, @{ team = 'Team: ---' }
        ) {
            $state.cohort.request.team = $team
            { Get-BackportBranchBase $state.cohort.request } | Should -Throw '*safe ASCII*'
        }

        It 'allocates the lowest suffix across remote branches, closed PRs and journal-only reservations' {
            Use-ReadableBranchFixture
            $base = $state.cohort.branch
            $db.remoteHeads[$base] = '0' * 40
            $db.pulls['90'] = @{ number = 90; state = 'closed'; head = @{ ref = "$base-2" } }
            $reserved = @{}
            $reserved += $state.cohort
            $reserved.branch = "$base-3"
            $records = @(@{ manifest = $reserved })
            $chosen = New-BackportCohortBranch microsoft/BCApps $TestDrive $state.cohort.request $records
            $chosen | Should -BeExactly "$base-4"
            [void]$db.remoteHeads.Remove($base)
            (New-BackportCohortBranch microsoft/BCApps $TestDrive $state.cohort.request $records) | Should -BeExactly $base
            $db.writes.Count | Should -Be 0
        }

        It 'reserves all-conflict and no-op cohorts without a remote branch and separates another same-day run' -ForEach @(
            @{ outcome = 'conflict' }, @{ outcome = 'already-present' }
        ) {
            $script:state = New-MilestoneFixture -Outcomes @($outcome)
            Register-MilestoneSources $state
            Use-ReadableBranchFixture
            $first = $state
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.remoteHeads.Count | Should -Be 0
            $script:state = New-MilestoneFixture -Start 50 -Outcomes @('applied')
            $state.cohort.request.reference_time = $first.cohort.request.reference_time
            [void]$state.cohort.request.Remove('key')
            $state.cohort.request.key = 'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $state.cohort.request)).Substring(0, 32)
            Register-MilestoneSources $state
            $state.cohort.branch = New-BackportCohortBranch microsoft/BCApps $TestDrive $state.cohort.request @(Get-BackportBatchRecords microsoft/BCApps)
            $state.cohort.branch | Should -BeExactly "$($first.cohort.branch)-2"
            Save-MilestoneFixture $state
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.comments.Count | Should -Be 2
            $db.pulls['200'].head.ref | Should -BeExactly $state.cohort.branch
            $db.sources['42'].labels.name | Should -Not -Contain 'ext-backport-processed'
        }

        It 'keeps readable pins and compact rows through later discovery, target changes and closed PRs' {
            Use-ReadableBranchFixture
            $branch = $state.cohort.branch
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.pulls['200'].state = 'closed'
            $db.version = '29.2'
            $row = Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 42 -TargetOverride releases/30.x -BatchId 999
            $row.key | Should -BeExactly $state.cohort.request.key
            $row.target | Should -BeExactly 'releases/29.x'
            $row.ContainsKey('branch') | Should -BeFalse
            (ConvertTo-Json $row -Compress -Depth 30).Length | Should -BeLessThan 4000
            New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $row -Depth 60) $statePath
            $prepared = Get-Content $statePath -Raw | ConvertFrom-Json -AsHashtable -Depth 80
            $prepared.cohort.branch | Should -BeExactly $branch
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.pulls.Count | Should -Be 1
            Should -Invoke Invoke-BackportGit -Times 1 -ParameterFilter { $Arguments[0] -eq 'push' }
        }

        It 'rejects malformed or identity-changing pinned branches' -ForEach @(
            @{ branch = 'human/finance-2026-10-21' }, @{ branch = 'bc-extrequest-backport/../main' },
            @{ branch = 'bc-extrequest-backport/backport_10' }, @{ branch = 'bc-extrequest-backport/finance-2026-10-20' },
            @{ branch = 'bc-extrequest-backport/finance-2026-10-21-1' }, @{ branch = 'bc-extrequest-backport/finance-2026-10-21-02' },
            @{ branch = 'bc-extrequest-backport/Finance-2026-10-21' }, @{ branch = 'bc-extrequest-backport/finance-2026-10-21.lock' },
            @{ branch = '' }, @{ branch = $null }, @{ branch = @('bc-extrequest-backport/finance-2026-10-21') }
        ) {
            $state.cohort.request.reference_time = '2026-10-21T12:00:00Z'
            [void]$state.cohort.request.Remove('key')
            $state.cohort.request.key = 'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $state.cohort.request)).Substring(0, 32)
            $state.cohort.branch = $branch
            Save-MilestoneFixture $state
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*branch*'
            $db.writes.Count | Should -Be 0
        }

        It 'rejects readable branch tampering in prepared state, journal or PR without adopting branch identity alone' -ForEach @(
            @{ kind = 'prepared' }, @{ kind = 'journal' }, @{ kind = 'pr-head' }, @{ kind = 'pr-source' }
        ) {
            Use-ReadableBranchFixture
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            switch ($kind) {
                'prepared' { $state.cohort.branch += '-2'; Save-MilestoneFixture $state }
                'journal' {
                    $other = ConvertTo-BackportCanonicalJson $state | ConvertFrom-Json -AsHashtable -Depth 80
                    $other.cohort.branch += '-2'
                    $db.comments['1000'].body = Get-BackportJournalMarker $other
                }
                'pr-head' { $db.pulls['200'].head.ref += '-2' }
                'pr-source' {
                    $other = New-MilestoneFixture -Start 50 -Outcomes @('applied')
                    $db.pulls['200'].body = Get-BackportMilestonePullBody $other 100
                }
            }
            $count = $db.writes.Count
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw
            $db.writes.Count | Should -Be $count
        }

        It 'fails rather than repinning a branch that became reserved during preparation' {
            Use-ReadableBranchFixture
            $first = $state
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $script:state = New-MilestoneFixture -Start 50 -Outcomes @('applied')
            Register-MilestoneSources $state
            $state.cohort.branch = $first.cohort.branch
            Save-MilestoneFixture $state
            $count = $db.writes.Count
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*reserved*'
            $db.writes.Count | Should -Be $count
        }

        It 'rejects an unreserved remote-only branch even when its SHA equals the prepared head' {
            Use-ReadableBranchFixture
            $db.remoteHeads[$state.cohort.branch] = $state.cohort.head
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*appeared*'
            $db.writes.Count | Should -Be 0
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
        }

        It 'resumes a lost push response from its confirmed branch intent without repinning or repeating a PR POST' {
            Use-ReadableBranchFixture
            Mock Invoke-BackportGit {
                $script:db.remoteHeads[$script:state.cohort.branch] = $script:state.cohort.head
                throw 'Lost push response'
            } -ParameterFilter { $Arguments[0] -eq 'push' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Lost push*'
            $db.comments['1000'].body | Should -Match 'branch-intent:v1'
            $db.comments['1000'].body | Should -Not -Match ':publication-intent:'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.pulls.Count | Should -Be 1
            $db.comments.Count | Should -Be 1
            Should -Invoke Invoke-BackportGit -Times 1 -ParameterFilter { $Arguments[0] -eq 'push' }
        }

        It 'reads an exact existing local-bare head without pushing only under confirmed branch intent' -ForEach @(
            @{ confirmedIntent = $true }, @{ confirmedIntent = $false }
        ) {
            $script:state = New-MilestoneFixture -Mode single -Outcomes @('applied')
            Register-MilestoneSources $state
            $state.cohort.branch = Get-BackportBranchBase $state.cohort.request
            $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $local = Join-Path $root 'git'
            $bare = Join-Path $root 'remote.git'
            $null = New-Item -ItemType Directory -Path $local -Force
            $null = & $script:originalBackportGit $local @('init', '--quiet')
            [IO.File]::WriteAllText((Join-Path $local '.git/empty-config'), '')
            $null = & $script:originalBackportGit $local @('commit', '--quiet', '--allow-empty', '-m', 'prepared head')
            $head = (& $script:originalBackportGit $local @('rev-parse', 'HEAD')).text.Trim()
            $null = & $script:originalBackportGit $local @('init', '--bare', '--quiet', $bare)
            $null = & $script:originalBackportGit $local @('remote', 'add', 'origin', $bare)
            $null = & $script:originalBackportGit $local @('-c', 'protocol.file.allow=always', 'push', 'origin',
                "$($head):refs/heads/$($state.cohort.branch)")
            $state.cohort.head = $head
            $state.cohort.members[0].result.commit = $head
            $script:statePath = Join-Path $root 'state.json'
            Save-MilestoneFixture $state
            Add-MilestoneTracker (Get-BackportSharedBody $state.release)
            $body = Get-BackportJournalMarker $state
            if ($confirmedIntent) { $body += "`n<!-- bc-extrequest-backport:branch-intent:v1 sha=$head -->" }
            $db.comments['1000'] = @{ id = 1000; issue_number = 100; body = $body; user = @{ login = 'test-app[bot]' } }
            Mock Invoke-BackportGit {
                & $script:originalBackportGit -Directory $Directory `
                    -Arguments (@('-c', 'protocol.file.allow=always') + $Arguments) `
                    -InputText $InputText -AllowFailure:$AllowFailure -CommitDate $CommitDate
            }
            if ($confirmedIntent) {
                Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
                $db.pulls['200'].head.sha | Should -BeExactly $head
            }
            else {
                { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*no confirmed branch publication intent*'
                $db.writes.Count | Should -Be 0
                $db.pulls.Count | Should -Be 0
            }
            (& $script:originalBackportGit $local @("--git-dir=$bare", 'rev-parse',
                "refs/heads/$($state.cohort.branch)")).text.Trim() | Should -BeExactly $head
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
        }

        It 'reserves unfinished same-team cohorts and normalizes distinct labels without cross-associating PRs' {
            Use-ReadableBranchFixture
            Mock Invoke-BackportApi { throw 'Interrupted after journal reservation' } -ParameterFilter {
                $Method -eq 'PATCH' -and $Path -like '*/issues/comments/*' -and $Body.body.Contains(':branch-intent:')
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Interrupted*'
            $first = $state
            $db.remoteHeads.Count | Should -Be 0
            $script:state = New-MilestoneFixture -Start 50 -Team 'Team: FINANCE!!' -Outcomes @('already-present')
            $state.cohort.request.reference_time = $first.cohort.request.reference_time
            [void]$state.cohort.request.Remove('key')
            $state.cohort.request.key = 'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $state.cohort.request)).Substring(0, 32)
            Register-MilestoneSources $state
            $state.cohort.branch = New-BackportCohortBranch microsoft/BCApps $TestDrive $state.cohort.request @(Get-BackportBatchRecords microsoft/BCApps)
            $state.cohort.branch | Should -BeExactly "$($first.cohort.branch)-2"
            Save-MilestoneFixture $state
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.pulls.Count | Should -Be 0
            $db.comments.Count | Should -Be 2
            $records = @(Get-BackportBatchRecords microsoft/BCApps)
            @($records | Where-Object { $_.journal.body.Contains(':journal-complete:') }).Count | Should -Be 1
            $row = Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 42 -BatchId 999
            $row.key | Should -BeExactly $first.cohort.request.key
            $row.source_prs.Count | Should -Be 3
        }

        It 'rejects a branch appearing during journal persistence without branch intent or a push' {
            Use-ReadableBranchFixture
            Mock Invoke-BackportApi {
                $id = $script:db.nextComment++
                $comment = @{ id = $id; issue_number = 100; body = $Body.body; user = @{ login = 'test-app[bot]' } }
                $script:db.comments[[string]$id] = $comment
                $script:db.remoteHeads[$script:state.cohort.branch] = $script:state.cohort.head
                return $comment
            } -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/issues/100/comments' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*no confirmed branch*'
            $db.comments['1000'].body | Should -Not -Match ':branch-intent:|:publication-intent:'
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
            $db.pulls.Count | Should -Be 0
        }

        It 'rejects changed branch reservations and malformed branch intents before any retry writes' -ForEach @(
            @{ kind = 'wrong-sha' }, @{ kind = 'duplicate' }, @{ kind = 'malformed' }, @{ kind = 'reservation' }
        ) {
            Use-ReadableBranchFixture
            Mock Invoke-BackportGit { throw 'Interrupted push' } -ParameterFilter { $Arguments[0] -eq 'push' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Interrupted push*'
            switch ($kind) {
                'wrong-sha' {
                    $db.comments['1000'].body = $db.comments['1000'].body.Replace(
                        "branch-intent:v1 sha=$($state.cohort.head)", "branch-intent:v1 sha=$('0' * 40)")
                }
                'duplicate' { $db.comments['1000'].body += "`n<!-- bc-extrequest-backport:branch-intent:v1 sha=$($state.cohort.head) -->" }
                'malformed' { $db.comments['1000'].body = $db.comments['1000'].body.Replace('branch-intent:v1 sha=', 'branch-intent:invalid sha=') }
                'reservation' {
                    $other = New-MilestoneFixture -Start 50 -Outcomes @('conflict')
                    $other.cohort.branch = $state.cohort.branch
                    $db.comments['1001'] = @{
                        id = 1001; issue_number = 100; body = Get-BackportJournalMarker $other; user = @{ login = 'test-app[bot]' }
                    }
                }
            }
            $writes = $db.writes.Count
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw
            $db.writes.Count | Should -Be $writes
            $db.pulls.Count | Should -Be 0
        }

        It 'preserves readable pins on explicit singleton conflict retries and rejects a new suffix' -ForEach @(
            @{ changed = $false }, @{ changed = $true }
        ) {
            $script:state = New-MilestoneFixture -Mode single -Outcomes @('conflict')
            Register-MilestoneSources $state
            Use-ReadableBranchFixture
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $old = @(Get-BackportJournalRecords microsoft/BCApps)[0]
            $revision = New-MilestoneFixture -Mode single -Outcomes @('applied')
            $revision.cohort.request = $state.cohort.request
            $revision.cohort.branch = $state.cohort.branch
            $revision.supersedes = $old.journal.id
            if ($changed) { $revision.cohort.branch += '-2' }
            $script:state = $revision
            Save-MilestoneFixture $state
            if ($changed) {
                $count = $db.writes.Count
                { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*pinned cohort branch*'
                $db.writes.Count | Should -Be $count
            }
            else {
                Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
                $db.comments.Count | Should -Be 2
                $db.pulls['200'].head.ref | Should -BeExactly 'bc-extrequest-backport/backport_42'
                @(Get-BackportJournalRecords microsoft/BCApps).Count | Should -Be 1
            }
        }

        It 'retains old schema-three branch derivation and canonical proof hashes when branch is absent' {
            $marker = Get-BackportJournalMarker $state
            $state.cohort.ContainsKey('branch') | Should -BeFalse
            $expected = "bc-extrequest-backport/$($state.cohort.request.key)"
            (Get-BackportCohortBranch $state.cohort) | Should -BeExactly $expected
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.pulls['200'].head.ref | Should -BeExactly $expected
            $row = Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 42 -BatchId 999
            New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $row -Depth 60) $statePath
            $loaded = Get-Content $statePath -Raw | ConvertFrom-Json -AsHashtable -Depth 80
            (Get-BackportJournalMarker $loaded) | Should -BeExactly $marker
            $loaded.cohort.ContainsKey('branch') | Should -BeFalse
            $db.comments['1000'].body | Should -Not -Match ':branch-intent:'
        }

        It 'pins readable names when publishing genuinely unpublished schema-one or schema-two preparations' -ForEach @(
            @{ schema = 1 }, @{ schema = 2 }
        ) {
            if ($schema -eq 1) { $script:state = New-MilestoneFixture -Mode single -Outcomes @('applied') }
            Register-MilestoneSources $state
            Use-ReadableBranchFixture
            $expected = $state.cohort.branch
            if ($schema -eq 1) {
                $old = $state.cohort.members[0]
                $old.release = $state.release
            }
            else {
                $old = @{} + $state.cohort
                [void]$old.Remove('branch')
            }
            Save-MilestoneFixture $old
            Publish-ExtRequestBackport $statePath 'test-app[bot]'
            $wrapped = Get-Content $statePath -Raw | ConvertFrom-Json -AsHashtable -Depth 80
            $wrapped.schema | Should -Be 3
            $wrapped.cohort.branch | Should -BeExactly $expected
            $db.pulls['200'].head.ref | Should -BeExactly $expected
            Publish-ExtRequestBackport $statePath 'test-app[bot]'
            $db.pulls.Count | Should -Be 1
            $db.comments.Count | Should -Be 1
        }

        It 'retains an unpublished durable native-v1 branch when promoting its App-authored tracker' {
            $script:state = New-MilestoneFixture -Mode single -Outcomes @('applied')
            Register-MilestoneSources $state
            Use-ReadableBranchFixture
            $member = $state.cohort.members[0]
            $member.release = $state.release
            $branch = Get-BackportBranch $member.source_pr $member.target
            $db.remoteHeads[$branch] = $member.result.commit
            $db.issues['90'] = @{
                number = 90; title = 'Legacy Task'; body = Get-BackportBody $member; state = 'open'; milestone = $null
                user = @{ login = 'test-app[bot]' }; labels = @(@{ name = 'ext-backporting' })
                html_url = 'https://github.com/microsoft/BCApps/issues/90'
            }
            $body = $db.issues['90'].body
            Save-MilestoneFixture $member
            Publish-ExtRequestBackport $statePath 'test-app[bot]'
            $wrapped = Get-Content $statePath -Raw | ConvertFrom-Json -AsHashtable -Depth 80
            $wrapped.legacy_issue | Should -Be 90
            $wrapped.cohort.branch | Should -BeExactly 'bc-extrequest-backport/pr-42/29.x'
            $db.pulls['200'].head.ref | Should -BeExactly $branch
            $db.issues['90'].body | Should -BeExactly $body
            Publish-ExtRequestBackport $statePath 'test-app[bot]'
            $db.pulls.Count | Should -Be 1
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
        }

        It 'retains a published closed v2 PR and its hashed branch through a version rollover' {
            $legacy = $state.cohort
            $body = Get-BackportBatchBody $legacy
            $branch = "bc-extrequest-backport/$($legacy.request.key)"
            $db.issues['90'] = @{
                number = 90; title = 'Legacy cohort'; body = $body; state = 'closed'; milestone = $null
                user = @{ login = 'test-app[bot]' }; labels = @(@{ name = 'ext-backporting' })
            }
            $db.pulls['91'] = @{
                number = 91; body = Get-BackportBatchBody $legacy 90; state = 'closed'; merged_at = $null
                user = @{ login = 'test-app[bot]' }; html_url = 'https://github.com/microsoft/BCApps/pull/91'
                head = @{ ref = $branch; sha = $legacy.head; repo = @{ full_name = 'microsoft/BCApps' } }
                base = @{ ref = $legacy.request.target; repo = @{ full_name = 'microsoft/BCApps' } }
            }
            Save-MilestoneFixture $legacy
            $db.version = '29.2'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.pulls['91'].head.ref | Should -BeExactly $branch
            $db.issues['90'].body | Should -BeExactly $body
            $db.comments.Count | Should -Be 0
            $db.writes.Count | Should -Be 1
            $db.writes[0].path | Should -BeExactly 'repos/microsoft/BCApps/issues/42/labels'
            Should -Invoke Invoke-BackportGit -Times 0
        }

        It 'resolves the target branch version exactly instead of the highest open milestone' {
            $release = Get-BackportRelease microsoft/BCApps releases/29.x
            $release.version | Should -Be '29.1'
            $release.milestone_number | Should -Be 1
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                $Path -like '*AL-Go-Settings.json?ref=releases%2F29.x' -and $Method -ne 'POST'
            }
        }

        It 'uses invariant numeric repoVersion conversion' {
            $script:db.version = 29.1
            $old = [Globalization.CultureInfo]::CurrentCulture
            try {
                [Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]'de-DE'
                (Get-BackportRelease microsoft/BCApps releases/29.x).version | Should -Be '29.1'
            } finally { [Globalization.CultureInfo]::CurrentCulture = $old }
        }

        It 'fails explicitly on invalid, missing, closed or ambiguous release metadata' -ForEach @(
            @{ kind = 'major' }, @{ kind = 'missing' }, @{ kind = 'closed' }, @{ kind = 'ambiguous' },
            @{ kind = 'invalid' }, @{ kind = 'encoding' }
        ) {
            switch ($kind) {
                'major' { $script:db.version = '30.1' }
                'missing' { $script:db.milestones = @($script:db.milestones | Where-Object number -ne 1) }
                'closed' { $script:db.milestones[0].state = 'closed' }
                'ambiguous' { $script:db.milestones += @{ number = 4; title = 'Version 29.1'; state = 'open' } }
                'invalid' { $script:db.version = '29.1; whoami' }
                'encoding' { Mock Invoke-BackportApi { @{ encoding = 'raw'; content = '{}' } } }
            }
            { Get-BackportRelease microsoft/BCApps releases/29.x } | Should -Throw
            @($script:db.writes).Count | Should -Be 0
        }

        It 'publishes one milestone Task with an applied link, a conflict and a no-op, and no extra Tasks' {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.issues.Count | Should -Be 1
            $db.comments.Count | Should -Be 1
            $db.pulls.Count | Should -Be 1
            $tracker = @($db.issues.Values)[0]
            $tracker.title | Should -BeExactly '[Backporting][releases/29.x][Extensibility Requests][Version 29.1]'
            $tracker.milestone.number | Should -Be 1
            $tracker.labels.name | Should -Not -Contain 'Team: Finance'
            $tracker.labels.name | Should -Not -Contain 'Ownership: External'
            $tracker.body | Should -Match '\| Original issue \| Original PR \| Team \| Backport PR \|'
            $tracker.body | Should -Match 'Conflict - manual resolution needed'
            $tracker.body | Should -Match 'Already present'
            [Net.WebUtility]::HtmlDecode($tracker.body) | Should -Match 'Expose the requested event\.'
            $tracker.body | Should -Match 'pull/42'
            $tracker.body.TrimEnd() | Should -Match '\*Auto-generated content\*$'
            $visible = [regex]::Replace($tracker.body, '(?s)<!--.*?-->', '')
            $visible | Should -Not -Match $state.cohort.members[0].source_sha
            $pull = @($db.pulls.Values)[0]
            $pull.title | Should -Be (Get-BackportTitle $state)
            $pull.title | Should -Not -Be $tracker.title
            $pull.milestone.number | Should -Be 1
            $pull.labels.name | Should -Contain 'Team: Finance'
            $pull.body | Should -Match "Fixes #$($tracker.number)"
            $pull.body | Should -Match '\[!IMPORTANT\]'
            $db.sources['42'].labels.name | Should -Contain 'ext-backport-processed'
            $db.sources['43'].labels.name | Should -Not -Contain 'ext-backport-processed'
            $db.sources['44'].labels.name | Should -Not -Contain 'ext-backport-processed'
        }

        It 'shares one tracker across teams, iterations and an explicit manual singleton' {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            foreach ($entry in @(@{ start = 50; team = 'Team: SCM'; mode = 'team' }, @{ start = 60; team = 'Team: Client'; mode = 'single' })) {
                $script:state = New-MilestoneFixture -Start $entry.start -Team $entry.team -Mode $entry.mode -Outcomes @('applied')
                Register-MilestoneSources $state
                Save-MilestoneFixture $state
                Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            }
            $db.issues.Count | Should -Be 1
            $db.comments.Count | Should -Be 3
            $db.pulls.Count | Should -Be 3
            $body = @($db.issues.Values)[0].body
            $body | Should -Match 'pull/42'
            $body | Should -Match 'pull/50'
            $body | Should -Match 'pull/60'
            [Net.WebUtility]::HtmlDecode($body) | Should -Match 'Team: Finance'
            [Net.WebUtility]::HtmlDecode($body) | Should -Match 'Team: SCM'
            @($db.issues.Values)[0].labels.name | Should -Contain 'feature-42'
            @($db.issues.Values)[0].labels.name | Should -Contain 'feature-60'
        }

        It 'repairs retries without duplicate rows, comments, PRs or lifecycle changes' -ForEach @(
            @{ status = 'open'; merged = $null }, @{ status = 'closed'; merged = $null },
            @{ status = 'closed'; merged = '2026-10-21T12:00:00Z' }
        ) {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $pull = @($db.pulls.Values)[0]; $pull.state = $status; $pull.merged_at = $merged
            $db.sources['42'].labels = @(@{ name = 'event-request' })
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.comments.Count | Should -Be 1
            $db.pulls.Count | Should -Be 1
            [regex]::Matches(@($db.issues.Values)[0].body, 'bc-extrequest-backport:row:').Count | Should -Be 3
            $db.sources['42'].labels.name | Should -Contain 'ext-backport-processed'
            @($db.writes | Where-Object { $_.body.ContainsKey('state') -and $_.body.state -eq 'closed' }).Count | Should -Be 0
        }

        It 'reopens a matching closed tracker only while its pinned milestone stays open' -ForEach @(
            @{ closedMilestone = $false }, @{ closedMilestone = $true }
        ) {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            @($db.issues.Values)[0].state = 'closed'
            if ($closedMilestone) {
                $db.milestones[0].state = 'closed'
                { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*closed*'
                @($db.issues.Values)[0].state | Should -Be 'closed'
            } else {
                Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
                @($db.issues.Values)[0].state | Should -Be 'open'
            }
            $db.issues.Count | Should -Be 1
        }

        It 'stops prepared-version rollover and uses a new tracker for fresh version-29.2 work' {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $oldBody = @($db.issues.Values)[0].body
            $script:state = New-MilestoneFixture -Start 50 -Outcomes @('applied')
            Register-MilestoneSources $state
            Save-MilestoneFixture $state
            $db.version = '29.2'
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*rollover*'
            $state.release = Get-BackportRelease microsoft/BCApps releases/29.x
            $state.cohort.request.release = $state.release
            [void]$state.cohort.request.Remove('key')
            $state.cohort.request.key = 'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $state.cohort.request)).Substring(0, 32)
            Save-MilestoneFixture $state
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.issues.Count | Should -Be 2
            $db.issues['100'].body | Should -BeExactly $oldBody
            $db.issues['101'].title | Should -Match '\[Version 29.2\]$'
        }

        It 'does not automatically replay a registered all-conflict/no-op cohort or mark its sources processed' {
            $script:state = New-MilestoneFixture -Outcomes @('conflict', 'already-present')
            Register-MilestoneSources $state
            Save-MilestoneFixture $state
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.issues.Count | Should -Be 1
            $db.pulls.Count | Should -Be 0
            $db.comments.Count | Should -Be 1
            Should -Invoke Assert-BackportPreparedBatch -Times 1
            Should -Invoke Invoke-BackportGit -Times 0
            @($db.writes | Where-Object { $_.path -match '/issues/(42|43)/labels$' }).Count | Should -Be 0
        }

        It 'preserves explicit Unassigned/Ambiguous teams and sources without original issues' -ForEach @(
            @{ team = 'Unassigned' }, @{ team = 'Ambiguous' }
        ) {
            $script:state = New-MilestoneFixture -Mode single -Outcomes @('applied')
            $state.cohort.members[0].main_team = $team
            $state.cohort.members[0].issues = @()
            Register-MilestoneSources $state
            Save-MilestoneFixture $state
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            @($db.issues.Values)[0].body | Should -Match "\| $team \|"
            @($db.issues.Values)[0].body | Should -Match 'No linked issue'
        }

        It 'fails closed on unsafe tracker, journal or PR identities' -ForEach @(
            @{ kind = 'tracker-author' }, @{ kind = 'comment-author' }, @{ kind = 'duplicate' },
            @{ kind = 'pull-author' }, @{ kind = 'pull-sha' }, @{ kind = 'milestone' }
        ) {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            switch ($kind) {
                'tracker-author' { $db.issues['100'].user.login = 'human' }
                'comment-author' { $db.comments['1000'].user.login = 'human' }
                'duplicate' {
                    $copy = @{} + $db.comments['1000']; $copy.id = 1001; $db.comments['1001'] = $copy
                }
                'pull-author' { $db.pulls['200'].user.login = 'human' }
                'pull-sha' { $db.pulls['200'].head.sha = '0' * 40 }
                'milestone' { $db.pulls['200'].milestone = $db.milestones[1] }
            }
            $count = $db.writes.Count
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw
            $db.writes.Count | Should -Be $count
        }

        It 'never retries uncertain comment creation within a run' {
            Mock Invoke-BackportApi { throw 'Lost comment response' } -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/comments' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*journal creation is unconfirmed*'
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/comments' }
            $db.pulls.Count | Should -Be 0
        }

        It 'does not repeat an uncertain Task POST, and reuses an observed Task after a lost response' {
            Mock Invoke-BackportApi {
                $script:db.issues['100'] = @{
                    number = 100; title = $Body.title; body = $Body.body; state = 'open'
                    milestone = $script:db.milestones[0]; labels = @(@{ name = 'ext-backporting' })
                    user = @{ login = 'test-app[bot]' }; html_url = 'https://github.com/microsoft/BCApps/issues/100'
                }
                throw 'Lost Task response'
            } -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/issues' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Task creation is unconfirmed*'
            $db.pulls.Count | Should -Be 0
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.issues.Count | Should -Be 1
            $db.pulls.Count | Should -Be 1
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/issues' }
        }

        It 'uses a journal observed at the final membership check instead of repeating comment POST' {
            $script:membershipChecks = 0
            Mock Assert-BackportNewCohort {
                $script:membershipChecks++
                if ($script:membershipChecks -eq 2) {
                    $comment = @{
                        id = 1000; issue_number = 100; body = Get-BackportJournalMarker $script:state
                        user = @{ login = 'test-app[bot]' }
                    }
                    $script:db.comments['1000'] = $comment
                    return @{ issue = $script:db.issues['100']; journal = $comment }
                }
            }
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.comments.Count | Should -Be 1
            $db.pulls.Count | Should -Be 1
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/comments' }
        }

        It 'never overwrites an existing human-modified branch or marks its source processed' {
            Mock Invoke-BackportGit { @{ text = "$('0' * 40)`trefs/heads/backport" } } -ParameterFilter { $Arguments[0] -eq 'ls-remote' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*never overwrite*'
            $db.pulls.Count | Should -Be 0
            $db.sources['42'].labels.name | Should -Not -Contain 'ext-backport-processed'
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
        }

        It 'rejects an orphaned closed standalone backport PR rather than creating a second PR or Task' {
            Mock Get-BackportPull { @{ number = 91; state = 'closed' } }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*standalone backport PR*'
            $db.issues.Count | Should -Be 0
            $db.writes.Count | Should -Be 0
        }

        It 'pushes only the exact prepared branch tip with an empty create-only lease before recording PR intent' {
            $script:pushed = $false
            Mock Invoke-BackportGit {
                if ($Arguments[0] -eq 'push') {
                    $branch = Get-BackportCohortBranch $script:state.cohort
                    $Arguments -join ' ' | Should -BeExactly "push --force-with-lease=refs/heads/$($branch): origin $($script:state.cohort.head):refs/heads/$branch"
                    $script:db.comments['1000'].body | Should -Not -Match 'publication-intent:'
                    $script:pushed = $true
                    return @{ text = '' }
                }
                if ($Arguments[0] -eq 'ls-remote') {
                    if ($script:pushed) { return @{ text = "$($script:state.cohort.head)`trefs/heads/backport" } }
                    return @{ text = '' }
                }
                throw 'Unexpected Git command'
            }
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Should -Invoke Invoke-BackportGit -Times 1 -ParameterFilter { $Arguments[0] -eq 'push' }
            Should -Invoke Invoke-BackportGit -Times 2 -ParameterFilter { $Arguments[0] -eq 'ls-remote' }
        }

        It 'rejects duplicate trackers or an exact-title tracker without an App identity' -ForEach @(
            @{ duplicate = $true }, @{ duplicate = $false }
        ) {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            if ($duplicate) {
                $copy = @{} + $db.issues['100']; $copy.number = 101; $db.issues['101'] = $copy
            } else {
                $db.issues['100'].body = 'Human-created tracker with the exact requested title.'
                $script:state = New-MilestoneFixture -Start 50 -Outcomes @('applied')
                Register-MilestoneSources $state
                Save-MilestoneFixture $state
            }
            $writes = $db.writes.Count
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw
            $db.writes.Count | Should -Be $writes
        }

        It 'filters shared tracker labels without changing original-issue PR labels' {
            $labels = @($state.cohort.members | ForEach-Object { $_.labels })
            $filtered = @(Get-BackportTrackerLabels $state.cohort.members @(
                @{ name = 'retained'; color = 'ffffff'; description = '' },
                @{ name = 'ext-ready-to-implement' }, @{ name = 'ext-backport-processed' }
            ))
            $filtered.name | Should -Contain 'retained'
            $filtered.name | Should -Contain 'ext-backporting'
            $filtered.name | Should -Not -Contain 'ext-ready-to-implement'
            $filtered.name | Should -Not -Contain 'ext-backport-processed'
            @($filtered | Where-Object { $_.name -match '^(Team:|Ownership:)' }).Count | Should -Be 0
            $state.cohort.members[0].labels.name | Should -Contain 'Ownership: External'
            (Get-BackportBatchLabels $state.cohort).name | Should -Contain 'Team: Finance'
            @($state.cohort.members | ForEach-Object { $_.labels }).Count | Should -Be $labels.Count
        }

        It 'persists PR intent in the comment and never blindly retries an uncertain PR POST' {
            Mock Invoke-BackportApi { throw 'Lost PR response' } -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/pulls' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Lost PR response*'
            (Read-BackportPublicationIntent $db.comments['1000'].body) | Should -Be $state.cohort.head
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*unconfirmed*'
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/pulls' }
            $db.sources['42'].labels.name | Should -Not -Contain 'ext-backport-processed'
        }

        It 'paginates exact milestones and more than one hundred distinct cohort journals' {
            $db.milestones = @(1..100 | ForEach-Object { @{ number = $_ + 10; title = "Future $_"; state = 'open' } }) +
                @(@{ number = 1; title = 'Version 29.1'; state = 'open' })
            (Get-BackportRelease microsoft/BCApps releases/29.x).milestone_number | Should -Be 1
            $tracker = @{
                number = 100; title = Get-BackportSharedTitle $state.release; body = Get-BackportSharedBody $state.release
                user = @{ login = 'test-app[bot]' }; milestone = $db.milestones[-1]; state = 'open'; labels = @()
            }
            $db.issues['100'] = $tracker
            foreach ($i in 1..101) {
                $cohort = New-MilestoneFixture -Start (1000 + $i) -Outcomes @('conflict')
                $db.comments[[string]$i] = @{
                    id = $i; issue_number = 100; user = @{ login = 'test-app[bot]' }
                    body = Get-BackportJournalMarker $cohort
                }
            }
            @(Get-BackportJournalRecords microsoft/BCApps).Count | Should -Be 101
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Path -like '*/comments?per_page=100&page=2' }
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Path -like '*/milestones?state=all&per_page=100&page=2' }
        }

        It 'keeps multiple original-issue rows per source and escapes title delimiters' {
            $state.cohort.members[0].issues += @{
                number = 11; url = 'https://github.com/microsoft/BCApps/issues/11'; title = 'AL | symbol <tag>'
            }
            $state.cohort.members[0].issues += $state.cohort.members[0].issues[0]
            Save-MilestoneFixture $state
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $body = $db.issues['100'].body
            [regex]::Matches($body, 'bc-extrequest-backport:row:').Count | Should -Be 4
            [regex]::Matches($body, '\[#200\]').Count | Should -Be 2
            $body | Should -Match 'AL &#124; symbol &#60;tag&#62;&#46;'
        }

        It 'renders source text literally rather than interpreting Markdown, HTML or protocol syntax' -ForEach @(
            @{ text = 'left | right' },
            @{ text = "first`r`nsecond`tthird" },
            @{ text = '[click](https://example.invalid/path "title")' },
            @{ text = '![image](https://example.invalid/image.png)' },
            @{ text = '<a href="https://example.invalid">link</a><script>bad()</script>' },
            @{ text = '<!-- bc-extrequest-backport:journal:v3 AAAA -->' },
            @{ text = '@someone #123 &lt;tag&gt; &#10; &#124;' },
            @{ text = '**bold** _emphasis_ ~~strike~~ `code` \ [ref]: https://example.invalid' },
            @{ text = ([char]::ConvertFromUtf32(0x1f680) + ' AL.OnAfter_Event()') }
        ) {
            $escaped = ConvertTo-BackportTableText $text
            $expected = [regex]::Replace($text, '\s+', ' ').Trim()
            [Net.WebUtility]::HtmlDecode($escaped) | Should -BeExactly $expected
            $withoutEntities = [regex]::Replace($escaped, '&#[0-9]+;', '')
            $withoutEntities | Should -Not -Match '[\x21-\x2f\x3a-\x40\x5b-\x60\x7b-\x7e\r\n]'
            $html = (ConvertFrom-Markdown -InputObject $escaped).Html
            $html | Should -Not -Match '<(?:a|img|script|strong|em|del|code)(?:\s|>)|<!--'
            $visible = [regex]::Replace($html, '^<p>|</p>\s*$', '').Trim()
            [Net.WebUtility]::HtmlDecode($visible) | Should -BeExactly $expected
        }

        It 'publishes hostile issue titles or team names without adding rows, links or hidden identities' -ForEach @(
            @{ field = 'title' }, @{ field = 'team' }
        ) {
            $payload = '[fake](https://example.invalid) ![image](https://example.invalid/a.png) | <b>bad</b> <!-- bc-extrequest-backport:journal:v3 AAAA --> @someone #999 &#124;'
            if ($field -eq 'team') {
                $script:state = New-MilestoneFixture -Team ("Team: $payload")
            } else {
                $state.cohort.members[0].issues[0].title = "$payload`r`n<!-- bc-extrequest-backport:table:end -->"
            }
            Register-MilestoneSources $state
            Save-MilestoneFixture $state
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $body = $db.issues['100'].body
            $rows = @($body -split '\r?\n' | Where-Object { $_ -match 'bc-extrequest-backport:row:' })
            $rows.Count | Should -Be 3
            foreach ($row in $rows) { [regex]::Matches($row, '\|').Count | Should -Be 5 }
            [regex]::Matches($body, '<!-- bc-extrequest-backport:tracker:v3 ').Count | Should -Be 1
            [regex]::Matches($body, '<!-- bc-extrequest-backport:table:end -->').Count | Should -Be 1
            Read-BackportJournalMarker $body | Should -BeNullOrEmpty
            (Read-BackportSharedMarker $body).milestone_number | Should -Be 1
            $html = (ConvertFrom-Markdown -InputObject $body).Html
            [regex]::Matches($html, '<td>').Count | Should -Be 12
            [regex]::Matches($html, '<a href=').Count | Should -Be 7
            $html | Should -Not -Match '<(?:img|b|script)(?:\s|>)|href="https://example\.invalid'
            $db.issues.Count | Should -Be 1
            $db.comments.Count | Should -Be 1
            $db.pulls.Count | Should -Be 1
        }

        It 'retains historical rows while moving old trailing markers inside the fourth table cell' {
            $history = "| Historical issue | [#98](https://github.com/microsoft/BCApps/pull/98) | Team: History | Already present | <!-- bc-extrequest-backport:row:$('0' * 64) -->"
            $body = (Get-BackportSharedBody $state.release).Replace('<!-- bc-extrequest-backport:table:end -->',
                "$history`n<!-- bc-extrequest-backport:table:end -->")
            Add-MilestoneTracker $body
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $body = $db.issues['100'].body
            $body | Should -Match "Already present <!-- bc-extrequest-backport:row:$('0' * 64) --> \|"
            $body | Should -Match 'Historical issue'
            $html = (ConvertFrom-Markdown -InputObject $body).Html
            [regex]::Matches($html, '<th>').Count | Should -Be 4
            [regex]::Matches($html, '<td>').Count | Should -Be 16
        }

        It 'rejects changed pinned request release and unsafe intent or confirmed-PR envelopes' -ForEach @(
            @{ kind = 'release' }, @{ kind = 'intent-sha' }, @{ kind = 'pr-sha' },
            @{ kind = 'pr-duplicate' }, @{ kind = 'complete-duplicate' }, @{ kind = 'pr-without-intent' }
        ) {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $comment = @($db.comments.Values)[0]
            switch ($kind) {
                'release' {
                    $bad = ConvertTo-BackportCanonicalJson $state | ConvertFrom-Json -AsHashtable -Depth 80
                    $bad.release.version = '29.2'; $bad.release.milestone_title = 'Version 29.2'
                    Save-MilestoneFixture $bad
                }
                'intent-sha' { $comment.body = $comment.body.Replace("publication-intent:v1 sha=$($state.cohort.head)", "publication-intent:v1 sha=$('0' * 40)") }
                'pr-sha' { $comment.body = $comment.body.Replace("number=200 sha=$($state.cohort.head)", "number=200 sha=$('0' * 40)") }
                'pr-duplicate' { $comment.body += "`n<!-- bc-extrequest-backport:journal-pr:v1 number=201 sha=$($state.cohort.head) -->" }
                'complete-duplicate' { $comment.body += "`n<!-- bc-extrequest-backport:journal-complete:v1 -->" }
                'pr-without-intent' { $comment.body = $comment.body -replace '(?m)^<!-- bc-extrequest-backport:publication-intent:v1.*\r?\n?', '' }
            }
            $count = $db.writes.Count
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw
            $db.writes.Count | Should -Be $count
        }

        It 'recovers the exact confirmed PR directly if the branch list is temporarily empty' {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Mock Get-BackportBatchPull { $null }
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.pulls.Count | Should -Be 1
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/pulls' }
        }

        It 'fails closed when a journal-confirmed PR is missing rather than posting again' {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.pulls.Clear()
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*missing*'
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/pulls' }
        }

        It 'repairs interrupted publication without new Tasks, journals or PRs' -ForEach @(
            @{ phase = 'table' }, @{ phase = 'source' }, @{ phase = 'milestone' }, @{ phase = 'complete' }
        ) {
            $script:interrupted = $false
            switch ($phase) {
                'table' {
                    Mock Invoke-BackportApi { $script:interrupted = $true; throw 'Table interruption' } -ParameterFilter {
                        -not $script:interrupted -and $Method -eq 'PATCH' -and $Path -match '/issues/\d+$' -and $Body.ContainsKey('body')
                    }
                }
                'source' {
                    Mock Invoke-BackportApi { $script:interrupted = $true; throw 'Source-label interruption' } -ParameterFilter {
                        -not $script:interrupted -and $Method -eq 'POST' -and $Path -like '*/issues/42/labels'
                    }
                }
                'milestone' {
                    Mock Invoke-BackportApi { $script:interrupted = $true; throw 'Milestone interruption' } -ParameterFilter {
                        -not $script:interrupted -and $Method -eq 'PATCH' -and $Path -like '*/issues/200'
                    }
                }
                'complete' {
                    Mock Invoke-BackportApi { $script:interrupted = $true; throw 'Completion interruption' } -ParameterFilter {
                        -not $script:interrupted -and $Method -eq 'PATCH' -and $Path -like '*/issues/comments/*' -and
                        $Body.body.Contains('<!-- bc-extrequest-backport:journal-complete:v1 -->')
                    }
                }
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*interruption*'
            $record = @(Get-BackportJournalRecords microsoft/BCApps)[0]
            $record.journal.body | Should -Not -Match 'journal-complete:v1'
            $row = @(Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 43 -BatchId 999)[0]
            $row.source_prs -join ',' | Should -Be '42,43,44'
            $row.target | Should -Be 'releases/29.x'
            [DateTimeOffset]$row.reference_time | Should -Be ([DateTimeOffset]$state.cohort.request.reference_time)
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.issues.Count | Should -Be 1
            $db.comments.Count | Should -Be 1
            $db.pulls.Count | Should -Be 1
            $db.sources['42'].labels.name | Should -Contain 'ext-backport-processed'
        }

        It 'does not mark a source or retry POST after a PR was created but its response was lost' {
            Mock Invoke-BackportApi {
                $created = @{
                    number = 200; title = $Body.title; body = $Body.body; state = 'open'; merged_at = $null; draft = $true
                    user = @{ login = 'test-app[bot]' }; milestone = $null; html_url = 'https://github.com/microsoft/BCApps/pull/200'
                    head = @{ ref = $Body.head; sha = $script:state.cohort.head; repo = @{ full_name = 'microsoft/BCApps' } }
                    base = @{ ref = $Body.base; repo = @{ full_name = 'microsoft/BCApps' } }; labels = @()
                }
                $script:db.pulls['200'] = $created
                throw 'Lost response'
            } -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/pulls' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*unconfirmed*'
            $db.sources['42'].labels.name | Should -Not -Contain 'ext-backport-processed'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.sources['42'].labels.name | Should -Contain 'ext-backport-processed'
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/pulls' }
        }

        It 'reuses an observed journal after a lost comment POST response without replaying its POST' {
            Mock Invoke-BackportApi {
                $id = $script:db.nextComment++
                $script:db.comments[[string]$id] = @{
                    id = $id; issue_number = 100; body = $Body.body; user = @{ login = 'test-app[bot]' }
                }
                throw 'Lost comment response'
            } -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/issues/100/comments' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*unconfirmed*'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.comments.Count | Should -Be 1
            $db.pulls.Count | Should -Be 1
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/comments' }
        }

        It 'refuses a processed source without a journal before creating any Task' {
            $script:state = New-MilestoneFixture -Mode single -Outcomes @('applied')
            Register-MilestoneSources $state
            Save-MilestoneFixture $state
            $db.sources['42'].labels += @{ name = 'ext-backport-processed' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Processed source*'
            $db.issues.Count | Should -Be 0
            $db.writes.Count | Should -Be 0
        }

        It 'preserves human-managed table edits by failing rather than replacing unknown rows' {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.issues['100'].body = $db.issues['100'].body.Replace('<!-- bc-extrequest-backport:table:end -->',
                "| Human edit | Preserve | Me | Please |`n<!-- bc-extrequest-backport:table:end -->")
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Unrecognized*'
            $db.issues['100'].body | Should -Match 'Human edit'
        }

        It 'retries only an explicitly selected standalone conflict through a linear journal revision' {
            $script:state = New-MilestoneFixture -Mode single -Outcomes @('conflict')
            Register-MilestoneSources $state
            Save-MilestoneFixture $state
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $old = @(Get-BackportJournalRecords microsoft/BCApps)[0]
            $row = @(Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 42 -BatchId 999)[0]
            $row.retry_conflict | Should -BeTrue
            $revision = New-MilestoneFixture -Mode single -Outcomes @('applied')
            $revision.cohort.request = $state.cohort.request
            $revision.supersedes = $old.journal.id
            $script:state = $revision
            Save-MilestoneFixture $state
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.comments.Count | Should -Be 2
            $db.pulls.Count | Should -Be 1
            @(Get-BackportJournalRecords microsoft/BCApps).Count | Should -Be 1
            [regex]::Matches($db.issues['100'].body, 'bc-extrequest-backport:row:').Count | Should -Be 1
            $db.issues['100'].body | Should -Not -Match 'Conflict - manual resolution needed'
            $fork = @{} + $db.comments['1001']
            $fork.id = 1002
            $db.comments['1002'] = $fork
            { Get-BackportJournalRecords microsoft/BCApps } | Should -Throw '*Duplicate/conflicting*'
        }

        It 'keeps a manual team-conflict selection in its original frozen cumulative cohort without Git replay' {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $row = @(Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 43 -BatchId 999)[0]
            $row.ContainsKey('retry_conflict') | Should -BeFalse
            $row.source_prs.Count | Should -Be 3
            New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $row -Depth 80) $statePath
            Should -Invoke Invoke-BackportGit -Times 1
            # The sole Git call was the first publication's exact remote-branch check.
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'cherry-pick' }
            $db.sources['43'].labels.name | Should -Not -Contain 'ext-backport-processed'
        }

        It 'promotes legacy v2 partial publication to the shared Task and resumes old prepared state safely' {
            $legacy = ConvertTo-BackportCanonicalJson $state.cohort | ConvertFrom-Json -AsHashtable -Depth 80
            foreach ($member in $legacy.members) { [void]$member.Remove('main_team') }
            [void]$legacy.request.Remove('release')
            [void]$legacy.request.Remove('key')
            $legacy.request.key = 'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $legacy.request)).Substring(0, 32)
            $db.issues['90'] = @{
                number = 90; body = Get-BackportBatchBody $legacy; title = 'Legacy batch'; state = 'open'
                user = @{ login = 'test-app[bot]' }; milestone = $null; labels = @(@{ name = 'ext-backporting' })
                html_url = 'https://github.com/microsoft/BCApps/issues/90'
            }
            $oldBody = $db.issues['90'].body
            Save-MilestoneFixture $legacy
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $exception = @{} + $legacy.members[1]
            $exception.batch_key = $legacy.request.key
            Publish-ExtRequestBackport $statePath 'test-app[bot]' -PreparedState $exception
            $db.issues.Count | Should -Be 2
            $db.issues['90'].body | Should -BeExactly $oldBody
            $db.comments.Count | Should -Be 1
            $db.pulls.Count | Should -Be 1
            @(Get-BackportBatchRecords microsoft/BCApps).Count | Should -Be 1
            $db.issues['100'].body | Should -Match 'Conflict - manual resolution needed'
        }

        It 'pins legacy cohort promotion during read-only preparation without replaying recorded conflicts' {
            $script:state = New-MilestoneFixture -Outcomes @('conflict')
            Register-MilestoneSources $state
            $legacy = ConvertTo-BackportCanonicalJson $state.cohort | ConvertFrom-Json -AsHashtable -Depth 80
            [void]$legacy.members[0].Remove('main_team')
            [void]$legacy.request.Remove('release')
            [void]$legacy.request.Remove('key')
            $legacy.request.key = 'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $legacy.request)).Substring(0, 32)
            $db.issues['90'] = @{
                number = 90; title = 'Legacy cohort'; body = Get-BackportBatchBody $legacy; state = 'open'; milestone = $null
                user = @{ login = 'test-app[bot]' }; labels = @(@{ name = 'ext-backporting' })
            }
            $row = @{} + $legacy.request
            $row.manifest = $legacy
            New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $row -Depth 80) $statePath
            Should -Invoke Invoke-BackportGit -Times 0
            $db.writes.Count | Should -Be 0
            $prepared = Get-Content $statePath -Raw | ConvertFrom-Json -AsHashtable -Depth 80
            $prepared.schema | Should -Be 3
            $prepared.legacy_issue | Should -Be 90
            $prepared.release.version | Should -Be '29.1'
            $db.version = '29.2'
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*rollover*'
            $db.writes.Count | Should -Be 0
        }

        It 'does not shift a pinned standalone legacy preparation to a new milestone during publication' {
            $member = @{} + $state.cohort.members[0]
            $member.release = $state.release
            $db.issues['90'] = @{
                number = 90; title = 'Legacy Task'; body = Get-BackportBody $member; state = 'open'; milestone = $null
                user = @{ login = 'test-app[bot]' }; labels = @(@{ name = 'ext-backporting' })
            }
            Save-MilestoneFixture $member
            $db.version = '29.2'
            { Publish-ExtRequestBackport $statePath 'test-app[bot]' } | Should -Throw '*rollover*'
            $db.writes.Count | Should -Be 0
            $db.comments.Count | Should -Be 0
        }

        It 'emits compact immutable references instead of tracker bodies, manifests or journal collections' {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.issues['100'].body += "`nManual notes: $('n' * 12000)"
            foreach ($id in 1001..1005) {
                $db.comments[[string]$id] = @{
                    id = $id; issue_number = 100; user = @{ login = 'human' }; body = 'unrelated discussion ' + ('d' * 12000)
                }
            }
            $row = @(Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 43 -BatchId 999)[0]
            $row.tracking_issue | Should -Be 100
            $row.journal_id | Should -Be 1000
            $row.state_digest | Should -Be (Get-BackportDigest (ConvertTo-BackportCanonicalJson $state))
            foreach ($field in 'manifest', 'journal_state', 'body', 'comments', 'members') {
                $row.ContainsKey($field) | Should -BeFalse
            }
            $json = ConvertTo-Json $row -Depth 15 -Compress
            $json.Length | Should -BeLessThan 4000
            $json | Should -Not -Match 'Manual notes|unrelated discussion|bc-extrequest-backport:journal'
            New-ExtRequestBackportBatch microsoft/BCApps $json $statePath
            $prepared = Get-Content $statePath -Raw | ConvertFrom-Json -AsHashtable -Depth 80
            (Get-BackportJournalMarker $prepared) | Should -Be (Get-BackportJournalMarker $state)
        }

        It 'rejects stale or missing compact registry references before Git or publication' -ForEach @(
            @{ field = 'tracking_issue' }, @{ field = 'journal_id' }, @{ field = 'state_digest' }, @{ field = 'missing' }
        ) {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $row = @(Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 43 -BatchId 999)[0]
            if ($field -eq 'missing') { $db.comments.Clear() }
            elseif ($field -eq 'state_digest') { $row.state_digest = '0' * 64 }
            else { $row[$field] = 999 }
            $writes = $db.writes.Count
            { New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $row -Depth 60) $statePath } | Should -Throw
            $db.writes.Count | Should -Be $writes
            Should -Invoke Invoke-BackportGit -Times 1
        }

        It 'stops an over-capacity complete table before PR, journal, label or reopen writes' -ForEach @(
            @{ trackerState = 'open' }, @{ trackerState = 'closed' }
        ) {
            $history = "| $('h' * 64000) | Original history | Team: History | Historical outcome | <!-- bc-extrequest-backport:row:$('1' * 64) -->"
            $body = (Get-BackportSharedBody $state.release).Replace('<!-- bc-extrequest-backport:table:end -->',
                "$history`n<!-- bc-extrequest-backport:table:end -->")
            $body.Length | Should -BeLessThan 65000
            Add-MilestoneTracker $body $trackerState
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*table exceeds*'
            $db.issues['100'].body | Should -BeExactly $body
            $db.issues['100'].state | Should -Be $trackerState
            $db.writes.Count | Should -Be 0
            $db.pulls.Count | Should -Be 0
            $db.comments.Count | Should -Be 0
            Should -Invoke Invoke-BackportGit -Times 0
        }

        It 'reserves complete PR links even when the shorter pending rows would fit' {
            $body = Get-BackportSharedBody $state.release
            $pending = Merge-BackportTrackerRows $body $state $null
            $body += "`n" + ('n' * (65000 - $pending.Length - 1))
            (Merge-BackportTrackerRows $body $state $null).Length | Should -Be 65000
            Add-MilestoneTracker $body
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*table exceeds*'
            $db.pulls.Count | Should -Be 0
            $db.writes.Count | Should -Be 0
        }

        It 'rechecks table capacity after branch preparation and retries safely without a premature intent' {
            $script:grew = $false
            $script:originalBody = ''
            Mock Invoke-BackportGit {
                if ($Arguments[0] -ne 'ls-remote') { throw 'Unexpected Git operation' }
                if (-not $script:grew) {
                    $script:originalBody = $script:db.issues['100'].body
                    $script:db.issues['100'].body += 'n' * (64800 - $script:originalBody.Length)
                    $script:grew = $true
                }
                @{ text = "$($script:state.cohort.head)`trefs/heads/backport" }
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*table exceeds*'
            $db.comments['1000'].body | Should -Not -Match 'publication-intent:'
            $db.pulls.Count | Should -Be 0
            $db.sources['42'].labels.name | Should -Not -Contain 'ext-backport-processed'
            $db.issues['100'].body = $script:originalBody
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.issues.Count | Should -Be 1
            $db.comments.Count | Should -Be 1
            $db.pulls.Count | Should -Be 1
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -like '*/pulls' }
        }

        It 'preserves manual notes outside the managed table during publication and retry' {
            $prefix = "Manual introduction - retain exactly.`n`n"
            $suffix = "`n`nManual footer - retain exactly."
            Add-MilestoneTracker ($prefix + (Get-BackportSharedBody $state.release) + $suffix)
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.issues['100'].body.StartsWith($prefix, [StringComparison]::Ordinal) | Should -BeTrue
            $db.issues['100'].body.EndsWith($suffix, [StringComparison]::Ordinal) | Should -BeTrue
            [regex]::Matches($db.issues['100'].body, 'bc-extrequest-backport:row:').Count | Should -Be 3
        }

        It 'fails stale discovery before initializing a Git preparation' {
            $db.version = '29.2'
            $path = Join-Path $TestDrive 'stale-discovery.json'
            { New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $state.cohort.request -Depth 60) $path } |
                Should -Throw '*rollover*'
            Should -Invoke Invoke-BackportGit -Times 0
            $db.writes.Count | Should -Be 0
            Test-Path $path | Should -BeFalse
        }

        It 'rejects a standalone legacy helper that silently changes the discovered release' {
            $script:state = New-MilestoneFixture -Mode single -Outcomes @('applied')
            Register-MilestoneSources $state
            $db.issues['90'] = @{
                number = 90; title = 'Legacy Task'; body = Get-BackportBody $state.cohort.members[0]
                state = 'open'; milestone = $null; user = @{ login = 'test-app[bot]' }
                labels = @(@{ name = 'ext-backporting' })
            }
            Mock New-ExtRequestBackport {
                @{
                    schema = 1; source_sha = $script:state.cohort.members[0].source_sha
                    release = @{ target = 'releases/29.x'; version = '29.2'; milestone_number = 2; milestone_title = 'Version 29.2' }
                } | ConvertTo-Json -Depth 10 | Set-Content $StatePath
            }
            $path = Join-Path $TestDrive 'legacy-release-mismatch.json'
            { New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $state.cohort.request -Depth 60) $path } |
                Should -Throw '*changed the discovered release*'
            $db.writes.Count | Should -Be 0
        }

        It 'fails a rollover during Git preparation rather than saving a silently retargeted state' {
            Mock Initialize-BackportBatchGit { $script:db.version = '29.2' }
            Mock Invoke-BackportApi { @{ object = @{ sha = $script:state.cohort.target_sha } } } -ParameterFilter {
                $Method -ne 'POST' -and $Path -like '*/git/ref/*'
            }
            Mock Invoke-BackportApi { @{ status = 'ahead' } } -ParameterFilter {
                $Method -ne 'POST' -and $Path -like '*/compare/*'
            }
            Mock Invoke-BackportBatchApply {
                @($script:state.cohort.members | Where-Object source_sha -eq $SourceSha)[0].result
            }
            Mock Invoke-BackportGit {
                if ($Arguments[0] -in @('fetch', 'ls-remote')) { return @{ text = ''; exit_code = 0 } }
                if ($Arguments[0] -eq 'rev-parse') { return @{ text = $script:state.cohort.tree } }
                throw 'Unexpected Git operation'
            }
            $path = Join-Path $TestDrive 'rollover-during-prepare.json'
            { New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $state.cohort.request -Depth 60) $path } |
                Should -Throw '*rollover*'
            Should -Invoke Initialize-BackportBatchGit -Times 1
            $db.writes.Count | Should -Be 0
            Test-Path $path | Should -BeFalse
        }

        It 'revalidates version and milestone after expensive provenance work, before any writes' -ForEach @(
            @{ change = 'version' }, @{ change = 'closed' }, @{ change = 'missing' }
        ) {
            $script:releaseChange = $change
            Mock Assert-BackportPreparedBatch {
                switch ($script:releaseChange) {
                    'version' { $script:db.version = '29.2' }
                    'closed' { $script:db.milestones[0].state = 'closed' }
                    'missing' { $script:db.milestones = @($script:db.milestones | Where-Object number -ne 1) }
                }
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw
            $db.writes.Count | Should -Be 0
            $db.issues.Count | Should -Be 0
            $db.comments.Count | Should -Be 0
            $db.pulls.Count | Should -Be 0
        }

        It 'stops a rollover after Task creation before writing a cohort journal or PR' {
            Mock Invoke-BackportApi {
                $script:db.version = '29.2'
                $script:db.issues['100']
            } -ParameterFilter { $Method -ne 'POST' -and $Method -ne 'PATCH' -and $Path -eq 'repos/microsoft/BCApps/issues/100' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*rollover*'
            $db.issues.Count | Should -Be 1
            $db.issues['100'].milestone.number | Should -Be 1
            $db.comments.Count | Should -Be 0
            $db.pulls.Count | Should -Be 0
            $db.writes.Count | Should -Be 1
        }

        It 'keeps existing journal and PR pins through a later branch version rollover' {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $db.sources['42'].labels = @(@{ name = 'event-request' })
            $db.version = '29.2'
            $row = @(Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 42 -BatchId 999)[0]
            New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $row -Depth 60) $statePath
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $prepared = Get-Content $statePath -Raw | ConvertFrom-Json -AsHashtable -Depth 80
            $prepared.release.version | Should -Be '29.1'
            $db.issues['100'].milestone.number | Should -Be 1
            $db.pulls['200'].milestone.number | Should -Be 1
            $db.issues.Count | Should -Be 1
            $db.pulls.Count | Should -Be 1
            $db.comments.Count | Should -Be 1
            $db.sources['42'].labels.name | Should -Contain 'ext-backport-processed'
        }

        It 'retains a legacy standalone PR without changing its Task or PR and repairs only source processed' {
            $member = $state.cohort.members[0]
            $db.issues['90'] = @{
                number = 90; title = 'Legacy Task'; body = Get-BackportBody $member; state = 'open'; milestone = $null
                user = @{ login = 'test-app[bot]' }; labels = @(@{ name = 'ext-backporting' })
                html_url = 'https://github.com/microsoft/BCApps/issues/90'
            }
            $db.pulls['91'] = @{
                number = 91; body = Get-BackportBody $member 90; state = 'closed'; merged_at = '2026-10-21T12:00:00Z'
                user = @{ login = 'test-app[bot]' }; html_url = 'https://github.com/microsoft/BCApps/pull/91'
                head = @{ ref = Get-BackportBranch 42 $member.target; sha = $member.result.commit; repo = @{ full_name = 'microsoft/BCApps' } }
                base = @{ ref = $member.target; repo = @{ full_name = 'microsoft/BCApps' } }
            }
            Save-MilestoneFixture $member
            Publish-ExtRequestBackport $statePath 'test-app[bot]'
            $db.writes.Count | Should -Be 1
            $db.writes[0].path | Should -Be 'repos/microsoft/BCApps/issues/42/labels'
            $db.issues['90'].state | Should -Be 'open'
            $db.comments.Count | Should -Be 0
            $db.sources['42'].labels.name | Should -Contain 'ext-backport-processed'
            $db.sources['42'].labels = @(@{ name = 'event-request' })
            $db.pulls['91'].head.sha = '0' * 40
            $writes = $db.writes.Count
            { Publish-ExtRequestBackport $statePath 'test-app[bot]' } | Should -Throw '*expected prepared commit*'
            $db.writes.Count | Should -Be $writes
        }
    }
}

BeforeAll {
    & (Get-Module Backport) {
    function script:New-BatchFixture {
        param([string[]] $Outcomes = @('applied', 'applied', 'conflict'))
        $request = @{
            mode = 'team'; team = 'Team: Finance'; target = 'releases/29.x'; batch_id = '123'
            reference_time = [DateTimeOffset]::UtcNow.ToString('o'); manual = $false
            source_prs = @(); sources = @()
            concurrency_key = 'team-finance-29'
        }
        $members = @()
        $tip = 'f' * 40
        for ($i = 0; $i -lt $Outcomes.Count; $i++) {
            $number = 42 + $i
            $sha = ([string][char](97 + $i)) * 40
            $request.source_prs += $number
            $request.sources += @{ number = $number; sha = $sha; merged_at = [DateTimeOffset]::UtcNow.AddDays(-10 + $i).ToString('o') }
            $result = @{ outcome = $Outcomes[$i]; target_sha = $tip; commit = $null; tree = $null; paths = @("src/$number.al") }
            if ($Outcomes[$i] -eq 'applied') {
                $result.commit = ([string]($i + 1)) * 40
                $result.tree = ([string]($i + 4)) * 40
                $tip = $result.commit
            }
            $labels = @(
                @{ name = 'event-request'; color = 'ffffff'; description = '' }
                @{ name = 'Team: Finance'; color = 'ffffff'; description = '' }
                @{ name = "issue-$i"; color = 'ffffff'; description = '' }
                @{ name = 'ext-backporting'; color = '5319E7'; description = '' }
            )
            $members += @{
                schema = 1; repository = 'microsoft/BCApps'; source_pr = $number; source_sha = $sha
                target = $request.target; manual = $false; reference_time = $request.reference_time; source_title = "Source $number"
                labels = $labels
                issues = @(@{ number = 10; url = 'https://github.com/microsoft/BCApps/issues/10'
                    title = 'Expose the requested event'
                    repository = @{ nameWithOwner = 'microsoft/BCApps' }; labels = @{ nodes = $labels[0..2] } })
                result = $result
            }
        }
        $module = Get-Module Backport
        $request.key = & $module {
            param($Row)
            'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $Row)).Substring(0, 32)
        } $request
        $tree = if (@($members | Where-Object { $_.result.outcome -eq 'applied' }).Count -gt 0) {
            @($members | Where-Object { $_.result.outcome -eq 'applied' })[-1].result.tree
        } else { 'e' * 40 }
        @{ schema = 2; repository = 'microsoft/BCApps'; request = $request; members = $members; target_sha = 'f' * 40
            head = $tip; tree = $tree }
    }
    }
}

Describe 'Team batch discovery and immutable identity' {
    InModuleScope Backport {
        BeforeEach {
            $script:fixture = New-BatchFixture
            $script:sourceData = @{}
            $script:issueData = @{}
            foreach ($member in $fixture.members) {
                $script:sourceData[[string]$member.source_pr] = @{
                    number = $member.source_pr; title = $member.source_title; merge_commit_sha = $member.source_sha
                    merged_at = $fixture.request.sources[$member.source_pr - 42].merged_at
                    updated_at = [DateTimeOffset]::UtcNow.ToString('o')
                    base = @{ ref = 'main'; repo = @{ full_name = 'microsoft/BCApps' } }
                    labels = @($member.labels | Where-Object { $_.name -ne 'ext-backporting' })
                }
                $script:issueData[[string]$member.source_pr] = $member.issues
            }
            Mock Get-BackportBatchRecords { @() }
            Mock Get-BackportRelease {
                $major = ($Target -split '/')[1] -replace '\.x$', ''
                @{ target = $Target; version = "$major.1"; milestone_number = 1; milestone_title = "Version $major.1" }
            }
            Mock Get-BackportTracking { $null }
            Mock Get-BackportSource { $script:sourceData[[string]$Number] }
            Mock Get-BackportSourceIssues { $script:issueData[[string]$Number] }
            Mock Get-BackportApiPages { @(@{ name = 'releases/29.x' }, @{ name = 'releases/9.x' }) }
            Mock Invoke-BackportApi {
                if ([string]::IsNullOrEmpty($Method)) { $Method = 'GET' }
                if ($Method -ne 'GET') { throw 'Discovery must be read-only.' }
                @($script:sourceData.Values)
            }
        }

        It 'groups whole multi-issue sources by their main PR team in oldest-first order' {
            $script:issueData['42'] += @{
                number = 11; url = 'https://github.com/microsoft/BCApps/issues/11'
                repository = @{ nameWithOwner = 'microsoft/BCApps' }
                labels = @{ nodes = @(@{ name = 'event-request' }, @{ name = 'Team: Finance' }) }
            }
            $rows = @(Find-ExtRequestBackportBatches microsoft/BCApps -BatchId 123)
            $rows.Count | Should -Be 1
            $rows[0].mode | Should -Be 'team'
            $rows[0].source_prs -join ',' | Should -Be '42,43,44'
            $rows[0].team | Should -Be 'Team: Finance'
            $rows[0].key | Should -Match '^team-[a-f0-9]{32}$'
            Assert-BackportBatchRequest $rows[0]
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Method -eq 'POST' }
        }

        It 'keeps missing, multiple or inconsistent teams independent without skipping sources' -ForEach @(
            @{ kind = 'missing-pr' }, @{ kind = 'multiple-pr' }, @{ kind = 'missing-issue' },
            @{ kind = 'multiple-issue' }, @{ kind = 'different-issue' }, @{ kind = 'external-issue' }
        ) {
            switch ($kind) {
                'missing-pr' { $script:sourceData['42'].labels = @(@{ name = 'event-request' }) }
                'multiple-pr' { $script:sourceData['42'].labels += @{ name = 'Team: Other' } }
                'missing-issue' { $script:issueData['42'][0].labels.nodes = @(@{ name = 'event-request' }) }
                'multiple-issue' { $script:issueData['42'][0].labels.nodes += @{ name = 'Team: Other' } }
                'different-issue' {
                    $script:issueData['42'][0].labels.nodes = @(@{ name = 'event-request' }, @{ name = 'Team: Other' })
                }
                'external-issue' { $script:issueData['42'][0].repository.nameWithOwner = 'other/repo' }
            }
            $rows = @(Find-ExtRequestBackportBatches microsoft/BCApps -BatchId 123)
            $rows.Count | Should -Be 2
            @($rows | Where-Object mode -eq 'single')[0].source_prs -join ',' | Should -Be '42'
            @($rows | Where-Object mode -eq 'team')[0].source_prs -join ',' | Should -Be '43,44'
        }

        It 'uses the sole main PR team when no original issue exists' {
            $script:issueData['42'] = @()
            @(Find-ExtRequestBackportBatches microsoft/BCApps -BatchId 123).Count | Should -Be 1
        }

        It 'retains category checks on each linked original issue' {
            $script:issueData['42'][0].labels.nodes += @{ name = 'enum-request' }
            $rows = @(Find-ExtRequestBackportBatches microsoft/BCApps -BatchId 123)
            $rows[0].source_prs -join ',' | Should -Be '43,44'
        }

        It 'keeps legacy requests and interrupted source intents independent and pinned' {
            $script:sourceData['42'].labels += @{ name = 'ext-backport-pending:28.x' }
            Mock Get-BackportTracking {
                if ($SourcePr -eq 43) {
                    @{ body = Get-BackportMarker 43 'releases/27.x' ('b' * 40) }
                }
            }
            $rows = @(Find-ExtRequestBackportBatches microsoft/BCApps -BatchId 123)
            $rows.Count | Should -Be 3
            ($rows | Where-Object key -eq 'single-42').target | Should -Be 'releases/28.x'
            ($rows | Where-Object key -eq 'single-43').target | Should -Be 'releases/27.x'
        }

        It 'manual single bypasses dates, categories and processed filters and yields exactly one source' {
            $script:sourceData['42'].merged_at = '2020-01-01T00:00:00Z'
            $script:sourceData['42'].labels = @(@{ name = 'enum-request' }, @{ name = 'ext-backport-processed' })
            $script:issueData['42'][0].labels.nodes = @(@{ name = 'enum-request' })
            $rows = @(Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 42 -BatchId 123)
            $rows.Count | Should -Be 1
            $rows[0].mode | Should -Be 'single'
            $rows[0].manual | Should -BeTrue
            $rows[0].source_prs -join ',' | Should -Be '42'
        }

        It 'manual full uses the same automatic filtering and fixed discovery clock' {
            $script:sourceData['42'].labels += @{ name = 'ext-backport-processed' }
            $script:sourceData['43'].merged_at = [DateTimeOffset]::UtcNow.AddDays(-16).ToString('o')
            $rows = @(Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr '' -BatchId 123)
            $rows[0].source_prs -join ',' | Should -Be '44'
            $rows[0].manual | Should -BeFalse
            [DateTimeOffset]$rows[0].reference_time | Should -BeLessOrEqual ([DateTimeOffset]::UtcNow)
        }

        It 'validates queued workers against the fixed discovery clock rather than their current date' {
            $clock = [DateTimeOffset]::UtcNow.AddDays(-30)
            $fixture.request.reference_time = $clock.ToString('o')
            foreach ($proof in $fixture.request.sources) {
                $proof.merged_at = $clock.AddDays(-14).AddMinutes($proof.number).ToString('o')
                $script:sourceData[[string]$proof.number].merged_at = $proof.merged_at
            }
            Test-BackportAutomaticSource $script:sourceData['42'] | Should -BeFalse
            @(Assert-BackportBatchSources $fixture.request microsoft/BCApps).Count | Should -Be 3
        }

        It 'delegates manual independent preparation and preserves the schema-one publication API' {
            Mock Get-BackportTracking {
                @{ number = 90; body = Get-BackportMarker 42 releases/29.x ('a' * 40) }
            }
            $row = @(Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 42 -BatchId 123)[0]
            $path = Join-Path $TestDrive 'single.json'
            Mock Assert-BackportRelease {}
            Mock New-ExtRequestBackport {
                @{ schema = 1; source_sha = 'a' * 40 } | ConvertTo-Json | Set-Content $StatePath
            }
            New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $row -Depth 60) $path
            Should -Invoke New-ExtRequestBackport -Times 1 -ParameterFilter {
                $Manual -and $SourcePr -eq 42 -and $Target -eq 'releases/29.x' -and
                $ReferenceTime -eq [DateTimeOffset]$row.reference_time
            }
            Mock Publish-BackportLegacyOrPromote {}
            Publish-ExtRequestBackportBatch $path 'test-app[bot]'
            Should -Invoke Publish-BackportLegacyOrPromote -Times 1
        }

        It 'routes the old per-PR prepare API to its immutable existing batch' {
            Mock Get-BackportBatchRecords { @{ issue = @{ number = 90; state = 'open' }; manifest = $script:fixture } }
            Mock New-ExtRequestBackportBatch {}
            New-ExtRequestBackport microsoft/BCApps 42 releases/99.x $true (Join-Path $TestDrive 'legacy.json')
            Should -Invoke New-ExtRequestBackportBatch -Times 1 -ParameterFilter {
                ($RequestJson | ConvertFrom-Json).source_prs.Count -eq 3 -and
                ($RequestJson | ConvertFrom-Json).target -eq 'releases/29.x'
            }
        }

        It 'manual batch member returns exactly its frozen batch including already processed members' {
            Mock Get-BackportBatchRecords { @{ issue = @{ number = 90; state = 'open' }; manifest = $script:fixture } }
            $script:sourceData['42'].labels += @{ name = 'ext-backport-processed' }
            $rows = @(Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 43 -TargetOverride releases/99.x -BatchId 999)
            $rows.Count | Should -Be 1
            $rows[0].key | Should -Be $fixture.request.key
            $rows[0].source_prs -join ',' | Should -Be '42,43,44'
            $rows[0].target | Should -Be 'releases/29.x'
            $rows[0].batch_id | Should -Be '123'
            Should -Invoke Invoke-BackportApi -Times 0
        }

        It 'resumes an open immutable batch even when all members are outside discovery' {
            Mock Get-BackportBatchRecords { @{ issue = @{ number = 90; state = 'open' }; manifest = $script:fixture } }
            Mock Invoke-BackportApi { @() }
            $rows = @(Find-ExtRequestBackportBatches microsoft/BCApps -BatchId 999)
            $rows.Count | Should -Be 1
            $rows[0].key | Should -Be $fixture.request.key
        }

        It 'does not poll a completed batch or replay its recorded conflict while its Task stays open' {
            Mock Get-BackportBatchRecords { @{ issue = @{ number = 90; state = 'open' }; manifest = $script:fixture } }
            foreach ($number in 42, 43) { $script:sourceData[[string]$number].labels += @{ name = 'ext-backport-processed' } }
            Mock Get-BackportTracking {
                if ($SourcePr -eq 44) { @{ state = 'open'; body = 'Preparation result: **conflict**.' } }
            }
            @(Find-ExtRequestBackportBatches microsoft/BCApps -BatchId 999).Count | Should -Be 0
            $rows = @(Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 44 -BatchId 999)
            $rows.Count | Should -Be 1
            $rows[0].key | Should -Be $fixture.request.key
        }

        It 'rejects changed frozen membership, targets, source proofs and malformed manifests' -ForEach @(
            @{ kind = 'target' }, @{ kind = 'membership' }, @{ kind = 'sha' }, @{ kind = 'parent' }
        ) {
            Assert-BackportBatchManifest $fixture
            $marker = Get-BackportBatchMarker $fixture
            (Read-BackportBatchMarker $marker).request.key | Should -Be $fixture.request.key
            { Read-BackportBatchMarker "$marker`n$marker" } | Should -Throw
            { Read-BackportBatchMarker '<!-- bc-extrequest-backport:v2 bad -->' } | Should -Throw
            switch ($kind) {
                'target' { $fixture.request.target = 'releases/30.x' }
                'membership' { $fixture.request.source_prs[0] = 999 }
                'sha' { $fixture.request.sources[0].sha = 'e' * 40 }
                'parent' { $fixture.members[1].result.target_sha = 'e' * 40 }
            }
            { Assert-BackportBatchManifest $fixture } | Should -Throw
        }
    }
}
Describe 'Backport descriptions and titles' {
    InModuleScope Backport {
        BeforeEach {
            $script:presentationState = @{
                schema = 1; repository = 'microsoft/BCApps'; source_pr = 42; target = 'releases/29.x'
                source_sha = 'a' * 40; source_title = 'Expose an event'; result = @{ outcome = 'applied' }
                issues = @(@{ url = 'https://github.com/microsoft/BCApps/issues/10'; title = 'Expose a new event' },
                    @{ url = 'https://github.com/microsoft/BCApps/issues/11'; title = 'Make the helper public' },
                    @{ url = 'https://github.com/microsoft/BCApps/issues/10'; title = 'Expose a new event' })
            }
            $script:expectedCore = @(
                'Backporting of extensibility requests to `releases/29.x`.'
                ''
                'Issues:'
                '- https://github.com/microsoft/BCApps/issues/10'
                '- https://github.com/microsoft/BCApps/issues/11'
                ''
                'PRs:'
                '- https://github.com/microsoft/BCApps/pull/42'
            ) -join "`n"
        }

        It 'renders the exact PR layout with a new-Task Fixes reference and Important AI disclaimer' {
            $body = Get-BackportBody $presentationState 99
            $visible = [regex]::Replace($body, '(?s)<!--.*?-->\s*', '').Trim()
            $expected = @($expectedCore, '', 'Fixes #99', '', '> [!IMPORTANT]',
                '> AI-generated: content may be inaccurate or incomplete. Please review and verify before relying on or merging.') -join "`n"
            $visible | Should -BeExactly $expected
            $visible | Should -Not -Match 'Source merge:|Original main issues|Preparation result:'
            $visible | Should -Not -Match ('a' * 40)
            (Read-BackportMarker $body).sha | Should -Be ('a' * 40)
        }

        It 'lists original issues with summaries but no PR list, Fixes or Important in a tracking Task' {
            $body = Get-BackportBody $presentationState
            $visible = [regex]::Replace($body, '(?s)<!--.*?-->\s*', '').Trim()
            $expected = @(
                'Backporting of extensibility requests to `releases/29.x`.'
                ''
                'Issues:'
                '- https://github.com/microsoft/BCApps/issues/10 - Expose a new event.'
                '- https://github.com/microsoft/BCApps/issues/11 - Make the helper public.'
                ''
                '*Auto-generated content*'
            ) -join "`n"
            $visible | Should -BeExactly $expected
            $visible | Should -Not -Match '(?i)\bfixes\s|\[!IMPORTANT\]|PRs:|/pull/'
            $body | Should -Match '<!-- Preparation result: \*\*applied\*\*\. -->'
        }

        It 'uses original issue titles as concise summaries without breaking AL names' -ForEach @(
            @{ title = "  Make RunModalWith public`r`n on page 20441  "; summary = 'Make RunModalWith public on page 20441.' },
            @{ title = 'Expose the Qlty. Edit Large Text helper!'; summary = 'Expose the Qlty. Edit Large Text helper!' }
        ) {
            Get-BackportIssueSummary @{ title = $title; url = 'issue-url' } | Should -BeExactly $summary
        }

        It 'fails explicitly if an original issue has no title for its summary' {
            { Get-BackportIssueSummary @{ url = 'issue-url' } } | Should -Throw '*no title to summarize*'
            { Get-BackportIssueSummary @{ url = 'issue-url'; title = ' ' } } | Should -Throw '*no title to summarize*'
        }

        It 'uses the same team layout and includes only applied sources with deduplicated original issues' {
            $manifest = New-BatchFixture
            $body = Get-BackportBatchBody $manifest 99
            $visible = [regex]::Replace($body, '(?s)<!--.*?-->\s*', '').Trim()
            $expected = @(
                'Backporting of extensibility requests for Team: Finance to `releases/29.x`.'
                ''
                'Issues:'
                '- https://github.com/microsoft/BCApps/issues/10'
                ''
                'PRs:'
                '- https://github.com/microsoft/BCApps/pull/42'
                '- https://github.com/microsoft/BCApps/pull/43'
                ''
                'Fixes #99'
                ''
                '> [!IMPORTANT]'
                '> AI-generated: content may be inaccurate or incomplete. Please review and verify before relying on or merging.'
            ) -join "`n"
            $visible | Should -BeExactly $expected
            $visible | Should -Not -Match 'pull/44|Independent outcomes|Source merge:'
            $issue = Get-BackportBatchBody $manifest
            $visibleIssue = [regex]::Replace($issue, '(?s)<!--.*?-->\s*', '').Trim()
            $expectedIssue = @(
                'Backporting of extensibility requests for Team: Finance to `releases/29.x`.'
                ''
                'Issues:'
                '- https://github.com/microsoft/BCApps/issues/10 - Expose the requested event.'
                ''
                '*Auto-generated content*'
            ) -join "`n"
            $visibleIssue | Should -BeExactly $expectedIssue
            $visibleIssue | Should -Not -Match 'PRs:|/pull/'
            $issue.TrimEnd() | Should -Match '\*Auto-generated content\*$'
            $issue | Should -Not -Match '(?m)^Fixes '
            (Read-BackportBatchMarker $body).members.Count | Should -Be 3
        }

        It 'uses the Copenhagen discovery date for a stable team title' -ForEach @(
            @{ reference = '2026-10-20T22:30:00Z'; expectedDate = '2026-10-21' },
            @{ reference = '2026-12-20T23:30:00Z'; expectedDate = '2026-12-21' }
        ) {
            $state = @{ schema = 2; request = @{
                target = 'releases/29.x'; team = 'Team: SCM'; reference_time = $reference
            } }
            Get-BackportTitle $state | Should -BeExactly "[Backport 29.x] [Extensibility Requests] [Team: SCM] till $expectedDate"
        }

        It 'keeps individual titles bounded and single-line' {
            Get-BackportTitle $presentationState | Should -BeExactly '[Backport 29.x] #42: Expose an event'
            $presentationState.source_title = "Line one`n" + ('x' * 300)
            $title = Get-BackportTitle $presentationState
            $title.Length | Should -Be 240
            $title | Should -Not -Match '[\r\n]'
        }
    }
}

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

        It 'uses a rolling fifteen-day inclusive cutoff and has no November cutoff' {
            $now = [DateTimeOffset]'2026-10-19T12:00:00Z'
            Test-BackportAutomaticSource (New-TestSource -Merged '2026-10-04T12:00:00Z') $now | Should -BeTrue
            Test-BackportAutomaticSource (New-TestSource -Merged '2026-10-04T11:59:59Z') $now | Should -BeFalse
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

        It 'excludes processed original main PRs carrying ext-backport-processed' {
            $source = New-TestSource @('event-request', 'ext-backport-processed')
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
                @{ name = 'event-request' }, @{ name = 'ext-ready-to-implement' },
                @{ name = 'ext-backport-processed' }
            ))
            $labels.name | Should -Contain 'event-request'
            $labels.name | Should -Contain 'ext-backporting'
            $labels.name | Should -Not -Contain 'ext-ready-to-implement'
            $labels.name | Should -Not -Contain 'ext-backport-processed'
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

        It 'includes original links and references only the new tracking Task with Fixes' {
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
            $body | Should -Match '(?m)^Fixes #99$'
            $body | Should -Not -Match '(?m)^Fixes #(10|11)$'
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

        It 'does not rediscover a processed source PR in the fifteen-day window' {
            Mock Invoke-BackportApi {
                @(
                    @{
                        number = 42; merged_at = [DateTimeOffset]::UtcNow.AddDays(-1).ToString('o')
                        updated_at = [DateTimeOffset]::UtcNow.ToString('o'); base = @{ ref = 'main' }
                        labels = @(@{ name = 'event-request' }, @{ name = 'ext-backport-processed' })
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

        It 'writes only the single processed label to the original main PR' {
            Mock Ensure-BackportLabels {}
            Mock Invoke-BackportApi {}
            Set-BackportProcessed microsoft/BCApps 42
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                $Path -eq 'repos/microsoft/BCApps/issues/42/labels' -and $Method -eq 'POST' -and
                $Body.labels -contains 'ext-backport-processed' -and
                $Body.labels.Count -eq 1
            }
            Should -Invoke Ensure-BackportLabels -Times 1 -ParameterFilter {
                @($Labels | Where-Object name -eq 'ext-backport-processed').Count -eq 1
            }
        }

        It 'removes the obsolete lifecycle API and accepts only well-formed publication intents' {
            (Get-Module Backport).ExportedFunctions.Keys | Should -Not -Contain 'Sync-ExtRequestBackport'
            Get-Command Add-BackportStatus, Remove-BackportIntents, Get-BackportStatusLabel -ErrorAction SilentlyContinue |
                Should -BeNullOrEmpty
            Read-BackportPublicationIntent 'ordinary issue' | Should -BeNullOrEmpty
            $marker = "<!-- bc-extrequest-backport:publication-intent:v1 sha=$('a' * 40) -->"
            Read-BackportPublicationIntent $marker | Should -Be ('a' * 40)
            { Read-BackportPublicationIntent "$marker`n$marker" } | Should -Throw
            { Read-BackportPublicationIntent '<!-- bc-extrequest-backport:publication-intent:bad -->' } | Should -Throw
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

        It 'never changes an existing local-bare ref even when an identical head succeeds as a no-op' -ForEach @(
            @{ existing = 'absent' }, @{ existing = 'ancestor' }, @{ existing = 'divergent' }, @{ existing = 'identical' }
        ) {
            $bare = Join-Path $TestDrive ([guid]::NewGuid().ToString('N') + '.git')
            $null = Invoke-BackportGit $directory @('init', '--bare', '--quiet', $bare)
            $null = Invoke-BackportGit $directory @('remote', 'add', 'origin', $bare)
            $script:createOnlyActualGit = (Get-Command Invoke-BackportGit).ScriptBlock
            Mock Invoke-BackportGit {
                & $script:createOnlyActualGit -Directory $Directory `
                    -Arguments (@('-c', 'protocol.file.allow=always') + $Arguments) `
                    -InputText $InputText -AllowFailure:$AllowFailure -CommitDate $CommitDate
            }
            $prepared = Invoke-BackportApply $directory $source $base
            $prepared.outcome | Should -Be 'applied'
            $null = Invoke-BackportGit $directory @('push', 'origin', "$($prepared.commit):refs/heads/fixture")
            $branch = 'bc-extrequest-backport/backport_11166'
            $ref = "refs/heads/$branch"
            (Invoke-BackportGit $directory @('ls-remote', '--heads', 'origin', $ref)).text.Trim() | Should -BeNullOrEmpty
            if ($existing -ne 'absent') {
                $foreign = if ($existing -eq 'identical') { $prepared.commit } else { $base }
                if ($existing -eq 'divergent') {
                    $null = Invoke-BackportGit $directory @('checkout', '--detach', $base)
                    $null = Invoke-BackportGit $directory @('commit', '--quiet', '--allow-empty', '-m', 'foreign divergent head')
                    $foreign = (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim()
                    $null = Invoke-BackportGit $directory @('push', 'origin', "$($foreign):refs/heads/foreign-fixture")
                }
                $null = Invoke-BackportGit $directory @("--git-dir=$bare", 'update-ref', $ref, $foreign)
                if ($existing -eq 'ancestor') {
                    (Invoke-BackportGit $directory @('push', '--dry-run', 'origin', "$($prepared.commit):$ref")).exit_code |
                        Should -Be 0
                }
                if ($existing -eq 'identical') {
                    { Publish-BackportBranchCreateOnly $directory $branch $prepared.commit } | Should -Not -Throw
                }
                else {
                    { Publish-BackportBranchCreateOnly $directory $branch $prepared.commit } | Should -Throw '*failed*'
                }
                (Invoke-BackportGit $directory @("--git-dir=$bare", 'rev-parse', $ref)).text.Trim() | Should -BeExactly $foreign
            }
            else {
                Publish-BackportBranchCreateOnly $directory $branch $prepared.commit
                (Invoke-BackportGit $directory @("--git-dir=$bare", 'rev-parse', $ref)).text.Trim() | Should -BeExactly $prepared.commit
            }
            Should -Invoke Invoke-BackportGit -Times 1 -ParameterFilter {
                $Arguments[0] -eq 'push' -and
                $Arguments[1] -ceq '--force-with-lease=refs/heads/bc-extrequest-backport/backport_11166:' -and
                $Arguments[2] -ceq 'origin' -and
                $Arguments[3] -ceq "$($prepared.commit):refs/heads/bc-extrequest-backport/backport_11166"
            }
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

        It 'preserves cumulative same-file changes with one provenance commit per oldest-first source' {
            [IO.File]::WriteAllText((Join-Path $directory 'src/Foo.al'), "source`nsecond`n")
            $null = Invoke-BackportGit $directory @('commit', '--quiet', '-am', 'second')
            $second = (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim()
            $firstResult = Invoke-BackportApply $directory $source $base
            $secondResult = Invoke-BackportApply $directory $second $firstResult.commit
            $secondResult.outcome | Should -Be 'applied'
            (Invoke-BackportGit $directory @('rev-parse', 'HEAD^^')).text.Trim() | Should -Be $base
            (Invoke-BackportGit $directory @('show', 'HEAD:src/Foo.al')).text | Should -Be "source`nsecond`n"
            (Invoke-BackportGit $directory @('log', '-2', '--format=%B')).text |
                Should -Match "cherry picked from commit $source"
            (Invoke-BackportGit $directory @('log', '-1', '--format=%B')).text |
                Should -Match "cherry picked from commit $second"
        }

        It 'retains a cumulative-tip conflict even when the same source applies cleanly to the original release' {
            [IO.File]::WriteAllText((Join-Path $directory 'src/Foo.al'), "base`n")
            $null = Invoke-BackportGit $directory @('commit', '--quiet', '-am', 'unselected main revert')
            [IO.File]::WriteAllText((Join-Path $directory 'src/Foo.al'), "other`n")
            $null = Invoke-BackportGit $directory @('commit', '--quiet', '-am', 'later source')
            $later = (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim()
            $first = Invoke-BackportBatchApply $directory $source $base $base @()
            $first.outcome | Should -Be 'applied'
            $cumulative = Invoke-BackportBatchApply $directory $later $first.commit $base @()
            $cumulative.outcome | Should -Be 'conflict'
            $cumulative.commit | Should -BeNullOrEmpty
            (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim() | Should -Be $first.commit
            (Invoke-BackportGit $directory @('show', 'HEAD:src/Foo.al')).text | Should -Be "source`n"
            $releaseOnly = Invoke-BackportApply $directory $later $base
            $releaseOnly.outcome | Should -Be 'applied'
            $cumulative.outcome | Should -Be 'conflict'
        }

        It 'prepares real Git through the team or standalone API and resumes immutable state' -ForEach @(
            @{ mode = 'team'; collision = $false }, @{ mode = 'single'; collision = $false },
            @{ mode = 'team'; collision = $true }, @{ mode = 'single'; collision = $true }
        ) {
            [IO.File]::WriteAllText((Join-Path $directory 'src/Foo.al'), "source`nsecond`n")
            $null = Invoke-BackportGit $directory @('commit', '--quiet', '-am', 'second')
            $second = (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim()
            [string[]]$outcomes = if ($mode -eq 'single') { @('applied') } else { @('applied', 'applied') }
            $script:fixture = New-BatchFixture -Outcomes $outcomes
            $request = $fixture.request
            $request.sources[0].sha = $source
            if ($mode -eq 'team') { $request.sources[1].sha = $second }
            else { $request.sources[0].merged_at = '2020-01-01T00:00:00Z' }
            [void]$request.Remove('key')
            $request.key = 'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $request)).Substring(0, 32)
            $script:request = $request
            $script:release = $base
            $script:durable = $null
            $script:remoteHead = ''
            $script:occupiedBranch = ''
            if ($collision) {
                $script:occupiedBranch = if ($mode -eq 'single') { 'bc-extrequest-backport/backport_42' }
                    else { Get-BackportBranchBase $request }
            }
            $script:actualGit = (Get-Command Invoke-BackportGit).ScriptBlock
            Mock Get-BackportBatchRecords {
                if ($null -ne $script:durable) {
                    @{ shared = $true; issue = @{ state = 'open' }; manifest = $script:durable
                        journal_state = $script:preparedState; journal = @{ body = Get-BackportJournalMarker $script:preparedState } }
                }
            }
            Mock Get-BackportRelease {
                @{ target = 'releases/29.x'; version = '29.1'; milestone_number = 1; milestone_title = 'Version 29.1' }
            }
            Mock Assert-BackportRelease {}
            Mock Get-BackportBatchPull { $null }
            Mock Get-BackportTracking { $null }
            Mock Get-BackportSource {
                $proof = @($script:request.sources | Where-Object number -eq $Number)[0]
                @{
                    number = $Number; title = "Source $Number"; merge_commit_sha = $proof.sha; merged_at = $proof.merged_at
                    base = @{ ref = 'main'; repo = @{ full_name = 'microsoft/BCApps' } }
                    labels = if ($script:request.sources.Count -eq 1) { @(@{ name = 'enum-request' }) }
                        else { @(@{ name = 'event-request' }, @{ name = 'Team: Finance' }) }
                }
            }
            Mock Get-BackportSourceIssues { @($script:fixture.members | Where-Object source_pr -eq $Number)[0].issues }
            Mock Initialize-BackportBatchGit {}
            Mock Invoke-BackportApi {
                if ([string]::IsNullOrEmpty($Method)) { $Method = 'GET' }
                if ($Method -ne 'GET') { throw 'Preparation attempted a remote write.' }
                if ($Path -like '*/git/ref/*') { return @{ object = @{ sha = $script:release } } }
                if ($Path -like '*/compare/*') { return @{ status = 'ahead' } }
                throw "Unexpected API read: $Path"
            }
            Mock Invoke-BackportGit {
                if ($Arguments[0] -eq 'fetch') { return @{ text = ''; exit_code = 0 } }
                if ($Arguments[0] -eq 'ls-remote') {
                    if ($script:occupiedBranch -and $Arguments[-1] -ceq "refs/heads/$script:occupiedBranch") {
                        return @{ text = "$('0' * 40)`trefs/heads/$script:occupiedBranch"; exit_code = 0 }
                    }
                    return @{ text = $script:remoteHead; exit_code = 0 }
                }
                & $script:actualGit -Directory $Directory -Arguments $Arguments -InputText $InputText `
                    -AllowFailure:$AllowFailure -CommitDate $CommitDate
            }
            $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $null = New-Item -ItemType Directory $root
            $preparedDirectory = Join-Path $root 'git'
            Move-Item -LiteralPath $directory -Destination $preparedDirectory
            $statePath = Join-Path $root 'state.json'
            if ($mode -eq 'single') {
                New-ExtRequestBackport microsoft/BCApps 42 releases/29.x $true $statePath
            } else {
                New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $request -Depth 60) $statePath
            }
            $script:preparedState = Get-Content $statePath -Raw | ConvertFrom-Json -AsHashtable -Depth 80
            $preparedState.schema | Should -Be 3
            $script:durable = $preparedState.cohort
            $expectedBranch = Get-BackportBranchBase $durable.request
            if ($collision) { $expectedBranch += '-2' }
            $durable.branch | Should -BeExactly $expectedBranch
            $durable.members.Count | Should -Be $outcomes.Count
            if ($mode -eq 'team') {
                $durable.members[1].result.target_sha | Should -Be $durable.members[0].result.commit
                (Invoke-BackportGit $preparedDirectory @('show', "$($durable.head):src/Foo.al")).text | Should -Be "source`nsecond`n"
            } else {
                $durable.members[0].main_team | Should -Be 'Unassigned'
                $durable.request.manual | Should -BeTrue
                $durable.request.key | Should -Be 'single-42'
            }
            Assert-BackportPreparedBatch $durable $preparedDirectory
            $tampered = $durable | ConvertTo-Json -Depth 60 | ConvertFrom-Json -AsHashtable -Depth 60
            $tampered.members[-1].result.paths = @('src/Unexpected.al')
            { Assert-BackportPreparedBatch $tampered $preparedDirectory } | Should -Throw '*provenance differs*'
            $resumeRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $null = New-Item -ItemType Directory $resumeRoot
            Copy-Item -LiteralPath $preparedDirectory -Destination (Join-Path $resumeRoot 'git') -Recurse
            $script:release = '0' * 40
            $script:remoteHead = "$($durable.head)`trefs/heads/$($durable.branch)"
            $row = @{} + $durable.request
            $row.manifest = $durable
            $resumedPath = Join-Path $resumeRoot 'state.json'
            New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $row -Depth 60) $resumedPath
            $resumed = Get-Content $resumedPath -Raw | ConvertFrom-Json -AsHashtable -Depth 60
            (Get-BackportJournalMarker $resumed) | Should -Be (Get-BackportJournalMarker $preparedState)
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Path -like '*/git/ref/*' }
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
        }

        It 'does not replay a frozen singleton conflict until explicit manual retry on the current release' -ForEach @(
            @{ readable = $false }, @{ readable = $true }
        ) {
            $null = Invoke-BackportGit $directory @('checkout', '--detach', $base)
            [IO.File]::WriteAllText((Join-Path $directory 'src/Foo.al'), "incompatible release`n")
            $null = Invoke-BackportGit $directory @('commit', '--quiet', '-am', 'old release')
            $oldRelease = (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim()
            $cohort = New-BatchFixture -Outcomes @('conflict')
            $cohort.request.mode = 'single'; $cohort.request.key = 'single-42'; $cohort.request.manual = $true
            if ($readable) { $cohort.branch = 'bc-extrequest-backport/backport_42-2' }
            $cohort.request.sources[0].sha = $source
            $cohort.target_sha = $oldRelease; $cohort.head = $oldRelease
            $cohort.tree = (Invoke-BackportGit $directory @('rev-parse', 'HEAD^{tree}')).text.Trim()
            $cohort.members[0].source_sha = $source; $cohort.members[0].manual = $true
            $cohort.members[0].main_team = 'Team: Finance'
            $cohort.members[0].result = Invoke-BackportApply $directory $source $oldRelease
            $cohort.members[0].result.outcome | Should -Be 'conflict'
            $script:frozen = @{
                schema = 3; repository = 'microsoft/BCApps'; cohort = $cohort
                release = @{ target = 'releases/29.x'; version = '29.1'; milestone_number = 1; milestone_title = 'Version 29.1' }
            }
            $script:currentRelease = $base
            $script:retryDirectory = $directory
            $script:actualGit = (Get-Command Invoke-BackportGit).ScriptBlock
            Mock Get-BackportBatchRecords {
                @{ shared = $true; manifest = $script:frozen.cohort; journal_state = $script:frozen
                    issue = @{ state = 'open' }; journal = @{ id = 1000; body = Get-BackportJournalMarker $script:frozen } }
            }
            Mock Get-BackportBatchPull { $null }
            Mock Assert-BackportRelease {}
            Mock Get-BackportSource {
                @{ number = 42; title = 'Source'; merge_commit_sha = $script:frozen.cohort.members[0].source_sha
                    merged_at = $script:frozen.cohort.request.sources[0].merged_at
                    labels = @(@{ name = 'Team: Finance' }) }
            }
            Mock Get-BackportSourceIssues { $script:frozen.cohort.members[0].issues }
            Mock Initialize-BackportBatchGit { Move-Item -LiteralPath $script:retryDirectory -Destination $Directory }
            Mock Invoke-BackportApi {
                if ($Method -and $Method -ne 'GET') { throw 'Preparation attempted a write.' }
                if ($Path -like '*/git/ref/*') { return @{ object = @{ sha = $script:currentRelease } } }
                if ($Path -like '*/compare/*') { return @{ status = 'ahead' } }
                throw "Unexpected API read: $Path"
            }
            Mock Invoke-BackportGit {
                if ($Arguments[0] -eq 'fetch' -or $Arguments[0] -eq 'ls-remote') { return @{ text = ''; exit_code = 0 } }
                & $script:actualGit -Directory $Directory -Arguments $Arguments -InputText $InputText `
                    -AllowFailure:$AllowFailure -CommitDate $CommitDate
            }
            $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $path = Join-Path $root 'state.json'
            $row = @{} + $frozen.cohort.request
            $row.manifest = $frozen.cohort
            New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $row -Depth 80) $path
            Should -Invoke Invoke-BackportGit -Times 0
            $row.retry_conflict = $true
            New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $row -Depth 80) $path
            $prepared = Get-Content $path -Raw | ConvertFrom-Json -AsHashtable -Depth 80
            $prepared.supersedes | Should -Be 1000
            $prepared.cohort.target_sha | Should -Be $base
            $prepared.cohort.members[0].result.outcome | Should -Be 'applied'
            (Get-BackportCohortBranch $prepared.cohort) | Should -BeExactly (Get-BackportCohortBranch $cohort)
            Assert-BackportPreparedBatch $prepared.cohort (Join-Path $root 'git')
        }

        It 'isolates conflicts, excludes dependent paths and retains a disjoint clean source' {
            [IO.File]::WriteAllText((Join-Path $directory 'src/Other.al'), "clean`n")
            $null = Invoke-BackportGit $directory @('add', 'src/Other.al')
            $null = Invoke-BackportGit $directory @('commit', '--quiet', '-m', 'disjoint')
            $clean = (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim()
            [IO.File]::WriteAllText((Join-Path $directory 'src/Foo.al'), "source`ndependent`n")
            $null = Invoke-BackportGit $directory @('commit', '--quiet', '-am', 'dependent')
            $dependent = (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim()
            $null = Invoke-BackportGit $directory @('checkout', '--detach', $base)
            [IO.File]::WriteAllText((Join-Path $directory 'src/Foo.al'), "release`n")
            $null = Invoke-BackportGit $directory @('commit', '--quiet', '-am', 'release')
            $release = (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim()
            $failed = Invoke-BackportApply $directory $source $release
            $failed.outcome | Should -Be 'conflict'
            $good = Invoke-BackportApply $directory $clean $release -BlockedPaths $failed.paths
            $good.outcome | Should -Be 'applied'
            $blocked = Invoke-BackportApply $directory $dependent $good.commit -BlockedPaths $failed.paths
            $blocked.outcome | Should -Be 'conflict'
            (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim() | Should -Be $good.commit
            (Invoke-BackportGit $directory @('show', 'HEAD:src/Foo.al')).text | Should -Be "release`n"
            (Invoke-BackportGit $directory @('show', 'HEAD:src/Other.al')).text | Should -Be "clean`n"
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
}
