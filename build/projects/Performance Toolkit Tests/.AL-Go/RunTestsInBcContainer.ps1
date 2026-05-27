Param(
    [Hashtable]$parameters
)

Import-Module (Join-Path $PSScriptRoot "../../../scripts/EnlistmentHelperFunctions.psm1" -Resolve)
Import-Module (Join-Path $PSScriptRoot "../../../scripts/BuildOptimization.psm1" -Resolve)

$baseFolder = Get-BaseFolder
if (Test-ShouldSkipTestApp -AppName $parameters["appName"] -BaseFolder $baseFolder) {
    return $true
}

$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve
. $script -parameters $parameters