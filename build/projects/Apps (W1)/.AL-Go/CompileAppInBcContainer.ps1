Param(
    [Hashtable] $parameters
)

$parameters["GenerateReportLayout"] = "Yes"

$scriptPath = Join-Path $PSScriptRoot "../../../scripts/CompileAppInBcContainer.ps1" -Resolve
. $scriptPath -parameters $parameters