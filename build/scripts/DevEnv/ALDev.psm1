function GetDefaultProjectSettings()
{
    # These settings must be kept in sync with GetAssemblyProbingFolders from ALDev.psm1 until
    # we find a better solution
    $packageCachePath = "C:\Users\aholstrup\Documents\GitHub\Microsoft\BCApps\.artifactsCache" #Get-AllExtensionsFolder -CountryCode $CountryCode
    $assemblyProbingPaths = @("C:\\ProgramData\\BcContainerHelper\\Extensions\\Test\\.netPackages\\Shared",
                            "C:\\ProgramData\\BcContainerHelper\\Extensions\\Test\\.netPackages\\Service",
                            "C:\\ProgramData\\BcContainerHelper\\Extensions\\Test\\.netPackages") | ForEach-Object { return ($_ -replace '\\', '/') }

    return @{
        "editor.codeLens"         = $false
        "al.assemblyProbingPaths" = $assemblyProbingPaths
        "al.packageCachePath"     = "$($packageCachePath -replace '\\', '/')"
        "al.enableCodeActions"    = $false
        "al.incrementalBuild"     = $true
        "al.enableCodeAnalysis"   = $true
        "al.codeAnalyzers"        = @('${CodeCop}', '${AppSourceCop}', '${PerTenantExtensionCop}', '${UICop}')
        "editor.formatOnSave"   = $true
        "[al]" = @{
            "editor.semanticHighlighting.enabled" = $true
        }
    }
}

function SetupProjectSettings(
    [string]$VSCodeSettingsFolder,
    [switch]$ResetConfiguration,
    [hashtable]$ProjectSettings = @{ })
{
    $projectSettingsPath = Join-Path $VSCodeSettingsFolder "settings.json"
    if ((Test-Path $projectSettingsPath) -and !$ResetConfiguration)
    {
        $existingSettings = Get-Content -Path $projectSettingsPath -Raw | ConvertFrom-Json
        foreach ($property in $existingSettings.PSObject.Properties)
        {
            if (!$ProjectSettings.ContainsKey($property.Name))
            {
                $ProjectSettings[$property.Name] = $property.Value
            }
        }
    }
    else 
    {
        [hashtable]$defaultSettings = GetDefaultProjectSettings
        foreach ($propertyName in $defaultSettings.Keys)
        {
            if (!$ProjectSettings.ContainsKey($propertyName))
            {
                $ProjectSettings[$propertyName] = $defaultSettings[$propertyName]
            }
        }
    }

    Set-Content -Path $projectSettingsPath -Value ($ProjectSettings | ConvertTo-Json)
}


function SetupLaunchSettings(
    [string]$VSCodeSettingsFolder,
    [switch]$ResetConfiguration,
    [hashtable]$LaunchSettings = @{ }
)
{
    $launchConfigurations = @"
{
    "version": "0.2.0",
    "configurations": []   
}
"@ | ConvertFrom-Json

    $launchSettingsPath = Join-Path $vsCodeFolder "launch.json"
    if ((Test-Path $launchSettingsPath) -and !$ResetConfiguration)
    {
        $launchConfigurations = Get-Content -Path $launchSettingsPath -Raw | ConvertFrom-Json
        $existingLaunchConfiguration = $launchConfigurations.configurations[0]
        foreach ($property in $existingLaunchConfiguration.PSObject.Properties)
        {
            if (!$LaunchSettings.ContainsKey($property.Name))
            {
                $LaunchSettings[$property.Name] = $property.Value
            }
        }

        # Set the server instance if it is not present in the existing configuration.
        if (!$LaunchSettings["serverInstance"])
        {
            $LaunchSettings["serverInstance"] = "BC"
        }
    }
    else 
    {
        # Set the server instance to our best guess if it has not been set before.
        # We do this here instead of doing it in the Get-DefaultLaunchSettings because the call to get the server settings
        # is expensive and we do not want to do this call if it is not needed.
        if (!$LaunchSettings["serverInstance"])
        {
            $LaunchSettings["serverInstance"] = "BC"
        }

        [hashtable]$defaultLaunchSettings = Get-DefaultLaunchSettings
        foreach ($propertyName in $defaultLaunchSettings.Keys)
        {
            if (!$LaunchSettings.ContainsKey($propertyName))
            {
                $LaunchSettings[$propertyName] = $defaultLaunchSettings[$propertyName]
            }
        }
    }

    if ($launchConfigurations.configurations.Length -gt 0)
    {
        $launchConfigurations.configurations[0] = $LaunchSettings
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

.PARAMETER ResetConfiguration
Set this flag if the configuration should be completely overwritten.

.PARAMETER LaunchSettings
A hash table containing the settings that should be set in the default launch configuration.

.PARAMETER ProjectSettings
A hash table containing the settings that should be set in the project settings.
#>
function Configure-ALProject(
    [Parameter(Mandatory = $true)]
    [string]$ProjectFolder,
    [switch]$ResetConfiguration,
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

    SetupProjectSettings $vsCodeFolder -ProjectSettings $ProjectSettings -ResetConfiguration:$ResetConfiguration
    SetupLaunchSettings $vsCodeFolder -LaunchSettings $LaunchSettings -ResetConfiguration:$ResetConfiguration
}

function Get-AppFolders($Path) {
    return Get-ChildItem $Path -Directory -Recurse | Where-Object { Test-Path (Join-Path $_.FullName app.json) } | ForEach-Object { return $_.FullName }
}

<#
.SYNOPSIS
Sets up the .vscode folder in all modules with the latest settings for development.
#>
function Setup-ModulesSettings([string] $AppRootFolder = (Get-BaseFolder), [string] $RulesetPath, [string] $ContainerName, [string] $Authentication)
{
    $RulesetPath = $RulesetPath -replace '\\', '/'

    # Get all module folder paths
    $appFolders = Get-AppFolders -Path $AppRootFolder

    $Settings = @{
        "al.ruleSetPath"        = $RulesetPath
    }

    $LaunchSettings = @{
        "name"                           = "$ContainerName"
        "server"                         = "http://$ContainerName/BC"
        "authentication"                 = "$Authentication"
    }

    $appFolders | ForEach-Object {
        Configure-ALProject -ProjectFolder $_ -ResetConfiguration -ProjectSettings $Settings -LaunchSettings $LaunchSettings
    }
}

function Get-DefaultLaunchSettings
{
    $hashtable = @{}
    $defaultLaunchSettings = Get-Content -Path (Join-Path $PSScriptRoot "DefaultLaunchSettings.json") -Raw | ConvertFrom-Json
    $defaultLaunchSettings.psobject.properties | ForEach-Object { $hashtable[$_.Name] = $_.Value }
    return $hashtable
}

Export-ModuleMember -Function *-*