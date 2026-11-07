// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7448 "EA Corp Card Expense Match" implements "EA Corp Card Expense Match"
{
    Access = Internal;
    Permissions =
        tabledata Expense = rm,
        tabledata "Expense Report Line" = rm,
        tabledata "Posted Expense Report Line" = rm;

    procedure MatchExistingExpense(CorpCardTrans: Record "EA Corp Card Trans"; var ExpenseNo: Code[20]): Boolean
    var
        Expense: Record Expense;
        CorpCard: Record "EA Corp Card";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        MatchDateWindow: Integer;
        AmountTolerance: Decimal;
    begin
        ExpenseNo := '';
        CorpCard.Get(CorpCardTrans."Card Id");
        if CorpCard."Expense User No." = '' then
            exit(false);
        CorpCard.TestField(Blocked, false);
        if ExpenseAgentSetup.Get() then begin
            MatchDateWindow := ExpenseAgentSetup."Corp Card Date Match Window";
            AmountTolerance := ExpenseAgentSetup."Corp Card Amount Tolerance";
        end;

        Expense.SetRange("Corporate Card Id", CorpCardTrans."Card Id");
        Expense.SetRange("Expense User No.", CorpCard."Expense User No.");
        Expense.SetRange("Reimbursement Type", Expense."Reimbursement Type"::"Credit Card");
        Expense.SetRange("Credit Card Feed No.", 0);
        Expense.SetRange("Currency Code", CorpCardTrans."Currency Code");
        Expense.SetRange(Amount, CorpCardTrans.Amount);
        Expense.SetRange("Expense Date", CorpCardTrans."Trans Date" - MatchDateWindow, CorpCardTrans."Trans Date" + MatchDateWindow);
        Expense.SetLoadFields("No.");
        if Expense.FindSet() then
            repeat
                if ExpenseNo <> '' then
                    Error(AmbiguousExpenseMatchErr, CorpCardTrans."Entry No.");
                ExpenseNo := Expense."No.";
            until Expense.Next() = 0;
        if ExpenseNo <> '' then
            exit(true);
        if AmountTolerance > 0 then begin
            Expense.SetRange(Amount, CorpCardTrans.Amount - AmountTolerance, CorpCardTrans.Amount + AmountTolerance);
            if not Expense.IsEmpty() then
                Error(ExpenseAmountNeedsReviewErr, CorpCardTrans."Entry No.");
        end;
        exit(false);
    end;

    procedure LinkExpense(var CorpCardTrans: Record "EA Corp Card Trans"; ExpenseNo: Code[20])
    var
        Expense: Record Expense;
        CorpCard: Record "EA Corp Card";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
    begin
        CorpCardTrans.TestField("Expense No.", '');
        CorpCardTrans.TestField("Posted Expense Report No.", '');
        Expense.LockTable();
        Expense.Get(ExpenseNo);
        CorpCard.Get(CorpCardTrans."Card Id");
        CorpCard.TestField("Expense User No.");
        CorpCard.TestField(Blocked, false);
        CorpCard.TestField("Provider Code", CorpCardTrans."Provider Code");
        Expense.TestField("Expense User No.", CorpCard."Expense User No.");
        Expense.TestField("Reimbursement Type", Expense."Reimbursement Type"::"Credit Card");
        Expense.TestField("Credit Card Feed No.", 0);
        if Expense."Corporate Card Id" <> '' then begin
            Expense.TestField("Corporate Card Id", CorpCardTrans."Card Id");
            Expense.TestField("Currency Code", CorpCardTrans."Currency Code");
            Expense.TestField(Amount, CorpCardTrans.Amount);
        end;

        ExpenseReportLine.LockTable();
        ExpenseReportLine.SetRange("Expense No.", ExpenseNo);
        ExpenseReportLine.SetFilter("Credit Card Feed No.", '<>%1', 0);
        if not ExpenseReportLine.IsEmpty() then
            Error(ExpenseAlreadyLinkedErr, ExpenseNo);
        ExpenseReportLine.SetRange("Credit Card Feed No.");

        if Expense."Posted Expense Report No." <> '' then begin
            if not ExpenseReportLine.IsEmpty() then
                Error(ExpenseReportLinkNotUniqueErr, ExpenseNo);
            PostedExpenseReportHeader.Get(Expense."Posted Expense Report No.");
            PostedExpenseReportHeader.TestField(Canceled, false);
            PostedExpenseReportLine.LockTable();
            PostedExpenseReportLine.SetRange("Document No.", PostedExpenseReportHeader."No.");
            PostedExpenseReportLine.SetRange("Expense No.", ExpenseNo);
            PostedExpenseReportLine.SetRange("Is Canceled", false);
            if PostedExpenseReportLine.Count() <> 1 then
                Error(PostedExpenseLineNotUniqueErr, ExpenseNo);
            PostedExpenseReportLine.FindFirst();
            PostedExpenseReportLine.TestField("Credit Card Feed No.", 0);
            PostedExpenseReportLine.TestField("Corporate Card Id", CorpCardTrans."Card Id");
            PostedExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";
            PostedExpenseReportLine.Modify(false);
            CorpCardTrans."Posted Expense Report No." := PostedExpenseReportHeader."No.";
            CorpCardTrans.Status := CorpCardTrans.Status::Posted;
        end else begin
            if Expense."Expense Report No." <> '' then begin
                if ExpenseReportLine.Count() <> 1 then
                    Error(ExpenseReportLinkNotUniqueErr, ExpenseNo);
                ExpenseReportLine.FindFirst();
                ExpenseReportLine.TestField("Document No.", Expense."Expense Report No.");
            end else
                if not ExpenseReportLine.IsEmpty() then
                    Error(ExpenseReportLinkNotUniqueErr, ExpenseNo);
            if ExpenseReportLine.FindSet(true) then
                repeat
                    ExpenseReportLine.TestField("Corporate Card Id", Expense."Corporate Card Id");
                    ExpenseReportLine."Corporate Card Id" := CorpCardTrans."Card Id";
                    ExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";
                    ExpenseReportLine.Modify(false);
                until ExpenseReportLine.Next() = 0;
            if Expense."Expense Report No." <> '' then
                CorpCardTrans.Status := CorpCardTrans.Status::Submitted
            else
                CorpCardTrans.Status := CorpCardTrans.Status::Matched;
        end;

        // Linking changes provenance only, including for released and posted documents.
        Expense."Corporate Card Id" := CorpCardTrans."Card Id";
        Expense."Credit Card Feed No." := CorpCardTrans."Entry No.";
        Expense.Modify(false);
        CorpCardTrans."Expense No." := ExpenseNo;
        if CorpCardTrans."Match Type" in [CorpCardTrans."Match Type"::None, CorpCardTrans."Match Type"::Employee] then begin
            CorpCardTrans."Match Type" := CorpCardTrans."Match Type"::Full;
            CorpCardTrans."Match Score" := 100;
        end;
    end;

    var
        AmbiguousExpenseMatchErr: Label 'More than one expense matches corporate card transaction %1. Review the expenses before linking the transaction.', Comment = '%1 = corporate card transaction entry number';
        ExpenseAlreadyLinkedErr: Label 'Expense %1 is already linked to a corporate card transaction.', Comment = '%1 = expense number';
        ExpenseReportLinkNotUniqueErr: Label 'The expense report link for expense %1 is inconsistent. Review the report lines before linking the transaction.', Comment = '%1 = expense number';
        PostedExpenseLineNotUniqueErr: Label 'A unique active posted report line could not be found for expense %1.', Comment = '%1 = expense number';
        ExpenseAmountNeedsReviewErr: Label 'A manually entered expense for corporate card transaction %1 has a different amount within the matching tolerance. Review the amount before linking; another expense was not created.', Comment = '%1 = corporate card transaction entry number';
}
