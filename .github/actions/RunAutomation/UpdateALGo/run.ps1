param (
    [Parameter(Mandatory=$true)]
    $runParameters
)

$repository = $runParameters.Repository
$targetBranch = $runParameters.TargetBranch

Write-Host "Running the workflow Update AL-Go System Files on branch $targetBranch"

$workflowName = " Update AL-Go System Files"
$workflowRunTime = Get-Date
gh workflow run --repo $repository --ref $targetBranch $workflowName

# Get the workflow run URL to display in the message

while((Get-Date) -lt $workflowRunTime.AddMinutes(1)) {
    Start-Sleep -Seconds 5 # wait for 5 seconds for the workflow to start
    $workflowRun = gh run list --branch $targetBranch --event workflow_dispatch --workflow $workflowName --repo $repository --json createdAt,url --limit 1 | ConvertFrom-Json

    if ($workflowRun -and ($workflowRun.createdAt -gt $workflowRunTime)) {
        break
    }
}


$result = @{
    'Files' = @()
    'Message' = "Could not start the Update AL-Go System Files workflow. Please check the workflow status."
}

if ($workflowRun.createdAt -gt $workflowRunTime) {
    $result.Message = "'Update AL-Go System Files' workflow started: $($workflowRun.url)"
}

return $result