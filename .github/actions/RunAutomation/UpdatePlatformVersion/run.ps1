[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'runParameters', Justification = 'The parameter is always passed to the script')]
param (
    [Parameter(Mandatory=$true)]
    $runParameters
)

Import-Module $PSScriptRoot\..\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1

$result = @{
    'Files' = @()
    'Message' = "No update available"
}

# Defensively check whether the BCPlatform package is tracked in the Packages config.
# Some (older) release branches do not track the BCPlatform package, in which case there is nothing to update.
$platformPackage = Get-ConfigValue -Key "BCPlatform" -ConfigType Packages
if (-not $platformPackage) {
    Write-Host "BCPlatform package is not present in the Packages config. Skipping update."
    return $result
}

$newVersion = Update-PackageVersion -PackageName "BCPlatform"

if ($newVersion) {
    $result.Files = @(Get-PackagesFilePath -Relative)
    $result.Message = "Update platform version. New value: $newVersion"
}

return $result
