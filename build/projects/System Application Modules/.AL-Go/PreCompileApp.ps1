Param(
    [string] $appType,
    [ref] $compilationParams
)

if($appType -eq 'app')
{
    Write-Host "compilationParams: $compilationParams"

    $scriptPath = Join-Path $PSScriptRoot "../../../scripts/VerifyExecutePermissions.ps1" -Resolve
    $workspaceFilePath = $compilationParams.Value["WorkspaceFile"]
    Write-Host "Reading workspace file from: $workspaceFilePath"
    $workspaceFile = (Get-Item -Path $workspaceFilePath)
    $workspace = Get-Content -Path $workspaceFile.FullName -Raw | ConvertFrom-Json
    Push-Location $workspaceFile.DirectoryName
    try {
        # iterate through all projects in the workspace file
        foreach ($project in $workspace.projects) {
            $appFolder = $project.path
            Write-Host "Verifying execute permissions for app folder: $appFolder"
            . $scriptPath -AppFolder $appFolder
        }
    } finally {
        Pop-Location
    }
}