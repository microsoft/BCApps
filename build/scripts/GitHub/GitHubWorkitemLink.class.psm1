
class GitHubWorkitemLink {
    static [int[]] GetLinkedIssueIDs($Body) {
        if(-not $Body) {
            return @()
        }

        $workitemPattern = "(^|\s)(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved) #(?<ID>\d+)" # e.g. "Fixes #1234"
        return [GitHubWorkitemLink]::GetLinkedWorkItemIDs($workitemPattern, $Body)
    }

    static [int[]] GetLinkedADOWorkitems($Body) {
        if(-not $Body) {
            return @()
        }

        $workitemPattern = "AB#(?<ID>\d+)" # e.g. "AB#1234" or "Fixes AB#1234"
        return [GitHubWorkitemLink]::GetLinkedWorkItemIDs($workitemPattern, $Body)
    }

    static [string] LinkToWorkItem($Description, $WorkItem) {
        if ([GitHubWorkitemLink]::IsLinkedToWorkItem($Description, $WorkItem)) {
            Write-Host "Pull request already linked to ADO workitem AB#$($WorkItem)"
            return $Description
        }

        $Description += "`nFixes AB#$($WorkItem)"
        return $Description
    }

    static [bool] IsLinkedToWorkItem($Description, $WorkItem) {
        return $Description -match "AB#$($WorkItem)"
    }

    static [int[]] GetLinkedWorkItemIDs($Pattern, $Body) {
        if(-not $Body) {
            return @()
        }

        $workitemMatches = Select-String $Pattern -InputObject $Body -AllMatches

        if(-not $workitemMatches) {
            return @()
        }

        $workitemIds = @()
        $groups = $workitemMatches.Matches.Groups | Where-Object { $_.Name -eq "ID" }
        foreach($group in $groups) {
            $workitemIds += $group.Value
        }
        return $workitemIds
    }
}