Param(
    [Hashtable] $parameters
)

$parameters["GenerateReportLayout"] = "No"

$scriptPath = Join-Path $PSScriptRoot "../../../scripts/CompileAppInBcContainer.ps1" -Resolve
. $scriptPath -parameters $parameters