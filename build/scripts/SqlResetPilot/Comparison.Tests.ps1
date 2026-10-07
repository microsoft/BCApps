BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Comparison.psm1') -Force
}

Describe 'Exact balanced 300-cell comparison manifest' {
    BeforeAll {
        $script:cells = @(Get-SqlComparisonCell)
    }
    It 'contains exactly 300 unique identities and all 50 indices per arm and country' {
        $script:cells.Count | Should -Be 300
        @($script:cells | ForEach-Object { "$($_.experiment)/$($_.country)/$($_.trial)" } |
            Sort-Object -Unique).Count | Should -Be 300
        foreach ($arm in @('control', 'warmup', 'retry')) {
            foreach ($country in @('W1', 'DE')) {
                $indices = @($script:cells | Where-Object { $_.experiment -eq $arm -and $_.country -eq $country } |
                    Select-Object -ExpandProperty trial | Sort-Object)
                ($indices -join ',') | Should -Be ((1..50) -join ',')
            }
        }
    }
    It 'splits into ten matrix-safe balanced batches and six-cell index blocks' {
        foreach ($batch in 0..9) {
            $selected = @($script:cells | Select-Object -Skip ($batch * 30) -First 30)
            $selected.Count | Should -Be 30
            foreach ($group in @($selected | Group-Object experiment, country)) {
                $group.Count | Should -Be 5
            }
        }
        foreach ($block in 0..49) {
            $selected = @($script:cells | Select-Object -Skip ($block * 6) -First 6)
            @($selected.trial | Sort-Object -Unique).Count | Should -Be 1
            @($selected | Group-Object experiment, country).Count | Should -Be 6
        }
    }
    It 'generates exactly one explicit replacement and no other cells' {
        $cells = @(Get-SqlComparisonCell -Mode replacement -Arm retry -Country DE -Trial 50)
        $cells.Count | Should -Be 1
        $cells[0].experiment | Should -Be 'retry'
        $cells[0].country | Should -Be 'DE'
        $cells[0].trial | Should -Be 50
    }
    It 'rejects invalid replacement identities and mixed original selection' {
        foreach ($trial in @('0', '51', '01', '-1', '1,2', '')) {
            { Get-SqlComparisonCell -Mode replacement -Arm retry -Country DE -Trial $trial } | Should -Throw
        }
        { Get-SqlComparisonCell -Mode replacement -Arm A -Country DE -Trial 1 } | Should -Throw
        { Get-SqlComparisonCell -Mode replacement -Arm retry -Country US -Trial 1 } | Should -Throw
        { Get-SqlComparisonCell -Mode originals -Arm control } | Should -Throw
    }
    It 'preserves original probe implementation and compiled source byte-for-byte' {
        $root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
        $diff = git -C $root diff fcc1776c6b165199dd66e4227675b1cc31da7a8f -- `
            build/scripts/SqlResetPilot/Lifecycle.psm1 build/scripts/SqlResetPilot/CompaniesProbe.Tests.ps1 `
            build/scripts/RunTestsInBcContainer.ps1 .github/AL-Go-Settings.json build/projects src
        $LASTEXITCODE | Should -Be 0
        $diff | Should -BeNullOrEmpty
    }
    It 'keeps exact immutable artifact pairs consistent with runtime preparation' {
        $prepare = Get-Content (Join-Path $PSScriptRoot 'Prepare.ps1') -Raw
        $pins = @(Get-SqlComparisonArtifact)
        $pins.Count | Should -Be 4
        foreach ($pin in $pins) {
            $prepare | Should -Match ([regex]::Escape($pin.id))
            $prepare | Should -Match ([regex]::Escape($pin.digest))
        }
    }
}

Describe 'Only authoritative original communication failures qualify for replacement' {
    BeforeEach {
        $script:sha = '1111111111111111111111111111111111111111'
        $script:run = [PSCustomObject]@{
            id = 100; head_sha = $script:sha; head_branch = 'features/646383-sql-api-300-trial-comparison'
            event = 'workflow_dispatch'; run_attempt = 1; path = '.github/workflows/CICD.yaml'
            display_title = 'SQL API 300 comparison - originals'
        }

        $script:job = [PSCustomObject]@{
            id = 200; run_id = 100; conclusion = 'failure'; status = 'completed'
            name = 'Batch01 / Trial warmup/DE/3'
        }
        $script:annotations = @([PSCustomObject]@{
            annotation_level = 'failure'
            message = 'The self-hosted runner: isolated-runner lost communication with the server.'
        })
        $script:cell = [PSCustomObject]@{ experiment = 'warmup'; country = 'DE'; trial = 3 }
    }
    It 'preserves the exact original run, job, revision and annotation' {
        $record = Assert-SqlComparisonReplacement $script:run $script:job $script:annotations $script:cell $script:sha
        $record.runId | Should -Be '100'
        $record.jobId | Should -Be '200'
        $record.trialIdentity | Should -Be 'warmup/DE/3'
        $record.workflowSha | Should -Be $script:sha
        $record.annotation.Count | Should -Be 1
    }
    It 'rejects SQL or ordinary test failures even if caller requests replacement' {
        $script:annotations[0].message = 'GET request failed: 500. AcquireSqlConnectionFromPool NullReferenceException'
        { Assert-SqlComparisonReplacement $script:run $script:job $script:annotations $script:cell $script:sha } | Should -Throw
        { Assert-SqlComparisonReplacement $script:run $script:job @() $script:cell $script:sha } | Should -Throw
    }
    It 'rejects original run drift: <Property>' -ForEach @(
        @{ Property = 'head_sha'; Value = '2222222222222222222222222222222222222222' }
        @{ Property = 'head_branch'; Value = 'features/646383-sql-api-de3-communication-replay' }
        @{ Property = 'event'; Value = 'pull_request' }
        @{ Property = 'run_attempt'; Value = 2 }
        @{ Property = 'path'; Value = '.github/workflows/Other.yaml' }
        @{ Property = 'display_title'; Value = 'SQL API 300 comparison - replacement' }
    ) {
        $script:run.$Property = $Value
        { Assert-SqlComparisonReplacement $script:run $script:job $script:annotations $script:cell $script:sha } | Should -Throw
    }
    It 'rejects wrong, skipped, cancelled or successful jobs: <Property>/<Value>' -ForEach @(
        @{ Property = 'run_id'; Value = 101 }
        @{ Property = 'name'; Value = 'Batch01 / Trial retry/DE/3' }
        @{ Property = 'conclusion'; Value = 'success' }
        @{ Property = 'conclusion'; Value = 'cancelled' }
        @{ Property = 'conclusion'; Value = 'skipped' }
        @{ Property = 'status'; Value = 'in_progress' }
    ) {
        $script:job.$Property = $Value
        { Assert-SqlComparisonReplacement $script:run $script:job $script:annotations $script:cell $script:sha } | Should -Throw
    }
}
