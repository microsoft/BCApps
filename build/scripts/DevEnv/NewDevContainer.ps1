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
$NewDevContainerModule = "$PSScriptRoot\NewDevContainer.psm1"
$repoVersion = Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go

Copy-FileToBcContainer -containerName $ContainerName -localpath $NewDevContainerModule
Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock { 
    param([string] $DevContainerModule, [System.Version] $RepoVersion, [string] $DatabaseName = "CRONUS") 
    
    Import-Module $DevContainerModule -DisableNameChecking -Force

    $server = Get-NAVServerInstance
    Write-Host "Server: $($server.ServerInstance)" -ForegroundColor Green

    if (-not(Test-NavDatabase -DatabaseName $DatabaseName)) {
        throw "Database $DatabaseName does not exist"
    }

    $installedApps = @(Get-NAVAppInfo -ServerInstance $server.ServerInstance)

    Write-Host "Stopping server instance $($server.ServerInstance)" -ForegroundColor Green
    Stop-NAVServerInstance -ServerInstance $server.ServerInstance

    try {
        $installedApps | ForEach-Object {
            if ($_.Scope -eq 'Global') {
                Write-Host "Moving $($_.Name) to Dev Scope"
                Move-ExtensionIntoDevScope -Name ($_.Name) -DatabaseName $DatabaseName
            }
            if ($_.Version -ne "$($RepoVersion.Major).$($RepoVersion.Minor).0.0") {
                Set-ExtensionVersion -Name ($_.Name) -DatabaseName $DatabaseName -Major $RepoVersion.Major -Minor $RepoVersion.Minor
            }
        }
    } finally {
        Write-Host "Starting server instance $($server.ServerInstance)" -ForegroundColor Green
        Start-NAVServerInstance -ServerInstance $server.ServerInstance
    }

    
} -argumentList $NewDevContainerModule,$repoVersion -usePwsh $false

# Step 3: Set up vscode for development against the container (i.e. set up launch.json and settings.json)
Setup-ModulesSettings -ContainerName $ContainerName -Authentication $Authentification