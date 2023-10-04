Param(
    [Hashtable]$parameters
)

$script = Join-Path $PSScriptRoot "../../../Build/Scripts/RunTestsInBcContainer.ps1" -Resolve
. $script -parameters $parameters