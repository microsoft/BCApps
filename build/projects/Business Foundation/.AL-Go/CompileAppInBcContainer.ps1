Param(
    [Hashtable] $parameters
)

$recompileDependencies = @("System Application")

$scriptPath = Join-Path $PSScriptRoot "../../../scripts/CompileAppInBcContainer.ps1" -Resolve
. $scriptPath -parameters $parameters -recompileDependencies $recompileDependencies