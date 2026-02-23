Param([Hashtable]$parameters)

# Load country-specific app names from generated list
$countryAppsFile = Join-Path $PSScriptRoot "CountrySpecificApps.txt"
$countrySpecificApps = @()
if (Test-Path $countryAppsFile) {
    $countrySpecificApps = Get-Content $countryAppsFile | Where-Object { $_.Trim() -ne "" }
    Write-Host "Loaded $($countrySpecificApps.Count) country-specific app names from exclusion list"
} else {
    Write-Warning "Country-specific apps list not found at: $countryAppsFile"
    Write-Warning "Run build/scripts/GenerateCountryAppsList.ps1 to generate the list"
}

function IsCountrySpecificApp {
    param([string]$appName)
    
    foreach ($countryApp in $countrySpecificApps) {
        # App file names are like: Microsoft_<AppName>_<Version>.app
        if ($appName -like "Microsoft_${countryApp}_*") {
            Write-Host "  Matched country-specific app: $countryApp"
            return $true
        }
    }
    
    return $false
}

function PublishApp() {
    param(
        [string]$appFile
    )

    $listOfAppsNotToPublish = @(
        "Library - No Transactions",
        "Prevent Metadata Updates Library"
    )

    Write-Host "Processing app file: $appFile"
    $appName = (Get-Item $appFile).BaseName
    Write-Host "App BaseName: '$appName'"
    
    # Check if this is a country-specific app (should not be installed in W1 unit tests)
    if (IsCountrySpecificApp -appName $appName) {
        Write-Host "Skipping publishing of app $appName as it is a country-specific app."
        return $false
    }
    
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
