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
    AS0018 = "^Procedure '.+' has been removed in '(?<kind>\w+) (?<name>.+)'\. A procedure that belongs to the public API must not be removed as it will break dependent extensions calling this procedure\.$"
    AS0031 = "^The (?<memberKind>action(?: group)?) with name '(?<member>.+)' defined in (?<kind>Page|PageExtension) '(?<name>.+)' was found in the previous version, but is missing in the current extension\.(?: This will break dependent extensions\.)?$"
    AS0032 = "^The (?<memberKind>field|part) with name '(?<member>.+)' defined in (?<kind>Page|PageExtension) '(?<name>.+)' was found in the previous version, but is missing in the current extension\.(?: This will break dependent extensions\.)?$"
    AS0106 = "^The variable '.+' of type '.+' defined in (?<kind>Page|PageExtension) '(?<name>.+)' was found in the previous version, but is missing in the current extension\. This will break dependent extensions\.$"
}
$script:DeferredRules = @($script:RemovalRules.Keys) + @($script:MemberRules.Keys)

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
        name = 'Defer object and page-member removals until aggregate Application reconciliation'
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
            $actionName = ''
            $actionKind = ''
            if (-not $lineMatches.ContainsKey($signature) -or $issue.properties.severity -ne 'Warning') {
                throw "Unsupported deferred diagnostic in '$structuredPath': $signature"
            }
            if ($script:MemberRules.ContainsKey($issue.ruleId)) {
                if ($issue.shortMessage -cnotmatch $script:MemberRules[$issue.ruleId]) {
                    throw "Unsupported member-removal diagnostic: $signature"
                }
                $parentKey = "$($Matches.kind):$($Matches.name)"
                if (-not $wholeObjects.ContainsKey($parentKey) -and $Matches.kind -eq 'Page') {
                    if ($issue.ruleId -eq 'AS0032' -and $Matches.memberKind -eq 'part') {
                        $partName = $Matches.member
                    }
                    elseif ($issue.ruleId -eq 'AS0031') {
                        $actionName = $Matches.member
                        $actionKind = if ($Matches.memberKind -eq 'action group') { 'ActionGroup' } else { 'Action' }
                    }
                    if ($partName -or $actionName) {
                        $parent = @{ Key = "Pages:Name:$($Matches.name)"; Kind = 'Pages'; Named = $true; Name = $Matches.name }
                    }
                }
            }
            else {
                $parentKey = $wholeObjectParents[$signature]
            }
            if (-not $partName -and -not $actionName -and -not $wholeObjects.ContainsKey($parentKey)) {
                throw "$signature is not part of a whole-object move; the original compatibility check remains enforced."
            }
            if (-not $partName -and -not $actionName) { $parent = $wholeObjects[$parentKey] }
            $diagnostics.Add([PSCustomObject]@{
                RuleId = $issue.ruleId
                Key = $parent.Key
                Kind = $parent.Kind
                Named = $parent.Named
                Name = $parent.Name
                PartName = $partName
                ActionName = $actionName
                ActionKind = $actionKind
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

function Get-ApplicationApiPageMemberMoveFailure {
    param(
        [hashtable] $Baseline,
        [hashtable] $Current,
        [object] $OldHost,
        [object] $NewHost,
        [object] $Diagnostic
    )

    if ($OldHost.OwnerId -ne $NewHost.OwnerId -or $OldHost.Name -cne $NewHost.Name -or $OldHost.Namespace -cne $NewHost.Namespace) {
        return 'The original host page identity or ownership changed.'
    }
    $memberName = if ($Diagnostic.PartName) { $Diagnostic.PartName } else { $Diagnostic.ActionName }
    $memberKind = if ($Diagnostic.PartName) { 'Part' } else { $Diagnostic.ActionKind }
    $collection = if ($Diagnostic.PartName) { 'PageParts' } else { 'PageActions' }
    $oldMembers = @($Baseline[$collection] | Where-Object { $_.OwnerKey -ceq $OldHost.Key -and $_.Name -ceq $memberName })
    if ($oldMembers.Count -ne 1 -or $oldMembers[0].MemberKind -cne $memberKind) {
        return 'The diagnostic does not identify a unique baseline page member of the same kind.'
    }
    $pages = @($Current.Symbols.Values | Where-Object Kind -CEQ 'Pages')
    $newMembers = [System.Collections.Generic.List[object]]::new()
    foreach ($member in $Current[$collection] | Where-Object Name -CEQ $memberName) {
        $hosts = @(
            foreach ($page in $pages) {
                $quotedName = '"' + $page.Name.Replace('"', '""') + '"'
                $references = @([string]$page.Id, $page.Name, $quotedName)
                if ($page.Namespace) { $references += "$($page.Namespace).$($page.Name)", "$($page.Namespace).$quotedName" }
                if ($member.PageReference -cin $references) { $page }
            }
        )
        if (@($hosts | Where-Object Key -CEQ $OldHost.Key).Count -eq 0) { continue }
        if ($hosts.Count -ne 1) { return 'A candidate member has an ambiguous host-page reference.' }
        $newMembers.Add($member)
    }
    if ($newMembers.Count -ne 1) { return 'The member is missing or ambiguous on the original host page.' }
    $old = $oldMembers[0]
    $new = $newMembers[0]
    if ($new.MemberKind -cne $memberKind -or $new.OwnerId -eq $old.OwnerId -or $new.OwnerKey -cnotlike 'PageExtensions:*') {
        return 'The member has not moved to a page extension in another exposed Application member.'
    }
    if ($old.ContractHash -cne $new.ContractHash) { return 'The relocated member contract changed.' }
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

<#
.SYNOPSIS
    Checks object and page-member removals against the same published baseline used by AppSourceCop.
#>
function Test-ApplicationApiMoves {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)] [hashtable] $Baseline,
        [Parameter(Mandatory)] [hashtable] $Current,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]] $Diagnostics
    )

    if ($Baseline.Application.Id -ne $Current.Application.Id -or $Baseline.Application.Publisher -cne $Current.Application.Publisher) {
        throw 'Application identity changed.'
    }
    foreach ($diagnostic in $Diagnostics) {
        $origin = $diagnostic.Origin
        $candidates = @(
            if ($diagnostic.Named) {
                $Baseline.Symbols.Values | Where-Object { $_.Kind -ceq $diagnostic.Kind -and $_.Name -ceq $diagnostic.Name -and $_.OwnerId -eq $origin.Id }
            }
            elseif ($Baseline.Symbols.ContainsKey($diagnostic.Key)) { $Baseline.Symbols[$diagnostic.Key] }
        )
        $old = if ($candidates.Count -eq 1) { $candidates[0] } else { $null }
        $key = if ($old) { $old.Key } else { $diagnostic.Key }
        $new = $Current.Symbols[$key]
        $reason = ''
        if ($candidates.Count -gt 1) { $reason = 'The diagnostic does not identify an unambiguous object namespace.' }
        elseif (-not $old -or -not $new) { $reason = 'Object is missing, internal, or outside the exposed Application API.' }
        elseif ($old.OwnerId -ne $origin.Id -or $old.Name -cne $diagnostic.Name) { $reason = 'Diagnostic does not identify the baseline owner/object.' }
        elseif (-not $Current.Packages.ContainsKey($origin.Id)) { $reason = 'The source app is no longer an exposed Application member.' }
        elseif ($Baseline.Packages[$origin.Id].Version -ne [version]$origin.BaselineVersion -or
            $Baseline.Packages[$origin.Id].Name -cne $origin.BaselineName -or
            $Baseline.Packages[$origin.Id].Publisher -cne $origin.BaselinePublisher) { $reason = 'AppSourceCop and aggregate baselines disagree.' }
        elseif ($diagnostic.PartName -or $diagnostic.ActionName) {
            $reason = Get-ApplicationApiPageMemberMoveFailure -Baseline $Baseline -Current $Current -OldHost $old -NewHost $new -Diagnostic $diagnostic
        }
        elseif ($old.OwnerId -eq $new.OwnerId) { $reason = 'Object has not moved to another Application member.' }
        elseif ($old.Name -cne $new.Name -or $old.Namespace -cne $new.Namespace -or $old.ContractHash -cne $new.ContractHash) {
            $reason = 'Moved object contract changed; automatic migration exception is unsafe.'
        }
        [PSCustomObject]@{
            RuleId = $diagnostic.RuleId
            Key = $key
            Name = $diagnostic.Name
            PartName = $diagnostic.PartName
            ActionName = $diagnostic.ActionName
            ActionKind = $diagnostic.ActionKind
            Accepted = -not $reason
            Reason = $reason
            Baseline = $old
            Current = $new
            Diagnostic = $diagnostic.Message
        }
    }
}

function Get-ApplicationApiGateSnapshot {
    param([string[]] $Paths, [string[]] $Keys, [string[]] $PartNames = @(), [string[]] $ActionNames = @())

    $roots = @($Paths | ForEach-Object { Get-ApplicationApiPackageInfo -Path $_ } |
        Where-Object { $_.Id -eq 'c1335042-3002-4257-bf8a-75c898ccb1b8' -and $_.Name -ceq 'Application' })
    if ($roots.Count -ne 1) { throw "Expected one compiled Application facade; found $($roots.Count)." }
    Get-ApplicationApiSnapshot -ApplicationPackagePath $roots[0].Path -DependencyPackagePaths $Paths -SymbolKeys $Keys `
        -PartNames $PartNames -ActionNames $ActionNames
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
            $baseline = Get-ApplicationApiGateSnapshot -Paths $baselinePaths -Keys $keys -PartNames $partNames -ActionNames $actionNames
            $current = Get-ApplicationApiGateSnapshot -Paths $currentPaths -Keys $keys -PartNames $partNames -ActionNames $actionNames
            $state.AcceptedMoves = @(Test-ApplicationApiMoves -Baseline $baseline -Current $current -Diagnostics $records.Diagnostics)
            $rejected = @($state.AcceptedMoves | Where-Object { -not $_.Accepted })
            if ($rejected.Count -gt 0) {
                foreach ($issue in $rejected) { Write-Host "::error::$($issue.RuleId) $($issue.Name): $($issue.Reason)" }
                throw "$($rejected.Count) removal(s) were not verified as ownership-only Application moves."
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
                    $log.Lines[$diagnostic.Line] = "[OUT] info BCAPPAPI: Verified ownership-only Application move ($($diagnostic.RuleId)): $($diagnostic.Name)."
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
