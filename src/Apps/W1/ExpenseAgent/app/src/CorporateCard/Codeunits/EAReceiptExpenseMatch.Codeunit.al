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
    /// Keep in sync with the Expense field "Pending Card Expense", which exposes the same rule through the expenses API.
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
    /// Corp Card Date Match Window. When CardLast4 is four digits, the expense must also be paid with one of the user's cards
    /// ending in those digits. The closest date and most similar merchant name win; ties keep the lowest expense number.
    /// </summary>
    internal procedure FindMatchingExpense(ExpenseUserSystemId: Guid; ExpenseDate: Date; Amount: Decimal; CurrencyCode: Code[10]; MerchantName: Text[100]; CardLast4: Text) ExpenseSystemId: Guid
    var
        Expense: Record Expense;
        CardIds: List of [Code[50]];
        ExpenseUserNo: Code[20];
        FilterByCard: Boolean;
        HasCandidate: Boolean;
        Score: Decimal;
        BestScore: Decimal;
    begin
        ExpenseUserNo := GetExpenseUserNo(ExpenseUserSystemId, ExpenseDate, Amount);
        SetCandidateFilters(Expense, ExpenseUserNo, ExpenseDate, GetDateWindow(), Amount, CurrencyCode);
        FilterByCard := GetCardIdsEndingIn(ExpenseUserNo, CardLast4, CardIds);

        Expense.SetLoadFields(SystemId, "Expense Date", "Merchant Name", "Corporate Card Id");
        if not Expense.FindSet() then
            exit;

        HasCandidate := false;
        BestScore := 0;
        repeat
            if IsPaidWithCard(Expense, FilterByCard, CardIds) then begin
                Score := CalculateMatchScore(ExpenseDate, MerchantName, Expense);
                if (not HasCandidate) or (Score > BestScore) then begin
                    HasCandidate := true;
                    BestScore := Score;
                    ExpenseSystemId := Expense.SystemId;
                end;
            end;
        until Expense.Next() = 0;
    end;

    /// <summary>
    /// Returns ExpenseSystemId when that expense is a pending card expense the receipt belongs to, or an empty GUID otherwise.
    /// Uses the same rules as FindMatchingExpense; the merchant name only ranks candidates, so it is not checked.
    /// </summary>
    internal procedure CheckMatchingExpense(ExpenseUserSystemId: Guid; ExpenseSystemId: Guid; ExpenseDate: Date; Amount: Decimal; CurrencyCode: Code[10]; CardLast4: Text): Guid
    var
        Expense: Record Expense;
        CardIds: List of [Code[50]];
        ExpenseUserNo: Code[20];
        EmptyGuid: Guid;
    begin
        ExpenseUserNo := GetExpenseUserNo(ExpenseUserSystemId, ExpenseDate, Amount);
        SetCandidateFilters(Expense, ExpenseUserNo, ExpenseDate, GetDateWindow(), Amount, CurrencyCode);
        Expense.SetRange(SystemId, ExpenseSystemId);
        Expense.SetLoadFields("Corporate Card Id");
        if not Expense.FindFirst() then
            exit(EmptyGuid);
        if not IsPaidWithCard(Expense, GetCardIdsEndingIn(ExpenseUserNo, CardLast4, CardIds), CardIds) then
            exit(EmptyGuid);
        exit(ExpenseSystemId);
    end;

    // Returns false when CardLast4 is not exactly four digits, so matching ignores the card.
    local procedure GetCardIdsEndingIn(ExpenseUserNo: Code[20]; CardLast4: Text; var CardIds: List of [Code[50]]): Boolean
    var
        CorpCard: Record "EA Corp Card";
    begin
        if (StrLen(CardLast4) <> 4) or (DelChr(CardLast4, '=', '0123456789') <> '') then
            exit(false);

        CorpCard.SetRange("Expense User No.", ExpenseUserNo);
        CorpCard.SetLoadFields("Card Id", "Masked Card No.");
        if CorpCard.FindSet() then
            repeat
                if CorpCard.GetLastFourDigits() = CardLast4 then
                    CardIds.Add(CorpCard."Card Id");
            until CorpCard.Next() = 0;
        exit(true);
    end;

    local procedure IsPaidWithCard(Expense: Record Expense; FilterByCard: Boolean; CardIds: List of [Code[50]]): Boolean
    begin
        if not FilterByCard then
            exit(true);
        exit(CardIds.Contains(Expense."Corporate Card Id"));
    end;

    local procedure GetExpenseUserNo(ExpenseUserSystemId: Guid; ExpenseDate: Date; Amount: Decimal): Code[20]
    var
        ExpenseUser: Record "Expense User";
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
        exit(ExpenseUser."No.");
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
