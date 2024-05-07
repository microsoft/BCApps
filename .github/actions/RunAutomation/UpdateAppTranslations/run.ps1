[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'runParameters', Justification = 'The parameter is always passed to the script')]
param (
    [Parameter(Mandatory=$true)]
    $runParameters
)

Import-Module $PSScriptRoot\..\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1

$newVersion = Update-PackageVersion -PackageName "Microsoft.Dynamics.BusinessCentral.Translations"

$result = @{
    'Files' = @()
    'Message' = "No update available"
}

if ($newVersion) {
    $result.Files = @(Get-PackagesFilePath -Relative)
    $result.Message = "Update translation package version. New value: $newVersion"
}

return $result