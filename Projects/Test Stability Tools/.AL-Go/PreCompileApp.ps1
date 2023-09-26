Param(
    [string] $appType,
    [Hashtable] $parameters
)

$scriptPath = Join-Path $PSScriptRoot "../../../Build/Scripts/PreCompileApp.ps1" -Resolve
$projectFolder = Join-Path $PSScriptRoot "../../Test Stability Tools"

. $scriptPath -parameters $parameters -currentProjectFolder $projectFolder -appType $appType