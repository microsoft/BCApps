// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Sales.Reminder;

codeunit 46926 "BC14 Reminder Level Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Reminder Level";

    trigger OnRun()
    begin
        MigrateReminderLevel(Rec);
    end;

    var
        MigratorNameLbl: Label 'Reminder Level Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Reminder Level", Database::"BC14 Reminder Level");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14ReminderLevel: Record "BC14 Reminder Level";
    begin
        exit(not BC14ReminderLevel.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14ReminderLevel: Record "BC14 Reminder Level";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14ReminderLevel;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Reminder Level Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14ReminderLevel: Record "BC14 Reminder Level";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Reminder Level", BC14ReminderLevel.Count()));
    end;

    internal procedure MigrateReminderLevel(BC14ReminderLevel: Record "BC14 Reminder Level")
    var
        ReminderLevel: Record "Reminder Level";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateReminderLevel(BC14ReminderLevel, IsMigrated);
        if IsMigrated then
            exit;

        if ReminderLevel.Get(BC14ReminderLevel."Reminder Terms Code", BC14ReminderLevel."No.") then begin
            TransferFields(BC14ReminderLevel, ReminderLevel);
            ReminderLevel.Modify();
        end else begin
            ReminderLevel.Init();
            TransferFields(BC14ReminderLevel, ReminderLevel);
            ReminderLevel.Insert();
        end;

        OnAfterMigrateReminderLevel(BC14ReminderLevel, ReminderLevel);
    end;

    local procedure TransferFields(BC14ReminderLevel: Record "BC14 Reminder Level"; var ReminderLevel: Record "Reminder Level")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        ReminderLevel."Reminder Terms Code" := BC14ReminderLevel."Reminder Terms Code";
        ReminderLevel."No." := BC14ReminderLevel."No.";

        // Use Validate so any OnValidate business logic runs.
        ReminderLevel.Validate("Grace Period", BC14ReminderLevel."Grace Period");
        ReminderLevel.Validate("Due Date Calculation", BC14ReminderLevel."Due Date Calculation");
        ReminderLevel.Validate("Calculate Interest", BC14ReminderLevel."Calculate Interest");
        ReminderLevel.Validate("Additional Fee (LCY)", BC14ReminderLevel."Additional Fee (LCY)");
        ReminderLevel.Validate("Add. Fee per Line Amount (LCY)", BC14ReminderLevel."Add. Fee per Line Amount (LCY)");
        // Min/Max Amount of Add. Fee (LCY) fields are not present on the modern Reminder Level table.

        OnTransferReminderLevelCustomFields(BC14ReminderLevel, ReminderLevel);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateReminderLevel(BC14ReminderLevel: Record "BC14 Reminder Level"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateReminderLevel(BC14ReminderLevel: Record "BC14 Reminder Level"; var ReminderLevel: Record "Reminder Level")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferReminderLevelCustomFields(BC14ReminderLevel: Record "BC14 Reminder Level"; var ReminderLevel: Record "Reminder Level")
    begin
    end;
}

