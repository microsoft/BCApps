# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

Describe 'AL dependency rules' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ALDependencyRules.psm1') -Force
        $script:architectureRunner = Join-Path $PSScriptRoot '../Test-PayablesAgentArchitecture.ps1'
        $script:paApp = Join-Path $PSScriptRoot '../../../src/Apps/W1/PayablesAgent/app'

        # Plain throwing assertions keep these tests usable with Pester 3 (Windows PowerShell), 4 and 5.
        function Assert-DependencyValue($Actual, $Expected) {
            if ($Actual -cne $Expected) { throw "Expected '$Expected', got '$Actual'." }
        }
        function Assert-DependencyFailure([scriptblock] $Action, [string] $Message) {
            $failure = $null
            try { & $Action | Out-Null } catch { $failure = $_ }
            if ($null -eq $failure) { throw "Expected a failure matching '$Message'." }
            if ($failure.Exception.Message -notlike "*$Message*") { throw "Unexpected failure: $failure" }
        }
        function Set-DependencyFile($Layout, [string] $Path, [string] $Text) {
            $fullPath = Join-Path $Layout.App $Path
            New-Item -ItemType Directory -Path (Split-Path $fullPath -Parent) -Force | Out-Null
            Set-Content -LiteralPath $fullPath -Value $Text -Encoding UTF8
        }
        function New-DependencyLayout {
            $root = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
            $layout = [PSCustomObject]@{ App = (Join-Path $root 'App'); Rules = (Join-Path $root 'rules.json'); External = (Join-Path $root 'External') }
            New-Item -ItemType Directory -Path $layout.App, $layout.External -Force | Out-Null
            Set-DependencyFile $layout 'Entities/Backing.Table.al' 'namespace Demo; table 50100 "Backing" { fields { field(1; Id; Integer) { } } }'
            Set-DependencyFile $layout 'Entities/Backing.Codeunit.al' 'namespace Demo; codeunit 50101 "Backing" { }'
            Set-DependencyFile $layout 'Entities/State.Enum.al' 'namespace Demo; enum 50102 "State" { value(0; Open) { } }'
            Set-DependencyFile $layout 'Views/Target.Page.al' 'namespace Demo; page 50103 "Target" { }'
            Set-DependencyFile $layout 'Entities/IWork.Interface.al' 'namespace Demo; interface IWork { procedure Work(); }'
            return $layout
        }
        function Set-DependencyPolicy($Layout, $Rule, [object[]] $Catalogs = @()) {
            if ($null -eq $Rule) {
                $Rule = @{ id = 'TEST'; description = 'Backing ownership.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('table'); names = @('Backing') } }
            }
            @{ version = 1; catalogs = $Catalogs; rules = @($Rule) } | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Layout.Rules -Encoding UTF8
        }
        function Get-DependencyResult($Layout) { Invoke-ALDependencyRules -AppRoot $Layout.App -RulesPath $Layout.Rules }
    }

    BeforeEach {
        $layout = New-DependencyLayout
        Set-DependencyPolicy $layout
    }

    It 'distinguishes a backing table from the codeunit with the same name' {
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { var Wrapper: Codeunit "Backing"; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 0
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { var Storage: Record "Backing"; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'ignores comments and strings, decodes quoted identifiers, and preserves line numbers' {
        Set-DependencyFile $layout 'Consumers/Caller.al' @'
namespace Demo;
codeunit 50104 Caller
{
    // Record "Backing";
    /* Codeunit Fake { Record "Backing"; } */
    var Fake: Label 'Record "Backing"; ''still just a string''';
    procedure Read(): Record "Backing"
    begin
    end;
}
'@
        $result = Get-DependencyResult $layout
        Assert-DependencyValue $result.Diagnostics.Count 1
        Assert-DependencyValue $result.Diagnostics[0].Line 7
    }

    It 'supports escaped quotes inside object names' {
        Set-DependencyFile $layout 'Entities/Backing.Table.al' 'namespace Demo; table 50100 "Back""ing" { }'
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { var R: Record "Back""ing"; }'
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Quoted.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('table'); names = @('Back"ing') } }
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'checks both preprocessor branches and accepts repeated declarations of the same identity' {
        Set-DependencyFile $layout 'Consumers/Caller.al' @'
namespace Demo;
#if FEATURE
codeunit 50104 Caller implements IWork
#else
codeunit 50104 Caller
#endif
{
#if FEATURE
    var R: Record "Backing";
#else
    var S: Record "Backing";
#endif
}
'@
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'fails rather than silently skipping an unreadable AL object' {
        Set-DependencyFile $layout 'Consumers/Invalid.al' 'this is not an AL object'
        Assert-DependencyFailure { Get-DependencyResult $layout } 'expected one AL object identity'
    }

    It 'fails on unterminated comments and strings' {
        Set-DependencyFile $layout 'Consumers/Invalid.al' 'codeunit 50104 Caller { /* unfinished'
        Assert-DependencyFailure { Get-DependencyResult $layout } 'unterminated'
        Set-DependencyFile $layout 'Consumers/Invalid.al' "codeunit 50104 Caller { var L: Label 'unfinished"
        Assert-DependencyFailure { Get-DependencyResult $layout } 'unterminated'
    }

    It 'excludes only explicit temporary references when requested' {
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Persistent only.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('table'); names = @('Backing') }; includeTemporary = $false }
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { var R: Record "Backing" temporary; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 0
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { var R: Record "Backing" temporary; S: Record "Backing"; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'recognizes intrinsic temporary tables and temporary page SourceTable bindings' {
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Persistent only.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('table'); names = @('Backing') }; includeTemporary = $false }
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; page 50104 Caller { SourceTable = "Backing"; SourceTableTemporary = true; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 0
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; page 50104 Caller { SourceTable = "Backing"; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
        Set-DependencyFile $layout 'Entities/Backing.Table.al' 'namespace Demo; table 50100 "Backing" { TableType = Temporary; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 0
    }

    It 'does not use conditional temporary properties to hide persistent preprocessor alternatives' {
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Persistent only.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('table'); names = @('Backing') }; includeTemporary = $false }
        Set-DependencyFile $layout 'Consumers/Caller.al' @'
namespace Demo;
page 50104 Caller
{
    SourceTable = Backing;
#if FEATURE
    SourceTableTemporary = true;
#endif
}
'@
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
        Set-DependencyFile $layout 'Entities/Backing.Table.al' @'
namespace Demo;
table 50100 Backing
{
#if FEATURE
    TableType = Temporary;
#endif
}
'@
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'does not exempt typed persistent records merely because their page SourceTable is temporary' {
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Persistent only.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('table'); names = @('Backing') }; includeTemporary = $false }
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; page 50104 Caller { SourceTable = "Backing"; SourceTableTemporary = true; var R: Record "Backing"; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'finds numeric Database references and numeric static Run calls' {
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { procedure P() begin Use(Database::50100); end; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'No navigation.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('page'); names = @('Target') } }
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { procedure P() begin Page.RunModal(50103); end; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'finds event subscription targets but not ObjectType enum members or string arguments' {
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { [EventSubscriber(ObjectType::Table, Database::"Backing", ''OnAfterInsertEvent'', '''', false, false)] local procedure P() begin end; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'separates permission grants from runtime references' {
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; permissionset 50104 Caller { Permissions = tabledata "Backing" = R; }'
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Types only.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ names = @('Backing') }; referenceKinds = @('type') }
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 0
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Permissions only.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ names = @('Backing') }; referenceKinds = @('permission') }
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'finds every target of conditional table relations and negative flowfield formulas' {
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; table 50104 Caller { fields { field(1; Id; Integer) { TableRelation = if (Id = const(1)) Backing.Id else if (Id = const(2)) "Backing" where(Id = const(2)) else Backing; CalcFormula = -sum(Backing.Id); } } }'
        $result = Get-DependencyResult $layout
        Assert-DependencyValue $result.Diagnostics.Count 2
    }

    It 'finds page parts, extensions and RunObject properties' {
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'No navigation.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('page'); names = @('Target') } }
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; pageextension 50104 Caller extends Target { layout { addlast(Content) { part(P; Target) { } } } actions { addlast(Processing) { action(A) { RunObject = Page Target; } } } }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 3
    }

    It 'finds query dataitem tables' {
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; query 50104 Caller { elements { dataitem(D; "Backing") { column(Id; Id) { } } } }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'finds all interfaces in implements lists' {
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'No interface dependency.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('interface'); names = @('IWork') } }
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller implements IOther, IWork { }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'finds implicit enum-type references' {
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'No enum dependency.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('enum'); names = @('State') } }
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { procedure P() begin Use("State"::Open); end; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'deduplicates explicit and qualified implicit enum references without losing namespace identity' {
        Set-Content -LiteralPath (Join-Path $layout.External 'State.al') -Value 'namespace External.Documents; enum 900 State { value(0; Open) { } }' -Encoding UTF8
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'No external enum.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ catalogs = @('documents') } } @(@{ id = 'documents'; path = '../External' })
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { procedure P() begin Use(External.Documents.State::Open); Use(Enum::External.Documents.State::Open); end; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'resolves qualified references and numeric IDs against external source catalogs' {
        Set-Content -LiteralPath (Join-Path $layout.External 'Imported.al') -Value 'namespace External.Documents; table 900 "Imported" { }' -Encoding UTF8
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'No external dependency.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ catalogs = @('documents') } } @(@{ id = 'documents'; path = '../External' })
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { var R: Record External.Documents.Imported; procedure P() begin Use(Database::900); end; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 2
    }

    It 'uses local namespaces and using directives to disambiguate catalog symbols' {
        Set-Content -LiteralPath (Join-Path $layout.External 'Other.al') -Value 'namespace External.Documents; table 900 "Backing" { }' -Encoding UTF8
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'No external dependency.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ catalogs = @('documents') } } @(@{ id = 'documents'; path = '../External' })
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Elsewhere; using External.Documents; codeunit 50104 Caller { var R: Record Backing; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; using External.Documents; codeunit 50104 Caller { var R: Record Backing; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 0
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Elsewhere; codeunit 50104 Caller { var R: Record Backing; }'
        Assert-DependencyFailure { Get-DependencyResult $layout } 'ambiguous'
    }

    It 'can restrict named framework symbols without a source catalog' {
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'One task factory.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('codeunit'); names = @('Agent Task Builder') } }
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { var B: Codeunit "Agent Task Builder"; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
    }

    It 'ANDs selector fields, ORs values, and matches case-insensitive forward-slash globs' {
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Selectors.'; severity = 'error'; from = @{ paths = @('consumers/*'); kinds = @('codeunit') }; to = @{ kinds = @('table'); names = @('Other', 'back?ng'); namespaces = @('d*') } }
        Set-DependencyFile $layout 'Consumers/Nested/Caller.al' 'namespace Demo; codeunit 50104 Caller { var R: Record Backing; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 1
        Set-DependencyFile $layout 'Consumers/Nested/Caller.al' 'namespace Demo; page 50104 Caller { SourceTable = Backing; }'
        Assert-DependencyValue (Get-DependencyResult $layout).Diagnostics.Count 0
    }

    It 'applies documented exceptions only to matching targets and reference kinds' {
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Exceptions.'; severity = 'error'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('table'); names = @('Backing') }; exceptions = @(@{ from = @{ paths = @('Consumers/Caller.al') }; to = @{ kinds = @('table'); names = @('Backing') }; referenceKinds = @('object'); reason = 'Classification ID only.' }) }
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { var R: Record Backing; procedure P() begin Use(Database::Backing); end; }'
        $result = Get-DependencyResult $layout
        Assert-DependencyValue $result.Diagnostics.Count 1
        Assert-DependencyValue $result.Diagnostics[0].RuleId 'TEST'
    }

    It 'fails stale exceptions, including on warning-only rules' {
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Stale.'; severity = 'warning'; from = @{ paths = @('Consumers/*') }; to = @{ names = @('Backing') }; exceptions = @(@{ from = @{ paths = @('Removed.al') }; reason = 'Old exemption.' }) }
        $result = Get-DependencyResult $layout
        Assert-DependencyValue $result.Diagnostics.Count 1
        Assert-DependencyValue $result.Diagnostics[0].RuleId 'CONFIG'
        Assert-DependencyValue $result.Diagnostics[0].Severity 'error'
    }

    It 'rejects malformed rules, unknown fields, invalid selectors and duplicate IDs' {
        Set-Content -LiteralPath $layout.Rules -Value '{invalid' -Encoding UTF8
        Assert-DependencyFailure { Get-DependencyResult $layout } ''
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Invalid.'; severity = 'error'; from = @{ paths = @('*') }; to = @{ names = @('Backing') }; typo = $true }
        Assert-DependencyFailure { Get-DependencyResult $layout } 'unknown property'
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Invalid.'; severity = 'error'; from = @{}; to = @{ names = @('Backing') } }
        Assert-DependencyFailure { Get-DependencyResult $layout } 'empty selector'
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Invalid.'; severity = 'ignore'; from = @{ paths = @('*') }; to = @{ names = @('Backing') } }
        Assert-DependencyFailure { Get-DependencyResult $layout } 'severity'
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Invalid.'; severity = 'error'; from = @{ paths = @('*') }; to = @{ names = @('Backing') }; includeTemporary = 'false' }
        Assert-DependencyFailure { Get-DependencyResult $layout } 'boolean'
        Set-DependencyPolicy $layout
        $policy = Get-Content $layout.Rules -Raw | ConvertFrom-Json
        $policy.rules = @($policy.rules[0], $policy.rules[0])
        $policy | ConvertTo-Json -Depth 20 | Set-Content $layout.Rules -Encoding UTF8
        Assert-DependencyFailure { Get-DependencyResult $layout } 'duplicate rule id'
    }

    It 'rejects unknown catalog selectors, reserved catalog names, missing and empty source catalogs' {
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Invalid.'; severity = 'error'; from = @{ paths = @('*') }; to = @{ catalogs = @('typo') } }
        Assert-DependencyFailure { Get-DependencyResult $layout } 'unknown catalog'
        Set-DependencyPolicy $layout $null @(@{ id = 'external'; path = '../External' })
        Assert-DependencyFailure { Get-DependencyResult $layout } 'catalog id'
        Set-DependencyPolicy $layout $null @(@{ id = 'documents'; path = '../External' })
        Assert-DependencyFailure { Get-DependencyResult $layout } 'contains no AL files'
        Remove-Item $layout.External -Recurse -Force
        Assert-DependencyFailure { Get-DependencyResult $layout } ''
    }

    It 'fails errors in the executable entry point and can promote warnings to errors' {
        Set-DependencyFile $layout 'Consumers/Caller.al' 'namespace Demo; codeunit 50104 Caller { var R: Record Backing; }'
        # Suppress expected diagnostics so negative tests do not emit fake GitHub error annotations.
        Assert-DependencyFailure { & $script:architectureRunner -AppRoot $layout.App -RulesPath $layout.Rules 6>$null } 'dependency rules failed'
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = 'Warning.'; severity = 'warning'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('table'); names = @('Backing') } }
        $result = & $script:architectureRunner -AppRoot $layout.App -RulesPath $layout.Rules -PassThru 6>$null
        Assert-DependencyValue $result.Diagnostics.Count 1
        Assert-DependencyFailure { & $script:architectureRunner -AppRoot $layout.App -RulesPath $layout.Rules -WarningsAsErrors 6>$null } 'dependency rules failed'
    }

    It 'escapes GitHub annotation paths and messages' {
        Set-DependencyFile $layout 'Consumers/Caller,%.al' 'namespace Demo; codeunit 50104 Caller { var R: Record Backing; }'
        Set-DependencyPolicy $layout @{ id = 'TEST'; description = "First`nsecond%."; severity = 'warning'; from = @{ paths = @('Consumers/*') }; to = @{ kinds = @('table'); names = @('Backing') } }
        $oldActions = $env:GITHUB_ACTIONS
        try {
            $env:GITHUB_ACTIONS = 'true'
            $output = @(& $script:architectureRunner -AppRoot $layout.App -RulesPath $layout.Rules 6>&1)
            $annotations = @($output | Where-Object { $_.ToString().StartsWith('::warning ') })
            Assert-DependencyValue $annotations.Count 1
            $annotation = $annotations[0].ToString()
            if (-not $annotation.Contains('Caller%2C%25.al') -or -not $annotation.Contains('First%0Asecond%25.')) { throw "Annotation not escaped: $annotation" }
        }
        finally { $env:GITHUB_ACTIONS = $oldActions }
    }

    It 'runs the build gate before AL-Go skip decisions and also hooks PR validation' {
        $repoRoot = Join-Path $PSScriptRoot '../../..'
        $build = Get-Content (Join-Path $repoRoot '.github/workflows/_BuildALGoProject.yaml') -Raw
        $pr = Get-Content (Join-Path $repoRoot '.github/workflows/PullRequestHandler.yaml') -Raw
        $gate = $build.IndexOf('name: Validate Payables Agent dependency rules')
        if ($gate -lt 0 -or $gate -gt $build.IndexOf('name: Determine whether to build project')) { throw 'Build gate must precede AL-Go skip/cache decisions.' }
        if (-not $build.Contains("if: inputs.projectName == 'Apps W1'")) { throw 'Build gate must apply to Apps W1.' }
        if (-not $pr.Contains('run: ./build/scripts/Test-PayablesAgentArchitecture.ps1')) { throw 'PR validation must invoke the checked-out checker.' }
    }

    It 'evaluates the real PA policy against the entire source tree and its catalogs' {
        $result = Invoke-ALDependencyRules -AppRoot $script:paApp -RulesPath (Join-Path $script:paApp 'dependency-rules.json')
        if ($result.ObjectCount -eq 0) { throw 'The PA source tree was not analyzed.' }
        Assert-DependencyValue @($result.Diagnostics | Where-Object { $_.Severity -eq 'error' }).Count 0
        if ($result.CatalogObjectCount -eq 0) { throw 'The e-document source catalogs were not indexed.' }
    }
}
