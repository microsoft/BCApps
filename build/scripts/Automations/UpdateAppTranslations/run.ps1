Import-Module $PSScriptRoot\..\..\EnlistmentHelperFunctions.psm1

$newVersion = Update-PackageVersion -PackageName "Microsoft.Dynamics.BusinessCentral.Translations"

if ($newVersion) {
    return @{
        'Files' = @("build/Packages.json")
        'Message' = "Update translation package version. New value: $newVersion"
    }
}