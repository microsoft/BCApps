<#
    .SYNOPSIS
    Creates a new development environment with a new container, sets up vscode for development against the container, and optionally builds and publishes apps.
    .DESCRIPTION
    This script creates a new development environment with a new container, sets up vscode for development against the container, and optionally builds and publishes apps.
    .PARAMETER ContainerName
    The name of the container to create. The default value is "BC-$(Get-Date -Format 'yyyyMMdd')".
    .PARAMETER Authentication
    The authentication type to use when creating the container. The default value is "UserPassword".
    .PARAMETER SkipVsCodeSetup
    If specified, vscode will not be set up for development against the container.
    .PARAMETER ProjectPaths
    The paths to the AL projects to build and publish. This parameter is mutually exclusive with the WorkspacePath and AlGoProject parameters.
    .PARAMETER WorkspacePath
    The path to the workspace containing the AL projects to build and publish. This parameter is mutually exclusive with the ProjectPaths and AlGoProject parameters.
    .PARAMETER AlGoProject
    The name of the AL-Go project to build and publish. This parameter is mutually exclusive with the ProjectPaths and WorkspacePath parameters.
    .PARAMETER RebuildApps
    If specified, the apps will be force rebuilt before publishing even if they exist.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] $ContainerName = "BC-$(Get-Date -Format 'yyyyMMdd')",
    [Parameter(Mandatory = $false)]
    [ValidateSet('Windows', 'UserPassword')]
    [string] $Authentication = "UserPassword",
    [Parameter(Mandatory = $false)]
    [switch] $SkipVsCodeSetup,
    [Parameter(Mandatory = $false)]
    [string[]] $ProjectPaths,
    [Parameter(Mandatory = $false)]
    [string] $WorkspacePath,
    [Parameter(Mandatory = $false)]
    [string] $AlGoProject,
    [Parameter(Mandatory = $false)]
    [switch] $RebuildApps
)

Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\ALDev.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\NewDevContainer.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\NewDevEnv.psm1" -DisableNameChecking
Import-Module BcContainerHelper

$baseFolder = (Get-BaseFolderForPath -Path $PSScriptRoot)
Push-Location $baseFolder

$credential = Get-CredentialForContainer -AuthenticationType $Authentication

# Step 1: Create a container if it does not exist
if (-not (Test-ContainerExists -ContainerName $ContainerName))
{
    # Get artifactUrl from branch
    $artifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-Go

    # Create a new container with a single tenant
    $bcContainerHelperConfig.sandboxContainersAreMultitenantByDefault = $false
    New-BcContainer -artifactUrl $artifactUrl -accept_eula -accept_insiderEula -containerName $ContainerName -auth $Authentication -Credential $credential -includeAL -additionalParameters @("--volume ""$($baseFolder):c:\sources""")
} else {
    Write-Host "Container $ContainerName already exists. Skipping creation." -ForegroundColor Yellow
}

# Step 2: Move all installed apps to the dev scope
# By default, the container is created with the global scope. We need to move all installed apps to the dev scope.
Setup-ContainerForDevelopment -ContainerName $ContainerName -RepoVersion (Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go)

if (-not $SkipVsCodeSetup)
{
    # Step 3: Set up vscode for development against the container (i.e. set up launch.json and settings.json)
    Configure-ALProjectsInPath -ContainerName $ContainerName -Authentication $Authentication
}

# Step 4: (Optional) Build the apps
if ($ProjectPaths -or $WorkspacePath -or $AlGoProject)
{
    # Resolve AL project paths
    $ProjectPaths = Resolve-ProjectPaths -ProjectPaths $ProjectPaths -WorkspacePath $WorkspacePath -AlGoProject $AlGoProject

    # Build apps
    Write-Host "Building apps..." -ForegroundColor Yellow
    $appFiles = Build-Apps -ProjectPaths $ProjectPaths -packageCacheFolder (Get-ArtifactsCacheFolder -ContainerName $ContainerName) -rebuild:$RebuildApps

    # Publish apps
    if ($appFiles) {
        Write-Host "Publishing apps..." -ForegroundColor Yellow
        Publish-Apps -ContainerName $ContainerName -AppFiles $appFiles -Credential $credential
    }
}