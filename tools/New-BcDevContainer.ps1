#Requires -Modules BcContainerHelper

[CmdletBinding()]
param(
    [string] $SettingsPath = (Join-Path $PSScriptRoot '..\.github\AL-Go-Settings.json'),
    [string] $BranchName,
    [pscredential] $Credential = (New-Object pscredential 'admin', (ConvertTo-SecureString 'Password123!' -AsPlainText -Force))
)

$ErrorActionPreference = 'Stop'

# Read artifact setting from AL-Go settings
$settings = Get-Content -Path $SettingsPath -Raw | ConvertFrom-Json
$artifactSetting = $settings.artifact
if (-not $artifactSetting) {
    throw "No 'artifact' setting found in $SettingsPath"
}

# Expected format: <storageAccount>/<type>/<version>/<country>/<select>
$parts = $artifactSetting.Split('/')
$storageAccount = $parts[0]
$type           = $parts[1]
$version        = $parts[2]
# Override country from settings: always use W1 for this script
$country        = 'w1'
$select         = if ($parts[4]) { $parts[4] } else { 'Latest' }

Write-Host "Resolving artifact: account=$storageAccount type=$type version=$version country=$country select=$select"

$artifactUrl = Get-BCArtifactUrl `
    -storageAccount $storageAccount `
    -type $type `
    -version $version `
    -country $country `
    -select $select `
    -accept_insiderEula

if (-not $artifactUrl) {
    throw "Could not resolve artifact URL for setting '$artifactSetting'"
}
Write-Host "Artifact URL: $artifactUrl"

# Derive container name from current git branch (max 10 chars, sanitized)
if (-not $BranchName) {
    try {
        $BranchName = (& git -C $PSScriptRoot rev-parse --abbrev-ref HEAD).Trim()
    } catch {
        $BranchName = 'devbranch'
    }
}

# Take the last segment after '/', strip non-alphanumerics, lowercase, cap at 10 chars
$lastSegment = ($BranchName -split '/')[-1]
$sanitized   = ($lastSegment -replace '[^a-zA-Z0-9]', '').ToLowerInvariant()
if (-not $sanitized) { $sanitized = 'devcontainer' }
$containerName = $sanitized.Substring(0, [Math]::Min(10, $sanitized.Length))

Write-Host "Container name: $containerName (from branch '$BranchName')"

if (Test-BcContainer -containerName $containerName) {
    Write-Host "Container '$containerName' already exists - skipping creation."
} else {
    $hostPort = $env:COPILOT_PORT
    if (-not $hostPort) {
        $hostPort = Get-Random -Minimum 8000 -Maximum 9000
        Write-Host "COPILOT_PORT not set - using random host port $hostPort"
    } else {
        Write-Host "Using COPILOT_PORT=$hostPort as host port"
    }

    $additionalParameters = @("--publish $($hostPort):80")
    Write-Host "Publishing container port 80 to localhost:$hostPort"

    New-BcContainer `
        -accept_eula `
        -accept_insiderEula `
        -containerName $containerName `
        -artifactUrl $artifactUrl `
        -auth UserPassword `
        -Credential $Credential `
        -additionalParameters $additionalParameters

    Write-Host "Web client available at http://localhost:$hostPort/BC/?tenant=default"
}

# Move all globally-scoped apps to Dev scope and align versions to the repo
$devContainerModule = Join-Path $PSScriptRoot '..\build\scripts\DevEnv\NewDevContainer.psm1'
if (Test-Path $devContainerModule) {
    Import-Module $devContainerModule -Force
    $repoVersion = [version]$version
    Write-Host "Setting up container '$containerName' for development (RepoVersion=$($repoVersion.Major).$($repoVersion.Minor))"
    Setup-ContainerForDevelopment -ContainerName $containerName -RepoVersion $repoVersion
} else {
    Write-Warning "Dev container helper module not found at $devContainerModule - skipping dev-scope move."
}

# Copy .app files from the artifact cache into the worktree
$repoRoot     = Resolve-Path (Join-Path $PSScriptRoot '..')
$cacheBase    = Join-Path 'C:\bcartifacts.cache' "sandbox\$version"
$cacheTarget  = Join-Path $repoRoot '.artifactsCache'

$cacheSources = @(
    (Join-Path $cacheBase $country),                                                       # country apps (e.g. w1)
    (Join-Path $cacheBase 'platform\ModernDev\PFiles\Microsoft Dynamics NAV\290\AL Development Environment') # System.app
)

if (-not (Test-Path $cacheTarget)) {
    New-Item -ItemType Directory -Path $cacheTarget | Out-Null
}

foreach ($src in $cacheSources) {
    if (Test-Path $src) {
        Write-Host "Copying .app files from $src to $cacheTarget"
        Get-ChildItem -Path $src -Filter *.app -Recurse |
            Copy-Item -Destination $cacheTarget -Force
    } else {
        Write-Warning "Artifact source not found: $src"
    }
}
Write-Host "Total .app files in cache: $((Get-ChildItem -Path $cacheTarget -Filter *.app).Count)"

# Resolve the published host port for port 80 from the running container
try {
    $portMap = (& docker port $containerName 80) -join ''
    if ($portMap -match ':(\d+)') {
        Write-Host ""
        Write-Host "Web client: http://localhost:$($Matches[1])/BC/?tenant=default"
    }
} catch { }

[Environment]::Exit(0)