param(
    [Parameter(Mandatory=$true)]
    [string] $AppProjectFolder,
    [Parameter(Mandatory=$true)]
    [string] $ALGoProjectFolder,
    [Parameter(Mandatory=$true)]
    [string] $BuildMode,
    [Parameter(Mandatory=$true)]
    [string] $AppFile,
    [switch] $IsTestApp
)

# Extract app name from app.json
$appName = (Get-ChildItem -Path $AppProjectFolder -Filter "app.json" | Get-Content | ConvertFrom-Json).name

Write-Host "Current app name: $appName; app folder: $AppProjectFolder"

# Determine the folder where the artifacts for the package will be stored
$holderFolder = 'Apps'
if($IsTestApp) {
    $holderFolder = 'TestApps'
}

$packageArtifactsFolder = "$ALGoProjectFolder/.buildartifacts/$holderFolder/Package/$appName/$BuildMode" # manually construct the artifacts folder

if(-not (Test-Path $packageArtifactsFolder)) {
    Write-Host "Creating $packageArtifactsFolder"
    New-Item -Path "$ALGoProjectFolder" -Name ".buildartifacts/$holderFolder/Package/$appName/$BuildMode" -ItemType Directory | Out-Null
}

Write-Host "Package artifacts folder: $packageArtifactsFolder"

# Add the app file for every built app to a folder for all built modes
Write-Host "Copying app file for app '$appName' from '$AppFile' to build artifacts folder: $packageArtifactsFolder"
Copy-Item -Path $AppFile -Destination $packageArtifactsFolder -Force | Out-Null