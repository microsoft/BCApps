function Get-BaseFolder() {
    if ($ENV:GITHUB_WORKSPACE) {
        return $ENV:GITHUB_WORKSPACE
    }
    return git rev-parse --show-toplevel
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
    $BuildConfig | ConvertTo-Json -Depth 100 | Set-Content -Path $ConfigPath
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
    Gets the latest version of a BC artifact
.Parameter MinimumVersion
    The minimum version of the artifact to look for
#>
function Get-LatestBCArtifactVersion
(
    [Parameter(Mandatory=$true)]
    $minimumVersion
)
{
    $latestVersion = Get-BCArtifactVersion -StorageAccount bcartifacts -MinimumVersion $minimumVersion
    if(-not $latestVersion) {
        #Fallback to bcinsider
        $latestVersion = Get-BCArtifactVersion -StorageAccount bcinsider -MinimumVersion $minimumVersion
    }

    if(-not $latestVersion) {
        throw "Could not find BCArtifact version (for min version: $minimumVersion)"
    }

    return $latestVersion
}


<#
.Synopsis
    Gets the URL or version of a BC artifact
.Parameter StorageAccount
    The storage account to look for the artifact in. Can be either "bcartifacts" or "bcinsider"
.Parameter MinimumVersion
    The minimum version of the artifact to look for
.Parameter Type
    The type of artifact to look for. Can be either "SandBox" or "OnPrem"
.Parameter Country
    The country of the artifact to look for. Can be either "base" or a country code
.Parameter Select
    The select parameter to use when looking for the artifact. Can be either "Latest" or "All"
.Parameter After
    The date to look for artifacts after. Default is 90 days ago
.Parameter ReturnUrl
    If specified, the function will return the URL of the artifact. Otherwise, it will return the version of the artifact    
#>
function Get-BCArtifactVersion(
    [Parameter(Mandatory=$true)]
    [ValidateSet("bcartifacts","bcinsider")]
    [string] $StorageAccount,
    [Parameter(Mandatory=$true)]
    [string] $MinimumVersion,
    [Parameter(Mandatory=$false)]
    [string] $Type = "SandBox",
    [Parameter(Mandatory=$false)]
    [string] $Country = "base",
    [Parameter(Mandatory=$false)]
    $Select = "Latest",
    [Parameter(Mandatory=$false)]
    $After = ((Get-Date).AddDays(-90)),
    [Parameter(Mandatory=$false)]
    [switch] $ReturnUrl
) {
    $artifactUrl = Get-BCArtifactUrl -type $Type -country $Country -version $MinimumVersion -select $Select -storageAccount $StorageAccount -accept_insiderEula -after $After
    
    if ($artifactUrl) {
        if ($ReturnUrl) {
            return $artifactUrl
        } elseif($artifactUrl -match "\d+\.\d+\.\d+\.\d+") {
            return $Matches[0]
        }
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