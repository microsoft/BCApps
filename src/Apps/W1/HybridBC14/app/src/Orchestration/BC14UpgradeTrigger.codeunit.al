// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

/// <summary>
/// Webhook-safe entry point for triggering an upgrade. Runs via Codeunit.Run so failures
/// during Insert/Modify/CreateTask are captured (GetLastErrorText) without bubbling up as
/// HTTP 500 on the replication-completed webhook. TryFunction is not an option because the
/// wrapped logic issues explicit Commit calls.
/// </summary>
codeunit 46856 "BC14 Upgrade Trigger"
{
    Access = Internal;

    var
        RunId: Text[50];

    procedure SetRunId(NewRunId: Text[50])
    begin
        RunId := NewRunId;
    end;

    trigger OnRun()
    var
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
    begin
        BC14MigrationOrchestrator.TriggerUpgradeIfOneStepEnabled(RunId);
    end;
}
