// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Sales.Reminder;

codeunit 46925 "BC14 Reminder Terms Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Reminder Terms";

    trigger OnRun()
    begin
        MigrateReminderTerms(Rec);
    end;

    var
        MigratorNameLbl: Label 'Reminder Terms Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Reminder Terms", Database::"BC14 Reminder Terms");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14ReminderTerms: Record "BC14 Reminder Terms";
    begin
        exit(not BC14ReminderTerms.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14ReminderTerms: Record "BC14 Reminder Terms";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14ReminderTerms;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Reminder Terms Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14ReminderTerms: Record "BC14 Reminder Terms";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Reminder Terms", BC14ReminderTerms.Count()));
    end;

    internal procedure MigrateReminderTerms(BC14ReminderTerms: Record "BC14 Reminder Terms")
    var
        ReminderTerms: Record "Reminder Terms";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateReminderTerms(BC14ReminderTerms, IsMigrated);
        if IsMigrated then
            exit;

        if ReminderTerms.Get(BC14ReminderTerms.Code) then begin
            TransferFields(BC14ReminderTerms, ReminderTerms);
            ReminderTerms.Modify();
        end else begin
            ReminderTerms.Init();
            TransferFields(BC14ReminderTerms, ReminderTerms);
            ReminderTerms.Insert();
        end;

        OnAfterMigrateReminderTerms(BC14ReminderTerms, ReminderTerms);
    end;

    local procedure TransferFields(BC14ReminderTerms: Record "BC14 Reminder Terms"; var ReminderTerms: Record "Reminder Terms")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        ReminderTerms.Code := BC14ReminderTerms.Code;

        // Use Validate so any OnValidate business logic runs.
        ReminderTerms.Validate(Description, BC14ReminderTerms.Description);
        ReminderTerms.Validate("Max. No. of Reminders", BC14ReminderTerms."Max. No. of Reminders");
        ReminderTerms.Validate("Post Interest", BC14ReminderTerms."Post Interest");
        ReminderTerms.Validate("Post Additional Fee", BC14ReminderTerms."Post Additional Fee");
        ReminderTerms.Validate("Minimum Amount (LCY)", BC14ReminderTerms."Minimum Amount (LCY)");
        ReminderTerms.Validate("Post Add. Fee per Line", BC14ReminderTerms."Post Add. Fee per Line");

        OnTransferReminderTermsCustomFields(BC14ReminderTerms, ReminderTerms);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateReminderTerms(BC14ReminderTerms: Record "BC14 Reminder Terms"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateReminderTerms(BC14ReminderTerms: Record "BC14 Reminder Terms"; var ReminderTerms: Record "Reminder Terms")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferReminderTermsCustomFields(BC14ReminderTerms: Record "BC14 Reminder Terms"; var ReminderTerms: Record "Reminder Terms")
    begin
    end;
}

