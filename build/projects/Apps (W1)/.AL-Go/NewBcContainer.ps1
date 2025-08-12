Param(
    [Hashtable]$parameters
)
Import-Module "../../../scripts/EnlistmentHelperFunctions.psm1"

$script = Join-Path $PSScriptRoot "../../../scripts/NewBcContainer.ps1" -Resolve
. $script -parameters $parameters -AppsToUnpublish (Get-AppsInFolder "src/Apps/W1")