Param([Hashtable]$parameters)

$scriptPath = Join-Path $PSScriptRoot "../../scripts/PublishBcContainerApp.ps1"
. $scriptPath -parameters $parameters