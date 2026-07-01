<#
.SYNOPSIS
    Prunes a BCQuality clone according to enabled-layers and the knowledge
    allow/deny globs from the resolved BCQuality configuration.

.DESCRIPTION
    Shared BCQuality integration helper. Any agent in this repository that
    consumes BCQuality clones it once per run and calls this filter before
    handing the directory to its agent process. Deterministic, on-disk
    filter; removes:

      - Knowledge files outside the enabled-layers set
      - Knowledge files matching `knowledge.deny` globs
      - Knowledge files NOT matching `knowledge.allow` globs (when `allow`
        is non-empty)
      - Action skill files inside non-enabled layers
      - Action skill files explicitly listed in `disabled-skills`

    Meta-skills under /skills/ are never removed: they are the contract
    every action skill follows.

    Every removal is recorded; the per-file list is written to
    `<BCQualityRoot>/_filter-report.json` so callers can surface it (for
    example, a PR-review orchestrator surfaces it in the PR summary, while
    a code-generation orchestrator can log it for traceability).

.PARAMETER BCQualityRoot
    Path to the local BCQuality clone.

.PARAMETER Config
    Resolved configuration hashtable from Get-BCQualityConfig.ps1. When
    omitted the script loads the config from the sibling YAML file.

.PARAMETER ReportPath
    Path to write the filter report JSON. Defaults to a file at the root
    of the BCQuality clone.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $BCQualityRoot,
    [object] $Config,
    [string] $ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $BCQualityRoot)) {
    throw "BCQuality root not found: $BCQualityRoot"
}

if (-not $Config) {
    $configScript = Join-Path $PSScriptRoot 'Get-BCQualityConfig.ps1'
    $Config = & $configScript
}

if (-not $ReportPath) {
    $ReportPath = Join-Path $BCQualityRoot '_filter-report.json'
}

$layers = @($Config['enabled-layers'])
$disabledSkills = @($Config['disabled-skills'])
$allow = @($Config['knowledge']['allow'])
$deny  = @($Config['knowledge']['deny'])

function Test-GlobMatch {
    # Matches a forward-slash repo-relative path against an unparametrised
    # glob. Supports `**` (any path segments) and `*` (within one segment).
    param([string] $Path, [string] $Pattern)

    $p = ($Pattern -replace '\\', '/').Trim()
    if (-not $p) { return $false }

    # Build a regex from the glob. Escape regex metacharacters except '*'
    # and '?' which we translate to their glob meanings.
    $regex = [System.Text.StringBuilder]::new()
    $null = $regex.Append('^')
    for ($i = 0; $i -lt $p.Length; $i++) {
        $c = $p[$i]
        if ($c -eq '*' -and ($i + 1) -lt $p.Length -and $p[$i + 1] -eq '*') {
            $null = $regex.Append('.*')
            $i++
            # consume an optional trailing '/'
            if (($i + 1) -lt $p.Length -and $p[$i + 1] -eq '/') { $i++ }
        }
        elseif ($c -eq '*') {
            $null = $regex.Append('[^/]*')
        }
        elseif ($c -eq '?') {
            $null = $regex.Append('[^/]')
        }
        elseif (@('.', '\', '+', '(', ')', '{', '}', '[', ']', '^', '$', '|') -contains $c) {
            $null = $regex.Append('\').Append($c)
        }
        else {
            $null = $regex.Append($c)
        }
    }
    $null = $regex.Append('$')
    return ($Path -match $regex.ToString())
}

function Get-LayerOfPath {
    # Returns 'microsoft' / 'community' / 'custom' / $null based on the
    # first path segment.
    param([string] $Path)
    if ($Path -match '^(microsoft|community|custom)(/|$)') { return $Matches[1] }
    return $null
}

function Get-RelativePath {
    param([string] $Root, [string] $Full)
    $rel = $Full.Substring($Root.Length).TrimStart([char]'/', [char]'\')
    return ($rel -replace '\\', '/')
}

$removed = [System.Collections.Generic.List[object]]::new()

# 1. Knowledge files. Walk every */knowledge/**/*.md across all three
#    layers (we cannot assume the corpus state of community/custom).
foreach ($layerDir in @('microsoft', 'community', 'custom')) {
    $kbRoot = Join-Path $BCQualityRoot (Join-Path $layerDir 'knowledge')
    if (-not (Test-Path $kbRoot)) { continue }

    Get-ChildItem -LiteralPath $kbRoot -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue |
        ForEach-Object {
            $rel = Get-RelativePath -Root $BCQualityRoot -Full $_.FullName
            $reason = $null

            if ($layers -notcontains $layerDir) {
                $reason = 'layer-disabled'
            }
            elseif ($allow.Count -gt 0) {
                $matched = $false
                foreach ($pat in $allow) { if (Test-GlobMatch -Path $rel -Pattern $pat) { $matched = $true; break } }
                if (-not $matched) { $reason = 'allow-list-miss' }
            }

            if (-not $reason -and $deny.Count -gt 0) {
                foreach ($pat in $deny) {
                    if (Test-GlobMatch -Path $rel -Pattern $pat) { $reason = 'deny-list-hit'; break }
                }
            }

            if ($reason) {
                Remove-Item -LiteralPath $_.FullName -Force
                $removed.Add([pscustomobject]@{ path = $rel; kind = 'knowledge'; reason = $reason }) | Out-Null
            }
        }
}

# 2. Action skills. Remove disabled skills explicitly and any skill files
#    in non-enabled layers. Meta-skills under /skills/ are never touched.
foreach ($layerDir in @('microsoft', 'community', 'custom')) {
    $skillsRoot = Join-Path $BCQualityRoot (Join-Path $layerDir 'skills')
    if (-not (Test-Path $skillsRoot)) { continue }

    if ($layers -notcontains $layerDir) {
        Get-ChildItem -LiteralPath $skillsRoot -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue |
            ForEach-Object {
                $rel = Get-RelativePath -Root $BCQualityRoot -Full $_.FullName
                Remove-Item -LiteralPath $_.FullName -Force
                $removed.Add([pscustomobject]@{ path = $rel; kind = 'skill'; reason = 'layer-disabled' }) | Out-Null
            }
        continue
    }

    foreach ($disabled in $disabledSkills) {
        $normalized = ($disabled -replace '\\', '/').Trim()
        if (-not $normalized) { continue }
        if (-not $normalized.StartsWith("$layerDir/")) { continue }
        $full = Join-Path $BCQualityRoot $normalized
        # Guard against path traversal: a value like 'microsoft/../../x' passes
        # the prefix check but resolves outside the clone. Only delete files that
        # canonically remain under $BCQualityRoot.
        $resolvedRoot = [System.IO.Path]::GetFullPath($BCQualityRoot)
        $resolvedFull = [System.IO.Path]::GetFullPath($full)
        if (-not $resolvedFull.StartsWith($resolvedRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Warning "Skipping unsafe disabled-skill path '$normalized' (escapes BCQuality root)."
            continue
        }
        if (Test-Path $resolvedFull) {
            Remove-Item -LiteralPath $resolvedFull -Force
            $removed.Add([pscustomobject]@{ path = $normalized; kind = 'skill'; reason = 'configuration' }) | Out-Null
        }
    }
}

$report = [pscustomobject]@{
    bcqualityRoot   = $BCQualityRoot
    enabledLayers   = $layers
    disabledSkills  = $disabledSkills
    knowledgeAllow  = $allow
    knowledgeDeny   = $deny
    removedCount    = $removed.Count
    removed         = @($removed)
}

$reportDir = Split-Path -Parent $ReportPath
if ($reportDir -and -not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
}
$report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ReportPath -Encoding UTF8

Write-Host "BCQuality filter: removed $($removed.Count) file(s). Report: $ReportPath"

return $report
