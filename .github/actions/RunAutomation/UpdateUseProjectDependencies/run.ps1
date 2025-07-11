[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'runParameters', Justification = 'The parameter is always passed to the script')]
param (
    [Parameter(Mandatory=$true)]
    $runParameters
)

Import-Module $PSScriptRoot\..\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1
$appExtensionsSettings = Join-Path (Get-BaseFolder) "build/projects/Apps (W1)/.AL-Go/settings.json" -Resolve
$settings = Get-Content -Path $appExtensionsSettings -Raw | ConvertFrom-Json

# Initialize the result object
$result = @{
    'Files' = @()
    'Message' = "No update available"
}

if ($settings.useProjectDependencies -eq $true) {
    Write-Host "Project dependencies are already enabled. No changes needed."
} else {
    # Update the settings to enable project dependencies
    $settings.useProjectDependencies = $true
    $settings | ConvertTo-Json -Depth 100 | Set-Content -Path $appExtensionsSettings -Force
    Write-Host "Project dependencies have been enabled."

    $result.Files += $appExtensionsSettings
    $result.Message = "Update useProjectDependencies to true"
}

return $result
