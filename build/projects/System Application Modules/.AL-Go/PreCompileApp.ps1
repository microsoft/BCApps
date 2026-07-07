Param(
    [string] $appType,
    [ref] $compilationParams
)

if($appType -eq 'app')
{
    $appFolder = $compilationParams.Value["appProjectFolder"]
    if ($appFolder) {
        $scriptPath = Join-Path $PSScriptRoot "../../../scripts/VerifyExecutePermissions.ps1" -Resolve
        . $scriptPath -AppFolder $appFolder
    } else {
        Write-Host "::Warning::PreCompileApp: appProjectFolder is not set; skipping execute permissions verification."
    }
}