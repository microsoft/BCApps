[CmdletBinding()]
param(
    [string] $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')),
    [string] $SourceFolder = 'src',
    [string] $WorkspaceFile,
    [string] $PackageCachePath,
    [string] $OutFolder,
    [string] $RuleSet,
    [string[]] $Analyzers = @(),
    [ValidateSet('Debug','Error','Normal','Verbose','Warning')]
    [string] $LogLevel = 'Normal',
    [int] $MaxCpuCount = 0,
    [switch] $Recreate,
    [switch] $All,
    [string] $BaseBranch = 'main',
    [string] $ContainerName,
    [pscredential] $Credential = (New-Object pscredential 'admin', (ConvertTo-SecureString 'Password123!' -AsPlainText -Force)),
    [switch] $NoPublish
)

$ErrorActionPreference = 'Stop'

# Resolve defaults relative to the repo
$RepoRoot         = (Resolve-Path $RepoRoot).Path
$source           = Join-Path $RepoRoot $SourceFolder
if (-not $WorkspaceFile)    { $WorkspaceFile    = Join-Path $RepoRoot '.artifactsCache\bcapps.code-workspace' }
if (-not $PackageCachePath) { $PackageCachePath = Join-Path $RepoRoot '.artifactsCache' }
if (-not $OutFolder)        { $OutFolder        = Join-Path $RepoRoot '.artifactsCache\out' }
if (-not $RuleSet)          { $RuleSet          = Join-Path $RepoRoot 'src\rulesets\ruleset.json' }

Write-Host "Repo root         : $RepoRoot"
Write-Host "Source folder     : $source"
Write-Host "Workspace file    : $WorkspaceFile"
Write-Host "Package cache     : $PackageCachePath"
Write-Host "Output folder     : $OutFolder"
Write-Host "Ruleset           : $RuleSet"
Write-Host "Analyzers         : $($Analyzers -join ', ')"

# Sanity checks
if (-not (Test-Path $source))           { throw "Source folder not found: $source" }
if (-not (Test-Path $PackageCachePath)) { throw "Package cache not found at $PackageCachePath. Run tools\New-BcDevContainer.ps1 first to populate it." }
if (-not (Test-Path $RuleSet))          { throw "Ruleset not found: $RuleSet" }

foreach ($dir in @((Split-Path $WorkspaceFile -Parent), $OutFolder)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

# Create workspace if missing or -Recreate
if ($Recreate -and (Test-Path $WorkspaceFile)) { Remove-Item $WorkspaceFile -Force }
if (-not (Test-Path $WorkspaceFile)) {
    Write-Host "Creating workspace from $source ..."
    & al workspace create $WorkspaceFile $source
    if ($LASTEXITCODE -ne 0) { throw "al workspace create failed (exit $LASTEXITCODE)" }
} else {
    Write-Host "Reusing existing workspace file"
}

# Filter to only changed projects (committed vs base branch + working tree)
if (-not $All) {
    Write-Host "Detecting changed files relative to '$BaseBranch' (use -All to compile everything) ..."
    Push-Location $RepoRoot
    try {
        $mergeBase = (& git merge-base HEAD $BaseBranch 2>$null).Trim()
        if (-not $mergeBase) {
            Write-Warning "Could not resolve merge-base with '$BaseBranch'; falling back to direct diff."
            $diffRange = $BaseBranch
        } else {
            $diffRange = $mergeBase
        }

        $committed = & git diff --name-only $diffRange 2>$null
        $working   = & git status --porcelain | ForEach-Object { ($_ -replace '^...','').Trim('"') }
        $changed   = @($committed) + @($working) | Where-Object { $_ } | Sort-Object -Unique
    }
    finally { Pop-Location }

    if (-not $changed -or $changed.Count -eq 0) {
        Write-Host "No changed files detected. Nothing to compile."
        exit 0
    }
    Write-Host "Detected $($changed.Count) changed file(s). Sample:"
    $changed | Select-Object -First 10 | ForEach-Object { "  $_" } | Write-Host

    # Normalize paths for comparison
    $changedFull = $changed | ForEach-Object {
        try { (Resolve-Path -LiteralPath (Join-Path $RepoRoot $_)).Path } catch { $null }
    } | Where-Object { $_ }

    $ws = Get-Content $WorkspaceFile -Raw | ConvertFrom-Json
    $wsDir = Split-Path $WorkspaceFile -Parent

    $changedFolders = @()
    foreach ($folder in $ws.folders) {
        $folderPath = (Resolve-Path -LiteralPath (Join-Path $wsDir $folder.path)).Path.TrimEnd('\') + '\'
        if ($changedFull | Where-Object { $_.StartsWith($folderPath, [StringComparison]::OrdinalIgnoreCase) }) {
            $changedFolders += $folder
        }
    }

    if ($changedFolders.Count -eq 0) {
        Write-Host "No AL projects intersect changed files. Nothing to compile."
        exit 0
    }

    Write-Host "Projects to compile ($($changedFolders.Count)):"
    $changedFolders | ForEach-Object { "  - $($_.name)" } | Write-Host

    $filteredFile = Join-Path (Split-Path $WorkspaceFile -Parent) ('changed.' + (Split-Path $WorkspaceFile -Leaf))
    @{ folders = $changedFolders } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $filteredFile -Encoding utf8
    $WorkspaceFile = $filteredFile
    Write-Host "Wrote filtered workspace file: $WorkspaceFile"
}

# Compile
$compileArgs = @(
    'workspace', 'compile', $WorkspaceFile,
    '--packagecachepath', $PackageCachePath,
    '--ruleset', $RuleSet,
    '--outfolder', $OutFolder,
    '--loglevel', $LogLevel
)
if ($Analyzers.Count -gt 0) { $compileArgs += @('--analyzers', ($Analyzers -join ',')) }
if ($MaxCpuCount -gt 0)     { $compileArgs += @('--maxcpucount', $MaxCpuCount) }

Write-Host "Running: al $($compileArgs -join ' ')"

# Snapshot .app files before compilation
$beforeSnapshot = @{}
if (Test-Path $OutFolder) {
    Get-ChildItem -Path $OutFolder -Filter *.app -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $beforeSnapshot[$_.FullName] = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
}

& al @compileArgs
$exit = $LASTEXITCODE
Write-Host "al workspace compile exited with $exit"

# Diff .app files after compilation
$afterFiles = @(Get-ChildItem -Path $OutFolder -Filter *.app -Recurse -ErrorAction SilentlyContinue)
$new     = @()
$changed = @()
foreach ($f in $afterFiles) {
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName).Hash
    if (-not $beforeSnapshot.ContainsKey($f.FullName)) {
        $new += $f.FullName
    } elseif ($beforeSnapshot[$f.FullName] -ne $hash) {
        $changed += $f.FullName
    }
}

Write-Host ""
Write-Host "================================================================================"
Write-Host "BUILT APP FILES"
Write-Host "================================================================================"
Write-Host "New     : $($new.Count)"
$new     | ForEach-Object { "  + $_" } | Write-Host
Write-Host "Changed : $($changed.Count)"
$changed | ForEach-Object { "  ~ $_" } | Write-Host
Write-Host "================================================================================"

# Publish built apps to the BC container via the dev endpoint
$builtApps = @($new) + @($changed)
if (-not $NoPublish -and $exit -eq 0 -and $builtApps.Count -gt 0) {
    if (-not $ContainerName) {
        try {
            $branch = (& git -C $RepoRoot rev-parse --abbrev-ref HEAD).Trim()
            $last = ($branch -split '/')[-1]
            $san  = ($last -replace '[^a-zA-Z0-9]', '').ToLowerInvariant()
            if (-not $san) { $san = 'devcontainer' }
            $ContainerName = $san.Substring(0, [Math]::Min(10, $san.Length))
        } catch {
            Write-Warning "Could not derive container name; skipping publish. Pass -ContainerName to publish."
        }
    }
    if ($ContainerName) {
        Import-Module BcContainerHelper -ErrorAction Stop
        if (Test-BcContainer -containerName $ContainerName) {
            Write-Host "Publishing $($builtApps.Count) app(s) to container '$ContainerName' via dev endpoint ..."
            foreach ($app in $builtApps) {
                Write-Host "  -> $app"
                Publish-BcContainerApp `
                    -containerName $ContainerName `
                    -credential $Credential `
                    -appFile $app `
                    -syncMode ForceSync `
                    -sync `
                    -install `
                    -upgrade `
                    -useDevEndpoint
            }
        } else {
            Write-Warning "Container '$ContainerName' does not exist - skipping publish."
        }
    }
}

if ($exit -eq 0) {
    [Environment]::Exit(0)
}
exit $exit
