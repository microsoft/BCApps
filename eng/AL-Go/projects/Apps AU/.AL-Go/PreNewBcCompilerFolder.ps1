Param(
    [Hashtable] $parameters
)

$script = Join-Path $PSScriptRoot "../../../scripts/PreNewBcCompilerFolder.ps1" -Resolve
. $script -parameters $parameters