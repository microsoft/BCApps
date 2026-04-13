<#
.SYNOPSIS
    Produces a structured code map for an AL app directory.
.DESCRIPTION
    Scans an AL codebase and outputs a markdown report with object inventory,
    subfolder scoring, and documentation inventory.
.PARAMETER Path
    Path to the AL app directory (must contain .al files).
.EXAMPLE
    pwsh -File Get-ALCodeMap.ps1 -Path "src/Apps/W1/Shopify/App"
#>
param(
    [Parameter(Mandatory)]
    [string]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$AppPath = Resolve-Path $Path

# --- Helpers ---

function Get-ObjectType([string]$FilePath) {
    $keywords = 'table|tableextension|page|pageextension|codeunit|report|reportextension|enum|enumextension|interface|query|xmlport|permissionset|permissionsetextension|profile|controladdin|entitlement'
    foreach ($line in [System.IO.File]::ReadLines($FilePath)) {
        if ($line -match "^(?i)($keywords)\s") {
            return $Matches[1].ToLower()
        }
    }
    return 'unknown'
}

function Get-Score($Stats) {
    $score = 0
    if ($Stats.Tables -ge 3)     { $score += 3 }
    if ($Stats.Codeunits -ge 3)  { $score += 2 }
    if ($Stats.Interfaces -ge 3) { $score += 3 }
    if ($Stats.HasPublishers)    { $score += 1 }
    if ($Stats.HasSubscribers)   { $score += 1 }
    if ($Stats.Total -ge 10)     { $score += 2 }
    if ($Stats.HasComplex)       { $score += 1 }
    if ($Stats.Extensions -gt 0) { $score += 1 }
    return $score
}

function Get-Classification([int]$Score) {
    if ($Score -ge 7) { return 'MUST_DOCUMENT' }
    if ($Score -ge 4) { return 'SHOULD_DOCUMENT' }
    if ($Score -ge 1) { return 'OPTIONAL' }
    return 'SKIP'
}

# --- 1. App metadata ---

$appJson = $null
$appJsonPath = Join-Path $AppPath 'app.json'
if (Test-Path $appJsonPath) {
    $appJson = Get-Content $appJsonPath -Raw | ConvertFrom-Json
}

# --- 2. Scan all .al files ---

$alFiles = Get-ChildItem -Path $AppPath -Filter '*.al' -Recurse -File
if ($alFiles.Count -eq 0) {
    Write-Output "No .al files found in $AppPath"
    exit 0
}

$objects = $alFiles | ForEach-Object {
    $relDir = $_.DirectoryName.Substring($AppPath.Path.Length).TrimStart([IO.Path]::DirectorySeparatorChar, '/')
    if (-not $relDir) { $relDir = '.' }
    [PSCustomObject]@{
        Type = Get-ObjectType $_.FullName
        Dir  = $relDir
        Path = $_.FullName
    }
}

# --- 3. Group by type for app-level summary ---

$typeCounts = $objects | Group-Object Type | Sort-Object Name |
    ForEach-Object { [PSCustomObject]@{ Type = $_.Name; Count = $_.Count } }

# --- 4. Per-subfolder stats and scoring ---

$extensionTypes = @('tableextension','pageextension','enumextension','reportextension','permissionsetextension')

$subfolders = $objects | Group-Object Dir | ForEach-Object {
    $dirObjects = $_.Group
    $dir = $_.Name
    $dirFull = if ($dir -eq '.') { $AppPath.Path } else { Join-Path $AppPath $dir }

    $tables     = @($dirObjects | Where-Object { $_.Type -in 'table','tableextension' }).Count
    $codeunits  = @($dirObjects | Where-Object { $_.Type -eq 'codeunit' }).Count
    $pages      = @($dirObjects | Where-Object { $_.Type -in 'page','pageextension' }).Count
    $interfaces = @($dirObjects | Where-Object { $_.Type -eq 'interface' }).Count
    $extensions = @($dirObjects | Where-Object { $_.Type -in $extensionTypes }).Count

    # Event detection
    $dirAlFiles = $dirObjects | ForEach-Object { $_.Path }
    $hasPublishers  = $false
    $hasSubscribers = $false
    $hasComplex     = $false

    foreach ($f in $dirAlFiles) {
        $content = [System.IO.File]::ReadAllText($f)
        if (-not $hasPublishers  -and $content -match '\[(IntegrationEvent|BusinessEvent)\]') { $hasPublishers = $true }
        if (-not $hasSubscribers -and $content -match '\[EventSubscriber\]') { $hasSubscribers = $true }
        if (-not $hasComplex) {
            $procCount = ([regex]::Matches($content, '(?m)^\s*(local |internal )?procedure ')).Count
            if ($procCount -ge 10) { $hasComplex = $true }
        }
    }

    $stats = [PSCustomObject]@{
        Tables        = $tables
        Codeunits     = $codeunits
        Interfaces    = $interfaces
        Extensions    = $extensions
        Total         = $dirObjects.Count
        HasPublishers = $hasPublishers
        HasSubscribers= $hasSubscribers
        HasComplex    = $hasComplex
    }

    $score = Get-Score $stats
    $events = @()
    if ($hasPublishers)  { $events += 'pub' }
    if ($hasSubscribers) { $events += 'sub' }
    $eventsStr = if ($events.Count -gt 0) { $events -join '+' } else { '-' }

    [PSCustomObject]@{
        Dir            = $dir
        Total          = $dirObjects.Count
        Tables         = $tables
        Codeunits      = $codeunits
        Pages          = $pages
        Interfaces     = $interfaces
        Events         = $eventsStr
        Extensions     = $extensions
        Score          = $score
        Classification = Get-Classification $score
    }
} | Sort-Object Dir

# --- 5. Documentation inventory ---

$docPatterns = @('CLAUDE.md','README.md')
$docFileList = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
Get-ChildItem -Path $AppPath -Include $docPatterns -Recurse -File -ErrorAction SilentlyContinue |
    ForEach-Object { $docFileList.Add($_) }
Get-ChildItem -Path $AppPath -Filter 'docs' -Recurse -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ChildItem -Path $_.FullName -Filter '*.md' -File -ErrorAction SilentlyContinue } |
    ForEach-Object { $docFileList.Add($_) }
$docFiles = @($docFileList | Sort-Object FullName -Unique)

$docInventory = @($docFiles | ForEach-Object {
    $rel = $_.FullName.Substring($AppPath.Path.Length).TrimStart([IO.Path]::DirectorySeparatorChar, '/')
    [PSCustomObject]@{
        File  = $rel
        Lines = ([System.IO.File]::ReadAllLines($_.FullName)).Count
    }
})

# --- 6. Output markdown ---

$mustCount   = @($subfolders | Where-Object Classification -eq 'MUST_DOCUMENT').Count
$shouldCount = @($subfolders | Where-Object Classification -eq 'SHOULD_DOCUMENT').Count

Write-Output '# AL Code Map'
Write-Output ''
Write-Output "**Target**: $AppPath"
Write-Output "**Generated**: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
Write-Output ''

Write-Output '## App metadata'
Write-Output ''
if ($appJson) {
    Write-Output '| Field | Value |'
    Write-Output '|-------|-------|'
    Write-Output "| Name | $($appJson.name) |"
    Write-Output "| Version | $($appJson.version) |"
    Write-Output "| ID | $($appJson.id) |"
} else {
    Write-Output "No app.json found. Using directory name: $(Split-Path $AppPath -Leaf)"
}
Write-Output ''

Write-Output '## Object summary'
Write-Output ''
Write-Output '| Type | Count |'
Write-Output '|------|-------|'
foreach ($tc in $typeCounts) {
    Write-Output "| $($tc.Type) | $($tc.Count) |"
}
Write-Output "| **Total** | **$($alFiles.Count)** |"
Write-Output ''

Write-Output '## Subfolders'
Write-Output ''
Write-Output '| Subfolder | Total | Tables | Codeunits | Pages | Interfaces | Events | Ext | Score | Class |'
Write-Output '|-----------|-------|--------|-----------|-------|------------|--------|-----|-------|-------|'
foreach ($sf in $subfolders) {
    Write-Output "| $($sf.Dir) | $($sf.Total) | $($sf.Tables) | $($sf.Codeunits) | $($sf.Pages) | $($sf.Interfaces) | $($sf.Events) | $($sf.Extensions) | $($sf.Score) | $($sf.Classification) |"
}
Write-Output ''

Write-Output '## Documentation inventory'
Write-Output ''
if ($docInventory.Count -gt 0) {
    Write-Output '| File | Lines |'
    Write-Output '|------|-------|'
    foreach ($doc in $docInventory) {
        Write-Output "| $($doc.File) | $($doc.Lines) |"
    }
} else {
    Write-Output '_(no documentation files found)_'
}
Write-Output ''

Write-Output '## Quick stats'
Write-Output ''
Write-Output '| Metric | Value |'
Write-Output '|--------|-------|'
Write-Output "| Total AL objects | $($alFiles.Count) |"
Write-Output "| Subfolders | $($subfolders.Count) |"
Write-Output "| MUST_DOCUMENT | $mustCount |"
Write-Output "| SHOULD_DOCUMENT | $shouldCount |"
Write-Output "| Doc files found | $($docInventory.Count) |"
