// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.GeneralLedger.Setup;

codeunit 46910 "BC14 Gen. Post. Setup Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 General Posting Setup";

    trigger OnRun()
    begin
        MigrateGeneralPostingSetup(Rec);
    end;

    var
        MigratorNameLbl: Label 'General Posting Setup Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"General Posting Setup", Database::"BC14 General Posting Setup");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14GeneralPostingSetup: Record "BC14 General Posting Setup";
    begin
        exit(not BC14GeneralPostingSetup.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14GeneralPostingSetup: Record "BC14 General Posting Setup";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14GeneralPostingSetup;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Gen. Post. Setup Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14GeneralPostingSetup: Record "BC14 General Posting Setup";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 General Posting Setup", BC14GeneralPostingSetup.Count()));
    end;

    internal procedure MigrateGeneralPostingSetup(BC14GeneralPostingSetup: Record "BC14 General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateGeneralPostingSetup(BC14GeneralPostingSetup, IsMigrated);
        if IsMigrated then
            exit;

        if GeneralPostingSetup.Get(BC14GeneralPostingSetup."Gen. Bus. Posting Group", BC14GeneralPostingSetup."Gen. Prod. Posting Group") then begin
            TransferFields(BC14GeneralPostingSetup, GeneralPostingSetup);
            GeneralPostingSetup.Modify();
        end else begin
            GeneralPostingSetup.Init();
            TransferFields(BC14GeneralPostingSetup, GeneralPostingSetup);
            GeneralPostingSetup.Insert();
        end;

        OnAfterMigrateGeneralPostingSetup(BC14GeneralPostingSetup, GeneralPostingSetup);
    end;

    local procedure TransferFields(BC14GeneralPostingSetup: Record "BC14 General Posting Setup"; var GeneralPostingSetup: Record "General Posting Setup")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        GeneralPostingSetup."Gen. Bus. Posting Group" := BC14GeneralPostingSetup."Gen. Bus. Posting Group";
        GeneralPostingSetup."Gen. Prod. Posting Group" := BC14GeneralPostingSetup."Gen. Prod. Posting Group";

        // G/L Account FK fields: direct assignment. General Posting Setup runs in the Setup phase,
        // before G/L Account is migrated in the Master phase, so Validate's TableRelation check would
        // always fail on a freshly-created target company. Accounts are verified lazily when posted.
        GeneralPostingSetup."Sales Account" := BC14GeneralPostingSetup."Sales Account";
        GeneralPostingSetup."Sales Line Disc. Account" := BC14GeneralPostingSetup."Sales Line Disc. Account";
        GeneralPostingSetup."Sales Inv. Disc. Account" := BC14GeneralPostingSetup."Sales Inv. Disc. Account";
        GeneralPostingSetup."Sales Pmt. Disc. Debit Acc." := BC14GeneralPostingSetup."Sales Pmt. Disc. Debit Acc.";
        GeneralPostingSetup."Sales Credit Memo Account" := BC14GeneralPostingSetup."Sales Credit Memo Account";
        GeneralPostingSetup."Purch. Account" := BC14GeneralPostingSetup."Purch. Account";
        GeneralPostingSetup."Purch. Line Disc. Account" := BC14GeneralPostingSetup."Purch. Line Disc. Account";
        GeneralPostingSetup."Purch. Inv. Disc. Account" := BC14GeneralPostingSetup."Purch. Inv. Disc. Account";
        GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc." := BC14GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc.";
        GeneralPostingSetup."Purch. Credit Memo Account" := BC14GeneralPostingSetup."Purch. Credit Memo Account";
        GeneralPostingSetup."COGS Account" := BC14GeneralPostingSetup."COGS Account";
        GeneralPostingSetup."Inventory Adjmt. Account" := BC14GeneralPostingSetup."Inventory Adjmt. Account";
        GeneralPostingSetup."Invt. Accrual Acc. (Interim)" := BC14GeneralPostingSetup."Invt. Accrual Acc. (Interim)";
        GeneralPostingSetup."Sales Pmt. Disc. Credit Acc." := BC14GeneralPostingSetup."Sales Pmt. Disc. Credit Acc.";
        GeneralPostingSetup."Purch. Pmt. Disc. Debit Acc." := BC14GeneralPostingSetup."Purch. Pmt. Disc. Debit Acc.";
        GeneralPostingSetup."Sales Pmt. Tol. Debit Acc." := BC14GeneralPostingSetup."Sales Pmt. Tol. Debit Acc.";
        GeneralPostingSetup."Sales Pmt. Tol. Credit Acc." := BC14GeneralPostingSetup."Sales Pmt. Tol. Credit Acc.";
        GeneralPostingSetup."Purch. Pmt. Tol. Debit Acc." := BC14GeneralPostingSetup."Purch. Pmt. Tol. Debit Acc.";
        GeneralPostingSetup."Purch. Pmt. Tol. Credit Acc." := BC14GeneralPostingSetup."Purch. Pmt. Tol. Credit Acc.";
        GeneralPostingSetup."Sales Prepayments Account" := BC14GeneralPostingSetup."Sales Prepayments Account";
        GeneralPostingSetup."Purch. Prepayments Account" := BC14GeneralPostingSetup."Purch. Prepayments Account";
        GeneralPostingSetup."COGS Account (Interim)" := BC14GeneralPostingSetup."COGS Account (Interim)";
        GeneralPostingSetup."Direct Cost Applied Account" := BC14GeneralPostingSetup."Direct Cost Applied Account";
        GeneralPostingSetup."Overhead Applied Account" := BC14GeneralPostingSetup."Overhead Applied Account";
        GeneralPostingSetup."Purchase Variance Account" := BC14GeneralPostingSetup."Purchase Variance Account";
        // Manufacturing-related variance accounts (Mfg. Overhead, Material Variance, Capacity Variance,
        // Cap. Overhead, Subcontracted Variance) live in a separate Manufacturing extension table
        // in modern BC and are not part of the base General Posting Setup table; they are intentionally
        // not migrated here.

        OnTransferGeneralPostingSetupCustomFields(BC14GeneralPostingSetup, GeneralPostingSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateGeneralPostingSetup(BC14GeneralPostingSetup: Record "BC14 General Posting Setup"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateGeneralPostingSetup(BC14GeneralPostingSetup: Record "BC14 General Posting Setup"; var GeneralPostingSetup: Record "General Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferGeneralPostingSetupCustomFields(BC14GeneralPostingSetup: Record "BC14 General Posting Setup"; var GeneralPostingSetup: Record "General Posting Setup")
    begin
    end;
}

