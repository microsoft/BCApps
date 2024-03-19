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

# Move all installed apps into dev scope
$NewDevContainerModule = "$PSScriptRoot\NewDevContainer.psm1"

Copy-FileToBcContainer -containerName $ContainerName -localpath $NewDevContainerModule
Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock { 
    param($DevContainerModule) 
    Import-Module $DevContainerModule -DisableNameChecking

    $DatabaseName = "CRONUS"
    $server = Get-NAVServerInstance

    Write-Host "Server: $($server.ServerInstance)" -ForegroundColor Green

    Test-NavDatabase -DatabaseName $DatabaseName

    $installedApps = @(Get-NAVAppInfo -ServerInstance $server.ServerInstance |
            Where-Object { $_.Scope -eq 'Global' })


    Write-Host "Installed apps: $installedApps" -ForegroundColor Green

    Write-Host "Stopping server instance $($server.ServerInstance)" -ForegroundColor Green
    Stop-NAVServerInstance -ServerInstance $server.ServerInstance

    $installedApps | ForEach-Object {
        Write-Host "Updating $($_.Name)"
        Move-ExtensionIntoDevScope -Name ($_.Name) -DatabaseName $DatabaseName
    }

    Start-NAVServerInstance -ServerInstance $server.ServerInstance
} -argumentList $NewDevContainerModule -usePwsh $false

# Set up the .vscode folder in all modules with the latest settings for development
Setup-ModulesSettings -ContainerName $ContainerName -Authentication $Authentification