Param([Hashtable]$parameters)

function PublishApp() {
    param(
        [string]$appFile
    )

    $listOfAppsNotToPublish = @(
        "Library - No Transactions",
        "Prevent Metadata Updates Library",
        "Contoso Coffee Demo Dataset (IN)"
    )

    Write-Host "Processing app file: $appFile"
    $appName = (Get-Item $appFile).BaseName
    Write-Host "App BaseName: '$appName'"
    
    $matchedApp = $listOfAppsNotToPublish | Where-Object { 
        $pattern = "Microsoft_$($_)_*"
        $matches = $appName -like $pattern
        Write-Host "  Checking pattern '$pattern': $matches"
        $matches
    }
    
    Write-Host "Matched exclusion: '$matchedApp'"
    $appShouldBePublished = $null -eq $matchedApp
    Write-Host "Should publish: $appShouldBePublished"
    
    if ($appShouldBePublished) {
        return $true
    } else {
        Write-Host "Skipping publishing of app $appName as it is in the exclusion list."
        return $false
    }
}

$appFiles = $parameters["appFile"]
if (($appFiles -is [string]) -and (PublishApp -appFile $appFiles)) {
    Write-Host "Single app file detected."
    $filteredAppFiles = $appFiles
} elseif ($appFiles -is [array]) {
    Write-Host "Multiple app files detected."
    $filteredAppFiles = @()
    foreach ($appFile in $appFiles) {
        if (PublishApp -appFile $appFile) {
            $filteredAppFiles += $appFile
        }
    }
}

$parameters["appFile"] = $filteredAppFiles
Publish-BcContainerApp @parameters
