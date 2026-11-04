#requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Read-ApplicationApiPackage {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [switch] $IncludeSymbols,
        [byte[]] $PackageBytes
    )

    $bytes = $PackageBytes
    if ($null -eq $bytes) { $bytes = [System.IO.File]::ReadAllBytes($Path) }
    if ($bytes.Length -lt 44 -or [System.Text.Encoding]::ASCII.GetString($bytes, 0, 4) -cne 'NAVX' -or
        [System.BitConverter]::ToUInt32($bytes, 40) -ne 0x04034b50) {
        throw "Unsupported package envelope in '$Path'; expected a 40-byte NAVX header followed by ZIP data."
    }

    $stream = [System.IO.MemoryStream]::new($bytes, 40, $bytes.Length - 40)
    $zip = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Read)
    try {
        $entries = @($zip.Entries | Where-Object { $_.FullName -ceq 'NavxManifest.xml' })
        $readyToRunEntries = @($zip.Entries | Where-Object { $_.FullName -ceq 'readytorunappmanifest.json' })
        if ($readyToRunEntries.Count -gt 0) {
            if ($null -ne $PackageBytes) { throw "Nested ready-to-run packages are not supported in '$Path'." }
            if ($readyToRunEntries.Count -ne 1 -or $entries.Count -gt 0) {
                throw "Expected a single, unambiguous ready-to-run manifest in '$Path'."
            }
            $reader = [System.IO.StreamReader]::new($readyToRunEntries[0].Open())
            try { $readyToRun = $reader.ReadToEnd() | ConvertFrom-Json -AsHashtable } finally { $reader.Dispose() }
            if ($readyToRun -isnot [System.Collections.IDictionary]) {
                throw "Invalid ready-to-run manifest in '$Path'."
            }
            foreach ($key in @('EmbeddedAppId', 'EmbeddedAppName', 'EmbeddedAppPublisher', 'EmbeddedAppVersion', 'EmbeddedAppFileName')) {
                if ($readyToRun[$key] -isnot [string] -or [string]::IsNullOrWhiteSpace($readyToRun[$key])) {
                    throw "Invalid ready-to-run manifest in '$Path': missing or invalid '$key'."
                }
            }
            $embeddedEntries = @($zip.Entries | Where-Object { $_.FullName -ceq $readyToRun.EmbeddedAppFileName })
            if ($embeddedEntries.Count -ne 1) {
                throw "Expected exactly one embedded app '$($readyToRun.EmbeddedAppFileName)' in '$Path'."
            }
            $embeddedStream = $embeddedEntries[0].Open()
            $buffer = [System.IO.MemoryStream]::new()
            try {
                $embeddedStream.CopyTo($buffer)
                $embeddedBytes = $buffer.ToArray()
            }
            finally {
                $buffer.Dispose()
                $embeddedStream.Dispose()
            }
            $embedded = Read-ApplicationApiPackage -Path $Path -PackageBytes $embeddedBytes -IncludeSymbols:$IncludeSymbols
            if ($embedded.Id -ine $readyToRun.EmbeddedAppId -or $embedded.Name -cne $readyToRun.EmbeddedAppName -or
                $embedded.Publisher -cne $readyToRun.EmbeddedAppPublisher -or [string]$embedded.Version -cne $readyToRun.EmbeddedAppVersion) {
                if ($null -ne $embedded.Document) { $embedded.Document.Dispose() }
                throw "Ready-to-run/embedded app identity mismatch in '$Path'."
            }
            return $embedded
        }
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

function Add-ApplicationApiReferenceTypes {
    param(
        [System.Text.Json.JsonElement] $Element,
        [string] $Namespace,
        [string] $OwnerId,
        [hashtable] $ReferenceTypes
    )

    $kinds = @{
        Tables = 'Record'; Codeunits = 'Codeunit'; Pages = 'Page'; Reports = 'Report'
        XmlPorts = 'XmlPort'; Queries = 'Query'; EnumTypes = 'Enum'; Interfaces = 'Interface'
    }
    foreach ($property in $Element.EnumerateObject()) {
        if ($property.Name -ceq 'Namespaces') {
            foreach ($child in $property.Value.EnumerateArray()) {
                $name = $child.GetProperty('Name').GetString()
                $childNamespace = if ($Namespace) { "$Namespace.$name" } else { $name }
                Add-ApplicationApiReferenceTypes -Element $child -Namespace $childNamespace -OwnerId $OwnerId -ReferenceTypes $ReferenceTypes
            }
        }
        elseif ($kinds.ContainsKey($property.Name)) {
            foreach ($symbol in $property.Value.EnumerateArray()) {
                $id = [System.Text.Json.JsonElement]::new()
                if (-not $symbol.TryGetProperty('Id', [ref]$id)) { continue }
                $properties = [System.Text.Json.JsonElement]::new()
                if ($symbol.TryGetProperty('Properties', [ref]$properties)) {
                    $hidden = @($properties.EnumerateArray() | Where-Object {
                        ($_.GetProperty('Name').GetString() -ceq 'Access' -and $_.GetProperty('Value').GetString() -ieq 'Internal') -or
                        ($_.GetProperty('Name').GetString() -ceq 'ObsoleteState' -and $_.GetProperty('Value').GetString() -iin @('Moved', 'Removed'))
                    })
                    if ($hidden.Count -gt 0) { continue }
                }
                $key = "${OwnerId}:$($kinds[$property.Name]):$($id.GetInt32())"
                $aggregateKey = "$($kinds[$property.Name]):$($id.GetInt32())"
                if ($ReferenceTypes.ContainsKey($key)) {
                    $ReferenceTypes[$key] = $null
                    $ReferenceTypes[$aggregateKey] = ''
                    continue
                }
                if ($ReferenceTypes.ContainsKey($aggregateKey)) { $ReferenceTypes[$aggregateKey] = '' }
                else { $ReferenceTypes[$aggregateKey] = $OwnerId }
                $ReferenceTypes[$key] = @{
                    Name = $symbol.GetProperty('Name').GetString()
                    Namespace = $Namespace
                    Identity = "$($property.Name):$($id.GetInt32()):${Namespace}:$($symbol.GetProperty('Name').GetString())"
                }
            }
        }
    }
}

function Get-ApplicationApiReferenceIdentity {
    param(
        [System.Text.Json.JsonElement] $Subtype,
        [string] $TypeName,
        [string] $OwnerId,
        [hashtable] $ReferenceTypes,
        [switch] $AllowImplicitAggregateModule
    )

    $name = [System.Text.Json.JsonElement]::new()
    $id = [System.Text.Json.JsonElement]::new()
    if (-not $Subtype.TryGetProperty('Id', [ref]$id)) { return '' }
    $module = [System.Text.Json.JsonElement]::new()
    $moduleId = if ($Subtype.TryGetProperty('ModuleId', [ref]$module)) { $module.GetString() }
        elseif ($AllowImplicitAggregateModule) { $ReferenceTypes["${TypeName}:$($id.GetInt32())"] }
        else { $OwnerId }
    if ($ReferenceTypes["${TypeName}:$($id.GetInt32())"] -ne $moduleId) { return '' }
    $target = $ReferenceTypes["${moduleId}:${TypeName}:$($id.GetInt32())"]
    if (-not $target) { return '' }
    if ($Subtype.TryGetProperty('Name', [ref]$name) -and $name.GetString() -and $name.GetString() -cne $target.Name) { return '' }
    $namespace = [System.Text.Json.JsonElement]::new()
    if ($Subtype.TryGetProperty('Namespace', [ref]$namespace) -and $namespace.GetString() -cne $target.Namespace) { return '' }
    return $target.Identity
}

function Write-ApplicationApiContract {
    param(
        [System.Text.Json.JsonElement] $Element,
        [System.Text.Json.Utf8JsonWriter] $Writer,
        [string[]] $IgnoredProperties = @(),
        [string] $OwnerId,
        [hashtable] $ReferenceTypes,
        [string] $ReferenceIdentity
    )

    switch ($Element.ValueKind) {
        Object {
            $Writer.WriteStartObject()
            $properties = @($Element.EnumerateObject())
            if ($ReferenceIdentity -and -not @($properties | Where-Object Name -CEQ 'ModuleId').Count) {
                $properties += @{ Name = 'ModuleId' }
            }
            foreach ($property in @($properties | Sort-Object Name -CaseSensitive)) {
                if ($property.Name -ceq 'ReferenceSourceFileName' -or $property.Name -cin $IgnoredProperties) { continue }
                if ($property.Name -ceq 'Variables') {
                    # Private globals are implementation details; retain unfamiliar visibility metadata.
                    $variables = @($property.Value.EnumerateArray() | Where-Object {
                        $protected = [System.Text.Json.JsonElement]::new()
                        ($_.TryGetProperty('Protected', [ref]$protected) -and $protected.GetBoolean()) -or
                        @($_.EnumerateObject() | Where-Object {
                            $_.Name -cnotin @('Name', 'TypeDefinition', 'Protected', 'Attributes', 'ArrayDimensions', 'OptionMembers', 'Type')
                        }).Count -gt 0
                    })
                    if ($variables.Count -eq 0) { continue }
                    $Writer.WritePropertyName($property.Name)
                    $Writer.WriteStartArray()
                    foreach ($variable in $variables) {
                        Write-ApplicationApiContract -Element $variable -Writer $Writer -OwnerId $OwnerId -ReferenceTypes $ReferenceTypes
                    }
                    $Writer.WriteEndArray()
                    continue
                }
                $Writer.WritePropertyName($property.Name)
                if ($property.Name -ceq 'ModuleId' -and $ReferenceIdentity) {
                    $Writer.WriteStringValue($ReferenceIdentity)
                    continue
                }
                $typeName = [System.Text.Json.JsonElement]::new()
                $reference = if ($property.Name -ceq 'RelatedPagePartId') {
                    # The compiler omits ModuleId on page-part references even for dependency pages.
                    Get-ApplicationApiReferenceIdentity -Subtype $property.Value -TypeName Page -OwnerId $OwnerId -ReferenceTypes $ReferenceTypes -AllowImplicitAggregateModule
                } elseif ($property.Name -ceq 'Subtype' -and $Element.TryGetProperty('Name', [ref]$typeName)) {
                    Get-ApplicationApiReferenceIdentity -Subtype $property.Value -TypeName $typeName.GetString() -OwnerId $OwnerId -ReferenceTypes $ReferenceTypes
                } else { '' }
                Write-ApplicationApiContract -Element $property.Value -Writer $Writer -OwnerId $OwnerId -ReferenceTypes $ReferenceTypes -ReferenceIdentity $reference
            }
            $Writer.WriteEndObject()
        }
        Array {
            $Writer.WriteStartArray()
            foreach ($item in $Element.EnumerateArray()) {
                Write-ApplicationApiContract -Element $item -Writer $Writer -OwnerId $OwnerId -ReferenceTypes $ReferenceTypes
            }
            $Writer.WriteEndArray()
        }
        default { $Element.WriteTo($Writer) }
    }
}

function Get-ApplicationApiContractJson {
    param(
        [System.Text.Json.JsonElement] $Element,
        [string[]] $IgnoredProperties = @(),
        [string] $OwnerId,
        [hashtable] $ReferenceTypes
    )

    $buffer = [System.IO.MemoryStream]::new()
    $writer = [System.Text.Json.Utf8JsonWriter]::new($buffer)
    try {
        Write-ApplicationApiContract -Element $Element -Writer $writer -IgnoredProperties $IgnoredProperties -OwnerId $OwnerId -ReferenceTypes $ReferenceTypes
        $writer.Flush()
        [System.Text.Encoding]::UTF8.GetString($buffer.ToArray())
    }
    finally {
        $writer.Dispose()
        $buffer.Dispose()
    }
}

function Add-ApplicationApiContract {
    param(
        [System.Text.Json.JsonElement] $Element,
        [object] $Target,
        [string] $OwnerId,
        [hashtable] $Snapshot,
        [string[]] $IgnoredProperties = @(),
        [string] $Key
    )

    # Resolve references only after all exposed packages have been indexed.
    $Snapshot.PendingContracts.Add(@{
        Element = $Element.Clone()
        Target = $Target
        OwnerId = $OwnerId
        IgnoredProperties = $IgnoredProperties
        Key = $Key
    })
}

function Add-ApplicationApiPageMembers {
    param(
        [System.Text.Json.JsonElement] $Elements,
        [string[]] $MemberNames,
        [ValidateSet('Controls', 'Actions')] [string] $ChildrenProperty,
        [ValidateSet('PageParts', 'PageFields', 'PageActions', 'PageCueGroups', 'PageControls')] [string] $Collection,
        [string] $OwnerKey,
        [string] $OwnerId,
        [string] $PageReference,
        [hashtable] $Snapshot,
        [switch] $IncludeContracts
    )

    foreach ($control in $Elements.EnumerateArray()) {
        $name = $control.GetProperty('Name').GetString()
        if (($ChildrenProperty -eq 'Actions') -eq ($Collection -eq 'PageActions') -and $name -cin $MemberNames) {
            $kind = $control.GetProperty('Kind')
            $kindValue = if ($kind.ValueKind -eq [System.Text.Json.JsonValueKind]::String) { $kind.GetString() } else { [string]$kind.GetInt32() }
            $kinds = if ($ChildrenProperty -eq 'Controls') {
                @('Area', 'Group', 'CueGroup', 'Repeater', 'Fixed', 'Grid', 'Part', 'SystemPart', 'Field', 'Label', 'UserControl', 'ChartPart')
            }
            else { @('Area', 'Group', 'Action', 'Separator', 'ActionRef', 'CustomAction', 'SystemAction', 'FileUploadAction') }
            $memberKind = 'Unsupported'
            for ($index = 0; $index -lt $kinds.Count; $index++) {
                if ($kindValue -ceq $kinds[$index] -or $kindValue -ceq [string]$index) {
                    $memberKind = $kinds[$index]
                    break
                }
            }
            if ($ChildrenProperty -eq 'Controls' -and $kindValue -ceq 'Chart') { $memberKind = 'ChartPart' }
            if ($ChildrenProperty -eq 'Actions' -and $memberKind -cin @('Area', 'Group')) { $memberKind = "Action$memberKind" }
            $isPart = $memberKind -eq 'Part'
            $type = [System.Text.Json.JsonElement]::new()
            $subtype = [System.Text.Json.JsonElement]::new()
            $target = [System.Text.Json.JsonElement]::new()
            $targetId = 0
            if ($isPart -and $control.TryGetProperty('RelatedPagePartId', [ref]$subtype) -and $subtype.TryGetProperty('Id', [ref]$target)) {
                $targetId = $target.GetInt32()
            }
            if ($isPart -and $control.TryGetProperty('TypeDefinition', [ref]$type) -and
                $type.TryGetProperty('Subtype', [ref]$subtype) -and $subtype.TryGetProperty('Id', [ref]$target)) {
                if ($targetId -ne 0 -and $targetId -ne $target.GetInt32()) { throw "Conflicting target pages for part '$name'." }
                $targetId = $target.GetInt32()
            }
            $member = [PSCustomObject]@{
                Name = $name
                IsPart = $isPart
                MemberKind = $memberKind
                OwnerKey = $OwnerKey
                OwnerId = $OwnerId
                PageReference = $PageReference
                TargetPageId = $targetId
                ContractHash = ''
            }
            if ($IncludeContracts) { $member | Add-Member -NotePropertyName Contract -NotePropertyValue '' }
            Add-ApplicationApiContract -Element $control -Target $member -OwnerId $OwnerId -Snapshot $Snapshot
            $Snapshot[$Collection].Add($member)
        }
        foreach ($nestedProperty in @('Controls', 'Actions')) {
            if ($nestedProperty -eq 'Actions' -and $Collection -ne 'PageActions') { continue }
            $children = [System.Text.Json.JsonElement]::new()
            if ($control.TryGetProperty($nestedProperty, [ref]$children)) {
                Add-ApplicationApiPageMembers -Elements $children -MemberNames $MemberNames -ChildrenProperty $nestedProperty `
                    -Collection $Collection -OwnerKey $OwnerKey -OwnerId $OwnerId -PageReference $PageReference -Snapshot $Snapshot -IncludeContracts:$IncludeContracts
            }
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
        $member = [PSCustomObject]@{
            Name = $name
            MemberKind = 'Method'
            OwnerKey = $OwnerKey
            OwnerId = $OwnerId
            HostKind = $HostKind
            HostReference = $HostReference
            ContractHash = ''
        }
        Add-ApplicationApiContract -Element $method -Target $member -OwnerId $OwnerId -Snapshot $Snapshot
        $Snapshot.Methods.Add($member)
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
        [string[]] $MethodNames,
        [string[]] $CueGroupNames,
        [string[]] $ControlNames,
        [switch] $IncludeContracts
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
                    -Names $Names -SymbolKeys $SymbolKeys -PartNames $PartNames -ActionNames $ActionNames -FieldNames $FieldNames -MethodNames $MethodNames -CueGroupNames $CueGroupNames -ControlNames $ControlNames -IncludeContracts:$IncludeContracts
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
                $inspectMembers = ($PartNames.Count -gt 0 -or $ActionNames.Count -gt 0 -or $FieldNames.Count -gt 0 -or $CueGroupNames.Count -gt 0 -or $ControlNames.Count -gt 0) -and $property.Name -cin @('Pages', 'PageExtensions')
                $inspectMethods = $MethodNames.Count -gt 0 -and $methodHosts.ContainsKey($property.Name)
                $inspectExtension = $IncludeContracts -and $property.Name -ceq 'PageExtensions'
                if (-not $selected -and -not $inspectMembers -and -not $inspectMethods -and -not $inspectExtension) { continue }
                $properties = [System.Text.Json.JsonElement]::new()
                if ($symbol.TryGetProperty('Properties', [ref]$properties)) {
                    $access = @($properties.EnumerateArray() | Where-Object { $_.GetProperty('Name').GetString() -ceq 'Access' })
                    if ($access.Count -eq 1 -and $access[0].GetProperty('Value').GetString() -ieq 'Internal') { continue }
                    $obsoleteState = @($properties.EnumerateArray() | Where-Object { $_.GetProperty('Name').GetString() -ceq 'ObsoleteState' })
                    if ($obsoleteState.Count -eq 1 -and $obsoleteState[0].GetProperty('Value').GetString() -iin @('Moved', 'Removed')) { continue }
                }
                if ($inspectExtension) {
                    if ($Snapshot.PageExtensionContracts.ContainsKey($key)) { throw "Ambiguous exposed page extension '$key'." }
                    $extension = [PSCustomObject]@{
                        Name = $name
                        OwnerId = $Package.Id
                        PageReference = $symbol.GetProperty('TargetObject').GetString()
                        ContractHash = ''
                        Contract = ''
                    }
                    $Snapshot.PageExtensionContracts[$key] = $extension
                    Add-ApplicationApiContract -Element $symbol -Target $extension -OwnerId $Package.Id -Snapshot $Snapshot
                    if (-not $selected -and -not $inspectMembers -and -not $inspectMethods) { continue }
                }
                $memberCount = $Snapshot.PageParts.Count + $Snapshot.PageActions.Count + $Snapshot.PageFields.Count + $Snapshot.PageCueGroups.Count + $Snapshot.PageControls.Count + $Snapshot.Methods.Count
                if ($inspectMembers) {
                    foreach ($collection in @('PageParts', 'PageFields', 'PageActions', 'PageCueGroups', 'PageControls')) {
                        $childrenProperties = if ($collection -eq 'PageActions') { @('Actions', 'Controls') } else { @('Controls') }
                        $memberNames = switch ($collection) {
                            PageParts { $PartNames }
                            PageFields { $FieldNames }
                            PageActions { $ActionNames }
                            PageCueGroups { $CueGroupNames }
                            PageControls { $ControlNames }
                        }
                        if (-not $memberNames) { continue }
                        $containers = @($symbol)
                        if ($property.Name -ceq 'PageExtensions') {
                            $changeNames = if ($collection -eq 'PageActions') { @('ActionChanges', 'ControlChanges') } else { @('ControlChanges') }
                            $containers = @(
                                foreach ($changesName in $changeNames) {
                                    $changes = [System.Text.Json.JsonElement]::new()
                                    if ($symbol.TryGetProperty($changesName, [ref]$changes)) { $changes.EnumerateArray() }
                                }
                            )
                        }
                        foreach ($container in $containers) {
                            foreach ($childrenProperty in $childrenProperties) {
                                $children = [System.Text.Json.JsonElement]::new()
                                if ($container.TryGetProperty($childrenProperty, [ref]$children)) {
                                    $pageReference = if ($property.Name -ceq 'Pages') { [string]$id.GetInt32() } else { $symbol.GetProperty('TargetObject').GetString() }
                                    Add-ApplicationApiPageMembers -Elements $children -MemberNames $memberNames -ChildrenProperty $childrenProperty `
                                        -Collection $collection -OwnerKey $key -OwnerId $Package.Id -PageReference $pageReference -Snapshot $Snapshot -IncludeContracts:$IncludeContracts
                                }
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
                    ($Snapshot.PageParts.Count + $Snapshot.PageActions.Count + $Snapshot.PageFields.Count + $Snapshot.PageCueGroups.Count + $Snapshot.PageControls.Count + $Snapshot.Methods.Count) -eq $memberCount) { continue }
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
                $customizationTarget = [System.Text.Json.JsonElement]::new()
                $hasCustomizationTarget = $property.Name -ceq 'PageCustomizations' -and $symbol.TryGetProperty('TargetObject', [ref]$customizationTarget)
                $record = [PSCustomObject]@{
                    Key = $key
                    Kind = $property.Name
                    Id = if ($hasId) { $id.GetInt32() } else { $null }
                    Name = $name
                    Namespace = $Namespace
                    OwnerId = $Package.Id
                    OwnerName = $Package.Name
                    ContractHash = ''
                    TargetObject = if ($hasCustomizationTarget) { $customizationTarget.GetString() } else { '' }
                }
                # Tables supply host identity only; schema validation remains with AppSourceCop.
                if (-not $isSchema) {
                    $contractKey = if ($IncludeContracts -and $selected) { $key } else { '' }
                    Add-ApplicationApiContract -Element $symbol -Target $record -OwnerId $Package.Id -Snapshot $Snapshot `
                        -IgnoredProperties @($ignoredProperties) -Key $contractKey
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
        [string[]] $MethodNames = @(),
        [string[]] $CueGroupNames = @(),
        [string[]] $ControlNames = @(),
        [switch] $IncludeContracts
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
        Contracts = @{}
        PageExtensionContracts = @{}
        ReferenceTypes = @{}
        PendingContracts = [System.Collections.Generic.List[object]]::new()
        PageParts = [System.Collections.Generic.List[object]]::new()
        PageActions = [System.Collections.Generic.List[object]]::new()
        PageFields = [System.Collections.Generic.List[object]]::new()
        PageCueGroups = [System.Collections.Generic.List[object]]::new()
        PageControls = [System.Collections.Generic.List[object]]::new()
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
            Add-ApplicationApiReferenceTypes -Element $symbols -Namespace '' -OwnerId $package.Id -ReferenceTypes $snapshot.ReferenceTypes
            Add-ApplicationApiSymbols -Element $symbols -Namespace '' -Package $package -Snapshot $snapshot `
                -Names $names -SymbolKeys $selectedKeys -PartNames $PartNames -ActionNames $ActionNames -FieldNames $FieldNames -MethodNames $MethodNames -CueGroupNames $CueGroupNames -ControlNames $ControlNames -IncludeContracts:$IncludeContracts
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
    $hash = [System.Security.Cryptography.SHA256]::Create()
    try {
        foreach ($pendingContract in $snapshot.PendingContracts) {
            $contract = Get-ApplicationApiContractJson -Element $pendingContract.Element -IgnoredProperties $pendingContract.IgnoredProperties `
                -OwnerId $pendingContract.OwnerId -ReferenceTypes $snapshot.ReferenceTypes
            $pendingContract.Target.ContractHash = [System.Convert]::ToBase64String($hash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($contract)))
            if ($pendingContract.Target.PSObject.Properties['Contract']) { $pendingContract.Target.Contract = $contract }
            if ($pendingContract.Key) { $snapshot.Contracts[$pendingContract.Key] = $contract }
        }
    }
    finally {
        $hash.Dispose()
    }
    $snapshot.Remove('PendingContracts')
    $snapshot.Remove('ReferenceTypes')
    return $snapshot
}

<#
.SYNOPSIS
    Compares aggregate non-table symbol contracts without replacing AppSourceCop.
.DESCRIPTION
    Unchanged means symbol equivalence, not full compatibility. Source file paths and
    JSON property order, private variables, and compiler-generated interface IDs/control-add-in
    tokens are ignored. Type references resolving to the same exposed aggregate type are
    compared independently of their owning module; other metadata is compared strictly.
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
