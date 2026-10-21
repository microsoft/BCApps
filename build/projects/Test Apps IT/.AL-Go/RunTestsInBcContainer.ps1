Param(
    [Hashtable] $parameters,
    [hashtable] $codeCoverageContext
)

Import-Module (Join-Path $PSScriptRoot "../../../scripts/ParallelTestExecution.psm1" -Resolve)
return (Invoke-PerProjectTestRun -parameters $parameters -codeCoverageContext $codeCoverageContext)