// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.GeneralLedger.Setup;

codeunit 46907 "BC14 GenProd PG Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Gen. Prod. Posting Group";

    trigger OnRun()
    begin
        MigrateGenProdPostingGroup(Rec);
    end;

    var
        MigratorNameLbl: Label 'Gen. Prod. Posting Group Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Gen. Product Posting Group", Database::"BC14 Gen. Prod. Posting Group");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14GenProdPostingGroup: Record "BC14 Gen. Prod. Posting Group";
    begin
        exit(not BC14GenProdPostingGroup.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14GenProdPostingGroup: Record "BC14 Gen. Prod. Posting Group";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14GenProdPostingGroup;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 GenProd PG Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14GenProdPostingGroup: Record "BC14 Gen. Prod. Posting Group";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Gen. Prod. Posting Group", BC14GenProdPostingGroup.Count()));
    end;

    internal procedure MigrateGenProdPostingGroup(BC14GenProdPostingGroup: Record "BC14 Gen. Prod. Posting Group")
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateGenProdPostingGroup(BC14GenProdPostingGroup, IsMigrated);
        if IsMigrated then
            exit;

        if GenProdPostingGroup.Get(BC14GenProdPostingGroup.Code) then begin
            TransferFields(BC14GenProdPostingGroup, GenProdPostingGroup);
            GenProdPostingGroup.Modify();
        end else begin
            GenProdPostingGroup.Init();
            TransferFields(BC14GenProdPostingGroup, GenProdPostingGroup);
            GenProdPostingGroup.Insert();
        end;

        OnAfterMigrateGenProdPostingGroup(BC14GenProdPostingGroup, GenProdPostingGroup);
    end;

    local procedure TransferFields(BC14GenProdPostingGroup: Record "BC14 Gen. Prod. Posting Group"; var GenProdPostingGroup: Record "Gen. Product Posting Group")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        GenProdPostingGroup.Code := BC14GenProdPostingGroup.Code;

        // Use Validate so any OnValidate business logic runs.
        GenProdPostingGroup.Validate(Description, BC14GenProdPostingGroup.Description);
        GenProdPostingGroup.Validate("Def. VAT Prod. Posting Group", BC14GenProdPostingGroup."Def. VAT Prod. Posting Group");
        GenProdPostingGroup.Validate("Auto Insert Default", BC14GenProdPostingGroup."Auto Insert Default");

        OnTransferGenProdPostingGroupCustomFields(BC14GenProdPostingGroup, GenProdPostingGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateGenProdPostingGroup(BC14GenProdPostingGroup: Record "BC14 Gen. Prod. Posting Group"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateGenProdPostingGroup(BC14GenProdPostingGroup: Record "BC14 Gen. Prod. Posting Group"; var GenProdPostingGroup: Record "Gen. Product Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferGenProdPostingGroupCustomFields(BC14GenProdPostingGroup: Record "BC14 Gen. Prod. Posting Group"; var GenProdPostingGroup: Record "Gen. Product Posting Group")
    begin
    end;
}

