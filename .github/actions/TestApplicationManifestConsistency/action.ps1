function Test-ApplicationManifestConsistency
{
    $errors = @()

    $bcAppsManifests = (Get-ChildItem "src" -Recurse -Include app.json).FullName
    $expectedAppVersion = "27.0.0.0"
    $expectedPlatVersion = "27.0.0.0"
    foreach($path in $bcAppsManifests)
    {
        $manifest = Get-Content $path | ConvertFrom-Json
        if ($expectedAppVersion -ne $manifest.version)
        {
            $errors += "ERROR: Wrong application version in manifest $path. Expected: $expectedAppVersion. Actual: $($manifest.version)"
        }
        foreach($item in $manifest.dependencies)
        {
            if ($expectedAppVersion -ne $item.version)
            {
                $errors += "ERROR: Wrong dependency version ($($item.name)) in manifest $path. Expected: $expectedAppVersion. Actual: $($item.version)"
            }
        }
        if ($manifest.platform -and ($expectedPlatVersion -ne $manifest.platform))
        {
            # If path is under App\BCApps, it means the app in the BCApps repository. In that case, do not fail if platform version do not match, as platform version is uptaken in BCApps at a later stage.
            if($path -like "$env:InetRoot\App\BCApps\*") {
                Write-Host "Skip checking platform version in $path as it is part of the BCApps repository."
            }
            else {
                $errors += "ERROR: Wrong platform version in manifest $path. Expected: $expectedPlatVersion. Actual: $($manifest.platform)"
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
        $errors | Write-Log
        throw "Found $($errors.Count) error(s) in application manifest versions"
    }
}

Test-ApplicationManifestConsistency