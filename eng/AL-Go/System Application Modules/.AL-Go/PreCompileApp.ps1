Param(
    [string] $appType,
    [ref] $compilationParams
)

if($appType -eq 'app')
{
    $scriptPath = Join-Path $PSScriptRoot "../../../CI/VerifyExecutePermissions.ps1" -Resolve
    $workspaceFilePath = (Get-Item -Path $compilationParams.Value["WorkspaceFile"])
    $workspace = Get-Content -Path $workspaceFilePath.FullName -Raw | ConvertFrom-Json
    Push-Location $workspaceFilePath.DirectoryName
    try {
        # iterate through all projects in the workspace file
        foreach ($project in $workspace.folders) {
            $appFolder = $project.path
            Write-Host "Verifying execute permissions for app folder: $appFolder"
            . $scriptPath -AppFolder $appFolder
        }
    } finally {
        Pop-Location
    }
}