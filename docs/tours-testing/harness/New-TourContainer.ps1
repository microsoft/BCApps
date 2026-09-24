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
    [string] $SecretPath = (Join-Path $env:USERPROFILE ".bc-tours\$ContainerName-credentials.json"),

    # ⚠️ Build selection. The repo's AL-Go `artifact` setting pins a MINIMUM version, and
    # Create-BCContainer uses it unconditionally - so a checkout can resolve to a build that is
    # weeks behind the newest daily. That is fatal for a "tour a recent fix" charter: the fix
    # you came to test may simply not be in the artifact, and the tour then measures the old
    # behaviour and reports it as a side effect.
    #
    # Measured on 2026-09-24: the repo pin resolved to 30.0.54812.0 while the latest W1 insider
    # was 30.0.55076.0 - 264 builds apart.
    #
    # Default is therefore LATEST. Pass -UseRepoPinnedArtifact to get the old behaviour (for
    # example when reproducing something against the exact build the repo targets).
    [switch] $UseRepoPinnedArtifact,

    # Explicit override, wins over both of the above.
    [string] $ArtifactUrl
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

# --- Choose the build -------------------------------------------------------------------
# Resolve and PRINT the artifact before building, so the session sheet can record exactly
# which build was toured. A tour that cannot name its build cannot support any finding.
$repoPinned = Get-CurrentBCArtifactUrl
if (-not $ArtifactUrl) {
    if ($UseRepoPinnedArtifact) {
        $ArtifactUrl = $repoPinned
    } else {
        $ArtifactUrl = Get-BCArtifactUrl -storageAccount bcinsider -type sandbox -country W1 `
                                         -select Latest -accept_insiderEula
    }
}

$pinnedVersion = ($repoPinned  -split '/')[-2]
$chosenVersion = ($ArtifactUrl -split '/')[-2]
Write-Host "Repo-pinned artifact : $repoPinned" -ForegroundColor DarkGray
Write-Host "Using artifact       : $ArtifactUrl" -ForegroundColor Cyan
if ($chosenVersion -ne $pinnedVersion) {
    Write-Host "  (repo pin is $pinnedVersion, this container is $chosenVersion)" -ForegroundColor Yellow
}

# Create-BCContainer calls Get-CurrentBCArtifactUrl unconditionally, so it cannot be pointed at
# a different build. Mirror its body here instead. Setup-ContainerForDevelopment is deliberately
# NOT called: it moves installed apps into the dev scope for AL development, and a tour drives
# the web client rather than compiling against the container.
#
# ⚠️ Push-Location is load-bearing. Get-ConfigValue -ConfigType AL-Go resolves the settings file
# relative to the CURRENT DIRECTORY, not to -BaseFolder, so running this script from anywhere
# but the repo root throws "Cannot bind argument to parameter 'Path' because it is null." In the
# dev-env path that throw lands AFTER the container is built, which silently skips the
# [dbo].[User] readiness gate below - the one check this script exists to guarantee.
Push-Location $BaseFolder
try {
    $memoryLimit = Get-ConfigValue -Key "memoryLimit" -ConfigType AL-Go
} finally {
    Pop-Location
}
if (-not $memoryLimit) { $memoryLimit = "16G" }
$bcContainerHelperConfig.sandboxContainersAreMultitenantByDefault = $false

New-BcContainer -artifactUrl $ArtifactUrl -accept_eula -accept_insiderEula `
    -containerName $ContainerName -auth 'UserPassword' -Credential $credential `
    -includeAL -memoryLimit $memoryLimit `
    -additionalParameters @("--volume ""$($BaseFolder):c:\sources""")

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

