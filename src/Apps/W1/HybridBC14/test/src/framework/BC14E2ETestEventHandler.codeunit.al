// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

codeunit 148902 "BC14 E2E Test Event Handler"
{
    EventSubscriberInstance = Manual;

    var
        InjectErrorOnMigrator: Text[250];
        ErrorInjectionEnabled: Boolean;
        MigratorCompletedList: List of [Text[250]];
        ForceSkipAllMigrators: Boolean;

    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Configures error injection for a specific migrator.
    /// When the runner encounters this migrator, it will be skipped and an error logged.
    /// </summary>
    procedure SetErrorInjection(MigratorName: Text[250]; RecordKey: Text[250]; ErrorMessage: Text)
    begin
        InjectErrorOnMigrator := MigratorName;
        ErrorInjectionEnabled := true;
    end;

    /// <summary>
    /// Clears any configured error injection.
    /// </summary>
    procedure ClearErrorInjection()
    begin
        InjectErrorOnMigrator := '';
        ErrorInjectionEnabled := false;
    end;

    /// <summary>
    /// Returns true if error injection is currently enabled.
    /// </summary>
    procedure IsErrorInjectionEnabled(): Boolean
    begin
        exit(ErrorInjectionEnabled);
    end;

    /// <summary>
    /// Resets all state for a new test.
    /// </summary>
    procedure Reset()
    begin
        ClearErrorInjection();
        Clear(MigratorCompletedList);
    end;

    /// <summary>
    /// When enabled, all migrators are skipped without logging errors.
    /// Used to simulate successful retry when actual migration cannot execute in test context.
    /// </summary>
    procedure SetForceSkipAllMigrators(Skip: Boolean)
    begin
        ForceSkipAllMigrators := Skip;
    end;

    /// <summary>
    /// Returns true if the specified migrator has completed.
    /// </summary>
    procedure HasMigratorCompleted(MigratorName: Text[250]): Boolean
    begin
        exit(MigratorCompletedList.Contains(MigratorName));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Migration Orchestrator", 'OnBeforeScheduleTask', '', false, false)]
    local procedure HandleOnBeforeScheduleTask(CodeunitId: Integer; var RunSynchronously: Boolean)
    begin
        RunSynchronously := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Migration Runner", 'OnBeforeRunMigrator', '', false, false)]
    local procedure HandleOnBeforeRunMigrator(MigratorName: Text[250]; var SkipMigrator: Boolean)
    var
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecId: RecordId;
    begin
        if ForceSkipAllMigrators then begin
            SkipMigrator := true;
            exit;
        end;

        if not ErrorInjectionEnabled then
            exit;

        if MigratorName <> InjectErrorOnMigrator then
            exit;

        // Log error and skip the migrator to simulate a migration failure
        BC14MigrationErrorHandler.LogError(
            MigratorName,
            0,
            MigratorName,
            '',
            0,
            'Injected test error',
            DummyRecId);

        SkipMigrator := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Migration Runner", 'OnAfterRunMigrator', '', false, false)]
    local procedure HandleOnAfterRunMigrator(MigratorName: Text[250]; Success: Boolean; RemainingPercentage: Integer)
    begin
        if not MigratorCompletedList.Contains(MigratorName) then
            MigratorCompletedList.Add(MigratorName);
    end;
}
