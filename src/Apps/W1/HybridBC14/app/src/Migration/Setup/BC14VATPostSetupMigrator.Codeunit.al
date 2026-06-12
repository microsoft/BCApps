// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.VAT.Setup;

codeunit 46911 "BC14 VAT Post. Setup Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 VAT Posting Setup";

    trigger OnRun()
    begin
        MigrateVATPostingSetup(Rec);
    end;

    var
        MigratorNameLbl: Label 'VAT Posting Setup Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"VAT Posting Setup", Database::"BC14 VAT Posting Setup");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14VATPostingSetup: Record "BC14 VAT Posting Setup";
    begin
        exit(not BC14VATPostingSetup.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14VATPostingSetup: Record "BC14 VAT Posting Setup";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14VATPostingSetup;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 VAT Post. Setup Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14VATPostingSetup: Record "BC14 VAT Posting Setup";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 VAT Posting Setup", BC14VATPostingSetup.Count()));
    end;

    internal procedure MigrateVATPostingSetup(BC14VATPostingSetup: Record "BC14 VAT Posting Setup")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateVATPostingSetup(BC14VATPostingSetup, IsMigrated);
        if IsMigrated then
            exit;

        if VATPostingSetup.Get(BC14VATPostingSetup."VAT Bus. Posting Group", BC14VATPostingSetup."VAT Prod. Posting Group") then begin
            TransferFields(BC14VATPostingSetup, VATPostingSetup);
            VATPostingSetup.Modify();
        end else begin
            VATPostingSetup.Init();
            TransferFields(BC14VATPostingSetup, VATPostingSetup);
            VATPostingSetup.Insert();
        end;

        OnAfterMigrateVATPostingSetup(BC14VATPostingSetup, VATPostingSetup);
    end;

    local procedure TransferFields(BC14VATPostingSetup: Record "BC14 VAT Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        VATPostingSetup."VAT Bus. Posting Group" := BC14VATPostingSetup."VAT Bus. Posting Group";
        VATPostingSetup."VAT Prod. Posting Group" := BC14VATPostingSetup."VAT Prod. Posting Group";

        // Use Validate so any OnValidate business logic runs.
        VATPostingSetup.Validate("VAT %", BC14VATPostingSetup."VAT %");
        // The following three fields all trigger the same Tax Jurisdiction cross-check on Validate
        // (\"... must be entered on the tax jurisdiction line when VAT Calculation Type is Sales
        // Tax\"). We do not migrate Tax Jurisdiction rows in this app, so direct-assign them; the
        // configuration is verified at posting time. Explicit Option->Enum mapping for the first.
        VATPostingSetup."VAT Calculation Type" := Enum::Microsoft.Foundation.Enums."Tax Calculation Type".FromInteger(BC14VATPostingSetup."VAT Calculation Type");
        VATPostingSetup."Unrealized VAT Type" := BC14VATPostingSetup."Unrealized VAT Type";
        VATPostingSetup."Adjust for Payment Discount" := BC14VATPostingSetup."Adjust for Payment Discount";
        // G/L Account FK fields: direct assignment (G/L Account migrates in Master phase).
        VATPostingSetup."Sales VAT Account" := BC14VATPostingSetup."Sales VAT Account";
        VATPostingSetup."Sales VAT Unreal. Account" := BC14VATPostingSetup."Sales VAT Unreal. Account";
        VATPostingSetup."Purchase VAT Account" := BC14VATPostingSetup."Purchase VAT Account";
        VATPostingSetup."Purch. VAT Unreal. Account" := BC14VATPostingSetup."Purch. VAT Unreal. Account";
        VATPostingSetup."Reverse Chrg. VAT Acc." := BC14VATPostingSetup."Reverse Chrg. VAT Acc.";
        VATPostingSetup."Reverse Chrg. VAT Unreal. Acc." := BC14VATPostingSetup."Reverse Chrg. VAT Unreal. Acc.";
        VATPostingSetup.Validate("VAT Identifier", BC14VATPostingSetup."VAT Identifier");
        VATPostingSetup.Validate("EU Service", BC14VATPostingSetup."EU Service");
        VATPostingSetup.Validate("VAT Clause Code", BC14VATPostingSetup."VAT Clause Code");
        VATPostingSetup.Validate(Description, BC14VATPostingSetup.Description);
        // "Description 2" and "Tax Group Code" are not part of the modern VAT Posting Setup table.
        VATPostingSetup.Validate("Tax Category", BC14VATPostingSetup."Tax Category");
        VATPostingSetup.Validate("Certificate of Supply Required", BC14VATPostingSetup."Certificate of Supply Required");

        OnTransferVATPostingSetupCustomFields(BC14VATPostingSetup, VATPostingSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateVATPostingSetup(BC14VATPostingSetup: Record "BC14 VAT Posting Setup"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateVATPostingSetup(BC14VATPostingSetup: Record "BC14 VAT Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferVATPostingSetupCustomFields(BC14VATPostingSetup: Record "BC14 VAT Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;
}

