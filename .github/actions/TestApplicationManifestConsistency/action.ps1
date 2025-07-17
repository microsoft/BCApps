function Test-ApplicationManifestConsistency
{
    param(
        [Parameter(Mandatory = $false)]
        [string]$ExpectedAppVersion = (GetApplicationVersion),
        [Parameter(Mandatory = $false)]
        [string]$ExpectedPlatformVersion = (GetPlatformVersion)
    )
    $errors = @()

    $bcAppsManifests = (Get-ChildItem "src" -Recurse -Include app.json).FullName
    foreach($path in $bcAppsManifests)
    {
        $manifest = Get-Content $path | ConvertFrom-Json
        if ($ExpectedAppVersion -ne $manifest.version)
        {
            $errors += "ERROR: Wrong application version in manifest $path. Expected: $ExpectedAppVersion. Actual: $($manifest.version)"
        }
        foreach($item in $manifest.dependencies)
        {
            if ($ExpectedAppVersion -ne $item.version)
            {
                $errors += "ERROR: Wrong dependency version ($($item.name)) in manifest $path. Expected: $ExpectedAppVersion. Actual: $($item.version)"
            }
        }
        if ($manifest.platform -and ($ExpectedPlatformVersion -ne $manifest.platform))
        {
            # If path is under App\BCApps, it means the app in the BCApps repository. In that case, do not fail if platform version do not match, as platform version is uptaken in BCApps at a later stage.
            if($path -like "$env:InetRoot\App\BCApps\*") {
                Write-Host "Skip checking platform version in $path as it is part of the BCApps repository."
            }
            else {
                $errors += "ERROR: Wrong platform version in manifest $path. Expected: $ExpectedPlatformVersion. Actual: $($manifest.platform)"
            }
        }
        if ($manifest.publisher -ne "Microsoft")
        {
            # Allow Partner publisher if path contains 'Partner Test' and is under App\BCApps
            if ($path -like "*Partner Test*" -and $manifest.publisher -eq "Partner")
            {
                Write-Host "Allowing Partner publisher in $path as it contains 'Partner Test' and is under BCApps."
            }
            else
            {
                $errors += "ERROR: Wrong publisher in manifest $path. Expected: Microsoft. Actual: $($manifest.publisher)"
            }
        }
    }

    if ($errors)
    {
        $errors | Write-Host
        throw "Found $($errors.Count) error(s) in application manifest versions"
    }
}

function GetApplicationVersion
{
    Import-Module (Join-Path $PSScriptRoot "..\..\..\build\scripts\EnlistmentHelperFunctions.psm1" -Resolve)
    $repoVersion = Get-ConfigValue -Key "repoVersion" -ConfigType AL-GO
    return "$repoVersion.0.0"
}

function GetPlatformVersion
{
    try {
        if (-not (Get-Module -ListAvailable -Name "BCContainerHelper")) {
            Write-Host "BCContainerHelper module not found. Installing..."
            Install-Module -Name "BCContainerHelper" -Scope CurrentUser -AllowPrerelease -Force
        }
        Import-Module BcContainerHelper
        Import-Module (Join-Path $PSScriptRoot "..\..\..\build\scripts\EnlistmentHelperFunctions.psm1" -Resolve)

        $artifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-GO

        if ($artifactUrl -and $artifactUrl -notlike "http*")
        {
            $repoVersion = Get-ConfigValue -Key "repoVersion" -ConfigType AL-GO

            $artifactUrl = Get-BCArtifactUrl -select Latest -type Sandbox -country base -version $repoVersion -accept_insiderEula
            if (-not $artifactUrl) {
                Get-BCArtifactUrl -select Latest -type Sandbox -country base -version $repoVersion -accept_insiderEula -storageAccount bcinsider
            }
        }

        if (-not $artifactUrl) {
            throw "No artifact URL found. Cannot determine platform version. Using the same as application version."
        }

        $artifactPath = Download-Artifacts -ArtifactUrl $artifactUrl
        $manifest = Get-Content (Join-Path $artifactPath "manifest.json" -Resolve) | ConvertFrom-Json

        # Get the platform version
        [System.Version] $platformVersion = $manifest.platform
        Write-Host "Using platform version: $($platformVersion.Major).$($platformVersion.Minor).0.0"
        return "$($platformVersion.Major).$($platformVersion.Minor).0.0"
    }
    catch {
        Write-Host "Failed to get platform version: $_"
        Write-Host "Using the major.0.0.0 as the platform version."
        [System.Version] $repoVersion = Get-ConfigValue -Key "repoVersion" -ConfigType AL-GO
        return "$($repoVersion.Major).0.0.0"
    }
}

Test-ApplicationManifestConsistency