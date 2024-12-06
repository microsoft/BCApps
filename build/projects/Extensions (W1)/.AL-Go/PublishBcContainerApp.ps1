Param([Hashtable]$parameters)

$doNotInstallApps = @("System Application", "Business Foundation", "Base Application", "Application", "Test Runner", "AI Test Toolkit", "Tests-TestLibraries", "System Application Test Library", "Library Assert", "Library Variable Storage")

$appFile = $parameters.appFile

$installApp = $true
foreach ($app in $doNotInstallApps) {
    if ($appFile -like "*Microsoft_$app*") {
        Write-Host "Skipping installation of $app"
        $installApp = $false
    }
}

if ($installApp) {
    Publish-BcContainerApp @parameters
}