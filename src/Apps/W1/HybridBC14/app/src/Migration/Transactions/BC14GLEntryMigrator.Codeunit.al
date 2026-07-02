// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 46888 "BC14 G/L Entry Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 G/L Entry";

    trigger OnRun()
    begin
        CreateJournalLine(Rec);
    end;

    var
        MigratorNameLbl: Label 'G/L Entry Migrator';
        GLAccountDoesNotExistErr: Label 'G/L Account %1 does not exist.', Comment = '%1 = G/L Account No.';
        JournalBatchNamePrefixTok: Label 'BC14GL', Locked = true;
        JournalBatchDescTok: Label 'Business Central 14 G/L Entry Migration %1', Locked = true, Comment = '%1 = Batch sequence number';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"G/L Entry", Database::"BC14 G/L Entry");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(BC14CompanySettings.GetGLModuleEnabled());
    end;

    procedure Migrate(): Boolean
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateGLEntries(IsMigrated);
        if IsMigrated then
            exit(true);

        // Pass 1: pre-assign each buffer record to a journal batch, splitting at
        // transaction boundaries when the current batch hits ~10,000 lines. This
        // guarantees every batch balances and stays under the posting size limit.
        AssignJournalBatches();

        // Pass 2: standard per-record migration loop, identical to all other migrators.
        // CreateJournalLine uses Get-before-Insert on Gen. Journal Line, so re-running
        // the loop after a partial failure does not re-insert already-staged lines.
        BC14GLEntry.SetFilter(Amount, '<>0');
        ApplyCutoffFilter(BC14GLEntry);
        SourceVariant := BC14GLEntry;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 G/L Entry Migrator");

        OnAfterMigrateGLEntries(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        TotalCount: Integer;
        StagedCount: Integer;
    begin
        BC14GLEntry.SetFilter(Amount, '<>0');
        ApplyCutoffFilter(BC14GLEntry);
        TotalCount := BC14GLEntry.Count();
        if TotalCount = 0 then
            exit(0);
        GenJournalLine.SetRange("Journal Template Name", BC14JournalMgmt.GetTemplateName());
        GenJournalLine.SetFilter("Journal Batch Name", 'BC14*');
        StagedCount := GenJournalLine.Count();
        exit(Round((TotalCount - StagedCount) / TotalCount * 100, 1));
    end;

    local procedure AssignJournalBatches()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        CurrentBatchName: Code[10];
        BatchSeqNo: Integer;
        LinesInCurrentBatch: Integer;
        LastTransactionNo: Integer;
    begin
        BC14GLEntry.SetCurrentKey("Transaction No.", "Entry No.");
        BC14GLEntry.SetFilter(Amount, '<>0');
        ApplyCutoffFilter(BC14GLEntry);
        if not BC14GLEntry.FindSet() then
            exit;

        BatchSeqNo := 1;
        CurrentBatchName := MakeBatchName(BatchSeqNo);
        BC14JournalMgmt.EnsureBatchExists(CurrentBatchName, CopyStr(StrSubstNo(JournalBatchDescTok, BatchSeqNo), 1, 100));
        LinesInCurrentBatch := 0;
        LastTransactionNo := BC14GLEntry."Transaction No.";

        repeat
            // Switch to a new batch only at transaction boundaries so each batch balances.
            if (LinesInCurrentBatch >= 10000) and (BC14GLEntry."Transaction No." <> LastTransactionNo) then begin
                BatchSeqNo += 1;
                CurrentBatchName := MakeBatchName(BatchSeqNo);
                BC14JournalMgmt.EnsureBatchExists(CurrentBatchName, CopyStr(StrSubstNo(JournalBatchDescTok, BatchSeqNo), 1, 100));
                LinesInCurrentBatch := 0;
            end;

            if BC14GLEntry."Journal Batch Name" <> CurrentBatchName then begin
                BC14GLEntry."Journal Batch Name" := CurrentBatchName;
                BC14GLEntry.Modify(false);
            end;
            LinesInCurrentBatch += 1;
            LastTransactionNo := BC14GLEntry."Transaction No.";
        until BC14GLEntry.Next() = 0;
    end;

    local procedure MakeBatchName(SeqNo: Integer): Code[10]
    begin
        exit(CopyStr(JournalBatchNamePrefixTok + PadLeft(Format(SeqNo), 4, '0'), 1, 10));
    end;

    /// <summary>
    /// Restricts the buffer to entries that should be re-posted into the live ledger. When the
    /// global "Historical Cutoff Date" is set, only entries on or after the cutoff are posted;
    /// older entries are left for the historical-phase "BC14 Old G/L Entry Migr." to archive
    /// read-only. Cutoff 0D preserves the legacy behavior of posting every entry.
    /// </summary>
    local procedure ApplyCutoffFilter(var BC14GLEntry: Record "BC14 G/L Entry")
    var
        BC14CompanyInfo: Record BC14CompanyMigrationInfo;
        CutoffDate: Date;
    begin
        CutoffDate := BC14CompanyInfo.GetHistoricalCutoffDate();
        if CutoffDate = 0D then
            exit;
        BC14GLEntry.SetFilter("Posting Date", '>=%1', CutoffDate);
    end;

    local procedure PadLeft(Text: Text; Length: Integer; PadChar: Char): Text
    begin
        while StrLen(Text) < Length do
            Text := PadChar + Text;
        exit(Text);
    end;

    internal procedure CreateJournalLine(BC14GLEntry: Record "BC14 G/L Entry")
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnBeforeCreateJournalLine(BC14GLEntry, IsMigrated);
        if IsMigrated then
            exit;

        if not GLAccount.Get(BC14GLEntry."G/L Account No.") then
            Error(GLAccountDoesNotExistErr, BC14GLEntry."G/L Account No.");

        if GLAccount."Account Type" <> GLAccount."Account Type"::Posting then
            exit;

        // Idempotency: a prior partial run for the same phase may have already created this line.
        // If so, leave it alone — it will be picked up by the subsequent post action.
        if GenJournalLine.Get(BC14JournalMgmt.GetTemplateName(), BC14GLEntry."Journal Batch Name", BC14GLEntry."Entry No.") then
            exit;

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := BC14JournalMgmt.GetTemplateName();
        GenJournalLine."Journal Batch Name" := BC14GLEntry."Journal Batch Name";
        GenJournalLine."Line No." := BC14GLEntry."Entry No.";
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine."Account No." := BC14GLEntry."G/L Account No.";
        GenJournalLine."Posting Date" := BC14GLEntry."Posting Date";
        GenJournalLine."Document No." := BC14GLEntry."Document No.";
        GenJournalLine.Description := CopyStr(BC14GLEntry.Description, 1, MaxStrLen(GenJournalLine.Description));
        GenJournalLine.Amount := BC14GLEntry.Amount;
        if BC14GLEntry.Amount > 0 then
            GenJournalLine."Debit Amount" := BC14GLEntry.Amount
        else
            GenJournalLine."Credit Amount" := -BC14GLEntry.Amount;
        GenJournalLine."Shortcut Dimension 1 Code" := BC14GLEntry."Global Dimension 1 Code";
        GenJournalLine."Shortcut Dimension 2 Code" := BC14GLEntry."Global Dimension 2 Code";
        GenJournalLine."External Document No." := BC14GLEntry."External Document No.";
        GenJournalLine."Source Code" := BC14GLEntry."Source Code";

        OnTransferGLEntryCustomFields(BC14GLEntry, GenJournalLine);

        GenJournalLine.Insert(false);

        OnAfterCreateJournalLine(BC14GLEntry, GenJournalLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateGLEntries(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateGLEntries(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJournalLine(BC14GLEntry: Record "BC14 G/L Entry"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateJournalLine(BC14GLEntry: Record "BC14 G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised during G/L entry migration to allow mapping of custom fields.
    /// Subscribe to this event to transfer TableExtension fields from BC14 G/L Entry to Gen. Journal Line.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnTransferGLEntryCustomFields(BC14GLEntry: Record "BC14 G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

