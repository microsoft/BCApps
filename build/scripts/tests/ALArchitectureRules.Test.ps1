# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

#Requires -Version 7.0
Describe 'Lightweight AL architecture checks' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ALArchitectureRules.psm1') -Force
        $script:runner = Join-Path $PSScriptRoot '../Test-PayablesAgentArchitecture.ps1'
        $script:paApp = Join-Path $PSScriptRoot '../../../src/Apps/W1/PayablesAgent/app'
        $script:schema = Join-Path $script:paApp 'architecture-rules.schema.json'
        function Assert-Value($Actual, $Expected) {
            if ($Actual -cne $Expected) { throw "Expected '$Expected', got '$Actual'." }
        }
        function Assert-Failure([scriptblock] $Action, [string] $Message = '') {
            $failure = $null
            try { & $Action | Out-Null } catch { $failure = $_ }
            if ($null -eq $failure) { throw "Expected failure matching '$Message'." }
            if ($failure.Exception.Message -notlike "*$Message*") { throw "Unexpected failure: $failure" }
        }
        function Set-File([string] $Path, [string] $Text) {
            $fullPath = Join-Path $layout.App $Path
            New-Item -ItemType Directory -Path (Split-Path $fullPath -Parent) -Force | Out-Null
            Set-Content -LiteralPath $fullPath -Value $Text -Encoding UTF8
        }
        function Set-Caller([string] $Body, [string] $Kind = 'codeunit', [string] $Preamble = 'namespace Demo;') {
            Set-File 'Consumers/Caller.al' "$Preamble`n$Kind 50104 Caller`n{`n$Body`n}"
        }
        function Set-Policy($Rule) {
            @{ version = 2; rules = @($Rule) } | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $layout.Rules -Encoding UTF8
        }
        function New-Rule([string] $Check, [hashtable] $Settings) {
            $rule = @{ id = 'TEST'; check = $Check; description = 'Test policy.'; severity = 'error'; from = @{ paths = @('Consumers/*') } }
            foreach ($key in $Settings.Keys) { $rule[$key] = $Settings[$key] }
            return $rule
        }
        function Get-Result { Invoke-ALArchitectureRules -AppRoot $layout.App -RulesPath $layout.Rules -SchemaPath $script:schema }
    }

    BeforeEach {
        $root = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
        $script:layout = @{ App = (Join-Path $root 'App'); Rules = (Join-Path $root 'architecture-rules.json') }
        Set-File 'Entities/Backing.Table.al' "namespace Demo;`ntable 50100 Backing`n{`n    Access = Internal;`n}"
        Set-File 'Entities/Backing.Codeunit.al' "namespace Demo;`ncodeunit 50101 Backing`n{`n    Access = Internal;`n}"
        Set-Caller ''
        $rule = New-Rule 'dependencies' @{ to = @{ paths = @('Entities/Backing.Table.al') } }
        Set-Policy $rule
        Copy-Item -LiteralPath $script:schema -Destination (Join-Path $root 'architecture-rules.schema.json')
    }

    It 'distinguishes Record/Database/TableData from a codeunit with the same name' {
        Set-Caller 'var Wrapper: Codeunit Backing;'
        Assert-Value (Get-Result).Diagnostics.Count 0
        foreach ($reference in @('Record Backing', 'Database::Backing', 'TableData Backing')) {
            Set-Caller "var R: $reference;"
            Assert-Value (Get-Result).Diagnostics.Count 1
        }
    }

    It 'selects target objects by paths and optional kinds, with case-insensitive recursive globs' {
        $rule.to = @{ paths = @('entities/*'); kinds = @('table') }
        Set-Policy $rule
        Set-Caller 'var R: Record BACKING; Wrapper: Codeunit Backing;'
        Assert-Value (Get-Result).Diagnostics.Count 1
    }

    It 'ignores comments, strings and quoted identifiers containing fake references, preserving lines' {
        Set-Caller @'
// Record Backing;
/* Record Backing;
   Database::Backing; */
var L: Label 'Record Backing; ''still a string''';
    "Record Backing": Integer;
procedure Read(): Record Backing
begin
end;
'@
        $result = Get-Result
        Assert-Value $result.Diagnostics.Count 1
        Assert-Value $result.Diagnostics[0].Line 9
    }

    It 'treats comment markers in quoted object names as opaque and supports escaped quotes' {
        Set-File 'Entities/Backing.Table.al' "namespace Demo;`ntable 50100 `"Back`"`"ing//`"`n{ }"
        Set-Caller 'var R: Record "Back""ing//";'
        Assert-Value (Get-Result).Diagnostics.Count 1
    }

    It 'matches whole identifiers and does not infer a table from a matching field name' {
        Set-Caller 'var R: Record BackingExtra; Backing: Integer; procedure P() begin Use(Rec.Backing); end;'
        Assert-Value (Get-Result).Diagnostics.Count 0
    }

    It 'accepts qualified identifiers without resolving using directives' {
        Set-Caller 'var R: Record Demo.Backing;'
        Assert-Value (Get-Result).Diagnostics.Count 1
        Set-Caller -Body 'var R: Record Other.Backing;' -Kind 'codeunit' -Preamble "namespace Demo;`nusing Other;"
        Assert-Value (Get-Result).Diagnostics.Count 0
    }

    It 'does not scan external source catalogs' {
        Set-File 'app.json' '{"dependencies":[{"name":"Missing external source"}]}'
        Set-Caller 'var R: Record Backing;'
        Assert-Value (Get-Result).Diagnostics.Count 1
    }

    It 'supports explicit typed framework symbols without catalogs' {
        Set-Policy (New-Rule 'dependencies' @{ symbols = @(@{ kind = 'codeunit'; name = 'Agent Task Builder' }) })
        Set-Caller 'var B: Codeunit "Agent Task Builder"; R: Record "Agent Task Builder";'
        Assert-Value (Get-Result).Diagnostics.Count 1
    }

    It 'counts temporary references and deduplicates all preprocessor branches' {
        Set-Caller "#if FEATURE`nvar R: Record Backing temporary;`n#else`nvar S: Record Backing;`n#endif"
        Assert-Value (Get-Result).Diagnostics.Count 1
    }

    It 'supports repeated declarations of one identity under preprocessor branches' {
        Set-File 'Consumers/Caller.al' "namespace Demo;`n#if FEATURE`ncodeunit 50104 Caller implements IWork`n#else`ncodeunit 50104 Caller`n#endif`n{ var R: Record Backing; }"
        Assert-Value (Get-Result).Diagnostics.Count 1
    }

    It 'recognizes simple SourceTable and TableRelation bindings as table references' {
        Set-Caller 'SourceTable = Backing;' 'page'
        Assert-Value (Get-Result).Diagnostics.Count 1
        Set-Caller 'fields { field(1; Id; Integer) { TableRelation = Backing.Id; } }' 'table'
        Assert-Value (Get-Result).Diagnostics.Count 1
    }

    It 'recognizes inheritance, RunObject and event subscriber object constants' {
        Set-File 'Consumers/Caller.al' "namespace Demo;`ntableextension 50104 Caller extends Backing`n{ }"
        Assert-Value (Get-Result).Diagnostics.Count 1
        Set-Caller '[EventSubscriber(ObjectType::Table, Database::Backing, ''OnAfterInsertEvent'', '''', false, false)] local procedure P() begin end;'
        Assert-Value (Get-Result).Diagnostics.Count 1
        Set-Policy (New-Rule 'dependencies' @{ to = @{ paths = @('Entities/Backing.Codeunit.al') } })
        Set-Caller 'actions { area(Processing) { action(A) { RunObject = codeunit Backing; } } }' 'page'
        Assert-Value (Get-Result).Diagnostics.Count 1
    }

    It 'does not mistake ObjectType enum members for typed object references' {
        Set-Policy (New-Rule 'dependencies' @{ symbols = @(@{ kind = 'table'; name = 'ObjectType' }) })
        Set-Caller 'procedure P() begin Use(ObjectType::Table); end;'
        Assert-Value (Get-Result).Diagnostics.Count 0
    }

    It 'deliberately does not resolve numeric IDs, dynamic references or implicit enum types' {
        Set-Caller 'procedure P() begin Use(Database::50100); Codeunit.Run(50101); Use(Backing::Open); end;'
        Assert-Value (Get-Result).Diagnostics.Count 0
    }

    It 'never treats an object declaration as its own dependency' {
        $rule.from.paths = @('Entities/Backing.Table.al')
        Set-Policy $rule
        Assert-Value (Get-Result).Diagnostics.Count 0
    }

    It 'checks external namespace imports even when unused and matches nested namespaces' {
        Set-Policy (New-Rule 'namespaces' @{ namespaces = @('External.Documents') })
        Set-Caller -Body '' -Kind 'codeunit' -Preamble "namespace Demo;`nusing external.documents.Import;"
        $result = Get-Result
        Assert-Value $result.Diagnostics.Count 1
        Assert-Value $result.Diagnostics[0].Line 2
    }

    It 'also detects fully qualified external uses without a using directive' {
        Set-Policy (New-Rule 'namespaces' @{ namespaces = @('External.Documents') })
        Set-Caller 'var R: Record External.Documents.Invoice;'
        Assert-Value (Get-Result).Diagnostics.Count 1
    }

    It 'does not match namespace-prefix lookalikes, strings, comments or quoted fields' {
        Set-Policy (New-Rule 'namespaces' @{ namespaces = @('External.Documents') })
        Set-Caller '// using External.Documents;'
        Assert-Value (Get-Result).Diagnostics.Count 0
        Set-Caller -Body 'var L: Label ''External.Documents''; "External.Documents": Integer;' -Kind 'codeunit' -Preamble "namespace Demo;`nusing External.DocumentsExtra;"
        Assert-Value (Get-Result).Diagnostics.Count 0
    }

    It 'requires internal access on the object header, not a field or procedure body' {
        Set-Policy (New-Rule 'properties' @{ from = @{ paths = @('Consumers/*'); kinds = @('table') }; properties = @{ Access = 'Internal' } })
        Set-Caller 'fields { field(1; Id; Integer) { Access = Internal; } }' 'table'
        Assert-Value (Get-Result).Diagnostics.Count 1
        Set-Caller 'Access = Internal; fields { field(1; Id; Integer) { } }' 'table'
        Assert-Value (Get-Result).Diagnostics.Count 0
    }

    It 'requires explicit non-extensibility and does not accept a commented property' {
        Set-Policy (New-Rule 'properties' @{ from = @{ paths = @('Consumers/*'); kinds = @('page') }; properties = @{ Extensible = $false } })
        Set-Caller '// Extensible = false;' 'page'
        Assert-Value (Get-Result).Diagnostics.Count 1
        Set-Caller 'Extensible = true;' 'page'
        Assert-Value (Get-Result).Diagnostics.Count 1
        Set-Caller 'Extensible = false;' 'page'
        Assert-Value (Get-Result).Diagnostics.Count 0
    }

    It 'does not accept conditionally supplied required properties' {
        Set-Policy (New-Rule 'properties' @{ from = @{ paths = @('Consumers/*'); kinds = @('codeunit') }; properties = @{ Access = 'Internal' } })
        Set-Caller "#if FEATURE`nAccess = Internal;`n#endif"
        Assert-Value (Get-Result).Diagnostics.Count 1
        Set-File 'Consumers/Caller.al' "namespace Demo;`n#if DEVELOPMENT`ncodeunit 50104 Caller`n{ Access = Internal; }`n#endif"
        Assert-Value (Get-Result).Diagnostics.Count 0
    }

    It 'rejects Access and Extensible policies applied to unsupported kinds' {
        Set-Policy (New-Rule 'properties' @{ from = @{ paths = @('Consumers/*'); kinds = @('page') }; properties = @{ Access = 'Internal' } })
        Assert-Failure { Get-Result } 'supported object kinds'
        Set-Policy (New-Rule 'properties' @{ properties = @{ Extensible = $false } })
        Assert-Failure { Get-Result } 'supported object kinds'
    }

    It 'pins explicit temporary table and page projection properties' {
        Set-Policy (New-Rule 'properties' @{ properties = @{ TableType = 'Temporary' } })
        Set-Caller 'TableType = Temporary;' 'table'
        Assert-Value (Get-Result).Diagnostics.Count 0
        Set-Policy (New-Rule 'properties' @{ properties = @{ SourceTableTemporary = $true } })
        Set-Caller 'SourceTableTemporary = false;' 'page'
        Assert-Value (Get-Result).Diagnostics.Count 1
    }

    It 'checks forbidden calls without mistaking comments, strings or methods for built-ins' {
        Set-Policy (New-Rule 'forbiddenCode' @{ pattern = '(?<![\w.])(?:Database\s*\.\s*)?Commit\s*\(' })
        Set-Caller 'procedure P() begin MyObject.Commit(); Use(''Commit()''); end; // Commit();'
        Assert-Value (Get-Result).Diagnostics.Count 0
        Set-Caller "procedure P() begin`nCommit(); Database.Commit();`nend;"
        Assert-Value (Get-Result).Diagnostics.Count 2
    }

    It 'requires the entire development object to be inside its guard' {
        Set-Policy (New-Rule 'developmentOnly' @{ symbol = 'DEVELOPMENT' })
        Set-Caller ''
        Assert-Value (Get-Result).Diagnostics.Count 1
        Set-File 'Consumers/Caller.al' "// header`n#if DEVELOPMENT`nnamespace Demo;`ncodeunit 50104 Caller`n{ }`n#endif // end"
        Assert-Value (Get-Result).Diagnostics.Count 0
    }

    It 'rejects outer else branches, missing endif and code after a development guard' {
        Set-Policy (New-Rule 'developmentOnly' @{ symbol = 'DEVELOPMENT' })
        foreach ($suffix in @("#else`n#endif", '', "#endif`nvar R: Integer;")) {
            Set-File 'Consumers/Caller.al' "#if DEVELOPMENT`nnamespace Demo;`ncodeunit 50104 Caller`n{ }`n$suffix"
            Assert-Value (Get-Result).Diagnostics.Count 1
        }
    }

    It 'permits nested conditionals inside the whole-file development guard' {
        Set-Policy (New-Rule 'developmentOnly' @{ symbol = 'DEVELOPMENT' })
        Set-File 'Consumers/Caller.al' "#if DEVELOPMENT`nnamespace Demo;`ncodeunit 50104 Caller`n{`n#if FEATURE`nvar R: Integer;`n#else`nvar S: Integer;`n#endif`n}`n#endif"
        Assert-Value (Get-Result).Diagnostics.Count 0
    }

    It 'checks production symbols, friend IDs and forbidden dependency IDs/names in manifests' {
        Set-Policy (New-Rule 'manifest' @{ from = @{ paths = @('app.json') }; forbiddenSymbols = @('DEVELOPMENT'); allowedFriends = @('approved'); forbiddenDependencies = @('Tests-*', 'blocked-id') })
        Set-File 'app.json' '{"preprocessorSymbols":["DEVELOPMENT"],"internalsVisibleTo":[{"id":"other","name":"Other"}],"dependencies":[{"id":"x","name":"Tests-Toolkit"},{"id":"blocked-id","name":"Renamed"}]}'
        Assert-Value (Get-Result).Diagnostics.Count 4
        Set-File 'app.json' '{"internalsVisibleTo":[{"id":"approved","name":"Approved"}]}'
        Assert-Value (Get-Result).Diagnostics.Count 0
        Set-File 'app.json' '{}'
        Assert-Value (Get-Result).Diagnostics.Count 0
    }

    It 'enforces placement and namespace without git or a second checkout' {
        Set-Policy (New-Rule 'placement' @{ allowedPaths = @('Consumers/Caller.al'); namespace = 'Demo' })
        Assert-Value (Get-Result).Diagnostics.Count 0
        Set-Caller -Body '' -Kind 'codeunit' -Preamble 'namespace Other;'
        Assert-Value (Get-Result).Diagnostics.Count 1
        Set-Policy (New-Rule 'placement' @{ allowedPaths = @('Approved/*'); namespace = 'Other' })
        Assert-Value (Get-Result).Diagnostics.Count 1
    }

    It 'applies target-scoped reasoned exceptions and fails stale ones even on warning rules' {
        $rule.exceptions = @(@{ from = @{ paths = @('Consumers/Caller.al') }; target = 'Entities/Backing.Table.al'; reason = 'Approved projection.' })
        Set-Caller 'var R: Record Backing;'
        Set-Policy $rule
        Assert-Value (Get-Result).Diagnostics.Count 0
        Set-Caller ''
        $rule.severity = 'warning'
        Set-Policy $rule
        $result = Get-Result
        Assert-Value $result.Diagnostics.Count 1
        Assert-Value $result.Diagnostics[0].RuleId 'CONFIG'
        Assert-Value $result.Diagnostics[0].Severity 'error'
    }

    It 'does not let a table exception hide a dependency on the same-named codeunit' {
        $rule.to.paths = @('Entities/*')
        $rule.exceptions = @(@{ from = @{ paths = @('Consumers/*') }; target = 'Entities/Backing.Table.al'; reason = 'Storage only.' })
        Set-Caller 'var R: Record Backing; C: Codeunit Backing;'
        Set-Policy $rule
        Assert-Value (Get-Result).Diagnostics.Count 1
    }

    It 'rejects malformed configuration, old catalogs, empty selectors and unused rule fields' {
        Set-Content -LiteralPath $layout.Rules -Value '{invalid' -Encoding UTF8
        Assert-Failure { Get-Result }
        foreach ($invalid in @(
            @{ version = 2; rules = @($rule); catalogs = @() },
            @{ version = 1; rules = @($rule) },
            @{ version = 2; rules = @((New-Rule 'dependencies' @{ to = @{ paths = @() } })) },
            @{ version = 2; rules = @((New-Rule 'dependencies' @{ to = @{ paths = @('Entities/*') }; includeTemporary = $false })) },
            @{ version = 2; rules = @((New-Rule 'namespaces' @{ namespaces = @('External'); symbols = @(@{kind='table';name='X'}) })) }
        )) {
            $invalid | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $layout.Rules -Encoding UTF8
            Assert-Failure { Get-Result }
        }
    }

    It 'rejects property values the textual checker cannot interpret' {
        foreach ($value in @(1.5, 'Temporary::Value', 'a quoted caption')) {
            Set-Policy (New-Rule 'properties' @{ properties = @{ TableType = $value } })
            Assert-Failure { Get-Result }
        }
    }

    It 'rejects duplicate IDs, invalid regexes, path traversal and missing source/target paths' {
        @{version=2;rules=@($rule,$rule)} | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $layout.Rules
        Assert-Failure { Get-Result } 'Duplicate rule ID'
        Set-Policy (New-Rule 'forbiddenCode' @{ pattern = '[' })
        Assert-Failure { Get-Result }
        $rule.from.paths = @('../Consumers/*')
        Set-Policy $rule
        Assert-Failure { Get-Result }
        $rule.from.paths = @('Removed/*')
        Set-Policy $rule
        Assert-Failure { Get-Result } 'source selector matches no files'
        $rule.from.paths = @('Consumers/*')
        $rule.to.paths = @('Removed/*')
        Set-Policy $rule
        Assert-Failure { Get-Result } 'target selector matches no objects'
    }

    It 'fails if an AL file has no conventionally readable object identity' {
        Set-File 'Consumers/Caller.al' 'not an object'
        Assert-Failure { Get-Result } 'expected one object identity'
    }

    It 'runner fails errors and optionally promotes warnings, with usable annotations and PassThru' {
        Set-Caller 'var R: Record Backing;'
        Assert-Failure { & $script:runner -AppRoot $layout.App -RulesPath $layout.Rules *> $null } 'architecture checks failed'
        $rule.severity = 'warning'
        Set-Policy $rule
        $result = & $script:runner -AppRoot $layout.App -RulesPath $layout.Rules -PassThru 6> $null
        Assert-Value $result.Diagnostics.Count 1
        Assert-Failure { & $script:runner -AppRoot $layout.App -RulesPath $layout.Rules -WarningsAsErrors *> $null } 'architecture checks failed'
        $previous = $env:GITHUB_ACTIONS
        try {
            $env:GITHUB_ACTIONS = 'true'
            $output = (& $script:runner -AppRoot $layout.App -RulesPath $layout.Rules 6>&1 | Out-String)
            if ($output -notmatch '::warning file=.*line=4::TEST:') { throw "Missing annotation: $output" }
        } finally { $env:GITHUB_ACTIONS = $previous }
    }

    It 'keeps both CI hooks on the checked-out runner under PowerShell 7 before build cache decisions' {
        $repo = Join-Path $PSScriptRoot '../../..'
        foreach ($workflow in @('PullRequestHandler.yaml', '_BuildALGoProject.yaml')) {
            $text = [IO.File]::ReadAllText((Join-Path $repo ".github/workflows/$workflow"))
            if ($text -notmatch '(?m)- name: Validate Payables Agent architecture\r?\n\s+shell: pwsh') { throw "Missing pwsh gate in $workflow" }
            if (-not $text.Contains('run: ./build/scripts/Test-PayablesAgentArchitecture.ps1')) { throw "Missing checked-out runner in $workflow" }
            if ($workflow -eq 'PullRequestHandler.yaml') {
                if (-not $text.Contains('Invoke-Pester -Script $testFiles.FullName -PassThru')) { throw 'PR validation must test the checker itself using the shared runner pattern.' }
                if (-not $text.Contains('$result.TotalCount -eq 0 -or $result.FailedCount -gt 0')) { throw 'PR validation must fail on failed or undiscovered tests.' }
            }
            if ($workflow -eq '_BuildALGoProject.yaml' -and $text.IndexOf('Validate Payables Agent architecture') -gt $text.IndexOf('- name: Read settings')) { throw 'Architecture gate must precede settings/cache decisions.' }
        }
    }

    It 'blocks concrete policy violations in a source-only copy of the app' {
        $sourceRoot = (Get-Item -LiteralPath $script:paApp).FullName
        foreach ($file in Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Filter '*.al') {
            Set-File $file.FullName.Substring($sourceRoot.Length + 1) ([IO.File]::ReadAllText($file.FullName))
        }
        foreach ($name in @('app.json', 'architecture-rules.json')) {
            Copy-Item -LiteralPath (Join-Path $sourceRoot $name) -Destination (Join-Path $layout.App $name)
        }
        $layout.Rules = Join-Path $layout.App 'architecture-rules.json'
        Set-File 'Entities/Task/BadOwner.Codeunit.al' @'
namespace Microsoft.Agent.PayablesAgent;
using Microsoft.eServices.EDocument.Processing.Import;
codeunit 50120 "Bad Owner"
{
    Access = Internal;
    var
        Fixtures: Codeunit "PA Test Fixtures";
        VendorPage: Page "Vendor Card";
    procedure P()
    begin
        Commit();
        Message('Interactive UI');
        Session.LogMessage('event');
    end;
}
'@
        Set-File '_Development/Unguarded.Codeunit.al' "namespace Microsoft.Agent.PayablesAgent;`ncodeunit 50121 Unguarded`n{ Access = Internal; }"
        Set-File '_Obsolete/New.Page.al' "namespace Microsoft.Agent.PayablesAgent;`npage 50122 NewPage`n{ Extensible = false; }"
        Set-File 'Flows/Supervision/Missing.Table.al' "namespace Microsoft.Agent.PayablesAgent;`ntable 50123 Missing`n{ }"
        $ids = @((Get-Result).Diagnostics | ForEach-Object RuleId)
        foreach ($id in @('PA003', 'PA009', 'PA010', 'PA011', 'PA012', 'PA013', 'PA015', 'PA016', 'PA019')) {
            if ($id -notin $ids) { throw "Concrete policy failed to detect $id" }
        }
        if ('CONFIG' -in $ids) { throw 'Copying source should not invalidate existing exceptions.' }
    }

    It 'validates the actual app without errors or stale exceptions' {
        $result = Invoke-ALArchitectureRules -AppRoot $script:paApp -RulesPath (Join-Path $script:paApp 'architecture-rules.json')
        $errors = @($result.Diagnostics | Where-Object Severity -eq 'error')
        if ($errors.Count) { throw ($errors | ForEach-Object Message | Out-String) }
        if ($result.RuleCount -lt 21 -or $result.ObjectCount -lt 100) { throw 'App policy scan was unexpectedly incomplete.' }
    }
}
