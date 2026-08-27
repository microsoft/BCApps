Describe "Test-PullRequestHasWorkItem" {
    BeforeAll {
        Import-Module "$PSScriptRoot\WorkItemValidation.psm1" -Force

        # Creates a fake pull request that records the comments it is asked to add or remove.
        function New-FakePullRequest {
            param(
                [bool] $FromFork = $false
            )

            $pr = [PSCustomObject]@{
                AddedComments   = [System.Collections.ArrayList]::new()
                RemovedComments = [System.Collections.ArrayList]::new()
                FromFork        = $FromFork
            }

            $pr | Add-Member -MemberType ScriptMethod -Name AddComment -Value { param($message) [void]$this.AddedComments.Add($message) }
            $pr | Add-Member -MemberType ScriptMethod -Name RemoveComment -Value { param($message) [void]$this.RemovedComments.Add($message) }
            $pr | Add-Member -MemberType ScriptMethod -Name IsFromFork -Value { return $this.FromFork }

            return $pr
        }

        # Creates a fake GitHub issue with a given GitHub issue type.
        function New-FakeIssue {
            param(
                [int] $Id,
                [string] $IssueType
            )

            $issue = [PSCustomObject]@{ IssueId = $Id; IssueType = $IssueType }
            $issue | Add-Member -MemberType ScriptMethod -Name IsOfType -Value { param($type) return $this.IssueType -eq $type }

            return $issue
        }
    }

    It "passes when the pull request links to an ADO work item (existing behavior)" {
        $pr = New-FakePullRequest
        { Test-PullRequestHasWorkItem -ADOWorkItems @('1234') -PullRequest $pr -LinkedIssues @() } | Should -Not -Throw
        $pr.AddedComments.Count | Should -Be 0
    }

    It "passes when a linked GitHub issue has type 'Task' and there is no ADO work item" {
        $pr = New-FakePullRequest
        $issues = @((New-FakeIssue -Id 10 -IssueType 'Bug'), (New-FakeIssue -Id 20 -IssueType 'Task'))
        { Test-PullRequestHasWorkItem -ADOWorkItems @() -PullRequest $pr -LinkedIssues $issues } | Should -Not -Throw
        $pr.AddedComments.Count | Should -Be 0
    }

    It "removes the stale missing-work-item comment when the GitHub Task exemption applies" {
        $pr = New-FakePullRequest
        $issues = @((New-FakeIssue -Id 20 -IssueType 'Task'))
        Test-PullRequestHasWorkItem -ADOWorkItems @() -PullRequest $pr -LinkedIssues $issues
        $pr.RemovedComments.Count | Should -BeGreaterThan 0
        $pr.RemovedComments[0] | Should -Match "Could not find a linked work item"
    }

    It "fails when a linked issue is not of type 'Task' and there is no ADO work item" {
        $pr = New-FakePullRequest
        $issues = @((New-FakeIssue -Id 10 -IssueType 'Bug'))
        { Test-PullRequestHasWorkItem -ADOWorkItems @() -PullRequest $pr -LinkedIssues $issues } | Should -Throw
        $pr.AddedComments.Count | Should -Be 1
    }

    It "fails when there are no linked issues and no ADO work item" {
        $pr = New-FakePullRequest
        { Test-PullRequestHasWorkItem -ADOWorkItems @() -PullRequest $pr -LinkedIssues @() } | Should -Throw
        $pr.AddedComments.Count | Should -Be 1
    }

    It "does not add a comment on fork pull requests when validation fails" {
        $pr = New-FakePullRequest -FromFork $true
        { Test-PullRequestHasWorkItem -ADOWorkItems @() -PullRequest $pr -LinkedIssues @() } | Should -Throw
        $pr.AddedComments.Count | Should -Be 0
    }
}

Describe "Get-LinkedGitHubTaskIssue" {
    BeforeAll {
        Import-Module "$PSScriptRoot\WorkItemValidation.psm1" -Force

        function New-FakeIssue {
            param(
                [int] $Id,
                [string] $IssueType
            )

            $issue = [PSCustomObject]@{ IssueId = $Id; IssueType = $IssueType }
            $issue | Add-Member -MemberType ScriptMethod -Name IsOfType -Value { param($type) return $this.IssueType -eq $type }

            return $issue
        }
    }

    It "returns the first Task issue" {
        $issues = @((New-FakeIssue -Id 1 -IssueType 'Bug'), (New-FakeIssue -Id 2 -IssueType 'Task'), (New-FakeIssue -Id 3 -IssueType 'Task'))
        (Get-LinkedGitHubTaskIssue -LinkedIssues $issues).IssueId | Should -Be 2
    }

    It "returns null when there are no Task issues" {
        $issues = @((New-FakeIssue -Id 1 -IssueType 'Bug'), (New-FakeIssue -Id 2 -IssueType 'Feature'))
        Get-LinkedGitHubTaskIssue -LinkedIssues $issues | Should -BeNullOrEmpty
    }

    It "returns null when there are no linked issues" {
        Get-LinkedGitHubTaskIssue -LinkedIssues @() | Should -BeNullOrEmpty
    }
}
