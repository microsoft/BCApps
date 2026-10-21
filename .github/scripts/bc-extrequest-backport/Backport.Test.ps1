using module .\Backport.psm1

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
            $row = @(Find-ExtRequestBackportBatches microsoft/BCApps -SourcePr 42 -BatchId 123)[0]
            $path = Join-Path $TestDrive 'single.json'
            Mock New-ExtRequestBackport {
                @{ schema = 1; source_sha = 'a' * 40 } | ConvertTo-Json | Set-Content $StatePath
            }
            New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $row -Depth 60) $path
            Should -Invoke New-ExtRequestBackport -Times 1 -ParameterFilter {
                $Manual -and $SourcePr -eq 42 -and $Target -eq 'releases/29.x' -and
                $ReferenceTime -eq [DateTimeOffset]$row.reference_time
            }
            Mock Publish-ExtRequestBackport {}
            Publish-ExtRequestBackportBatch $path 'test-app[bot]'
            Should -Invoke Publish-ExtRequestBackport -Times 1
        }

        It 'routes the old per-PR prepare API to its immutable existing batch' {
            Mock Get-BackportBatchRecords { @{ issue = @{ state = 'open' }; manifest = $script:fixture } }
            Mock New-ExtRequestBackportBatch {}
            New-ExtRequestBackport microsoft/BCApps 42 releases/99.x $true (Join-Path $TestDrive 'legacy.json')
            Should -Invoke New-ExtRequestBackportBatch -Times 1 -ParameterFilter {
                ($RequestJson | ConvertFrom-Json).source_prs.Count -eq 3 -and
                ($RequestJson | ConvertFrom-Json).target -eq 'releases/29.x'
            }
        }

        It 'manual batch member returns exactly its frozen batch including already processed members' {
            Mock Get-BackportBatchRecords { @{ issue = @{ state = 'open' }; manifest = $script:fixture } }
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
            Mock Get-BackportBatchRecords { @{ issue = @{ state = 'open' }; manifest = $script:fixture } }
            Mock Invoke-BackportApi { @() }
            $rows = @(Find-ExtRequestBackportBatches microsoft/BCApps -BatchId 999)
            $rows.Count | Should -Be 1
            $rows[0].key | Should -Be $fixture.request.key
        }

        It 'does not poll a completed batch or replay its recorded conflict while its Task stays open' {
            Mock Get-BackportBatchRecords { @{ issue = @{ state = 'open' }; manifest = $script:fixture } }
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

Describe 'Batch publication and duplicate prevention' {
    InModuleScope Backport {
        BeforeEach {
            $script:fixture = New-BatchFixture
            $script:statePath = Join-Path $TestDrive 'batch-state.json'
            $script:batchTracking = $null
            $script:batchPull = $null
            $script:singleTracking = @{}
            $script:sourceData = @{}
            foreach ($member in $fixture.members) {
                $script:sourceData[[string]$member.source_pr] = @{
                    number = $member.source_pr; title = $member.source_title; merge_commit_sha = $member.source_sha
                    merged_at = $fixture.request.sources[$member.source_pr - 42].merged_at
                    base = @{ ref = 'main'; repo = @{ full_name = 'microsoft/BCApps' } }
                    labels = @($member.labels | Where-Object { $_.name -ne 'ext-backporting' })
                }
            }
            $fixture | ConvertTo-Json -Depth 60 | Set-Content $statePath
            Mock Get-BackportBatchRecords {
                if ($null -ne $script:batchTracking) { @{ issue = $script:batchTracking; manifest = $script:fixture } }
            }
            Mock Get-BackportBatchPull { $script:batchPull }
            Mock Get-BackportTracking { $script:singleTracking[[string]$SourcePr] }
            Mock Get-BackportPull { $null }
            Mock Get-BackportSource { $script:sourceData[[string]$Number] }
            Mock Get-BackportSourceIssues { @($script:fixture.members | Where-Object source_pr -eq $Number)[0].issues }
            Mock Ensure-BackportLabels {}
            $script:realProcessed = (Get-Command Set-BackportProcessed).ScriptBlock
            Mock Set-BackportProcessed {
                & $script:realProcessed -Repository $Repository -SourcePr $SourcePr
                $script:sourceData[[string]$SourcePr].labels += @{ name = 'ext-backport-processed' }
            }
            Mock Assert-BackportPreparedBatch {}
            Mock Invoke-BackportGit {
                if ($Arguments[0] -eq 'ls-remote') { return @{ text = "$($script:fixture.head)`trefs/heads/bc-extrequest-backport/$($script:fixture.request.key)" } }
                throw "Unexpected Git write: $($Arguments -join ' ')"
            }
            Mock Get-BackportApiPages {
                if ($null -ne $script:batchTracking) { $script:batchTracking }
                foreach ($item in $script:singleTracking.Values) { $item }
            }
            Mock Invoke-BackportApi {
                if ([string]::IsNullOrEmpty($Method)) { $Method = 'GET' }
                if ($Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues') {
                    $object = @{
                        number = 100; title = $Body.title; body = $Body.body; state = 'open'
                        user = @{ login = 'test-app[bot]' }; labels = @()
                        html_url = 'https://github.com/microsoft/BCApps/issues/100'
                    }
                    if ($Body.body.Contains('bc-extrequest-backport:v2')) { $script:batchTracking = $object }
                    else {
                        $marker = Read-BackportMarker $Body.body
                        $object.number = 200 + $marker.source_pr
                        $object.html_url = "https://github.com/microsoft/BCApps/issues/$($object.number)"
                        $script:singleTracking[[string]$marker.source_pr] = $object
                    }
                    return $object
                }
                if ($Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls') {
                    $script:batchPull = @{
                        number = 101; body = $Body.body; draft = $Body.draft; state = 'open'; merged_at = $null
                        user = @{ login = 'test-app[bot]' }; html_url = 'https://github.com/microsoft/BCApps/pull/101'
                        head = @{ sha = $script:fixture.head; ref = $Body.head; repo = @{ full_name = 'microsoft/BCApps' } }
                        base = @{ ref = $Body.base; repo = @{ full_name = 'microsoft/BCApps' } }
                    }
                    return $script:batchPull
                }
                if ($Method -eq 'GET' -and $Path -eq 'repos/microsoft/BCApps/pulls/101') { return $script:batchPull }
                if ($Method -eq 'GET' -and $Path -eq 'repos/microsoft/BCApps/issues/100') { return $script:batchTracking }
                foreach ($object in $script:singleTracking.Values) {
                    if ($Method -eq 'GET' -and $Path -eq "repos/microsoft/BCApps/issues/$($object.number)") { return $object }
                }
                if ($Method -eq 'POST' -and $Path -match '/issues/\d+/labels$') { return }
                if ($Method -eq 'PATCH' -and $Path -match '/issues/\d+$') {
                    if ($Path -eq 'repos/microsoft/BCApps/issues/100') {
                        if ($Body.ContainsKey('body')) { $script:batchTracking.body = $Body.body }
                        if ($Body.ContainsKey('state')) { $script:batchTracking.state = $Body.state }
                    }
                    return
                }
                throw "Unexpected remote operation: $Method $Path"
            }
        }

        It 'publishes one team Task and draft PR plus an independent conflict Task with deduplicated links and label union' {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                $Path -eq 'repos/microsoft/BCApps/issues' -and $Method -eq 'POST' -and
                $Body.body.Contains('bc-extrequest-backport:v2') -and $Body.type -eq 'Task' -and
                $Body.labels -contains 'issue-0' -and $Body.labels -contains 'issue-1' -and
                $Body.labels -notcontains 'issue-2'
            }
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                $Path -eq 'repos/microsoft/BCApps/pulls' -and $Method -eq 'POST' -and $Body.draft -and
                $Body.body.Contains('Fixes #100') -and $Body.base -eq 'releases/29.x' -and
                $Body.title -ceq $script:batchTracking.title
            }
            $body = $script:batchPull.body
            $body | Should -Match 'pull/42'
            $body | Should -Match 'pull/43'
            $identity = Read-BackportBatchMarker $body
            $identity.members[0].source_sha | Should -Be ('a' * 40)
            $identity.members[1].source_sha | Should -Be ('b' * 40)
            [regex]::Matches($body, 'https://github.com/microsoft/BCApps/issues/10(?=\s|$)').Count | Should -Be 1
            $body | Should -Match '(?m)^Fixes #100$'
            $body | Should -Not -Match '(?m)^Fixes #10$'
            $script:batchTracking.body.TrimEnd() | Should -Match '\*Auto-generated content\*$'
            Should -Invoke Set-BackportProcessed -Times 1 -ParameterFilter { $SourcePr -eq 42 }
            Should -Invoke Set-BackportProcessed -Times 1 -ParameterFilter { $SourcePr -eq 43 }
            Should -Invoke Set-BackportProcessed -Times 0 -ParameterFilter { $SourcePr -eq 44 }
            Should -Invoke Invoke-BackportApi -Times 2 -ParameterFilter {
                $Method -eq 'POST' -and $Path -match '^repos/microsoft/BCApps/issues/(42|43)/labels$' -and
                $Body.labels.Count -eq 1 -and $Body.labels[0] -ceq 'ext-backport-processed'
            }
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                $Method -ne 'GET' -and $Path -match '^repos/microsoft/BCApps/issues/(10|44)(?:/|$)'
            }
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter {
                $Arguments[0] -in @('cherry-pick', 'checkout', 'fetch')
            }
        }

        It 'reports actual team, source proofs, original issue links and each prepared outcome' {
            Mock Write-BackportSummary {}
            Write-BackportBatchSummary $fixture prepared
            Should -Invoke Write-BackportSummary -Times 1 -ParameterFilter {
                $Text.Contains('pull/42') -and $Text.Contains('Team: Finance') -and
                $Text.Contains('issues/10') -and $Text.Contains('**applied**') -and $Text.Contains('a' * 40)
            }
            Should -Invoke Write-BackportSummary -Times 1 -ParameterFilter {
                $Text.Contains('pull/44') -and $Text.Contains('issues/10') -and $Text.Contains('**conflict**')
            }
        }

        It 'repairs processed flags for any existing batch PR without Task lifecycle changes' -ForEach @(
            @{ pullState = 'open'; merged = $null }, @{ pullState = 'closed'; merged = $null },
            @{ pullState = 'closed'; merged = '2026-10-20T09:00:00Z' }
        ) {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $script:batchPull.state = $pullState
            $script:batchPull.merged_at = $merged
            $script:batchTracking.state = 'closed'
            $script:sourceData['42'].labels = @(@{ name = 'event-request' })
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Should -Invoke Set-BackportProcessed -Times 2 -ParameterFilter { $SourcePr -eq 42 }
            Should -Invoke Set-BackportProcessed -Times 2 -ParameterFilter { $SourcePr -eq 43 }
            Should -Invoke Set-BackportProcessed -Times 0 -ParameterFilter { $SourcePr -eq 44 }
            Should -Invoke Assert-BackportPreparedBatch -Times 1
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                $Method -eq 'PATCH' -and $Body.ContainsKey('state')
            }
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' }
        }

        It 'reconciles an existing batch without duplicating issue, PR or conflict outcomes' {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Should -Invoke Invoke-BackportApi -Times 2 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues' }
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' }
        }

        It 'prepares an existing batch PR resume without local Git or lifecycle polling' {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            $script:batchPull.state = 'closed'
            $script:batchPull.merged_at = '2026-10-20T09:00:00Z'
            $row = @{} + $fixture.request
            $row.manifest = $fixture
            $resumedPath = Join-Path $TestDrive 'resumed-batch.json'
            Mock Initialize-BackportBatchGit { throw 'Existing PR must not prepare Git again.' }
            New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $row -Depth 60) $resumedPath
            $resumed = Get-Content $resumedPath -Raw | ConvertFrom-Json -AsHashtable -Depth 60
            (Get-BackportBatchMarker $resumed) | Should -Be (Get-BackportBatchMarker $fixture)
            Publish-ExtRequestBackportBatch $resumedPath 'test-app[bot]'
            Should -Invoke Initialize-BackportBatchGit -Times 0
            Should -Invoke Assert-BackportPreparedBatch -Times 1
            Should -Invoke Invoke-BackportGit -Times 1
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                $Method -eq 'PATCH' -and $Body.ContainsKey('state')
            }
        }

        It 'attempts an uncertain team Task POST only once within an invocation and never labels sources' {
            Mock Invoke-BackportApi { throw 'Uncertain POST' } -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues'
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Uncertain POST*'
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues' }
            Should -Invoke Set-BackportProcessed -Times 0
        }

        It 'recovers a tracking Task observed by the final REST membership recheck without another Task POST' {
            $script:lookupCount = 0
            $script:observed = @{
                number = 100; body = Get-BackportBatchMarker $fixture; state = 'open'; labels = @()
                title = 'Recovered backport Task title'
                user = @{ login = 'test-app[bot]' }; html_url = 'https://github.com/microsoft/BCApps/issues/100'
            }
            Mock Get-BackportBatchRecords {
                $script:lookupCount++
                if ($script:lookupCount -ge 2) {
                    $script:batchTracking = $script:observed
                    @{ issue = $script:observed; manifest = $script:fixture }
                }
            }
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues' -and
                $Body.body.Contains('bc-extrequest-backport:v2')
            }
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' -and
                $Body.title -ceq $script:observed.title
            }
        }

        It 'recovers a confirmed team issue after an interrupted response without repeating its POST' {
            Mock Invoke-BackportApi {
                $script:batchTracking = @{
                    number = 100; body = $Body.body; state = 'open'; labels = @()
                    title = $Body.title
                    user = @{ login = 'test-app[bot]' }; html_url = 'https://github.com/microsoft/BCApps/issues/100'
                }
                throw 'Lost response'
            } -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues' -and $Body.body.Contains('bc-extrequest-backport:v2') }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Lost response*'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues' -and $Body.body.Contains('bc-extrequest-backport:v2')
            }
            $script:batchPull | Should -Not -BeNullOrEmpty
        }

        It 'does not blindly repeat an unconfirmed batch PR POST' {
            Mock Invoke-BackportApi { throw 'Uncertain PR POST' } -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls'
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Uncertain PR POST*'
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*unconfirmed*'
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' }
            (Read-BackportPublicationIntent $script:batchTracking.body) | Should -Be $fixture.head
            Should -Invoke Set-BackportProcessed -Times 0
        }

        It 'requires durable intent readback before attempting a batch PR POST' {
            Mock Invoke-BackportApi {} -ParameterFilter {
                $Method -eq 'PATCH' -and $Body.ContainsKey('body') -and
                $Body.body.Contains('bc-extrequest-backport:publication-intent:')
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*intent was not confirmed*'
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls'
            }
            Should -Invoke Set-BackportProcessed -Times 0
        }

        It 'retains an accepted intent PATCH with a lost response and never guesses whether to POST a PR' {
            Mock Invoke-BackportApi {
                $script:batchTracking.body = $Body.body
                throw 'Lost intent response'
            } -ParameterFilter {
                $Method -eq 'PATCH' -and $Body.ContainsKey('body') -and
                $Body.body.Contains('bc-extrequest-backport:publication-intent:')
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Lost intent response*'
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*unconfirmed*'
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls'
            }
            Should -Invoke Set-BackportProcessed -Times 0
        }

        It 'reuses an accepted batch PR when its response was lost' {
            Mock Invoke-BackportApi {
                $script:batchPull = @{
                    number = 101; body = $Body.body; draft = $true; state = 'open'; merged_at = $null
                    user = @{ login = 'test-app[bot]' }; html_url = 'https://github.com/microsoft/BCApps/pull/101'
                    head = @{ sha = $script:fixture.head; ref = $Body.head; repo = @{ full_name = 'microsoft/BCApps' } }
                    base = @{ ref = $Body.base; repo = @{ full_name = 'microsoft/BCApps' } }
                }
                throw 'Lost PR response'
            } -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Lost PR response*'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' }
            Should -Invoke Set-BackportProcessed -Times 1 -ParameterFilter { $SourcePr -eq 42 }
        }

        It 'publishes the clean batch even when independent conflict issue publication fails' {
            Mock Invoke-BackportApi { throw 'Independent POST failed' } -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues' -and
                $Body.body.Contains('bc-extrequest-backport:v1')
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Independent POST failed*'
            $script:batchPull | Should -Not -BeNullOrEmpty
            Should -Invoke Set-BackportProcessed -Times 1 -ParameterFilter { $SourcePr -eq 42 }
            Should -Invoke Set-BackportProcessed -Times 0 -ParameterFilter { $SourcePr -eq 44 }
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues' -and
                $Body.body.Contains('bc-extrequest-backport:v1')
            }
        }

        It 'never publishes a branch or PR when every source is conflict or already present' {
            $script:fixture = New-BatchFixture -Outcomes @('conflict', 'already-present')
            foreach ($proof in $fixture.request.sources) { $script:sourceData[[string]$proof.number].merged_at = $proof.merged_at }
            $fixture | ConvertTo-Json -Depth 60 | Set-Content $statePath
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                $Method -eq 'POST' -and ($Path -eq 'repos/microsoft/BCApps/pulls' -or
                ($Path -eq 'repos/microsoft/BCApps/issues' -and $Body.body.Contains('bc-extrequest-backport:v2')))
            }
            Should -Invoke Invoke-BackportGit -Times 0
            Should -Invoke Set-BackportProcessed -Times 0
        }

        It 'fails closed on modified prepared provenance before any remote write' {
            Mock Assert-BackportPreparedBatch { throw 'Provenance changed' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Provenance changed*'
            Should -Invoke Invoke-BackportApi -Times 0
        }

        It 'refuses changed source proofs before writes' {
            $script:sourceData['43'].merge_commit_sha = '0' * 40
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*SHA changed*'
            Should -Invoke Invoke-BackportApi -Times 0
        }

        It 'refuses a different per-source pinned release instead of silently moving a resumed request' {
            $script:sourceData['43'].labels += @{ name = 'ext-backport-pending:28.x' }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*different pinned target*'
            Should -Invoke Invoke-BackportApi -Times 0
        }

        It 'reads legacy source publication intents fail-closed without writing or clearing legacy labels' {
            $script:sourceData['42'].labels += @{ name = 'ext-backport-publishing:29.x' }
            $script:batchTracking = @{
                number = 100; body = Get-BackportBatchMarker $fixture; state = 'open'
                user = @{ login = 'test-app[bot]' }
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Legacy batch PR publication is unconfirmed*'
            Should -Invoke Invoke-BackportApi -Times 0
            Should -Invoke Set-BackportProcessed -Times 0
        }

        It 'refuses a batch object by another actor even if its manifest is intact' {
            $script:batchTracking = @{
                number = 100; body = Get-BackportBatchMarker $fixture; state = 'open'; user = @{ login = 'human' }
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*author*'
            Should -Invoke Invoke-BackportApi -Times 0
        }

        It 'does not mark sources for an existing PR with changed author or SHA' -ForEach @(
            @{ kind = 'author' }, @{ kind = 'sha' }
        ) {
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            if ($kind -eq 'author') { $script:batchPull.user.login = 'human' }
            else { $script:batchPull.head.sha = '0' * 40 }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw
            Should -Invoke Set-BackportProcessed -Times 2
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls'
            }
        }

        It 'does not overwrite a batch branch with human changes' {
            Mock Invoke-BackportGit { @{ text = "$('e' * 40)`trefs/heads/changed" } }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*never overwrite*'
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' }
        }

        It 'reuses a no-op Task after initial closure failure without marking its source or duplicating the Task' {
            $script:fixture = New-BatchFixture -Outcomes @('already-present')
            $script:sourceData['42'].merged_at = $fixture.request.sources[0].merged_at
            $fixture | ConvertTo-Json -Depth 60 | Set-Content $statePath
            Mock Invoke-BackportApi { throw 'Close failed' } -ParameterFilter {
                $Method -eq 'PATCH' -and $Body.ContainsKey('state') -and $Body.state -eq 'closed'
            }
            { Publish-ExtRequestBackportBatch $statePath 'test-app[bot]' } | Should -Throw '*Close failed*'
            Should -Invoke Set-BackportProcessed -Times 0
            Mock Invoke-BackportApi { $script:singleTracking['42'].state = 'closed' } -ParameterFilter {
                $Method -eq 'PATCH' -and $Body.ContainsKey('state') -and $Body.state -eq 'closed'
            }
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Publish-ExtRequestBackportBatch $statePath 'test-app[bot]'
            Should -Invoke Set-BackportProcessed -Times 0
            Should -Invoke Invoke-BackportApi -Times 2 -ParameterFilter {
                $Method -eq 'PATCH' -and $Body.ContainsKey('state') -and $Body.state -eq 'closed'
            }
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues'
            }
        }
    }
}

Describe 'Backport descriptions and titles' {
    InModuleScope Backport {
        BeforeEach {
            $script:presentationState = @{
                schema = 1; repository = 'microsoft/BCApps'; source_pr = 42; target = 'releases/29.x'
                source_sha = 'a' * 40; source_title = 'Expose an event'; result = @{ outcome = 'applied' }
                issues = @(@{ url = 'https://github.com/microsoft/BCApps/issues/10' },
                    @{ url = 'https://github.com/microsoft/BCApps/issues/11' },
                    @{ url = 'https://github.com/microsoft/BCApps/issues/10' })
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

        It 'renders the same issue content without Fixes or Important and ends with the italic generation note' {
            $body = Get-BackportBody $presentationState
            $visible = [regex]::Replace($body, '(?s)<!--.*?-->\s*', '').Trim()
            $visible | Should -BeExactly (@($expectedCore, '', '*Auto-generated content*') -join "`n")
            $visible | Should -Not -Match '(?i)\bfixes\s|\[!IMPORTANT\]'
            $body | Should -Match '<!-- Preparation result: \*\*applied\*\*\. -->'
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

        It 'repairs labels and links for an existing PR instead of creating another issue or PR' {
            $marker = Get-BackportMarker 42 'releases/29.x' ('a' * 40)
            $state = @{
                repository = 'microsoft/BCApps'; source_pr = 42; target = 'releases/29.x'; source_sha = 'a' * 40
                labels = @(@{ name = 'event-request' }, @{ name = 'ext-backporting' })
            }
            $tracking = @{ number = 100; body = $marker; user = @{ login = 'test-app[bot]' }; state = 'open'; html_url = 'issue-url' }
            $pull = @{
                number = 101; body = $marker; user = @{ login = 'test-app[bot]' }; merged_at = $null
                head = @{ sha = 'b' * 40; ref = 'bc-extrequest-backport/pr-42/29.x'; repo = @{ full_name = 'microsoft/BCApps' } }
                base = @{ ref = 'releases/29.x'; repo = @{ full_name = 'microsoft/BCApps' } }
                state = 'open'; html_url = 'pr-url'
            }
            Mock Ensure-BackportLabels {}
            Mock Set-BackportProcessed {}
            Mock Invoke-BackportApi {}
            Complete-BackportPull $state $tracking $pull 'test-app[bot]'
            Should -Invoke Invoke-BackportApi -Times 2 -ParameterFilter { $Path -like '*/labels' -and $Method -eq 'POST' }
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Path -match '/(issues|pulls)$' -and $Method -eq 'POST' }
            Should -Invoke Set-BackportProcessed -Times 1 -ParameterFilter { $SourcePr -eq 42 }
        }

        It 'marks the original PR for a validated merged PR without closing its tracking Task' {
            $marker = Get-BackportMarker 42 'releases/29.x' ('a' * 40)
            $state = @{ repository = 'microsoft/BCApps'; source_pr = 42; target = 'releases/29.x'; source_sha = 'a' * 40 }
            $tracking = @{
                number = 100; body = "$marker`nBackport PR: pr-url"; user = @{ login = 'test-app[bot]' }
                state = 'open'; html_url = 'issue-url'; labels = @(@{ name = 'ext-backporting' })
            }
            $pull = @{
                number = 101; body = $marker; user = @{ login = 'test-app[bot]' }; merged_at = '2026-10-19T00:00:00Z'
                head = @{ sha = 'b' * 40; ref = 'bc-extrequest-backport/pr-42/29.x'; repo = @{ full_name = 'microsoft/BCApps' } }
                base = @{ ref = 'releases/29.x'; repo = @{ full_name = 'microsoft/BCApps' } }
                state = 'closed'; html_url = 'pr-url'
            }
            Mock Ensure-BackportLabels {}
            Mock Set-BackportProcessed {}
            Mock Invoke-BackportApi {}
            Complete-BackportPull $state $tracking $pull 'test-app[bot]'
            Should -Invoke Set-BackportProcessed -Times 1 -ParameterFilter { $SourcePr -eq 42 }
            Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                $Method -eq 'PATCH' -and $Body.ContainsKey('state')
            }
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

        It 'prepares and validates a real cumulative batch and resumes its exact immutable release and membership' {
            [IO.File]::WriteAllText((Join-Path $directory 'src/Foo.al'), "source`nsecond`n")
            $null = Invoke-BackportGit $directory @('commit', '--quiet', '-am', 'second')
            $second = (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim()
            $script:fixture = New-BatchFixture -Outcomes @('applied', 'applied')
            $request = $fixture.request
            $request.sources[0].sha = $source
            $request.sources[1].sha = $second
            [void]$request.Remove('key')
            $request.key = 'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $request)).Substring(0, 32)
            $script:request = $request
            $script:release = $base
            $script:durable = $null
            $script:remoteHead = ''
            $script:actualGit = (Get-Command Invoke-BackportGit).ScriptBlock
            Mock Get-BackportBatchRecords {
                if ($null -ne $script:durable) {
                    @{ issue = @{ state = 'open'; body = Get-BackportBatchMarker $script:durable }; manifest = $script:durable }
                }
            }
            Mock Get-BackportBatchPull { $null }
            Mock Get-BackportTracking { $null }
            Mock Get-BackportSource {
                $proof = @($script:request.sources | Where-Object number -eq $Number)[0]
                @{
                    number = $Number; title = "Source $Number"; merge_commit_sha = $proof.sha; merged_at = $proof.merged_at
                    base = @{ ref = 'main'; repo = @{ full_name = 'microsoft/BCApps' } }
                    labels = @(@{ name = 'event-request' }, @{ name = 'Team: Finance' })
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
                if ($Arguments[0] -eq 'ls-remote') { return @{ text = $script:remoteHead; exit_code = 0 } }
                & $script:actualGit -Directory $Directory -Arguments $Arguments -InputText $InputText `
                    -AllowFailure:$AllowFailure -CommitDate $CommitDate
            }
            $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $null = New-Item -ItemType Directory $root
            $preparedDirectory = Join-Path $root 'git'
            Move-Item -LiteralPath $directory -Destination $preparedDirectory
            $statePath = Join-Path $root 'state.json'
            New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $request -Depth 60) $statePath
            $script:durable = Get-Content $statePath -Raw | ConvertFrom-Json -AsHashtable -Depth 60
            $durable.members.Count | Should -Be 2
            $durable.members[1].result.target_sha | Should -Be $durable.members[0].result.commit
            (Invoke-BackportGit $preparedDirectory @('show', "$($durable.head):src/Foo.al")).text | Should -Be "source`nsecond`n"
            Assert-BackportPreparedBatch $durable $preparedDirectory
            $tampered = $durable | ConvertTo-Json -Depth 60 | ConvertFrom-Json -AsHashtable -Depth 60
            $tampered.members[1].result.paths = @('src/Unexpected.al')
            { Assert-BackportPreparedBatch $tampered $preparedDirectory } | Should -Throw '*provenance differs*'
            $resumeRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $null = New-Item -ItemType Directory $resumeRoot
            Copy-Item -LiteralPath $preparedDirectory -Destination (Join-Path $resumeRoot 'git') -Recurse
            $script:release = '0' * 40
            $script:remoteHead = "$($durable.head)`trefs/heads/bc-extrequest-backport/$($request.key)"
            $row = @{} + $request
            $row.manifest = $durable
            $resumedPath = Join-Path $resumeRoot 'state.json'
            New-ExtRequestBackportBatch microsoft/BCApps (ConvertTo-Json $row -Depth 60) $resumedPath
            $resumed = Get-Content $resumedPath -Raw | ConvertFrom-Json -AsHashtable -Depth 60
            (Get-BackportBatchMarker $resumed) | Should -Be (Get-BackportBatchMarker $durable)
            Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Path -like '*/git/ref/*' }
            Should -Invoke Invoke-BackportGit -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
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
                Mock Get-BackportBatchRecords { @() }
                Mock Ensure-BackportLabels {}
                $script:realProcessed = (Get-Command Set-BackportProcessed).ScriptBlock
                Mock Set-BackportProcessed { & $script:realProcessed -Repository $Repository -SourcePr $SourcePr }
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
                    if ($Method -eq 'POST' -and $Path -match '/issues/(42|100|101)/labels$') { return }
                    if ($Method -eq 'PATCH' -and $Path -eq 'repos/microsoft/BCApps/issues/100') {
                        if ($Body.ContainsKey('body')) { $script:tracking.body = $Body.body }
                        if ($Body.ContainsKey('state')) { $script:tracking.state = $Body.state }
                        return
                    }
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
                    $Body.body.Contains('Fixes #100') -and
                    $Body.title -ceq $script:tracking.title
                }
                Should -Invoke Set-BackportProcessed -Times 1 -ParameterFilter { $SourcePr -eq 42 }
                (Read-BackportPublicationIntent $script:tracking.body) | Should -Be ('b' * 40)
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                    $Path -like 'repos/microsoft/BCApps/issues/10/*'
                }
            }

            It 'creates the tracking issue on a conflict but publishes no branch or PR' {
                $state.result.outcome = 'conflict'
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                Publish-ExtRequestBackport $statePath 'test-app[bot]'
                Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues' }
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' }
                Should -Invoke Invoke-BackportGit -Times 0
                Should -Invoke Set-BackportProcessed -Times 0
            }

            It 'closes an already-present tracking issue without creating an empty PR' {
                $state.result.outcome = 'already-present'
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                Publish-ExtRequestBackport $statePath 'test-app[bot]'
                Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter { $Method -eq 'PATCH' -and $Body.state -eq 'closed' }
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' }
                Should -Invoke Set-BackportProcessed -Times 0
            }

            It 'reuses recorded conflict and no-op results without Git re-preparation, source labels or duplicate Tasks' -ForEach @(
                @{ outcome = 'conflict'; manual = $false },
                @{ outcome = 'already-present'; manual = $false }, @{ outcome = 'already-present'; manual = $true }
            ) {
                $state.result.outcome = $outcome
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                Publish-ExtRequestBackport $statePath 'test-app[bot]'
                $reusedPath = Join-Path $TestDrive 'reused.json'
                New-ExtRequestBackport microsoft/BCApps 42 releases/99.x $manual $reusedPath
                $reused = Get-Content $reusedPath -Raw | ConvertFrom-Json -AsHashtable
                $reused.target | Should -Be 'releases/29.x'
                $reused.result.outcome | Should -Be $outcome
                Publish-ExtRequestBackport $reusedPath 'test-app[bot]'
                Should -Invoke Invoke-BackportGit -Times 0
                Should -Invoke Set-BackportProcessed -Times 0
                Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues'
                }
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls'
                }
            }

            It 'allows explicit manual preparation to retry an open standalone conflict' {
                $state.result.outcome = 'conflict'
                Publish-ExtRequestBackport -BotLogin 'test-app[bot]' -PreparedState $state
                Mock Invoke-BackportGit { throw 'Manual preparation attempted' } -ParameterFilter {
                    $Arguments[0] -eq 'init'
                }
                { New-ExtRequestBackport microsoft/BCApps 42 releases/99.x $true (Join-Path $TestDrive 'retry.json') } |
                    Should -Throw '*Manual preparation attempted*'
                Should -Invoke Set-BackportProcessed -Times 0
            }

            It 'publishes a clean manual conflict retry using the same Task and refreshes its stale outcome' {
                $state.result.outcome = 'conflict'
                Publish-ExtRequestBackport -BotLogin 'test-app[bot]' -PreparedState $state
                $state.result.outcome = 'applied'
                Publish-ExtRequestBackport -StatePath $statePath -BotLogin 'test-app[bot]' -PreparedState $state
                $script:tracking.body | Should -Not -Match 'Preparation result: \*\*conflict\*\*'
                $script:tracking.body | Should -Match 'Preparation result: \*\*applied\*\*'
                Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues'
                }
                Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls'
                }
                Should -Invoke Set-BackportProcessed -Times 1 -ParameterFilter { $SourcePr -eq 42 }
            }

            It 'uses only the processed payload after a confirmed standalone PR and never labels original issues' {
                Mock Set-BackportProcessed {
                    if ($null -eq $script:pull -or $script:pull.head.sha -cne $script:state.result.commit) {
                        throw 'Attempted to mark a source without a confirmed PR.'
                    }
                    & $script:realProcessed -Repository $Repository -SourcePr $SourcePr
                }
                Mock Invoke-BackportApi {} -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues/42/labels'
                }
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                Publish-ExtRequestBackport $statePath 'test-app[bot]'
                Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues/42/labels' -and
                    $Body.labels.Count -eq 1 -and $Body.labels[0] -ceq 'ext-backport-processed'
                }
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                    $Method -ne 'GET' -and $Path -match '^repos/microsoft/BCApps/issues/10(?:/|$)'
                }
            }

            It 'requires confirmed intent before PR creation and leaves source labels untouched on PR POST failure' {
                Mock Invoke-BackportApi {
                    (Read-BackportPublicationIntent $script:tracking.body) | Should -Be ('b' * 40)
                    throw 'Uncertain PR response'
                } -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls'
                }
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                { Publish-ExtRequestBackport $statePath 'test-app[bot]' } | Should -Throw '*Uncertain PR response*'
                { Publish-ExtRequestBackport $statePath 'test-app[bot]' } | Should -Throw '*unconfirmed*'
                Should -Invoke Set-BackportProcessed -Times 0
                Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls'
                }
            }

            It 'fails closed on legacy source state without a tracking record' {
                $source.labels += @{ name = 'ext-backport-pending:29.x' }
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                { Publish-ExtRequestBackport $statePath 'test-app[bot]' } | Should -Throw '*prior backport state*'
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues' }
            }

            It 'does not recreate processed work whose tracking issue is missing, even manually' {
                $source.labels += @{ name = 'ext-backport-processed' }
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                { Publish-ExtRequestBackport $statePath 'test-app[bot]' } | Should -Throw '*prior backport state*'
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues'
                }
            }

            It 'does not repeat an uncertain release-PR POST' {
                $marker = Get-BackportMarker 42 'releases/29.x' ('a' * 40)
                $script:tracking = @{
                    number = 100; body = "$marker`n<!-- bc-extrequest-backport:publication-intent:v1 sha=$('b' * 40) -->"; state = 'open'
                    user = @{ login = 'test-app[bot]' }
                }
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                { Publish-ExtRequestBackport $statePath 'test-app[bot]' } | Should -Throw '*previous PR creation is unconfirmed*'
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls' }
                Should -Invoke Set-BackportProcessed -Times 0
            }

            It 'reuses open, closed and merged standalone PRs without changing Task lifecycle' -ForEach @(
                @{ pullState = 'open'; merged = $null }, @{ pullState = 'closed'; merged = $null },
                @{ pullState = 'closed'; merged = '2026-10-20T09:00:00Z' }
            ) {
                $state | ConvertTo-Json -Depth 20 | Set-Content $statePath
                Publish-ExtRequestBackport $statePath 'test-app[bot]'
                $script:pull.state = $pullState
                $script:pull.merged_at = $merged
                $script:tracking.state = 'closed'
                Publish-ExtRequestBackport $statePath 'test-app[bot]'
                Should -Invoke Set-BackportProcessed -Times 2
                Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/issues'
                }
                Should -Invoke Invoke-BackportApi -Times 1 -ParameterFilter {
                    $Method -eq 'POST' -and $Path -eq 'repos/microsoft/BCApps/pulls'
                }
                Should -Invoke Invoke-BackportApi -Times 0 -ParameterFilter {
                    $Method -eq 'PATCH' -and $Body.ContainsKey('state')
                }
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
