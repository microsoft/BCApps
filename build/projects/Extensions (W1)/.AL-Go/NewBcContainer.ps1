Param(
    [Hashtable]$parameters
)
$parameters.installApps = @()
$parameters.installTestApps = @()

$script = Join-Path $PSScriptRoot "../../../scripts/NewBcContainer.ps1" -Resolve
. $script -parameters $parameters -keepApps @("System Application", "Business Foundation", "Base Application", "Application")