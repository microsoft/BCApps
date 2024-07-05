Param(
    [Hashtable] $parameters
)

$scriptPath = Join-Path $PSScriptRoot "../../../scripts/CompileAppInBcContainer.ps1" -Resolve
$projectFolder = Join-Path $PSScriptRoot "../../AI Test Toolkit" -Resolve

. $scriptPath -parameters $parameters -currentProjectFolder $projectFolder