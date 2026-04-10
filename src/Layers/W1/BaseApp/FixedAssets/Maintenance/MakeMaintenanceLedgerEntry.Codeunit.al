// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Maintenance;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;

codeunit 5647 "Make Maintenance Ledger Entry"
{

    trigger OnRun()
    begin
    end;

    procedure CopyFromFAJnlLine(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry"; FAJnlLine: Record "FA Journal Line")
    begin
        MaintenanceLedgEntry.Init();
        MaintenanceLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(MaintenanceLedgEntry."User ID"));
        MaintenanceLedgEntry."G/L Entry No." := 0;
        MaintenanceLedgEntry."Depreciation Book Code" := FAJnlLine."Depreciation Book Code";
        MaintenanceLedgEntry."FA No." := FAJnlLine."FA No.";
        MaintenanceLedgEntry."FA Posting Date" := FAJnlLine."FA Posting Date";
        MaintenanceLedgEntry."Posting Date" := FAJnlLine."Posting Date";
        MaintenanceLedgEntry."Document Date" := FAJnlLine."Document Date";
        if MaintenanceLedgEntry."Document Date" = 0D then
            MaintenanceLedgEntry."Document Date" := MaintenanceLedgEntry."Posting Date";
        MaintenanceLedgEntry."Document Type" := FAJnlLine."Document Type";
        MaintenanceLedgEntry."Document No." := FAJnlLine."Document No.";
        MaintenanceLedgEntry."External Document No." := FAJnlLine."External Document No.";
        MaintenanceLedgEntry.Description := FAJnlLine.Description;
        MaintenanceLedgEntry.Amount := FAJnlLine.Amount;
        MaintenanceLedgEntry.Quantity := FAJnlLine.Quantity;
        MaintenanceLedgEntry."Index Entry" := FAJnlLine."Index Entry";
        MaintenanceLedgEntry."FA Posting Group" := FAJnlLine."FA Posting Group";
        MaintenanceLedgEntry."Global Dimension 1 Code" := FAJnlLine."Shortcut Dimension 1 Code";
        MaintenanceLedgEntry."Global Dimension 2 Code" := FAJnlLine."Shortcut Dimension 2 Code";
        MaintenanceLedgEntry."Dimension Set ID" := FAJnlLine."Dimension Set ID";
        MaintenanceLedgEntry."Reason Code" := FAJnlLine."Reason Code";
        MaintenanceLedgEntry."Source Code" := FAJnlLine."Source Code";
        MaintenanceLedgEntry."Journal Batch Name" := FAJnlLine."Journal Batch Name";
        MaintenanceLedgEntry."Maintenance Code" := FAJnlLine."Maintenance Code";
        MaintenanceLedgEntry.Correction := FAJnlLine.Correction;
        MaintenanceLedgEntry."No. Series" := FAJnlLine."Posting No. Series";

        OnAfterCopyFromFAJnlLine(MaintenanceLedgEntry, FAJnlLine);
    end;

    procedure CopyFromGenJnlLine(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    begin
        MaintenanceLedgEntry.Init();
        MaintenanceLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(MaintenanceLedgEntry."User ID"));
        MaintenanceLedgEntry."Entry No." := GenJnlLine."FA Error Entry No.";
        MaintenanceLedgEntry."G/L Entry No." := 1;
        MaintenanceLedgEntry."Depreciation Book Code" := GenJnlLine."Depreciation Book Code";
        MaintenanceLedgEntry."FA No." := GenJnlLine."Account No.";
        MaintenanceLedgEntry."FA Posting Date" := GenJnlLine."FA Posting Date";
        MaintenanceLedgEntry."Posting Date" := GenJnlLine."Posting Date";
        MaintenanceLedgEntry."Document Date" := GenJnlLine."Document Date";
        if MaintenanceLedgEntry."Document Date" = 0D then
            MaintenanceLedgEntry."Document Date" := MaintenanceLedgEntry."Posting Date";
        MaintenanceLedgEntry."Document Type" := GenJnlLine."Document Type";
        MaintenanceLedgEntry."Document No." := GenJnlLine."Document No.";
        MaintenanceLedgEntry."External Document No." := GenJnlLine."External Document No.";
        MaintenanceLedgEntry.Description := GenJnlLine.Description;
        MaintenanceLedgEntry.Quantity := GenJnlLine.Quantity;
        MaintenanceLedgEntry.Correction := GenJnlLine.Correction;
        MaintenanceLedgEntry."Index Entry" := GenJnlLine."Index Entry";
        MaintenanceLedgEntry."FA Posting Group" := GenJnlLine."Posting Group";
        MaintenanceLedgEntry."Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        MaintenanceLedgEntry."Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        MaintenanceLedgEntry."Dimension Set ID" := GenJnlLine."Dimension Set ID";
        MaintenanceLedgEntry."Maintenance Code" := GenJnlLine."Maintenance Code";
        MaintenanceLedgEntry."Reason Code" := GenJnlLine."Reason Code";
        MaintenanceLedgEntry."Source Code" := GenJnlLine."Source Code";
        MaintenanceLedgEntry."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        MaintenanceLedgEntry."Bal. Account Type" := GenJnlLine."Bal. Account Type";
        MaintenanceLedgEntry."Bal. Account No." := GenJnlLine."Bal. Account No.";
        MaintenanceLedgEntry."Gen. Posting Type" := GenJnlLine."Gen. Posting Type";
        MaintenanceLedgEntry."Gen. Bus. Posting Group" := GenJnlLine."Gen. Bus. Posting Group";
        MaintenanceLedgEntry."Gen. Prod. Posting Group" := GenJnlLine."Gen. Prod. Posting Group";
        MaintenanceLedgEntry."VAT Bus. Posting Group" := GenJnlLine."VAT Bus. Posting Group";
        MaintenanceLedgEntry."VAT Prod. Posting Group" := GenJnlLine."VAT Prod. Posting Group";
        MaintenanceLedgEntry."Tax Area Code" := GenJnlLine."Tax Area Code";
        MaintenanceLedgEntry."Tax Liable" := GenJnlLine."Tax Liable";
        MaintenanceLedgEntry."Tax Group Code" := GenJnlLine."Tax Group Code";
        MaintenanceLedgEntry."Use Tax" := GenJnlLine."Use Tax";
        MaintenanceLedgEntry.Correction := GenJnlLine.Correction;
        MaintenanceLedgEntry."No. Series" := GenJnlLine."Posting No. Series";

        OnAfterCopyFromGenJnlLine(MaintenanceLedgEntry, GenJnlLine);
    end;

    procedure CopyFromFACard(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry"; var FA: Record "Fixed Asset"; var FADeprBook: Record "FA Depreciation Book")
    begin
        MaintenanceLedgEntry."FA Class Code" := FA."FA Class Code";
        MaintenanceLedgEntry."FA Subclass Code" := FA."FA Subclass Code";
        MaintenanceLedgEntry."FA Location Code" := FA."FA Location Code";
        MaintenanceLedgEntry."Location Code" := FA."Location Code";
        MaintenanceLedgEntry."FA Exchange Rate" := FADeprBook.GetExchangeRate();

        OnAfterCopyFromFACard(MaintenanceLedgEntry, FA, FADeprBook);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromFAJnlLine(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromGenJnlLine(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromFACard(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;
}

