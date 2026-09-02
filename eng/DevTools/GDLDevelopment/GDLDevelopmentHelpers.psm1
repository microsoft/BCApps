Import-Module "$PSScriptRoot/../../Shared/EnlistmentHelperFunctions.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot/../../Shared/Logger.psm1" -DisableNameChecking

$env:GDLViewsRoot = Join-Path $(Get-BaseFolder) "src\Views\"
$env:GDLLayersRoot = Join-Path $(Get-BaseFolder) "src\Layers\"

function GetLayersRootFolder()
{
    return $env:GDLLayersRoot
}

function GetViewsRootFolder()
{
    return $env:GDLViewsRoot
}

function GetViewFolder([string] $CountryCode)
{
    return Join-Path $env:GDLViewsRoot $CountryCode
}

function GetLayerFolder([string] $CountryCode)
{
    return Join-Path (GetLayersRootFolder) $CountryCode
}

function GetLayerFolderForApplication([string]$CountryCode, [string]$ApplicationName)
{
    return Join-Path (GetLayerFolder -CountryCode $CountryCode) $ApplicationName
}

$ViewInfoFiles= @("layered_view_files.json");
function GetViewInfoFiles()
{
    return $ViewInfoFiles
}

function GetViewInfoFolder([string]$CountryCode)
{
    $viewInfoPath = Join-Path (GetViewFolder -CountryCode $CountryCode) ".view"
    if(!(Test-Path $viewInfoPath))
    {
        $null = mkdir $viewInfoPath
    }

    return $viewInfoPath
}

function GetViewConfigurationFile()
{
    return Join-Path (GetLayersRootFolder) ".config\views_config.json"
}

function GetViewSummaryFile([string]$CountryCode)
{
    return Join-Path (GetViewInfoFolder -CountryCode $CountryCode) "layered_view_files.json"
}

$LayerInfoFiles = @("view_files.json")

function GetLayerInfoFiles()
{
    return $LayerInfoFiles;
}

function GetAllGDLCountryCodes()
{
    return Get-ChildItem (GetLayersRootFolder) -Directory |
        Where-Object { $_.Name -notin @(".config", ".build") } |
        Select-Object -ExpandProperty "Name"
}

function GetAllLayers()
{
    return (GetAllGDLCountryCodes)
}

function GetLayerInfoFolder([string]$CountryCode)
{
    $layerFolderInfoPath = Join-Path (GetLayerFolder -CountryCode $CountryCode) ".layer"
    if(!(Test-Path $layerFolderInfoPath))
    {
        $null = mkdir $layerFolderInfoPath
    }

    return $layerFolderInfoPath
}

function GetViewExclusionFile([string]$CountryCode)
{
    return Join-Path (GetLayerInfoFolder -CountryCode $CountryCode) "excluded_view_files.json"
}

<#
.SYNOPSIS
Analyze a LayerConfig object and extract the list of layers that compose the given view.
Returns a list of country/region codes in the order in which they should be applied.

.PARAMETER LayersConfigObject
A JSON object as seen in views_config.json

.PARAMETER CountryCode
The country code of the view.
#>
function GetLayersForView(
    [Parameter(Mandatory = $true)]
    $LayersConfigObject,

    [Parameter(Mandatory = $true)]
    [string]$CountryCode
)
{
    $result = @();

    if($LayersConfigObject."$CountryCode".baseLayer)
    {
        $result += GetLayersForView -LayersConfigObject $LayersConfigObject -CountryCode $LayersConfigObject."$CountryCode".baseLayer
    }

    $result += @($CountryCode);
    return $result;
}
