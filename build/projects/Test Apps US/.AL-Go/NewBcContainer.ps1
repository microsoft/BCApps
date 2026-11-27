Param(
    [Hashtable]$parameters
)

$parameters['isolation'] = 'process'

$script = Join-Path $PSScriptRoot "../../../scripts/NewBcContainer.ps1" -Resolve
. $script -parameters $parameters