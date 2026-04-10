// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Setup;

codeunit 5657 "Make Ins. Coverage Ledg. Entry"
{
    Permissions = TableData "Ins. Coverage Ledger Entry" = rm;

    trigger OnRun()
    begin
    end;

    procedure CopyFromJnlLine(var InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry"; var InsuranceJnlLine: Record "Insurance Journal Line")
    begin
        InsCoverageLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(InsCoverageLedgEntry."User ID"));
        InsCoverageLedgEntry."Insurance No." := InsuranceJnlLine."Insurance No.";
        InsCoverageLedgEntry."FA No." := InsuranceJnlLine."FA No.";
        InsCoverageLedgEntry."FA Description" := InsuranceJnlLine."FA Description";
        InsCoverageLedgEntry."Posting Date" := InsuranceJnlLine."Posting Date";
        InsCoverageLedgEntry."Document Type" := InsuranceJnlLine."Document Type";
        InsCoverageLedgEntry."Document Date" := InsuranceJnlLine."Document Date";
        if InsCoverageLedgEntry."Document Date" = 0D then
            InsCoverageLedgEntry."Document Date" := InsCoverageLedgEntry."Posting Date";
        InsCoverageLedgEntry."Document No." := InsuranceJnlLine."Document No.";
        InsCoverageLedgEntry."External Document No." := InsuranceJnlLine."External Document No.";
        InsCoverageLedgEntry.Amount := InsuranceJnlLine.Amount;
        InsCoverageLedgEntry.Description := InsuranceJnlLine.Description;
        InsCoverageLedgEntry."Index Entry" := InsuranceJnlLine."Index Entry";
        InsCoverageLedgEntry."Global Dimension 1 Code" := InsuranceJnlLine."Shortcut Dimension 1 Code";
        InsCoverageLedgEntry."Global Dimension 2 Code" := InsuranceJnlLine."Shortcut Dimension 2 Code";
        InsCoverageLedgEntry."Source Code" := InsuranceJnlLine."Source Code";
        InsCoverageLedgEntry."Journal Batch Name" := InsuranceJnlLine."Journal Batch Name";
        InsCoverageLedgEntry."Reason Code" := InsuranceJnlLine."Reason Code";
        InsCoverageLedgEntry."Disposed FA" := SetDisposedFA(InsCoverageLedgEntry."FA No.");
        InsCoverageLedgEntry."No. Series" := InsuranceJnlLine."Posting No. Series";

        OnAfterCopyFromJnlLine(InsCoverageLedgEntry, InsuranceJnlLine);
    end;

    procedure CopyFromInsuranceCard(var InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry"; var Insurance: Record Insurance)
    begin
        InsCoverageLedgEntry."FA Class Code" := Insurance."FA Class Code";
        InsCoverageLedgEntry."FA Subclass Code" := Insurance."FA Subclass Code";
        InsCoverageLedgEntry."FA Location Code" := Insurance."FA Location Code";
        InsCoverageLedgEntry."Location Code" := Insurance."Location Code";
    end;

    procedure SetDisposedFA(FANo: Code[20]): Boolean
    var
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
    begin
        FASetup.Get();
        FASetup.TestField("Insurance Depr. Book");
        if FADeprBook.Get(FANo, FASetup."Insurance Depr. Book") then
            exit(FADeprBook."Disposal Date" > 0D);

        exit(false);
    end;

    procedure UpdateInsCoverageLedgerEntryFromFASetup(InsDeprBookCode: Code[10])
    var
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        FADeprBook: Record "FA Depreciation Book";
    begin
        if InsCoverageLedgEntry.IsEmpty() then
            exit;

        InsCoverageLedgEntry.SetRange("Disposed FA", true);
        InsCoverageLedgEntry.ModifyAll("Disposed FA", false);
        if InsDeprBookCode <> '' then begin
            InsCoverageLedgEntry.Reset();
            FADeprBook.SetRange("Depreciation Book Code", InsDeprBookCode);
            FADeprBook.SetFilter("Disposal Date", '<>%1', 0D);
            if FADeprBook.FindSet() then
                repeat
                    InsCoverageLedgEntry.SetRange("FA No.", FADeprBook."FA No.");
                    InsCoverageLedgEntry.ModifyAll("Disposed FA", true)
                until FADeprBook.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromJnlLine(var InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry"; InsuranceJournalLine: Record "Insurance Journal Line")
    begin
    end;
}

