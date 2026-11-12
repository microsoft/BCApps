using module .\GitHubIssue.class.psm1

Describe "GitHubIssue GitHub issue type" {
    Context "GetIssueTypeName" {
        It "returns the issue type name when the type is 'Task'" {
            $issue = [PSCustomObject]@{ type = [PSCustomObject]@{ name = 'Task' } }
            [GitHubIssue]::GetIssueTypeName($issue) | Should -Be 'Task'
        }

        It "returns the issue type name for a non-Task type" {
            $issue = [PSCustomObject]@{ type = [PSCustomObject]@{ name = 'Bug' } }
            [GitHubIssue]::GetIssueTypeName($issue) | Should -Be 'Bug'
        }

        It "returns null when the type property is present but null" {
            $issue = [PSCustomObject]@{ number = 1; type = $null }
            [GitHubIssue]::GetIssueTypeName($issue) | Should -BeNullOrEmpty
        }

        It "returns null when the issue has no type property" {
            $issue = [PSCustomObject]@{ number = 1 }
            [GitHubIssue]::GetIssueTypeName($issue) | Should -BeNullOrEmpty
        }

        It "returns null when the issue is null" {
            [GitHubIssue]::GetIssueTypeName($null) | Should -BeNullOrEmpty
        }
    }
}
