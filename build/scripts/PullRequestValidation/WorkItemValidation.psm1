<#
    Reusable logic for validating that a pull request is tracked by a work item.

    A pull request is considered tracked when either:
      - it links to an Azure DevOps work item (using the 'AB#' pattern), or
      - it links to at least one GitHub issue whose GitHub issue type is 'Task'.

    The GitHub Task exemption is deliberately based on GitHub's issue type only, not on labels,
    titles, templates or file paths, so that event requests and other extensibility requests can
    use the same durable mechanism.
#>

$script:MissingWorkItemComment = "Could not find a linked work item. Please link one in either of these ways: (1) link an ADO work item using the pattern 'AB#' followed by the work item number - you may use the 'Fixes' keyword to automatically resolve it when the pull request is merged, e.g. 'Fixes AB#1234'; or (2) link a GitHub issue of type 'Task' using the pattern 'Fixes #' followed by the issue number, e.g. 'Fixes #1234'."

<#
    .SYNOPSIS
    Returns the first linked GitHub issue whose GitHub issue type is 'Task', or $null if none.
    .PARAMETER LinkedIssues
    The GitHub issues linked to the pull request. Each issue is expected to expose an IsOfType([string]) method.
#>
function Get-LinkedGitHubTaskIssue() {
    param(
        [Parameter(Mandatory = $false)]
        [object[]] $LinkedIssues
    )

    if (-not $LinkedIssues) {
        return $null
    }

    foreach ($issue in $LinkedIssues) {
        if ($issue -and $issue.IsOfType('Task')) {
            return $issue
        }
    }

    return $null
}

<#
    .SYNOPSIS
    Validates that a pull request is tracked by a work item, applying the GitHub Task exemption.
    .DESCRIPTION
    A pull request is considered tracked when either it links to an ADO work item, or it links to at
    least one GitHub issue whose GitHub issue type is 'Task'. When neither is present, a comment with
    guidance is added (for non-fork pull requests) and an error is thrown.

    When the GitHub Task exemption applies, any stale 'missing ADO work item' comment left by a previous
    run is removed.
    .PARAMETER ADOWorkItems
    The IDs of the ADO work items linked to the pull request.
    .PARAMETER PullRequest
    The pull request to validate.
    .PARAMETER LinkedIssues
    The GitHub issues linked to the pull request, used to evaluate the GitHub Task exemption.
#>
function Test-PullRequestHasWorkItem() {
    param(
        [Parameter(Mandatory = $false)]
        [string[]] $ADOWorkItems,
        [Parameter(Mandatory = $true)]
        [object] $PullRequest,
        [Parameter(Mandatory = $false)]
        [object[]] $LinkedIssues
    )

    $Comment = $script:MissingWorkItemComment

    # An ADO work item satisfies the requirement. Remove any previous failure comment.
    if ($ADOWorkItems) {
        $PullRequest.RemoveComment($Comment)
        return
    }

    # Exemption: a linked GitHub issue of type 'Task' is sufficient tracking on its own.
    $taskIssue = Get-LinkedGitHubTaskIssue -LinkedIssues $LinkedIssues
    if ($taskIssue) {
        Write-Host "GitHub Task exemption applied: pull request is linked to GitHub issue #$($taskIssue.IssueId) of type 'Task', so no ADO work item is required." -ForegroundColor Green
        # Remove any stale 'missing ADO work item' comment left by a previous run.
        $PullRequest.RemoveComment($Comment)
        return
    }

    # No ADO work item and no GitHub Task exemption -> fail with the existing guidance.
    if (-not $PullRequest.IsFromFork()) {
        $PullRequest.AddComment($Comment)
    }

    throw $Comment
}

Export-ModuleMember -Function Test-PullRequestHasWorkItem, Get-LinkedGitHubTaskIssue
