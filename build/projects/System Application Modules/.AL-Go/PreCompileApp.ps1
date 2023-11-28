Param(
    [string] $appType,
    [ref] $compilationParams
)

if($appType -eq 'app')
{
    Write-Host "compilationParams: $compilationParams"

    $scriptPath = Join-Path $PSScriptRoot "../../../scripts/VerifyExecutePermissions.ps1" -Resolve
    . $scriptPath -ModulesDirectory $compilationParams.Value["appProjectFolder"]
}