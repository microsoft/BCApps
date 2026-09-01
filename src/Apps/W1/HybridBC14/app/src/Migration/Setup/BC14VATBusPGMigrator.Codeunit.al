// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.VAT.Setup;

codeunit 46908 "BC14 VATBus PG Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 VAT Bus. Posting Group";

    trigger OnRun()
    begin
        MigrateVATBusPostingGroup(Rec);
    end;

    var
        MigratorNameLbl: Label 'VAT Bus. Posting Group Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"VAT Business Posting Group", Database::"BC14 VAT Bus. Posting Group");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14VATBusPostingGroup: Record "BC14 VAT Bus. Posting Group";
    begin
        exit(not BC14VATBusPostingGroup.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14VATBusPostingGroup: Record "BC14 VAT Bus. Posting Group";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14VATBusPostingGroup;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 VATBus PG Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14VATBusPostingGroup: Record "BC14 VAT Bus. Posting Group";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 VAT Bus. Posting Group", BC14VATBusPostingGroup.Count()));
    end;

    internal procedure MigrateVATBusPostingGroup(BC14VATBusPostingGroup: Record "BC14 VAT Bus. Posting Group")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateVATBusPostingGroup(BC14VATBusPostingGroup, IsMigrated);
        if IsMigrated then
            exit;

        if VATBusPostingGroup.Get(BC14VATBusPostingGroup.Code) then begin
            TransferFields(BC14VATBusPostingGroup, VATBusPostingGroup);
            VATBusPostingGroup.Modify();
        end else begin
            VATBusPostingGroup.Init();
            TransferFields(BC14VATBusPostingGroup, VATBusPostingGroup);
            VATBusPostingGroup.Insert();
        end;

        OnAfterMigrateVATBusPostingGroup(BC14VATBusPostingGroup, VATBusPostingGroup);
    end;

    local procedure TransferFields(BC14VATBusPostingGroup: Record "BC14 VAT Bus. Posting Group"; var VATBusPostingGroup: Record "VAT Business Posting Group")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        VATBusPostingGroup.Code := BC14VATBusPostingGroup.Code;

        // Use Validate so any OnValidate business logic runs.
        VATBusPostingGroup.Validate(Description, BC14VATBusPostingGroup.Description);

        OnTransferVATBusPostingGroupCustomFields(BC14VATBusPostingGroup, VATBusPostingGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateVATBusPostingGroup(BC14VATBusPostingGroup: Record "BC14 VAT Bus. Posting Group"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateVATBusPostingGroup(BC14VATBusPostingGroup: Record "BC14 VAT Bus. Posting Group"; var VATBusPostingGroup: Record "VAT Business Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferVATBusPostingGroupCustomFields(BC14VATBusPostingGroup: Record "BC14 VAT Bus. Posting Group"; var VATBusPostingGroup: Record "VAT Business Posting Group")
    begin
    end;
}

