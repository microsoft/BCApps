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

function Get-ArtifactsCacheFolder($ContainerName) {
    return Join-Path (Get-BaseFolder) "artifacts\$ContainerName"
}

function Get-RulesetPath($Name = "ruleset.json") {
    $rulesetPath = Join-Path (Get-BaseFolder) "src\rulesets\$Name" -Resolve
    return $rulesetPath
}

function Get-BuildMode() {
    if ($ENV:BuildMode) {
        return $ENV:BuildMode
    }
    return 'Default'
}

function Get-CurrentBranch() {
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

function GetPath($Path, $Relative) {
    if ($Relative) {
        return $Path
    }

    return Join-Path (Get-BaseFolder) $Path -Resolve
}

<#
.Synopsis
    Gets the path to the AL-Go settings file
.Parameter Relative
    If specified, the path will be relative to the base folder
.Outputs
    System.String - The path to the AL-Go settings file
#>
function Get-ALGoSettingsPath([switch] $Relative) {
    return GetPath ".github/AL-Go-Settings.json" $Relative
}

<#
.Synopsis
    Gets the path to the Packages file
.Parameter Relative
    If specified, the path will be relative to the base folder
.Outputs
    System.String - The path to the Packages file
#>
function Get-PackagesFilePath([switch] $Relative) {
    return GetPath "build/Packages.json" $Relative
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
        "AL-GO" {
            $ConfigPath = Get-ALGoSettingsPath
        }
        "Packages" {
            $ConfigPath = Get-PackagesFilePath
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
.Returns
    The latest version of the package
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

            $currentBranch = Get-CurrentBranch
            Write-Host "Current branch: $currentBranch"
            $storageAccountOrder = @("bcartifacts", "bcinsider")
            if($currentBranch -eq "main") {
                # Always use bcinsider for baselines for the main branch
                $storageAccountOrder = @("bcinsider")
            }

            $latestArtifactUrl = Get-LatestBCArtifactUrl -minimumVersion $minimumVersion -storageAccountOrder $storageAccountOrder

            if ($latestArtifactUrl -and ($latestArtifactUrl -match "\d+\.\d+\.\d+\.\d+")) {
                $latestVersion = $Matches[0]
            } else {
                throw "Could not find BCArtifact version (for min version: $minimumVersion)"
            }

            return $latestVersion
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
.Parameter StorageAccountOrder
    The order of storage accounts to look for the artifact in
.Returns
    The latest version of the artifact
#>
function Get-LatestBCArtifactUrl
(
    [Parameter(Mandatory=$true)]
    $minimumVersion,
    [Parameter(Mandatory=$false)]
    $storageAccountOrder = @("bcartifacts", "bcinsider")
)
{
    $artifactUrl = Get-BCArtifactUrl -type Sandbox -country base -version $minimumVersion -select Latest -storageAccount $storageAccountOrder[0] -accept_insiderEula

    if(-not $artifactUrl -and $storageAccountOrder.Count -gt 1) {
        #Fallback to the other storage account
        $artifactUrl = Get-BCArtifactUrl -type Sandbox -country base -version $minimumVersion -select Latest -storageAccount $storageAccountOrder[1] -accept_insiderEula
    }

    if(-not $artifactUrl) {
        throw "No artifact found for version $minimumVersion"
    }

    return $artifactUrl
}

<#
.Synopsis
    Updates the BCArtifact version in the AL-Go settings file (artifact property) to the latest version available on the BC artifacts feed (bcinsider/bcartifacts storage account).
.Returns
    The new version of the BCArtifact, if it was updated
#>
function Update-BCArtifactVersion {
    $currentArtifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-Go

    Write-Host "Current BCArtifact URL: $currentArtifactUrl"

    $currentVersion = Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go
    $latestArtifactUrl = Get-LatestBCArtifactUrl -minimumVersion $currentVersion

    Write-Host "Latest BCArtifact URL: $latestArtifactUrl"

    $result = $null
    if($latestArtifactUrl -ne $currentArtifactUrl) {
        Write-Host "Updating BCArtifact version from $currentArtifactUrl to $latestArtifactUrl"
        Set-ConfigValue -Key "artifact" -Value $latestArtifactUrl -ConfigType AL-Go

        $result = $latestArtifactUrl # only return the new version if it was updated
    }

    return $result
}

<#
.Synopsis
    Updates the version of a package in the Packages config file to the latest version available.
.Parameter PackageName
    The name of the package to update
.Returns
    The new version of the package, if it was updated
#>
function Update-PackageVersion
(
    [Parameter(Mandatory=$true)]
    [string] $PackageName
)
{
    $currentPackage = Get-ConfigValue -Key $PackageName -ConfigType Packages
    # Defensively check if the package is not found in the config
    if(!$currentPackage) {
        throw "Package $PackageName not found in Packages config"
    }

    $currentVersion = $currentPackage.Version
    Write-Host "Current $PackageName version: $currentVersion"

    $latestVersion = Get-PackageLatestVersion -PackageName $PackageName
    Write-Host "Latest $PackageName version found: $latestVersion"

    $result = $null
    if ([System.Version] $latestVersion -gt [System.Version] $currentVersion) {
        Write-Host "Updating $PackageName version from $currentVersion to $latestVersion"

        $currentPackage.Version = $latestVersion
        Set-ConfigValue -Key $PackageName -Value $currentPackage -ConfigType Packages

        $result = $latestVersion
    } else {
        Write-Host "$PackageName is already up to date."
    }

    return $result
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
