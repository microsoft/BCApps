<#
.SYNOPSIS
    Loads tools/BCQuality/bcquality.config.yaml, applies Actions-variable
    overrides, validates, and returns the resolved configuration as a
    hashtable.

.DESCRIPTION
    Shared BCQuality integration helper. Returns the resolved configuration
    that every agent in this repository which consumes BCQuality (the
    Copilot PR reviewer, and future code-generation / telemetry-audit /
    other agents) uses to decide which BCQuality repo, layers, skills, and
    knowledge files to read at run time.

    The YAML file is the tracked default; environment variables override
    file values for operator-controlled one-off changes.

    Override map (env var -> config path; comma-separated lists where shown):

        BCQUALITY_REPO              bcquality.repo
        BCQUALITY_REF               bcquality.ref
        BCQUALITY_ENABLED_LAYERS    enabled-layers      (comma-separated)
        BCQUALITY_DISABLED_SKILLS   disabled-skills     (comma-separated)
        BCQUALITY_KNOWLEDGE_ALLOW   knowledge.allow     (comma-separated)
        BCQUALITY_KNOWLEDGE_DENY    knowledge.deny      (comma-separated)

    Requires the powershell-yaml module. Workflows that consume this script
    install it before invoking.

.PARAMETER ConfigPath
    Path to bcquality.config.yaml. Defaults to a sibling of this script's
    parent directory (tools/BCQuality/bcquality.config.yaml).
#>
[CmdletBinding()]
param(
    [string] $ConfigPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'bcquality.config.yaml')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    throw "powershell-yaml module is required. Install with: Install-Module powershell-yaml -Scope CurrentUser -Force"
}
Import-Module powershell-yaml -DisableNameChecking -ErrorAction Stop

if (-not (Test-Path $ConfigPath)) {
    throw "bcquality config not found: $ConfigPath"
}

function Split-CsvOverride {
    param([string] $Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return ,@() }
    return ,@(($Value -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function ConvertTo-Mutable {
    # powershell-yaml returns ordered dictionaries and Object[] arrays.
    # Normalize into plain hashtables and List[object] so we can mutate
    # cleanly and keep single-element arrays from getting unwrapped.
    param([object] $Value)
    if ($Value -is [System.Collections.IDictionary]) {
        $h = @{}
        foreach ($k in $Value.Keys) { $h[$k] = ConvertTo-Mutable $Value[$k] }
        return $h
    }
    if ($Value -is [System.Collections.IList] -and -not ($Value -is [string])) {
        $list = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $Value) { $list.Add((ConvertTo-Mutable $item)) | Out-Null }
        return ,$list
    }
    return $Value
}

function Ensure-List {
    param([object] $Value)
    if ($null -eq $Value) { return [System.Collections.Generic.List[object]]::new() }
    if ($Value -is [System.Collections.Generic.List[object]]) { return $Value }
    $list = [System.Collections.Generic.List[object]]::new()
    if ($Value -is [System.Collections.IList] -and -not ($Value -is [string])) {
        foreach ($item in $Value) { $list.Add($item) | Out-Null }
    } else {
        $list.Add($Value) | Out-Null
    }
    return $list
}

$raw = [System.IO.File]::ReadAllText($ConfigPath, [System.Text.Encoding]::UTF8)
$parsed = ConvertFrom-Yaml -Yaml $raw -Ordered

$cfg = ConvertTo-Mutable $parsed
if ($null -eq $cfg -or -not ($cfg -is [hashtable])) {
    throw "bcquality.config.yaml did not parse to a mapping at the top level."
}

# Defaults for any missing keys so downstream code never sees them missing.
if (-not $cfg.ContainsKey('bcquality') -or -not ($cfg['bcquality'] -is [hashtable])) { $cfg['bcquality'] = @{} }
if (-not $cfg['bcquality'].ContainsKey('repo')) { $cfg['bcquality']['repo'] = 'https://github.com/microsoft/BCQuality' }
if (-not $cfg['bcquality'].ContainsKey('ref'))  { $cfg['bcquality']['ref']  = 'main' }
$cfg['enabled-layers']   = Ensure-List ($cfg['enabled-layers']  ?? @('microsoft'))
$cfg['disabled-skills']  = Ensure-List ($cfg['disabled-skills'] ?? @())
if (-not $cfg.ContainsKey('knowledge') -or -not ($cfg['knowledge'] -is [hashtable])) { $cfg['knowledge'] = @{} }
$cfg['knowledge']['allow'] = Ensure-List ($cfg['knowledge']['allow'] ?? @())
$cfg['knowledge']['deny']  = Ensure-List ($cfg['knowledge']['deny']  ?? @())
if (-not $cfg.ContainsKey('task-context') -or -not ($cfg['task-context'] -is [hashtable])) { $cfg['task-context'] = @{} }

# Apply env-var overrides (each override wins over the file value when set).
$repoOverride = [System.Environment]::GetEnvironmentVariable('BCQUALITY_REPO')
if ($repoOverride) { $cfg['bcquality']['repo'] = $repoOverride.Trim() }

$refOverride = [System.Environment]::GetEnvironmentVariable('BCQUALITY_REF')
if ($refOverride) { $cfg['bcquality']['ref'] = $refOverride.Trim() }

$layersOverride = [System.Environment]::GetEnvironmentVariable('BCQUALITY_ENABLED_LAYERS')
if ($layersOverride) { $cfg['enabled-layers'] = Ensure-List (Split-CsvOverride $layersOverride) }

$skillsOverride = [System.Environment]::GetEnvironmentVariable('BCQUALITY_DISABLED_SKILLS')
if ($skillsOverride) { $cfg['disabled-skills'] = Ensure-List (Split-CsvOverride $skillsOverride) }

$allowOverride = [System.Environment]::GetEnvironmentVariable('BCQUALITY_KNOWLEDGE_ALLOW')
if ($allowOverride) { $cfg['knowledge']['allow'] = Ensure-List (Split-CsvOverride $allowOverride) }

$denyOverride = [System.Environment]::GetEnvironmentVariable('BCQUALITY_KNOWLEDGE_DENY')
if ($denyOverride) { $cfg['knowledge']['deny'] = Ensure-List (Split-CsvOverride $denyOverride) }

# Validate enabled-layers against the known layer set; reject typos early.
$knownLayers = @('microsoft', 'community', 'custom')
foreach ($layer in $cfg['enabled-layers']) {
    if ($knownLayers -notcontains $layer) {
        throw "Unknown enabled-layers value: '$layer'. Allowed: $($knownLayers -join ', ')"
    }
}

$repoUri = $cfg['bcquality']['repo'] -as [System.Uri]
if (-not $repoUri -or $repoUri.Scheme -notin @('http','https')) {
    throw "bcquality.repo must be an http(s) URL. Got: $($cfg['bcquality']['repo'])"
}

return $cfg

