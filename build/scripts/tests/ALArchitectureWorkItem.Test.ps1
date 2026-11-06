# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

#Requires -Version 7.0
Describe 'Payables Agent Work Item API boundary' {
    BeforeEach {
        Import-Module (Join-Path $PSScriptRoot '../ALArchitectureRules.psm1') -Force
        $script:app = Join-Path $PSScriptRoot '../../../src/Apps/W1/PayablesAgent/app'
        $script:schema = Join-Path $app 'architecture-rules.schema.json'
        $script:policy = Get-Content -LiteralPath (Join-Path $app 'architecture-rules.json') -Raw | ConvertFrom-Json -AsHashtable
        $script:root = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
        $script:entityPath = Join-Path $root 'Entities/WorkItem/PAWorkItem.Codeunit.al'
        New-Item -ItemType Directory -Path (Split-Path $entityPath) -Force | Out-Null
        Copy-Item (Join-Path $app 'Entities/WorkItem/PAWorkItem.Codeunit.al') $entityPath
        $selected = @{ version = $policy.version; rules = @($policy.rules | Where-Object { $_.id -in 'PA024', 'PA025' }) }
        $script:rulesPath = Join-Path $root 'rules.json'
        $selected | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $rulesPath -Encoding UTF8
        # Both exact exceptions remain exercised; stale exceptions must fail rather than become blanket permission.
        foreach ($approved in @('Shared/Telemetry/PATelemetry.Codeunit.al', 'TestSupport/PATestFixtures.Codeunit.al')) {
            $path = Join-Path $root $approved
            New-Item -ItemType Directory -Path (Split-Path $path) -Force | Out-Null
            $id = if ($approved.StartsWith('Shared')) { 50101 } else { 50102 }
            Set-Content -LiteralPath $path -Encoding UTF8 -Value "namespace Microsoft.Agent.PayablesAgent;`ncodeunit $id Approved$id`n{`n    var Versions: Codeunit `"PA V1V2 Flag`"; WorkItemId: Guid;`n    procedure P()`n    begin`n        Versions.GetVersion(WorkItemId);`n    end;`n}"
        }
        $script:callerPath = Join-Path $root 'Flows/Supervision/Caller.Codeunit.al'
        New-Item -ItemType Directory -Path (Split-Path $callerPath) -Force | Out-Null
    }

    It 'allows the approved entity surface and supported-operation consumers' {
        Set-Content -LiteralPath $callerPath -Encoding UTF8 -Value @'
namespace Microsoft.Agent.PayablesAgent;
codeunit 50103 Caller
{
    var WorkItem: Codeunit "PA Work Item";
    procedure P()
    begin
        if WorkItem.CanExtractText() then;
    end;
}
'@
        $result = Invoke-ALArchitectureRules -AppRoot $root -RulesPath $rulesPath -SchemaPath $schema
        if ($result.Diagnostics.Count -ne 0) { throw 'Approved Work Item usage must pass the boundary.' }
    }

    It 'blocks ordinary consumers from calling version lookup, including quoted member syntax' {
        foreach ($member in @('GetVersion', '"GetVersion"')) {
            Set-Content -LiteralPath $callerPath -Encoding UTF8 -Value "namespace Microsoft.Agent.PayablesAgent;`ncodeunit 50103 Caller`n{`n    var Versions: Codeunit `"PA V1V2 Flag`"; WorkItemId: Guid;`n    procedure P()`n    begin`n        Versions.$member(WorkItemId);`n    end;`n}"
            $result = Invoke-ALArchitectureRules -AppRoot $root -RulesPath $rulesPath -SchemaPath $schema
            if (@($result.Diagnostics | Where-Object RuleId -eq 'PA024').Count -ne 1) { throw 'Raw version lookup must remain restricted independently of active-flag selection.' }
        }
    }

    It 'blocks reintroducing a version alias as a new entity API member' {
        $source = Get-Content -LiteralPath $entityPath -Raw
        $source = $source.Insert($source.LastIndexOf('}'), "    internal procedure GetVersionText(): Text`n    begin`n        exit('V2');`n    end;`n")
        Set-Content -LiteralPath $entityPath -Value $source -Encoding UTF8
        $result = Invoke-ALArchitectureRules -AppRoot $root -RulesPath $rulesPath -SchemaPath $schema
        if (@($result.Diagnostics | Where-Object RuleId -eq 'PA025').Count -ne 1) { throw 'Adding a text-valued version getter must require an explicit API contract change.' }
    }

    It 'blocks changing an existing exported signature without contract review' {
        $source = Get-Content -LiteralPath $entityPath -Raw
        $source = $source.Replace('internal procedure GetTitle(): Text[150]', 'internal procedure GetTitle(): Text')
        Set-Content -LiteralPath $entityPath -Value $source -Encoding UTF8
        $result = Invoke-ALArchitectureRules -AppRoot $root -RulesPath $rulesPath -SchemaPath $schema
        if (@($result.Diagnostics | Where-Object RuleId -eq 'PA025').Count -ne 1) { throw 'The gate must pin signatures, not just procedure names.' }
    }

    It 'fails closed for multiline declarations outside the explicit one-line contract' {
        $source = Get-Content -LiteralPath $entityPath -Raw
        $source = $source.Replace('internal procedure GetId(): Guid', "internal procedure GetId(`n    ): Guid")
        Set-Content -LiteralPath $entityPath -Value $source -Encoding UTF8
        $result = Invoke-ALArchitectureRules -AppRoot $root -RulesPath $rulesPath -SchemaPath $schema
        if (@($result.Diagnostics | Where-Object RuleId -eq 'PA025').Count -ne 1) { throw 'Formatting must not bypass the entity API boundary.' }
    }
}
