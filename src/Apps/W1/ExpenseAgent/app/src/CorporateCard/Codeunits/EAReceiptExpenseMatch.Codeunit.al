// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Finds the corporate card expense that an incoming receipt belongs to.
/// Candidates are card-created expenses that are still waiting for a receipt, either not on an expense report yet
/// or on an open expense report whose line has no receipt.
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
    /// Returns true when the expense is a card-created expense waiting to be added to an expense report.
    /// Keep in sync with the Expense field "Pending Card Expense", which exposes the same rule through the expenses API.
    /// </summary>
    internal procedure IsPendingCardExpense(Expense: Record Expense): Boolean
    begin
        exit((Expense.Source = Expense.Source::CorporateCard) and
             (Expense."Credit Card Feed No." <> 0) and
             (Expense.Status = Expense.Status::Open) and
             (Expense."Expense Report No." = ''));
    end;

    /// <summary>
    /// Returns the SystemId of the card expense that the receipt belongs to, or an empty GUID when none matches.
    /// Candidates must have the same expense user, currency and exact amount, and an expense date within the
    /// Corp Card Date Match Window. When CardLast4 is four digits, the expense must also be paid with one of the user's cards
    /// ending in those digits. Otherwise nothing proves the receipt was paid by card, so the merchant name must be similar
    /// enough. The closest date and most similar merchant name win; ties keep the lowest expense number.
    /// </summary>
    internal procedure FindMatchingExpense(ExpenseUserSystemId: Guid; ExpenseDate: Date; Amount: Decimal; CurrencyCode: Code[10]; MerchantName: Text[100]; CardLast4: Text) ExpenseSystemId: Guid
    var
        Expense: Record Expense;
        CardIds: List of [Code[50]];
        ExpenseUserNo: Code[20];
        FilterByCard: Boolean;
        HasCandidate: Boolean;
        MerchantSimilarity: Decimal;
        Score: Decimal;
        BestScore: Decimal;
    begin
        ExpenseUserNo := GetExpenseUserNo(ExpenseUserSystemId, ExpenseDate, Amount);
        SetCandidateFilters(Expense, ExpenseUserNo, ExpenseDate, GetDateWindow(), Amount, CurrencyCode);
        FilterByCard := GetCardIdsEndingIn(ExpenseUserNo, CardLast4, CardIds);

        Expense.SetLoadFields(SystemId, "No.", Status, "Expense Report No.", "Expense Date", "Merchant Name", "Corporate Card Id");
        if not Expense.FindSet() then
            exit;

        HasCandidate := false;
        BestScore := 0;
        repeat
            if IsPaidWithCard(Expense, FilterByCard, CardIds) and IsWaitingForReceipt(Expense) then begin
                MerchantSimilarity := GetMerchantSimilarity(MerchantName, Expense."Merchant Name");
                if FilterByCard or (MerchantSimilarity >= GetMinMerchantSimilarity()) then begin
                    Score := CalculateMatchScore(ExpenseDate, MerchantSimilarity, Expense);
                    if (not HasCandidate) or (Score > BestScore) then begin
                        HasCandidate := true;
                        BestScore := Score;
                        ExpenseSystemId := Expense.SystemId;
                    end;
                end;
            end;
        until Expense.Next() = 0;
    end;

    /// <summary>
    /// Returns ExpenseSystemId when that expense is a card expense the receipt belongs to, or an empty GUID otherwise.
    /// Uses the same rules as FindMatchingExpense, except the merchant name: the user picked the expense, so it is not checked.
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
        Expense.SetLoadFields("No.", Status, "Expense Report No.", "Corporate Card Id");
        if not Expense.FindFirst() then
            exit(EmptyGuid);
        if not IsPaidWithCard(Expense, GetCardIdsEndingIn(ExpenseUserNo, CardLast4, CardIds), CardIds) then
            exit(EmptyGuid);
        if not IsWaitingForReceipt(Expense) then
            exit(EmptyGuid);
        exit(ExpenseSystemId);
    end;

    /// <summary>
    /// Returns true when a receipt can still be applied to the card expense: either the expense is not on an expense report yet,
    /// or it is on an open expense report and its line has no receipt and no lost-receipt declaration.
    /// </summary>
    internal procedure IsWaitingForReceipt(Expense: Record Expense): Boolean
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        if Expense."Expense Report No." = '' then
            exit(Expense.Status = Expense.Status::Open);

        if Expense.Status <> Expense.Status::Submitted then
            exit(false);
        ExpenseReportHeader.SetLoadFields(Status);
        if not ExpenseReportHeader.Get(Expense."Expense Report No.") then
            exit(false);
        if ExpenseReportHeader.Status <> ExpenseReportHeader.Status::Open then
            exit(false);

        ExpenseReportLine.SetRange("Document No.", Expense."Expense Report No.");
        ExpenseReportLine.SetRange("Expense No.", Expense."No.");
        ExpenseReportLine.SetRange("Receipt Attached", false);
        ExpenseReportLine.SetFilter("No Receipt Type", '<>%1', ExpenseReportLine."No Receipt Type"::"Lost Receipt");
        exit(not ExpenseReportLine.IsEmpty());
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
        // The open-and-not-on-a-report or open-report-line part of the rule is checked per record in IsWaitingForReceipt.
        Expense.SetRange("Expense User No.", ExpenseUserNo);
        Expense.SetRange(Source, Expense.Source::CorporateCard);
        Expense.SetFilter("Credit Card Feed No.", '<>%1', 0);
        Expense.SetRange("Receipt Attached", false);
        Expense.SetFilter("No Receipt Type", '<>%1', Expense."No Receipt Type"::"Lost Receipt");
        Expense.SetFilter(Status, '%1|%2', Expense.Status::Open, Expense.Status::Submitted);
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
    local procedure CalculateMatchScore(ReceiptDate: Date; MerchantSimilarity: Decimal; Expense: Record Expense): Decimal
    begin
        exit(100 - Abs(Expense."Expense Date" - ReceiptDate) * 5 + MerchantSimilarity * 100);
    end;

    // Statement merchant names often add a location or legal suffix ("FOURTH COFFEE CANARY WHARF" for "Fourth Coffee"),
    // so the shorter name is also compared with the start of the longer one.
    local procedure GetMerchantSimilarity(ReceiptMerchantName: Text; ExpenseMerchantName: Text): Decimal
    var
        ShorterName: Text;
        LongerName: Text;
        FullSimilarity: Decimal;
        PrefixSimilarity: Decimal;
    begin
        ReceiptMerchantName := DelChr(ReceiptMerchantName, '<>', ' ');
        ExpenseMerchantName := DelChr(ExpenseMerchantName, '<>', ' ');
        if (ReceiptMerchantName = '') or (ExpenseMerchantName = '') then
            exit(0);

        ShorterName := ReceiptMerchantName;
        LongerName := ExpenseMerchantName;
        if StrLen(ShorterName) > StrLen(LongerName) then begin
            ShorterName := ExpenseMerchantName;
            LongerName := ReceiptMerchantName;
        end;

        FullSimilarity := EnhMatchMgt.CalculateSimilarity(ReceiptMerchantName, ExpenseMerchantName);
        PrefixSimilarity := EnhMatchMgt.CalculateSimilarity(ShorterName, CopyStr(LongerName, 1, StrLen(ShorterName)));
        if PrefixSimilarity > FullSimilarity then
            exit(PrefixSimilarity);
        exit(FullSimilarity);
    end;

    local procedure GetMinMerchantSimilarity(): Decimal
    begin
        exit(0.6);
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
