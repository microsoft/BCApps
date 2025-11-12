// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.Finance.VAT.Calculation;

codeunit 5604 "Make FA Ledger Entry"
{

    trigger OnRun()
    begin
    end;

    procedure CopyFromFAJnlLine(var FALedgEntry: Record "FA Ledger Entry"; FAJnlLine: Record "FA Journal Line")
    begin
        FALedgEntry.Init();
        FALedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(FALedgEntry."User ID"));
        FALedgEntry."Entry No." := FAJnlLine."FA Error Entry No.";
        FALedgEntry."G/L Entry No." := 0;
        FALedgEntry."Depreciation Book Code" := FAJnlLine."Depreciation Book Code";
        FALedgEntry."FA No." := FAJnlLine."FA No.";
        FALedgEntry."FA Posting Date" := FAJnlLine."FA Posting Date";
        FALedgEntry."Posting Date" := FAJnlLine."Posting Date";
        FALedgEntry."Document Date" := FAJnlLine."Document Date";
        if FALedgEntry."Document Date" = 0D then
            FALedgEntry."Document Date" := FALedgEntry."Posting Date";
        FALedgEntry."Document Type" := FAJnlLine."Document Type";
        FALedgEntry."Document No." := FAJnlLine."Document No.";
        FALedgEntry."External Document No." := FAJnlLine."External Document No.";
        FALedgEntry.Description := FAJnlLine.Description;
        FALedgEntry.Amount := FAJnlLine.Amount;
        FALedgEntry.Quantity := FAJnlLine.Quantity;
        FALedgEntry.Correction := FAJnlLine.Correction;
        FALedgEntry."Reclassification Entry" := FAJnlLine."FA Reclassification Entry";
        FALedgEntry."Index Entry" := FAJnlLine."Index Entry";
        FALedgEntry."No. of Depreciation Days" := FAJnlLine."No. of Depreciation Days";
        FALedgEntry."FA Posting Group" := FAJnlLine."FA Posting Group";
        FALedgEntry."Global Dimension 1 Code" := FAJnlLine."Shortcut Dimension 1 Code";
        FALedgEntry."Global Dimension 2 Code" := FAJnlLine."Shortcut Dimension 2 Code";
        FALedgEntry."Dimension Set ID" := FAJnlLine."Dimension Set ID";
        FALedgEntry."Reason Code" := FAJnlLine."Reason Code";
        FALedgEntry."Source Code" := FAJnlLine."Source Code";
        FALedgEntry."Journal Batch Name" := FAJnlLine."Journal Batch Name";
        FALedgEntry."FA Posting Type" := "FA Ledger Entry FA Posting Type".FromInteger(FAJnlLine.ConvertToLedgEntry(FAJnlLine));
        FALedgEntry."No. Series" := FAJnlLine."Posting No. Series";

        OnAfterCopyFromFAJnlLine(FALedgEntry, FAJnlLine);
    end;

    procedure CopyFromGenJnlLine(var FALedgEntry: Record "FA Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    var
        FAJnlLine: Record "FA Journal Line";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
    begin
        FALedgEntry.Init();
        FALedgEntry."User ID" := UserId();
        FALedgEntry."Entry No." := GenJnlLine."FA Error Entry No.";
        FALedgEntry."G/L Entry No." := 1;
        FALedgEntry."Depreciation Book Code" := GenJnlLine."Depreciation Book Code";
        FALedgEntry."FA No." := GenJnlLine."Account No.";
        FALedgEntry."FA Posting Date" := GenJnlLine."FA Posting Date";
        FALedgEntry."Posting Date" := GenJnlLine."Posting Date";
        FALedgEntry."Document Date" := GenJnlLine."Document Date";
        if FALedgEntry."Document Date" = 0D then
            FALedgEntry."Document Date" := FALedgEntry."Posting Date";
        FALedgEntry."Document Type" := GenJnlLine."Document Type";
        FALedgEntry."Document No." := GenJnlLine."Document No.";
        FALedgEntry."External Document No." := GenJnlLine."External Document No.";
        FALedgEntry.Description := GenJnlLine.Description;
        FALedgEntry.Quantity := GenJnlLine.Quantity;
        FALedgEntry.Correction := GenJnlLine.Correction;
        FALedgEntry."Index Entry" := GenJnlLine."Index Entry";
        FALedgEntry."Reclassification Entry" := GenJnlLine."FA Reclassification Entry";
        FALedgEntry."No. of Depreciation Days" := GenJnlLine."No. of Depreciation Days";
        FALedgEntry."FA Posting Group" := GenJnlLine."Posting Group";
        FALedgEntry."Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        FALedgEntry."Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        FALedgEntry."Dimension Set ID" := GenJnlLine."Dimension Set ID";
        FALedgEntry."Reason Code" := GenJnlLine."Reason Code";
        FALedgEntry."Source Code" := GenJnlLine."Source Code";
        FALedgEntry."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        FALedgEntry."Bal. Account Type" := GenJnlLine."Bal. Account Type";
        FALedgEntry."Bal. Account No." := GenJnlLine."Bal. Account No.";
        FALedgEntry."Gen. Posting Type" := GenJnlLine."Gen. Posting Type";
        FALedgEntry."Gen. Bus. Posting Group" := GenJnlLine."Gen. Bus. Posting Group";
        FALedgEntry."Gen. Prod. Posting Group" := GenJnlLine."Gen. Prod. Posting Group";
        FALedgEntry."VAT Bus. Posting Group" := GenJnlLine."VAT Bus. Posting Group";
        FALedgEntry."VAT Prod. Posting Group" := GenJnlLine."VAT Prod. Posting Group";
        FALedgEntry."Tax Area Code" := GenJnlLine."Tax Area Code";
        FALedgEntry."Tax Liable" := GenJnlLine."Tax Liable";
        FALedgEntry."Tax Group Code" := GenJnlLine."Tax Group Code";
        FALedgEntry."Use Tax" := GenJnlLine."Use Tax";
        FALedgEntry."No. Series" := GenJnlLine."Posting No. Series";
        FAJnlLine."FA Posting Type" := "FA Journal Line FA Posting Type".FromInteger(GenJnlLine."FA Posting Type".AsInteger() - 1);
        FALedgEntry."FA Posting Type" := "FA Ledger Entry FA Posting Type".FromInteger(FAJnlLine.ConvertToLedgEntry(FAJnlLine));
        NonDeductibleVAT.CopyNonDedVATFromGenJnlLineToFALedgEntry(FALedgEntry, GenJnlLine);

        OnAfterCopyFromGenJnlLine(FALedgEntry, GenJnlLine);
    end;

    procedure CopyFromFACard(var FALedgEntry: Record "FA Ledger Entry"; var FA: Record "Fixed Asset"; var FADeprBook: Record "FA Depreciation Book")
    var
        xFALedgerEntry: Record "FA Ledger Entry";
    begin
        OnBeforeCopyFromFACard(FALedgEntry, FA, FADeprBook, xFALedgerEntry);

        FALedgEntry."FA Class Code" := FA."FA Class Code";
        FALedgEntry."FA Subclass Code" := FA."FA Subclass Code";
        FALedgEntry."FA Location Code" := FA."FA Location Code";
        FALedgEntry."Location Code" := FA."Location Code";
        FALedgEntry."FA Exchange Rate" := FADeprBook.GetExchangeRate();
        FALedgEntry."Depreciation Method" := FADeprBook."Depreciation Method";
        FALedgEntry."Depreciation Starting Date" := FADeprBook."Depreciation Starting Date";
        FALedgEntry."Depreciation Ending Date" := FADeprBook."Depreciation Ending Date";
        FALedgEntry."Straight-Line %" := FADeprBook."Straight-Line %";
        FALedgEntry."No. of Depreciation Years" := FADeprBook."No. of Depreciation Years";
        FALedgEntry."Fixed Depr. Amount" := FADeprBook."Fixed Depr. Amount";
        FALedgEntry."Declining-Balance %" := FADeprBook."Declining-Balance %";
        FALedgEntry."Depreciation Table Code" := FADeprBook."Depreciation Table Code";
        FALedgEntry."Use FA Ledger Check" := FADeprBook."Use FA Ledger Check";
        FALedgEntry."Depr. Starting Date (Custom 1)" := FADeprBook."Depr. Starting Date (Custom 1)";
        FALedgEntry."Depr. Ending Date (Custom 1)" := FADeprBook."Depr. Ending Date (Custom 1)";
        FALedgEntry."Accum. Depr. % (Custom 1)" := FADeprBook."Accum. Depr. % (Custom 1)";
        FALedgEntry."Depr. % this year (Custom 1)" := FADeprBook."Depr. This Year % (Custom 1)";
        FALedgEntry."Property Class (Custom 1)" := FADeprBook."Property Class (Custom 1)";

        OnAfterCopyFromFACard(FALedgEntry, FA, FADeprBook, xFALedgerEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromFAJnlLine(var FALedgerEntry: Record "FA Ledger Entry"; FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromGenJnlLine(var FALedgerEntry: Record "FA Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromFACard(var FALedgerEntry: Record "FA Ledger Entry"; var FixedAsset: Record "Fixed Asset"; var FADepreciationBook: Record "FA Depreciation Book"; var xFALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromFACard(var FALedgerEntry: Record "FA Ledger Entry"; var FixedAsset: Record "Fixed Asset"; var FADepreciationBook: Record "FA Depreciation Book"; var xFALedgerEntry: Record "FA Ledger Entry")
    begin
    end;
}

