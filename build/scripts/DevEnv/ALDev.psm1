Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1" -DisableNameChecking

function GetAssemblyProbingPaths($ContainerName) {
    $netPackages = @()
    $netPackages += @(Get-ChildItem -Path "$($bcContainerHelperConfig.containerHelperFolder)\\Extensions\\$ContainerName\\.netPackages\\Shared\\Microsoft.AspNetCore.App" | Sort-Object -Descending | Select-Object -ExpandProperty FullName)
    $netPackages += @(Get-ChildItem -Path "$($bcContainerHelperConfig.containerHelperFolder)\\Extensions\\$ContainerName\\.netPackages\\Shared\\Microsoft.NETCore.App" | Sort-Object -Descending | Select-Object -ExpandProperty FullName)
    $netPackages += "$($bcContainerHelperConfig.containerHelperFolder)\\Extensions\\$ContainerName\\.netPackages\\Service"
    $netPackages += "$($bcContainerHelperConfig.containerHelperFolder)\\Extensions\\$ContainerName\\.netPackages"

    $assemblyProbingPaths = $netPackages | ForEach-Object { return ($_ -replace '\\', '/') }
    return $assemblyProbingPaths
}

function GetDefaultProjectSettings($ContainerName)
{
    $defaultSettings = GetDefaultSettings -SettingsJson
    $defaultSettings["al.assemblyProbingPaths"] = (GetAssemblyProbingPaths -ContainerName $ContainerName)
    $defaultSettings["al.packageCachePath"] = (Get-ArtifactsCacheFolder -ContainerName $ContainerName)

    # Output the compiled app files into the artifacts cache folder
    $compilationOptions = @{
        "outFolder" = (Get-ArtifactsCacheFolder -ContainerName $ContainerName)
    }
    $defaultSettings["al.compilationOptions"] = $compilationOptions

    return $defaultSettings
}

function MergeSettings($CustomLaunchSettings, $DefaultLaunchSettings) {
    foreach ($propertyName in $DefaultLaunchSettings.Keys)
    {
        if (!$CustomLaunchSettings.ContainsKey($propertyName))
        {
            $CustomLaunchSettings[$propertyName] = $DefaultLaunchSettings[$propertyName]
        }
    }
    return $CustomLaunchSettings
}

function GetDefaultSettings([switch]$LaunchJson, [switch]$SettingsJson)
{
    if ($LaunchJson)
    {
        $DefaultSettingsFile = Join-Path $PSScriptRoot "DefaultLaunchSettings.json" -Resolve
    } elseif($SettingsJson)
    {
        $DefaultSettingsFile = Join-Path $PSScriptRoot "DefaultSettings.json" -Resolve
    } else {
        throw "You must specify either -LaunchJson or -SettingsJson"
    }

    $hashtable = @{}
    $defaultSettings = Get-Content -Path $DefaultSettingsFile -Raw | ConvertFrom-Json
    $defaultSettings.psobject.properties | ForEach-Object { $hashtable[$_.Name] = $_.Value }
    return $hashtable
}

function SetupProjectSettings(
    [string]$VSCodeSettingsFolder,
    [hashtable]$ProjectSettings = @{ }
    )
{
    $projectSettingsPath = Join-Path $VSCodeSettingsFolder "settings.json"
    Set-Content -Path $projectSettingsPath -Value ($ProjectSettings | ConvertTo-Json)
}

function SetupLaunchSettings(
    [string]$VSCodeSettingsFolder,
    [hashtable]$LaunchSettings = @{ }
)
{
    $launchSettingsPath = Join-Path $VSCodeSettingsFolder "launch.json"
    if (Test-Path $launchSettingsPath) {
        $launchConfigurations = Get-Content -Path $launchSettingsPath -Raw | ConvertFrom-Json
    } else {
            $launchConfigurations = @"
{
    "version": "0.2.0",
    "configurations": []
}
"@ | ConvertFrom-Json
    }

    if (($launchConfigurations.configurations.Length -gt 0) -and ($launchConfigurations.configurations.name -eq $LaunchSettings.name))
    {
        $configurationIndex = $launchConfigurations.configurations.name.IndexOf($LaunchSettings.name)
        $launchConfigurations.configurations[$configurationIndex] = $LaunchSettings
    }
    else
    {
        $launchConfigurations.configurations += @($LaunchSettings)
    }

    Set-Content -Path $launchSettingsPath -Value ($launchConfigurations | ConvertTo-Json)
}

<#
.SYNOPSIS
Configure the project and launch settings for the given project.

.PARAMETER ProjectFolder
The path to root folder of the AL project.

.PARAMETER CountryCode
The country code for which the service should be configured.

.PARAMETER LaunchSettings
A hash table containing the settings that should be set in the default launch configuration.

.PARAMETER ProjectSettings
A hash table containing the settings that should be set in the project settings.
#>
function Configure-ALProject(
    [Parameter(Mandatory = $true)]
    [string]$ProjectFolder,
    [Parameter(Mandatory = $false)]
    [string] $ContainerName,
    [Parameter(Mandatory = $false)]
    [string] $Authentication,
    [Parameter(Mandatory = $false)]
    [hashtable] $LaunchSettings = (Get-LaunchSettings -ContainerName $ContainerName -Authentication $Authentication),
    [Parameter(Mandatory = $false)]
    [hashtable] $ProjectSettings = (Get-ProjectSettings -ContainerName $ContainerName)
)
{
    if (!(Test-Path (Join-Path $ProjectFolder "app.json")))
    {
        throw "Could not find an 'app.json' file in $ProjectFolder. Are you sure this is an AL project?"
    }

    # Create the .vscode folder if it does not exist
    $vsCodeFolder = Join-Path $ProjectFolder ".vscode"
    if (!(Test-Path $vsCodeFolder))
    {
        New-Item -Path $vsCodeFolder -ItemType Directory | Out-Null
    }

    SetupProjectSettings -VSCodeSettingsFolder $vsCodeFolder -ProjectSettings $ProjectSettings
    SetupLaunchSettings -VSCodeSettingsFolder $vsCodeFolder -LaunchSettings $LaunchSettings
}

<#
    .SYNOPSIS
    Configures all AL projects in the given path with the given settings.
    .DESCRIPTION
    This function will search for all AL projects in the given path and configure them with the given settings.
    .PARAMETER Path
    The path to the root folder of the projects.
    .PARAMETER ContainerName
    The name of the container to configure the projects for.
    .PARAMETER Authentication
    The authentication method to use when connecting to the container.
    .PARAMETER LaunchSettings
    A hash table containing the settings that should be set in the default launch configuration.
    .PARAMETER ProjectSettings
    A hash table containing the settings that should be set in the project settings.
    .EXAMPLE
    Configure-ALProjectsInPath -Path "C:\Projects" -ContainerName "BC-20210101" -Authentication "Windows"
    .EXAMPLE
    Configure-ALProjectsInPath -Path "C:\Projects" -LaunchSettings @{ "name" = "BC-20210101" } -ProjectSettings @{ "al.ruleSetPath" = "C:\Projects\Ruleset.ruleset" }
#>
function Configure-ALProjectsInPath()
{
    param(
        [Parameter(Mandatory = $false)]
        [string] $Path = (Get-BaseFolder),
        [Parameter(Mandatory = $false)]
        [string] $ContainerName,
        [Parameter(Mandatory = $false)]
        [string] $Authentication,
        [Parameter(Mandatory = $false)]
        [hashtable] $LaunchSettings = (Get-LaunchSettings -ContainerName $ContainerName -Authentication $Authentication),
        [Parameter(Mandatory = $false)]
        [hashtable] $ProjectSettings = (Get-ProjectSettings -ContainerName $ContainerName)
    )

    # Get all module folder paths
    $appFolders = Get-ChildItem $Path -Directory -Recurse | Where-Object { Test-Path (Join-Path $_.FullName app.json) } | ForEach-Object { return $_.FullName }

    $appFolders | ForEach-Object {
        Configure-ALProject -ProjectFolder $_ -ProjectSettings $ProjectSettings -LaunchSettings $LaunchSettings
    }
}

<#
    .SYNOPSIS
    Get the launch settings for the given container.

    .PARAMETER ContainerName
    The name of the container to get the launch settings for.

    .PARAMETER Authentication
    The authentication method to use when connecting to the container.
#>
function Get-LaunchSettings([string] $ContainerName, [string] $Authentication)
{
    $LaunchSettings = @{
        "name"                           = "$ContainerName"
        "server"                         = "http://$ContainerName/BC"
        "authentication"                 = "$Authentication"
    }

    return MergeSettings -CustomLaunchSettings $LaunchSettings -DefaultLaunchSettings (GetDefaultSettings -LaunchJson)
}

<#
    .SYNOPSIS
    Get the project settings for the given container.

    .PARAMETER ContainerName
    The name of the container to get the project settings for.
#>
function Get-ProjectSettings([string] $ContainerName)
{
    $Settings = @{
        "al.ruleSetPath"        = (Get-RulesetPath)
    }

    return MergeSettings -CustomLaunchSettings $Settings -DefaultLaunchSettings (GetDefaultProjectSettings -ContainerName $ContainerName)
}

Export-ModuleMember -Function Configure-ALProjectsInPath
Export-ModuleMember -Function Configure-ALProject
Export-ModuleMember -Function Get-LaunchSettings
Export-ModuleMember -Function Get-ProjectSettings