// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148365 EACorpCardSelectionUITests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Assert: Codeunit Assert;
        CorpCardTestLib: Codeunit EACorpCardTestLib;

    [Test]
    procedure ExpenseCardCorporateCardFieldOpensAndReflectsDocumentState()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ManualExpense: Record Expense;
        ReleasedExpense: Record Expense;
        LinkedExpense: Record Expense;
        EmployeePaidExpense: Record Expense;
        LibraryExpense: Codeunit "Library - Expense";
        ExpenseCard: TestPage Expense;
    begin
        Initialize();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InsertExpense(ManualExpense, CorpCard);
        CorpCardTestLib.InsertExpense(ReleasedExpense, CorpCard);
        ReleasedExpense.Status := ReleasedExpense.Status::Released;
        ReleasedExpense.Modify();
        CorpCardTestLib.InsertExpense(LinkedExpense, CorpCard);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        LinkedExpense."Credit Card Feed No." := CorpCardTrans."Entry No.";
        LinkedExpense.Modify();
        CorpCardTestLib.InitializeExpense(EmployeePaidExpense, CorpCard);
        EmployeePaidExpense."Reimbursement Type" := EmployeePaidExpense."Reimbursement Type"::"Employee Paid";
        EmployeePaidExpense.Insert();

        ExpenseCard.OpenEdit();
        ExpenseCard.GoToRecord(ManualExpense);
        Assert.IsTrue(ExpenseCard.CorporateCard.Visible(), 'The corporate card must be shown for a credit-card expense.');
        Assert.IsTrue(ExpenseCard.CorporateCard.Editable(), 'An open manual expense must allow card selection.');
        ExpenseCard.GoToRecord(ReleasedExpense);
        Assert.IsTrue(ExpenseCard.CorporateCard.Visible(), 'The selected card must remain visible after release.');
        Assert.IsFalse(ExpenseCard.CorporateCard.Editable(), 'A released expense must not allow card selection.');
        ExpenseCard.GoToRecord(LinkedExpense);
        Assert.IsFalse(ExpenseCard.CorporateCard.Editable(), 'A feed-linked expense must not allow card selection.');
        ExpenseCard.GoToRecord(EmployeePaidExpense);
        Assert.IsTrue(ExpenseCard.CorporateCard.Visible(), 'The card selector must remain visible so it can be enabled after choosing CARD.');
        Assert.IsFalse(ExpenseCard.CorporateCard.Editable(), 'Employee-paid expenses must not allow corporate card selection.');
        ExpenseCard.Close();
    end;

    [Test]
    [HandlerFunctions('SelectExpenseUsersCardHandler')]
    procedure ManuallyCreatedExpenseAllowsCardSelectionAfterChoosingCardPayment()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        LibraryExpense: Codeunit "Library - Expense";
        CorpCardSelectionMgt: Codeunit "EA Corp Card Selection Mgt";
        ExpenseCard: TestPage Expense;
    begin
        Initialize();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        CorpCard.Get('CORPCARD-0001');
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCard.OpenNew();
        ExpenseCard."Expense User No.".SetValue(CorpCard."Expense User No.");
        ExpenseCard."Expense Category".SetValue(ExpenseCategory.Code);
        Assert.IsTrue(ExpenseCard.CorporateCard.Visible(), 'The card selector must be present on a newly created expense.');
        Assert.IsFalse(ExpenseCard.CorporateCard.Editable(), 'A non-credit-card payment method must not allow card selection.');

        ExpenseCard."Payment Method Code".SetValue('CARD');

        Assert.IsTrue(ExpenseCard.CorporateCard.Visible(), 'Choosing CARD must not require reopening the expense to find the selector.');
        Assert.IsTrue(ExpenseCard.CorporateCard.Editable(), 'Choosing CARD must immediately enable card selection.');
        ExpenseCard.CorporateCard.Lookup();
        ExpenseCard.CorporateCard.AssertEquals(CorpCardSelectionMgt.GetCardDisplay(CorpCard."Card Id"));
        ExpenseCard.Close();
        Expense.SetRange("Corporate Card Id", CorpCard."Card Id");
        Assert.RecordCount(Expense, 1);
        Expense.FindFirst();
        Expense.TestField("Expense User No.", CorpCard."Expense User No.");
        Expense.TestField("Credit Card Feed No.", 0);
    end;

    [Test]
    procedure ExpenseUserCardCorporateCardsAreFilteredToCurrentExpenseUser()
    var
        CorpCard: Record "EA Corp Card";
        UnassignedCorpCard: Record "EA Corp Card";
        ExpenseUser: Record "Expense User";
        ExpenseUserCard: TestPage "Expense User";
        CorporateCards: TestPage "EA Corp Card Cards";
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        UnassignedCorpCard := CorpCard;
        UnassignedCorpCard."Card Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(UnassignedCorpCard."Card Id"));
        UnassignedCorpCard."Expense User No." := '';
        UnassignedCorpCard.Insert(true);
        ExpenseUser.Get(CorpCard."Expense User No.");
        ExpenseUserCard.OpenView();
        ExpenseUserCard.GoToRecord(ExpenseUser);
        CorporateCards.Trap();

        ExpenseUserCard.CorporateCards.Invoke();

        Assert.IsTrue(CorporateCards.First(), 'The expense user must have corporate cards in the filtered list.');
        repeat
            CorporateCards."Expense User No.".AssertEquals(ExpenseUser."No.");
        until not CorporateCards.Next();
        CorporateCards.Close();
        ExpenseUserCard.Close();
    end;

    [Test]
    procedure NewCorporateCardDefaultsToCurrentExpenseUser()
    var
        CorpCard: Record "EA Corp Card";
        ExpenseUser: Record "Expense User";
        ExpenseUserCard: TestPage "Expense User";
        CorporateCards: TestPage "EA Corp Card Cards";
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        ExpenseUser.Get(CorpCard."Expense User No.");
        ExpenseUserCard.OpenView();
        ExpenseUserCard.GoToRecord(ExpenseUser);
        CorporateCards.Trap();
        ExpenseUserCard.CorporateCards.Invoke();

        CorporateCards.New();

        CorporateCards."Expense User No.".AssertEquals(ExpenseUser."No.");
        CorporateCards."Card Id".SetValue('NEW-USER-CARD');
        CorporateCards."Provider Code".SetValue(CorpCard."Provider Code");
        CorporateCards.Close();
        ExpenseUserCard.Close();
        CorpCard.Get('NEW-USER-CARD');
        CorpCard.TestField("Expense User No.", ExpenseUser."No.");
    end;

    [Test]
    procedure ExpenseUserWithoutCardsDoesNotSeeOtherUsersCards()
    var
        ExpenseUser: Record "Expense User";
        LibraryExpense: Codeunit "Library - Expense";
        ExpenseUserCard: TestPage "Expense User";
        CorporateCards: TestPage "EA Corp Card Cards";
    begin
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUserCard.OpenView();
        ExpenseUserCard.GoToRecord(ExpenseUser);
        CorporateCards.Trap();

        ExpenseUserCard.CorporateCards.Invoke();

        Assert.IsFalse(CorporateCards.First(), 'An expense user without cards must see an empty list, not other users'' cards.');
        CorporateCards.Close();
        ExpenseUserCard.Close();
    end;

    [Test]
    procedure CardLookupAndExpenseDisplayUseProviderShortNameAndLastFourDigits()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardSelectionMgt: Codeunit "EA Corp Card Selection Mgt";
        CardLookup: TestPage "EA Corp Card Lookup";
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        CorpCardProvider.Get(CorpCard."Provider Code");
        CorpCardProvider."Short Name" := 'AmEx';
        CorpCardProvider.Modify();

        CardLookup.OpenView();
        CardLookup.GoToRecord(CorpCard);
        CardLookup.CorporateCard.AssertEquals('AmEx 0001');
        CardLookup.Close();
        Assert.AreEqual('AmEx 0001', CorpCardSelectionMgt.GetCardDisplay(CorpCard."Card Id"), 'Expense and report displays must use the same compact label as the lookup.');
    end;

    [ModalPageHandler]
    procedure SelectExpenseUsersCardHandler(var CardLookup: TestPage "EA Corp Card Lookup")
    var
        CorpCard: Record "EA Corp Card";
    begin
        CorpCard.Get('CORPCARD-0001');
        Assert.IsTrue(CardLookup.GoToRecord(CorpCard), 'The selected expense user''s card must be available in the lookup.');
        CardLookup.OK().Invoke();
    end;

    local procedure Initialize()
    begin
        CorpCardTestLib.InitializeCorpCardData();
    end;
}
