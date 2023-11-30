Param(
    [string] $appType,
    [ref] $compilationParams
)

if($appType -eq 'app')
{
    Write-Host "compilationParams: $compilationParams"

    $scriptPath = Join-Path $PSScriptRoot "../../../scripts/VerifyExecutePermissions.ps1" -Resolve
    . $scriptPath -AppFolder $compilationParams.Value["appProjectFolder"]
}