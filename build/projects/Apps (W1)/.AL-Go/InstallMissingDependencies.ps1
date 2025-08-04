Param(
    [Hashtable]$parameters
)

Import-Module (Join-Path $PSScriptRoot "../../../scripts/AppExtensionsHelper.psm1" -Resolve)

# If the base app isn't installed we need to start by installing the app dependencies. Later we will install the test app dependencies.
$isBaseAppInstalled = Get-BcContainerAppInfo -containerName $parameters.containerName -tenantSpecificProperties | Where-Object { ($_.Name -eq "Base Application") -and ($_.IsInstalled -eq $true) }
if (-not $isBaseAppInstalled) {
    Write-Host "Installing App Dependencies"
    $configuration = "App"
} else {
    Write-Host "Installing Test App Dependencies"
    $configuration = "Test"
}

$script = Join-Path $PSScriptRoot "../../../scripts/InstallMissingDependencies.ps1" -Resolve
. $script -parameters $parameters -configuration $configuration