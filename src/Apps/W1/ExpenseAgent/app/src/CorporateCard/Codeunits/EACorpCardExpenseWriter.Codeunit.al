// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Creates draft Expense records from corporate card transactions.
/// Implements EACorpCardExpWriterInterface to populate expense fields from transaction data.
/// </summary>
codeunit 7212 "EA Corp Card Expense Writer" implements "EA Corp Card Expense Writer"
{
    Access = Internal;
    Permissions = tabledata "Expense VAT Specification" = rimd;

    var
        ExpenseUserNotFoundErr: Label 'Expense User not found for card %1.', Comment = '%1 is the card id.';
        Level3ReconcileWarnLbl: Label 'Level 3 detail total %1 does not match transaction amount %2.', Comment = '%1 = detail total, %2 = transaction amount';

    procedure CreateDraftFromTrans(var CorpCardTrans: Record "EA Corp Card Trans"; var ExpenseNo: Code[20])
    var
        Expense: Record Expense;
        CorpCard: Record "EA Corp Card";
        ExpenseUserNo: Code[20];
        ExpenseCategory: Code[20];
    begin
        if not CorpCard.Get(CorpCardTrans."Card Id") then
            Error(ExpenseUserNotFoundErr, CorpCardTrans."Card Id");

        ExpenseUserNo := CorpCard."Expense User No.";
        if ExpenseUserNo = '' then
            Error(ExpenseUserNotFoundErr, CorpCardTrans."Card Id");

        ExpenseCategory := GetExpenseCategoryFromMCC(CorpCardTrans.MCC);

        Expense.Init();
        Expense."Expense User No." := ExpenseUserNo;
        Expense."Status" := Expense."Status"::Open;
        if ExpenseCategory <> '' then
            Expense.Validate("Expense Category", ExpenseCategory);
        Expense.Description := CopyStr(CorpCardTrans."Merchant Norm", 1, MaxStrLen(Expense.Description));
        Expense."Merchant Name" := CopyStr(CorpCardTrans."Merchant Norm", 1, MaxStrLen(Expense."Merchant Name"));
        Expense."Expense Date" := CorpCardTrans."Trans Date";
        Expense.Amount := CorpCardTrans.Amount;
        Expense."Currency Code" := CorpCardTrans."Currency Code";
        Expense."Credit Card Feed No." := CorpCardTrans."Entry No.";

        Expense.Insert(true);
        ExpenseNo := Expense."No.";

        CreateVatSpecificationsFromTransDetails(CorpCardTrans, ExpenseNo);

        CorpCardTrans."Expense No." := ExpenseNo;
        CorpCardTrans.Status := CorpCardTrans.Status::DraftCreated;
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

    local procedure CreateVatSpecificationsFromTransDetails(CorpCardTrans: Record "EA Corp Card Trans"; ExpenseNo: Code[20])
    var
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        CorpCardTransForUpdate: Record "EA Corp Card Trans";
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

        if CorpCardTransForUpdate.Get(CorpCardTrans."Entry No.") then begin
            if Round(TotalFromDetails, 0.01) <> Round(CorpCardTrans.Amount, 0.01) then
                CorpCardTransForUpdate."Reject Reason" := CopyStr(StrSubstNo(Level3ReconcileWarnLbl, Format(Round(TotalFromDetails, 0.01)), Format(Round(CorpCardTrans.Amount, 0.01))), 1, MaxStrLen(CorpCardTransForUpdate."Reject Reason"))
            else
                if CorpCardTransForUpdate."Reject Reason" <> '' then
                    CorpCardTransForUpdate."Reject Reason" := '';
            CorpCardTransForUpdate.Modify(true);
        end;
    end;
}
