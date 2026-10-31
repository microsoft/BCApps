Param(
    [Hashtable]$parameters,
    [string[]]$AdditionalAppsNotToPublish = @()
)

Import-Module (Join-Path $PSScriptRoot 'AppPublicationPolicy.psm1')
$listOfAppsNotToPublish = @(Get-StandardAppPublicationExclusion) + $AdditionalAppsNotToPublish

function Test-ShouldPublishApp() {
    param(
        [string]$appFile,
        [string[]]$exclusionList
    )

    $appName = (Get-Item $appFile).BaseName

    if (Test-AppPublicationExcluded -BaseName $appName -ExclusionList $exclusionList) {
        Write-Host "Skipping publishing of app $appName as it is in the exclusion list."
        return $false
    }

    return $true
}

$appFiles = $parameters["appFile"]
if ($appFiles -is [string]) {
    if (Test-ShouldPublishApp -appFile $appFiles -exclusionList $listOfAppsNotToPublish) {
        $filteredAppFiles = $appFiles
    } else {
        $filteredAppFiles = @()
    }
} elseif ($appFiles -is [array]) {
    $filteredAppFiles = @()
    foreach ($appFile in $appFiles) {
        if (Test-ShouldPublishApp -appFile $appFile -exclusionList $listOfAppsNotToPublish) {
            $filteredAppFiles += $appFile
        }
    }
}

$parameters["appFile"] = $filteredAppFiles
$parameters["scope"] = "Global"
# Publish only — do not install. Installation is handled by ImportTestDataInBcContainer.ps1
# which controls the install order based on test type (e.g. Legacy needs DemoTool to run
# before certain apps are installed).
$parameters["install"] = $false
$parameters["upgrade"] = $false
$parameters["sync"] = $true
Publish-BcContainerApp @parameters
