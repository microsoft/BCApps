Param(
    [string] $appType,
    [ref] $compilationParams
)

$scriptPath = Join-Path $PSScriptRoot "../../../scripts/PreCompileApp.ps1" -Resolve
$projectFolder = Join-Path $PSScriptRoot "../../System Application"

. $scriptPath -parameters $compilationParams -currentProjectFolder $projectFolder -appType $appType