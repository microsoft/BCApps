<#
.SYNOPSIS
    Appends the " (Power BI)" suffix to the Caption and AboutTitle of Power BI
    embedded pages across the BC apps (Power BI Reports app and any other app
    that defines Power BI embedded pages).

.DESCRIPTION
    A Power BI embedded page is identified as an AL page object that:
      * has PageType = UserControlHost, and
      * hosts the PowerBIManagement control add-in via usercontrol(...; PowerBIManagement).

    For every such page the script appends " (Power BI)" to the Caption and to
    the AboutTitle property values, e.g.:
        Caption    = 'Production Order WIP'        -> 'Production Order WIP (Power BI)'
        AboutTitle = 'About Production Order WIP'   -> 'About Production Order WIP (Power BI)'

    If "Power BI" (or "PowerBI") is already mentioned in the Caption, the page is
    skipped and reported so it can be reviewed manually.

    Pages under an _Obsolete folder are ignored.

.PARAMETER Root
    Root folder to scan. Defaults to <repo>/src/Apps relative to this script.

.PARAMETER WhatIf
    Preview the changes without writing to disk.

.EXAMPLE
    ./Rename-PowerBIEmbeddedCaptions.ps1 -WhatIf
    ./Rename-PowerBIEmbeddedCaptions.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Root
)

$ErrorActionPreference = 'Stop'

if (-not $Root) {
    $Root = Join-Path (Split-Path -Parent $PSScriptRoot) '..' | Join-Path -ChildPath 'src\Apps'
    $Root = [System.IO.Path]::GetFullPath($Root)
}

if (-not (Test-Path $Root)) {
    throw "Root path not found: $Root"
}

Write-Host "Scanning for Power BI embedded pages under: $Root" -ForegroundColor Cyan

$Suffix = ' (Power BI)'

# Matches a Caption/AboutTitle property, capturing the string literal contents.
# Group 1: 'Caption' or 'AboutTitle', Group 2: property value (without quotes).
$captionRegex = "(?m)^(?<indent>\s*)(?<prop>Caption|AboutTitle)(?<sep>\s*=\s*)'(?<value>(?:[^']|'')*)'(?<tail>\s*;)"

$changed = [System.Collections.Generic.List[object]]::new()
$skipped = [System.Collections.Generic.List[object]]::new()

$files = Get-ChildItem -Path $Root -Recurse -Filter '*.Page.al' -File |
    Where-Object { $_.FullName -notmatch '\\_Obsolete\\' }

foreach ($file in $files) {
    # Read as UTF-8 explicitly. Get-Content in Windows PowerShell 5.1 uses the
    # system codepage by default, which corrupts non-ASCII characters (e.g. U+2019).
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $offset = if ($hasBom) { 3 } else { 0 }
    $content = [System.Text.UTF8Encoding]::new($false).GetString($bytes, $offset, $bytes.Length - $offset)

    # Only Power BI embedded pages: UserControlHost hosting PowerBIManagement.
    if ($content -notmatch 'PageType\s*=\s*UserControlHost') { continue }
    if ($content -notmatch 'usercontrol\s*\([^;]*;\s*PowerBIManagement\s*\)') { continue }

    # Extract the current Caption value.
    $captionMatch = [regex]::Match($content, "(?m)^\s*Caption\s*=\s*'(?<value>(?:[^']|'')*)'\s*;")
    if (-not $captionMatch.Success) { continue }
    $captionValue = $captionMatch.Groups['value'].Value

    # Skip pages that already mention Power BI in the caption.
    if ($captionValue -match '(?i)power\s*bi') {
        $skipped.Add([pscustomobject]@{
            File    = $file.FullName
            Caption = $captionValue
        })
        continue
    }

    $props = @()
    $newContent = [regex]::Replace($content, $captionRegex, {
        param($m)
        $value = $m.Groups['value'].Value
        # Guard: never double-append the suffix.
        if ($value -match '(?i)power\s*bi') { return $m.Value }
        $script:props += "$($m.Groups['prop'].Value): '$value' -> '$value$Suffix'"
        return "$($m.Groups['indent'].Value)$($m.Groups['prop'].Value)$($m.Groups['sep'].Value)'$value$Suffix'$($m.Groups['tail'].Value)"
    })

    if ($newContent -ne $content) {
        if ($PSCmdlet.ShouldProcess($file.FullName, 'Append " (Power BI)" to Caption/AboutTitle')) {
            # Preserve original file encoding, including BOM presence.
            [System.IO.File]::WriteAllText($file.FullName, $newContent, [System.Text.UTF8Encoding]::new($hasBom))
        }
        $changed.Add([pscustomobject]@{
            File    = $file.FullName
            Changes = $props
        })
    }
}

Write-Host ""
Write-Host "=== Updated pages ($($changed.Count)) ===" -ForegroundColor Green
foreach ($c in $changed) {
    Write-Host $c.File
    foreach ($p in $c.Changes) { Write-Host "    $p" }
}

Write-Host ""
Write-Host "=== Skipped pages - 'Power BI' already in caption ($($skipped.Count)) ===" -ForegroundColor Yellow
foreach ($s in $skipped) {
    Write-Host "    [$($s.Caption)]  $($s.File)"
}

Write-Host ""
Write-Host "Done. Updated: $($changed.Count), Skipped/flagged: $($skipped.Count)." -ForegroundColor Cyan
