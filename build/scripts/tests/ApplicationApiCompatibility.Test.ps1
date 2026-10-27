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
            param([string] $RuleId = 'AS0029', [string] $Kind = 'Page', [string[]] $CacheDependencies = @())

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
                    $message = "The '$Kind' with ID '621' and name 'IC API Log Entries' was found in the previous version, but is missing in the current extension. This will break dependent extensions."
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

        It 'still rejects <RuleId> member removals from objects that have not moved' -TestCases @(
            @{ RuleId = 'AS0018'; Message = "Procedure 'Process(Text)' has been removed in 'Table Gen. Journal Line'. A procedure that belongs to the public API must not be removed as it will break dependent extensions calling this procedure." },
            @{ RuleId = 'AS0031'; Message = "The action with name 'Partners' defined in Page 'Accountant Role Center' was found in the previous version, but is missing in the current extension. This will break dependent extensions." },
            @{ RuleId = 'AS0032'; Message = "The field with name 'icPartnerCode' defined in Page 'Workflow - Customer Entity' was found in the previous version, but is missing in the current extension. This will break dependent extensions." },
            @{ RuleId = 'AS0106'; Message = "The variable 'ShortcutDimCode' of type 'array[8] of Code[20]' defined in Page 'Unmoved Page' was found in the previous version, but is missing in the current extension. This will break dependent extensions." }
        ) {
            param($RuleId, $Message)
            $gate = New-ApiGateLayout
            Add-ApiMemberDiagnostic -Gate $gate -RuleId $RuleId -Message $Message
            { Complete-ApplicationApiValidation -CompilationParameters $gate.Parameters -AppFiles $gate.Compiled } | Should -Throw '*not part of a whole-object move*'
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
