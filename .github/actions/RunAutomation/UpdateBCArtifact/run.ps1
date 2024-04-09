[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'runParameters', Justification = 'The parameter is always passed to the script')]
param (
    [Parameter(Mandatory=$true)]
    $runParameters
)


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
