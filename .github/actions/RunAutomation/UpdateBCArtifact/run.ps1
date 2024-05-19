[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'runParameters', Justification = 'The parameter is always passed to the script')]
param (
    [Parameter(Mandatory=$true)]
    $runParameters
)


# BC Container Helper is needed to fetch the latest artifact version
Install-Module -Name BcContainerHelper -AllowPrerelease -Force
Import-Module BcContainerHelper -DisableNameChecking

Import-Module $PSScriptRoot\..\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1

$newArtifactUrl = Update-BCArtifactVersion

$result = @{
    'Files' = @()
    'Message' = "No update available"
}

if ($newArtifactUrl) {
    $result.Files = @(Get-ALGoSettingsPath -Relative)

    if ($newArtifactUrl -match "\d+\.\d+\.\d+\.\d+") {
        $result.Message = "Update BCArtifact version. New value: $($Matches[0])"
    } else {
        $result.Message = "Update BCArtifact version. New value: $newArtifactUrl"
    }
}

return $result
