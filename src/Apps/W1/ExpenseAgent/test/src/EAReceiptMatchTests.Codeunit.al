// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

// [FEATURE] [Expense Agent] [Corporate Card] [Receipt Matching]
codeunit 148367 EAReceiptMatchTests
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
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] A receipt dated within the date window is matched.
        // [THEN] The card expense is returned.
        Assert.AreEqual(Expense.SystemId, FindMatch(Expense, WorkDate() + 2, 20), 'The card expense must match the receipt.');
    end;

    [Test]
    procedure ReceiptWithDifferentAmountOrDateOutsideWindowDoesNotMatch()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Amount must match exactly and the receipt date must be within the date window.
        Initialize();
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [THEN] No expense is returned for a different amount or a date outside the 7-day window.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 21)), 'A different amount must not match.');
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate() + 8, 20)), 'A date outside the window must not match.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchExpenseThatAlreadyHasReceipt()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Card expenses that already have a receipt are not candidates.
        Initialize();
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        Expense."Receipt Attached" := true;
        Expense.Modify();

        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 20)), 'An expense with a receipt must not match.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchManualExpenseLinkedToTransaction()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Only card-created expenses are candidates; a manual expense already has its own receipt flow.
        Initialize();
        CreateLinkedManualExpense(Expense);

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
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        OtherCorpCard.Get('CORPCARD-0002');
        OtherExpenseUser.Get(OtherCorpCard."Expense User No.");

        // [THEN] Matching for another user returns no expense.
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
        CreateCardExpense(FartherExpense, 'CORPCARD-0001', WorkDate() - 3, 'FABRIKAM TAXI');
        CreateCardExpense(CloserExpense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

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
