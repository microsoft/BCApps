[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'parameters', Justification = 'The parameter is not used, but it''s script needs to match this format')]
Param(
    [hashtable] $parameters
)

$installedApps = Get-BcContainerAppInfo -containerName $parameters.containerName -tenantSpecificProperties -sort DependenciesLast
$installedApps | ForEach-Object {
    Write-Host "App $($_.Name) is installed"
}

Import-TestToolkitToBcContainer @parameters

$installedApps = Get-BcContainerAppInfo -containerName $parameters.containerName -tenantSpecificProperties -sort DependenciesLast
$installedApps | ForEach-Object {
    Write-Host "App $($_.Name) is installed"
}