# BC Container Helper is needed to fetch the latest artifact version
Install-Module -Name BcContainerHelper -AllowPrerelease -Force
Import-Module BcContainerHelper

Import-Module $PSScriptRoot\..\..\EnlistmentHelperFunctions.psm1

$newVersion = Update-BCArtifactVersion

if ($newVersion) {
    return @{
        'Files' = @(".github/AL-Go-Settings.json")
        'Message' = "Update BCArtifact version. New value: $newVersion"
    }
}
