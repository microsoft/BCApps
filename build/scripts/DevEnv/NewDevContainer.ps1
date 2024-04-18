[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] $ContainerName = "BC-$(Get-Date -Format 'yyyyMMdd')",
    [Parameter(Mandatory = $false)]
    [ValidateSet('Windows', 'UserPassword')]
    [string] $Authentication = "UserPassword",
    [Parameter(Mandatory = $false)]
    [switch] $SkipVsCodeSetup,
    [Parameter(Mandatory = $false, ParameterSetName = 'ProjectPaths')]
    [string[]] $ProjectPaths,
    [Parameter(Mandatory = $false, ParameterSetName = 'WorkspacePath')]
    [string] $WorkspacePath,
    [Parameter(Mandatory = $false, ParameterSetName = 'ALGoProject')]
    [string] $AlGoProject
)

Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\ALDev.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\NewDevContainer.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\NewDevEnv.psm1" -DisableNameChecking

$credential = Get-CredentialForContainer -AuthenticationType $Authentication

# Step 1: Create a container if it does not exist
if (-not (Test-ContainerExists -ContainerName $ContainerName))
{
    # Get artifactUrl from branch
    $artifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-Go

    # Create a new container with a single tenant
    $bcContainerHelperConfig.sandboxContainersAreMultitenantByDefault = $false
    New-BcContainer -artifactUrl $artifactUrl -accept_eula -accept_insiderEula -containerName $ContainerName -auth $Authentication -Credential $credential -includeAL
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
    $appFiles = Build-Apps -ProjectPaths $ProjectPaths -packageCacheFolder (Get-ArtifactsCacheFolder -ContainerName $ContainerName)

    Write-Host "Publishing apps..." -ForegroundColor Yellow
    Publish-Apps -ContainerName $ContainerName -AppFiles $appFiles -Credential $credential
}