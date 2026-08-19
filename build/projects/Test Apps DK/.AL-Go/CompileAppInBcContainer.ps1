Param(
    [Hashtable] $parameters
)

$scriptPath = Join-Path $PSScriptRoot "../../../scripts/CompileAppInBcContainer.ps1" -Resolve
. $scriptPath -parameters $parameters