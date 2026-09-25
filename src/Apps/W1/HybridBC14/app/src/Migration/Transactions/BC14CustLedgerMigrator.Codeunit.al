// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 46939 "BC14 Cust. Ledger Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Cust. Ledger Entry";

    trigger OnRun()
    begin
        CreateJournalLine(Rec);
    end;

    var
        MigratorNameLbl: Label 'Customer Ledger Entry Migrator';
        ReceivablesAccountMissingErr: Label 'Customer Posting Group %1 does not have a Receivables Account.', Comment = '%1 = Customer Posting Group code';
        JournalBatchNamePrefixTok: Label 'BC14CU', Locked = true;
        JournalBatchDescTok: Label 'Business Central 14 Customer Ledger Migration %1', Locked = true, Comment = '%1 = Batch sequence number';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Cust. Ledger Entry", Database::"BC14 Cust. Ledger Entry");
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Detailed Cust. Ledg. Entry", Database::"BC14 Detailed Cust. LE");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(BC14CompanySettings.GetReceivablesModuleEnabled());
    end;

    procedure Migrate(): Boolean
    var
        BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateCustLedgerEntries(IsMigrated);
        if IsMigrated then
            exit(true);

        // Pass 1: pre-assign each open buffer record to a journal batch, capping each batch at
        // ~10,000 lines. Every line is self-balancing (Bal. Account = receivables control account),
        // so a batch can be split at any record without unbalancing it.
        AssignJournalBatches();

        // Pass 2: standard per-record migration loop, identical to all other migrators.
        // CreateJournalLine uses Get-before-Insert on Gen. Journal Line, so re-running the loop
        // after a partial failure does not re-insert already-staged lines.
        ApplyOpenFilter(BC14CustLedgerEntry);
        SourceVariant := BC14CustLedgerEntry;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Cust. Ledger Migrator");

        OnAfterMigrateCustLedgerEntries(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        TotalCount: Integer;
        StagedCount: Integer;
    begin
        ApplyOpenFilter(BC14CustLedgerEntry);
        TotalCount := BC14CustLedgerEntry.Count();
        if TotalCount = 0 then
            exit(0);
        GenJournalLine.SetRange("Journal Template Name", BC14JournalMgmt.GetTemplateName());
        GenJournalLine.SetFilter("Journal Batch Name", JournalBatchNamePrefixTok + '*');
        StagedCount := GenJournalLine.Count();
        exit(Round((TotalCount - StagedCount) / TotalCount * 100, 1));
    end;

    local procedure AssignJournalBatches()
    var
        BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        CurrentBatchName: Code[10];
        BatchSeqNo: Integer;
        LinesInCurrentBatch: Integer;
    begin
        BC14CustLedgerEntry.SetCurrentKey("Entry No.");
        ApplyOpenFilter(BC14CustLedgerEntry);
        if not BC14CustLedgerEntry.FindSet() then
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

            if BC14CustLedgerEntry."Journal Batch Name" <> CurrentBatchName then begin
                BC14CustLedgerEntry."Journal Batch Name" := CurrentBatchName;
                BC14CustLedgerEntry.Modify(false);
            end;
            LinesInCurrentBatch += 1;
        until BC14CustLedgerEntry.Next() = 0;
    end;

    local procedure MakeBatchName(SeqNo: Integer): Code[10]
    begin
        exit(CopyStr(JournalBatchNamePrefixTok + PadLeft(Format(SeqNo), 4, '0'), 1, 10));
    end;

    /// <summary>
    /// Restricts the buffer to the open customer ledger entries that should be re-created in the
    /// live subledger. When the global "Historical Cutoff Date" is set, only entries on or after
    /// the cutoff are re-created as opening balances (matching the G/L Entry migrator's live/archive
    /// split); older entries are left for the historical-phase archive. Cutoff 0D re-creates every
    /// open entry, preserving the legacy single-ledger behavior.
    /// </summary>
    local procedure ApplyOpenFilter(var BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry")
    var
        BC14CompanyInfo: Record BC14CompanyMigrationInfo;
        CutoffDate: Date;
    begin
        BC14CustLedgerEntry.SetRange(Open, true);
        CutoffDate := BC14CompanyInfo.GetHistoricalCutoffDate();
        if CutoffDate <> 0D then
            BC14CustLedgerEntry.SetFilter("Posting Date", '>=%1', CutoffDate);
    end;

    local procedure PadLeft(Text: Text; Length: Integer; PadChar: Char): Text
    begin
        while StrLen(Text) < Length do
            Text := PadChar + Text;
        exit(Text);
    end;

    /// <summary>
    /// Sums the remaining amount of a customer ledger entry from its detailed entries. The sum of a
    /// customer ledger entry's detailed entries equals its outstanding (remaining) balance, mirroring
    /// the "Remaining Amount" FlowField on "Cust. Ledger Entry".
    /// </summary>
    local procedure CalcRemainingAmount(CustLedgerEntryNo: Integer): Decimal
    var
        BC14DetailedCustLE: Record "BC14 Detailed Cust. LE";
    begin
        BC14DetailedCustLE.SetCurrentKey("Cust. Ledger Entry No.");
        BC14DetailedCustLE.SetRange("Cust. Ledger Entry No.", CustLedgerEntryNo);
        BC14DetailedCustLE.CalcSums(Amount);
        exit(BC14DetailedCustLE.Amount);
    end;

    internal procedure CreateJournalLine(BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry")
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        ReceivablesAccountNo: Code[20];
        RemainingAmount: Decimal;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnBeforeCreateJournalLine(BC14CustLedgerEntry, IsMigrated);
        if IsMigrated then
            exit;

        // Only the outstanding (unapplied) amount is carried live as an opening balance. Fully
        // settled entries net to zero and are skipped here; their detail is kept read-only by the
        // historical-phase archive migrator.
        RemainingAmount := CalcRemainingAmount(BC14CustLedgerEntry."Entry No.");
        if RemainingAmount = 0 then
            exit;

        if not CustomerPostingGroup.Get(BC14CustLedgerEntry."Customer Posting Group") then
            Error(ReceivablesAccountMissingErr, BC14CustLedgerEntry."Customer Posting Group");
        ReceivablesAccountNo := CustomerPostingGroup."Receivables Account";
        if ReceivablesAccountNo = '' then
            Error(ReceivablesAccountMissingErr, BC14CustLedgerEntry."Customer Posting Group");

        // Idempotency: a prior partial run for the same phase may have already staged this line.
        if GenJournalLine.Get(BC14JournalMgmt.GetTemplateName(), BC14CustLedgerEntry."Journal Batch Name", BC14CustLedgerEntry."Entry No.") then
            exit;

        // Post the open amount to the customer with the receivables control account as the balancing
        // line. Because the G/L Entry migrator already re-posts the receivables control account, using
        // it as the balancing account nets the G/L impact to zero while still creating the customer
        // ledger detail (the open opening balance).
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := BC14JournalMgmt.GetTemplateName();
        GenJournalLine."Journal Batch Name" := BC14CustLedgerEntry."Journal Batch Name";
        GenJournalLine."Line No." := BC14CustLedgerEntry."Entry No.";
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine.Validate("Account No.", BC14CustLedgerEntry."Customer No.");
        GenJournalLine.Validate("Posting Date", BC14CustLedgerEntry."Posting Date");
        GenJournalLine."Document Type" := BC14CustLedgerEntry."Document Type";
        GenJournalLine."Document No." := BC14CustLedgerEntry."Document No.";
        GenJournalLine.Description := CopyStr(BC14CustLedgerEntry.Description, 1, MaxStrLen(GenJournalLine.Description));
        GenJournalLine.Validate("Currency Code", BC14CustLedgerEntry."Currency Code");
        GenJournalLine.Validate(Amount, RemainingAmount);
        GenJournalLine."Due Date" := BC14CustLedgerEntry."Due Date";
        GenJournalLine."External Document No." := BC14CustLedgerEntry."External Document No.";
        GenJournalLine."Source Code" := BC14CustLedgerEntry."Source Code";
        GenJournalLine."Shortcut Dimension 1 Code" := BC14CustLedgerEntry."Global Dimension 1 Code";
        GenJournalLine."Shortcut Dimension 2 Code" := BC14CustLedgerEntry."Global Dimension 2 Code";
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account";
        GenJournalLine.Validate("Bal. Account No.", ReceivablesAccountNo);

        OnTransferCustLedgerEntryCustomFields(BC14CustLedgerEntry, GenJournalLine);

        GenJournalLine.Insert(false);

        OnAfterCreateJournalLine(BC14CustLedgerEntry, GenJournalLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateCustLedgerEntries(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateCustLedgerEntries(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJournalLine(BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateJournalLine(BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised during customer ledger migration to allow mapping of custom fields.
    /// Subscribe to transfer TableExtension fields from BC14 Cust. Ledger Entry to Gen. Journal Line.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnTransferCustLedgerEntryCustomFields(BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}
