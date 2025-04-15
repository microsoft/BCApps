Param(
    [hashtable] $parameters,
    [string[]] $dependenciesToInstall = @()
)

Import-Module $PSScriptRoot\AppExtensionsHelper.psm1

# Step 1: If the app is published to the container then we can install it from there
$remainingDependenciesToInstall = Install-MissingDependencies -ContainerName $containerName -DependenciesToInstall $dependenciesToInstall

# Step 2: If the app is not published to the container then we need to install it from the file system
foreach ($dependency in $remainingDependenciesToInstall) {
    Publish-AppFromFile -ContainerName $containerName -AppName $dependency
}