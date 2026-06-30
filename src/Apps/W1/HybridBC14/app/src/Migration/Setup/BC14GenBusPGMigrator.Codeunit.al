// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.GeneralLedger.Setup;

codeunit 46906 "BC14 GenBus PG Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Gen. Bus. Posting Group";

    trigger OnRun()
    begin
        MigrateGenBusPostingGroup(Rec);
    end;

    var
        MigratorNameLbl: Label 'Gen. Bus. Posting Group Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Gen. Business Posting Group", Database::"BC14 Gen. Bus. Posting Group");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14GenBusPostingGroup: Record "BC14 Gen. Bus. Posting Group";
    begin
        exit(not BC14GenBusPostingGroup.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14GenBusPostingGroup: Record "BC14 Gen. Bus. Posting Group";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14GenBusPostingGroup;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 GenBus PG Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14GenBusPostingGroup: Record "BC14 Gen. Bus. Posting Group";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Gen. Bus. Posting Group", BC14GenBusPostingGroup.Count()));
    end;

    internal procedure MigrateGenBusPostingGroup(BC14GenBusPostingGroup: Record "BC14 Gen. Bus. Posting Group")
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateGenBusPostingGroup(BC14GenBusPostingGroup, IsMigrated);
        if IsMigrated then
            exit;

        if GenBusPostingGroup.Get(BC14GenBusPostingGroup.Code) then begin
            TransferFields(BC14GenBusPostingGroup, GenBusPostingGroup);
            GenBusPostingGroup.Modify();
        end else begin
            GenBusPostingGroup.Init();
            TransferFields(BC14GenBusPostingGroup, GenBusPostingGroup);
            GenBusPostingGroup.Insert();
        end;

        OnAfterMigrateGenBusPostingGroup(BC14GenBusPostingGroup, GenBusPostingGroup);
    end;

    local procedure TransferFields(BC14GenBusPostingGroup: Record "BC14 Gen. Bus. Posting Group"; var GenBusPostingGroup: Record "Gen. Business Posting Group")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        GenBusPostingGroup.Code := BC14GenBusPostingGroup.Code;

        // Use Validate so any OnValidate business logic runs.
        GenBusPostingGroup.Validate(Description, BC14GenBusPostingGroup.Description);
        GenBusPostingGroup.Validate("Def. VAT Bus. Posting Group", BC14GenBusPostingGroup."Def. VAT Bus. Posting Group");
        GenBusPostingGroup.Validate("Auto Insert Default", BC14GenBusPostingGroup."Auto Insert Default");

        OnTransferGenBusPostingGroupCustomFields(BC14GenBusPostingGroup, GenBusPostingGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateGenBusPostingGroup(BC14GenBusPostingGroup: Record "BC14 Gen. Bus. Posting Group"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateGenBusPostingGroup(BC14GenBusPostingGroup: Record "BC14 Gen. Bus. Posting Group"; var GenBusPostingGroup: Record "Gen. Business Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferGenBusPostingGroupCustomFields(BC14GenBusPostingGroup: Record "BC14 Gen. Bus. Posting Group"; var GenBusPostingGroup: Record "Gen. Business Posting Group")
    begin
    end;
}

