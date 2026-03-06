Param(
    [Hashtable]$parameters
)
Import-Module (Join-Path $PSScriptRoot "../../../scripts/EnlistmentHelperFunctions.psm1" -Resolve)

$script = Join-Path $PSScriptRoot "../../../scripts/NewBcContainer.ps1" -Resolve
. $script -parameters $parameters -AppsToUnpublish @("AI Test Toolkit") # temp fix to allow renaming 'AI Test Toolkit'
