// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

codeunit 46943 "BC14 Vendor Ledger Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Vendor Ledger Entry";

    trigger OnRun()
    begin
        CreateJournalLine(Rec);
    end;

    var
        MigratorNameLbl: Label 'Vendor Ledger Entry Migrator';
        PayablesAccountMissingErr: Label 'Vendor Posting Group %1 does not have a Payables Account.', Comment = '%1 = Vendor Posting Group code';
        JournalBatchNamePrefixTok: Label 'BC14VE', Locked = true;
        JournalBatchDescTok: Label 'Business Central 14 Vendor Ledger Migration %1', Locked = true, Comment = '%1 = Batch sequence number';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Vendor Ledger Entry", Database::"BC14 Vendor Ledger Entry");
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Detailed Vendor Ledg. Entry", Database::"BC14 Detailed Vendor LE");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(BC14CompanySettings.GetPayablesModuleEnabled());
    end;

    procedure Migrate(): Boolean
    var
        BC14VendorLedgerEntry: Record "BC14 Vendor Ledger Entry";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateVendorLedgerEntries(IsMigrated);
        if IsMigrated then
            exit(true);

        // Pass 1: pre-assign each open buffer record to a journal batch, capping each batch at
        // ~10,000 lines. Every line is self-balancing (Bal. Account = payables control account),
        // so a batch can be split at any record without unbalancing it.
        AssignJournalBatches();

        // Pass 2: standard per-record migration loop, identical to all other migrators.
        // CreateJournalLine uses Get-before-Insert on Gen. Journal Line, so re-running the loop
        // after a partial failure does not re-insert already-staged lines.
        ApplyOpenFilter(BC14VendorLedgerEntry);
        SourceVariant := BC14VendorLedgerEntry;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Vendor Ledger Migrator");

        OnAfterMigrateVendorLedgerEntries(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14VendorLedgerEntry: Record "BC14 Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        TotalCount: Integer;
        StagedCount: Integer;
    begin
        ApplyOpenFilter(BC14VendorLedgerEntry);
        TotalCount := BC14VendorLedgerEntry.Count();
        if TotalCount = 0 then
            exit(0);
        GenJournalLine.SetRange("Journal Template Name", BC14JournalMgmt.GetTemplateName());
        GenJournalLine.SetFilter("Journal Batch Name", JournalBatchNamePrefixTok + '*');
        StagedCount := GenJournalLine.Count();
        exit(Round((TotalCount - StagedCount) / TotalCount * 100, 1));
    end;

    local procedure AssignJournalBatches()
    var
        BC14VendorLedgerEntry: Record "BC14 Vendor Ledger Entry";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        CurrentBatchName: Code[10];
        BatchSeqNo: Integer;
        LinesInCurrentBatch: Integer;
    begin
        BC14VendorLedgerEntry.SetCurrentKey("Entry No.");
        ApplyOpenFilter(BC14VendorLedgerEntry);
        if not BC14VendorLedgerEntry.FindSet() then
            exit;

        BatchSeqNo := 1;
        CurrentBatchName := MakeBatchName(BatchSeqNo);
        BC14JournalMgmt.EnsureBatchExists(CurrentBatchName, CopyStr(StrSubstNo(JournalBatchDescTok, BatchSeqNo), 1, 100));
        LinesInCurrentBatch := 0;

        repeat
            if LinesInCurrentBatch >= 10000 then begin
                BatchSeqNo += 1;
                CurrentBatchName := MakeBatchName(BatchSeqNo);
                BC14JournalMgmt.EnsureBatchExists(CurrentBatchName, CopyStr(StrSubstNo(JournalBatchDescTok, BatchSeqNo), 1, 100));
                LinesInCurrentBatch := 0;
            end;

            if BC14VendorLedgerEntry."Journal Batch Name" <> CurrentBatchName then begin
                BC14VendorLedgerEntry."Journal Batch Name" := CurrentBatchName;
                BC14VendorLedgerEntry.Modify(false);
            end;
            LinesInCurrentBatch += 1;
        until BC14VendorLedgerEntry.Next() = 0;
    end;

    local procedure MakeBatchName(SeqNo: Integer): Code[10]
    begin
        exit(CopyStr(JournalBatchNamePrefixTok + PadLeft(Format(SeqNo), 4, '0'), 1, 10));
    end;

    /// <summary>
    /// Restricts the buffer to the open vendor ledger entries that should be re-created in the
    /// live subledger. When the global "Historical Cutoff Date" is set, only entries on or after
    /// the cutoff are re-created as opening balances (matching the G/L Entry migrator's live/archive
    /// split); older entries are left for the historical-phase archive. Cutoff 0D re-creates every
    /// open entry, preserving the legacy single-ledger behavior.
    /// </summary>
    local procedure ApplyOpenFilter(var BC14VendorLedgerEntry: Record "BC14 Vendor Ledger Entry")
    var
        BC14CompanyInfo: Record BC14CompanyMigrationInfo;
        CutoffDate: Date;
    begin
        BC14VendorLedgerEntry.SetRange(Open, true);
        CutoffDate := BC14CompanyInfo.GetHistoricalCutoffDate();
        if CutoffDate <> 0D then
            BC14VendorLedgerEntry.SetFilter("Posting Date", '>=%1', CutoffDate);
    end;

    local procedure PadLeft(Text: Text; Length: Integer; PadChar: Char): Text
    begin
        while StrLen(Text) < Length do
            Text := PadChar + Text;
        exit(Text);
    end;

    /// <summary>
    /// Sums the remaining amount of a vendor ledger entry from its detailed entries. The sum of a
    /// vendor ledger entry's detailed entries equals its outstanding (remaining) balance, mirroring
    /// the "Remaining Amount" FlowField on "Vendor Ledger Entry".
    /// </summary>
    local procedure CalcRemainingAmount(VendorLedgerEntryNo: Integer): Decimal
    var
        BC14DetailedVendorLE: Record "BC14 Detailed Vendor LE";
    begin
        BC14DetailedVendorLE.SetCurrentKey("Vendor Ledger Entry No.");
        BC14DetailedVendorLE.SetRange("Vendor Ledger Entry No.", VendorLedgerEntryNo);
        BC14DetailedVendorLE.CalcSums(Amount);
        exit(BC14DetailedVendorLE.Amount);
    end;

    internal procedure CreateJournalLine(BC14VendorLedgerEntry: Record "BC14 Vendor Ledger Entry")
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        PayablesAccountNo: Code[20];
        RemainingAmount: Decimal;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnBeforeCreateJournalLine(BC14VendorLedgerEntry, IsMigrated);
        if IsMigrated then
            exit;

        // Only the outstanding (unapplied) amount is carried live as an opening balance. Fully
        // settled entries net to zero and are skipped here; their detail is kept read-only by the
        // historical-phase archive migrator.
        RemainingAmount := CalcRemainingAmount(BC14VendorLedgerEntry."Entry No.");
        if RemainingAmount = 0 then
            exit;

        if not VendorPostingGroup.Get(BC14VendorLedgerEntry."Vendor Posting Group") then
            Error(PayablesAccountMissingErr, BC14VendorLedgerEntry."Vendor Posting Group");
        PayablesAccountNo := VendorPostingGroup."Payables Account";
        if PayablesAccountNo = '' then
            Error(PayablesAccountMissingErr, BC14VendorLedgerEntry."Vendor Posting Group");

        // Idempotency: a prior partial run for the same phase may have already staged this line.
        if GenJournalLine.Get(BC14JournalMgmt.GetTemplateName(), BC14VendorLedgerEntry."Journal Batch Name", BC14VendorLedgerEntry."Entry No.") then
            exit;

        // Post the open amount to the vendor with the payables control account as the balancing
        // line. Because the G/L Entry migrator already re-posts the payables control account, using
        // it as the balancing account nets the G/L impact to zero while still creating the vendor
        // ledger detail (the open opening balance).
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := BC14JournalMgmt.GetTemplateName();
        GenJournalLine."Journal Batch Name" := BC14VendorLedgerEntry."Journal Batch Name";
        GenJournalLine."Line No." := BC14VendorLedgerEntry."Entry No.";
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine.Validate("Account No.", BC14VendorLedgerEntry."Vendor No.");
        GenJournalLine.Validate("Posting Date", BC14VendorLedgerEntry."Posting Date");
        GenJournalLine."Document Type" := BC14VendorLedgerEntry."Document Type";
        GenJournalLine."Document No." := BC14VendorLedgerEntry."Document No.";
        GenJournalLine.Description := CopyStr(BC14VendorLedgerEntry.Description, 1, MaxStrLen(GenJournalLine.Description));
        GenJournalLine.Validate("Currency Code", BC14VendorLedgerEntry."Currency Code");
        GenJournalLine.Validate(Amount, RemainingAmount);
        GenJournalLine."Due Date" := BC14VendorLedgerEntry."Due Date";
        GenJournalLine."External Document No." := BC14VendorLedgerEntry."External Document No.";
        GenJournalLine."Source Code" := BC14VendorLedgerEntry."Source Code";
        GenJournalLine."Shortcut Dimension 1 Code" := BC14VendorLedgerEntry."Global Dimension 1 Code";
        GenJournalLine."Shortcut Dimension 2 Code" := BC14VendorLedgerEntry."Global Dimension 2 Code";
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account";
        GenJournalLine.Validate("Bal. Account No.", PayablesAccountNo);

        OnTransferVendorLedgerEntryCustomFields(BC14VendorLedgerEntry, GenJournalLine);

        GenJournalLine.Insert(false);

        OnAfterCreateJournalLine(BC14VendorLedgerEntry, GenJournalLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateVendorLedgerEntries(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateVendorLedgerEntries(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJournalLine(BC14VendorLedgerEntry: Record "BC14 Vendor Ledger Entry"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateJournalLine(BC14VendorLedgerEntry: Record "BC14 Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised during vendor ledger migration to allow mapping of custom fields.
    /// Subscribe to transfer TableExtension fields from BC14 Vendor Ledger Entry to Gen. Journal Line.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnTransferVendorLedgerEntryCustomFields(BC14VendorLedgerEntry: Record "BC14 Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}
