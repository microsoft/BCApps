<#
    Non-interactive container creation for exploratory tours testing.

    Uses the repo's own Create-BCContainer wrapper (the same code path NewDevEnv.ps1 uses,
    so the artifact is still resolved via Get-CurrentBCArtifactUrl and matches the checkout)
    but supplies a generated credential instead of prompting.

    The password is written outside the repo, to a file named after the container, so
    several tours can run in parallel against separate containers without overwriting
    each other's credentials.

    .EXAMPLE
    # One tour
    .\New-TourContainer.ps1

    .EXAMPLE
    # A second, parallel tour - different container, different credentials file
    .\New-TourContainer.ps1 -ContainerName BCApps-Money
#>
[CmdletBinding()]
param(
    [string] $ContainerName = 'BCApps-Tours',

    # Repo root. Defaults to the checkout this script is running from
    # (<repo>\docs\tours-testing\harness), so a worktree per session just works.
    [string] $BaseFolder = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,

    # Never inside the repo. One file per container.
    [string] $SecretPath = (Join-Path $env:USERPROFILE ".bc-tours\$ContainerName-credentials.json")
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path "$BaseFolder\build\scripts\DevEnv\NewDevEnv.psm1")) {
    throw "-BaseFolder '$BaseFolder' is not a BCApps checkout. Run this script from the repo copy " +
          "(<repo>\docs\tours-testing\harness), or pass -BaseFolder explicitly. The scratch " +
          "working copy cannot resolve the repo root."
}

if (docker ps -a --filter "name=^/$ContainerName$" --format '{{.Names}}') {
    throw "Container '$ContainerName' already exists. Remove it, or pass a different -ContainerName for a parallel tour."
}

Import-Module "$BaseFolder\build\scripts\EnlistmentHelperFunctions.psm1" -DisableNameChecking
Import-Module "$BaseFolder\build\scripts\DevEnv\NewDevEnv.psm1" -DisableNameChecking
Import-Module BcContainerHelper -DisableNameChecking

$alphabet = [char[]]((48..57) + (65..90) + (97..122))
$password = (-join (1..20 | ForEach-Object { $alphabet | Get-Random })) + 'Aa1!'

$credential = New-Object System.Management.Automation.PSCredential(
    'admin', (ConvertTo-SecureString $password -AsPlainText -Force))

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $SecretPath) | Out-Null
@{ containerName = $ContainerName; user = 'admin'; password = $password } |
    ConvertTo-Json | Set-Content -Path $SecretPath -Encoding utf8
Write-Host "Credentials written to $SecretPath" -ForegroundColor Yellow

Create-BCContainer -ContainerName $ContainerName -Authentication 'UserPassword' -Credential $credential

# ⚠️ A half-built container passes every obvious readiness check.
#
# Three separate tours were handed a container that reported `healthy` to docker, served
# HTTP 200 from the web client, and returned the correct build from Get-BcContainerNavVersion
# - while [dbo].[User] was EMPTY, because the build had been interrupted after the service
# tier started but before the tenant was finished. Every probe then failed in a way that
# reads like a product defect rather than a broken environment.
#
# The User table is the cheapest thing that is only populated once the container is genuinely
# usable, so check it explicitly rather than trusting health + HTTP + version.
Write-Host 'Verifying the container is genuinely ready (not just healthy)...' -ForegroundColor Cyan
$userCount = Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
    try {
        (Invoke-Sqlcmd -ServerInstance 'localhost\SQLEXPRESS' -Database 'CRONUS' `
            -Query 'SELECT COUNT(*) AS N FROM [dbo].[User]' -TrustServerCertificate).N
    } catch { -1 }
}
if ($userCount -lt 1) {
    throw "Container '$ContainerName' reports healthy but [dbo].[User] has $userCount rows, so the " +
          "build did not finish. Do NOT tour it - every probe will fail in ways that look like " +
          "product defects. Remove it and rebuild (the artifact cache is warm, so a rebuild is " +
          "minutes, not the full download)."
}
Write-Host "Ready: [dbo].[User] has $userCount row(s)." -ForegroundColor Green

Write-Host "Container build: $(Get-BcContainerNavVersion -containerOrImageName $ContainerName)" -ForegroundColor Green
docker logs $ContainerName 2>&1 | Select-String 'Web Client'

Write-Host ''
Write-Host 'Point this tour''s harness at this container:' -ForegroundColor Cyan
Write-Host "  `$env:BC_CREDS = '$SecretPath'" -ForegroundColor Cyan

