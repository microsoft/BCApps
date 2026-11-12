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
        tabledata "Expense Report Header" = r,
        tabledata "Expense Report Line" = rm,
        tabledata "Posted Expense Report Header" = r,
        tabledata "Posted Expense Report Line" = rm;

    procedure MatchExistingExpense(CorpCardTrans: Record "EA Corp Card Trans"; var MatchedDocumentId: RecordId): Boolean
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CorpCard: Record "EA Corp Card";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        MatchDateWindow: Integer;
        AmountTolerance: Decimal;
    begin
        Clear(MatchedDocumentId);
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
                RegisterMatch(MatchedDocumentId, Expense.RecordId, CorpCardTrans."Entry No.");
            until Expense.Next() = 0;

        // Lines with a source expense are represented by that expense, not a second candidate.
        ExpenseReportLine.SetRange("Expense No.", '');
        ExpenseReportLine.SetRange("Corporate Card Id", CorpCardTrans."Card Id");
        ExpenseReportLine.SetRange("Expense User No.", CorpCard."Expense User No.");
        ExpenseReportLine.SetRange("Reimbursement Type", ExpenseReportLine."Reimbursement Type"::"Credit Card");
        ExpenseReportLine.SetRange("Credit Card Feed No.", 0);
        ExpenseReportLine.SetRange("Expense Currency Code", CorpCardTrans."Currency Code");
        ExpenseReportLine.SetRange(Amount, CorpCardTrans.Amount);
        ExpenseReportLine.SetRange("Expense Date", CorpCardTrans."Trans Date" - MatchDateWindow, CorpCardTrans."Trans Date" + MatchDateWindow);
        ExpenseReportLine.SetLoadFields("Document No.", "Line No.");
        if ExpenseReportLine.FindSet() then
            repeat
                RegisterMatch(MatchedDocumentId, ExpenseReportLine.RecordId, CorpCardTrans."Entry No.");
            until ExpenseReportLine.Next() = 0;

        PostedExpenseReportLine.SetRange("Expense No.", '');
        PostedExpenseReportLine.SetRange("Corporate Card Id", CorpCardTrans."Card Id");
        PostedExpenseReportLine.SetRange("Expense User No.", CorpCard."Expense User No.");
        PostedExpenseReportLine.SetRange("Reimbursement Type", PostedExpenseReportLine."Reimbursement Type"::"Credit Card");
        PostedExpenseReportLine.SetRange("Credit Card Feed No.", 0);
        PostedExpenseReportLine.SetRange("Is Canceled", false);
        PostedExpenseReportLine.SetRange("Expense Currency Code", CorpCardTrans."Currency Code");
        PostedExpenseReportLine.SetRange(Amount, CorpCardTrans.Amount);
        PostedExpenseReportLine.SetRange("Expense Date", CorpCardTrans."Trans Date" - MatchDateWindow, CorpCardTrans."Trans Date" + MatchDateWindow);
        PostedExpenseReportLine.SetLoadFields("Document No.", "Line No.");
        if PostedExpenseReportLine.FindSet() then
            repeat
                RegisterMatch(MatchedDocumentId, PostedExpenseReportLine.RecordId, CorpCardTrans."Entry No.");
            until PostedExpenseReportLine.Next() = 0;

        if MatchedDocumentId.TableNo <> 0 then
            exit(true);
        if AmountTolerance > 0 then begin
            Expense.SetRange(Amount, CorpCardTrans.Amount - AmountTolerance, CorpCardTrans.Amount + AmountTolerance);
            ExpenseReportLine.SetRange(Amount, CorpCardTrans.Amount - AmountTolerance, CorpCardTrans.Amount + AmountTolerance);
            PostedExpenseReportLine.SetRange(Amount, CorpCardTrans.Amount - AmountTolerance, CorpCardTrans.Amount + AmountTolerance);
            if not Expense.IsEmpty() or not ExpenseReportLine.IsEmpty() or not PostedExpenseReportLine.IsEmpty() then
                Error(ExpenseAmountNeedsReviewErr, CorpCardTrans."Entry No.");
        end;
        exit(false);
    end;

    procedure LinkExpense(var CorpCardTrans: Record "EA Corp Card Trans"; MatchedDocumentId: RecordId)
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        MatchedDocument: RecordRef;
    begin
        CheckTransactionNotLinked(CorpCardTrans);
        if not (MatchedDocumentId.TableNo in [Database::Expense, Database::"Expense Report Line", Database::"Posted Expense Report Line"]) then
            Error(UnsupportedMatchDocumentErr, MatchedDocumentId.TableNo);
        MatchedDocument.Open(MatchedDocumentId.TableNo);
        MatchedDocument.LockTable();
        MatchedDocument.Get(MatchedDocumentId);
        case MatchedDocumentId.TableNo of
            Database::Expense:
                begin
                    MatchedDocument.SetTable(Expense);
                    LinkExpense(CorpCardTrans, Expense."No.");
                end;
            Database::"Expense Report Line":
                begin
                    MatchedDocument.SetTable(ExpenseReportLine);
                    LinkReportLine(CorpCardTrans, ExpenseReportLine);
                end;
            Database::"Posted Expense Report Line":
                begin
                    MatchedDocument.SetTable(PostedExpenseReportLine);
                    LinkPostedReportLine(CorpCardTrans, PostedExpenseReportLine);
                end;
        end;
        MatchedDocument.Close();
    end;

    procedure LinkExpense(var CorpCardTrans: Record "EA Corp Card Trans"; ExpenseNo: Code[20])
    var
        Expense: Record Expense;
        CorpCard: Record "EA Corp Card";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        MatchDateWindow: Integer;
    begin
        CheckTransactionNotLinked(CorpCardTrans);
        Expense.LockTable();
        Expense.Get(ExpenseNo);
        GetTransactionCard(CorpCardTrans, CorpCard);
        Expense.TestField("Expense User No.", CorpCard."Expense User No.");
        Expense.TestField("Reimbursement Type", Expense."Reimbursement Type"::"Credit Card");
        Expense.TestField("Credit Card Feed No.", 0);
        if Expense."Corporate Card Id" <> '' then
            Expense.TestField("Corporate Card Id", CorpCardTrans."Card Id");
        Expense.TestField("Currency Code", CorpCardTrans."Currency Code");
        Expense.TestField(Amount, CorpCardTrans.Amount);
        if ExpenseAgentSetup.Get() then
            MatchDateWindow := ExpenseAgentSetup."Corp Card Date Match Window";
        CheckMatchDate(Expense."Expense Date", ExpenseNo, CorpCardTrans, MatchDateWindow);

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
            CheckPostedReportLine(PostedExpenseReportLine, CorpCardTrans, CorpCard, MatchDateWindow);
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
                    CheckReportLine(ExpenseReportLine, CorpCardTrans, CorpCard, MatchDateWindow);
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
        SetFullMatch(CorpCardTrans);
    end;

    local procedure RegisterMatch(var MatchedDocumentId: RecordId; CandidateDocumentId: RecordId; TransactionEntryNo: Integer)
    begin
        if MatchedDocumentId.TableNo <> 0 then
            Error(AmbiguousExpenseMatchErr, TransactionEntryNo);
        MatchedDocumentId := CandidateDocumentId;
    end;

    local procedure LinkReportLine(var CorpCardTrans: Record "EA Corp Card Trans"; var ExpenseReportLine: Record "Expense Report Line")
    var
        CorpCard: Record "EA Corp Card";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        MatchDateWindow: Integer;
    begin
        GetTransactionCard(CorpCardTrans, CorpCard);
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        ExpenseReportHeader.TestField("Expense User No.", CorpCard."Expense User No.");
        ExpenseReportLine.TestField("Expense No.", '');
        ExpenseReportLine.TestField("Credit Card Feed No.", 0);
        ExpenseReportLine.TestField("Corporate Card Id", CorpCardTrans."Card Id");
        if ExpenseAgentSetup.Get() then
            MatchDateWindow := ExpenseAgentSetup."Corp Card Date Match Window";
        CheckReportLine(ExpenseReportLine, CorpCardTrans, CorpCard, MatchDateWindow);
        ExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";
        ExpenseReportLine.Modify(false);
        CorpCardTrans.Status := CorpCardTrans.Status::Submitted;
        SetFullMatch(CorpCardTrans);
    end;

    local procedure LinkPostedReportLine(var CorpCardTrans: Record "EA Corp Card Trans"; var PostedExpenseReportLine: Record "Posted Expense Report Line")
    var
        CorpCard: Record "EA Corp Card";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        MatchDateWindow: Integer;
    begin
        GetTransactionCard(CorpCardTrans, CorpCard);
        PostedExpenseReportHeader.Get(PostedExpenseReportLine."Document No.");
        PostedExpenseReportHeader.TestField(Canceled, false);
        PostedExpenseReportHeader.TestField("Expense User No.", CorpCard."Expense User No.");
        PostedExpenseReportLine.TestField("Expense No.", '');
        PostedExpenseReportLine.TestField("Credit Card Feed No.", 0);
        PostedExpenseReportLine.TestField("Is Canceled", false);
        if ExpenseAgentSetup.Get() then
            MatchDateWindow := ExpenseAgentSetup."Corp Card Date Match Window";
        CheckPostedReportLine(PostedExpenseReportLine, CorpCardTrans, CorpCard, MatchDateWindow);
        PostedExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";
        PostedExpenseReportLine.Modify(false);
        CorpCardTrans."Posted Expense Report No." := PostedExpenseReportHeader."No.";
        CorpCardTrans.Status := CorpCardTrans.Status::Posted;
        SetFullMatch(CorpCardTrans);
    end;

    local procedure CheckTransactionNotLinked(CorpCardTrans: Record "EA Corp Card Trans")
    begin
        CorpCardTrans.TestField("Expense No.", '');
        CorpCardTrans.TestField("Posted Expense Report No.", '');
        if CorpCardTrans.Status in [CorpCardTrans.Status::Submitted, CorpCardTrans.Status::Posted] then
            Error(TransactionAlreadyLinkedErr, CorpCardTrans."Entry No.");
    end;

    local procedure GetTransactionCard(CorpCardTrans: Record "EA Corp Card Trans"; var CorpCard: Record "EA Corp Card")
    begin
        CorpCard.Get(CorpCardTrans."Card Id");
        CorpCard.TestField("Expense User No.");
        CorpCard.TestField(Blocked, false);
        CorpCard.TestField("Provider Code", CorpCardTrans."Provider Code");
    end;

    local procedure CheckReportLine(ExpenseReportLine: Record "Expense Report Line"; CorpCardTrans: Record "EA Corp Card Trans"; CorpCard: Record "EA Corp Card"; MatchDateWindow: Integer)
    begin
        ExpenseReportLine.TestField("Expense User No.", CorpCard."Expense User No.");
        ExpenseReportLine.TestField("Reimbursement Type", ExpenseReportLine."Reimbursement Type"::"Credit Card");
        ExpenseReportLine.TestField("Expense Currency Code", CorpCardTrans."Currency Code");
        ExpenseReportLine.TestField(Amount, CorpCardTrans.Amount);
        CheckMatchDate(ExpenseReportLine."Expense Date", ExpenseReportLine."Document No.", CorpCardTrans, MatchDateWindow);
    end;

    local procedure CheckPostedReportLine(PostedExpenseReportLine: Record "Posted Expense Report Line"; CorpCardTrans: Record "EA Corp Card Trans"; CorpCard: Record "EA Corp Card"; MatchDateWindow: Integer)
    begin
        PostedExpenseReportLine.TestField("Corporate Card Id", CorpCardTrans."Card Id");
        PostedExpenseReportLine.TestField("Expense User No.", CorpCard."Expense User No.");
        PostedExpenseReportLine.TestField("Reimbursement Type", PostedExpenseReportLine."Reimbursement Type"::"Credit Card");
        PostedExpenseReportLine.TestField("Expense Currency Code", CorpCardTrans."Currency Code");
        PostedExpenseReportLine.TestField(Amount, CorpCardTrans.Amount);
        CheckMatchDate(PostedExpenseReportLine."Expense Date", PostedExpenseReportLine."Document No.", CorpCardTrans, MatchDateWindow);
    end;

    local procedure CheckMatchDate(ExpenseDate: Date; DocumentNo: Code[20]; CorpCardTrans: Record "EA Corp Card Trans"; MatchDateWindow: Integer)
    begin
        if (ExpenseDate < CorpCardTrans."Trans Date" - MatchDateWindow) or
           (ExpenseDate > CorpCardTrans."Trans Date" + MatchDateWindow)
        then
            Error(ExpenseDateOutsideMatchWindowErr, DocumentNo, CorpCardTrans."Entry No.");
    end;

    local procedure SetFullMatch(var CorpCardTrans: Record "EA Corp Card Trans")
    begin
        if CorpCardTrans."Match Type" in [CorpCardTrans."Match Type"::None, CorpCardTrans."Match Type"::Employee] then begin
            CorpCardTrans."Match Type" := CorpCardTrans."Match Type"::Full;
            CorpCardTrans."Match Score" := 100;
        end;
    end;

    var
        TransactionAlreadyLinkedErr: Label 'Corporate card transaction %1 is already linked to an expense report.', Comment = '%1 = corporate card transaction entry number';
        UnsupportedMatchDocumentErr: Label 'Table %1 cannot be linked to a corporate card transaction.', Comment = '%1 = table number';
        AmbiguousExpenseMatchErr: Label 'More than one expense matches corporate card transaction %1. Review the expenses before linking the transaction.', Comment = '%1 = corporate card transaction entry number';
        ExpenseAlreadyLinkedErr: Label 'Expense %1 is already linked to a corporate card transaction.', Comment = '%1 = expense number';
        ExpenseReportLinkNotUniqueErr: Label 'The expense report link for expense %1 is inconsistent. Review the report lines before linking the transaction.', Comment = '%1 = expense number';
        PostedExpenseLineNotUniqueErr: Label 'A unique active posted report line could not be found for expense %1.', Comment = '%1 = expense number';
        ExpenseAmountNeedsReviewErr: Label 'A manually entered expense for corporate card transaction %1 has a different amount within the matching tolerance. Review the amount before linking; another expense was not created.', Comment = '%1 = corporate card transaction entry number';
        ExpenseDateOutsideMatchWindowErr: Label 'The date of expense %1 is outside the matching date window for corporate card transaction %2.', Comment = '%1 = expense number, %2 = corporate card transaction entry number';
}
