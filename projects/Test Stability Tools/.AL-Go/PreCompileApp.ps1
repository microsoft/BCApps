Param(
    [string] $appType,
    [ref] $compilationParams
)

$scriptPath = Join-Path $PSScriptRoot "../../../Build/Scripts/PreCompileApp.ps1" -Resolve
$projectFolder = Join-Path $PSScriptRoot "../../Test Stability Tools"

. $scriptPath -parameters $compilationParams -currentProjectFolder $projectFolder -appType $appType