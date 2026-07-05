Param(
    [Hashtable] $parameters
)

Import-Module (Join-Path $PSScriptRoot '../../Shared/PlatformHelper.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../../Shared/EnlistmentHelperFunctions.psm1') -Force

$platformVersion = (Get-ConfigValue -Key "BCPlatform" -ConfigType Packages).Version
if ($platformVersion) {
    Write-Host "Platform version specified: $platformVersion"
    $platformVersion = Resolve-PlatformVersion -Version $platformVersion
    $platformUrl = Get-PlatformVersionUrl -Version $platformVersion
    $parameters.platformArtifactUrl = "$platformUrl/platform"

    Write-Host "Platform artifact URL set to: $($parameters.platformArtifactUrl)"
}