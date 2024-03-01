# BC Container Helper is needed to fetch the latest artifact version
Install-Module -Name BcContainerHelper -AllowPrerelease -Force
Import-Module BcContainerHelper
Import-Module $PSScriptRoot\..\..\EnlistmentHelperFunctions.psm1

$newVersion = Update-PackageVersion -PackageName "AppBaselines-BCArtifacts"

if ($newVersion) {
    return @{
        'Files' = @("build/Packages.json")
        'Message' = "Update app baselines package version. New value: $newVersion"
    }
}