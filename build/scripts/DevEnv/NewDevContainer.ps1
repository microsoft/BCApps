[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] $ContainerName = "BC-$(Get-Date -Format 'yyyyMMdd')",
    [Parameter(Mandatory = $false)]
    [ValidateSet('Windows', 'UserPassword')]
    [string] $Authentification = "Windows"
)

Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\ALDev.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\NewDevContainer.psm1" -DisableNameChecking

# Step 1: Create a container if it does not exist
$containerExists = Get-BcContainers | Where-Object { $_ -eq $ContainerName }

if (-not $containerExists)
{
    # Get artifactUrl from branch
    $artifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-Go

    # Create a new container with a single tenant
    $bcContainerHelperConfig.sandboxContainersAreMultitenantByDefault = $false
    New-BcContainer -artifactUrl $artifactUrl -accept_eula -accept_insiderEula -containerName $ContainerName -auth $Authentification -includeAL
} else {
    Write-Host "Container $ContainerName already exists. Skipping creation." -ForegroundColor Yellow
}

# Step 2: Move all installed apps to the dev scope
# By default, the container is created with the global scope. We need to move all installed apps to the dev scope.
Setup-ContainerForDevelopment -ContainerName $ContainerName -RepoVersion (Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go)

# Step 3: Set up vscode for development against the container (i.e. set up launch.json and settings.json)
Setup-ModulesSettings -ContainerName $ContainerName -Authentication $Authentification