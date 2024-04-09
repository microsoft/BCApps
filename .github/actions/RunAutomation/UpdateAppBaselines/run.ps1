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

if ($newVersion) {
    return @{
        'Files' = @("build/Packages.json")
        'Message' = "Update app baselines package version. New value: $newVersion"
    }
}