[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'runParameters', Justification = 'The parameter is always passed to the script')]
param (
    [Parameter(Mandatory=$true)]
    $runParameters
)


# BC Container Helper is needed to fetch the latest artifact version
Install-Module -Name BcContainerHelper -AllowPrerelease -Force
Import-Module BcContainerHelper -DisableNameChecking

Import-Module $PSScriptRoot\..\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1

$newVersion = Update-BCArtifactVersion

$result = @{
    'Files' = @()
    'Message' = "No update available"
}

if ($newVersion) {
    $result.Files = @(".github/AL-Go-Settings.json")
    $result.Message = "Update BCArtifact version. New value: $newVersion"
}

return $result
