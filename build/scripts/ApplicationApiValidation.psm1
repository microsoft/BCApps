#requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
Import-Module "$PSScriptRoot\ApplicationApiCompatibility.psm1"

$script:RemovalRules = @{
    AS0029 = @{ Page = 'Pages'; PageExtension = 'PageExtensions' }
    AS0088 = @{
        Codeunit = 'Codeunits'; Report = 'Reports'; ReportExtension = 'ReportExtensions'
        Query = 'Queries'; XmlPort = 'XmlPorts'
        Enum = 'EnumTypes'; EnumExtension = 'EnumExtensionTypes'
        PermissionSet = 'PermissionSets'; PermissionSetExtension = 'PermissionSetExtensions'
    }
    AS0089 = @{ Profile = 'Profiles'; ProfileExtension = 'ProfileExtensions'; ControlAddIn = 'ControlAddIns'; PageCustomization = 'PageCustomizations' }
    AS0065 = @{ Interface = 'Interfaces' }
}
$script:ObjectRemovalPattern = "^The '(?<kind>\w+)' with (?:ID '(?<id>[0-9]+)' and name|name) '(?<name>.+)' was found in the previous version, but is missing in the current extension\. This will break dependent extensions\.$"
$script:MemberRules = @{
    AS0018 = "^Procedure '(?<method>.+)' has been removed in '(?<kind>\w+) (?<name>.+)'\. A procedure that belongs to the public API must not be removed as it will break dependent extensions calling this procedure\.$"
    AS0031 = "^The (?<memberKind>action(?: group| area| separator|ref)?|separator|(?:custom|system) ?action|file ?upload ?action) with name '(?<member>.+)' defined in (?<kind>Page|PageExtension|PageCustomization) '(?<name>.+)' was found in the previous version, but is missing in the current extension\.(?: This will break dependent extensions\.)?$"
    AS0032 = "^The (?<memberKind>field|part|cuegroup|area|group|repeater|fixed|grid|system ?part|label|user ?control|chart(?: ?part)?) with name '(?<member>.+)' defined in (?<kind>Page|PageExtension|PageCustomization) '(?<name>.+)' was found in the previous version, but is missing in the current extension\.(?: This will break dependent extensions\.)?$"
    AS0106 = "^The variable '.+' of type '.+' defined in (?<kind>Page|PageExtension|Report|ReportExtension) '(?<name>.+)' was found in the previous version, but is missing in the current extension\.(?: This will break dependent extensions\.)?$"
}
$script:DeferredRules = @($script:RemovalRules.Keys) + @($script:MemberRules.Keys)
$script:ControlMemberKinds = @{
    area = 'Area'; group = 'Group'; repeater = 'Repeater'; fixed = 'Fixed'; grid = 'Grid'
    systempart = 'SystemPart'; label = 'Label'; usercontrol = 'UserControl'; chart = 'ChartPart'; chartpart = 'ChartPart'
}
$script:ActionMemberKinds = @{
    action = 'Action'; actiongroup = 'ActionGroup'; actionarea = 'ActionArea'; actionref = 'ActionRef'
    separator = 'Separator'; actionseparator = 'Separator'; customaction = 'CustomAction'
    systemaction = 'SystemAction'; fileuploadaction = 'FileUploadAction'
}

function Select-ApplicationApiPackages {
    param([string[]] $PreferredPaths = @(), [string[]] $FallbackPaths = @())

    $selected = @{}
    foreach ($paths in @(@{ Paths = $PreferredPaths }, @{ Paths = $FallbackPaths })) {
        $group = @{}
        foreach ($path in @($paths.Paths | Sort-Object -Unique)) {
            $file = Get-Item -LiteralPath $path
            if ($file.Name -eq 'System.app' -or $file.Name -like 'Microsoft_System_*.app') { continue }
            $package = Get-ApplicationApiPackageInfo -Path $file.FullName
            if ($selected.ContainsKey($package.Id)) { continue }
            if ($group.ContainsKey($package.Id)) {
                throw "Ambiguous packages for '$($package.Name)': '$($group[$package.Id])' and '$($file.FullName)'."
            }
            $group[$package.Id] = $file.FullName
        }
        foreach ($id in $group.Keys) { $selected[$id] = $group[$id] }
    }
    $selected.Values | Sort-Object
}

function Get-ApplicationApiValidationPath {
    param([hashtable] $CompilationParameters)

    if (-not $CompilationParameters['OutFolder']) { throw 'OutFolder is required for aggregate API validation.' }
    Join-Path (Split-Path $CompilationParameters['OutFolder'] -Parent) 'ApplicationApiValidation'
}

<#
.SYNOPSIS
    Records the baseline and enables mandatory post-workspace removal reconciliation.
#>
function Initialize-ApplicationApiValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [hashtable] $CompilationParameters,
        [Parameter(Mandatory)] [string] $CountryCode,
        [Parameter(Mandatory)] [string] $BuildMode
    )

    $root = Get-ApplicationApiValidationPath -CompilationParameters $CompilationParameters
    if (Test-Path -LiteralPath $root) { throw "Aggregate validation directory already exists: '$root'." }
    $workspacePath = (Get-Item -LiteralPath $CompilationParameters['WorkspaceFile']).FullName
    $projectFolder = Split-Path $workspacePath -Parent
    if (-not (Test-Path -LiteralPath (Join-Path $projectFolder '.AL-Go\PostCompileApp.ps1'))) {
        throw 'Aggregate API validation requires the PostCompileApp hook.'
    }
    $projects = @(
        foreach ($folder in (Get-Content -LiteralPath $workspacePath -Raw | ConvertFrom-Json).folders) {
            $folderPath = if ([System.IO.Path]::IsPathRooted($folder.path)) { $folder.path } else { Join-Path $projectFolder $folder.path }
            $path = (Get-Item -LiteralPath $folderPath).FullName
            $app = Get-Content -LiteralPath (Join-Path $path 'app.json') -Raw | ConvertFrom-Json
            $configPath = Join-Path $path 'AppSourceCop.json'
            $config = if (Test-Path -LiteralPath $configPath) { Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json -AsHashtable } else { @{} }
            [PSCustomObject]@{
                Path = $path
                Id = ([guid]$app.id).ToString()
                Name = $app.name
                BaselineVersion = [string]$config['version']
                BaselineName = [string]$config['name']
                BaselinePublisher = [string]$config['publisher']
            }
        }
    )
    $null = New-Item -Path $root -ItemType Directory
    $state = @{
        Status = 'Pending'
        CountryCode = $CountryCode
        BuildMode = $BuildMode
        Projects = $projects
        OriginalErrorLogDirectory = $CompilationParameters['ErrorLogDirectory']
        AcceptedMoves = @()
    }
    if ($BuildMode -eq 'Clean') {
        $cachePaths = @(Get-ChildItem -LiteralPath $CompilationParameters['PackageCachePath'] -Filter '*.app' -File)
        $baselinePaths = @(Select-ApplicationApiPackages -PreferredPaths @($cachePaths | Where-Object Name -Like '*_clean.app' | Select-Object -ExpandProperty FullName) `
            -FallbackPaths @(Get-ChildItem -LiteralPath $CompilationParameters['OutFolder'] -Filter '*.app' -File | Select-Object -ExpandProperty FullName))
        $baselinePaths = @(Select-ApplicationApiPackages -PreferredPaths $baselinePaths -FallbackPaths @($cachePaths.FullName))
        $baselineFolder = Join-Path $root 'Baseline'
        $null = New-Item -Path $baselineFolder -ItemType Directory
        foreach ($path in $baselinePaths) { Copy-Item -LiteralPath $path -Destination $baselineFolder }
    }
    $state | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $root 'state.json') -Encoding UTF8
    $rulesetPath = (Get-Item -LiteralPath $CompilationParameters['Ruleset']).FullName
    @{
        name = 'Defer object and member removals until aggregate Application reconciliation'
        includedRuleSets = @(@{ path = $rulesetPath; action = 'Default' })
        rules = @($script:DeferredRules | Sort-Object | ForEach-Object { @{ id = $_; action = 'Warning' } })
    } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $root 'deferred.ruleset.json') -Encoding UTF8
    $CompilationParameters['Ruleset'] = Join-Path $root 'deferred.ruleset.json'
    $CompilationParameters['LogDirectory'] = Join-Path $root 'Logs'
    $CompilationParameters['ErrorLogDirectory'] = Join-Path $root 'Diagnostics'
    $null = New-Item -Path $CompilationParameters['LogDirectory'], $CompilationParameters['ErrorLogDirectory'] -ItemType Directory
    Write-Host "Deferring object/member removals to mandatory aggregate Application validation ($CountryCode, $BuildMode)."
}

function Get-ApplicationApiRemovalDiagnostics {
    param([string] $Root, [object[]] $Projects)

    $diagnostics = [System.Collections.Generic.List[object]]::new()
    $logs = [System.Collections.Generic.List[object]]::new()
    $seen = @{}
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $Root 'Logs') -Filter '*.log' -File) {
        $lines = @(Get-Content -LiteralPath $file.FullName)
        $paths = @($lines | Where-Object { $_ -cmatch '^Path: (.+)$' } | ForEach-Object { $_.Substring(6) })
        if ($paths.Count -ne 1) { throw "Missing or ambiguous project path in '$($file.FullName)'." }
        $owners = @($Projects | Where-Object { $_.Path -eq $paths[0] })
        if ($owners.Count -ne 1 -or $seen.ContainsKey($owners[0].Id)) { throw "Unexpected or duplicate project log '$($file.FullName)'." }
        $owner = $owners[0]
        $seen[$owner.Id] = $true
        $structuredPath = Join-Path (Join-Path $Root 'Diagnostics') "$($file.BaseName).errorLog.json"
        $structured = Get-Content -LiteralPath $structuredPath -Raw | ConvertFrom-Json -AsHashtable
        if ($structured['version'] -ne '0.2' -or -not $structured.ContainsKey('issues')) {
            throw "Unsupported compiler diagnostic format in '$structuredPath'."
        }
        if (@($structured.issues | Where-Object { $_.properties.severity -eq 'Error' }).Count -gt 0) {
            throw "Compiler errors must not be deferred by aggregate validation: '$structuredPath'."
        }
        $removals = @($structured.issues | Where-Object { $_.ruleId -in $script:DeferredRules })
        $lineMatches = @{}
        $warningPattern = '^(?:\[OUT\] )?(?:.+\([0-9]+,[0-9]+\): )?warning (' + ($script:DeferredRules -join '|') + '): (.+)$'
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -cmatch $warningPattern) {
                $signature = "$($Matches[1]):$($Matches[2])"
                if ($lineMatches.ContainsKey($signature)) { throw "Duplicate removal diagnostic in '$($file.FullName)'." }
                $lineMatches[$signature] = $i
            }
        }
        if ($lineMatches.Count -ne $removals.Count) { throw "Text/structured removal diagnostics disagree in '$($file.FullName)'." }
        $wholeObjects = @{}
        $wholeObjectParents = @{}
        foreach ($issue in @($removals | Where-Object { $script:RemovalRules.ContainsKey($_.ruleId) })) {
            $kind = ''
            $id = ''
            $name = ''
            if ($issue.ruleId -eq 'AS0065' -and $issue.shortMessage -cmatch "^Interface '(?<name>.+)' has been deleted\.$") {
                $kind = 'Interface'
                $name = $Matches.name
            }
            elseif ($issue.shortMessage -cmatch $script:ObjectRemovalPattern) {
                $kind = $Matches.kind
                $name = $Matches.name
                if ($Matches.ContainsKey('id')) { $id = $Matches.id }
            }
            else {
                throw "Unsupported object-removal diagnostic: $($issue.shortMessage)"
            }
            $kinds = $script:RemovalRules[$issue.ruleId]
            if (-not $kinds.ContainsKey($kind)) { throw "Unexpected object type for '$($issue.ruleId)'." }
            $named = $issue.ruleId -in @('AS0065', 'AS0089')
            if (-not $named -and -not $id) { throw "Missing object ID for '$($issue.ruleId)'." }
            $collection = $kinds[$kind]
            $parentKey = "${kind}:$name"
            if ($wholeObjects.ContainsKey($parentKey)) { throw "Ambiguous parent object '$parentKey'." }
            $key = if ($named) { "${collection}:Name:$name" } else { "${collection}:$([int]$id)" }
            $wholeObjects[$parentKey] = @{ Key = $key; Kind = $collection; Name = $name; Named = $named }
            $wholeObjectParents["$($issue.ruleId):$($issue.shortMessage)"] = $parentKey
        }
        foreach ($issue in $removals) {
            $signature = "$($issue.ruleId):$($issue.shortMessage)"
            $partName = ''
            $fieldName = ''
            $actionName = ''
            $actionKind = ''
            $methodName = ''
            $cueGroupName = ''
            $controlName = ''
            $controlKind = ''
            if (-not $lineMatches.ContainsKey($signature) -or $issue.properties.severity -ne 'Warning') {
                throw "Unsupported deferred diagnostic in '$structuredPath': $signature"
            }
            if ($script:MemberRules.ContainsKey($issue.ruleId)) {
                if ($issue.shortMessage -cnotmatch $script:MemberRules[$issue.ruleId]) {
                    throw "Unsupported member-removal diagnostic: $signature"
                }
                $parentKey = "$($Matches.kind):$($Matches.name)"
                if (-not $wholeObjects.ContainsKey($parentKey) -and $issue.ruleId -eq 'AS0018' -and $Matches.kind -cin @('Table', 'Page', 'Report')) {
                    $methodSignature = $Matches.method
                    $parameterStart = $methodSignature.IndexOf('(')
                    if ($parameterStart -le 0 -or -not $methodSignature.EndsWith(')')) {
                        throw "Unsupported procedure signature in diagnostic: $signature"
                    }
                    $methodName = $methodSignature.Substring(0, $parameterStart)
                    if ($methodName.StartsWith('"') -and $methodName.EndsWith('"')) {
                        $methodName = $methodName.Substring(1, $methodName.Length - 2).Replace('""', '"')
                    }
                    $collection = switch ($Matches.kind) { Table { 'Tables' }; Page { 'Pages' }; Report { 'Reports' } }
                    $parent = @{ Key = "${collection}:Name:$($Matches.name)"; Kind = $collection; Named = $true; Name = $Matches.name }
                }
                if (-not $wholeObjects.ContainsKey($parentKey) -and $Matches.kind -cin @('Page', 'PageCustomization')) {
                    if ($issue.ruleId -eq 'AS0032' -and $Matches.memberKind -eq 'part') {
                        $partName = $Matches.member
                    }
                    elseif ($issue.ruleId -eq 'AS0032' -and $Matches.memberKind -eq 'field') {
                        $fieldName = $Matches.member
                    }
                    elseif ($issue.ruleId -eq 'AS0032' -and $Matches.memberKind -eq 'cuegroup') {
                        $cueGroupName = $Matches.member
                    }
                    elseif ($issue.ruleId -eq 'AS0031') {
                        $actionName = $Matches.member
                        $actionKind = $script:ActionMemberKinds[$Matches.memberKind.Replace(' ', '')]
                    }
                    elseif ($issue.ruleId -eq 'AS0032') {
                        $controlName = $Matches.member
                        $controlKind = $script:ControlMemberKinds[$Matches.memberKind.Replace(' ', '')]
                    }
                    if ($partName -or $actionName -or $fieldName -or $cueGroupName -or $controlName) {
                        $collection = if ($Matches.kind -eq 'PageCustomization') { 'PageCustomizations' } else { 'Pages' }
                        $parent = @{ Key = "${collection}:Name:$($Matches.name)"; Kind = $collection; Named = $true; Name = $Matches.name }
                    }
                }
            }
            else {
                $parentKey = $wholeObjectParents[$signature]
            }
            if (-not $partName -and -not $actionName -and -not $fieldName -and -not $methodName -and -not $cueGroupName -and -not $controlName -and -not $wholeObjects.ContainsKey($parentKey)) {
                throw "$signature is not part of a whole-object move; the original compatibility check remains enforced."
            }
            if (-not $partName -and -not $actionName -and -not $fieldName -and -not $methodName -and -not $cueGroupName -and -not $controlName) { $parent = $wholeObjects[$parentKey] }
            $diagnostics.Add([PSCustomObject]@{
                RuleId = $issue.ruleId
                Key = $parent.Key
                Kind = $parent.Kind
                Named = $parent.Named
                Name = $parent.Name
                PartName = $partName
                FieldName = $fieldName
                ActionName = $actionName
                ActionKind = $actionKind
                MethodName = $methodName
                CueGroupName = $cueGroupName
                ControlName = $controlName
                ControlKind = $controlKind
                Origin = $owner
                Message = $issue.shortMessage
                Line = $lineMatches[$signature]
                LogPath = $file.FullName
            })
        }
        $logs.Add([PSCustomObject]@{ Path = $file.FullName; Lines = $lines; StructuredPath = $structuredPath; Structured = $structured })
    }
    if ($seen.Count -ne $Projects.Count) { throw 'Not every workspace project produced text and structured diagnostics.' }
    [PSCustomObject]@{ Diagnostics = $diagnostics.ToArray(); Logs = $logs.ToArray() }
}

function Get-ApplicationApiHostCandidates {
    param([hashtable] $Objects, [string] $Kind, [string] $Reference)

    $ownerId = ''
    if ($Reference -cmatch '^#(?<module>[0-9a-fA-F]{32})#(?<target>.+)$') {
        $ownerId = ([guid]$Matches.module).ToString()
        $Reference = $Matches.target
    }
    foreach ($object in $Objects.Values | Where-Object { $_.Kind -ceq $Kind -and (-not $ownerId -or $_.OwnerId -eq $ownerId) }) {
        $quotedName = '"' + $object.Name.Replace('"', '""') + '"'
        $references = @([string]$object.Id, $object.Name, $quotedName)
        if ($object.Namespace) { $references += "$($object.Namespace).$($object.Name)", "$($object.Namespace).$quotedName" }
        if ($Reference -cin $references) { $object }
    }
}

function Update-ApplicationApiPageMemberIds {
    param([object] $Baseline, [object] $Current, [ValidateSet('Controls', 'Actions')] [string] $ChildrenProperty)

    if ($Baseline -isnot [System.Collections.IDictionary] -or $Current -isnot [System.Collections.IDictionary] -or
        $Baseline['Name'] -isnot [string] -or [string]::IsNullOrWhiteSpace($Baseline['Name']) -or
        $Baseline['Name'] -cne $Current['Name'] -or $Baseline['Kind'] -cne $Current['Kind']) { return $false }
    $kinds = if ($ChildrenProperty -ceq 'Actions') {
        @('Area', 'Group', 'Action', 'Separator', 'ActionRef', 'CustomAction', 'SystemAction', 'FileUploadAction')
    }
    else { @('Area', 'Group', 'CueGroup', 'Repeater', 'Fixed', 'Grid', 'Part', 'SystemPart', 'Field', 'Label', 'UserControl', 'ChartPart') }
    $knownKinds = @($kinds) + @(0..($kinds.Count - 1) | ForEach-Object { [string]$_ })
    if ($ChildrenProperty -ceq 'Controls') { $knownKinds += 'Chart' }
    if ([string]$Baseline['Kind'] -cnotin $knownKinds) { return $false }

    $changed = $false
    if (($Baseline['Id'] -is [int] -or $Baseline['Id'] -is [long]) -and
        ($Current['Id'] -is [int] -or $Current['Id'] -is [long]) -and
        $Baseline['Id'] -ge 0 -and $Baseline['Id'] -le [int]::MaxValue -and
        $Current['Id'] -ge 0 -and $Current['Id'] -le [int]::MaxValue -and
        $Baseline['Id'] -ne $Current['Id']) {
        $Current['Id'] = $Baseline['Id']
        $changed = $true
    }
    foreach ($property in @('Controls', 'Actions')) {
        if ($Baseline[$property] -isnot [array] -or $Current[$property] -isnot [array] -or
            $Baseline[$property].Count -ne $Current[$property].Count) { continue }
        for ($index = 0; $index -lt $Baseline[$property].Count; $index++) {
            $childChanged = Update-ApplicationApiPageMemberIds -Baseline $Baseline[$property][$index] -Current $Current[$property][$index] -ChildrenProperty $property
            $changed = $changed -or $childChanged
        }
    }
    return $changed
}

function Update-ApplicationApiActionReferenceTarget {
    param(
        [System.Collections.IDictionary] $BaselineContract,
        [System.Collections.IDictionary] $CurrentContract,
        [object] $OldMember,
        [object] $NewMember,
        [hashtable] $Baseline,
        [hashtable] $Current
    )

    if ($BaselineContract['TargetName'] -isnot [string] -or [string]::IsNullOrWhiteSpace($BaselineContract['TargetName']) -or
        $BaselineContract['TargetName'] -cne $CurrentContract['TargetName']) { return $false }
    $oldTargets = @($Baseline.PageActions | Where-Object {
        $_.OwnerKey -ceq $OldMember.OwnerKey -and $_.MemberKind -ceq 'Action' -and $_.Name -ceq $BaselineContract['TargetName']
    })
    $newTargets = @($Current.PageActions | Where-Object {
        $_.OwnerKey -ceq $NewMember.OwnerKey -and $_.MemberKind -ceq 'Action' -and $_.Name -ceq $CurrentContract['TargetName']
    })
    if ($oldTargets.Count -ne 1 -or $newTargets.Count -ne 1 -or
        -not $oldTargets[0].PSObject.Properties['Contract'] -or -not $newTargets[0].PSObject.Properties['Contract']) { return $false }
    $oldTarget = $oldTargets[0].Contract | ConvertFrom-Json -AsHashtable
    $newTarget = $newTargets[0].Contract | ConvertFrom-Json -AsHashtable
    if ($BaselineContract['TargetId'] -cne $oldTarget['Id'] -or $CurrentContract['TargetId'] -cne $newTarget['Id']) { return $false }
    $null = Update-ApplicationApiPageMemberIds -Baseline $oldTarget -Current $newTarget -ChildrenProperty Actions
    $comparison = Get-ApplicationApiContractDifferences -Baseline ($oldTarget | ConvertTo-Json -Depth 100 -Compress) `
        -Current ($newTarget | ConvertTo-Json -Depth 100 -Compress)
    if ($comparison.Differences.Count -gt 0) { return $false }
    $CurrentContract['TargetId'] = $BaselineContract['TargetId']
    return $true
}

function Get-ApplicationApiCleanGroupRenames {
    param([string] $BuildMode, [string] $CountryCode)

    if ($BuildMode -cne 'Clean') { return @{} }
    if ($CountryCode -cin @('CA', 'US', 'MX')) {
        return @{
            Group56 = 'SalesTax'; Group57 = 'Group56'; Group58 = 'Group57'
            Group59 = 'Group58'; Group60 = 'Group59'; Group61 = 'Group60'; Group62 = 'Group61'
        }
    }
    if ($CountryCode -cin @('AU', 'NZ')) {
        return @{
            Group3 = 'WHT'; Group4 = 'Group3'; Group5 = 'Group4'; Group6 = 'BAS'
            Group7 = 'Group5'; Group8 = 'Group6'; Group9 = 'Group7'; Group10 = 'Group8'
            Group11 = 'Group9'; Group12 = 'Group10'; Group13 = 'Group11'; Group14 = 'Group12'
            Group15 = 'Group13'; Group16 = 'Group14'; Group17 = 'Group15'; Group18 = 'Group16'
            Group19 = 'Group17'; Group20 = 'Group18'; Group21 = 'Group19'; Group22 = 'Group20'
            Group23 = 'Group21'; Group24 = 'Group22'; Group25 = 'Group23'; Group26 = 'Group24'
            Group27 = 'Group25'; Group28 = 'Group26'; Group29 = 'Group27'; Group30 = 'Group28'
            Group31 = 'Group29'; Group32 = 'Group30'; Group33 = 'Group31'; Group34 = 'Group32'
            Group35 = 'Group33'; Group36 = 'Group34'; Group37 = 'Group35'; Group38 = 'Group36'
            Group39 = 'Group37'; Group41 = 'Group39'; Group42 = 'Group38'; Group43 = 'Group41'
            Group44 = 'Group42'; Group45 = 'Group43'; Group46 = 'Group44'; Group47 = 'Group45'
            Group48 = 'Group46'; Group49 = 'Group47'; Group50 = 'Group48'; Group51 = 'Group49'
            Group52 = 'Group50'; Group53 = 'Group51'; Group54 = 'Group52'; Group55 = 'Group53'
            Group56 = 'Group54'; Group57 = 'Group55'; Group58 = 'Group56'
            Group60 = 'Group58'; Group61 = 'Group59'; Group62 = 'Group60'; Group64 = 'Group61'
        }
    }
    return @{}
}

function Update-ApplicationApiCleanGroupNames {
    param([hashtable] $Action, [hashtable] $Renames)

    if ($Action['Kind'] -cin @('Group', 1) -and $Action['Name'] -cin @($Renames.Keys)) {
        $Action['Name'] = $Renames[$Action['Name']]
    }
    foreach ($child in $Action['Actions']) {
        Update-ApplicationApiCleanGroupNames -Action $child -Renames $Renames
    }
}

function Get-ApplicationApiActionPaths {
    param([object[]] $Actions, [string] $Name, [string[]] $Parent = @())

    foreach ($action in $Actions) {
        if ($action['Name'] -ceq $Name) {
            [PSCustomObject]@{ Parent = $Parent; Action = $action }
        }
        if ($action['Actions'] -is [array]) {
            Get-ApplicationApiActionPaths -Actions $action['Actions'] -Name $Name -Parent @($Parent + $action['Name'])
        }
    }
}

function Get-ApplicationApiCleanGroupRenameFailure {
    param(
        [hashtable] $Baseline, [hashtable] $Current, [object] $OldHost, [object] $NewHost,
        [object] $Diagnostic, [hashtable] $Renames, [string] $CountryCode,
        [System.Collections.Generic.List[string]] $CompatibleChanges, [ref] $ContractComparison
    )

    if ($OldHost.OwnerId -ne $NewHost.OwnerId -or $OldHost.Name -cne $NewHost.Name -or $OldHost.Namespace -cne $NewHost.Namespace) {
        return 'The original host object identity or ownership changed.'
    }
    $oldMembers = @($Baseline.PageActions | Where-Object { $_.OwnerKey -ceq $OldHost.Key -and $_.Name -ceq $Diagnostic.ActionName })
    if ($oldMembers.Count -ne 1 -or $oldMembers[0].MemberKind -cne 'ActionGroup') {
        return 'The clean rename does not identify a unique baseline action group.'
    }
    $newName = $Renames[$Diagnostic.ActionName]
    $newMembers = [System.Collections.Generic.List[object]]::new()
    foreach ($member in $Current.PageActions | Where-Object Name -CEQ $newName) {
        if ($member.OwnerKey -ceq $NewHost.Key -and $member.OwnerId -eq $NewHost.OwnerId) {
            $newMembers.Add($member)
        }
        elseif ($member.OwnerKey -clike 'PageExtensions:*' -and $member.OwnerId -ne $OldHost.OwnerId) {
            $hosts = @(Get-ApplicationApiHostCandidates -Objects $Current.Symbols -Kind Pages -Reference $member.PageReference)
            if (@($hosts | Where-Object Key -CEQ $OldHost.Key).Count -eq 0) { continue }
            if ($hosts.Count -ne 1) { return 'The clean rename target has an ambiguous host-object reference.' }
            $newMembers.Add($member)
        }
    }
    if ($newMembers.Count -ne 1 -or $newMembers[0].MemberKind -cne 'ActionGroup') {
        return "The clean rename target '$newName' is missing, ambiguous, or not an action group ($($newMembers.Count) candidates)."
    }
    $old = $oldMembers[0]
    $new = $newMembers[0]
    $oldPage = $Baseline.Contracts[$OldHost.Key] | ConvertFrom-Json -AsHashtable
    $newPage = $Current.Contracts[$NewHost.Key] | ConvertFrom-Json -AsHashtable
    $oldPaths = @(Get-ApplicationApiActionPaths -Actions $oldPage['Actions'] -Name $old.Name)
    $newParents = [System.Collections.Generic.List[object]]::new()
    if ($new.OwnerKey -ceq $NewHost.Key) {
        foreach ($path in @(Get-ApplicationApiActionPaths -Actions $newPage['Actions'] -Name $new.Name)) { $newParents.Add($path) }
    }
    else {
        $extension = $Current.PageExtensionContracts[$new.OwnerKey].Contract | ConvertFrom-Json -AsHashtable
        foreach ($change in $extension['ActionChanges']) {
            $paths = @(Get-ApplicationApiActionPaths -Actions $change['Actions'] -Name $new.Name)
            if ($paths.Count -eq 0) { continue }
            if ($change['ChangeKind'] -cnotin @('AddBefore', 3, 'AddAfter', 4)) {
                return 'The clean rename requires a verified sibling insertion anchor.'
            }
            $anchors = @(Get-ApplicationApiActionPaths -Actions $newPage['Actions'] -Name $change['Anchor'])
            if ($anchors.Count -ne 1) { return 'The clean rename insertion anchor is missing or ambiguous.' }
            foreach ($path in $paths) {
                $newParents.Add([PSCustomObject]@{ Parent = @($anchors[0].Parent + $path.Parent) })
            }
        }
    }
    if ($oldPaths.Count -ne 1 -or $newParents.Count -ne 1) {
        return 'The clean rename action hierarchy is missing or ambiguous.'
    }
    $oldParent = @($oldPaths[0].Parent | ForEach-Object { if ($_ -cin @($Renames.Keys)) { $Renames[$_] } else { $_ } })
    if (($oldParent -join "`0") -cne ($newParents[0].Parent -join "`0")) {
        return 'The clean rename changed the action group hierarchy.'
    }
    $oldContract = $old.Contract | ConvertFrom-Json -AsHashtable
    $newContract = $new.Contract | ConvertFrom-Json -AsHashtable
    Update-ApplicationApiCleanGroupNames -Action $oldContract -Renames $Renames
    $null = Update-ApplicationApiPageMemberIds -Baseline $oldContract -Current $newContract -ChildrenProperty Actions
    $comparison = Get-ApplicationApiContractDifferences -Baseline ($oldContract | ConvertTo-Json -Depth 100 -Compress) `
        -Current ($newContract | ConvertTo-Json -Depth 100 -Compress)
    if ($comparison.Differences.Count -gt 0) {
        $ContractComparison.Value = $comparison
        return 'The clean rename changed the action group contract.'
    }
    $CompatibleChanges.Add("CLEAN30 action group rename '$($old.Name)' -> '$newName' on '$($OldHost.Name)' ($CountryCode).")
    return ''
}

function Get-ApplicationApiMemberMoveFailure {
    param(
        [hashtable] $Baseline,
        [hashtable] $Current,
        [object] $OldHost,
        [object] $NewHost,
        [object] $Diagnostic,
        [System.Collections.Generic.List[string]] $CompatibleChanges,
        [ref] $ContractComparison
    )

    if ($OldHost.Kind -ceq 'PageCustomizations') {
        if ($OldHost.OwnerId -ne $NewHost.OwnerId -or $OldHost.Name -cne $NewHost.Name -or
            $OldHost.Namespace -cne $NewHost.Namespace -or $OldHost.ContractHash -cne $NewHost.ContractHash) {
            return 'The original page customization identity, ownership, or contract changed.'
        }
        if (-not $OldHost.TargetObject -or -not $NewHost.TargetObject) {
            return 'The page customization does not identify its underlying page.'
        }
        $oldPages = @(Get-ApplicationApiHostCandidates -Objects $Baseline.Symbols -Kind Pages -Reference $OldHost.TargetObject)
        $newPages = @(Get-ApplicationApiHostCandidates -Objects $Current.Symbols -Kind Pages -Reference $NewHost.TargetObject)
        if ($oldPages.Count -ne 1 -or $newPages.Count -ne 1) {
            return 'The customized page is missing or ambiguous in the exposed Application API.'
        }
        if ($oldPages[0].Key -cne $newPages[0].Key) { return 'The customized page identity changed.' }
        $OldHost = $oldPages[0]
        $NewHost = $newPages[0]
    }
    if ($OldHost.OwnerId -ne $NewHost.OwnerId -or $OldHost.Name -cne $NewHost.Name -or $OldHost.Namespace -cne $NewHost.Namespace) {
        return 'The original host object identity or ownership changed.'
    }
    $memberName = if ($Diagnostic.MethodName) { $Diagnostic.MethodName } elseif ($Diagnostic.PartName) { $Diagnostic.PartName } elseif ($Diagnostic.FieldName) { $Diagnostic.FieldName } elseif ($Diagnostic.CueGroupName) { $Diagnostic.CueGroupName } elseif ($Diagnostic.ControlName) { $Diagnostic.ControlName } else { $Diagnostic.ActionName }
    $memberKind = if ($Diagnostic.MethodName) { 'Method' } elseif ($Diagnostic.PartName) { 'Part' } elseif ($Diagnostic.FieldName) { 'Field' } elseif ($Diagnostic.CueGroupName) { 'CueGroup' } elseif ($Diagnostic.ControlName) { $Diagnostic.ControlKind } else { $Diagnostic.ActionKind }
    $collection = if ($Diagnostic.MethodName) { 'Methods' } elseif ($Diagnostic.PartName) { 'PageParts' } elseif ($Diagnostic.FieldName) { 'PageFields' } elseif ($Diagnostic.CueGroupName) { 'PageCueGroups' } elseif ($Diagnostic.ControlName) { 'PageControls' } else { 'PageActions' }
    $oldMembers = @($Baseline[$collection] | Where-Object { $_.OwnerKey -ceq $OldHost.Key -and $_.Name -ceq $memberName })
    if ($oldMembers.Count -ne 1 -or $oldMembers[0].MemberKind -cne $memberKind) {
        return 'The diagnostic does not identify a unique baseline member of the same kind.'
    }
    $objects = if ($Diagnostic.MethodName) { $Current.MethodObjects } else { $Current.Symbols }
    $newMembers = [System.Collections.Generic.List[object]]::new()
    foreach ($member in $Current[$collection] | Where-Object Name -CEQ $memberName) {
        if ($Diagnostic.MethodName -and $member.HostKind -cne $OldHost.Kind) { continue }
        $reference = if ($Diagnostic.MethodName) { $member.HostReference } else { $member.PageReference }
        $hosts = @(Get-ApplicationApiHostCandidates -Objects $objects -Kind $OldHost.Kind -Reference $reference)
        if (@($hosts | Where-Object Key -CEQ $OldHost.Key).Count -eq 0) { continue }
        if ($hosts.Count -ne 1) { return 'A candidate member has an ambiguous host-object reference.' }
        $newMembers.Add($member)
    }
    if ($newMembers.Count -ne 1) { return 'The member is missing or ambiguous on the original host object.' }
    $old = $oldMembers[0]
    $new = $newMembers[0]
    $extensionKind = switch ($OldHost.Kind) { Tables { 'TableExtensions' }; Pages { 'PageExtensions' }; Reports { 'ReportExtensions' } }
    if ($new.MemberKind -cne $memberKind -or $new.OwnerId -eq $old.OwnerId -or $new.OwnerKey -cnotlike "${extensionKind}:*") {
        return 'The member has not moved to a matching extension in another exposed Application member.'
    }
    if ($old.ContractHash -cne $new.ContractHash) {
        $compatible = $false
        $idsChanged = $false
        $targetIdChanged = $false
        $tooltipAdded = $false
        if ($memberKind -ne 'Method' -and $old.PSObject.Properties['Contract'] -and $new.PSObject.Properties['Contract']) {
            $oldContract = $old.Contract | ConvertFrom-Json -AsHashtable
            $newContract = $new.Contract | ConvertFrom-Json -AsHashtable
            $childrenProperty = if ($collection -ceq 'PageActions') { 'Actions' } else { 'Controls' }
            # Reference IDs require a separately verified equivalent target.
            $idsChanged = Update-ApplicationApiPageMemberIds -Baseline $oldContract -Current $newContract -ChildrenProperty $childrenProperty
            if ($memberKind -ceq 'ActionRef' -and $oldContract['TargetId'] -cne $newContract['TargetId']) {
                $targetIdChanged = Update-ApplicationApiActionReferenceTarget -BaselineContract $oldContract -CurrentContract $newContract `
                    -OldMember $old -NewMember $new -Baseline $Baseline -Current $Current
            }
            $oldJson = $oldContract | ConvertTo-Json -Depth 100 -Compress
            $newJson = $newContract | ConvertTo-Json -Depth 100 -Compress
            $compatible = (Get-ApplicationApiContractDifferences -Baseline $oldJson -Current $newJson).Differences.Count -eq 0
            if (-not $compatible -and $memberKind -ceq 'Field') {
                $tooltipAdded = Test-ApplicationApiAddedFieldTooltip -Baseline $oldJson -Current $newJson
                $compatible = $tooltipAdded
            }
        }
        if (-not $compatible) {
            if ($ContractComparison -and $old.PSObject.Properties['Contract'] -and $new.PSObject.Properties['Contract']) {
                $ContractComparison.Value = Get-ApplicationApiContractDifferences -Baseline $old.Contract -Current $new.Contract
            }
            return 'The relocated member contract changed.'
        }
        if ($idsChanged) { $CompatibleChanges.Add("Regenerated compiler IDs for relocated page member '$memberName'.") }
        if ($targetIdChanged) { $CompatibleChanges.Add("Verified regenerated target ID for relocated actionref '$memberName'.") }
        if ($tooltipAdded) { $CompatibleChanges.Add("Added tooltip to relocated field '$memberName'.") }
    }
    if ($memberKind -ne 'Part') { return '' }
    if ($old.TargetPageId -le 0) { return 'The baseline part does not identify its target page.' }
    $targetKey = "Pages:$($old.TargetPageId)"
    $oldTarget = $Baseline.Symbols[$targetKey]
    $newTarget = $Current.Symbols[$targetKey]
    if (-not $oldTarget -or -not $newTarget) { return 'The part target page is missing, internal, or outside the exposed Application API.' }
    if ($oldTarget.Name -cne $newTarget.Name -or $oldTarget.Namespace -cne $newTarget.Namespace -or
        $oldTarget.ContractHash -cne $newTarget.ContractHash) {
        return 'The part target page contract changed.'
    }
    return ''
}

function Add-ApplicationApiContractValues {
    param(
        [System.Text.Json.JsonElement] $Element,
        [string] $Path,
        [System.Collections.IDictionary] $Values
    )

    if ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Object -and @($Element.EnumerateObject()).Count -gt 0) {
        foreach ($property in $Element.EnumerateObject()) {
            Add-ApplicationApiContractValues -Element $property.Value -Path "$Path.$($property.Name)" -Values $Values
        }
    }
    elseif ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Array -and $Element.GetArrayLength() -gt 0) {
        for ($index = 0; $index -lt $Element.GetArrayLength(); $index++) {
            Add-ApplicationApiContractValues -Element $Element[$index] -Path "$Path[$index]" -Values $Values
        }
    }
    else {
        $Values[$Path] = $Element.GetRawText()
    }
}

function Get-ApplicationApiContractDifferences {
    param([string] $Baseline, [string] $Current)

    $old = [System.Text.Json.JsonDocument]::Parse($Baseline)
    try {
        $new = [System.Text.Json.JsonDocument]::Parse($Current)
        try {
            $oldValues = [System.Collections.Generic.Dictionary[string, string]]::new([StringComparer]::Ordinal)
            $newValues = [System.Collections.Generic.Dictionary[string, string]]::new([StringComparer]::Ordinal)
            Add-ApplicationApiContractValues -Element $old.RootElement -Path '$' -Values $oldValues
            Add-ApplicationApiContractValues -Element $new.RootElement -Path '$' -Values $newValues
            $differences = @(
                foreach ($path in @(@($oldValues.Keys) + @($newValues.Keys) | Sort-Object -Unique -CaseSensitive)) {
                    if ($oldValues.ContainsKey($path) -and $newValues.ContainsKey($path) -and $oldValues[$path] -ceq $newValues[$path]) { continue }
                    [PSCustomObject]@{
                        Path = $path
                        Baseline = if ($oldValues.ContainsKey($path)) { $oldValues[$path] } else { '<missing>' }
                        Current = if ($newValues.ContainsKey($path)) { $newValues[$path] } else { '<missing>' }
                    }
                }
            )
            [PSCustomObject]@{
                Differences = @($differences | Select-Object -First 20)
                Truncated = $differences.Count -gt 20
            }
        }
        finally {
            $new.Dispose()
        }
    }
    finally {
        $old.Dispose()
    }
}

function Test-ApplicationApiAddedFieldTooltip {
    param([string] $Baseline, [string] $Current)

    $old = $Baseline | ConvertFrom-Json -AsHashtable
    $new = $Current | ConvertFrom-Json -AsHashtable
    if ($old['Kind'] -cnotin @('Field', 8) -or $new['Kind'] -cne $old['Kind'] -or
        $old['Properties'] -isnot [array] -or $new['Properties'] -isnot [array]) { return $false }
    $oldTooltip = @($old['Properties'] | Where-Object { $_['Name'] -ceq 'ToolTip' })
    $newTooltip = @($new['Properties'] | Where-Object { $_['Name'] -ceq 'ToolTip' })
    if ($oldTooltip.Count -ne 0 -or $newTooltip.Count -ne 1 -or $newTooltip[0]['Value'] -isnot [string] -or
        [string]::IsNullOrWhiteSpace($newTooltip[0]['Value']) -or
        @($newTooltip[0].Keys | Where-Object { $_ -cnotin @('Name', 'Value') }).Count -gt 0) { return $false }
    $new['Properties'] = @($new['Properties'] | Where-Object { $_['Name'] -cne 'ToolTip' })
    $remaining = Get-ApplicationApiContractDifferences -Baseline ($old | ConvertTo-Json -Depth 100 -Compress) -Current ($new | ConvertTo-Json -Depth 100 -Compress)
    return $remaining.Differences.Count -eq 0
}

function Update-ApplicationApiOptionCaptions {
    param([object] $Baseline, [object] $Current, [System.Collections.Generic.List[string]] $Changes, [string] $Path = '$')

    if ($Baseline -is [System.Collections.IDictionary] -and $Current -is [System.Collections.IDictionary]) {
        $type = $Baseline['TypeDefinition']
        $newType = $Current['TypeDefinition']
        if ($Baseline['Kind'] -in @('Field', 8) -and $Current['Kind'] -eq $Baseline['Kind'] -and
            $type -is [System.Collections.IDictionary] -and $newType -is [System.Collections.IDictionary] -and
            $type['Name'] -ceq 'Option' -and $newType['Name'] -ceq 'Option' -and $type['OptionMembers'] -is [array] -and
            $Baseline['Properties'] -is [array] -and $Current['Properties'] -is [array]) {
            $oldCaption = @($Baseline['Properties'] | Where-Object { $_['Name'] -ceq 'OptionCaption' })
            $newCaption = @($Current['Properties'] | Where-Object { $_['Name'] -ceq 'OptionCaption' })
            if ($oldCaption.Count -eq 1 -and $newCaption.Count -eq 1 -and
                $oldCaption[0]['Value'] -is [string] -and $newCaption[0]['Value'] -is [string]) {
                $oldLabels = $oldCaption[0]['Value'].Split(',')
                $newLabels = $newCaption[0]['Value'].Split(',')
                $prefixMatches = $newLabels.Count -gt $oldLabels.Count -and $newLabels.Count -eq $type['OptionMembers'].Count
                if ($prefixMatches) {
                    for ($i = 0; $i -lt $oldLabels.Count; $i++) {
                        if ($oldLabels[$i] -cne $newLabels[$i]) { $prefixMatches = $false; break }
                    }
                    foreach ($label in $newLabels[$oldLabels.Count..($newLabels.Count - 1)]) {
                        if ([string]::IsNullOrWhiteSpace($label)) { $prefixMatches = $false }
                    }
                }
                if ($prefixMatches) {
                    $newCaption[0]['Value'] = $oldCaption[0]['Value']
                    $Changes.Add("Completed missing option captions at $Path.")
                }
            }
        }
        foreach ($key in $Baseline.Keys) {
            if ($Current.Contains($key)) {
                Update-ApplicationApiOptionCaptions -Baseline $Baseline[$key] -Current $Current[$key] -Changes $Changes -Path "$Path.$key"
            }
        }
    }
    elseif ($Baseline -is [array] -and $Current -is [array]) {
        for ($i = 0; $i -lt [Math]::Min($Baseline.Count, $Current.Count); $i++) {
            Update-ApplicationApiOptionCaptions -Baseline $Baseline[$i] -Current $Current[$i] -Changes $Changes -Path "$Path[$i]"
        }
    }
}

function Get-ApplicationApiControls {
    param([object[]] $Controls)

    foreach ($control in $Controls) {
        $control
        if ($control['Controls'] -is [array]) { Get-ApplicationApiControls -Controls $control['Controls'] }
    }
}

function Add-ApplicationApiFieldsBeforeAnchor {
    param([System.Collections.IDictionary] $Node, [string] $Anchor, [object[]] $Fields)

    if ($Node['Controls'] -isnot [array]) { return }
    $controls = [System.Collections.Generic.List[object]]::new()
    foreach ($control in $Node['Controls']) {
        if ($control['Name'] -ceq $Anchor) {
            foreach ($field in $Fields) { $controls.Add($field) }
        }
        $controls.Add($control)
        Add-ApplicationApiFieldsBeforeAnchor -Node $control -Anchor $Anchor -Fields $Fields
    }
    $Node['Controls'] = $controls.ToArray()
}

function Update-ApplicationApiRelocatedFields {
    param(
        [System.Collections.IDictionary] $Baseline,
        [System.Collections.IDictionary] $Current,
        [hashtable] $Snapshot,
        [object] $Page,
        [System.Collections.Generic.List[string]] $Changes
    )

    $oldFields = @(Get-ApplicationApiControls -Controls $Baseline['Controls'] | Where-Object { $_['Kind'] -cin @('Field', 8) })
    $currentNames = @(Get-ApplicationApiControls -Controls $Current['Controls'] | ForEach-Object { $_['Name'] })
    $missing = [System.Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    foreach ($field in $oldFields | Where-Object { $_['Name'] -cnotin $currentNames }) {
        if ($missing.ContainsKey($field['Name'])) { return $false }
        $missing.Add($field['Name'], [System.Collections.Generic.List[object]]::new())
    }
    if ($missing.Count -eq 0) { return $true }
    $providers = [System.Collections.Generic.List[object]]::new()
    foreach ($extension in $Snapshot.PageExtensionContracts.Values) {
        $hosts = @(Get-ApplicationApiHostCandidates -Objects $Snapshot.Symbols -Kind Pages -Reference $extension.PageReference)
        if (@($hosts | Where-Object Key -CEQ $Page.Key).Count -eq 0) { continue }
        if ($hosts.Count -ne 1 -or $extension.OwnerId -ne $Page.OwnerId) { return $false }
        $contract = $extension.Contract | ConvertFrom-Json -AsHashtable
        $provider = @{ Extension = $extension; Contract = $contract }
        $providers.Add($provider)
        foreach ($change in $contract['ControlChanges']) {
            foreach ($field in Get-ApplicationApiControls -Controls $change['Controls']) {
                if ($field['Kind'] -cin @('Field', 8) -and $missing.ContainsKey($field['Name'])) {
                    $missing[$field['Name']].Add($provider)
                }
            }
        }
    }
    foreach ($name in $missing.Keys) {
        if ($missing[$name].Count -ne 1) { return $false }
    }
    foreach ($provider in $providers) {
        $contract = $provider.Contract
        if (@($contract.Keys | Where-Object { $_ -cnotin @('Name', 'Id', 'TargetObject', 'ControlChanges') }).Count -gt 0 -or
            $contract['ControlChanges'] -isnot [array]) { return $false }
        foreach ($change in $contract['ControlChanges']) {
            if (@($change.Keys | Where-Object { $_ -cnotin @('Anchor', 'ChangeKind', 'Controls') }).Count -gt 0 -or
                $change['ChangeKind'] -cnotin @('AddBefore', 3) -or $change['Anchor'] -isnot [string] -or
                $change['Controls'] -isnot [array] -or $change['Controls'].Count -eq 0) { return $false }
            foreach ($field in $change['Controls']) {
                if ($field['Kind'] -cnotin @('Field', 8) -or -not $missing.ContainsKey($field['Name'])) { return $false }
            }
            $anchors = @(Get-ApplicationApiControls -Controls $Current['Controls'] | Where-Object { $_['Name'] -ceq $change['Anchor'] })
            if ($anchors.Count -ne 1) { return $false }
            Add-ApplicationApiFieldsBeforeAnchor -Node $Current -Anchor $change['Anchor'] -Fields $change['Controls']
            foreach ($field in $change['Controls']) {
                $Changes.Add("Relocated field '$($field['Name'])' into page extension '$($provider.Extension.Name)'.")
            }
        }
    }
    return $true
}

function Get-ApplicationApiCompatibleAdditions {
    param([string] $Baseline, [string] $Current, [hashtable] $Snapshot, [object] $Page)

    $old = $Baseline | ConvertFrom-Json -AsHashtable
    $new = $Current | ConvertFrom-Json -AsHashtable
    $rejected = [PSCustomObject]@{ Compatible = $false; Changes = @() }
    $changes = [System.Collections.Generic.List[string]]::new()
    $methods = @()
    foreach ($contract in @($old, $new)) {
        if ($contract.ContainsKey('Methods') -and $contract.Methods -isnot [array]) { return $rejected }
        $index = [System.Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
        foreach ($method in $(if ($contract.ContainsKey('Methods')) { $contract.Methods })) {
            if ($method -isnot [System.Collections.IDictionary] -or $method['Name'] -isnot [string] -or
                [string]::IsNullOrWhiteSpace($method.Name)) { return $rejected }
            $signature = $method | ConvertTo-Json -Depth 100 -Compress
            if ($index.ContainsKey($signature)) { return $rejected }
            $index.Add($signature, $method)
        }
        $methods += ,$index
    }
    foreach ($signature in $methods[0].Keys) {
        if (-not $methods[1].ContainsKey($signature)) { return $rejected }
    }
    foreach ($signature in $methods[1].Keys) {
        if ($methods[0].ContainsKey($signature)) { continue }
        $method = $methods[1][$signature]
        if (@($methods[0].Values | Where-Object { $_['Name'] -ceq $method['Name'] }).Count -gt 0) { return $rejected }
        $attributes = $method['Attributes']
        if ($method['IsLocal'] -isnot [bool] -or -not $method.IsLocal -or $attributes -isnot [array] -or $attributes.Count -ne 1 -or
            $attributes[0]['Name'] -cne 'IntegrationEvent' -or $attributes[0]['Arguments'] -isnot [array] -or
            $attributes[0].Arguments.Count -ne 2 -or $attributes[0].Arguments[0]['Value'] -cne 'False' -or
            $attributes[0].Arguments[1]['Value'] -cne 'False') { return $rejected }
        if ($method.ContainsKey('ReturnTypeDefinition') -and $method.ReturnTypeDefinition['Name'] -cne 'None') { return $rejected }
        $changes.Add("Added integration event '$($method.Name)'.")
    }
    if ($methods[0].Count -gt 0) {
        $old.Methods = @($methods[0].Keys | Sort-Object -CaseSensitive | ForEach-Object { $methods[0][$_] })
        $new.Methods = @($methods[0].Keys | Sort-Object -CaseSensitive | ForEach-Object { $methods[1][$_] })
    }
    else {
        $null = $old.Remove('Methods')
        $null = $new.Remove('Methods')
    }
    if ($Page -and $Page.Kind -ceq 'Pages' -and
        -not (Update-ApplicationApiRelocatedFields -Baseline $old -Current $new -Snapshot $Snapshot -Page $Page -Changes $changes)) { return $rejected }
    Update-ApplicationApiOptionCaptions -Baseline $old -Current $new -Changes $changes
    if ($changes.Count -eq 0) { return $rejected }
    $remaining = Get-ApplicationApiContractDifferences -Baseline ($old | ConvertTo-Json -Depth 100 -Compress) -Current ($new | ConvertTo-Json -Depth 100 -Compress)
    if ($remaining.Differences.Count -gt 0) { return $rejected }
    [PSCustomObject]@{ Compatible = $true; Changes = $changes.ToArray() }
}

<#
.SYNOPSIS
    Checks object and member removals against the same published baseline used by AppSourceCop.
.DESCRIPTION
    Whole-object moves may add local, nonisolated integration events or complete missing
    trailing option captions. Page fields may move unchanged into the destination app's
    page extensions using addbefore at their original positions. Existing methods, option
    values, and all other contracts must remain unchanged. Relocated fields may gain a
    tooltip but cannot change an existing one. Verified page-member relocations may
    regenerate declaration IDs. Actionref target IDs require an unchanged, uniquely
    identified source action in both owners. Accepted changes are recorded.
#>
function Test-ApplicationApiMoves {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)] [hashtable] $Baseline,
        [Parameter(Mandatory)] [hashtable] $Current,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]] $Diagnostics,
        [string] $BuildMode,
        [string] $CountryCode
    )

    if ($Baseline.Application.Id -ne $Current.Application.Id -or $Baseline.Application.Publisher -cne $Current.Application.Publisher) {
        throw 'Application identity changed.'
    }
    $cleanRenames = Get-ApplicationApiCleanGroupRenames -BuildMode $BuildMode -CountryCode $CountryCode
    foreach ($diagnostic in $Diagnostics) {
        $origin = $diagnostic.Origin
        $baselineObjects = if ($diagnostic.MethodName) { $Baseline.MethodObjects } else { $Baseline.Symbols }
        $currentObjects = if ($diagnostic.MethodName) { $Current.MethodObjects } else { $Current.Symbols }
        $candidates = @(
            if ($diagnostic.Named) {
                $baselineObjects.Values | Where-Object { $_.Kind -ceq $diagnostic.Kind -and $_.Name -ceq $diagnostic.Name -and $_.OwnerId -eq $origin.Id }
            }
            elseif ($baselineObjects.ContainsKey($diagnostic.Key)) { $baselineObjects[$diagnostic.Key] }
        )
        $old = if ($candidates.Count -eq 1) { $candidates[0] } else { $null }
        $key = if ($old) { $old.Key } else { $diagnostic.Key }
        $new = $currentObjects[$key]
        $reason = ''
        $memberComparison = $null
        $compatibleChanges = [System.Collections.Generic.List[string]]::new()
        if ($candidates.Count -gt 1) { $reason = 'The diagnostic does not identify an unambiguous object namespace.' }
        elseif (-not $old -or -not $new) { $reason = 'Object is missing, internal, or outside the exposed Application API.' }
        elseif ($old.OwnerId -ne $origin.Id -or $old.Name -cne $diagnostic.Name) { $reason = 'Diagnostic does not identify the baseline owner/object.' }
        elseif (-not $Current.Packages.ContainsKey($origin.Id)) { $reason = 'The source app is no longer an exposed Application member.' }
        elseif ($Baseline.Packages[$origin.Id].Version -ne [version]$origin.BaselineVersion -or
            $Baseline.Packages[$origin.Id].Name -cne $origin.BaselineName -or
            $Baseline.Packages[$origin.Id].Publisher -cne $origin.BaselinePublisher) { $reason = 'AppSourceCop and aggregate baselines disagree.' }
        elseif ($diagnostic.RuleId -ceq 'AS0031' -and $diagnostic.ActionKind -ceq 'ActionGroup' -and
            $key -ceq 'Pages:8901' -and $old.Name -ceq 'Finance Manager Role Center' -and
            $old.Namespace -ceq 'Microsoft.Finance.RoleCenters' -and $old.OwnerId -eq '437dbf0e-84ff-417a-965d-ed2bb9650972' -and
            $diagnostic.ActionName -cin @($cleanRenames.Keys)) {
            $reason = Get-ApplicationApiCleanGroupRenameFailure -Baseline $Baseline -Current $Current -OldHost $old -NewHost $new `
                -Diagnostic $diagnostic -Renames $cleanRenames -CountryCode $CountryCode -CompatibleChanges $compatibleChanges -ContractComparison ([ref]$memberComparison)
        }
        elseif ($diagnostic.PartName -or $diagnostic.ActionName -or $diagnostic.FieldName -or $diagnostic.MethodName -or $diagnostic.CueGroupName -or $diagnostic.ControlName) {
            $reason = Get-ApplicationApiMemberMoveFailure -Baseline $Baseline -Current $Current -OldHost $old -NewHost $new -Diagnostic $diagnostic -CompatibleChanges $compatibleChanges -ContractComparison ([ref]$memberComparison)
        }
        elseif ($old.OwnerId -eq $new.OwnerId) { $reason = 'Object has not moved to another Application member.' }
        elseif ($old.Name -cne $new.Name -or $old.Namespace -cne $new.Namespace) {
            $reason = 'Moved object contract changed; automatic migration exception is unsafe.'
        }
        elseif ($old.ContractHash -cne $new.ContractHash) {
            $compatible = if ($Baseline.ContainsKey('Contracts') -and $Current.ContainsKey('Contracts') -and
                $Baseline.Contracts.ContainsKey($key) -and $Current.Contracts.ContainsKey($key)) {
                Get-ApplicationApiCompatibleAdditions -Baseline $Baseline.Contracts[$key] -Current $Current.Contracts[$key] -Snapshot $Current -Page $new
            }
            if ($compatible -and $compatible.Compatible) { $compatibleChanges.AddRange([string[]]$compatible.Changes) }
            else { $reason = 'Moved object contract changed; automatic migration exception is unsafe.' }
        }
        $contractDifferences = @()
        $contractDifferencesTruncated = $false
        if ($memberComparison) {
            $contractDifferences = $memberComparison.Differences
            $contractDifferencesTruncated = $memberComparison.Truncated
        }
        elseif ($reason -and $old -and $new -and $old.ContractHash -cne $new.ContractHash -and
            $Baseline.ContainsKey('Contracts') -and $Current.ContainsKey('Contracts') -and
            $Baseline.Contracts.ContainsKey($key) -and $Current.Contracts.ContainsKey($key)) {
            $comparison = Get-ApplicationApiContractDifferences -Baseline $Baseline.Contracts[$key] -Current $Current.Contracts[$key]
            $contractDifferences = $comparison.Differences
            $contractDifferencesTruncated = $comparison.Truncated
        }
        [PSCustomObject]@{
            RuleId = $diagnostic.RuleId
            Key = $key
            Name = $diagnostic.Name
            PartName = $diagnostic.PartName
            FieldName = $diagnostic.FieldName
            ActionName = $diagnostic.ActionName
            ActionKind = $diagnostic.ActionKind
            MethodName = $diagnostic.MethodName
            CueGroupName = $diagnostic.CueGroupName
            ControlName = $diagnostic.ControlName
            ControlKind = $diagnostic.ControlKind
            Accepted = -not $reason
            Reason = $reason
            CompatibleChanges = $compatibleChanges.ToArray()
            ContractDifferences = $contractDifferences
            ContractDifferencesTruncated = $contractDifferencesTruncated
            Baseline = $old
            Current = $new
            Diagnostic = $diagnostic.Message
        }
    }
}

function Get-ApplicationApiGateSnapshot {
    param([string[]] $Paths, [string[]] $Keys, [string[]] $PartNames = @(), [string[]] $ActionNames = @(), [string[]] $FieldNames = @(), [string[]] $MethodNames = @(), [string[]] $CueGroupNames = @(), [string[]] $ControlNames = @())

    $roots = @($Paths | ForEach-Object { Get-ApplicationApiPackageInfo -Path $_ } |
        Where-Object { $_.Id -eq 'c1335042-3002-4257-bf8a-75c898ccb1b8' -and $_.Name -ceq 'Application' })
    if ($roots.Count -ne 1) { throw "Expected one compiled Application facade; found $($roots.Count)." }
    Get-ApplicationApiSnapshot -ApplicationPackagePath $roots[0].Path -DependencyPackagePaths $Paths -SymbolKeys $Keys `
        -PartNames $PartNames -ActionNames $ActionNames -FieldNames $FieldNames -MethodNames $MethodNames -CueGroupNames $CueGroupNames -ControlNames $ControlNames -IncludeContracts
}

<#
.SYNOPSIS
    Verifies deferred removals before AL-Go consolidates logs and checks new warnings.
#>
function Complete-ApplicationApiValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [hashtable] $CompilationParameters,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [string[]] $AppFiles
    )

    $root = Get-ApplicationApiValidationPath -CompilationParameters $CompilationParameters
    $statePath = Join-Path $root 'state.json'
    if (-not (Test-Path -LiteralPath $statePath)) { return }
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -AsHashtable
    if ($state.Status -ne 'Pending') { throw "Unexpected aggregate validation status '$($state.Status)'." }
    try {
        $records = Get-ApplicationApiRemovalDiagnostics -Root $root -Projects $state.Projects
        if ($records.Diagnostics.Count -gt 0) {
            $baselineFolder = Join-Path $root 'Baseline'
            if ($state.BuildMode -ne 'Clean') {
                $versions = @($state.Projects.BaselineVersion | Where-Object { $_ } | Sort-Object -Unique)
                if ($versions.Count -ne 1) { throw 'A single AppSourceCop baseline version is required for aggregate validation.' }
                Import-Module "$PSScriptRoot\GuardingV2ExtensionsHelper.psm1"
                $restored = Restore-BaselinesFromArtifacts -AppName 'Application' -TargetFolder $baselineFolder -BaselineVersion $versions[0] -CountryCode $state.CountryCode
                if (-not $restored) { throw 'Unable to restore the baseline Application facade.' }
            }
            $baselinePaths = @(Get-ChildItem -LiteralPath $baselineFolder -Filter '*.app' -File | Select-Object -ExpandProperty FullName)
            $currentPaths = @(Select-ApplicationApiPackages -PreferredPaths $AppFiles `
                -FallbackPaths @(Get-ChildItem -LiteralPath $CompilationParameters.OutFolder -Filter '*.app' -File | Select-Object -ExpandProperty FullName))
            $releasedBaselineNames = if ($state.BuildMode -eq 'Clean') { @() } else { @($baselinePaths | Split-Path -Leaf) }
            $cachePaths = @(Get-ChildItem -LiteralPath $CompilationParameters.PackageCachePath -Filter '*.app' -File |
                Where-Object { $_.Name -notlike '*_clean.app' -and $_.Name -notin $releasedBaselineNames } |
                Select-Object -ExpandProperty FullName)
            $currentPaths = @(Select-ApplicationApiPackages -PreferredPaths $currentPaths -FallbackPaths $cachePaths)
            $keys = @($records.Diagnostics.Key | Sort-Object -Unique)
            $partNames = @($records.Diagnostics.PartName | Where-Object { $_ } | Sort-Object -Unique)
            $actionNames = @($records.Diagnostics.ActionName | Where-Object { $_ } | Sort-Object -Unique)
            $cleanRenames = Get-ApplicationApiCleanGroupRenames -BuildMode $state.BuildMode -CountryCode $state.CountryCode
            if (@($records.Diagnostics | Where-Object {
                $_.Kind -ceq 'Pages' -and $_.Name -ceq 'Finance Manager Role Center' -and $_.ActionKind -ceq 'ActionGroup'
            }).Count -gt 0) {
                $actionNames = @(@($actionNames) + @($cleanRenames.Values) | Sort-Object -Unique)
            }
            $fieldNames = @($records.Diagnostics.FieldName | Where-Object { $_ } | Sort-Object -Unique)
            $methodNames = @($records.Diagnostics.MethodName | Where-Object { $_ } | Sort-Object -Unique)
            $cueGroupNames = @($records.Diagnostics.CueGroupName | Where-Object { $_ } | Sort-Object -Unique)
            $controlNames = @($records.Diagnostics.ControlName | Where-Object { $_ } | Sort-Object -Unique)
            $baseline = Get-ApplicationApiGateSnapshot -Paths $baselinePaths -Keys $keys -PartNames $partNames -ActionNames $actionNames -FieldNames $fieldNames -MethodNames $methodNames -CueGroupNames $cueGroupNames -ControlNames $controlNames
            $current = Get-ApplicationApiGateSnapshot -Paths $currentPaths -Keys $keys -PartNames $partNames -ActionNames $actionNames -FieldNames $fieldNames -MethodNames $methodNames -CueGroupNames $cueGroupNames -ControlNames $controlNames
            $state.AcceptedMoves = @(Test-ApplicationApiMoves -Baseline $baseline -Current $current -Diagnostics $records.Diagnostics `
                -BuildMode $state.BuildMode -CountryCode $state.CountryCode)
            foreach ($move in @($state.AcceptedMoves | Where-Object { $_.CompatibleChanges.Count -gt 0 } | Group-Object Key)) {
                $changes = @($move.Group.CompatibleChanges | Sort-Object -Unique -CaseSensitive)
                Write-Host "Verified compatible additions for $($move.Group[0].Name): $($changes -join ' ')"
            }
            $rejected = @($state.AcceptedMoves | Where-Object { -not $_.Accepted })
            if ($rejected.Count -gt 0) {
                foreach ($issue in $rejected) {
                    Write-Host "::error::$($issue.RuleId) $($issue.Name): $($issue.Reason)"
                    if ($issue.ContractDifferences.Count -gt 0) {
                        Write-Host "$($issue.RuleId) $($issue.Name) contract differences (JSON paths; full values in ApplicationApi state.json):"
                        foreach ($difference in $issue.ContractDifferences) {
                            Write-Host "  $($difference.Path)"
                        }
                        if ($issue.ContractDifferencesTruncated) { Write-Host '  Only the first 20 differences are included.' }
                    }
                }
                throw "$($rejected.Count) removal(s) were not verified as compatible Application moves."
            }
        }
        $originals = Join-Path $root 'Originals'
        $null = New-Item -Path $originals -ItemType Directory
        foreach ($log in $records.Logs) {
            $accepted = @($records.Diagnostics | Where-Object { $_.LogPath -eq $log.Path })
            if ($accepted.Count -gt 0) {
                Copy-Item -LiteralPath $log.Path -Destination (Join-Path $originals "$([System.IO.Path]::GetFileName($log.Path)).txt")
                Copy-Item -LiteralPath $log.StructuredPath -Destination $originals
                foreach ($diagnostic in $accepted) {
                    $log.Lines[$diagnostic.Line] = "[OUT] info BCAPPAPI: Verified compatible Application move ($($diagnostic.RuleId)): $($diagnostic.Name)."
                }
                $log.Structured.issues = @($log.Structured.issues | Where-Object { $_.ruleId -notin $script:DeferredRules })
                $log.Lines | Set-Content -LiteralPath $log.Path -Encoding UTF8
                $log.Structured | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $log.StructuredPath -Encoding UTF8
            }
            if ($state.OriginalErrorLogDirectory) {
                $null = New-Item -Path $state.OriginalErrorLogDirectory -ItemType Directory -Force
                Copy-Item -LiteralPath $log.StructuredPath -Destination $state.OriginalErrorLogDirectory
            }
        }
        $state.Status = 'Passed'
        $moveCount = @($state.AcceptedMoves | ForEach-Object Key | Sort-Object -Unique).Count
        Write-Host "Aggregate Application API validation passed: $moveCount verified move(s), $($state.AcceptedMoves.Count) diagnostic exception(s)."
    }
    catch {
        $state.Status = 'Failed'
        $state.Failure = $_.Exception.Message
        throw
    }
    finally {
        $state | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $statePath -Encoding UTF8
    }
}

<#
.SYNOPSIS
    Fails the workflow if configured migration validation did not complete successfully.
#>
function Assert-ApplicationApiValidationComplete {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $ProjectFolder)

    $root = Join-Path $ProjectFolder '.buildartifacts\ApplicationApiValidation'
    if (-not (Test-Path -LiteralPath $root)) {
        Write-Host 'No aggregate API exceptions were configured for this compilation.'
        return
    }
    $state = Get-Content -LiteralPath (Join-Path $root 'state.json') -Raw | ConvertFrom-Json
    if ($state.Status -ne 'Passed') { throw "Mandatory aggregate Application API validation did not pass: $($state.Status)." }
}

Export-ModuleMember -Function Initialize-ApplicationApiValidation, Complete-ApplicationApiValidation, Assert-ApplicationApiValidationComplete, Test-ApplicationApiMoves
