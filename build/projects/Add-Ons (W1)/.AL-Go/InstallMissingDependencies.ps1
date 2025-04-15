Param(
    [Hashtable]$parameters
)

# Reinstall the dependencies in the container
$customSettings = Get-Content -Path (Join-Path $PSScriptRoot "customSettings.json" -Resolve) | ConvertFrom-Json

$script = Join-Path $PSScriptRoot "../../../scripts/InstallMissingDependencies.ps1" -Resolve
. $script -parameters $parameters -dependenciesToInstall $customSettings.ExternalAppDependencies