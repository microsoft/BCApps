// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;

codeunit 50188 "BC14 G/L Entry Migrator" implements "ITransactionMigrator"
{
    var
        MigratorNameLbl: Label 'G/L Entry Migrator';
        GLAccountDoesNotExistErr: Label 'G/L Account %1 does not exist.', Comment = '%1 = G/L Account No.';
        JournalBatchNameTxt: Label 'BC14GL', Locked = true;
        JournalBatchDescTxt: Label 'BC14 G/L Entry Migration', Locked = true;

    procedure GetName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(BC14CompanySettings.GetGLModuleEnabled());
    end;

    procedure GetSourceTableId(): Integer
    begin
        exit(Database::"BC14 G/L Entry");
    end;

    procedure InitializeSourceRecords(var SourceRecordRef: RecordRef)
    var
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        AmountFieldRef: FieldRef;
    begin
        // Ensure journal batch exists before migration starts
        BC14HelperFunctions.EnsureGenJournalBatchExists(JournalBatchNameTxt, JournalBatchDescTxt);

        // Filter to non-zero amounts only
        AmountFieldRef := SourceRecordRef.Field(13); // Amount field
        AmountFieldRef.SetFilter('<>0');
    end;

    procedure MigrateRecord(var SourceRecordRef: RecordRef): Boolean
    var
        BC14GLEntry: Record "BC14 G/L Entry";
    begin
        SourceRecordRef.SetTable(BC14GLEntry);
        if not TryCreateJournalLine(BC14GLEntry) then
            exit(false);

        exit(true);
    end;

    procedure GetSourceRecordKey(var SourceRecordRef: RecordRef): Text[250]
    var
        EntryNoFieldRef: FieldRef;
    begin
        EntryNoFieldRef := SourceRecordRef.Field(1); // Entry No. field
        exit(Format(EntryNoFieldRef.Value()));
    end;

    procedure GetRecordCount(): Integer
    var
        BC14GLEntry: Record "BC14 G/L Entry";
    begin
        BC14GLEntry.SetFilter(Amount, '<>0');
        exit(BC14GLEntry.Count());
    end;

    [TryFunction]
    local procedure TryCreateJournalLine(BC14GLEntry: Record "BC14 G/L Entry")
    begin
        CreateJournalLine(BC14GLEntry);
    end;

    internal procedure CreateJournalLine(BC14GLEntry: Record "BC14 G/L Entry")
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        LineNo: Integer;
    begin
        // Check if G/L Account exists
        if not GLAccount.Get(BC14GLEntry."G/L Account No.") then
            Error(GLAccountDoesNotExistErr, BC14GLEntry."G/L Account No.");

        // Skip non-posting accounts
        if GLAccount."Account Type" <> GLAccount."Account Type"::Posting then
            exit;

        // Direct Posting is handled by Runner.EnableDirectPostingOnAllAccounts() before posting phase

        // Get next line number
        GenJournalLine.SetRange("Journal Template Name", BC14HelperFunctions.GetGeneralJournalTemplateName());
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        if GenJournalLine.FindLast() then
            LineNo := GenJournalLine."Line No." + 10000
        else
            LineNo := 10000;

        // Create journal line
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", BC14HelperFunctions.GetGeneralJournalTemplateName());
        GenJournalLine.Validate("Journal Batch Name", JournalBatchNameTxt);
        GenJournalLine."Line No." := LineNo;
        GenJournalLine.Insert(true);

        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", BC14GLEntry."G/L Account No.");
        GenJournalLine.Validate("Posting Date", BC14GLEntry."Posting Date");
        GenJournalLine.Validate("Document No.", BC14GLEntry."Document No.");
        GenJournalLine.Validate(Description, CopyStr(BC14GLEntry.Description, 1, 100));

        // Set amount - use the signed Amount field
        GenJournalLine.Validate(Amount, BC14GLEntry.Amount);

        // Set dimensions using direct assignment to avoid validation errors
        // (Dimension setup may differ between BC14 and BC Online)
        if BC14GLEntry."Global Dimension 1 Code" <> '' then
            GenJournalLine."Shortcut Dimension 1 Code" := BC14GLEntry."Global Dimension 1 Code";
        if BC14GLEntry."Global Dimension 2 Code" <> '' then
            GenJournalLine."Shortcut Dimension 2 Code" := BC14GLEntry."Global Dimension 2 Code";

        // Set external document no
        if BC14GLEntry."External Document No." <> '' then
            GenJournalLine."External Document No." := BC14GLEntry."External Document No.";

        // Set source code (direct assignment to avoid validation)
        if BC14GLEntry."Source Code" <> '' then
            GenJournalLine."Source Code" := BC14GLEntry."Source Code";

        OnTransferGLEntryCustomFields(BC14GLEntry, GenJournalLine);

        GenJournalLine.Modify(true);
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
