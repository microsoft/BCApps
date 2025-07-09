Param(
    [Hashtable]$parameters
)

$parameters['SetupData '] = $true

$script = Join-Path $PSScriptRoot "../../../scripts/ImportTestDataInBcContainer.ps1" -Resolve
. $script -parameters $parameters