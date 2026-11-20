// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Finds the corporate card expense that an incoming receipt belongs to.
/// Candidates are card-created expenses that are still waiting for a receipt and an expense report.
/// </summary>
codeunit 7438 "EA Receipt Expense Match"
{
    Access = Internal;

    var
        EnhMatchMgt: Codeunit "EA Corp Card Enh. Match Mgt";
        CurrencyHelper: Codeunit "Expense API Currency Helper";
        ExpenseUserRequiredErr: Label 'Card expense matching must be requested for an expense user through expenseUsers({id})/cardExpenseMatches.';
        ExpenseUserNotFoundErr: Label 'Expense user %1 was not found.', Comment = '%1 = Expense user system ID';
        ExpenseDateRequiredErr: Label 'The receipt expense date must be specified.';
        AmountRequiredErr: Label 'The receipt amount must be specified.';

    /// <summary>
    /// Sets the filters that define a card-created expense waiting for a receipt and an expense report.
    /// </summary>
    internal procedure SetPendingCardExpenseFilters(var Expense: Record Expense)
    begin
        Expense.SetRange(Source, Expense.Source::CorporateCard);
        Expense.SetFilter("Credit Card Feed No.", '<>%1', 0);
        Expense.SetRange("Receipt Attached", false);
        Expense.SetRange("No Receipt Type", Expense."No Receipt Type"::" ");
        Expense.SetRange(Status, Expense.Status::Open);
        Expense.SetRange("Expense Report No.", '');
    end;

    /// <summary>
    /// Returns the SystemId of the pending card expense that the receipt belongs to, or an empty GUID when none matches.
    /// Candidates must have the same expense user, currency and exact amount, and an expense date within the
    /// Corp Card Date Match Window. The closest date and most similar merchant name win; ties keep the lowest expense number.
    /// </summary>
    internal procedure FindMatchingExpense(ExpenseUserSystemId: Guid; ExpenseDate: Date; Amount: Decimal; CurrencyCode: Code[10]; MerchantName: Text[100]) ExpenseSystemId: Guid
    var
        ExpenseUser: Record "Expense User";
        Expense: Record Expense;
        Score: Decimal;
        BestScore: Decimal;
    begin
        if IsNullGuid(ExpenseUserSystemId) then
            Error(ExpenseUserRequiredErr);
        if ExpenseDate = 0D then
            Error(ExpenseDateRequiredErr);
        if Amount = 0 then
            Error(AmountRequiredErr);

        ExpenseUser.SetLoadFields("No.");
        if not ExpenseUser.GetBySystemId(ExpenseUserSystemId) then
            Error(ExpenseUserNotFoundErr, ExpenseUserSystemId);

        SetCandidateFilters(Expense, ExpenseUser."No.", ExpenseDate, GetDateWindow(), Amount, CurrencyCode);

        Expense.SetLoadFields(SystemId, "Expense Date", "Merchant Name");
        if not Expense.FindSet() then
            exit;

        BestScore := CalculateMatchScore(ExpenseDate, MerchantName, Expense);
        ExpenseSystemId := Expense.SystemId;
        while Expense.Next() <> 0 do begin
            Score := CalculateMatchScore(ExpenseDate, MerchantName, Expense);
            if Score > BestScore then begin
                BestScore := Score;
                ExpenseSystemId := Expense.SystemId;
            end;
        end;
    end;

    local procedure SetCandidateFilters(var Expense: Record Expense; ExpenseUserNo: Code[20]; ExpenseDate: Date; DateWindow: Integer; Amount: Decimal; CurrencyCode: Code[10])
    begin
        Expense.SetRange("Expense User No.", ExpenseUserNo);
        SetPendingCardExpenseFilters(Expense);
        Expense.SetRange(Amount, Amount);
        Expense.SetRange("Expense Date", ExpenseDate - DateWindow, ExpenseDate + DateWindow);
        SetCurrencyFilter(Expense, CurrencyCode);
    end;

    local procedure GetDateWindow(): Integer
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        if ExpenseAgentSetup."Corp Card Date Match Window" < 0 then
            exit(0);
        exit(ExpenseAgentSetup."Corp Card Date Match Window");
    end;

    // Each day of date difference costs as much as 5 percentage points of merchant name similarity.
    local procedure CalculateMatchScore(ReceiptDate: Date; ReceiptMerchantName: Text[100]; Expense: Record Expense): Decimal
    begin
        exit(100 - Abs(Expense."Expense Date" - ReceiptDate) * 5 + EnhMatchMgt.CalculateSimilarity(ReceiptMerchantName, Expense."Merchant Name") * 100);
    end;

    // LCY can be stored as blank or as the LCY code, so both are accepted for an LCY receipt.
    local procedure SetCurrencyFilter(var Expense: Record Expense; CurrencyCode: Code[10])
    var
        LCYCode: Code[10];
    begin
        if CurrencyHelper.GetCurrencyCodeFromAPI(CurrencyCode) <> '' then begin
            Expense.SetRange("Currency Code", CurrencyCode);
            exit;
        end;

        LCYCode := CurrencyHelper.GetCurrencyCodeForAPI('');
        if LCYCode = '' then
            Expense.SetRange("Currency Code", '')
        else
            Expense.SetFilter("Currency Code", '%1|%2', '', LCYCode);
    end;
}
