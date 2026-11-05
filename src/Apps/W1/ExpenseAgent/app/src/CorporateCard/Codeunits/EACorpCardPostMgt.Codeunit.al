// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Utilities;

codeunit 7440 "EA Corp Card Post Mgt"
{
    Access = Internal;
    Permissions = tabledata "EA Corp Card Trans" = rm,
                  tabledata "EA Corp Card Statement" = r;

    internal procedure LockPostedReportTransactions(PostedExpenseReportNo: Code[20])
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        TempCorpCardStatement: Record "EA Corp Card Statement" temporary;
        CorpCardTrans: Record "EA Corp Card Trans";
        TempCorpCardTransEntry: Record Integer temporary;
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        Expense: Record Expense;
        PostedReportCardTrans: Query "EA Posted Report Card Trans";
        StatementEntryNos: Dictionary of [Integer, Integer];
    begin
        PostedExpenseReportLine.SetRange("Document No.", PostedExpenseReportNo);
        PostedExpenseReportLine.SetRange("Is Canceled", false);
        PostedExpenseReportLine.SetFilter("Credit Card Feed No.", '<>%1', 0);
        PostedReportCardTrans.SetRange(PostedReportNo, PostedExpenseReportNo);
        PostedReportCardTrans.Open();
        while PostedReportCardTrans.Read() do begin
            if PostedReportCardTrans.TransactionEntryNo = 0 then begin
                PostedReportCardTrans.Close();
                Error(ReportCardLinksChangedErr);
            end;
            if not StatementEntryNos.ContainsKey(PostedReportCardTrans.TransactionEntryNo) then begin
                StatementEntryNos.Add(PostedReportCardTrans.TransactionEntryNo, PostedReportCardTrans.StatementEntryNo);
                TempCorpCardTransEntry.Number := PostedReportCardTrans.TransactionEntryNo;
                TempCorpCardTransEntry.Insert();
            end;
            if PostedReportCardTrans.StatementEntryNo <> 0 then
                if not TempCorpCardStatement.Get(PostedReportCardTrans.StatementEntryNo) then begin
                    TempCorpCardStatement.Init();
                    TempCorpCardStatement."Statement Entry No." := PostedReportCardTrans.StatementEntryNo;
                    TempCorpCardStatement.Insert();
                end;
        end;
        PostedReportCardTrans.Close();

        CorpCardStatement.LockTable();
        if TempCorpCardStatement.FindSet() then
            repeat
                CorpCardStatement.Get(TempCorpCardStatement."Statement Entry No.");
            until TempCorpCardStatement.Next() = 0;
        CorpCardTrans.LockTable();
        // Keep transaction locks in entry-number order.
        if TempCorpCardTransEntry.FindSet() then
            repeat
                CorpCardTrans.Get(TempCorpCardTransEntry.Number);
                CorpCardTrans.TestField("Statement Entry No.", StatementEntryNos.Get(TempCorpCardTransEntry.Number));
            until TempCorpCardTransEntry.Next() = 0;

        Expense.LockTable();
        Expense.SetRange("Posted Expense Report No.", PostedExpenseReportNo);
        if Expense.FindSet() then
            repeat
                Expense.TestField("Posted Expense Report No.", PostedExpenseReportNo);
            until Expense.Next() = 0;

        if PostedExpenseReportLine.FindSet() then
            repeat
                if not StatementEntryNos.ContainsKey(PostedExpenseReportLine."Credit Card Feed No.") then
                    Error(ReportCardLinksChangedErr);
            until PostedExpenseReportLine.Next() = 0;
    end;

    internal procedure LinkPostedExpense(PostedExpenseReportLine: Record "Posted Expense Report Line"; PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        if PostedExpenseReportLine."Credit Card Feed No." = 0 then
            exit;
        if not CorpCardTrans.Get(PostedExpenseReportLine."Credit Card Feed No.") then
            exit;

        CorpCardTrans."Posted Expense Report No." := PostedExpenseReportHeader."No.";
        CorpCardTrans.Status := CorpCardTrans.Status::Posted;
        CorpCardTrans.Modify(true);
    end;

    internal procedure HandleCanceledPostedExpense(PostedExpenseReportLine: Record "Posted Expense Report Line"; PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
        CorpCardLiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
        InvalidationReason: Text[250];
    begin
        if PostedExpenseReportLine."Credit Card Feed No." = 0 then
            exit;
        if not CorpCardTrans.Get(PostedExpenseReportLine."Credit Card Feed No.") then
            exit;
        if (CorpCardTrans."Liability Transaction No." <> 0) and (CorpCardTrans."Liability Reversal Trans. No." = 0) then
            CorpCardLiabilityMgt.ReverseLiability(CorpCardTrans);

        if CorpCardTrans."Statement Entry No." <> 0 then
            if CorpCardStatement.Get(CorpCardTrans."Statement Entry No.") then begin
                InvalidationReason :=
                    CopyStr(
                        StrSubstNo(ExpenseReportCanceledReasonTxt, PostedExpenseReportHeader."No."),
                        1, MaxStrLen(InvalidationReason));
                CorpCardStatementMgt.InvalidateReconciliation(CorpCardStatement, InvalidationReason);
            end;

        CorpCardTrans."Posted Expense Report No." := '';
        CorpCardTrans.Status := CorpCardTrans.Status::Matched;
        CorpCardTrans.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Expense Report-Post", 'OnAfterProcessExpenseReportLine', '', false, false)]
    local procedure OnAfterProcessExpenseReportLine(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; PostedExpenseReportLine: Record "Posted Expense Report Line"; PostedExpenseReportHeader: Record "Posted Expense Report Header")
    begin
        LinkPostedExpense(PostedExpenseReportLine, PostedExpenseReportHeader);
    end;

    var
        ExpenseReportCanceledReasonTxt: Label 'Posted expense report %1 was canceled.', Comment = '%1 = posted expense report number';
        ReportCardLinksChangedErr: Label 'Corporate card links changed while preparing cancellation. Try canceling the expense report again.';
}
