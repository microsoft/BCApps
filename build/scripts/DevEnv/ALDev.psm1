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
    $defaultSettings["al.packageCachePath"] = (Get-ArtifactsCacheFolder)

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
    [hashtable]$ProjectSettings = @{ },
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
    [hashtable]$LaunchSettings = @{ },
    [hashtable]$ProjectSettings = @{ }
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
    Sets up the .vscode folder in all modules with the latest settings for development.
    .DESCRIPTION
    This function will go through all modules in the given folder and set up the .vscode folder with the latest settings for development.
    .PARAMETER AppRootFolder
    The root folder of the app.
    .PARAMETER RulesetPath
    The path to the ruleset file.
    .PARAMETER ContainerName
    The name of the container to use for the development.
    .PARAMETER Authentication
    The authentication method to use for the development.
#>
function Setup-ModulesSettings([string] $AppRootFolder = (Get-BaseFolder), [string] $RulesetPath = (Get-RulesetPath), [string] $ContainerName, [string] $Authentication)
{
    # Get all module folder paths
    $appFolders = Get-ChildItem $Path -Directory -Recurse | Where-Object { Test-Path (Join-Path $_.FullName app.json) } | ForEach-Object { return $_.FullName }

    $Settings = @{
        "al.ruleSetPath"        = $RulesetPath
    }

    $LaunchSettings = @{
        "name"                           = "$ContainerName"
        "server"                         = "http://$ContainerName/BC"
        "authentication"                 = "$Authentication"
    }

    # Get configuration for launch.json
    $LaunchSettings = MergeSettings -CustomLaunchSettings $LaunchSettings -DefaultLaunchSettings (GetDefaultSettings -LaunchJson)

    # Get settings for setting.json
    $Settings = MergeSettings -CustomLaunchSettings $Settings -DefaultLaunchSettings (GetDefaultProjectSettings -ContainerName $ContainerName)

    $appFolders | ForEach-Object {
        Configure-ALProject -ProjectFolder $_ -ProjectSettings $Settings -LaunchSettings $LaunchSettings
    }
}

Export-ModuleMember -Function *-*