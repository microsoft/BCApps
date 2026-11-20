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
            IsNullGuid(ReceiptExpenseMatch.FindMatchingExpense(OtherExpenseUser.SystemId, WorkDate(), 20, '', 'CONTOSO COFFEE')),
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

    local procedure Initialize()
    begin
        CorpCardTestLib.InitializeCorpCardData();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
    end;

    local procedure FindMatch(Expense: Record Expense; ReceiptDate: Date; ReceiptAmount: Decimal): Guid
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.Get(Expense."Expense User No.");
        exit(ReceiptExpenseMatch.FindMatchingExpense(ExpenseUser.SystemId, ReceiptDate, ReceiptAmount, '', Expense."Merchant Name"));
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
