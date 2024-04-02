function Get-BaseFolder() {
    if ($ENV:GITHUB_WORKSPACE) {
        return $ENV:GITHUB_WORKSPACE
    }
    return git rev-parse --show-toplevel
}

function Get-BaseFolderForPath($Path) {
    Push-Location $Path
    $baseFolder = Get-BaseFolder
    Pop-Location
    return $baseFolder
}

function Get-BuildMode() {
    if ($ENV:BuildMode) {
        return $ENV:BuildMode
    }
    return 'Default'
}

function Get-CurrentBranch() {
    if ($ENV:GITHUB_REF) {
        return $ENV:GITHUB_REF.Replace("refs/heads/", "")
    }
    return git rev-parse --abbrev-ref HEAD
}

function Get-PullRequestTargetBranch() {
    if ($ENV:GITHUB_BASE_REF) {
        return $ENV:GITHUB_BASE_REF.Replace("refs/heads/", "")
    }
    return $null
}

<#
.Synopsis
    Creates a new directory if it does not exist. If the directory exists, it will be emptied.
.Parameter Path
    The path of the directory to create
.Parameter ForceEmpty
    If specified, the directory will be emptied if it exists
#>
function New-Directory()
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $Path,
        [switch] $ForceEmpty
    )
    if ($ForceEmpty -and (Test-Path $Path)) {
        Remove-Item -Path $Path -Recurse -Force | Out-Null
    }

    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

<#
.Synopsis
    Get the value of a key from a config file
.Parameter ConfigType
    The type of config file to read from. Can be either "BuildConfig" or "AL-GO", or "Packages".
.Parameter Key
    The key to read the value from
#>
function Get-ConfigValue() {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("BuildConfig","AL-GO","Packages")]
        [string] $ConfigType,
        [Parameter(Mandatory=$true)]
        [string] $Key
    )

    switch ($ConfigType) {
        "BuildConfig" {
            $ConfigPath = Join-Path (Get-BaseFolder) "build/BuildConfig.json" -Resolve
        }
        "AL-GO" {
            $ConfigPath = Join-Path (Get-BaseFolder) ".github/AL-Go-Settings.json" -Resolve
        }
        "Packages" {
            $ConfigPath = Join-Path (Get-BaseFolder) "build/Packages.json" -Resolve
        }
    }

    $BuildConfig = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

    return $BuildConfig.$Key
}

<#
    .Synopsis
        Sets the content of a file, without carriage returns at the end of each line.
    .Description
        This function is similar to Set-Content, but it does not add carriage returns at the end of each line.
        AL-Go uses this function to write JSON files to ensure that the files are consistent across platforms.
    .Parameter Path
        The path of the file to write to
    .Parameter Content
        The content to write to the file
#>
function Set-ContentLF {
    Param(
        [parameter(mandatory = $true, ValueFromPipeline = $false)]
        [string] $Path,
        [parameter(mandatory = $true, ValueFromPipeline = $true)]
        $Content
    )

    Process {
        $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        if ($Content -is [array]) {
            $Content = $Content -join "`n"
        }
        else {
            $Content = "$Content".Replace("`r", "")
        }
        [System.IO.File]::WriteAllText($Path, "$Content`n")
    }

}

<#
.Synopsis
    Sets a config value in a config file
.Parameter ConfigType
    The type of config file to write to. Can be either "BuildConfig" or "AL-GO", or "Packages".
.Parameter Key
    The key to write to
.Parameter Value
    The value to set the key to
#>
function Set-ConfigValue() {
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("BuildConfig","AL-GO", "Packages")]
        [string]$ConfigType = "AL-GO",
        [Parameter(Mandatory=$true)]
        [string]$Key,
        [Parameter(Mandatory=$true)]
        $Value
    )

    switch ($ConfigType) {
        "BuildConfig" {
            $ConfigPath = Join-Path (Get-BaseFolder) "build/BuildConfig.json" -Resolve
        }
        "AL-GO" {
            $ConfigPath = Join-Path (Get-BaseFolder) ".github/AL-Go-Settings.json" -Resolve
        }
        "Packages" {
            $ConfigPath = Join-Path (Get-BaseFolder) "build/Packages.json" -Resolve
        }
    }

    $BuildConfig = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    $BuildConfig.$Key = $Value
    $BuildConfig | ConvertTo-Json -Depth 100 | Set-ContentLF -Path $ConfigPath
}

<#
.Synopsis
    Gets the latest version of a package from a NuGet.org feed based on the repo version.
.Description
    The function will look for the latest version of the package that matches the `repoVersion` setting.
    For example, if the repo version is 1.2, the function will look for the latest version of the package that has major.minor = 1.2.
.Parameter PackageName
    The name of the package
#>
function Get-PackageLatestVersion() {
    param(
        [Parameter(Mandatory=$true)]
        [string] $PackageName
    )

    $package = Get-ConfigValue -Key $PackageName -ConfigType Packages
    if(!$package) {
        throw "Package $PackageName not found in Packages config"
    }

    [System.Version] $majorMinorVersion = Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go

    switch($package.Source)
    {
        'NuGet.org' {
            $maxVersion = "$majorMinorVersion.99999999.99" # maximum version for the given major/minor

            $packageSource = "https://api.nuget.org/v3/index.json" # default source
            $latestVersion = (Find-Package $PackageName -Source $packageSource -MaximumVersion $maxVersion -AllVersions | Sort-Object -Property Version -Descending | Select-Object -First 1).Version

            return $latestVersion
        }
        'BCArtifacts' {
            # BC artifacts works with minimum version
            $minimumVersion = $majorMinorVersion

            if ($PackageName -eq "AppBaselines-BCArtifacts") {
                # For app baselines, use the previous minor version as minimum version
                if ($majorMinorVersion.Minor -gt 0) {
                    $minimumVersion = "$($majorMinorVersion.Major).$($majorMinorVersion.Minor - 1)"
                } else {
                    $minimumVersion = "$($majorMinorVersion.Major - 1)"
                }
            }

            return Get-LatestBCArtifactVersion -minimumVersion $minimumVersion
        }
        default {
            throw "Unknown package source: $($package.Source)"
        }
    }
}

<#
.Synopsis
    Gets the current version of a package from the Packages config file
.Parameter PackageName
    The name of the package to get the version for
.Returns
    The current version of the package
#>
function Get-CurrentPackageVersion {
    param(
        [Parameter(Mandatory=$true)]
        [string] $PackageName
    )

    $package = Get-ConfigValue -Key $PackageName -ConfigType Packages
    if(!$package) {
        throw "Package $PackageName not found in Packages config"
    }

    return $package.Version
}

<#
.Synopsis
    Updates the version of a package in the Packages config file to the latest version available.
.Parameter PackageName
    The name of the package to update
.Returns
    The new version of the package, if it was updated
#>
function Update-PackageVersion {
    param(
        [Parameter(Mandatory=$true)]
        [string] $PackageName
    )

    $updatesAvailable = $false
    $currentVersion = Get-CurrentPackageVersion -PackageName $PackageName
    $latestVersion = Get-PackageLatestVersion -PackageName $PackageName

    if ([System.Version] $latestVersion -gt [System.Version] $currentVersion) {
        Write-Host "Updating $PackageName version from $currentVersion to $latestVersion"

        $package = Get-ConfigValue -Key $PackageName -ConfigType Packages
        $package.Version = $latestVersion

        Set-ConfigValue -Key $PackageName -Value $package -ConfigType Packages

        $updatesAvailable = $true
    } else {
        Write-Host "$PackageName is already up to date. Version: $currentVersion"
    }

    if($updatesAvailable) {
        return $latestVersion
    }
}

<#
.Synopsis
    Gets the current version of a BC artifact
.Returns
    The current version of the BC artifact
#>
function Get-CurrentBCArtifactVersion {
    $artifactValue = Get-ConfigValue -Key "artifact" -ConfigType AL-Go
    if ($artifactValue -and ($artifactValue -match "\d+\.\d+\.\d+\.\d+")) {
        return $Matches[0]
    } else {
        throw "Could not find BCArtifact version: $artifactValue"
    }
}

<#
.Synopsis
    Gets the latest version of a BC artifact
.Parameter MinimumVersion
    The minimum version of the artifact to look for
.Returns
    The latest version of the artifact
#>
function Get-LatestBCArtifactVersion
(
    [Parameter(Mandatory=$true)]
    $minimumVersion
)
{
    $artifactUrl = Get-BCArtifactUrl -type Sandbox -country base -version $minimumVersion -select Latest

    if(-not $artifactUrl) {
        #Fallback to bcinsider
        $artifactUrl = Get-BCArtifactUrl -type Sandbox -country base -version $minimumVersion -select Latest -storageAccount bcinsider -accept_insiderEula
    }

    if ($artifactUrl -and ($artifactUrl -match "\d+\.\d+\.\d+\.\d+")) {
        $latestVersion = $Matches[0]
    } else {
        throw "Could not find BCArtifact version (for min version: $minimumVersion)"
    }

    return $latestVersion
}

<#
.Synopsis
    Updates the BCArtifact version in the AL-Go settings file (artifact property) to the latest version available on the BC artifacts feed (bcinsider/bcartifacts storage account).
.Returns
    The new version of the BCArtifact, if it was updated
#>
function Update-BCArtifactVersion {
    $currentArtifactVersion = Get-CurrentBCArtifactVersion

    Write-Host "Current BCArtifact version: $currentArtifactVersion"

    $currentVersion = Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go
    $latestArtifactVersion = Get-LatestBCArtifactVersion -minimumVersion $currentVersion

    Write-Host "Latest BCArtifact version: $latestArtifactVersion"

    if($latestArtifactVersion -gt $currentArtifactVersion) {
        Write-Host "Updating BCArtifact version from $currentArtifactVersion to $latestArtifactVersion"

        $artifactValue = Get-ConfigValue -Key "artifact" -ConfigType AL-Go
        $artifactValue = $artifactValue -replace $currentArtifactVersion, $latestArtifactVersion
        Set-ConfigValue -Key "artifact" -Value $artifactValue -ConfigType AL-Go

        return $latestArtifactVersion
    }
}

<#
.Synopsis
    Installs a package from a NuGet.org feed
.Parameter PackageName
    The name of the package to install
.Parameter OutputPath
    The path to install the package to
.Parameter PackageVersion
    The version of the package to install. If not specified, the version will be read from the Packages config
.Returns
    The path to the installed package
#>
function Install-PackageFromConfig
(
    [Parameter(Mandatory=$true)]
    [string] $PackageName,
    [Parameter(Mandatory=$true)]
    [string] $OutputPath,
    [switch] $Force
) {
    $packageConfig = Get-ConfigValue -Key $PackageName -ConfigType Packages

    if(!$packageConfig) {
        throw "Package $PackageName not found in Packages config"
    }

    if($packageConfig.Source -ne 'NuGet.org') {
        throw "Package $PackageName is not from NuGet.org"
    }

    $packageVersion = $packageConfig.Version

    $packageSource = "https://api.nuget.org/v3/index.json" # default source

    $packagePath = Join-Path $OutputPath "$PackageName.$packageVersion"

    if((Test-Path $packagePath) -and !$Force) {
        Write-Host "Package $PackageName is already installed; version: $packageVersion"
        return $packagePath
    }

    $package = Find-Package $PackageName -Source $packageSource -RequiredVersion $packageVersion
    if(!$package) {
        throw "Package $PackageName not found; source $packageSource. Version: $packageVersion"
    }

    Write-Host "Installing package $PackageName; source $packageSource; version: $packageVersion; destination: $OutputPath"
    Install-Package $PackageName -Source $packageSource -RequiredVersion $packageVersion -Destination $OutputPath -Force | Out-Null

    return $packagePath
}

<#
.SYNOPSIS
Run an executable and check the exit code
.EXAMPLE
RunAndCheck git checkout -b xxx
#>
function RunAndCheck {
    $ErrorActionPreference = 'Continue'
    $rest = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { $null }
    & $args[0] $rest
    if ($LASTEXITCODE -ne 0) {
        throw "$($args[0]) $($rest | ForEach-Object { $_ }) failed with exit code $LASTEXITCODE"
    }
}

Export-ModuleMember -Function *-*
Export-ModuleMember -Function RunAndCheck