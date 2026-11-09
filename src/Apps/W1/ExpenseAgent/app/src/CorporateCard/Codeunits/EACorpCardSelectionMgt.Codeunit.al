// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7447 "EA Corp Card Selection Mgt"
{
    Access = Internal;

    internal procedure ValidateExpenseCard(Expense: Record Expense; RequireCard: Boolean)
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        SourceRecord: RecordRef;
    begin
        if RequireCard and (Expense."Reimbursement Type" = Expense."Reimbursement Type"::"Credit Card") then begin
            Expense.TestField("Corporate Card Id");
            Expense.TestField("Expense Date");
        end;
        if Expense."Credit Card Feed No." <> 0 then begin
            CorpCardTrans.Get(Expense."Credit Card Feed No.");
            Expense.TestField("Corporate Card Id", CorpCardTrans."Card Id");
        end;
        SourceRecord.GetTable(Expense);
        ValidateCard(Expense."Corporate Card Id", Expense."Expense User No.", Expense."Expense Date", Expense."Reimbursement Type", SourceRecord);
    end;

    internal procedure ValidateCard(CardId: Code[50]; ExpenseUserNo: Code[20]; ExpenseDate: Date; ReimbursementType: Enum "Expense Reimbursement Type"; SourceRecord: RecordRef)
    var
        CorpCard: Record "EA Corp Card";
    begin
        if CardId = '' then
            exit;

        if ReimbursementType <> ReimbursementType::"Credit Card" then
            Error(GetCreditCardPaymentRequiredError(SourceRecord));
        CorpCard.Get(CardId);
        CorpCard.TestField("Expense User No.");
        CorpCard.TestField("Expense User No.", ExpenseUserNo);
        CorpCard.TestField(Blocked, false);
        if ExpenseDate <> 0D then begin
            if (CorpCard."Valid From" <> 0D) and (ExpenseDate < CorpCard."Valid From") then
                Error(CardNotValidOnDateErr, CardId, ExpenseDate);
            if (CorpCard."Valid To" <> 0D) and (ExpenseDate > CorpCard."Valid To") then
                Error(CardNotValidOnDateErr, CardId, ExpenseDate);
        end;
    end;

    internal procedure LookupCard(var Expense: Record Expense): Boolean
    var
        CorpCard: Record "EA Corp Card";
        CardLookup: Page "EA Corp Card Lookup";
    begin
        Expense.TestStatusOpen();
        Expense.TestField("Expense User No.");
        Expense.TestField("Credit Card Feed No.", 0);
        CorpCard.SetRange("Expense User No.", Expense."Expense User No.");
        CorpCard.SetRange(Blocked, false);
        if Expense."Expense Date" <> 0D then begin
            CorpCard.SetFilter("Valid From", '%1|..%2', 0D, Expense."Expense Date");
            CorpCard.SetFilter("Valid To", '%1|%2..', 0D, Expense."Expense Date");
        end;
        CardLookup.SetTableView(CorpCard);
        CardLookup.LookupMode(true);
        if CardLookup.RunModal() <> Action::LookupOK then
            exit(false);
        CardLookup.GetRecord(CorpCard);
        Expense.Validate("Corporate Card Id", CorpCard."Card Id");
        exit(true);
    end;

    internal procedure ValidateReportLine(ExpenseReportLine: Record "Expense Report Line"; RequireCard: Boolean)
    var
        Expense: Record Expense;
        CorpCardTrans: Record "EA Corp Card Trans";
        SourceRecord: RecordRef;
    begin
        if RequireCard and (ExpenseReportLine."Reimbursement Type" = ExpenseReportLine."Reimbursement Type"::"Credit Card") then begin
            ExpenseReportLine.TestField("Corporate Card Id");
            ExpenseReportLine.TestField("Expense Date");
        end;
        if ExpenseReportLine."Credit Card Feed No." <> 0 then begin
            CorpCardTrans.Get(ExpenseReportLine."Credit Card Feed No.");
            ExpenseReportLine.TestField("Corporate Card Id", CorpCardTrans."Card Id");
        end;
        if ExpenseReportLine."Expense No." <> '' then begin
            Expense.Get(ExpenseReportLine."Expense No.");
            ExpenseReportLine.TestField("Corporate Card Id", Expense."Corporate Card Id");
        end;
        SourceRecord.GetTable(ExpenseReportLine);
        ValidateCard(ExpenseReportLine."Corporate Card Id", ExpenseReportLine."Expense User No.", ExpenseReportLine."Expense Date", ExpenseReportLine."Reimbursement Type", SourceRecord);
    end;

    internal procedure LookupReportLineCard(var ExpenseReportLine: Record "Expense Report Line"): Boolean
    var
        SelectionExpense: Record Expense;
    begin
        ExpenseReportLine.TestStatusOpen();
        ExpenseReportLine.TestField("Credit Card Feed No.", 0);
        SelectionExpense."Expense User No." := ExpenseReportLine."Expense User No.";
        SelectionExpense."Expense Date" := ExpenseReportLine."Expense Date";
        SelectionExpense."Reimbursement Type" := ExpenseReportLine."Reimbursement Type";
        if not LookupCard(SelectionExpense) then
            exit(false);
        ExpenseReportLine.Validate("Corporate Card Id", SelectionExpense."Corporate Card Id");
        exit(true);
    end;

    internal procedure GetCardDisplay(CardId: Code[50]): Text[150]
    var
        CorpCard: Record "EA Corp Card";
    begin
        if CardId = '' then
            exit('');
        CorpCard.SetAutoCalcFields("Provider Short Name");
        CorpCard.Get(CardId);
        exit(GetCardDisplay(CorpCard, CorpCard."Provider Short Name"));
    end;

    internal procedure GetCardDisplay(CorpCard: Record "EA Corp Card"; ProviderShortName: Text[4]): Text[150]
    begin
        if CorpCard."Provider Code" = '' then
            exit(CorpCard.GetLastFourDigits());
        if ProviderShortName = '' then
            ProviderShortName := CopyStr(CorpCard."Provider Code", 1, MaxStrLen(ProviderShortName));
        exit(CopyStr(StrSubstNo(CardDisplayLbl, ProviderShortName, CorpCard.GetLastFourDigits()), 1, 150));
    end;

    local procedure GetCreditCardPaymentRequiredError(SourceRecord: RecordRef): ErrorInfo
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreditCardPaymentError: ErrorInfo;
    begin
        CreditCardPaymentError.Title := CreditCardPaymentRequiredTitleErr;
        CreditCardPaymentError.Message := CreditCardPaymentRequiredErr;
        CreditCardPaymentError.DetailedMessage := CreditCardPaymentRequiredDetailsErr;
        CreditCardPaymentError.ErrorType := ErrorType::Client;
        CreditCardPaymentError.DataClassification := DataClassification::CustomerContent;
        if SourceRecord.IsTemporary() then
            exit(CreditCardPaymentError);
        if not SourceRecord.Get(SourceRecord.RecordId) then
            exit(CreditCardPaymentError);

        case SourceRecord.Number of
            Database::Expense:
                begin
                    CreditCardPaymentError.RecordId := SourceRecord.RecordId;
                    CreditCardPaymentError.FieldNo := Expense.FieldNo("Corporate Card Id");
                    CreditCardPaymentError.PageNo := Page::Expense;
                    CreditCardPaymentError.AddNavigationAction(OpenExpenseLbl);
                end;
            Database::"Expense Report Line":
                begin
                    SourceRecord.SetTable(ExpenseReportLine);
                    if ExpenseReportHeader.Get(ExpenseReportLine."Document No.") then begin
                        CreditCardPaymentError.RecordId := ExpenseReportHeader.RecordId;
                        CreditCardPaymentError.PageNo := Page::"Expense Report";
                        CreditCardPaymentError.AddNavigationAction(OpenExpenseReportLbl);
                    end;
                end;
        end;
        exit(CreditCardPaymentError);
    end;

    var
        CreditCardPaymentRequiredErr: Label 'A corporate card can only be selected for an expense paid by credit card. Clear the corporate card before changing the payment type.';
        CreditCardPaymentRequiredTitleErr: Label 'Credit card payment required';
        CreditCardPaymentRequiredDetailsErr: Label 'Clear the Corporate Card selection on the expense or expense report line, then retry changing the payment method.';
        OpenExpenseLbl: Label 'Open expense';
        OpenExpenseReportLbl: Label 'Open expense report';
        CardNotValidOnDateErr: Label 'Corporate card %1 is not valid on expense date %2.', Comment = '%1 = corporate card identifier, %2 = expense date';
        CardDisplayLbl: Label '%1 %2', Locked = true, Comment = '%1 = card provider short name, %2 = card last four digits';
}
