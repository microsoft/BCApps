# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

#Requires -Version 7.0
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# These are textual conventions, not an AL grammar or symbol resolver. Keep this list bounded.
$script:Identifier = '(?:"(?:[^"]|"")*"|[A-Za-z_][A-Za-z0-9_]*)'
$script:QualifiedIdentifier = "$script:Identifier(?:\s*\.\s*$script:Identifier)*"
$script:ObjectKinds = 'tableextension|pageextension|pagecustomization|enumextension|reportextension|permissionsetextension|table|page|codeunit|enum|interface|report|query|xmlport|permissionset|profile|controladdin|entitlement'

function Get-ArchitectureMatches([string] $Text, [string] $Pattern) {
    [regex]::Matches($Text, $Pattern, 'IgnoreCase, Multiline', [TimeSpan]::FromSeconds(2))
}

function Hide-ALTrivia([string] $Text, [switch] $Identifiers) {
    # Match quoted identifiers first so //, /* and apostrophes inside them stay opaque.
    $pattern = '"(?:[^"]|"")*"|//[^\r\n]*|/\*[\s\S]*?\*/|''(?:[^'']|'''')*'''
    [regex]::Replace($Text, $pattern, [System.Text.RegularExpressions.MatchEvaluator] {
        param($match)
        if (-not $Identifiers -and $match.Value.StartsWith('"')) { return $match.Value }
        return [regex]::Replace($match.Value, '[^\r\n]', ' ')
    }, 'None', [TimeSpan]::FromSeconds(2))
}

function Test-ArchitectureGlob([string] $Value, [string[]] $Patterns) {
    foreach ($pattern in $Patterns) {
        # Preserve the old policy's semantics: only * and ?, and * spans directories.
        $regex = '^' + [regex]::Escape($pattern).Replace('\*', '.*').Replace('\?', '.') + '$'
        if ($Value -match $regex) { return $true }
    }
    return $false
}

function Test-ArchitectureSelector($File, $Selector) {
    return (Test-ArchitectureGlob $File.Path $Selector.paths) -and
        (-not $Selector.Contains('kinds') -or $File.Kind -in $Selector.kinds)
}

<#
.SYNOPSIS
    Reads and validates the app-owned architecture policy against its JSON schema.
.DESCRIPTION
    Uses PowerShell 7 JSON Schema validation, then validates cross-rule constraints
    such as unique rule IDs and supported object kinds for access/extensibility.
#>
function Read-ALArchitectureRules {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $Path,
        [string] $SchemaPath = (Join-Path (Split-Path $Path -Parent) 'architecture-rules.schema.json'))
    $json = [IO.File]::ReadAllText($Path)
    if (-not (Test-Json -Json $json -SchemaFile $SchemaPath -ErrorAction Stop)) { throw "Invalid architecture configuration: $Path" }
    $config = ConvertFrom-Json -InputObject $json -AsHashtable
    $ids = @{}
    foreach ($rule in $config.rules) {
        if ($ids.ContainsKey($rule.id)) { throw "Duplicate rule ID '$($rule.id)'." }
        $ids[$rule.id] = $true
        if ($rule.check -eq 'forbiddenCode') { $null = Get-ArchitectureMatches '' $rule.pattern }
        if ($rule.check -eq 'manifest' -and -not ($rule.Contains('allowedFriends') -or $rule.Contains('forbiddenSymbols') -or $rule.Contains('forbiddenDependencies'))) {
            throw "$($rule.id): manifest rule needs at least one policy."
        }
        if ($rule.check -eq 'properties') {
            $supported = @{ Access = @('table', 'codeunit', 'enum', 'query', 'report', 'xmlport', 'interface', 'permissionset'); Extensible = @('table', 'page', 'enum') }
            foreach ($property in $rule.properties.Keys) {
                if ($supported.ContainsKey($property) -and (-not $rule.from.Contains('kinds') -or @($rule.from.kinds | Where-Object { $_ -notin $supported[$property] }).Count)) {
                    throw "$($rule.id): $property needs an explicit selector of supported object kinds."
                }
            }
        }
    }
    return $config
}

function Read-ArchitectureFile($File, [string] $Root) {
    $text = [IO.File]::ReadAllText($File.FullName)
    $source = Hide-ALTrivia $text
    $code = Hide-ALTrivia $text -Identifiers
    $declarations = @(Get-ArchitectureMatches $source "^[ \t]*(?<kind>$script:ObjectKinds)\s+(?:\d+\s+)?(?<name>$script:Identifier)(?=\s|\{)")
    $identities = @($declarations | ForEach-Object { $_.Groups['kind'].Value + '|' + $_.Groups['name'].Value } | Sort-Object -Unique)
    if ($identities.Count -ne 1) { throw "$($File.FullName): expected one object identity in conventional AL declaration lines, found $($identities.Count)." }
    $declaration = $declarations[0]
    $namespace = @(Get-ArchitectureMatches $code '^\s*namespace\s+([A-Za-z_][A-Za-z0-9_.]*)\s*;')
    $headers = @(foreach ($item in $declarations) {
        $start = $code.IndexOf('{', $item.Index + $item.Length)
        if ($start -lt 0) { throw "$($File.FullName): object body not found." }
        $end = $start + 1
        while ($end -lt $code.Length -and $code[$end] -notin @('{', '}')) { $end++ }
        $header = $code.Substring($start + 1, $end - $start - 1)
        $header = [regex]::Split($header, '\b(?:var|procedure|trigger)\b', 'IgnoreCase')[0]
        [PSCustomObject]@{ Text = $header; Offset = $start + 1 }
    })
    [PSCustomObject]@{
        Path = $File.FullName.Substring($Root.Length + 1).Replace('\', '/')
        FullPath = $File.FullName; Text = $text; Source = $source; Code = $code
        Kind = $declaration.Groups['kind'].Value.ToLowerInvariant()
        Name = $(if ($declaration.Groups['name'].Value.StartsWith('"')) { $declaration.Groups['name'].Value.Substring(1, $declaration.Groups['name'].Value.Length - 2).Replace('""', '"') } else { $declaration.Groups['name'].Value })
        Namespace = $(if ($namespace.Count) { $namespace[0].Groups[1].Value } else { '' })
        Headers = $headers; DeclarationLine = 1 + [regex]::Matches($text.Substring(0, $declaration.Index), "`n").Count
    }
}

function Get-ArchitectureReferences($File) {
    $aliases = @{ record = 'table'; database = 'table'; tabledata = 'table'; testpage = 'page'; testrequestpage = 'report' }
    $properties = @{ SourceTable = 'table'; TableRelation = 'table'; LookupPageId = 'page'; DrillDownPageId = 'page'; CardPageId = 'page'; RoleCenter = 'page'; Profile = 'profile' }
    $bases = @{ tableextension = 'table'; pageextension = 'page'; pagecustomization = 'page'; enumextension = 'enum'; reportextension = 'report'; permissionsetextension = 'permissionset' }
    $types = 'record|database|tabledata|testpage|testrequestpage|codeunit|page|report|query|xmlport|enum|interface|permissionset|profile|table'
    # Only explicit type contexts and a few direct object-valued properties. No AL expression parsing.
    $pattern = '"(?:[^"]|"")*"|(?<![\w.])(?:(?<type>' + $types + ')\s*(?:::|\s)\s*|(?<property>' + ($properties.Keys -join '|') + ')\s*=\s*|(?<base>extends|customizes)\s+)(?<target>' + $script:QualifiedIdentifier + ')'
    foreach ($match in Get-ArchitectureMatches $File.Source $pattern) {
        if (-not $match.Groups['target'].Success) { continue }
        $kind = $match.Groups['type'].Value.ToLowerInvariant()
        if ($aliases.ContainsKey($kind)) { $kind = $aliases[$kind] }
        if ($match.Groups['property'].Success) { $kind = $properties[$match.Groups['property'].Value] }
        if ($match.Groups['base'].Success) {
            if (-not $bases.ContainsKey($File.Kind)) { continue }
            $kind = $bases[$File.Kind]
        }
        $parts = @(Get-ArchitectureMatches $match.Groups['target'].Value $script:Identifier | ForEach-Object {
            if ($_.Value.StartsWith('"')) { $_.Value.Substring(1, $_.Value.Length - 2).Replace('""', '"') } else { $_.Value }
        })
        # Only the simple TableRelation = Table[.Field] convention, not qualified/conditional expressions.
        if ($match.Groups['property'].Value -eq 'TableRelation') { $parts = @($parts[0]) }
        [PSCustomObject]@{
            Kind = $kind; Name = $parts[-1]
            Namespace = $(if ($parts.Count -gt 1) { $parts[0..($parts.Count - 2)] -join '.' } else { '' })
            Index = $match.Index
        }
    }
}

function New-ArchitectureFinding([string] $Target, [int] $Index, [string] $Detail) {
    [PSCustomObject]@{ Target = $Target; Index = $Index; Detail = $Detail }
}

function Get-ArchitectureFindings($Rule, $File, [object[]] $Files, [object[]] $References) {
    switch ($Rule.check) {
        'dependencies' {
            $targets = if ($Rule.Contains('to')) { @($Files | Where-Object { Test-ArchitectureSelector $_ $Rule.to }) } else {
                @($Rule.symbols | ForEach-Object { [PSCustomObject]@{ Kind = $_.kind; Name = $_.name; Namespace = ''; Path = "$($_.kind):$($_.name)"; FullPath = '' } })
            }
            foreach ($target in $targets) {
                if ($target.FullPath -eq $File.FullPath) { continue }
                $reference = @($References | Where-Object {
                    $_.Kind -eq $target.Kind -and $_.Name -eq $target.Name -and
                    (-not $_.Namespace -or -not $target.Namespace -or $_.Namespace -eq $target.Namespace)
                } | Select-Object -First 1)
                if ($reference.Count) {
                    New-ArchitectureFinding -Target $target.Path -Index $reference[0].Index -Detail "$($target.Kind) '$($target.Name)' ($($target.Path))"
                }
            }
        }
        'namespaces' {
            # Imports are intentionally a proxy, even if unused. Also catches fully qualified uses.
            foreach ($prefix in $Rule.namespaces) {
                $pattern = '(?<![\w.])' + [regex]::Escape($prefix) + '(?![A-Za-z0-9_])(?:\.[A-Za-z_][A-Za-z0-9_]*)*'
                $namespaceMatches = @(Get-ArchitectureMatches $File.Code $pattern)
                if ($namespaceMatches.Count) {
                    New-ArchitectureFinding -Target $prefix -Index $namespaceMatches[0].Index -Detail "namespace '$prefix' (import or qualified use)"
                }
            }
        }
        'properties' {
            foreach ($property in $Rule.properties.Keys) {
                foreach ($header in $File.Headers) {
                    $propertyMatches = @(Get-ArchitectureMatches $header.Text ('\b' + [regex]::Escape($property) + '\s*=\s*(?<value>\w+)\s*;'))
                    $valid = $propertyMatches.Count -eq 1 -and $propertyMatches[0].Groups['value'].Value -eq [string]$Rule.properties[$property]
                    if ($valid) {
                        $directives = @(Get-ArchitectureMatches $header.Text.Substring(0, $propertyMatches[0].Index) '^\s*#(?<directive>if|endif)\b')
                        $depth = 0
                        foreach ($directive in $directives) { if ($directive.Groups['directive'].Value -eq 'if') { $depth++ } else { $depth-- } }
                        $valid = $depth -eq 0
                    }
                    if (-not $valid) {
                        New-ArchitectureFinding -Target $property -Index $header.Offset -Detail "require unconditional object property $property = $($Rule.properties[$property])"
                    }
                }
            }
        }
        'forbiddenCode' {
            foreach ($match in Get-ArchitectureMatches $File.Code $Rule.pattern) {
                New-ArchitectureFinding -Target 'code' -Index $match.Index -Detail "forbidden code '$($match.Value.Trim())'"
            }
        }
        'developmentOnly' {
            # Require one outer #if SYMBOL, with no outer #else or content after #endif.
            $trimmed = $File.Source.Trim()
            $valid = $trimmed -match ('^#if\s+' + [regex]::Escape($Rule.symbol) + '\s*\r?\n')
            $depth = 0
            foreach ($directive in Get-ArchitectureMatches $trimmed '^\s*#(?<directive>if|else|endif)\b[^\r\n]*') {
                switch ($directive.Groups['directive'].Value.ToLowerInvariant()) {
                    'if' { $depth++ }
                    'endif' { $depth--; if ($depth -eq 0 -and $trimmed.Substring($directive.Index + $directive.Length).Trim()) { $valid = $false } }
                    default { if ($depth -eq 1) { $valid = $false } }
                }
                if ($depth -lt 0) { $valid = $false }
            }
            if (-not $valid -or $depth -ne 0) {
                New-ArchitectureFinding -Target $Rule.symbol -Index 0 -Detail "require whole file guarded by #if $($Rule.symbol)"
            }
        }
        'placement' {
            if (-not (Test-ArchitectureGlob $File.Path $Rule.allowedPaths)) {
                New-ArchitectureFinding -Target 'path' -Index 0 -Detail "unapproved object path '$($File.Path)'"
            }
            if ($File.Namespace -ne $Rule.namespace) {
                New-ArchitectureFinding -Target 'namespace' -Index 0 -Detail "require namespace $($Rule.namespace)"
            }
        }
        'manifest' {
            $manifest = ConvertFrom-Json -InputObject $File.Text -AsHashtable
            foreach ($symbol in @($(if ($manifest.Contains('preprocessorSymbols')) { $manifest.preprocessorSymbols }))) {
                if ($Rule.Contains('forbiddenSymbols') -and $symbol -in $Rule.forbiddenSymbols) {
                    New-ArchitectureFinding -Target "symbol:$symbol" -Index 0 -Detail "production manifest enables $symbol"
                }
            }
            foreach ($friend in @($(if ($manifest.Contains('internalsVisibleTo')) { $manifest.internalsVisibleTo }))) {
                if ($null -ne $friend -and $Rule.Contains('allowedFriends') -and $friend.id -notin $Rule.allowedFriends) {
                    New-ArchitectureFinding -Target "friend:$($friend.id)" -Index 0 -Detail "unapproved friend app '$($friend.name)'"
                }
            }
            foreach ($dependency in @($(if ($manifest.Contains('dependencies')) { $manifest.dependencies }))) {
                if ($null -ne $dependency -and $Rule.Contains('forbiddenDependencies') -and ((Test-ArchitectureGlob $dependency.name $Rule.forbiddenDependencies) -or $dependency.id -in $Rule.forbiddenDependencies)) {
                    New-ArchitectureFinding -Target "dependency:$($dependency.id)" -Index 0 -Detail "forbidden manifest dependency '$($dependency.name)'"
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Evaluates lightweight architectural conventions over an AL application.
.PARAMETER AppRoot
    Root directory of the AL app to scan, including all preprocessor branches.
.PARAMETER RulesPath
    App-owned architecture-rules.json policy.
.PARAMETER SchemaPath
    JSON schema used to validate the policy, beside RulesPath by default.
.OUTPUTS
    An object containing object/reference/rule counts and deterministic diagnostics.
    Policy errors are returned as diagnostics; invalid configuration or unreadable
    inputs throw. The script entry point decides whether warnings fail the build.
#>
function Invoke-ALArchitectureRules {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory)] [string] $AppRoot, [Parameter(Mandatory)] [string] $RulesPath,
        [string] $SchemaPath = (Join-Path (Split-Path $RulesPath -Parent) 'architecture-rules.schema.json'))
    $config = Read-ALArchitectureRules $RulesPath $SchemaPath
    $root = (Get-Item -LiteralPath $AppRoot -ErrorAction Stop).FullName.TrimEnd('/', '\')
    $files = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.al' -ErrorAction Stop | Sort-Object FullName | ForEach-Object { Read-ArchitectureFile $_ $root })
    if (-not $files.Count) { throw "No AL files found under $root" }
    $references = @{}
    foreach ($file in $files) { $references[$file.Path] = @(Get-ArchitectureReferences $file) }
    $diagnostics = @()
    foreach ($rule in $config.rules) {
        $used = @{}
        $selected = @(if ($rule.check -eq 'manifest') {
            @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.json' | ForEach-Object {
                [PSCustomObject]@{ Path = $_.FullName.Substring($root.Length + 1).Replace('\', '/'); FullPath = $_.FullName; Kind = ''; Text = [IO.File]::ReadAllText($_.FullName) }
            } | Where-Object { Test-ArchitectureSelector $_ $rule.from })
        } else { $files | Where-Object { Test-ArchitectureSelector $_ $rule.from } })
        if (-not $selected.Count) { throw "$($rule.id): source selector matches no files." }
        if ($rule.check -eq 'dependencies' -and $rule.Contains('to') -and -not @($files | Where-Object { Test-ArchitectureSelector $_ $rule.to }).Count) { throw "$($rule.id): target selector matches no objects." }
        foreach ($file in $selected) {
            $fileReferences = @()
            if ($references.ContainsKey($file.Path)) { $fileReferences = @($references[$file.Path]) }
            foreach ($finding in @(Get-ArchitectureFindings -Rule $rule -File $file -Files $files -References $fileReferences)) {
                $excepted = $false
                if ($rule.Contains('exceptions')) {
                    for ($i = 0; $i -lt $rule.exceptions.Count; $i++) {
                        $exception = $rule.exceptions[$i]
                        if ((Test-ArchitectureSelector $file $exception.from) -and (-not $exception.Contains('target') -or (Test-ArchitectureGlob $finding.Target @($exception.target)))) {
                            $used[$i] = $true; $excepted = $true
                        }
                    }
                }
                if (-not $excepted) {
                    $diagnostics += [PSCustomObject]@{ RuleId = $rule.id; Severity = $rule.severity; Path = $file.FullPath
                        Line = 1 + [regex]::Matches($file.Text.Substring(0, $finding.Index), "`n").Count
                        Message = "$($rule.description) $($finding.Detail)." }
                }
            }
        }
        if ($rule.Contains('exceptions')) {
            for ($i = 0; $i -lt $rule.exceptions.Count; $i++) {
                if (-not $used.ContainsKey($i)) { $diagnostics += [PSCustomObject]@{ RuleId = 'CONFIG'; Severity = 'error'; Path = [IO.Path]::GetFullPath($RulesPath); Line = 1; Message = "Unused exception $($rule.id)[$i]: $($rule.exceptions[$i].reason)" } }
            }
        }
    }
    [PSCustomObject]@{ ObjectCount = $files.Count; ReferenceCount = @($references.Values | ForEach-Object { $_ }).Count
        RuleCount = $config.rules.Count; Diagnostics = @($diagnostics | Sort-Object Path, Line, RuleId, Message -Unique) }
}

Export-ModuleMember -Function Invoke-ALArchitectureRules
