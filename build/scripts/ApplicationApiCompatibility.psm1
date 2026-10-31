#requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Read-ApplicationApiPackage {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [switch] $IncludeSymbols
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 44 -or [System.Text.Encoding]::ASCII.GetString($bytes, 0, 4) -cne 'NAVX' -or
        [System.BitConverter]::ToUInt32($bytes, 40) -ne 0x04034b50) {
        throw "Unsupported package envelope in '$Path'; expected a 40-byte NAVX header followed by ZIP data."
    }

    $stream = [System.IO.MemoryStream]::new($bytes, 40, $bytes.Length - 40)
    $zip = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Read)
    try {
        $entries = @($zip.Entries | Where-Object { $_.FullName -ceq 'NavxManifest.xml' })
        if ($entries.Count -ne 1) {
            throw "Expected exactly one NavxManifest.xml in '$Path'."
        }
        $settings = [System.Xml.XmlReaderSettings]::new()
        $settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
        $settings.XmlResolver = $null
        $manifestStream = $entries[0].Open()
        $reader = [System.Xml.XmlReader]::Create($manifestStream, $settings)
        try {
            $manifest = [System.Xml.XmlDocument]::new()
            $manifest.Load($reader)
        }
        finally {
            $reader.Dispose()
            $manifestStream.Dispose()
        }
        $namespaces = [System.Xml.XmlNamespaceManager]::new($manifest.NameTable)
        $namespaces.AddNamespace('m', 'http://schemas.microsoft.com/navx/2015/manifest')
        $app = $manifest.SelectSingleNode('/m:Package/m:App', $namespaces)
        if ($null -eq $app -or -not $app.GetAttribute('Name') -or -not $app.GetAttribute('Publisher')) {
            throw "Missing application identity in '$Path'."
        }
        $dependencies = @(
            foreach ($dependency in $manifest.SelectNodes('/m:Package/m:Dependencies/m:Dependency', $namespaces)) {
                if (-not $dependency.GetAttribute('Name') -or -not $dependency.GetAttribute('Publisher')) {
                    throw "Missing dependency identity in '$Path'."
                }
                [PSCustomObject]@{
                    Id = ([guid]$dependency.GetAttribute('Id')).ToString()
                    Name = $dependency.GetAttribute('Name')
                    Publisher = $dependency.GetAttribute('Publisher')
                    MinVersion = [version]$dependency.GetAttribute('MinVersion')
                }
            }
        )
        $document = $null
        if ($IncludeSymbols) {
            $entries = @($zip.Entries | Where-Object { $_.FullName -ceq 'SymbolReference.json' })
            if ($entries.Count -ne 1) {
                throw "Expected exactly one SymbolReference.json in '$Path'."
            }
            $symbolStream = $entries[0].Open()
            try {
                $document = [System.Text.Json.JsonDocument]::Parse($symbolStream)
            }
            finally {
                $symbolStream.Dispose()
            }
        }
        [PSCustomObject]@{
            Id = ([guid]$app.GetAttribute('Id')).ToString()
            Name = $app.GetAttribute('Name')
            Publisher = $app.GetAttribute('Publisher')
            Version = [version]$app.GetAttribute('Version')
            PropagateDependencies = $app.GetAttribute('PropagateDependencies') -ieq 'true'
            Dependencies = $dependencies
            Path = $Path
            Document = $document
        }
    }
    finally {
        $zip.Dispose()
        $stream.Dispose()
    }
}

function Write-ApplicationApiContract {
    param(
        [System.Text.Json.JsonElement] $Element,
        [System.Text.Json.Utf8JsonWriter] $Writer,
        [string[]] $IgnoredProperties = @()
    )

    switch ($Element.ValueKind) {
        Object {
            $Writer.WriteStartObject()
            foreach ($property in @($Element.EnumerateObject() | Sort-Object Name -CaseSensitive)) {
                if ($property.Name -ceq 'ReferenceSourceFileName' -or $property.Name -cin $IgnoredProperties) { continue }
                $Writer.WritePropertyName($property.Name)
                Write-ApplicationApiContract -Element $property.Value -Writer $Writer
            }
            $Writer.WriteEndObject()
        }
        Array {
            $Writer.WriteStartArray()
            foreach ($item in $Element.EnumerateArray()) {
                Write-ApplicationApiContract -Element $item -Writer $Writer
            }
            $Writer.WriteEndArray()
        }
        default { $Element.WriteTo($Writer) }
    }
}

function Get-ApplicationApiContractHash {
    param(
        [System.Text.Json.JsonElement] $Element,
        [string[]] $IgnoredProperties = @()
    )

    $buffer = [System.IO.MemoryStream]::new()
    $writer = [System.Text.Json.Utf8JsonWriter]::new($buffer)
    $hash = [System.Security.Cryptography.SHA256]::Create()
    try {
        Write-ApplicationApiContract -Element $Element -Writer $writer -IgnoredProperties $IgnoredProperties
        $writer.Flush()
        [System.Convert]::ToBase64String($hash.ComputeHash($buffer.ToArray()))
    }
    finally {
        $hash.Dispose()
        $writer.Dispose()
        $buffer.Dispose()
    }
}

function Add-ApplicationApiPageMembers {
    param(
        [System.Text.Json.JsonElement] $Elements,
        [string[]] $MemberNames,
        [ValidateSet('Controls', 'Actions')] [string] $ChildrenProperty,
        [ValidateSet('PageParts', 'PageFields', 'PageActions')] [string] $Collection,
        [string] $OwnerKey,
        [string] $OwnerId,
        [string] $PageReference,
        [hashtable] $Snapshot
    )

    foreach ($control in $Elements.EnumerateArray()) {
        $name = $control.GetProperty('Name').GetString()
        if ($name -cin $MemberNames) {
            $kind = $control.GetProperty('Kind')
            $kindValue = if ($kind.ValueKind -eq [System.Text.Json.JsonValueKind]::String) { $kind.GetString() } else { [string]$kind.GetInt32() }
            $memberKind = if ($ChildrenProperty -eq 'Controls' -and $kindValue -cin @('Part', '6')) { 'Part' }
                elseif ($ChildrenProperty -eq 'Controls' -and $kindValue -cin @('Field', '8')) { 'Field' }
                elseif ($ChildrenProperty -eq 'Actions' -and $kindValue -cin @('Group', '1')) { 'ActionGroup' }
                elseif ($ChildrenProperty -eq 'Actions' -and $kindValue -cin @('Action', '2')) { 'Action' }
                else { 'Unsupported' }
            $isPart = $memberKind -eq 'Part'
            $type = [System.Text.Json.JsonElement]::new()
            $subtype = [System.Text.Json.JsonElement]::new()
            $target = [System.Text.Json.JsonElement]::new()
            $targetId = 0
            if ($isPart -and $control.TryGetProperty('TypeDefinition', [ref]$type) -and
                $type.TryGetProperty('Subtype', [ref]$subtype) -and $subtype.TryGetProperty('Id', [ref]$target)) {
                $targetId = $target.GetInt32()
            }
            $Snapshot[$Collection].Add([PSCustomObject]@{
                Name = $name
                IsPart = $isPart
                MemberKind = $memberKind
                OwnerKey = $OwnerKey
                OwnerId = $OwnerId
                PageReference = $PageReference
                TargetPageId = $targetId
                ContractHash = Get-ApplicationApiContractHash -Element $control
            })
        }
        $children = [System.Text.Json.JsonElement]::new()
        if ($control.TryGetProperty($ChildrenProperty, [ref]$children)) {
            Add-ApplicationApiPageMembers -Elements $children -MemberNames $MemberNames -ChildrenProperty $ChildrenProperty `
                -Collection $Collection -OwnerKey $OwnerKey -OwnerId $OwnerId -PageReference $PageReference -Snapshot $Snapshot
        }
    }
}

function Add-ApplicationApiMethods {
    param(
        [System.Text.Json.JsonElement] $Symbol,
        [string[]] $MethodNames,
        [string] $OwnerKey,
        [string] $OwnerId,
        [string] $HostKind,
        [string] $HostReference,
        [hashtable] $Snapshot
    )

    $methods = [System.Text.Json.JsonElement]::new()
    if (-not $Symbol.TryGetProperty('Methods', [ref]$methods)) { return }
    foreach ($method in $methods.EnumerateArray()) {
        $name = $method.GetProperty('Name').GetString()
        if ($name -cnotin $MethodNames) { continue }
        $access = [System.Text.Json.JsonElement]::new()
        if ($method.TryGetProperty('IsInternal', [ref]$access) -and $access.GetBoolean()) { continue }
        $modifier = if ($method.TryGetProperty('AccessModifier', [ref]$access)) { $access.GetString() } else { '' }
        if ($modifier -ieq 'Internal') { continue }
        $attributes = [System.Text.Json.JsonElement]::new()
        $isEvent = $false
        if ($method.TryGetProperty('Attributes', [ref]$attributes)) {
            $isEvent = @($attributes.EnumerateArray() | Where-Object {
                $_.GetProperty('Name').GetString() -cin @('IntegrationEvent', 'BusinessEvent')
            }).Count -gt 0
        }
        $isLocal = $modifier -ieq 'Local' -or ($method.TryGetProperty('IsLocal', [ref]$access) -and $access.GetBoolean())
        if ($isLocal -and -not $isEvent) { continue }
        $Snapshot.Methods.Add([PSCustomObject]@{
            Name = $name
            MemberKind = 'Method'
            OwnerKey = $OwnerKey
            OwnerId = $OwnerId
            HostKind = $HostKind
            HostReference = $HostReference
            ContractHash = Get-ApplicationApiContractHash -Element $method
        })
    }
}

function Add-ApplicationApiSymbols {
    param(
        [System.Text.Json.JsonElement] $Element,
        [string] $Namespace,
        [object] $Package,
        [hashtable] $Snapshot,
        [hashtable] $Names,
        [hashtable] $SymbolKeys,
        [string[]] $PartNames,
        [string[]] $ActionNames,
        [string[]] $FieldNames,
        [string[]] $MethodNames
    )

    $objectCollections = @(
        'Codeunits', 'Pages', 'PageExtensions', 'Reports', 'ReportExtensions', 'XmlPorts', 'Queries',
        'EnumTypes', 'EnumExtensionTypes', 'Interfaces', 'PermissionSets', 'PermissionSetExtensions', 'ControlAddIns',
        'Profiles', 'ProfileExtensions', 'PageCustomizations'
    )
    $methodHosts = @{
        Tables = 'Tables'; TableExtensions = 'Tables'
        Pages = 'Pages'; PageExtensions = 'Pages'
        Reports = 'Reports'; ReportExtensions = 'Reports'
    }
    foreach ($property in $Element.EnumerateObject()) {
        if ($property.Name -ceq 'Namespaces') {
            foreach ($child in $property.Value.EnumerateArray()) {
                $name = $child.GetProperty('Name').GetString()
                $childNamespace = if ($Namespace) { "$Namespace.$name" } else { $name }
                Add-ApplicationApiSymbols -Element $child -Namespace $childNamespace -Package $Package -Snapshot $Snapshot `
                    -Names $Names -SymbolKeys $SymbolKeys -PartNames $PartNames -ActionNames $ActionNames -FieldNames $FieldNames -MethodNames $MethodNames
            }
        }
        elseif ($property.Name -cin $objectCollections -or $property.Name -cin @('Tables', 'TableExtensions')) {
            foreach ($symbol in $property.Value.EnumerateArray()) {
                $isSchema = $property.Name -cin @('Tables', 'TableExtensions')
                if ($isSchema) {
                    $Snapshot.SchemaObjects.Add("$($Package.Name): $($property.Name) $($symbol.GetProperty('Name').GetString())")
                    if ($MethodNames.Count -eq 0) { continue }
                }
                $id = [System.Text.Json.JsonElement]::new()
                $hasId = $symbol.TryGetProperty('Id', [ref]$id)
                $name = $symbol.GetProperty('Name').GetString()
                $namedIdentity = $property.Name -cin @('Interfaces', 'ControlAddIns', 'Profiles', 'ProfileExtensions', 'PageCustomizations')
                $key = if ($namedIdentity) { "$($property.Name):${Namespace}:$name" } elseif ($hasId) { "$($property.Name):$($id.GetInt32())" } else { '' }
                $nameSelector = "$($property.Name):Name:$name"
                $selected = $SymbolKeys.Count -eq 0 -or $SymbolKeys.ContainsKey($key) -or $SymbolKeys.ContainsKey($nameSelector)
                $inspectMembers = ($PartNames.Count -gt 0 -or $ActionNames.Count -gt 0 -or $FieldNames.Count -gt 0) -and $property.Name -cin @('Pages', 'PageExtensions')
                $inspectMethods = $MethodNames.Count -gt 0 -and $methodHosts.ContainsKey($property.Name)
                if (-not $selected -and -not $inspectMembers -and -not $inspectMethods) { continue }
                $properties = [System.Text.Json.JsonElement]::new()
                if ($symbol.TryGetProperty('Properties', [ref]$properties)) {
                    $access = @($properties.EnumerateArray() | Where-Object { $_.GetProperty('Name').GetString() -ceq 'Access' })
                    if ($access.Count -eq 1 -and $access[0].GetProperty('Value').GetString() -ieq 'Internal') { continue }
                }
                $memberCount = $Snapshot.PageParts.Count + $Snapshot.PageActions.Count + $Snapshot.PageFields.Count + $Snapshot.Methods.Count
                if ($inspectMembers) {
                    foreach ($collection in @('PageParts', 'PageFields', 'PageActions')) {
                        $childrenProperty = if ($collection -eq 'PageActions') { 'Actions' } else { 'Controls' }
                        $memberNames = switch ($collection) {
                            PageParts { $PartNames }
                            PageFields { $FieldNames }
                            PageActions { $ActionNames }
                        }
                        if (-not $memberNames) { continue }
                        $containers = @($symbol)
                        if ($property.Name -ceq 'PageExtensions') {
                            $changesName = if ($childrenProperty -eq 'Controls') { 'ControlChanges' } else { 'ActionChanges' }
                            $changes = [System.Text.Json.JsonElement]::new()
                            if (-not $symbol.TryGetProperty($changesName, [ref]$changes)) { continue }
                            $containers = @($changes.EnumerateArray())
                        }
                        foreach ($container in $containers) {
                            $children = [System.Text.Json.JsonElement]::new()
                            if ($container.TryGetProperty($childrenProperty, [ref]$children)) {
                                $pageReference = if ($property.Name -ceq 'Pages') { [string]$id.GetInt32() } else { $symbol.GetProperty('TargetObject').GetString() }
                                Add-ApplicationApiPageMembers -Elements $children -MemberNames $memberNames -ChildrenProperty $childrenProperty `
                                    -Collection $collection -OwnerKey $key -OwnerId $Package.Id -PageReference $pageReference -Snapshot $Snapshot
                            }
                        }
                    }
                }
                if ($inspectMethods) {
                    $hostReference = if ($property.Name -cin @('Tables', 'Pages', 'Reports')) { [string]$id.GetInt32() }
                        elseif ($property.Name -ceq 'ReportExtensions') { $symbol.GetProperty('Target').GetString() }
                        else { $symbol.GetProperty('TargetObject').GetString() }
                    Add-ApplicationApiMethods -Symbol $symbol -MethodNames $MethodNames -OwnerKey $key -OwnerId $Package.Id `
                        -HostKind $methodHosts[$property.Name] -HostReference $hostReference -Snapshot $Snapshot
                }
                # Member checks also need potential host/target objects, not just diagnostic owners.
                if (-not $selected -and $property.Name -cin @('TableExtensions', 'PageExtensions', 'ReportExtensions') -and
                    ($Snapshot.PageParts.Count + $Snapshot.PageActions.Count + $Snapshot.PageFields.Count + $Snapshot.Methods.Count) -eq $memberCount) { continue }
                if (-not $hasId -and -not $namedIdentity) {
                    $Snapshot.ReviewRequired.Add("$($Package.Name): unsupported ID-less $($property.Name) '$name'.")
                    continue
                }
                $nameKey = "$($property.Name):${Namespace}:$name"
                if ($Snapshot.Symbols.ContainsKey($key) -or $Snapshot.MethodObjects.ContainsKey($key) -or $Names.ContainsKey($nameKey)) {
                    throw "Ambiguous exposed symbol '$nameKey' ($key) in '$($Package.Path)'."
                }
                # These root properties are generated from the owning app, not the public object contract.
                $ignoredProperties = switch ($property.Name) {
                    Interfaces { @('Id') }
                    ControlAddIns { @('PublicKeyToken') }
                    default { @() }
                }
                # Tables supply host identity only; schema validation remains with AppSourceCop.
                $fingerprint = if ($isSchema) { '' } else { Get-ApplicationApiContractHash -Element $symbol -IgnoredProperties @($ignoredProperties) }
                $record = [PSCustomObject]@{
                    Key = $key
                    Kind = $property.Name
                    Id = if ($hasId) { $id.GetInt32() } else { $null }
                    Name = $name
                    Namespace = $Namespace
                    OwnerId = $Package.Id
                    OwnerName = $Package.Name
                    ContractHash = $fingerprint
                }
                if ($inspectMethods) { $Snapshot.MethodObjects[$key] = $record }
                if (-not $isSchema) { $Snapshot.Symbols[$key] = $record }
                $Names[$nameKey] = $key
            }
        }
        elseif ($property.Name -cnotin @('Name', 'AppId', 'Publisher', 'Version', 'RuntimeVersion', 'InternalsVisibleToModules')) {
            if ($property.Value.ValueKind -ne [System.Text.Json.JsonValueKind]::Array -or $property.Value.GetArrayLength() -gt 0) {
                $Snapshot.ReviewRequired.Add("$($Package.Name): unsupported symbol metadata '$($property.Name)' in namespace '$Namespace'.")
            }
        }
    }
}

<#
.SYNOPSIS
    Reads compiled package identity and dependency metadata without loading symbols.
#>
function Get-ApplicationApiPackageInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)] [string] $Path)

    Read-ApplicationApiPackage -Path $Path
}

<#
.SYNOPSIS
    Collects exposed non-table symbols and requested extension-member contracts.
.DESCRIPTION
    Conservative symbol-equivalence collector, not an AppSourceCop replacement.
    Use separate, country-specific baseline and current package sets.
    A dependency must have exactly one package satisfying its ID, name, publisher and
    minimum version. Multiple eligible versions or country variants are an error.
    Only dependencies propagated to Application consumers are exposed. Internal objects
    are excluded; friend-module contracts and platform symbols are outside this scope.
#>
function Get-ApplicationApiSnapshot {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)] [string] $ApplicationPackagePath,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [string[]] $DependencyPackagePaths,
        [string[]] $SymbolKeys = @(),
        [string[]] $PartNames = @(),
        [string[]] $ActionNames = @(),
        [string[]] $FieldNames = @(),
        [string[]] $MethodNames = @()
    )

    $index = @{}
    $paths = @($ApplicationPackagePath) + $DependencyPackagePaths
    foreach ($path in @($paths | ForEach-Object { (Get-Item -LiteralPath $_ -ErrorAction Stop).FullName } | Sort-Object -Unique)) {
        $package = Read-ApplicationApiPackage -Path $path
        if (-not $index.ContainsKey($package.Id)) {
            $index[$package.Id] = [System.Collections.Generic.List[object]]::new()
        }
        $index[$package.Id].Add($package)
    }
    $rootPath = (Get-Item -LiteralPath $ApplicationPackagePath).FullName
    $root = @($index.Values | ForEach-Object { $_ } | Where-Object { $_.Path -eq $rootPath })[0]
    if ($root.Name -cne 'Application' -or -not $root.PropagateDependencies) {
        throw "The root must be an Application package with PropagateDependencies enabled."
    }
    $snapshot = @{
        Application = $root
        Packages = @{}
        Symbols = @{}
        PageParts = [System.Collections.Generic.List[object]]::new()
        PageActions = [System.Collections.Generic.List[object]]::new()
        PageFields = [System.Collections.Generic.List[object]]::new()
        Methods = [System.Collections.Generic.List[object]]::new()
        MethodObjects = @{}
        SchemaObjects = [System.Collections.Generic.List[string]]::new()
        ReviewRequired = [System.Collections.Generic.List[string]]::new()
    }
    $pending = [System.Collections.Generic.Queue[object]]::new()
    $pending.Enqueue($root)
    $names = @{}
    $selectedKeys = @{}
    foreach ($key in $SymbolKeys) { $selectedKeys[$key] = $true }
    while ($pending.Count -gt 0) {
        $package = $pending.Dequeue()
        if ($snapshot.Packages.ContainsKey($package.Id)) {
            if ($snapshot.Packages[$package.Id].Path -ne $package.Path) {
                throw "Conflicting package selections for '$($package.Name)'."
            }
            continue
        }
        $snapshot.Packages[$package.Id] = $package
        $loaded = Read-ApplicationApiPackage -Path $package.Path -IncludeSymbols
        try {
            $symbols = $loaded.Document.RootElement
            foreach ($attribute in @('AppId', 'Name', 'Publisher', 'Version')) {
                $expected = if ($attribute -eq 'AppId') { $package.Id } else { [string]$package.$attribute }
                if ($symbols.GetProperty($attribute).GetString() -ine $expected) {
                    throw "Manifest/symbol identity mismatch for '$attribute' in '$($package.Path)'."
                }
            }
            Add-ApplicationApiSymbols -Element $symbols -Namespace '' -Package $package -Snapshot $snapshot `
                -Names $names -SymbolKeys $selectedKeys -PartNames $PartNames -ActionNames $ActionNames -FieldNames $FieldNames -MethodNames $MethodNames
        }
        finally {
            $loaded.Document.Dispose()
        }
        if (-not $package.PropagateDependencies) { continue }
        foreach ($dependency in $package.Dependencies) {
            $candidates = @(
                if ($index.ContainsKey($dependency.Id)) {
                    $index[$dependency.Id] | Where-Object {
                        $_.Name -ceq $dependency.Name -and $_.Publisher -ceq $dependency.Publisher -and $_.Version -ge $dependency.MinVersion
                    }
                }
            )
            if ($candidates.Count -ne 1) {
                throw "Expected exactly one package for '$($dependency.Name)' ($($dependency.Id)), minimum $($dependency.MinVersion); found $($candidates.Count)."
            }
            $pending.Enqueue($candidates[0])
        }
    }
    return $snapshot
}

<#
.SYNOPSIS
    Compares aggregate non-table symbol contracts without replacing AppSourceCop.
.DESCRIPTION
    Unchanged means symbol equivalence, not full compatibility. Source file paths and
    JSON property order and compiler-generated interface IDs/control-add-in tokens are
    ignored; all remaining object metadata is compared strictly.
    Changed contracts require review, even for potentially compatible additions.
    Table/field schema and move metadata must still be validated by AppSourceCop.
.EXAMPLE
    $baseline = Get-ApplicationApiSnapshot -ApplicationPackagePath $oldApplication -DependencyPackagePaths $oldPackages
    $current = Get-ApplicationApiSnapshot -ApplicationPackagePath $newApplication -DependencyPackagePaths $newPackages
    Compare-ApplicationApiSnapshot -Baseline $baseline -Current $current
#>
function Compare-ApplicationApiSnapshot {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [hashtable] $Baseline,
        [Parameter(Mandatory)] [hashtable] $Current
    )

    if ($Baseline.Application.Id -ne $Current.Application.Id) {
        throw 'Cannot compare different Application identities.'
    }
    $breaking = [System.Collections.Generic.List[object]]::new()
    $review = [System.Collections.Generic.List[object]]::new()
    $moves = [System.Collections.Generic.List[object]]::new()
    foreach ($issue in @($Baseline.ReviewRequired) + @($Current.ReviewRequired)) {
        $review.Add([PSCustomObject]@{ Symbol = $null; Current = $null; Reason = $issue })
    }
    if ($Baseline.Application.Publisher -cne $Current.Application.Publisher) {
        $breaking.Add([PSCustomObject]@{ Symbol = $null; Current = $null; Reason = 'Application publisher changed.' })
    }
    foreach ($key in @($Baseline.Symbols.Keys | Sort-Object)) {
        $old = $Baseline.Symbols[$key]
        if (-not $Current.Symbols.ContainsKey($key)) {
            $breaking.Add([PSCustomObject]@{ Symbol = $old; Current = $null; Reason = 'No longer exposed by Application.' })
            continue
        }
        $new = $Current.Symbols[$key]
        if ($old.Name -cne $new.Name -or $old.Namespace -cne $new.Namespace) {
            $breaking.Add([PSCustomObject]@{ Symbol = $old; Current = $new; Reason = 'Name or namespace changed.' })
        }
        elseif ($old.ContractHash -cne $new.ContractHash) {
            $review.Add([PSCustomObject]@{ Symbol = $old; Current = $new; Reason = 'Symbol contract changed; semantic compatibility requires review.' })
        }
        elseif ($old.OwnerId -ne $new.OwnerId) {
            $moves.Add([PSCustomObject]@{ Symbol = $old; Current = $new })
        }
    }
    $verdict = if ($breaking.Count) { 'Breaking' } elseif ($review.Count) { 'ReviewRequired' } else { 'Unchanged' }
    [PSCustomObject]@{
        Verdict = $verdict
        BreakingChanges = $breaking.ToArray()
        ReviewRequired = $review.ToArray()
        UnchangedMoves = $moves.ToArray()
        SchemaValidationRequired = $true
        Scope = 'Non-table symbol equivalence only; not an AppSourceCop replacement.'
    }
}

Export-ModuleMember -Function Get-ApplicationApiPackageInfo, Get-ApplicationApiSnapshot, Compare-ApplicationApiSnapshot
