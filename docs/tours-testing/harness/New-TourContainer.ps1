<#
    Non-interactive container creation for exploratory tours testing.

    Uses the repo's own Create-BCContainer wrapper (the same code path NewDevEnv.ps1 uses,
    so the artifact is still resolved via Get-CurrentBCArtifactUrl and matches the checkout)
    but supplies a generated credential instead of prompting.

    The password is written to the session artifacts folder, never to the repo.
#>
[CmdletBinding()]
param(
    [string] $ContainerName = 'BCApps-Tours',
    [string] $BaseFolder = 'C:\Users\jonasbl\.copilot\repos\copilot-worktrees\BCApps\jonas-blunck-scaling-guacamole',
    [string] $SecretPath = 'C:\Users\jonasbl\.copilot\session-state\ca19d914-b190-4409-a2c5-2c23c566afcc\files\bc-credentials.json'
)

$ErrorActionPreference = 'Stop'

Import-Module "$BaseFolder\build\scripts\EnlistmentHelperFunctions.psm1" -DisableNameChecking
Import-Module "$BaseFolder\build\scripts\DevEnv\NewDevEnv.psm1" -DisableNameChecking
Import-Module BcContainerHelper -DisableNameChecking

$alphabet = [char[]]((48..57) + (65..90) + (97..122))
$password = (-join (1..20 | ForEach-Object { $alphabet | Get-Random })) + 'Aa1!'

$credential = New-Object System.Management.Automation.PSCredential(
    'admin', (ConvertTo-SecureString $password -AsPlainText -Force))

@{ containerName = $ContainerName; user = 'admin'; password = $password } |
    ConvertTo-Json | Set-Content -Path $SecretPath -Encoding utf8
Write-Host "Credentials written to $SecretPath" -ForegroundColor Yellow

Create-BCContainer -ContainerName $ContainerName -Authentication 'UserPassword' -Credential $credential

Write-Host "Container build: $(Get-BcContainerNavVersion -containerOrImageName $ContainerName)" -ForegroundColor Green
docker logs $ContainerName 2>&1 | Select-String 'Web Client'
