Param(
    [Hashtable] $parameters
)

Import-Module (Join-Path $PSScriptRoot 'PlatformHelper.psm1') -Force

$platformArtifactUrl = Get-BCPlatformArtifactUrl
if ($platformArtifactUrl) {
    $parameters.platformArtifactUrl = $platformArtifactUrl

    Write-Host "Platform artifact URL set to: $($parameters.platformArtifactUrl)"
}