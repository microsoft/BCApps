Param(
    [Hashtable]$parameters
)

# Reinstall the dependencies in the container
$customSettings = Get-Content -Path (Join-Path $PSScriptRoot "customSettings.json" -Resolve) | ConvertFrom-Json


$isBaseAppInstalled = Get-BcContainerAppInfo -containerName $parameters.containerName -tenantSpecificProperties | Where-Object { ($_.Name -eq "Base Application") -and ($_.IsInstalled -eq $true) }
if (-not $isBaseAppInstalled) {
    Write-Host "Installing App Dependencies"
    $dependenciesToInstall = $customSettings.ExternalAppDependencies
} else {
    Write-Host "Installing Test App Dependencies"
    $dependenciesToInstall = $customSettings.ExternalTestAppDependencies
}

$script = Join-Path $PSScriptRoot "../../../scripts/InstallMissingDependencies.ps1" -Resolve
. $script -parameters $parameters -dependenciesToInstall $dependenciesToInstall