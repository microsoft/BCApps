param (
    [Parameter(Mandatory=$true)]
    $runParameters
)

$repository = $runParameters.Repository
$targetBranch = $runParameters.TargetBranch
$workflowName = " CI/CD"
$workflowRunTime = Get-Date -AsUTC

Write-Host "Running the workflow '$workflowName' on branch $targetBranch"
gh workflow run --repo $repository --ref $targetBranch $workflowName

# Get the workflow run URL to display in the message

while((Get-Date -AsUTC) -lt $workflowRunTime.AddMinutes(1)) {
    Start-Sleep -Seconds 5 # wait for 5 seconds for the workflow to start
    $workflowRun = gh run list --branch $targetBranch --event workflow_dispatch --workflow $workflowName --repo $repository --json createdAt,url --limit 1 | ConvertFrom-Json

    if ($workflowRun -and ($workflowRun.createdAt -gt $workflowRunTime)) {
        break
    }
}


$result = @{
    'Files' = @()
    'Message' = "Could not start the '$workflowName' workflow. Please check the workflow status."
}

if ($workflowRun.createdAt -gt $workflowRunTime) {
    $result.Message = "'$workflowName' workflow started: $($workflowRun.url)"
}

return $result