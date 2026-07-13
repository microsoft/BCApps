Param(
    [Hashtable]$parameters
)

Import-Module (Join-Path $PSScriptRoot "../../../scripts/ParallelTestExecution.psm1" -Resolve)
return (Invoke-PerProjectTestRun -parameters $parameters)