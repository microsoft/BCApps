// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Creates draft Expense records from corporate card transactions.
/// Implements EACorpCardExpWriterInterface to populate expense fields from transaction data.
/// </summary>
codeunit 7422 "EA Corp Card Expense Writer" implements "EA Corp Card Expense Writer"
{
    Access = Internal;
    Permissions = tabledata "Expense VAT Specification" = rimd;

    var
        CreditCardPaymentMethodMissingErr: Label 'An expense payment method with reimbursement type Credit Card must exist before corporate card expenses can be created.';
        OpenPaymentMethodsLbl: Label 'Open payment methods';
        RecordNotFoundForCardErr: Label '%1 not found for card %2.', Comment = '%1 = table caption, %2 = card id.';
        ExpenseUserNotSpecifiedForCardErr: Label 'Specify %1 for corporate card %2 before creating expenses.', Comment = '%1 = Expense User No. field caption, %2 = card id.';
        ShowItLbl: Label 'Show it';
        Level3ReconcileWarnLbl: Label 'Level 3 detail total %1 does not match transaction amount %2.', Comment = '%1 = detail total, %2 = transaction amount';

    procedure CreateDraftFromTrans(var CorpCardTrans: Record "EA Corp Card Trans"; var ExpenseNo: Code[20])
    var
        Expense: Record Expense;
        ExpensePaymentMethod: Record "Expense Payment Method";
        CorpCard: Record "EA Corp Card";
        ExpenseUserNo: Code[20];
        ExpenseCategory: Code[20];
    begin
        if not CorpCard.Get(CorpCardTrans."Card Id") then
            Error(RecordNotFoundForCardErr, CorpCard.TableCaption(), CorpCardTrans."Card Id");
        CorpCard.TestField(Blocked, false);

        ExpenseUserNo := CorpCard."Expense User No.";
        if ExpenseUserNo = '' then
            RaiseMissingExpenseUserError(CorpCard);

        ExpenseCategory := GetExpenseCategoryFromMCC(CorpCardTrans.MCC);

        Expense.Init();
        Expense."Expense User No." := ExpenseUserNo;
        Expense."Status" := Expense."Status"::Open;
        if ExpenseCategory <> '' then
            Expense.Validate("Expense Category", ExpenseCategory);
        ExpensePaymentMethod.SetRange("Reimbursement Type", ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
        if not ExpensePaymentMethod.FindFirst() then
            RaiseMissingPaymentMethodError();
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Description := CopyStr(CorpCardTrans."Merchant Norm", 1, MaxStrLen(Expense.Description));
        Expense."Merchant Name" := CopyStr(CorpCardTrans."Merchant Norm", 1, MaxStrLen(Expense."Merchant Name"));
        Expense.Validate("Expense Date", CorpCardTrans."Trans Date");
        Expense.Validate("Currency Code", CorpCardTrans."Currency Code");
        Expense.Validate(Amount, CorpCardTrans.Amount);
        Expense."Credit Card Feed No." := CorpCardTrans."Entry No.";

        Expense.Insert(true);
        ExpenseNo := Expense."No.";

        CreateVatSpecificationsFromTransDetails(CorpCardTrans, ExpenseNo);

        CorpCardTrans."Expense No." := ExpenseNo;
        CorpCardTrans.Status := CorpCardTrans.Status::DraftCreated;
    end;

    local procedure RaiseMissingExpenseUserError(CorpCard: Record "EA Corp Card")
    var
        CorpCardErrorContext: Codeunit "EA Corp Card Error Context";
        MissingExpenseUserErrorInfo: ErrorInfo;
    begin
        MissingExpenseUserErrorInfo.Message := StrSubstNo(ExpenseUserNotSpecifiedForCardErr, CorpCard.FieldCaption("Expense User No."), CorpCard."Card Id");
        MissingExpenseUserErrorInfo.DataClassification := DataClassification::CustomerContent;
        MissingExpenseUserErrorInfo.ErrorType := ErrorType::Client;
        MissingExpenseUserErrorInfo.RecordId := CorpCard.RecordId;
        MissingExpenseUserErrorInfo.PageNo := Page::"EA Corp Card Cards";
        MissingExpenseUserErrorInfo.AddNavigationAction(ShowItLbl);
        CorpCardErrorContext.SetErrorInfo(MissingExpenseUserErrorInfo);
        Error(MissingExpenseUserErrorInfo);
    end;

    local procedure RaiseMissingPaymentMethodError()
    var
        CorpCardErrorContext: Codeunit "EA Corp Card Error Context";
        MissingPaymentMethodErrorInfo: ErrorInfo;
    begin
        MissingPaymentMethodErrorInfo.Message := CreditCardPaymentMethodMissingErr;
        MissingPaymentMethodErrorInfo.DataClassification := DataClassification::SystemMetadata;
        MissingPaymentMethodErrorInfo.ErrorType := ErrorType::Client;
        MissingPaymentMethodErrorInfo.PageNo := Page::"Expense Payment Methods";
        MissingPaymentMethodErrorInfo.AddNavigationAction(OpenPaymentMethodsLbl);
        CorpCardErrorContext.SetErrorInfo(MissingPaymentMethodErrorInfo);
        Error(MissingPaymentMethodErrorInfo);
    end;

    procedure LinkPosted(var CorpCardTrans: Record "EA Corp Card Trans"; PostedDocNo: Code[20])
    begin
        CorpCardTrans."Expense No." := PostedDocNo;
        CorpCardTrans.Status := CorpCardTrans.Status::Posted;
        CorpCardTrans.Modify();
    end;

    local procedure GetExpenseCategoryFromMCC(MCC: Code[4]): Code[20]
    var
        MCCMgt: Codeunit "EA Corp Card MCC Mgt";
    begin
        exit(MCCMgt.GetExpenseCategoryForMCC(MCC));
    end;

    local procedure CreateVatSpecificationsFromTransDetails(var CorpCardTrans: Record "EA Corp Card Trans"; ExpenseNo: Code[20])
    var
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        ExpenseVATSpecification: Record "Expense VAT Specification";
        BaseAmount: Decimal;
        VatAmount: Decimal;
        TotalAmount: Decimal;
        TotalFromDetails: Decimal;
        VatPercent: Decimal;
        LineNo: Integer;
    begin
        CorpCardTransDetail.SetRange("Trans Entry No.", CorpCardTrans."Entry No.");
        if not CorpCardTransDetail.FindSet() then
            exit;

        LineNo := 0;
        repeat
            BaseAmount := Round(CorpCardTransDetail.Quantity * CorpCardTransDetail."Unit Cost", 0.00001);
            VatAmount := CorpCardTransDetail."VAT Amount";
            if VatAmount = 0 then
                VatAmount := CorpCardTransDetail."Tax Amount";
            TotalAmount := BaseAmount + VatAmount;
            TotalFromDetails += TotalAmount;

            if TotalAmount = 0 then
                continue;

            VatPercent := 0;
            if BaseAmount <> 0 then
                VatPercent := Round((VatAmount / BaseAmount) * 100, 0.00001);

            ExpenseVATSpecification.Init();
            ExpenseVATSpecification."Expense No." := ExpenseNo;
            LineNo += 1;
            ExpenseVATSpecification."Line No." := LineNo;
            ExpenseVATSpecification.Validate(Amount, TotalAmount);
            if VatPercent > 0 then
                ExpenseVATSpecification.Validate("VAT %", VatPercent);
            ExpenseVATSpecification.Source := ExpenseVATSpecification.Source::Agent;
            ExpenseVATSpecification.Insert(true);
        until CorpCardTransDetail.Next() = 0;

        if Round(TotalFromDetails, 0.01) <> Round(CorpCardTrans.Amount, 0.01) then
            CorpCardTrans."Reject Reason" := CopyStr(StrSubstNo(Level3ReconcileWarnLbl, Format(Round(TotalFromDetails, 0.01)), Format(Round(CorpCardTrans.Amount, 0.01))), 1, MaxStrLen(CorpCardTrans."Reject Reason"))
        else
            if CorpCardTrans."Reject Reason" <> '' then
                CorpCardTrans."Reject Reason" := '';
    end;
}
