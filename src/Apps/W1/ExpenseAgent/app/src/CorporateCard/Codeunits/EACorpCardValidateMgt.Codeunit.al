// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Setup;

codeunit 7435 "EA Corp Card Validate Mgt"
{
    Access = Internal;

    var
        MissingProviderCodeErr: Label 'Provider Code is missing.';
        NoCardMatchErr: Label 'No corporate card could be identified from the last four digits or an existing expense with the same date, amount, and currency.';
        InvalidCardLast4Err: Label 'Card Last 4 must contain exactly four digits. Full card numbers and internal card identifiers are not accepted.';
        AmbiguousCardErr: Label 'More than one corporate card matches the last four digits for this provider.';
        AmbiguousExpenseErr: Label 'More than one expense or corporate card matches this transaction. Review the card and expense setup.';
        CardNotFoundErr: Label 'The corporate card could not be found.';
        BlockedCardErr: Label 'The corporate card is blocked.';
        MissingProviderTransIdErr: Label 'Provider Trans Id is missing.';
        MissingTransDateErr: Label 'Trans Date is missing.';
        CardProviderMismatchErr: Label 'Card %1 belongs to provider %2, not provider %3.', Comment = '%1 = card id, %2 = card provider code, %3 = transaction provider code';

    internal procedure ValidateTrans(var CorpCardTrans: Record "EA Corp Card Trans"): Boolean
    var
        ValidationReason: Text[250];
    begin
        exit(ValidateTrans(CorpCardTrans, ValidationReason));
    end;

    internal procedure ValidateTrans(var CorpCardTrans: Record "EA Corp Card Trans"; var ValidationReason: Text[250]): Boolean
    var
        CorpCard: Record "EA Corp Card";
    begin
        NormalizeCurrencyCode(CorpCardTrans."Currency Code");

        if CorpCardTrans."Provider Code" = '' then begin
            ValidationReason := MissingProviderCodeErr;
            exit(false);
        end;
        if CorpCardTrans."Provider Trans Id" = '' then begin
            ValidationReason := MissingProviderTransIdErr;
            exit(false);
        end;
        if CorpCardTrans."Trans Date" = 0D then begin
            ValidationReason := MissingTransDateErr;
            exit(false);
        end;

        if CorpCardTrans."Card Id" = '' then begin
            if CorpCardTrans."Card Last 4" <> '' then begin
                if not ResolveCardFromLast4(CorpCardTrans, CorpCard, ValidationReason) then
                    exit(false);
            end else
                if not ResolveCardFromExpense(CorpCardTrans, CorpCard, CorpCardTrans."Expense Match No.", ValidationReason) then
                    exit(false);
            CorpCardTrans."Card Id" := CorpCard."Card Id";
        end;
        if not CorpCard.Get(CorpCardTrans."Card Id") then begin
            ValidationReason := CardNotFoundErr;
            exit(false);
        end;
        if CorpCard.Blocked then begin
            ValidationReason := BlockedCardErr;
            exit(false);
        end;
        if CorpCard."Provider Code" <> CorpCardTrans."Provider Code" then begin
            ValidationReason := CopyStr(StrSubstNo(CardProviderMismatchErr, CorpCardTrans."Card Id", CorpCard."Provider Code", CorpCardTrans."Provider Code"), 1, MaxStrLen(ValidationReason));
            exit(false);
        end;
        ValidationReason := '';

        exit(true);
    end;

    internal procedure TrySetCardLast4(CardLast4: Text; var CorpCardTrans: Record "EA Corp Card Trans"; var ValidationReason: Text[250]): Boolean
    begin
        if (CardLast4 <> '') and ((StrLen(CardLast4) <> 4) or (DelChr(CardLast4, '=', '0123456789') <> '')) then begin
            ValidationReason := InvalidCardLast4Err;
            exit(false);
        end;
        CorpCardTrans."Card Last 4" := CopyStr(CardLast4, 1, MaxStrLen(CorpCardTrans."Card Last 4"));
        exit(true);
    end;

    local procedure ResolveCardFromLast4(CorpCardTrans: Record "EA Corp Card Trans"; var CorpCard: Record "EA Corp Card"; var ValidationReason: Text[250]): Boolean
    begin
        if not TrySetCardLast4(CorpCardTrans."Card Last 4", CorpCardTrans, ValidationReason) then
            exit(false);
        CorpCard.SetRange("Provider Code", CorpCardTrans."Provider Code");
        CorpCard.SetFilter("Masked Card No.", '%1', '*' + CorpCardTrans."Card Last 4");
        if not CorpCard.FindFirst() then begin
            ValidationReason := NoCardMatchErr;
            exit(false);
        end;
        if CorpCard.Next() <> 0 then begin
            ValidationReason := AmbiguousCardErr;
            exit(false);
        end;
        exit(true);
    end;

    internal procedure ResolveCardFromExpense(CorpCardTrans: Record "EA Corp Card Trans"; var CorpCard: Record "EA Corp Card"; var ExpenseNo: Code[20]; var ValidationReason: Text[250]): Boolean
    var
        ProviderCorpCard: Record "EA Corp Card";
        TempCorpCard: Record "EA Corp Card" temporary;
        Expense: Record Expense;
        ExpensePaymentMethod: Record "Expense Payment Method";
        TempExpensePaymentMethod: Record "Expense Payment Method" temporary;
        MatchedCardId: Code[50];
    begin
        ExpenseNo := '';
        Expense.SetRange(Status, Expense.Status::Open);
        Expense.SetRange("Credit Card Feed No.", 0);
        Expense.SetRange("Expense Date", CorpCardTrans."Trans Date");
        Expense.SetRange(Amount, CorpCardTrans.Amount);
        Expense.SetRange("Currency Code", CorpCardTrans."Currency Code");
        Expense.SetLoadFields("Expense User No.", "Payment Method Code");
        if Expense.FindSet() then begin
            ProviderCorpCard.SetRange("Provider Code", CorpCardTrans."Provider Code");
            ProviderCorpCard.SetLoadFields("Expense User No.");
            if ProviderCorpCard.FindSet() then
                repeat
                    TempCorpCard.Init();
                    TempCorpCard."Card Id" := ProviderCorpCard."Card Id";
                    TempCorpCard."Expense User No." := ProviderCorpCard."Expense User No.";
                    TempCorpCard.Insert();
                until ProviderCorpCard.Next() = 0;
            TempCorpCard.SetCurrentKey("Expense User No.");

            ExpensePaymentMethod.SetRange("Reimbursement Type", ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
            ExpensePaymentMethod.SetLoadFields(Code);
            if ExpensePaymentMethod.FindSet() then
                repeat
                    TempExpensePaymentMethod.Init();
                    TempExpensePaymentMethod.Code := ExpensePaymentMethod.Code;
                    TempExpensePaymentMethod.Insert();
                until ExpensePaymentMethod.Next() = 0;

            repeat
                if Expense."Expense User No." = '' then
                    continue;
                if not TempExpensePaymentMethod.Get(Expense."Payment Method Code") then
                    continue;
                TempCorpCard.SetRange("Expense User No.", Expense."Expense User No.");
                if not TempCorpCard.FindSet() then
                    continue;
                if (ExpenseNo <> '') or (TempCorpCard.Next() <> 0) then begin
                    ValidationReason := AmbiguousExpenseErr;
                    exit(false);
                end;
                ExpenseNo := Expense."No.";
                MatchedCardId := TempCorpCard."Card Id";
            until Expense.Next() = 0;
        end;
        if ExpenseNo = '' then begin
            ValidationReason := NoCardMatchErr;
            exit(false);
        end;
        CorpCard.Reset();
        CorpCard.Get(MatchedCardId);
        if CorpCard.Blocked then begin
            ValidationReason := BlockedCardErr;
            exit(false);
        end;
        exit(true);
    end;

    internal procedure NormalizeCurrencyCode(var CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode = '' then
            exit;

        GeneralLedgerSetup.Get();
        if CurrencyCode = GeneralLedgerSetup."LCY Code" then
            CurrencyCode := '';
    end;
}