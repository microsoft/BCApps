param (
    [Parameter(Mandatory=$true)]
    [string] $Repository
)

Import-Module $PSScriptRoot\..\..\EnlistmentHelperFunctions.psm1

$TargetBranch = Get-CurrentBranch
Write-Host "Running the workflow Update AL-Go System Files on branch $TargetBranch"

$workflowName = " Update AL-Go System Files"
$workflowRunTime = Get-Date
gh workflow run --repo $Repository --ref $TargetBranch $workflowName

# Get the workflow run URL to display in the message

while((Get-Date) -lt $workflowRunTime.AddMinutes(1)) {
    $workflowRun = gh run list --branch $TargetBranch --event workflow_dispatch --workflow $workflowName --repo $Repository --json createdAt,url --limit 1 | ConvertFrom-Json

    if ($workflowRun.createdAt -gt $workflowRunTime) {
        break
    }

    Start-Sleep -Seconds 5
}

$message = ""
if ($workflowRun.createdAt -gt $workflowRunTime) {
    $message = "Update AL-Go System Files workflow stared: $($workflowRun.url)"
}

return @{
    'Files' = @()
    'Message' = $message
}
