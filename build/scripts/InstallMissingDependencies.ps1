[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'parameters', Justification = 'The parameter is not used, but the script needs to match this format')]
Param(
    [hashtable] $parameters,
    [string] $configuration
)

<#
Import-Module $PSScriptRoot\AppExtensionsHelper.psm1

# Step 1: If the app is published to the container then we can install it from there
$remainingDependenciesToInstall = Install-AppFromContainer -ContainerName $containerName -AppsToInstall $dependenciesToInstall

# Step 2: If the app is not published to the container then we need to install it from the file system
foreach ($dependency in $remainingDependenciesToInstall) {
    Install-AppFromFile -ContainerName $containerName -AppName $dependency
}
#>

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

$baseFolder = Get-BaseFolder
$outFolder = Join-Path $baseFolder 'out'

Write-Host "Restoring dependencies for configuration: $configuration"

dotnet restore (Join-Path $baseFolder 'build\projects\Apps (W1)\.AL-Go\') -p:Configuration=$configuration --packages $outFolder
# Get all .app files under the out directory
$AppFiles = Get-ChildItem -Path $outFolder -Filter '*.app' -Recurse | Select-Object -ExpandProperty FullName

foreach($AppFilePath in $AppFiles) {
    Write-Host "Publishing app: $AppFilePath"
    Publish-BcContainerApp -containerName $ContainerName -appFile "$($AppFilePath)" -skipVerification -scope Global -install -sync
}