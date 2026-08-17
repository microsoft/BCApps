// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Sales.Reminder;

codeunit 46927 "BC14 Reminder Text Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Reminder Text";

    trigger OnRun()
    begin
        MigrateReminderText(Rec);
    end;

    var
        MigratorNameLbl: Label 'Reminder Text Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Reminder Text", Database::"BC14 Reminder Text");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14ReminderText: Record "BC14 Reminder Text";
    begin
        exit(not BC14ReminderText.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14ReminderText: Record "BC14 Reminder Text";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14ReminderText;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Reminder Text Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14ReminderText: Record "BC14 Reminder Text";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Reminder Text", BC14ReminderText.Count()));
    end;

    internal procedure MigrateReminderText(BC14ReminderText: Record "BC14 Reminder Text")
    var
        ReminderText: Record "Reminder Text";
        ReminderTextPosition: Enum "Reminder Text Position";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateReminderText(BC14ReminderText, IsMigrated);
        if IsMigrated then
            exit;

        ReminderTextPosition := Enum::"Reminder Text Position".FromInteger(BC14ReminderText.Position);
        if ReminderText.Get(BC14ReminderText."Reminder Terms Code", BC14ReminderText."Reminder Level", ReminderTextPosition, BC14ReminderText."Line No.") then begin
            TransferFields(BC14ReminderText, ReminderText);
            ReminderText.Modify();
        end else begin
            ReminderText.Init();
            TransferFields(BC14ReminderText, ReminderText);
            ReminderText.Insert();
        end;

        OnAfterMigrateReminderText(BC14ReminderText, ReminderText);
    end;

    local procedure TransferFields(BC14ReminderText: Record "BC14 Reminder Text"; var ReminderText: Record "Reminder Text")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        ReminderText."Reminder Terms Code" := BC14ReminderText."Reminder Terms Code";
        ReminderText."Reminder Level" := BC14ReminderText."Reminder Level";
        // Position is part of the primary key; use Validate to handle the Option-to-Enum conversion.
        ReminderText.Validate(Position, BC14ReminderText.Position);
        ReminderText."Line No." := BC14ReminderText."Line No.";

        // Use Validate so any OnValidate business logic runs.
        ReminderText.Validate(Text, BC14ReminderText.Text);

        OnTransferReminderTextCustomFields(BC14ReminderText, ReminderText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateReminderText(BC14ReminderText: Record "BC14 Reminder Text"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateReminderText(BC14ReminderText: Record "BC14 Reminder Text"; var ReminderText: Record "Reminder Text")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferReminderTextCustomFields(BC14ReminderText: Record "BC14 Reminder Text"; var ReminderText: Record "Reminder Text")
    begin
    end;
}

