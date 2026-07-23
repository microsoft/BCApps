Param(
    [string] $appType,
    [ref] $compilationParams
)

if($appType -eq 'app')
{
    $scriptPath = Join-Path $PSScriptRoot "../../../scripts/VerifyExecutePermissions.ps1" -Resolve
    $workspaceFilePath = (Get-Item -Path $compilationParams.Value["WorkspaceFile"])
    $workspace = Get-Content -Path $workspaceFilePath.FullName -Raw | ConvertFrom-Json
    Push-Location $workspaceFilePath.DirectoryName
    try {
        # iterate through all projects in the workspace file
        foreach ($project in $workspace.folders) {
            $appFolder = $project.path
            # The execute-permissions check applies to the System Application and Business Foundation
            # modules. Apps under src/Tools (test framework, performance toolkit, etc.) are dev and
            # test tooling and are exempt.
            if ($appFolder -match '[\\/]src[\\/]Tools[\\/]') {
                Write-Host "Skipping execute permissions verification for Tools app folder: $appFolder"
                continue
            }
            Write-Host "Verifying execute permissions for app folder: $appFolder"
            . $scriptPath -AppFolder $appFolder
        }
    } finally {
        Pop-Location
    }
}