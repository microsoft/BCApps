Describe 'Application API compatibility prototype' {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\ApplicationApiCompatibility.psm1" -Force

        function New-ApiTestPackage {
            param(
                [string] $Name,
                [string] $Id,
                [string] $Version = '2.0.0.0',
                [string] $Publisher = 'Microsoft',
                [object[]] $Dependencies = @(),
                [hashtable] $Collections = @{},
                [bool] $Propagate = $false,
                [string] $Path = (Join-Path $TestDrive "$([guid]::NewGuid()).app")
            )

            $manifest = [xml]'<Package xmlns="http://schemas.microsoft.com/navx/2015/manifest"><App/><Dependencies/></Package>'
            $app = $manifest.DocumentElement.FirstChild
            foreach ($attribute in @{ Id = $Id; Name = $Name; Publisher = $Publisher; Version = $Version; PropagateDependencies = [string]$Propagate }.GetEnumerator()) {
                $app.SetAttribute($attribute.Key, $attribute.Value)
            }
            foreach ($dependency in $Dependencies) {
                $element = $manifest.CreateElement('Dependency', $manifest.DocumentElement.NamespaceURI)
                foreach ($attribute in @{ Id = $dependency.Id; Name = $dependency.Name; Publisher = $dependency.Publisher; MinVersion = $dependency.Version }.GetEnumerator()) {
                    $element.SetAttribute($attribute.Key, $attribute.Value)
                }
                $null = $manifest.DocumentElement.LastChild.AppendChild($element)
            }
            $symbols = @{ AppId = $Id; Name = $Name; Publisher = $Publisher; Version = $Version }
            foreach ($key in $Collections.Keys) { $symbols[$key] = $Collections[$key] }
            $buffer = [System.IO.MemoryStream]::new()
            $zip = [System.IO.Compression.ZipArchive]::new($buffer, [System.IO.Compression.ZipArchiveMode]::Create, $true)
            try {
                foreach ($entry in @{ 'NavxManifest.xml' = $manifest.OuterXml; 'SymbolReference.json' = ($symbols | ConvertTo-Json -Depth 100 -Compress) }.GetEnumerator()) {
                    $writer = [System.IO.StreamWriter]::new($zip.CreateEntry($entry.Key).Open())
                    try { $writer.Write($entry.Value) } finally { $writer.Dispose() }
                }
            }
            finally {
                $zip.Dispose()
            }
            $output = [System.IO.File]::Create($Path)
            try {
                $header = [byte[]]::new(40)
                [System.Text.Encoding]::ASCII.GetBytes('NAVX').CopyTo($header, 0)
                $output.Write($header, 0, $header.Length)
                $buffer.Position = 0
                $buffer.CopyTo($output)
            }
            finally {
                $output.Dispose()
                $buffer.Dispose()
            }
            [PSCustomObject]@{ Path = $Path; Id = $Id; Name = $Name; Publisher = $Publisher; Version = $Version }
        }

        function Write-ApiDestination {
            param(
                [object[]] $Pages = @($page),
                [string] $Namespace = 'Microsoft.Intercompany.DataExchange',
                [hashtable] $ExtraCollections = @{}
            )
            $collections = @{ Namespaces = @(@{ Name = $Namespace; Pages = $Pages }) }
            foreach ($key in $ExtraCollections.Keys) { $collections[$key] = $ExtraCollections[$key] }
            $null = New-ApiTestPackage -Name 'Intercompany' -Id $destination.Id -Path $destination.Path -Collections $collections
        }

        function Get-ApiCurrentSnapshot {
            Get-ApplicationApiSnapshot -ApplicationPackagePath $script:currentApplication.Path -DependencyPackagePaths @($script:currentBase.Path, $destination.Path)
        }

        function New-ApiGateLayout {
            param(
                [string] $RuleId = 'AS0029',
                [string] $Kind = 'Page',
                [int] $Id = 621,
                [string] $Name = 'IC API Log Entries',
                [string[]] $CacheDependencies = @()
            )

            $project = Join-Path $TestDrive ([guid]::NewGuid().ToString())
            $output = Join-Path $project '.buildartifacts\Apps'
            $cache = Join-Path $project 'cache'
            $null = New-Item -Path $output, $cache, (Join-Path $project '.AL-Go') -ItemType Directory -Force
            Copy-Item -LiteralPath "$PSScriptRoot\..\ALGoPostCompileApp.ps1" -Destination (Join-Path $project '.AL-Go\PostCompileApp.ps1')
            Copy-Item -LiteralPath $oldBase.Path, $oldApplication.Path -Destination $cache
            foreach ($path in $CacheDependencies) { Copy-Item -LiteralPath $path -Destination $cache }
            $folders = @(
                foreach ($package in @($script:currentBase, $destination, $script:currentApplication)) {
                    $path = Join-Path $project $package.Id
                    $null = New-Item -Path $path -ItemType Directory
                    @{ id = $package.Id; name = $package.Name; version = $package.Version; publisher = $package.Publisher } |
                        ConvertTo-Json | Set-Content -LiteralPath (Join-Path $path 'app.json')
                    @{ name = $package.Name; publisher = $package.Publisher; version = '1.0.0.0' } |
                        ConvertTo-Json | Set-Content -LiteralPath (Join-Path $path 'AppSourceCop.json')
                    @{ path = $path }
                }
            )
            $workspace = Join-Path $project 'workspace.code-workspace'
            @{ folders = $folders } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $workspace
            $ruleset = Join-Path $project 'original.ruleset.json'
            '{"name":"Original checks","generalAction":"Error","rules":[{"id":"AS0002","action":"Error"}]}' | Set-Content -LiteralPath $ruleset
            $parameters = @{ WorkspaceFile = $workspace; OutFolder = $output; PackageCachePath = $cache; Ruleset = $ruleset; ErrorLogDirectory = (Join-Path $project 'alerts') }
            Initialize-ApplicationApiValidation -CompilationParameters $parameters -CountryCode 'W1' -BuildMode Clean
            $compiled = @(
                foreach ($package in @($script:currentBase, $destination, $script:currentApplication)) {
                    Copy-Item -LiteralPath $package.Path -Destination $output
                    (Join-Path $output (Split-Path $package.Path -Leaf))
                }
            )
            $validation = Join-Path $project '.buildartifacts\ApplicationApiValidation'
            $sourceLog = ''
            foreach ($folder in $folders) {
                $app = Get-Content -LiteralPath (Join-Path $folder.path 'app.json') -Raw | ConvertFrom-Json
                $log = Join-Path $parameters.LogDirectory "$($app.name)_20261027_000000.log"
                $lines = @("Project: $($app.name)", "Path: $($folder.path)")
                $issues = @()
                if ($app.id -eq $baseId) {
                    $sourceLog = $log
                    $message = switch ($RuleId) {
                        AS0065 { "Interface '$Name' has been deleted." }
                        AS0089 { "The '$Kind' with name '$Name' was found in the previous version, but is missing in the current extension. This will break dependent extensions." }
                        default { "The '$Kind' with ID '$Id' and name '$Name' was found in the previous version, but is missing in the current extension. This will break dependent extensions." }
                    }
                    $lines += "[OUT] warning ${RuleId}: $message"
                    $lines += '[OUT] app.json(1,1): warning AA0021: ordinary warning stays visible'
                    $issues = @(
                        @{ ruleId = $RuleId; shortMessage = $message; properties = @{ severity = 'Warning' } },
                        @{ ruleId = 'AA0021'; shortMessage = 'ordinary warning stays visible'; properties = @{ severity = 'Warning' } }
                    )
                }
                $lines | Set-Content -LiteralPath $log
                @{ version = '0.2'; issues = $issues } | ConvertTo-Json -Depth 10 |
                    Set-Content -LiteralPath (Join-Path $parameters.ErrorLogDirectory "$($app.name)_20261027_000000.errorLog.json")
            }
            [PSCustomObject]@{ Project = $project; Parameters = $parameters; Compiled = $compiled; Root = $validation; SourceLog = $sourceLog }
        }

        function Add-ApiMemberDiagnostic {
            param([object] $Gate, [string] $RuleId, [string] $Message)

            "[OUT] warning ${RuleId}: $Message" | Add-Content -LiteralPath $Gate.SourceLog
            $path = Join-Path $Gate.Parameters.ErrorLogDirectory 'Base Application_20261027_000000.errorLog.json'
            $data = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -AsHashtable
            $data.issues += @{ ruleId = $RuleId; shortMessage = $Message; properties = @{ severity = 'Warning' } }
            $data | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $path
        }
    }

    BeforeEach {
        $applicationId = 'c1335042-3002-4257-bf8a-75c898ccb1b8'
        $baseId = '437dbf0e-84ff-417a-965d-ed2bb9650972'
        $destinationId = '74676280-1b87-43cc-8ca2-3b2b17a5b81d'
        $page = @{
            Id = 621
            Name = 'IC API Log Entries'
            ReferenceSourceFileName = 'old\ICAPILogEntries.Page.al'
            Methods = @(@{
                Name = 'Process'
                Parameters = @(@{ Name = 'Value'; TypeDefinition = @{ Name = 'Text' } })
            })
        }
        $oldBase = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Version '1.0.0.0' -Collections @{
            Namespaces = @(@{ Name = 'Microsoft'; Namespaces = @(@{ Name = 'Intercompany'; Namespaces = @(@{ Name = 'DataExchange'; Pages = @($page) }) }) })
        }
        $oldApplication = New-ApiTestPackage -Name 'Application' -Id $applicationId -Version '1.0.0.0' -Propagate $true -Dependencies @($oldBase)
        $script:baseline = Get-ApplicationApiSnapshot -ApplicationPackagePath $oldApplication.Path -DependencyPackagePaths @($oldBase.Path)
        $script:currentBase = New-ApiTestPackage -Name 'Base Application' -Id $baseId
        $destination = New-ApiTestPackage -Name 'Intercompany' -Id $destinationId
        $script:currentApplication = New-ApiTestPackage -Name 'Application' -Id $applicationId -Propagate $true -Dependencies @($script:currentBase, $destination)
        $page.ReferenceSourceFileName = 'new\ICAPILogEntries.Page.al'
        Write-ApiDestination
    }

    It 'recognizes an ownership-only move across differently shaped namespace trees' {
        $result = Compare-ApplicationApiSnapshot -Baseline $script:baseline -Current (Get-ApiCurrentSnapshot)
        $result.Verdict | Should -Be 'Unchanged'
        $result.UnchangedMoves.Count | Should -Be 1
        $result.UnchangedMoves[0].Symbol.OwnerId | Should -Be $baseId
        $result.UnchangedMoves[0].Current.OwnerId | Should -Be $destinationId
    }

    It 'ignores JSON property order when comparing an otherwise unchanged contract' {
        $reordered = [ordered]@{}
        $keys = @($page.Keys)
        [array]::Reverse($keys)
        foreach ($key in $keys) { $reordered[$key] = $page[$key] }
        Write-ApiDestination -Pages @($reordered)
        (Compare-ApplicationApiSnapshot -Baseline $script:baseline -Current (Get-ApiCurrentSnapshot)).Verdict | Should -Be 'Unchanged'
    }

    It 'rejects a genuinely deleted object rather than passing an empty facade comparison' {
        Write-ApiDestination -Pages @()
        $result = Compare-ApplicationApiSnapshot -Baseline $script:baseline -Current (Get-ApiCurrentSnapshot)
        $result.Verdict | Should -Be 'Breaking'
        $result.BreakingChanges[0].Symbol.Id | Should -Be 621
    }

    It 'rejects a changed object <Attribute>' -TestCases @(
        @{ Attribute = 'Id'; Value = 622 },
        @{ Attribute = 'Name'; Value = 'Renamed IC API Log Entries' }
    ) {
        param($Attribute, $Value)
        $page[$Attribute] = $Value
        Write-ApiDestination
        (Compare-ApplicationApiSnapshot -Baseline $script:baseline -Current (Get-ApiCurrentSnapshot)).Verdict | Should -Be 'Breaking'
    }

    It 'rejects a changed namespace' {
        Write-ApiDestination -Namespace 'Microsoft.Other'
        (Compare-ApplicationApiSnapshot -Baseline $script:baseline -Current (Get-ApiCurrentSnapshot)).Verdict | Should -Be 'Breaking'
    }

    It 'requires review of changed method signatures instead of approving the move' {
        $page.Methods[0].Parameters[0].TypeDefinition.Name = 'Integer'
        Write-ApiDestination
        $result = Compare-ApplicationApiSnapshot -Baseline $script:baseline -Current (Get-ApiCurrentSnapshot)
        $result.Verdict | Should -Be 'ReviewRequired'
        $result.ReviewRequired.Count | Should -Be 1
        $result.UnchangedMoves.Count | Should -Be 0
    }

    It 'rejects an object whose access becomes internal' {
        $page.Properties = @(@{ Name = 'Access'; Value = 'Internal' })
        Write-ApiDestination
        (Compare-ApplicationApiSnapshot -Baseline $script:baseline -Current (Get-ApiCurrentSnapshot)).Verdict | Should -Be 'Breaking'
    }

    It 'does not expose an app merely because its package is available' {
        $script:currentApplication = New-ApiTestPackage -Name 'Application' -Id $applicationId -Propagate $true -Dependencies @($script:currentBase)
        (Compare-ApplicationApiSnapshot -Baseline $script:baseline -Current (Get-ApiCurrentSnapshot)).Verdict | Should -Be 'Breaking'
    }

    It 'follows a transitive dependency only when its parent propagates dependencies' {
        $script:currentBase = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Dependencies @($destination)
        $script:currentApplication = New-ApiTestPackage -Name 'Application' -Id $applicationId -Propagate $true -Dependencies @($script:currentBase)
        (Compare-ApplicationApiSnapshot -Baseline $script:baseline -Current (Get-ApiCurrentSnapshot)).Verdict | Should -Be 'Breaking'
        $script:currentBase = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Dependencies @($destination) -Propagate $true
        (Compare-ApplicationApiSnapshot -Baseline $script:baseline -Current (Get-ApiCurrentSnapshot)).Verdict | Should -Be 'Unchanged'
    }

    It 'fails explicitly when an exposed dependency is missing' {
        { Get-ApplicationApiSnapshot -ApplicationPackagePath $script:currentApplication.Path -DependencyPackagePaths @($script:currentBase.Path) } |
            Should -Throw '*Intercompany*found 0*'
    }

    It 'does not substitute an incompatible dependency <Attribute>' -TestCases @(
        @{ Attribute = 'Version'; Value = '1.0.0.0' },
        @{ Attribute = 'Publisher'; Value = 'Other Publisher' }
    ) {
        param($Attribute, $Value)
        $options = @{ Name = 'Intercompany'; Id = $destinationId; Path = $destination.Path }
        $options[$Attribute] = $Value
        $null = New-ApiTestPackage @options
        { Get-ApiCurrentSnapshot } | Should -Throw '*Intercompany*found 0*'
    }

    It 'rejects ambiguous dependency versions instead of selecting an arbitrary package' {
        $other = New-ApiTestPackage -Name 'Intercompany' -Id $destinationId -Version '3.0.0.0'
        { Get-ApplicationApiSnapshot -ApplicationPackagePath $script:currentApplication.Path -DependencyPackagePaths @($script:currentBase.Path, $destination.Path, $other.Path) } |
            Should -Throw '*Intercompany*found 2*'
    }

    It 'rejects duplicate exposed object identities across apps' {
        $script:currentBase = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Collections @{ Pages = @($page) }
        { Get-ApiCurrentSnapshot } | Should -Throw '*Ambiguous exposed symbol*'
    }

    It 'keeps table and field ownership outside the non-table comparison' {
        Write-ApiDestination -ExtraCollections @{ Tables = @(@{ Id = 621; Name = 'Schema requires AppSourceCop'; Fields = @(@{ Id = 1; Name = 'Moved field' }) }) }
        $snapshot = Get-ApiCurrentSnapshot
        $snapshot.SchemaObjects.Count | Should -Be 1
        $snapshot.Symbols.Count | Should -Be 1
        (Compare-ApplicationApiSnapshot -Baseline $script:baseline -Current $snapshot).SchemaValidationRequired | Should -BeTrue
    }

    It 'reports unknown symbol collections as requiring review' {
        Write-ApiDestination -ExtraCollections @{ FutureObjects = @(@{ Id = 1; Name = 'Unknown contract' }) }
        $result = Compare-ApplicationApiSnapshot -Baseline $script:baseline -Current (Get-ApiCurrentSnapshot)
        $result.Verdict | Should -Be 'ReviewRequired'
        $result.ReviewRequired[0].Reason | Should -Match 'FutureObjects'
    }

    It 'rejects an unsupported package envelope' {
        [System.IO.File]::WriteAllText($destination.Path, 'not a NAVX package')
        { Get-ApiCurrentSnapshot } | Should -Throw '*Unsupported package envelope*'
    }

    Context 'Pipeline reconciliation' {
        BeforeAll {
            Import-Module "$PSScriptRoot\..\ApplicationApiValidation.psm1" -Force
        }

        It 'reconciles an unchanged move before the warning gate, retaining ordinary warnings and raw evidence' {
            $gate = New-ApiGateLayout
            Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled
            { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Not -Throw
            $state = Get-Content -LiteralPath (Join-Path $gate.Root 'state.json') -Raw | ConvertFrom-Json
            $state.Status | Should -Be 'Passed'
            $state.AcceptedMoves.Count | Should -Be 1
            $text = Get-Content -LiteralPath $gate.SourceLog -Raw
            $text | Should -Match 'info BCAPPAPI'
            $text | Should -Not -Match 'warning AS0029'
            $text | Should -Match 'warning AA0021'
            Get-Content -LiteralPath (Join-Path $gate.Root "Originals\$([System.IO.Path]::GetFileName($gate.SourceLog)).txt") -Raw |
                Should -Match 'warning AS0029'
            $alerts = Get-Content -LiteralPath (Join-Path $gate.Project 'alerts\Base Application_20261027_000000.errorLog.json') -Raw | ConvertFrom-Json
            @($alerts.issues).Count | Should -Be 1
            $alerts.issues[0].ruleId | Should -Be 'AA0021'
        }

        It 'rejects deletion without removing its original warning from build logs' {
            Write-ApiDestination -Pages @()
            $gate = New-ApiGateLayout
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Throw '*not verified*'
            Get-Content -LiteralPath $gate.SourceLog -Raw | Should -Match 'warning AS0029'
            { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Throw '*Failed*'
        }

        It 'reconciles an unchanged <Kind> move using its symbol collection' -TestCases @(
            @{ Kind = 'PageExtension'; Collection = 'PageExtensions'; RuleId = 'AS0029' },
            @{ Kind = 'Report'; Collection = 'Reports'; RuleId = 'AS0088' },
            @{ Kind = 'ReportExtension'; Collection = 'ReportExtensions'; RuleId = 'AS0088' },
            @{ Kind = 'XmlPort'; Collection = 'XmlPorts'; RuleId = 'AS0088' },
            @{ Kind = 'Query'; Collection = 'Queries'; RuleId = 'AS0088' },
            @{ Kind = 'Enum'; Collection = 'EnumTypes'; RuleId = 'AS0088' },
            @{ Kind = 'EnumExtension'; Collection = 'EnumExtensionTypes'; RuleId = 'AS0088' },
            @{ Kind = 'PermissionSet'; Collection = 'PermissionSets'; RuleId = 'AS0088' },
            @{ Kind = 'PermissionSetExtension'; Collection = 'PermissionSetExtensions'; RuleId = 'AS0088' }
        ) {
            param($Kind, $Collection, $RuleId)
            $symbol = @{ Id = 511; Name = 'Complete IC Inbox Action' }
            $collections = @{ Namespaces = @(@{ Name = 'Microsoft.Intercompany.Inbox'; $Collection = @($symbol) }) }
            $null = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Version '1.0.0.0' -Path $oldBase.Path -Collections $collections
            $null = New-ApiTestPackage -Name 'Intercompany' -Id $destinationId -Path $destination.Path -Collections $collections
            $gate = New-ApiGateLayout -RuleId $RuleId -Kind $Kind -Id $symbol.Id -Name $symbol.Name
            Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled
            { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Not -Throw
            $state = Get-Content -LiteralPath (Join-Path $gate.Root 'state.json') -Raw | ConvertFrom-Json
            $state.AcceptedMoves.Count | Should -Be 1
            $state.AcceptedMoves[0].Key | Should -Be "${Collection}:511"
            $state.AcceptedMoves[0].Accepted | Should -BeTrue
            Get-Content -LiteralPath $gate.SourceLog -Raw | Should -Not -Match "warning ${RuleId}:"
        }

        It 'reconciles an unchanged named <Kind> move including regenerated ownership metadata' -TestCases @(
            @{ Kind = 'Interface'; Collection = 'Interfaces'; RuleId = 'AS0065' },
            @{ Kind = 'ControlAddIn'; Collection = 'ControlAddIns'; RuleId = 'AS0089' },
            @{ Kind = 'Profile'; Collection = 'Profiles'; RuleId = 'AS0089' },
            @{ Kind = 'ProfileExtension'; Collection = 'ProfileExtensions'; RuleId = 'AS0089' },
            @{ Kind = 'PageCustomization'; Collection = 'PageCustomizations'; RuleId = 'AS0089' }
        ) {
            param($Kind, $Collection, $RuleId)
            $symbol = @{ Name = 'Moved named object'; Methods = @(@{ Name = 'Process'; Id = 123 }) }
            if ($Kind -eq 'Interface') { $symbol.Id = 111 }
            if ($Kind -eq 'ControlAddIn') { $symbol.PublicKeyToken = 'source-token' }
            if ($Kind -eq 'PageCustomization') { $symbol.Id = 0 }
            $collections = @{ Namespaces = @(@{ Name = 'Migration.Probe'; $Collection = @($symbol) }) }
            $null = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Version '1.0.0.0' -Path $oldBase.Path -Collections $collections
            if ($Kind -eq 'Interface') { $symbol.Id = 222 }
            if ($Kind -eq 'ControlAddIn') { $symbol.PublicKeyToken = 'destination-token' }
            $null = New-ApiTestPackage -Name 'Intercompany' -Id $destinationId -Path $destination.Path -Collections $collections
            $gate = New-ApiGateLayout -RuleId $RuleId -Kind $Kind -Name $symbol.Name
            if ($Kind -in @('Interface', 'ControlAddIn')) {
                Add-ApiMemberDiagnostic -Gate $gate -RuleId AS0018 -Message "Procedure 'Process()' has been removed in '$Kind Moved named object'. A procedure that belongs to the public API must not be removed as it will break dependent extensions calling this procedure."
            }
            Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled
            { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Not -Throw
            $state = Get-Content -LiteralPath (Join-Path $gate.Root 'state.json') -Raw | ConvertFrom-Json
            $state.AcceptedMoves[0].Key | Should -Be "${Collection}:Migration.Probe:Moved named object"
            @($state.AcceptedMoves | Where-Object { -not $_.Accepted }).Count | Should -Be 0
        }

        It 'rejects a named move when its identity or contract is <Failure>' -TestCases @(
            @{ Failure = 'deleted' },
            @{ Failure = 'changed' },
            @{ Failure = 'renamed' },
            @{ Failure = 'in another namespace' },
            @{ Failure = 'ambiguous' }
        ) {
            param($Failure)
            $symbol = @{ Name = 'Moved interface'; Id = 111; Methods = @(@{ Name = 'Process'; Id = 123 }) }
            $collections = @{ Namespaces = @(@{ Name = 'Migration.Probe'; Interfaces = @($symbol) }) }
            if ($Failure -eq 'ambiguous') {
                $collections.Namespaces += @{ Name = 'Migration.Other'; Interfaces = @($symbol) }
            }
            $null = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Version '1.0.0.0' -Path $oldBase.Path -Collections $collections
            switch ($Failure) {
                deleted { $collections.Namespaces[0].Interfaces = @() }
                changed { $symbol.Methods[0].Id = 456 }
                renamed { $symbol.Name = 'Renamed interface' }
                'in another namespace' { $collections.Namespaces[0].Name = 'Migration.Other' }
            }
            $symbol.Id = 222
            $null = New-ApiTestPackage -Name 'Intercompany' -Id $destinationId -Path $destination.Path -Collections $collections
            $gate = New-ApiGateLayout -RuleId AS0065 -Kind Interface -Name 'Moved interface'
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Throw '*not verified*'
            { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Throw '*Failed*'
            Get-Content -LiteralPath $gate.SourceLog -Raw | Should -Match 'warning AS0065'
        }

        It 'keeps multiple page customizations with compiler-assigned ID zero distinct' {
            $symbols = @(@{ Id = 0; Name = 'First customization' }, @{ Id = 0; Name = 'Second customization' })
            $collections = @{ Namespaces = @(@{ Name = 'Migration.Probe'; PageCustomizations = $symbols }) }
            $null = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Version '1.0.0.0' -Path $oldBase.Path -Collections $collections
            $null = New-ApiTestPackage -Name 'Intercompany' -Id $destinationId -Path $destination.Path -Collections $collections
            $gate = New-ApiGateLayout -RuleId AS0089 -Kind PageCustomization -Name $symbols[0].Name
            Add-ApiMemberDiagnostic -Gate $gate -RuleId AS0089 -Message "The 'PageCustomization' with name '$($symbols[1].Name)' was found in the previous version, but is missing in the current extension. This will break dependent extensions."
            Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled
            $state = Get-Content -LiteralPath (Join-Path $gate.Root 'state.json') -Raw | ConvertFrom-Json
            $state.AcceptedMoves.Count | Should -Be 2
            @($state.AcceptedMoves | Where-Object { -not $_.Accepted }).Count | Should -Be 0
        }

        It 'rejects a report move when the report is <Failure>' -TestCases @(
            @{ Failure = 'deleted' },
            @{ Failure = 'changed' }
        ) {
            param($Failure)
            $symbol = @{ Id = 511; Name = 'Complete IC Inbox Action'; Properties = @(@{ Name = 'ProcessingOnly'; Value = 'true' }) }
            $collections = @{ Reports = @($symbol) }
            $null = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Version '1.0.0.0' -Path $oldBase.Path -Collections $collections
            if ($Failure -eq 'deleted') { $collections.Reports = @() }
            else { $symbol.Properties[0].Value = 'false' }
            $null = New-ApiTestPackage -Name 'Intercompany' -Id $destinationId -Path $destination.Path -Collections $collections
            $gate = New-ApiGateLayout -RuleId AS0088 -Kind Report -Id $symbol.Id -Name $symbol.Name
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Throw '*not verified*'
            { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Throw '*Failed*'
            Get-Content -LiteralPath $gate.SourceLog -Raw | Should -Match 'warning AS0088'
        }

        It 'does not defer unsupported <Kind> removals under <RuleId>' -TestCases @(
            @{ Kind = 'Table'; RuleId = 'AS0029' },
            @{ Kind = 'TableExtension'; RuleId = 'AS0029' },
            @{ Kind = 'Table'; RuleId = 'AS0088' },
            @{ Kind = 'TableExtension'; RuleId = 'AS0088' },
            @{ Kind = 'FutureObject'; RuleId = 'AS0029' },
            @{ Kind = 'Report'; RuleId = 'AS0029' }
        ) {
            param($Kind, $RuleId)
            $gate = New-ApiGateLayout -Kind $Kind -RuleId $RuleId
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Throw '*Unexpected object type*'
            { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Throw '*Failed*'
            Get-Content -LiteralPath $gate.SourceLog -Raw | Should -Match "warning ${RuleId}:"
        }

        It 'rejects a changed moved contract' {
            $page.Methods[0].Parameters[0].TypeDefinition.Name = 'Integer'
            Write-ApiDestination
            $gate = New-ApiGateLayout
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Throw '*not verified*'
            $state = Get-Content -LiteralPath (Join-Path $gate.Root 'state.json') -Raw | ConvertFrom-Json
            $state.AcceptedMoves[0].Reason | Should -Match 'contract changed'
        }

        It 'rejects a move to an installed but unexposed app' {
            $script:currentApplication = New-ApiTestPackage -Name 'Application' -Id $applicationId -Propagate $true -Dependencies @($script:currentBase)
            $gate = New-ApiGateLayout
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Throw '*not verified*'
        }

        It 'fails when structured diagnostics are missing rather than treating missing output as no removals' {
            $gate = New-ApiGateLayout
            Remove-Item -LiteralPath (Join-Path $gate.Parameters.ErrorLogDirectory 'Base Application_20261027_000000.errorLog.json')
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Throw
            { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Throw '*Failed*'
        }

        It 'fails when the post-compilation hook has not completed' {
            $gate = New-ApiGateLayout
            { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Throw '*Pending*'
        }

        It 'completes normally when the compiler reports no ownership removals' {
            $gate = New-ApiGateLayout
            $text = @(Get-Content -LiteralPath $gate.SourceLog | Where-Object { $_ -notmatch 'warning AS0029' })
            $text | Set-Content -LiteralPath $gate.SourceLog
            $path = Join-Path $gate.Parameters.ErrorLogDirectory 'Base Application_20261027_000000.errorLog.json'
            $data = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -AsHashtable
            $data.issues = @($data.issues | Where-Object { $_.ruleId -ne 'AS0029' })
            $data | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $path
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Not -Throw
            { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Not -Throw
            Get-Content -LiteralPath $gate.SourceLog -Raw | Should -Match 'warning AA0021'
        }

        It 'rejects a diagnostic validated against a different published baseline' {
            $gate = New-ApiGateLayout
            $statePath = Join-Path $gate.Root 'state.json'
            $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -AsHashtable
            $state.Projects[0].BaselineVersion = '9.0.0.0'
            $state | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $statePath
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Throw '*not verified*'
        }

        It 'resolves the shared post hook for root projects and nested country projects alike' {
            $oldFlag = $env:BC_APPLICATION_API_VALIDATION
            $oldWorkspace = $env:GITHUB_WORKSPACE
            try {
                $env:BC_APPLICATION_API_VALIDATION = 'true'
                $env:GITHUB_WORKSPACE = (Get-Item "$PSScriptRoot\..\..\..").FullName
                $emptyProject = Join-Path $TestDrive 'no-deferrals'
                $parameters = @{ OutFolder = (Join-Path $emptyProject '.buildartifacts\Apps') }
                { & "$PSScriptRoot\..\ALGoPostCompileApp.ps1" -appFiles @() -appType app -compilationParams $parameters } | Should -Not -Throw
            }
            finally {
                $env:BC_APPLICATION_API_VALIDATION = $oldFlag
                $env:GITHUB_WORKSPACE = $oldWorkspace
            }
        }

        It 'does not lose an ownership diagnostic when the text and structured logs disagree' {
            $gate = New-ApiGateLayout
            Get-Content -LiteralPath $gate.SourceLog | Where-Object { $_ -notmatch 'warning AS0029' } |
                Set-Content -LiteralPath (Join-Path $gate.Root 'changed.txt')
            Copy-Item -LiteralPath (Join-Path $gate.Root 'changed.txt') -Destination $gate.SourceLog -Force
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Throw '*disagree*'
        }

        It 'accepts procedure-removal diagnostics only when the entire owning codeunit moved unchanged' {
            $null = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Version '1.0.0.0' -Path $oldBase.Path -Collections @{
                Namespaces = @(@{ Name = 'Microsoft.Intercompany.DataExchange'; Codeunits = @($page) })
            }
            $null = New-ApiTestPackage -Name 'Intercompany' -Id $destinationId -Path $destination.Path -Collections @{
                Namespaces = @(@{ Name = 'Microsoft.Intercompany.DataExchange'; Codeunits = @($page) })
            }
            $gate = New-ApiGateLayout -RuleId AS0088 -Kind Codeunit
            Add-ApiMemberDiagnostic -Gate $gate -RuleId AS0018 -Message "Procedure 'Process(Text)' has been removed in 'Codeunit IC API Log Entries'. A procedure that belongs to the public API must not be removed as it will break dependent extensions calling this procedure."
            Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled
            $rules = Get-Content -LiteralPath $gate.Parameters.Ruleset -Raw | ConvertFrom-Json
            @($rules.rules.id) | Should -Not -Contain 'AS0002'
            $state = Get-Content -LiteralPath (Join-Path $gate.Root 'state.json') -Raw | ConvertFrom-Json
            $state.AcceptedMoves[0].RuleId | Should -Be 'AS0088'
            $state.AcceptedMoves[1].RuleId | Should -Be 'AS0018'
            $state.AcceptedMoves[1].Accepted | Should -BeTrue
        }

        It 'recognizes part-removal diagnostics accompanying an unchanged whole-page move' {
            $page.Controls = @(@{ Name = 'Activities'; Kind = 'Part'; TypeDefinition = @{ Name = 'Page'; Subtype = @{ Id = 9071; Name = 'Intercompany Activities' } } })
            $null = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Version '1.0.0.0' -Path $oldBase.Path -Collections @{
                Namespaces = @(@{ Name = 'Microsoft.Intercompany.DataExchange'; Pages = @($page) })
            }
            Write-ApiDestination
            $gate = New-ApiGateLayout
            Add-ApiMemberDiagnostic -Gate $gate -RuleId AS0032 -Message "The part with name 'Activities' defined in Page 'IC API Log Entries' was found in the previous version, but is missing in the current extension."
            Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled
            $state = Get-Content -LiteralPath (Join-Path $gate.Root 'state.json') -Raw | ConvertFrom-Json
            $state.AcceptedMoves.Count | Should -Be 2
            $state.AcceptedMoves[1].Accepted | Should -BeTrue
        }

        Context 'Page parts relocated into Application page extensions' {
            BeforeAll {
                function Write-PartApiPackages {
                    $null = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Version '1.0.0.0' -Path $oldBase.Path -Collections $partOldCollections
                    $null = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Path $script:currentBase.Path -Collections $partCurrentCollections
                    $null = New-ApiTestPackage -Name 'Intercompany' -Id $destinationId -Path $destination.Path -Collections $partDestinationCollections
                }
            }

            BeforeEach {
                $part = @{
                    Name = 'Intercompany Activities'
                    Kind = 'Part'
                    TypeDefinition = @{ Name = 'Page'; Subtype = @{ Id = 9071; Name = 'Intercompany Activities' } }
                    Properties = @(@{ Name = 'ApplicationArea'; Value = 'Intercompany' })
                }
                $newPart = $part | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
                $oldHost = @{
                    Id = 9027
                    Name = 'Accountant Role Center'
                    Controls = @(@{ Name = 'rolecenter'; Kind = 'Area'; Controls = @($part) })
                }
                $currentHost = $oldHost | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
                $currentHost.Controls[0].Controls = @()
                $oldTarget = @{
                    Id = 9071
                    Name = 'Intercompany Activities'
                    Properties = @(@{ Name = 'PageType'; Value = 'CardPart' })
                    Methods = @(@{ Name = 'GetCount'; ReturnTypeDefinition = @{ Name = 'Integer' } })
                }
                $newTarget = $oldTarget | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
                $partExtension = @{
                    Id = 8405
                    Name = 'IC Accountant Role Center'
                    TargetObject = 'Accountant Role Center'
                    ControlChanges = @(@{ Name = 'Control1902304208'; Controls = @($newPart) })
                }
                $partOldCollections = @{ Namespaces = @(@{ Name = 'Migration.PartProbe'; Pages = @($page, $oldHost, $oldTarget) }) }
                $partCurrentCollections = @{ Namespaces = @(@{ Name = 'Migration.PartProbe'; Pages = @($currentHost) }) }
                $partDestinationCollections = @{
                    Namespaces = @(@{ Name = 'Migration.PartProbe'; Pages = @($page, $newTarget); PageExtensions = @($partExtension) })
                }
                $partMessage = "The part with name 'Intercompany Activities' defined in Page 'Accountant Role Center' was found in the previous version, but is missing in the current extension."
            }

            It 'reconciles an unchanged part using a <Reference> host reference' -TestCases @(
                @{ Reference = 'simple'; Kind = 'Part'; Suffix = '' },
                @{ Reference = 'qualified'; Kind = 6; Suffix = ' This will break dependent extensions.' }
            ) {
                param($Reference, $Kind, $Suffix)
                $part.Kind = $Kind
                $newPart.Kind = $Kind
                if ($Reference -eq 'qualified') { $partExtension.TargetObject = 'Migration.PartProbe."Accountant Role Center"' }
                Write-PartApiPackages
                $gate = New-ApiGateLayout
                Add-ApiMemberDiagnostic -Gate $gate -RuleId AS0032 -Message "$partMessage$Suffix"
                Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled
                { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Not -Throw
                $state = Get-Content -LiteralPath (Join-Path $gate.Root 'state.json') -Raw | ConvertFrom-Json
                $partMove = @($state.AcceptedMoves | Where-Object RuleId -EQ 'AS0032')
                $partMove.Count | Should -Be 1
                $partMove[0].Accepted | Should -BeTrue
                $partMove[0].PartName | Should -Be 'Intercompany Activities'
                Get-Content -LiteralPath $gate.SourceLog -Raw | Should -Not -Match 'warning AS0032'
                Get-Content -LiteralPath (Join-Path $gate.Root "Originals\$([System.IO.Path]::GetFileName($gate.SourceLog)).txt") -Raw |
                    Should -Match 'warning AS0032'
                $alerts = Get-Content -LiteralPath (Join-Path $gate.Project 'alerts\Base Application_20261027_000000.errorLog.json') -Raw | ConvertFrom-Json
                @($alerts.issues | Where-Object ruleId -EQ 'AS0032').Count | Should -Be 0
                @($alerts.issues | Where-Object ruleId -EQ 'AA0021').Count | Should -Be 1
            }

            It 'rejects a part relocation when <Failure>' -TestCases @(
                @{ Failure = 'the part is deleted' },
                @{ Failure = 'the part is renamed' },
                @{ Failure = 'the control is no longer a part' },
                @{ Failure = 'the target page changes' },
                @{ Failure = 'part properties change' },
                @{ Failure = 'the host page changes' },
                @{ Failure = 'the host namespace changes' },
                @{ Failure = 'the host reference is ambiguous' },
                @{ Failure = 'two extensions provide the part' },
                @{ Failure = 'the target page is missing' },
                @{ Failure = 'the target page contract changes' },
                @{ Failure = 'the provider is not exposed' },
                @{ Failure = 'the part stays in the source app' }
            ) {
                param($Failure)
                switch ($Failure) {
                    'the part is deleted' { $partExtension.ControlChanges = @() }
                    'the part is renamed' { $newPart.Name = 'Renamed activities' }
                    'the control is no longer a part' { $newPart.Kind = 'Field' }
                    'the target page changes' { $newPart.TypeDefinition.Subtype.Id = 9072 }
                    'part properties change' { $newPart.Properties[0].Value = 'Basic' }
                    'the host page changes' {
                        $partExtension.TargetObject = 'Other Role Center'
                        $partCurrentCollections.Namespaces[0].Pages += @{ Id = 9028; Name = 'Other Role Center' }
                    }
                    'the host namespace changes' { $partCurrentCollections.Namespaces[0].Name = 'Migration.Other' }
                    'the host reference is ambiguous' {
                        $partCurrentCollections.Namespaces += @{ Name = 'Migration.Other'; Pages = @(@{ Id = 9028; Name = 'Accountant Role Center' }) }
                    }
                    'two extensions provide the part' {
                        $duplicate = $partExtension | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
                        $duplicate.Id = 8406
                        $duplicate.Name = 'Duplicate part provider'
                        $partDestinationCollections.Namespaces[0].PageExtensions += $duplicate
                    }
                    'the target page is missing' { $partDestinationCollections.Namespaces[0].Pages = @($page) }
                    'the target page contract changes' { $newTarget.Methods[0].ReturnTypeDefinition.Name = 'Text' }
                    'the provider is not exposed' {
                        $script:currentApplication = New-ApiTestPackage -Name 'Application' -Id $applicationId -Propagate $true -Dependencies @($script:currentBase)
                    }
                    'the part stays in the source app' {
                        $partCurrentCollections.Namespaces[0].PageExtensions = @($partExtension)
                        $partDestinationCollections.Namespaces[0].PageExtensions = @()
                    }
                }
                Write-PartApiPackages
                $gate = New-ApiGateLayout
                Add-ApiMemberDiagnostic -Gate $gate -RuleId AS0032 -Message $partMessage
                { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Throw '*not verified*'
                $state = Get-Content -LiteralPath (Join-Path $gate.Root 'state.json') -Raw | ConvertFrom-Json
                $partMove = @($state.AcceptedMoves | Where-Object RuleId -EQ 'AS0032')
                $partMove.Count | Should -Be 1
                $partMove[0].Accepted | Should -BeFalse
                $partMove[0].Reason | Should -Not -BeNullOrEmpty
                Get-Content -LiteralPath $gate.SourceLog -Raw | Should -Match 'warning AS0032'
                { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Throw '*Failed*'
            }
        }

        Context 'Actions relocated into Application page extensions' {
            BeforeAll {
                function Write-ActionApiPackages {
                    $null = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Version '1.0.0.0' -Path $oldBase.Path -Collections $actionOldCollections
                    $null = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Path $script:currentBase.Path -Collections $actionCurrentCollections
                    $null = New-ApiTestPackage -Name 'Intercompany' -Id $destinationId -Path $destination.Path -Collections $actionDestinationCollections
                }
            }

            BeforeEach {
                $group = @{
                    Name = 'Group3'
                    Kind = 'Group'
                    Properties = @(@{ Name = 'Caption'; Value = 'Intercompany' })
                    Actions = @(@{
                        Name = 'General Journals'
                        Kind = 'Action'
                        Properties = @(@{ Name = 'RunObject'; Value = 'Page "IC General Journal"' })
                    })
                }
                $newGroup = $group | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
                $standalone = $group.Actions[0] | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
                $standalone.Name = 'General Journals2'
                $newStandalone = $standalone | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
                $oldHost = @{
                    Id = 9041
                    Name = 'Finance Manager Role Center'
                    Actions = @(@{ Name = 'sections'; Kind = 'Area'; Actions = @($group, $standalone) })
                }
                $currentHost = $oldHost | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
                $currentHost.Actions[0].Actions = @()
                $actionExtension = @{
                    Id = 8406
                    Name = 'IC Finance Manager RC'
                    TargetObject = 'Finance Manager Role Center'
                    ActionChanges = @(
                        @{ Name = 'Group2'; Actions = @($newGroup) },
                        @{ Name = 'Recurring Journals'; Actions = @($newStandalone) }
                    )
                }
                $actionOldCollections = @{ Namespaces = @(@{ Name = 'Migration.ActionProbe'; Pages = @($page, $oldHost) }) }
                $actionCurrentCollections = @{ Namespaces = @(@{ Name = 'Migration.ActionProbe'; Pages = @($currentHost) }) }
                $actionDestinationCollections = @{
                    Namespaces = @(@{ Name = 'Migration.ActionProbe'; Pages = @($page); PageExtensions = @($actionExtension) })
                }
                $groupMessage = "The action group with name 'Group3' defined in Page 'Finance Manager Role Center' was found in the previous version, but is missing in the current extension."
                $childMessage = "The action with name 'General Journals' defined in Page 'Finance Manager Role Center' was found in the previous version, but is missing in the current extension."
                $standaloneMessage = "The action with name 'General Journals2' defined in Page 'Finance Manager Role Center' was found in the previous version, but is missing in the current extension."
            }

            It 'reconciles an unchanged group, its child action and a standalone action with <Encoding> kinds' -TestCases @(
                @{ Encoding = 'string'; Suffix = '' },
                @{ Encoding = 'numeric'; Suffix = ' This will break dependent extensions.' }
            ) {
                param($Encoding, $Suffix)
                if ($Encoding -eq 'numeric') {
                    $group.Kind = $newGroup.Kind = 1
                    $group.Actions[0].Kind = $newGroup.Actions[0].Kind = 2
                    $standalone.Kind = $newStandalone.Kind = 2
                }
                Write-ActionApiPackages
                $gate = New-ApiGateLayout
                foreach ($message in @($groupMessage, $childMessage, $standaloneMessage)) {
                    Add-ApiMemberDiagnostic -Gate $gate -RuleId AS0031 -Message "$message$Suffix"
                }
                Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled
                { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Not -Throw
                $state = Get-Content -LiteralPath (Join-Path $gate.Root 'state.json') -Raw | ConvertFrom-Json
                $moves = @($state.AcceptedMoves | Where-Object RuleId -EQ 'AS0031')
                $moves.Count | Should -Be 3
                @($moves | Where-Object { -not $_.Accepted }).Count | Should -Be 0
                ($moves | Where-Object ActionName -EQ 'Group3').ActionKind | Should -Be 'ActionGroup'
                Get-Content -LiteralPath $gate.SourceLog -Raw | Should -Not -Match 'warning AS0031'
                Get-Content -LiteralPath (Join-Path $gate.Root "Originals\$([System.IO.Path]::GetFileName($gate.SourceLog)).txt") -Raw |
                    Should -Match 'warning AS0031'
                $alerts = Get-Content -LiteralPath (Join-Path $gate.Project 'alerts\Base Application_20261027_000000.errorLog.json') -Raw | ConvertFrom-Json
                @($alerts.issues | Where-Object ruleId -EQ 'AS0031').Count | Should -Be 0
                @($alerts.issues | Where-Object ruleId -EQ 'AA0021').Count | Should -Be 1
            }

            It 'recognizes an action-group diagnostic accompanying an unchanged whole-page move' {
                $actionCurrentCollections.Namespaces[0].Pages = @()
                $actionDestinationCollections.Namespaces[0].Pages += $oldHost
                $actionDestinationCollections.Namespaces[0].PageExtensions = @()
                Write-ActionApiPackages
                $gate = New-ApiGateLayout -Id $oldHost.Id -Name $oldHost.Name
                Add-ApiMemberDiagnostic -Gate $gate -RuleId AS0031 -Message $groupMessage
                Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled
                $state = Get-Content -LiteralPath (Join-Path $gate.Root 'state.json') -Raw | ConvertFrom-Json
                $state.AcceptedMoves.Count | Should -Be 2
                @($state.AcceptedMoves | Where-Object { -not $_.Accepted }).Count | Should -Be 0
            }

            It 'rejects action relocations when <Failure>' -TestCases @(
                @{ Failure = 'the group is missing' },
                @{ Failure = 'the group is renamed' },
                @{ Failure = 'the member kind changes' },
                @{ Failure = 'a child action is missing' },
                @{ Failure = 'a child action target changes' },
                @{ Failure = 'the group properties change' },
                @{ Failure = 'the host page changes' },
                @{ Failure = 'two extensions provide the group' },
                @{ Failure = 'the provider is not exposed' },
                @{ Failure = 'the group stays in the source app' },
                @{ Failure = 'the standalone action is missing' }
            ) {
                param($Failure)
                $message = $groupMessage
                switch ($Failure) {
                    'the group is missing' { $actionExtension.ActionChanges[0].Actions = @() }
                    'the group is renamed' { $newGroup.Name = 'Renamed group' }
                    'the member kind changes' { $newGroup.Kind = 'Action' }
                    'a child action is missing' { $newGroup.Actions = @() }
                    'a child action target changes' { $newGroup.Actions[0].Properties[0].Value = 'Page "Different Journal"' }
                    'the group properties change' { $newGroup.Properties[0].Value = 'Changed caption' }
                    'the host page changes' {
                        $actionExtension.TargetObject = 'Other Role Center'
                        $actionCurrentCollections.Namespaces[0].Pages += @{ Id = 9042; Name = 'Other Role Center' }
                    }
                    'two extensions provide the group' {
                        $duplicate = $actionExtension | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
                        $duplicate.Id = 8408
                        $duplicate.Name = 'Duplicate action provider'
                        $actionDestinationCollections.Namespaces[0].PageExtensions += $duplicate
                    }
                    'the provider is not exposed' {
                        $script:currentApplication = New-ApiTestPackage -Name 'Application' -Id $applicationId -Propagate $true -Dependencies @($script:currentBase)
                    }
                    'the group stays in the source app' {
                        $actionCurrentCollections.Namespaces[0].PageExtensions = @($actionExtension)
                        $actionDestinationCollections.Namespaces[0].PageExtensions = @()
                    }
                    'the standalone action is missing' {
                        $actionExtension.ActionChanges[1].Actions = @()
                        $message = $standaloneMessage
                    }
                }
                Write-ActionApiPackages
                $gate = New-ApiGateLayout
                Add-ApiMemberDiagnostic -Gate $gate -RuleId AS0031 -Message $message
                { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Throw '*not verified*'
                $state = Get-Content -LiteralPath (Join-Path $gate.Root 'state.json') -Raw | ConvertFrom-Json
                $moves = @($state.AcceptedMoves | Where-Object RuleId -EQ 'AS0031')
                $moves.Count | Should -Be 1
                $moves[0].Accepted | Should -BeFalse
                $moves[0].Reason | Should -Not -BeNullOrEmpty
                Get-Content -LiteralPath $gate.SourceLog -Raw | Should -Match 'warning AS0031'
                { Assert-ApplicationApiValidationComplete -ProjectFolder $gate.Project } | Should -Throw '*Failed*'
            }
        }

        It 'still rejects <RuleId> member removals without a verified replacement' -TestCases @(
            @{ RuleId = 'AS0018'; ExpectedFailure = '*not part of a whole-object move*'; Message = "Procedure 'Process(Text)' has been removed in 'Table Gen. Journal Line'. A procedure that belongs to the public API must not be removed as it will break dependent extensions calling this procedure." },
            @{ RuleId = 'AS0031'; ExpectedFailure = '*not verified*'; Message = "The action with name 'Partners' defined in Page 'Accountant Role Center' was found in the previous version, but is missing in the current extension. This will break dependent extensions." },
            @{ RuleId = 'AS0032'; ExpectedFailure = '*not part of a whole-object move*'; Message = "The field with name 'icPartnerCode' defined in Page 'Workflow - Customer Entity' was found in the previous version, but is missing in the current extension. This will break dependent extensions." },
            @{ RuleId = 'AS0106'; ExpectedFailure = '*not part of a whole-object move*'; Message = "The variable 'ShortcutDimCode' of type 'array[8] of Code[20]' defined in Page 'Unmoved Page' was found in the previous version, but is missing in the current extension. This will break dependent extensions." }
        ) {
            param($RuleId, $Message, $ExpectedFailure)
            $gate = New-ApiGateLayout
            Add-ApiMemberDiagnostic -Gate $gate -RuleId $RuleId -Message $Message
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Throw $ExpectedFailure
            Get-Content -LiteralPath $gate.SourceLog -Raw | Should -Match "warning ${RuleId}:"
        }

        It 'does not require unrelated, compatible method additions to have identical symbols' {
            $unchangedMethod = @{ Name = 'Existing'; Parameters = @() }
            $null = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Version '1.0.0.0' -Path $oldBase.Path -Collections @{
                Namespaces = @(@{ Name = 'Microsoft.Intercompany.DataExchange'; Pages = @($page) })
                Codeunits = @(@{ Id = 100; Name = 'Other API'; Methods = @($unchangedMethod) })
            }
            $script:currentBase = New-ApiTestPackage -Name 'Base Application' -Id $baseId -Collections @{
                Codeunits = @(@{ Id = 100; Name = 'Other API'; Methods = @($unchangedMethod, @{ Name = 'Added'; Parameters = @() }) })
            }
            $gate = New-ApiGateLayout
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Not -Throw
        }

        It 'retains unchanged cache-only dependencies shared by CLEAN baseline and current snapshots' {
            $shared = New-ApiTestPackage -Name 'Shared Dependency' -Id '00000000-0000-0000-0000-000000000001'
            $null = New-ApiTestPackage -Name 'Application' -Id $applicationId -Version '1.0.0.0' -Path $oldApplication.Path -Propagate $true -Dependencies @($oldBase, $shared)
            $script:currentApplication = New-ApiTestPackage -Name 'Application' -Id $applicationId -Propagate $true -Dependencies @($script:currentBase, $destination, $shared)
            $gate = New-ApiGateLayout -CacheDependencies @($shared.Path)
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Not -Throw
        }
    }
}
