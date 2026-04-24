<#
.SYNOPSIS
    Produces a raw code map for an AL app directory.
.DESCRIPTION
    Scans an AL codebase and outputs: app metadata, object counts per folder,
    and existing documentation files. No scoring or filtering — just data.
.PARAMETER Path
    Path to the AL app directory.
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

function Get-ObjectType([string]$FilePath) {
    $keywords = 'table|tableextension|page|pageextension|codeunit|report|reportextension|enum|enumextension|interface|query|xmlport|permissionset|permissionsetextension|profile|controladdin|entitlement'
    foreach ($line in [System.IO.File]::ReadLines($FilePath)) {
        if ($line -match "^(?i)($keywords)\s") {
            return $Matches[1].ToLower()
        }
    }
    return 'unknown'
}

# --- App metadata ---

$appJsonPath = Join-Path $AppPath 'app.json'
$appJson = if (Test-Path $appJsonPath) { Get-Content $appJsonPath -Raw | ConvertFrom-Json } else { $null }

# --- Scan all .al files ---

$alFiles = Get-ChildItem -Path $AppPath -Filter '*.al' -Recurse -File
if ($alFiles.Count -eq 0) {
    Write-Output "No .al files found in $AppPath"
    exit 0
}

$objects = $alFiles | ForEach-Object {
    $relDir = $_.DirectoryName.Substring($AppPath.Path.Length).TrimStart([IO.Path]::DirectorySeparatorChar, '/')
    if (-not $relDir) { $relDir = '.' }
    [PSCustomObject]@{ Type = Get-ObjectType $_.FullName; Dir = $relDir }
}

# --- Per-folder counts ---

$folders = $objects | Group-Object Dir | ForEach-Object {
    $group = $_.Group
    $types = $group | Group-Object Type
    $counts = @{}
    foreach ($t in $types) { $counts[$t.Name] = $t.Count }
    [PSCustomObject]@{
        Dir        = $_.Name
        Total      = $group.Count
        Tables     = ($counts['table'] ?? 0) + ($counts['tableextension'] ?? 0)
        Codeunits  = $counts['codeunit'] ?? 0
        Pages      = ($counts['page'] ?? 0) + ($counts['pageextension'] ?? 0)
        Interfaces = $counts['interface'] ?? 0
        Enums      = ($counts['enum'] ?? 0) + ($counts['enumextension'] ?? 0)
        Other      = $group.Count - (($counts['table'] ?? 0) + ($counts['tableextension'] ?? 0) + ($counts['codeunit'] ?? 0) + ($counts['page'] ?? 0) + ($counts['pageextension'] ?? 0) + ($counts['interface'] ?? 0) + ($counts['enum'] ?? 0) + ($counts['enumextension'] ?? 0))
    }
} | Sort-Object Dir

# --- Documentation inventory ---

$docPatterns = @('CLAUDE.md', 'README.md')
$docFileList = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
Get-ChildItem -Path $AppPath -Include $docPatterns -Recurse -File -ErrorAction SilentlyContinue |
    ForEach-Object { $docFileList.Add($_) }
Get-ChildItem -Path $AppPath -Filter 'docs' -Recurse -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ChildItem -Path $_.FullName -Filter '*.md' -File -ErrorAction SilentlyContinue } |
    ForEach-Object { $docFileList.Add($_) }
$docFiles = @($docFileList | Sort-Object FullName -Unique | ForEach-Object {
    $rel = $_.FullName.Substring($AppPath.Path.Length).TrimStart([IO.Path]::DirectorySeparatorChar, '/')
    [PSCustomObject]@{ File = $rel; Lines = ([System.IO.File]::ReadAllLines($_.FullName)).Count }
})

# --- Output ---

Write-Output '# AL Code Map'
Write-Output ''

if ($appJson) {
    Write-Output "**App**: $($appJson.name) v$($appJson.version) ($($appJson.id))"
} else {
    Write-Output "**App**: $(Split-Path $AppPath -Leaf) (no app.json)"
}
Write-Output "**Total AL objects**: $($alFiles.Count)"
Write-Output ''

Write-Output '## Folders'
Write-Output ''
Write-Output '| Folder | Total | Tables | Codeunits | Pages | Interfaces | Enums | Other |'
Write-Output '|--------|-------|--------|-----------|-------|------------|-------|-------|'
foreach ($f in $folders) {
    Write-Output "| $($f.Dir) | $($f.Total) | $($f.Tables) | $($f.Codeunits) | $($f.Pages) | $($f.Interfaces) | $($f.Enums) | $($f.Other) |"
}
Write-Output ''

Write-Output '## Existing docs'
Write-Output ''
if ($docFiles.Count -gt 0) {
    Write-Output '| File | Lines |'
    Write-Output '|------|-------|'
    foreach ($d in $docFiles) { Write-Output "| $($d.File) | $($d.Lines) |" }
} else {
    Write-Output '_(none)_'
}
