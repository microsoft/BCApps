using module .\GitHubAPI.class.psm1
using module .\GitHubWorkItemLink.class.psm1

<#
    Class that represents a GitHub issue.
#>
class GitHubIssue {
    $IssueId
    $Repository
    $Issue

    hidden GitHubIssue([int] $IssueId, [string] $Repository) {
        $this.IssueId = $IssueId
        $this.Repository = $Repository

        $gitHubIssue = gh api "/repos/$Repository/issues/$IssueId" -H ([GitHubAPI]::AcceptJsonHeader) -H ([GitHubAPI]::GitHubAPIHeader) | ConvertFrom-Json
        if ($gitHubIssue.message) {
            # message property is populated when the issue is not found
            Write-Host "::Warning:: Could not get issue $IssueId from repository $Repository. Error: $($gitHubIssue.message)"
            $this.Issue = $null
            return
        }
        $this.Issue = $gitHubIssue
    }

    <#
        Gets the issue from GitHub.
    #>
    static [GitHubIssue] Get([int] $IssueId, [string] $Repository) {
        $gitHubIssue = [GitHubIssue]::new($IssueId, $Repository)

        if (-not $gitHubIssue.Issue) {
            return $null
        }

        return $gitHubIssue
    }

    <#
        Returns true if the issue is approved, otherwise returns false.
        Issue is considered approved if it has a label named "approved".
    #>
    [bool] IsApproved() {
        if(-not $this.Issue.labels) {
            return $false
        }

        return $this.Issue.labels.name -contains "approved"
    }

    <#
        Gets the linked ADO workitem IDs from the pull request description.
        .returns
            An array of linked issue IDs.
    #>
    [int[]] GetLinkedADOWorkItemIDs() {
        return [GitHubWorkItemLink]::GetLinkedADOWorkItemIDs($this.Issue.body)
    }

    <#
        Gets the GitHub issue type name (e.g. 'Task', 'Bug', 'Feature') from a raw issue object.
        Safe to call under Set-StrictMode: returns $null when the issue or its type is not set.
        .returns
            The issue type name, or $null if the issue has no type.
    #>
    static [string] GetIssueTypeName($Issue) {
        if (-not $Issue) {
            return $null
        }

        if (-not ($Issue.PSObject.Properties.Name -contains "type")) {
            return $null
        }

        if (-not $Issue.type) {
            return $null
        }

        return $Issue.type.name
    }

    <#
        Gets the GitHub issue type name for this issue (e.g. 'Task', 'Bug', 'Feature').
        .returns
            The issue type name, or $null if the issue has no type.
    #>
    [string] GetIssueType() {
        return [GitHubIssue]::GetIssueTypeName($this.Issue)
    }

    <#
        Returns true if the issue's GitHub issue type matches the provided type, otherwise returns false.
        .Parameter IssueType
            The GitHub issue type to compare against (e.g. 'Task').
    #>
    [bool] IsOfType([string] $IssueType) {
        return $this.GetIssueType() -eq $IssueType
    }

    <#
        Returns true if the issue is open, otherwise returns false.
    #>
    [bool] IsOpen() {
        if (-not $this.Issue.state) {
            return $false
        }

        return $this.Issue.state -eq "open"
    }

    [bool] IsPullRequest() {
        return $this.Issue.PSobject.Properties.name -eq "pull_request"
    }
}
