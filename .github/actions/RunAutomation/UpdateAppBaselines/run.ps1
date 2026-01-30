[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'runParameters', Justification = 'The parameter is always passed to the script')]
param (
    [Parameter(Mandatory=$true)]
    $runParameters
)

# BC Container Helper is needed to fetch the latest artifact version
Install-Module -Name BcContainerHelper -AllowPrerelease -Force
Import-Module BcContainerHelper -DisableNameChecking
Import-Module $PSScriptRoot\..\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1

$newVersion = Update-PackageVersion -PackageName "AppBaselines-BCArtifacts"

$result = @{
    'Files' = @()
    'Message' = "No update available"
}

if ($newVersion) {
    $result.Files = @(Get-PackagesFilePath -Relative)
    $result.Message = "Update app baselines package version. New value: $newVersion"
}

return $result