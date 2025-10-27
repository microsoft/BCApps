[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'parameters', Justification = 'The parameter is not used, but the script needs to match this format')]
Param(
    [hashtable] $parameters,
    [string[]] $dependenciesToInstall = @()
)

Import-Module $PSScriptRoot\AppExtensionsHelper.psm1

# Step 1: If the app is published to the container then we can install it from there
$remainingDependenciesToInstall = Install-AppInContainer -ContainerName $containerName -AppsToInstall $dependenciesToInstall

# Step 2: If the app is not published to the container then we need to install it from the file system
foreach ($dependency in $remainingDependenciesToInstall) {
    Install-AppFromFile -ContainerName $containerName -AppName $dependency
}