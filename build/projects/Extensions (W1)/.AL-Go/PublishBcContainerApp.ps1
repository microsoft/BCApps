Param([Hashtable]$parameters)

# Ordered list of test framework apps to install. These are apps we build in BCApps but don't want to use for this project. 
$doNotInstallApps = @("System Application", "Business Foundation", "Base Application", "Application")

# These should be installed as part of import test toolkit
$testToolkitApps = @("Test Runner", "AI Test Toolkit", "Tests-TestLibraries", "System Application Test Library", "Library Assert", "Library Variable Storage")

$doNotInstallApps += $testToolkitApps

$appFile = $parameters.appFile

$installApp = $true
foreach ($app in $doNotInstallApps) {
    if ($appFile -like "*Microsoft_$app*") {
        Write-Host "FIX: Skipping installation of $app"
        $installApp = $false
    }
}

if ($installApp) {
    Publish-BcContainerApp @parameters
}