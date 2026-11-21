// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

// [FEATURE] [Expense Agent] [Corporate Card] [Receipt Matching]
codeunit 148355 EAReceiptMatchTests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Assert: Codeunit Assert;
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryERM: Codeunit "Library - ERM";
        LibraryExpense: Codeunit "Library - Expense";
        ReceiptExpenseMatch: Codeunit "EA Receipt Expense Match";

    [Test]
    procedure ReceiptMatchesCardExpenseWithinDateWindow()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] A receipt with the same amount and currency matches the card expense that is still waiting for a receipt.
        Initialize();

        // [GIVEN] A card expense of 20 waiting for a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] A receipt dated within the date window is matched.
        // [THEN] The card expense is returned.
        Assert.AreEqual(Expense.SystemId, FindMatch(Expense, WorkDate() + 2, 20), 'The card expense must match the receipt.');
    end;

    [Test]
    procedure ReceiptWithDifferentAmountDoesNotMatch()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] The receipt amount must match the card expense amount exactly.
        Initialize();

        // [GIVEN] A card expense of 20 waiting for a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] A receipt of 21 on the same date is matched.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 21)), 'A different amount must not match.');
    end;

    [Test]
    procedure ReceiptDateOutsideWindowDoesNotMatch()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] The receipt date must be within the date window of the card expense.
        Initialize();

        // [GIVEN] A card expense of 20 waiting for a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] A receipt of 20 dated 8 days later, outside the 7-day window, is matched.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate() + 8, 20)), 'A date outside the window must not match.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchExpenseThatAlreadyHasReceipt()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Card expenses that already have a receipt are not candidates.
        Initialize();

        // [GIVEN] A card expense that already has a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        Expense."Receipt Attached" := true;
        Expense.Modify();

        // [WHEN] A receipt with the same amount and date is matched.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 20)), 'An expense with a receipt must not match.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchLostReceiptCardExpense()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Card expenses declared as lost receipt are not candidates.
        Initialize();

        // [GIVEN] A card expense declared as lost receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        Expense."No Receipt Type" := Expense."No Receipt Type"::"Lost Receipt";
        Expense.Modify();

        // [WHEN] A receipt with the same amount and date is matched.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 20)), 'A lost receipt expense must not match.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchReceiptNotNeededCardExpense()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Card expenses that do not need a receipt are not candidates.
        Initialize();

        // [GIVEN] A card expense marked as receipt not needed.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        Expense."No Receipt Type" := Expense."No Receipt Type"::"Receipt not needed";
        Expense.Modify();

        // [WHEN] A receipt with the same amount and date is matched.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 20)), 'An expense that does not need a receipt must not match.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchManualExpenseLinkedToTransaction()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Only card-created expenses are candidates; a manual expense already has its own receipt flow.
        Initialize();

        // [GIVEN] A manual expense without a receipt linked to a card transaction.
        CreateLinkedManualExpense(Expense);

        // [WHEN] A receipt with the same amount and date is matched.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, Expense."Expense Date", Expense.Amount)), 'A manual expense must not match.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchOtherUsersCardExpense()
    var
        Expense: Record Expense;
        OtherCorpCard: Record "EA Corp Card";
        OtherExpenseUser: Record "Expense User";
    begin
        // [SCENARIO] Only the expense user's own card expenses are candidates.
        Initialize();

        // [GIVEN] A card expense waiting for a receipt and another expense user with their own card.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        OtherCorpCard.Get('CORPCARD-0002');
        OtherExpenseUser.Get(OtherCorpCard."Expense User No.");

        // [WHEN] The receipt is matched for the other expense user.
        // [THEN] No expense is returned.
        Assert.IsTrue(
            IsNullGuid(ReceiptExpenseMatch.FindMatchingExpense(OtherExpenseUser.SystemId, WorkDate(), 20, '', 'CONTOSO COFFEE', '')),
            'Another user''s expense must not match.');
    end;

    [Test]
    procedure ReceiptMatchesClosestDateAndMerchant()
    var
        FartherExpense: Record Expense;
        CloserExpense: Record Expense;
    begin
        // [SCENARIO] When several card expenses qualify, the closest date and most similar merchant win.
        Initialize();

        // [GIVEN] Two card expenses of 20: one 3 days earlier from another merchant, one on the receipt date from the same merchant.
        CreateCardExpense(FartherExpense, 'CORPCARD-0001', WorkDate() - 3, 'FABRIKAM TAXI');
        CreateCardExpense(CloserExpense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] The receipt is matched.
        // [THEN] The expense with the same date and merchant is returned.
        Assert.AreEqual(CloserExpense.SystemId, FindMatch(CloserExpense, WorkDate(), 20), 'The closest candidate must match.');
    end;

    [Test]
    procedure CategoryCanBeSetOnCardExpenseWithoutChangingCardValues()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        PaymentMethodCode: Code[10];
    begin
        // [SCENARIO] A pending card expense gets its category from the user; amount, currency, date and card payment come from the card and stay unchanged.
        Initialize();

        // [GIVEN] A card expense waiting for a receipt and an employee-paid category.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        PaymentMethodCode := Expense."Payment Method Code";
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [WHEN] The category is changed to an employee-paid category.
        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Expense.Modify(true);

        // [THEN] The category is saved and the card values are kept.
        Expense.Get(Expense."No.");
        Expense.TestField("Expense Category", ExpenseCategory.Code);
        Expense.TestField(Amount, 20);
        Expense.TestField("Currency Code", '');
        Expense.TestField("Expense Date", WorkDate());
        Expense.TestField("Reimbursement Type", Expense."Reimbursement Type"::"Credit Card");
        Expense.TestField("Payment Method Code", PaymentMethodCode);
    end;

    [Test]
    procedure ClearingCategoryOnManualExpenseKeepsCurrency()
    var
        Expense: Record Expense;
        CorpCard: Record "EA Corp Card";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] Clearing the category on a manual expense resets the amount but keeps the currency.
        Initialize();

        // [GIVEN] A manual expense of 20 in a foreign currency.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 2, 1);
        CorpCard.Get('CORPCARD-0001');
        LibraryExpense.CreateExpense(Expense, CorpCard."Expense User No.", 'AIRLINE', '', '', false, CurrencyCode, 20, false);

        // [WHEN] The category is cleared.
        Expense.Validate("Expense Category", '');
        Expense.Modify(true);

        // [THEN] The amount is reset and the currency is kept.
        Expense.Get(Expense."No.");
        Expense.TestField(Source, Expense.Source::Manual);
        Expense.TestField(Amount, 0);
        Expense.TestField("Currency Code", CurrencyCode);
    end;

    [Test]
    procedure CheckReturnsExpenseWhenReceiptFits()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Checking a receipt against a given card expense returns that expense when the receipt fits it.
        Initialize();

        // [GIVEN] A card expense of 20 waiting for a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] A receipt of 20 dated within the window is checked against the expense.
        // [THEN] The expense is returned.
        Assert.AreEqual(Expense.SystemId, CheckMatch(Expense, Expense.SystemId, WorkDate() + 2, 20), 'The receipt must fit the card expense.');
    end;

    [Test]
    procedure CheckReturnsEmptyWhenAmountDiffers()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Checking a receipt with another amount against a given card expense returns no match.
        Initialize();

        // [GIVEN] A card expense of 20 waiting for a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] A receipt of 21 is checked against the expense.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(CheckMatch(Expense, Expense.SystemId, WorkDate(), 21)), 'A different amount must not fit.');
    end;

    [Test]
    procedure CheckReturnsEmptyForOtherUsersExpense()
    var
        Expense: Record Expense;
        OtherExpense: Record Expense;
    begin
        // [SCENARIO] A receipt cannot be checked against another expense user's card expense.
        Initialize();

        // [GIVEN] A card expense for the expense user and a card expense with the same values for another expense user.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        CreateCardExpense(OtherExpense, 'CORPCARD-0002', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] The receipt is checked for the expense user against the other user's expense.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(CheckMatch(Expense, OtherExpense.SystemId, WorkDate(), 20)), 'Another user''s expense must not fit.');
    end;

    [Test]
    procedure ReceiptCardLast4SelectsExpensePaidWithThatCard()
    var
        Expense: Record Expense;
        OtherCardExpense: Record Expense;
    begin
        // [SCENARIO] When the receipt shows the card's last four digits, only expenses paid with a card ending in those digits match.
        Initialize();

        // [GIVEN] Two equal card expenses of the same expense user, paid with cards ending in 0001 and 7777.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        CreateCardExpense(OtherCardExpense, CreateSecondCard('CORPCARD-0001', '****7777'), WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] The receipt is matched with card last four digits 7777.
        // [THEN] The expense paid with the card ending in 7777 is returned.
        Assert.AreEqual(OtherCardExpense.SystemId, FindMatch(Expense, WorkDate(), 20, '7777'), 'The expense paid with the receipt card must match.');
    end;

    [Test]
    procedure ReceiptCardLast4OfNoUserCardDoesNotMatch()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] A receipt paid with a card the expense user does not have matches no expense.
        Initialize();

        // [GIVEN] A card expense paid with the card ending in 0001.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] The receipt is matched with card last four digits 9999.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 20, '9999')), 'Another card must not match.');
    end;

    [Test]
    procedure ReceiptInvalidCardLast4IsIgnored()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Card digits that are not exactly four digits are ignored.
        Initialize();

        // [GIVEN] A card expense paid with the card ending in 0001.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] The receipt is matched with card last four digits 12A4.
        // [THEN] The card expense is returned.
        Assert.AreEqual(Expense.SystemId, FindMatch(Expense, WorkDate(), 20, '12A4'), 'Invalid card digits must be ignored.');
    end;

    [Test]
    procedure CheckReturnsEmptyWhenCardLast4Differs()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Checking a receipt paid with another card against a given card expense returns no match.
        Initialize();

        // [GIVEN] A card expense paid with the card ending in 0001.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] A receipt with card last four digits 9999 is checked against the expense.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(CheckMatch(Expense, Expense.SystemId, WorkDate(), 20, '9999')), 'Another card must not fit.');
    end;

    local procedure Initialize()
    begin
        CorpCardTestLib.InitializeCorpCardData();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
    end;

    local procedure FindMatch(Expense: Record Expense; ReceiptDate: Date; ReceiptAmount: Decimal): Guid
    begin
        exit(FindMatch(Expense, ReceiptDate, ReceiptAmount, ''));
    end;

    local procedure FindMatch(Expense: Record Expense; ReceiptDate: Date; ReceiptAmount: Decimal; CardLast4: Text): Guid
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.Get(Expense."Expense User No.");
        exit(ReceiptExpenseMatch.FindMatchingExpense(ExpenseUser.SystemId, ReceiptDate, ReceiptAmount, '', Expense."Merchant Name", CardLast4));
    end;

    local procedure CheckMatch(Expense: Record Expense; ExpenseSystemId: Guid; ReceiptDate: Date; ReceiptAmount: Decimal): Guid
    begin
        exit(CheckMatch(Expense, ExpenseSystemId, ReceiptDate, ReceiptAmount, ''));
    end;

    // Checks the receipt for the expense user of Expense against the expense identified by ExpenseSystemId.
    local procedure CheckMatch(Expense: Record Expense; ExpenseSystemId: Guid; ReceiptDate: Date; ReceiptAmount: Decimal; CardLast4: Text): Guid
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.Get(Expense."Expense User No.");
        exit(ReceiptExpenseMatch.CheckMatchingExpense(ExpenseUser.SystemId, ExpenseSystemId, ReceiptDate, ReceiptAmount, '', CardLast4));
    end;

    // Creates another card for the expense user of the given card and returns its card ID.
    local procedure CreateSecondCard(CardId: Code[50]; MaskedCardNo: Text[30]): Code[50]
    var
        CorpCard: Record "EA Corp Card";
        SecondCorpCard: Record "EA Corp Card";
    begin
        CorpCard.Get(CardId);
        SecondCorpCard := CorpCard;
        SecondCorpCard."Card Id" := CopyStr(CardId + '-2', 1, MaxStrLen(SecondCorpCard."Card Id"));
        SecondCorpCard."External Card Ref" := '';
        SecondCorpCard."Masked Card No." := MaskedCardNo;
        SecondCorpCard.Insert(true);
        exit(SecondCorpCard."Card Id");
    end;

    local procedure CreateCardExpense(var Expense: Record Expense; CardId: Code[50]; ExpenseDate: Date; MerchantName: Text[100])
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseWriter: Codeunit "EA Corp Card Expense Writer";
        ExpenseNo: Code[20];
    begin
        CorpCard.Get(CardId);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        ExpenseWriter.CreateDraftFromTrans(CorpCardTrans, ExpenseNo);
        Expense.Get(ExpenseNo);
        Expense."Expense Date" := ExpenseDate;
        Expense."Merchant Name" := MerchantName;
        Expense.Modify();
    end;

    local procedure CreateLinkedManualExpense(var Expense: Record Expense)
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Require Corporate Card", false);
        ExpenseAgentSetup.Modify(true);
        CorpCard.Get('CORPCARD-0001');
        LibraryExpense.CreateExpense(Expense, CorpCard."Expense User No.", 'AIRLINE', '', '', false, '', 20);
        Expense.Validate("Corporate Card Id", CorpCard."Card Id");
        Expense.Modify(true);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        CorpCardExpenseMatch.LinkExpense(CorpCardTrans, Expense."No.");
        CorpCardTrans.Modify(true);
        Expense.Get(Expense."No.");
        Expense.TestField(Source, Expense.Source::Manual);
        Expense.TestField("Receipt Attached", false);
    end;
}
