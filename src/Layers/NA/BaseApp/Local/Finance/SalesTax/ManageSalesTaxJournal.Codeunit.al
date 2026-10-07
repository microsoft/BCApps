// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;

codeunit 10102 "Manage Sales Tax Journal"
{
    Permissions = TableData "VAT Entry" = ri;

    trigger OnRun()
    begin
    end;

    var
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        NextVATEntryNo: Integer;
        NextTransactionNo: Integer;
        TotalAmount: Decimal;
        Text001: Label 'Amount must not be 0 in Gen. Journal Line Template Name=''%1'',Journal Batch Name=''%2'',Line No.=''%3''. ';

    procedure CreateGenJnlLines(var GeneralJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
        BalanceAccNo: Code[20];
    begin
        BalanceAccNo := GeneralJnlLine."Bal. Account No.";
        GeneralJnlLine.ModifyAll("Bal. Account No.", '');

        GeneralJnlLine.SetRange("Document No.", GeneralJnlLine."Document No.");
        GeneralJnlLine.FindLast();
        GenJnlLine.Init();
        GenJnlLine.TransferFields(GeneralJnlLine, false);
        GenJnlLine."Journal Template Name" := GeneralJnlLine."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GeneralJnlLine."Journal Batch Name";
        GenJnlLine."Line No." := GeneralJnlLine."Line No." + 10000;
        GenJnlLine.Insert();
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine.Validate("Account No.", BalanceAccNo);
        GenJnlLine.Validate(Amount, TotalAmount);
        GenJnlLine.Modify();
        GeneralJnlLine.FindSet();
    end;

    procedure CreateTempGenJnlLines(GenJnlLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line")
    var
        BalanceAccNo: Code[20];
    begin
        BalanceAccNo := GenJnlLine."Bal. Account No.";

        GenJnlLine.SetRange("Document No.", GenJnlLine."Document No.");

        TempGenJnlLine.DeleteAll();

        if GenJnlLine.FindSet() then
            repeat
                TempGenJnlLine.Init();
                TempGenJnlLine.TransferFields(GenJnlLine, true);
                TempGenJnlLine.Insert();
                TempGenJnlLine."Bal. Account No." := '';
                TempGenJnlLine.Modify();
            until GenJnlLine.Next() = 0;

        TempGenJnlLine.Init();
        TempGenJnlLine.TransferFields(GenJnlLine, false);
        TempGenJnlLine."Journal Template Name" := GenJnlLine."Journal Template Name";
        TempGenJnlLine."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        TempGenJnlLine."Line No." := GenJnlLine."Line No." + 10000;
        TempGenJnlLine.Insert();
        TempGenJnlLine."System-Created Entry" := true;
        TempGenJnlLine.Validate("Account No.", BalanceAccNo);
        TempGenJnlLine.Validate(Amount, TotalAmount);
        TempGenJnlLine.Modify();
        TempGenJnlLine.FindSet();
    end;

    local procedure GetLastNosForVAT()
    begin
        GLEntry.LockTable();
        if GLEntry.FindLast() then
            NextTransactionNo := GLEntry."Transaction No." + 1
        else
            NextTransactionNo := 1;

        VATEntry.LockTable();
        if VATEntry.FindLast() then
            NextVATEntryNo := VATEntry."Entry No." + 1
        else
            NextVATEntryNo := 1;
    end;

    procedure PostToVAT(GenJournlLine: Record "Gen. Journal Line")
    begin
        GetLastNosForVAT();
        CalculateTotalAmount(GenJournlLine);

        VATEntry.Init();
        VATEntry."Entry No." := NextVATEntryNo;
        VATEntry."Posting Date" := GenJournlLine."Posting Date";
        VATEntry."Document No." := GenJournlLine."Document No.";
        VATEntry.Amount := -TotalAmount;
        VATEntry."User ID" := UserId;
        VATEntry."Source Code" := GenJournlLine."Source Code";
        VATEntry."Transaction No." := NextTransactionNo;
        VATEntry."Tax Group Code" := GenJournlLine."Tax Group Code";
        VATEntry."Tax Jurisdiction Code" := GenJournlLine."Tax Jurisdiction Code";
        VATEntry."Document Date" := GenJournlLine."Document Date";
        VATEntry."GST/HST" := GenJournlLine."GST/HST";
        VATEntry.Insert();
    end;

    local procedure CalculateTotalAmount(GenJournlLine: Record "Gen. Journal Line")
    begin
        TotalAmount := 0;
        GenJournlLine.SetRange("Document No.", GenJournlLine."Document No.");
        if GenJournlLine.FindSet() then
            repeat
                TotalAmount := TotalAmount - GenJournlLine.Amount;
            until GenJournlLine.Next() = 0;

        if TotalAmount = 0 then begin
            GenJournlLine.FindFirst();
            Error(Text001, GenJournlLine."Journal Template Name", GenJournlLine."Journal Batch Name", GenJournlLine."Line No.");
        end;
    end;
}

