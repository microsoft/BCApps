// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.VAT.Setup;

codeunit 46909 "BC14 VATProd PG Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 VAT Prod. Posting Group";

    trigger OnRun()
    begin
        MigrateVATProdPostingGroup(Rec);
    end;

    var
        MigratorNameLbl: Label 'VAT Prod. Posting Group Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"VAT Product Posting Group", Database::"BC14 VAT Prod. Posting Group");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14VATProdPostingGroup: Record "BC14 VAT Prod. Posting Group";
    begin
        exit(not BC14VATProdPostingGroup.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14VATProdPostingGroup: Record "BC14 VAT Prod. Posting Group";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14VATProdPostingGroup;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 VATProd PG Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14VATProdPostingGroup: Record "BC14 VAT Prod. Posting Group";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 VAT Prod. Posting Group", BC14VATProdPostingGroup.Count()));
    end;

    internal procedure MigrateVATProdPostingGroup(BC14VATProdPostingGroup: Record "BC14 VAT Prod. Posting Group")
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateVATProdPostingGroup(BC14VATProdPostingGroup, IsMigrated);
        if IsMigrated then
            exit;

        if VATProdPostingGroup.Get(BC14VATProdPostingGroup.Code) then begin
            TransferFields(BC14VATProdPostingGroup, VATProdPostingGroup);
            VATProdPostingGroup.Modify();
        end else begin
            VATProdPostingGroup.Init();
            TransferFields(BC14VATProdPostingGroup, VATProdPostingGroup);
            VATProdPostingGroup.Insert();
        end;

        OnAfterMigrateVATProdPostingGroup(BC14VATProdPostingGroup, VATProdPostingGroup);
    end;

    local procedure TransferFields(BC14VATProdPostingGroup: Record "BC14 VAT Prod. Posting Group"; var VATProdPostingGroup: Record "VAT Product Posting Group")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        VATProdPostingGroup.Code := BC14VATProdPostingGroup.Code;

        // Use Validate so any OnValidate business logic runs.
        VATProdPostingGroup.Validate(Description, BC14VATProdPostingGroup.Description);

        OnTransferVATProdPostingGroupCustomFields(BC14VATProdPostingGroup, VATProdPostingGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateVATProdPostingGroup(BC14VATProdPostingGroup: Record "BC14 VAT Prod. Posting Group"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateVATProdPostingGroup(BC14VATProdPostingGroup: Record "BC14 VAT Prod. Posting Group"; var VATProdPostingGroup: Record "VAT Product Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferVATProdPostingGroupCustomFields(BC14VATProdPostingGroup: Record "BC14 VAT Prod. Posting Group"; var VATProdPostingGroup: Record "VAT Product Posting Group")
    begin
    end;
}

