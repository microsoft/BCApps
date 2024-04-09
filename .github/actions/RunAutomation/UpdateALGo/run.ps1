param (
    [Parameter(Mandatory=$true)]
    $runParameters
)

Import-Module $PSScriptRoot\..\..\EnlistmentHelperFunctions.psm1

$repository = $runParameters.Repository
$targetBranch = $runParameters.TargetBranch

Write-Host "Running the workflow Update AL-Go System Files on branch $targetBranch"

$workflowName = " Update AL-Go System Files"
$workflowRunTime = Get-Date
gh workflow run --repo $repository --ref $targetBranch $workflowName

# Get the workflow run URL to display in the message

while((Get-Date) -lt $workflowRunTime.AddMinutes(1)) {
    $workflowRun = gh run list --branch $targetBranch --event workflow_dispatch --workflow $workflowName --repo $repository --json createdAt,url --limit 1 | ConvertFrom-Json

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
