// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7440 "EA Corp Card Post Mgt"
{
    Access = Internal;
    Permissions = tabledata "EA Corp Card Trans" = rm;

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
        InvalidationReason: Text[250];
    begin
        if PostedExpenseReportLine."Credit Card Feed No." = 0 then
            exit;
        if not CorpCardTrans.Get(PostedExpenseReportLine."Credit Card Feed No.") then
            exit;

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
}
