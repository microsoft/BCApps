// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Purchases.Vendor;

codeunit 46905 "BC14 Vend. Post. Grp. Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Vendor Posting Group";

    trigger OnRun()
    begin
        MigrateVendorPostingGroup(Rec);
    end;

    var
        MigratorNameLbl: Label 'Vendor Posting Group Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Vendor Posting Group", Database::"BC14 Vendor Posting Group");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14VendorPostingGroup: Record "BC14 Vendor Posting Group";
    begin
        exit(not BC14VendorPostingGroup.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14VendorPostingGroup: Record "BC14 Vendor Posting Group";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14VendorPostingGroup;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Vend. Post. Grp. Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14VendorPostingGroup: Record "BC14 Vendor Posting Group";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Vendor Posting Group", BC14VendorPostingGroup.Count()));
    end;

    internal procedure MigrateVendorPostingGroup(BC14VendorPostingGroup: Record "BC14 Vendor Posting Group")
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateVendorPostingGroup(BC14VendorPostingGroup, IsMigrated);
        if IsMigrated then
            exit;

        if VendorPostingGroup.Get(BC14VendorPostingGroup.Code) then begin
            TransferFields(BC14VendorPostingGroup, VendorPostingGroup);
            VendorPostingGroup.Modify();
        end else begin
            VendorPostingGroup.Init();
            TransferFields(BC14VendorPostingGroup, VendorPostingGroup);
            VendorPostingGroup.Insert();
        end;

        OnAfterMigrateVendorPostingGroup(BC14VendorPostingGroup, VendorPostingGroup);
    end;

    local procedure TransferFields(BC14VendorPostingGroup: Record "BC14 Vendor Posting Group"; var VendorPostingGroup: Record "Vendor Posting Group")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        VendorPostingGroup.Code := BC14VendorPostingGroup.Code;

        // G/L Account FK fields: direct assignment. Vendor Posting Group runs in the Setup phase,
        // before G/L Account is migrated in the Master phase, so Validate's TableRelation check would
        // always fail on a freshly-created target company. Accounts are verified lazily when posted.
        VendorPostingGroup."Payables Account" := BC14VendorPostingGroup."Payables Account";
        VendorPostingGroup."Service Charge Acc." := BC14VendorPostingGroup."Service Charge Acc.";
        VendorPostingGroup."Payment Disc. Debit Acc." := BC14VendorPostingGroup."Payment Disc. Debit Acc.";
        VendorPostingGroup."Invoice Rounding Account" := BC14VendorPostingGroup."Invoice Rounding Account";
        VendorPostingGroup."Debit Curr. Appln. Rndg. Acc." := BC14VendorPostingGroup."Debit Curr. Appln. Rndg. Acc.";
        VendorPostingGroup."Credit Curr. Appln. Rndg. Acc." := BC14VendorPostingGroup."Credit Curr. Appln. Rndg. Acc.";
        VendorPostingGroup."Debit Rounding Account" := BC14VendorPostingGroup."Debit Rounding Account";
        VendorPostingGroup."Credit Rounding Account" := BC14VendorPostingGroup."Credit Rounding Account";
        VendorPostingGroup."Payment Disc. Credit Acc." := BC14VendorPostingGroup."Payment Disc. Credit Acc.";
        VendorPostingGroup."Payment Tolerance Debit Acc." := BC14VendorPostingGroup."Payment Tolerance Debit Acc.";
        VendorPostingGroup."Payment Tolerance Credit Acc." := BC14VendorPostingGroup."Payment Tolerance Credit Acc.";
        VendorPostingGroup.Description := BC14VendorPostingGroup.Description;

        OnTransferVendorPostingGroupCustomFields(BC14VendorPostingGroup, VendorPostingGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateVendorPostingGroup(BC14VendorPostingGroup: Record "BC14 Vendor Posting Group"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateVendorPostingGroup(BC14VendorPostingGroup: Record "BC14 Vendor Posting Group"; var VendorPostingGroup: Record "Vendor Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferVendorPostingGroupCustomFields(BC14VendorPostingGroup: Record "BC14 Vendor Posting Group"; var VendorPostingGroup: Record "Vendor Posting Group")
    begin
    end;
}

