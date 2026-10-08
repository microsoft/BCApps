// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 10101 "Post- Print Sales Tax Jnl"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        GenJnlLine.Copy(Rec);
        Code();
        Rec.Copy(GenJnlLine);
    end;

    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        GLReg: Record "G/L Register";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        ManageSalesTaxJournal: Codeunit "Manage Sales Tax Journal";
        TempJnlBatchName: Code[10];
        Text000: Label 'cannot be filtered when posting recurring journals.', Comment = 'Posting Date cannot be filtered when posting recurring journals.';
        Text001: Label 'Do you want to post the journal lines and print the report(s)?';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';

    procedure "Code"()
    begin
        GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
        if GenJnlTemplate."Force Posting Report" or
           (GenJnlTemplate."Cust. Receipt Report ID" = 0) and (GenJnlTemplate."Vendor Receipt Report ID" = 0)
        then
            GenJnlTemplate.TestField("Posting Report ID");
        if GenJnlTemplate.Recurring and (GenJnlLine.GetFilter("Posting Date") <> '') then
            GenJnlLine.FieldError("Posting Date", Text000);

        if not Confirm(Text001, false) then
            exit;

        TempJnlBatchName := GenJnlLine."Journal Batch Name";

        ManageSalesTaxJournal.PostToVAT(GenJnlLine);
        ManageSalesTaxJournal.CreateGenJnlLines(GenJnlLine);
        GenJnlPostBatch.Run(GenJnlLine);

        if GLReg.Get(GenJnlLine."Line No.") then begin
            if GenJnlTemplate."Cust. Receipt Report ID" <> 0 then begin
                CustLedgEntry.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
                REPORT.Run(GenJnlTemplate."Cust. Receipt Report ID", false, false, CustLedgEntry);
            end;
            if GenJnlTemplate."Vendor Receipt Report ID" <> 0 then begin
                VendLedgEntry.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
                REPORT.Run(GenJnlTemplate."Vendor Receipt Report ID", false, false, VendLedgEntry);
            end;
            if GenJnlTemplate."Posting Report ID" <> 0 then begin
                GLReg.SetRecFilter();
                REPORT.Run(GenJnlTemplate."Posting Report ID", false, false, GLReg);
            end;
        end;

        if GenJnlLine."Line No." = 0 then
            Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
        else
            if TempJnlBatchName = GenJnlLine."Journal Batch Name" then
                Message(Text003)
            else
                Message(
                  Text004,
                  GenJnlLine."Journal Batch Name");

        if not GenJnlLine.Find('=><') or (TempJnlBatchName <> GenJnlLine."Journal Batch Name") then begin
            GenJnlLine.Reset();
            GenJnlLine.FilterGroup(2);
            GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
            GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
            GenJnlLine.FilterGroup(0);
            GenJnlLine."Line No." := 1;
        end;
    end;
}

