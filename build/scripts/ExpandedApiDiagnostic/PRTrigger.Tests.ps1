BeforeAll {
    $script:workflowPath = Join-Path $PSScriptRoot '..\..\..\.github\workflows\PullRequestHandler.yaml'
    $script:workflow = Get-Content $workflowPath -Raw
    $script:prefix = "(github.event_name != 'pull_request' || github.event.pull_request.head.repo.full_name != 'microsoft/BCApps' || github.event.pull_request.head.ref != 'features/653393-expanded-api-helper-scope') && "
    $script:conditions = @{}
    $job = $null
    $inJobs = $false
    foreach ($line in Get-Content $workflowPath) {
        if ($line -eq 'jobs:') { $inJobs = $true; continue }
        if (-not $inJobs) { continue }
        if ($line -match '^  ([A-Za-z][A-Za-z0-9-]*):$') { $job = $Matches[1] }
        if ($line -match '^    if: (.+)$') { $conditions[$job] = $Matches[1] }
    }
    function Test-OrdinaryPRGate {
        param([string]$Condition, $Payload)
        $pattern = "^\(github\.event_name != '([^']+)' \|\| github\.event\.pull_request\.head\.repo\.full_name != '([^']+)' \|\| github\.event\.pull_request\.head\.ref != '([^']+)'\) && "
        $match = [regex]::Match($Condition, $pattern)
        if (-not $match.Success) { throw 'Unexpected workflow gate expression.' }
        # GitHub string comparisons ignore case; no glob or prefix match is used.
        $Payload.name -ine $match.Groups[1].Value -or
            $Payload.repository -ine $match.Groups[2].Value -or
            $Payload.head -ine $match.Groups[3].Value
    }
}

Describe 'Exact diagnostic PR head opts out of ordinary jobs' {
    It 'uses merge-context pull_request rather than trusted-base pull_request_target' {
        $workflow | Should -Match '(?m)^  pull_request:\r?$'
        $workflow | Should -Not -Match '(?m)^  pull_request_target:'
        $workflow | Should -Match '(?m)^  merge_group:\r?$'
        $workflow | Should -Not -Match '(?m)^    types:'
    }
    It 'guards every ordinary job, including direct build and always-like follow-up conditions' {
        ($conditions.Keys | Sort-Object) -join ',' |
            Should -Be 'Build,Build1,CodeAnalysisUpload,CustomJob-VerifyAppChanges,Initialization,PregateCheck,StatusCheck'
        foreach ($condition in $conditions.Values) { $condition.StartsWith($prefix) | Should -BeTrue }
    }
    It 'skips all jobs on <action>, draft=<draft>' -ForEach @(
        @{action='opened';draft=$true}, @{action='opened';draft=$false},
        @{action='synchronize';draft=$true}, @{action='synchronize';draft=$false},
        @{action='reopened';draft=$true}, @{action='reopened';draft=$false}
    ) {
        $payload = @{name='pull_request';repository='microsoft/BCApps';head='features/653393-expanded-api-helper-scope';action=$action;draft=$draft}
        foreach ($condition in $conditions.Values) { Test-OrdinaryPRGate -Condition $condition -Payload $payload | Should -BeFalse }
    }
    It 'does not exempt other heads, forks with the same branch name or merge queues' -ForEach @(
        @{eventName='pull_request';repo='microsoft/BCApps';head='features/653393-expanded-api-helper-scope-other'},
        @{eventName='pull_request';repo='microsoft/BCApps';head='features/653393-expanded-api-diagnostic'},
        @{eventName='pull_request';repo='microsoft/BCApps';head='features/646383-sql-api-tenant-count-comparison'},
        @{eventName='pull_request';repo='microsoft/BCApps';head='feature/ordinary'},
        @{eventName='pull_request';repo='another/BCApps';head='features/653393-expanded-api-helper-scope'},
        @{eventName='merge_group';repo='microsoft/BCApps';head='features/653393-expanded-api-helper-scope'}
    ) {
        $payload = @{name=$eventName;repository=$repo;head=$head}
        foreach ($condition in $conditions.Values) { Test-OrdinaryPRGate -Condition $condition -Payload $payload | Should -BeTrue }
    }
}
