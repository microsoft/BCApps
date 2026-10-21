# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

Set-StrictMode -Version 2.0

$script:ObjectKinds = @('table', 'tableextension', 'page', 'pageextension', 'pagecustomization', 'codeunit', 'enum', 'enumextension', 'interface', 'report', 'reportextension', 'query', 'xmlport', 'permissionset', 'permissionsetextension', 'profile', 'controladdin', 'entitlement')
$script:ReferenceKinds = @('type', 'object', 'sourceTable', 'tableRelation', 'permission', 'extends', 'implements', 'pagePart', 'dataItem', 'calcFormula', 'property')

function Assert-ALRuleProperties {
    param($Value, [string[]] $Required, [string[]] $Optional, [string] $Location)
    if ($null -eq $Value -or $Value -isnot [PSCustomObject]) {
        throw "${Location}: expected a JSON object."
    }
    $names = @($Value.PSObject.Properties | ForEach-Object { $_.Name })
    foreach ($name in $Required) {
        if ($names -cnotcontains $name) { throw "${Location}: missing '$name'." }
    }
    foreach ($name in $names) {
        if (@($Required) + @($Optional) -cnotcontains $name) { throw "${Location}: unknown property '$name'." }
    }
}

function Assert-ALRuleStrings {
    param($Value, [string] $Location, [string[]] $Allowed = @())
    if ($Value -isnot [Array] -or $Value.Count -eq 0) { throw "${Location}: expected a non-empty JSON array." }
    foreach ($item in $Value) {
        if ($item -isnot [string] -or [string]::IsNullOrWhiteSpace($item)) { throw "${Location}: expected non-empty strings." }
        if ($Allowed.Count -gt 0 -and $Allowed -cnotcontains $item) { throw "${Location}: unsupported value '$item'." }
    }
}

function Assert-ALRuleSelector {
    param($Selector, [string] $Location)
    Assert-ALRuleProperties $Selector @() @('paths', 'kinds', 'names', 'namespaces', 'catalogs') $Location
    if (@($Selector.PSObject.Properties).Count -eq 0) { throw "${Location}: an empty selector would match everything; use an explicit wildcard instead." }
    foreach ($property in $Selector.PSObject.Properties) {
        $allowed = @()
        if ($property.Name -eq 'kinds') { $allowed = $script:ObjectKinds }
        Assert-ALRuleStrings $property.Value "$Location.$($property.Name)" $allowed
        if ($property.Name -eq 'paths') {
            foreach ($path in $property.Value) {
                if ($path.Contains('\') -or $path.StartsWith('/') -or $path -match '(^|/)\.\.(/|$)|^[A-Za-z]:') {
                    throw "${Location}: selector paths must be relative, forward-slash paths."
                }
            }
        }
    }
}

function Read-ALDependencyRules {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $Path)
    $configuration = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    # Deliberately validate here as well as in the editor schema: Windows PowerShell 5.1 has no Test-Json.
    Assert-ALRuleProperties $configuration @('version', 'catalogs', 'rules') @('$schema') 'rules file'
    if ($configuration.PSObject.Properties['$schema'] -and $configuration.'$schema' -isnot [string]) { throw '$schema must be a string.' }
    if ($configuration.version -isnot [ValueType] -or $configuration.version -is [bool] -or $configuration.version -ne 1) { throw 'Unsupported dependency rules version; expected 1.' }
    if ($configuration.catalogs -isnot [Array]) { throw 'catalogs must be a JSON array.' }
    $catalogIds = @('app', 'external')
    foreach ($catalog in $configuration.catalogs) {
        Assert-ALRuleProperties $catalog @('id', 'path') @() 'catalog'
        if ($catalog.id -isnot [string] -or $catalog.id -notmatch '^[a-zA-Z][a-zA-Z0-9-]*$' -or $catalogIds -contains $catalog.id) { throw "Invalid or duplicate catalog id '$($catalog.id)'." }
        if ($catalog.path -isnot [string] -or [string]::IsNullOrWhiteSpace($catalog.path) -or [IO.Path]::IsPathRooted($catalog.path) -or $catalog.path -match '^[A-Za-z]:') { throw 'Catalog paths must be non-empty paths relative to AppRoot.' }
        $catalogIds += $catalog.id
    }
    if ($configuration.rules -isnot [Array] -or $configuration.rules.Count -eq 0) { throw 'rules must be a non-empty JSON array.' }
    $ids = @()
    foreach ($rule in $configuration.rules) {
        Assert-ALRuleProperties $rule @('id', 'description', 'severity', 'from', 'to') @('referenceKinds', 'includeTemporary', 'exceptions') 'rule'
        if ($rule.id -isnot [string] -or $rule.id -notmatch '^[A-Z][A-Z0-9-]*$' -or $ids -contains $rule.id) { throw "Invalid or duplicate rule id '$($rule.id)'." }
        $ids += $rule.id
        if ($rule.description -isnot [string] -or [string]::IsNullOrWhiteSpace($rule.description)) { throw "$($rule.id): description is required." }
        if (@('error', 'warning') -cnotcontains $rule.severity) { throw "$($rule.id): severity must be error or warning." }
        Assert-ALRuleSelector $rule.from "$($rule.id).from"
        Assert-ALRuleSelector $rule.to "$($rule.id).to"
        if ($rule.PSObject.Properties['referenceKinds']) { Assert-ALRuleStrings $rule.referenceKinds "$($rule.id).referenceKinds" $script:ReferenceKinds }
        if ($rule.PSObject.Properties['includeTemporary'] -and $rule.includeTemporary -isnot [bool]) { throw "$($rule.id): includeTemporary must be a boolean." }
        if ($rule.PSObject.Properties['exceptions']) {
            if ($rule.exceptions -isnot [Array]) { throw "$($rule.id): exceptions must be an array." }
            foreach ($exception in $rule.exceptions) {
                Assert-ALRuleProperties $exception @('from', 'reason') @('to', 'referenceKinds') "$($rule.id) exception"
                Assert-ALRuleSelector $exception.from "$($rule.id) exception.from"
                if ($exception.reason -isnot [string] -or [string]::IsNullOrWhiteSpace($exception.reason)) { throw "$($rule.id): exceptions require a reason." }
                if ($exception.PSObject.Properties['to']) { Assert-ALRuleSelector $exception.to "$($rule.id) exception.to" }
                if ($exception.PSObject.Properties['referenceKinds']) { Assert-ALRuleStrings $exception.referenceKinds "$($rule.id) exception.referenceKinds" $script:ReferenceKinds }
            }
        }
        $selectors = @($rule.from, $rule.to)
        if ($rule.PSObject.Properties['exceptions']) {
            foreach ($exception in $rule.exceptions) {
                $selectors += $exception.from
                if ($exception.PSObject.Properties['to']) { $selectors += $exception.to }
            }
        }
        foreach ($selector in $selectors) {
            if ($selector.PSObject.Properties['catalogs']) {
                foreach ($catalogId in $selector.catalogs) {
                    if ($catalogId -ne 'external' -and $catalogIds -notcontains $catalogId) { throw "$($rule.id): unknown catalog '$catalogId'." }
                }
            }
        }
    }
    return $configuration
}

function Get-ALDependencyTokens {
    param([string] $Text, [string] $Path)
    # Single-quoted values are NOT identifiers. Keep them as opaque tokens so an event's
    # string argument cannot accidentally be interpreted as an object reference.
    $pattern = '(?<directive>\#[^\r\n]*)|(?<skip>//[^\r\n]*|/\*[\s\S]*?\*/|\s+)|(?<string>''(?:[^'']|'''')*'')|(?<quoted>"(?:[^"]|"")*")|(?<word>[A-Za-z_][A-Za-z_0-9]*)|(?<number>\d+)|(?<symbol>::|:=|.)'
    $line = 1
    $conditionalDepth = 0
    foreach ($match in [regex]::Matches($Text, $pattern)) {
        $value = $match.Value
        if ($match.Groups['directive'].Success) {
            if ($value -match '^#if\b') { $conditionalDepth++ }
            if ($value -match '^#endif\b') { $conditionalDepth-- }
            if ($conditionalDepth -lt 0) { throw "${Path}:${line}: unmatched #endif." }
        }
        elseif (-not $match.Groups['skip'].Success) {
            $kind = 'symbol'
            foreach ($candidate in @('string', 'quoted', 'word', 'number')) {
                if ($match.Groups[$candidate].Success) { $kind = $candidate; break }
            }
            if (($kind -eq 'symbol' -and $value -in @("'", '"')) -or ($value -eq '/' -and $Text.Substring($match.Index).StartsWith('/*'))) {
                throw "${Path}:${line}: unterminated AL string, identifier, or comment."
            }
            if ($kind -eq 'quoted') { $value = $value.Substring(1, $value.Length - 2).Replace('""', '"') }
            [PSCustomObject]@{ Value = $value; Kind = $kind; Line = $line; Conditional = ($conditionalDepth -gt 0) }
        }
        $line += ([regex]::Matches($match.Value, "`n")).Count
    }
    if ($conditionalDepth -ne 0) { throw "${Path}: unmatched #if." }
}

function Get-ALDependencyObject {
    param([IO.FileInfo] $File, [string] $Root, [string] $Catalog)
    $rootPrefix = $Root.TrimEnd('/', '\') + [IO.Path]::DirectorySeparatorChar
    if (-not $File.FullName.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw "Cannot construct a catalog-relative path for '$($File.FullName)' under '$Root'." }
    $text = [IO.File]::ReadAllText($File.FullName)
    $tokens = @(Get-ALDependencyTokens $text $File.FullName)
    $declarations = @()
    for ($i = 0; $i -lt $tokens.Count - 2; $i++) {
        if ($tokens[$i].Kind -ne 'word' -or $script:ObjectKinds -notcontains $tokens[$i].Value.ToLowerInvariant()) { continue }
        $nameIndex = $i + 1
        $id = ''
        if ($tokens[$nameIndex].Kind -eq 'number') { $id = $tokens[$nameIndex].Value; $nameIndex++ }
        # A definition is followed by a body, extends/customizes, or implements, unlike a variable or permission.
        if ($tokens[$nameIndex].Kind -notin @('word', 'quoted') -or $tokens[$nameIndex + 1].Value -notin @('{', 'extends', 'customizes', 'implements')) { continue }
        $declarations += [PSCustomObject]@{ Index = $i; Name = $tokens[$nameIndex].Value; Id = $id; Kind = $tokens[$i].Value.ToLowerInvariant() }
    }
    # An AL file can repeat its declaration across #if branches (for example, different implements lists).
    $identities = @($declarations | Group-Object Kind, Id, Name)
    if ($identities.Count -ne 1) { throw "$($File.FullName): expected one AL object identity, found $($identities.Count)." }
    $declaration = $declarations[0]
    $namespace = ''
    $usings = @()
    for ($i = 0; $i -lt $declaration.Index; $i++) {
        if ($tokens[$i].Value -notin @('namespace', 'using')) { continue }
        $keyword = $tokens[$i].Value
        $parts = @()
        for ($j = $i + 1; $j -lt $tokens.Count -and $tokens[$j].Value -ne ';'; $j++) { $parts += $tokens[$j].Value }
        if ($keyword -eq 'namespace') { $namespace = $parts -join '' } else { $usings += $parts -join '' }
    }
    $temporary = $false
    $temporarySource = $false
    for ($i = $declaration.Index; $i -lt $tokens.Count - 2; $i++) {
        # A temporary property in only one #if branch must not hide a persistent alternative.
        if ($tokens[$i].Kind -ne 'word' -or $tokens[$i + 1].Value -ne '=' -or $tokens[$i].Conditional -or $tokens[$i - 1].Value -notin @('{', ';')) { continue }
        if ($tokens[$i].Value -eq 'TableType' -and $tokens[$i + 2].Value -eq 'Temporary') { $temporary = $true }
        if ($tokens[$i].Value -eq 'SourceTableTemporary' -and $tokens[$i + 2].Value -eq 'true') { $temporarySource = $true }
    }
    # Catalog definitions are only used for resolution; retain full token streams for app objects alone.
    $retainedTokens = @()
    if ($Catalog -eq 'app') { $retainedTokens = $tokens }
    [PSCustomObject]@{
        Kind = $declaration.Kind; Name = $declaration.Name; Id = $declaration.Id
        Namespace = $namespace; Catalog = $Catalog
        Path = $File.FullName.Substring($rootPrefix.Length).Replace('\', '/')
        FullPath = $File.FullName; Tokens = $retainedTokens; DeclarationIndex = $declaration.Index
        Usings = $usings; Temporary = $temporary; TemporarySource = $temporarySource
    }
}

function Resolve-ALDependencyTarget {
    param($Source, [object[]] $Tokens, [int] $Start, [string] $Kind, [hashtable] $Index)
    if ($Start -ge $Tokens.Count -or $Tokens[$Start].Kind -notin @('word', 'quoted', 'number')) { return }
    $parts = @($Tokens[$Start].Value)
    $ends = @($Start)
    $cursor = $Start
    while ($cursor + 2 -lt $Tokens.Count -and $Tokens[$cursor + 1].Value -eq '.' -and $Tokens[$cursor + 2].Kind -in @('word', 'quoted')) {
        $parts += $Tokens[$cursor + 2].Value
        $cursor += 2
        $ends += $cursor
    }
    for ($length = $parts.Count; $length -gt 0; $length--) {
        $name = $parts[0..($length - 1)] -join '.'
        $key = "$Kind|$name"
        if (-not $Index.ContainsKey($key)) { continue }
        $candidates = @($Index[$key])
        if ($candidates.Count -gt 1) {
            $visible = @($candidates | Where-Object { $_.Namespace -eq $Source.Namespace })
            if ($visible.Count -eq 0) { $visible = @($candidates | Where-Object { $Source.Usings -contains $_.Namespace }) }
            if ($visible.Count -ne 1) { throw "$($Source.FullPath):$($Tokens[$Start].Line): ambiguous $Kind reference '$name'. Qualify its namespace." }
            $candidates = $visible
        }
        return [PSCustomObject]@{ Target = $candidates[0]; End = $ends[$length - 1] }
    }
    # Framework/package symbols outside the configured source catalogs still participate in name/kind rules.
    # Their namespace/path cannot be inferred from 'using' statements; do not invent one.
    $name = $parts -join '.'
    $namespace = ''
    if ($parts.Count -gt 1) { $namespace = $parts[0..($parts.Count - 2)] -join '.'; $name = $parts[-1] }
    [PSCustomObject]@{
        Target = [PSCustomObject]@{ Kind = $Kind; Name = $name; Id = ''; Namespace = $namespace; Catalog = 'external'; Path = ''; FullPath = ''; Temporary = $false }
        End = $ends[-1]
    }
}

function Get-ALTableRelationStarts {
    param([object[]] $Tokens, [int] $Start)
    $depth = 0
    $expectTable = $true
    for ($i = $Start; $i -lt $Tokens.Count; $i++) {
        $token = $Tokens[$i]
        if ($token.Value -eq ';' -and $depth -eq 0) { break }
        if ($token.Value -eq '(') { $depth++; continue }
        if ($token.Value -eq ')') { $depth--; continue }
        if ($depth -ne 0 -or $token.Kind -notin @('word', 'quoted', 'number')) { continue }
        if ($token.Kind -eq 'word' -and $token.Value -eq 'else') { $expectTable = $true; continue }
        if ($token.Kind -eq 'word' -and $token.Value -eq 'if') { continue }
        if ($expectTable) { $i; $expectTable = $false }
    }
}

function Get-ALObjectDependencies {
    param($Source, [hashtable] $Index)
    $tokens = $Source.Tokens
    $typeMap = @{ record = 'table'; testpage = 'page'; testrequestpage = 'report'; database = 'table'; tabledata = 'table' }
    foreach ($kind in $script:ObjectKinds) { $typeMap[$kind] = $kind }
    $properties = @{ SourceTable = 'table'; TableRelation = 'table'; LookupPageId = 'page'; DrillDownPageId = 'page'; CardPageId = 'page'; RoleCenter = 'page'; Profile = 'profile' }
    $seen = @{}
    for ($i = $Source.DeclarationIndex + 1; $i -lt $tokens.Count - 1; $i++) {
        $token = $tokens[$i]
        # AL also permits [Namespace.]EnumName::Value without the explicit Enum:: prefix.
        if ($token.Kind -in @('word', 'quoted') -and $tokens[$i + 1].Value -in @('.', '::') -and $tokens[$i - 1].Value -notin @('.', '::')) {
            $enumParts = @($token.Value)
            $enumEnd = $i
            while ($enumEnd + 2 -lt $tokens.Count -and $tokens[$enumEnd + 1].Value -eq '.' -and $tokens[$enumEnd + 2].Kind -in @('word', 'quoted')) {
                $enumEnd += 2
                $enumParts += $tokens[$enumEnd].Value
            }
            if ($enumEnd + 1 -lt $tokens.Count -and $tokens[$enumEnd + 1].Value -eq '::' -and $Index.ContainsKey("enum|$($enumParts -join '.')")) {
                $resolvedEnum = Resolve-ALDependencyTarget $Source $tokens $i 'enum' $Index
                $enumKey = "$($resolvedEnum.Target.Catalog)|enum|$($resolvedEnum.Target.Namespace)|$($resolvedEnum.Target.Name)|object|False"
                if ($resolvedEnum.Target.FullPath -ne $Source.FullPath -and -not $seen.ContainsKey($enumKey)) {
                    $seen[$enumKey] = $true
                    [PSCustomObject]@{ Source = $Source; Target = $resolvedEnum.Target; ReferenceKind = 'object'; Temporary = $false; Line = $token.Line }
                }
            }
        }
        if ($token.Kind -ne 'word') { continue }
        $word = $token.Value.ToLowerInvariant()
        $start = -1
        $kind = ''
        $referenceKind = 'object'
        if ($typeMap.ContainsKey($word)) {
            if ($tokens[$i + 1].Value -eq '::') { $start = $i + 2; $kind = $typeMap[$word] }
            elseif ($tokens[$i - 1].Value -eq ':') { $start = $i + 1; $kind = $typeMap[$word]; $referenceKind = 'type' }
            elseif ($tokens[$i + 1].Value -eq '.' -and $i + 4 -lt $tokens.Count -and $tokens[$i + 2].Value -in @('Run', 'RunModal') -and $tokens[$i + 3].Value -eq '(') { $start = $i + 4; $kind = $typeMap[$word] }
            elseif ($word -eq 'tabledata' -or ($tokens[$i - 1].Value -in @('=', ',') -and $tokens[$i - 2].Value -ne 'RunObject')) { $start = $i + 1; $kind = $typeMap[$word]; $referenceKind = 'permission' }
        }
        if ($properties.ContainsKey($word) -and $tokens[$i + 1].Value -eq '=') {
            $kind = $properties[$word]; $start = $i + 2; $referenceKind = 'property'
            if ($word -eq 'sourcetable') { $referenceKind = 'sourceTable' }
            if ($word -eq 'tablerelation') { $referenceKind = 'tableRelation' }
        }
        if ($word -eq 'runobject' -and $tokens[$i + 1].Value -eq '=' -and $i + 3 -lt $tokens.Count -and $typeMap.ContainsKey($tokens[$i + 2].Value)) {
            $kind = $typeMap[$tokens[$i + 2].Value]; $start = $i + 3; $referenceKind = 'property'
        }
        if ($word -in @('extends', 'customizes')) {
            $baseKinds = @{ tableextension = 'table'; pageextension = 'page'; pagecustomization = 'page'; enumextension = 'enum'; reportextension = 'report'; permissionsetextension = 'permissionset' }
            if ($baseKinds.ContainsKey($Source.Kind)) { $kind = $baseKinds[$Source.Kind]; $start = $i + 1; $referenceKind = 'extends' }
        }
        if ($word -in @('part', 'dataitem') -and $tokens[$i + 1].Value -eq '(') {
            for ($j = $i + 2; $j -lt $tokens.Count -and $tokens[$j].Value -notin @(';', ')'); $j++) { }
            if ($j -lt $tokens.Count -and $tokens[$j].Value -eq ';') {
                $start = $j + 1; $kind = 'page'; $referenceKind = 'pagePart'
                if ($word -eq 'dataitem') { $kind = 'table'; $referenceKind = 'dataItem' }
            }
        }
        if ($word -eq 'implements') { $kind = 'interface'; $start = $i + 1; $referenceKind = 'implements' }
        if ($word -in @('includedpermissionsets', 'excludedpermissionsets') -and $tokens[$i + 1].Value -eq '=') { $kind = 'permissionset'; $start = $i + 2; $referenceKind = 'permission' }
        if ($word -in @('lookup', 'sum', 'count', 'exist', 'average', 'min', 'max') -and $i -ge 2 -and ($tokens[$i - 2].Value -eq 'CalcFormula' -or ($i -ge 3 -and $tokens[$i - 1].Value -eq '-' -and $tokens[$i - 3].Value -eq 'CalcFormula')) -and $tokens[$i + 1].Value -eq '(') {
            $kind = 'table'; $start = $i + 2; $referenceKind = 'calcFormula'
        }
        if ($start -lt 0) { continue }
        $starts = @($start)
        if ($referenceKind -eq 'tableRelation') { $starts = @(Get-ALTableRelationStarts $tokens $start) }
        foreach ($start in $starts) {
            do {
                $resolved = Resolve-ALDependencyTarget $Source $tokens $start $kind $Index
                if ($null -eq $resolved) { break }
                $target = $resolved.Target
                $temporary = $target.Temporary -or ($resolved.End + 1 -lt $tokens.Count -and $tokens[$resolved.End + 1].Value -eq 'temporary') -or ($referenceKind -eq 'sourceTable' -and $Source.TemporarySource)
                $key = "$($target.Catalog)|$($target.Kind)|$($target.Namespace)|$($target.Name)|$referenceKind|$temporary"
                if ($target.FullPath -ne $Source.FullPath -and -not $seen.ContainsKey($key)) {
                    $seen[$key] = $true
                    [PSCustomObject]@{ Source = $Source; Target = $target; ReferenceKind = $referenceKind; Temporary = $temporary; Line = $tokens[$start].Line }
                }
                $start = $resolved.End + 2
            } while ($referenceKind -in @('implements', 'permission') -and $resolved.End + 1 -lt $tokens.Count -and $tokens[$resolved.End + 1].Value -eq ',')
        }
    }
}

function Test-ALDependencySelector {
    param($Object, $Selector)
    $fields = @{ paths = 'Path'; kinds = 'Kind'; names = 'Name'; namespaces = 'Namespace'; catalogs = 'Catalog' }
    foreach ($property in $Selector.PSObject.Properties) {
        $value = [string]$Object.($fields[$property.Name])
        $matched = $false
        foreach ($pattern in $property.Value) {
            # Deliberately only * and ? globs. Matching is case-insensitive, like AL; * also spans '/'.
            $regex = '^' + [regex]::Escape($pattern).Replace('\*', '.*').Replace('\?', '.') + '$'
            if ($value -match $regex) { $matched = $true; break }
        }
        if (-not $matched) { return $false }
    }
    return $true
}

function Invoke-ALDependencyRules {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $AppRoot, [Parameter(Mandatory)] [string] $RulesPath)
    $configuration = Read-ALDependencyRules $RulesPath
    # Get-Item expands Windows 8.3 paths, unlike Resolve-Path. FileInfo.FullName also uses
    # expanded paths; substring-based relative paths must never mix those representations.
    $root = (Get-Item -LiteralPath $AppRoot -ErrorAction Stop).FullName.TrimEnd('/', '\')
    $catalogs = @([PSCustomObject]@{ id = 'app'; path = $root })
    foreach ($catalog in $configuration.catalogs) { $catalogs += [PSCustomObject]@{ id = $catalog.id; path = [IO.Path]::GetFullPath((Join-Path $root $catalog.path)) } }
    $objects = @()
    foreach ($catalog in $catalogs) {
        $directory = Get-Item -LiteralPath $catalog.path -ErrorAction Stop
        if (-not $directory.PSIsContainer) { throw "Catalog '$($catalog.id)' must be a directory: $($catalog.path)" }
        $catalogRoot = $directory.FullName.TrimEnd('/', '\')
        $files = @(Get-ChildItem -LiteralPath $catalogRoot -Recurse -File -Filter '*.al' -ErrorAction Stop | Sort-Object FullName)
        if ($files.Count -eq 0) { throw "Catalog '$($catalog.id)' contains no AL files: $catalogRoot" }
        foreach ($file in $files) { $objects += Get-ALDependencyObject $file $catalogRoot $catalog.id }
    }
    $index = @{}
    foreach ($object in $objects) {
        $keys = @("$($object.Kind)|$($object.Name)")
        if ($object.Namespace) { $keys += "$($object.Kind)|$($object.Namespace).$($object.Name)" }
        if ($object.Id) { $keys += "$($object.Kind)|$($object.Id)" }
        foreach ($key in $keys | Select-Object -Unique) {
            if (-not $index.ContainsKey($key)) { $index[$key] = @() }
            $index[$key] += $object
        }
    }
    $sources = @($objects | Where-Object { $_.Catalog -eq 'app' })
    $dependencies = @(foreach ($source in $sources) { Get-ALObjectDependencies $source $index })
    $diagnostics = @()
    $usedExceptions = @{}
    foreach ($rule in $configuration.rules) {
        foreach ($dependency in $dependencies) {
            if (-not (Test-ALDependencySelector $dependency.Source $rule.from) -or -not (Test-ALDependencySelector $dependency.Target $rule.to)) { continue }
            if ($rule.PSObject.Properties['referenceKinds'] -and $rule.referenceKinds -notcontains $dependency.ReferenceKind) { continue }
            if ($rule.PSObject.Properties['includeTemporary'] -and -not $rule.includeTemporary -and $dependency.Temporary) { continue }
            $excepted = $false
            if ($rule.PSObject.Properties['exceptions']) {
                for ($i = 0; $i -lt $rule.exceptions.Count; $i++) {
                    $exception = $rule.exceptions[$i]
                    if (-not (Test-ALDependencySelector $dependency.Source $exception.from)) { continue }
                    if ($exception.PSObject.Properties['to'] -and -not (Test-ALDependencySelector $dependency.Target $exception.to)) { continue }
                    if ($exception.PSObject.Properties['referenceKinds'] -and $exception.referenceKinds -notcontains $dependency.ReferenceKind) { continue }
                    $usedExceptions["$($rule.id)|$i"] = $true
                    $excepted = $true
                }
            }
            if (-not $excepted) {
                $diagnostics += [PSCustomObject]@{
                    RuleId = $rule.id; Severity = $rule.severity; Path = $dependency.Source.FullPath; Line = $dependency.Line
                    Message = "$($rule.description) $($dependency.Source.Kind) '$($dependency.Source.Name)' -> $($dependency.Target.Kind) '$($dependency.Target.Name)' [$($dependency.ReferenceKind), catalog=$($dependency.Target.Catalog)]."
                }
            }
        }
        if ($rule.PSObject.Properties['exceptions']) {
            for ($i = 0; $i -lt $rule.exceptions.Count; $i++) {
                if (-not $usedExceptions.ContainsKey("$($rule.id)|$i")) {
                    $diagnostics += [PSCustomObject]@{ RuleId = 'CONFIG'; Severity = 'error'; Path = [IO.Path]::GetFullPath($RulesPath); Line = 1; Message = "Unused exception $($rule.id)[$i]: $($rule.exceptions[$i].reason) Remove it or correct its selectors." }
                }
            }
        }
    }
    [PSCustomObject]@{ ObjectCount = $sources.Count; CatalogObjectCount = $objects.Count - $sources.Count; DependencyCount = $dependencies.Count; Diagnostics = @($diagnostics | Sort-Object Path, Line, RuleId, Message) }
}

Export-ModuleMember -Function Read-ALDependencyRules, Invoke-ALDependencyRules
