// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

// [FEATURE] [Expense Agent] [Corporate Card] [UI]
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
    procedure OpenManualExpenseAllowsCorporateCardSelection()
    var
        CorpCard: Record "EA Corp Card";
        ManualExpense: Record Expense;
        LibraryExpense: Codeunit "Library - Expense";
        ExpenseCard: TestPage Expense;
    begin
        // [SCENARIO] An open manual credit-card expense allows and requires corporate card selection.
        Initialize();

        // [GIVEN] An open manual expense is paid by credit card.
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InsertExpense(ManualExpense, CorpCard);

        // [WHEN] The expense is shown.
        ExpenseCard.OpenEdit();
        ExpenseCard.GoToRecord(ManualExpense);

        // [THEN] Card selection is visible, editable, and mandatory.
        Assert.IsTrue(ExpenseCard.CorporateCard.Visible(), 'The corporate card must be shown for a credit-card expense.');
        Assert.IsTrue(ExpenseCard.CorporateCard.Editable(), 'An open manual expense must allow card selection.');
        Assert.IsTrue(ExpenseCard.CorporateCard.ShowMandatory(), 'Credit-card expenses must indicate that a corporate card is required.');
        ExpenseCard.Close();
    end;

    [Test]
    procedure ReleasedExpenseDisablesCorporateCardSelection()
    var
        CorpCard: Record "EA Corp Card";
        ReleasedExpense: Record Expense;
        LibraryExpense: Codeunit "Library - Expense";
        ExpenseCard: TestPage Expense;
    begin
        // [SCENARIO] A released expense shows its corporate card without allowing selection changes.
        Initialize();

        // [GIVEN] A released expense has a selected corporate card.
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InsertExpense(ReleasedExpense, CorpCard);
        ReleasedExpense.Status := ReleasedExpense.Status::Released;
        ReleasedExpense.Modify();

        // [WHEN] The expense is shown.
        ExpenseCard.OpenEdit();
        ExpenseCard.GoToRecord(ReleasedExpense);

        // [THEN] The selected card remains visible but cannot be changed.
        Assert.IsTrue(ExpenseCard.CorporateCard.Visible(), 'The selected card must remain visible after release.');
        Assert.IsFalse(ExpenseCard.CorporateCard.Editable(), 'A released expense must not allow card selection.');
        ExpenseCard.Close();
    end;

    [Test]
    procedure FeedLinkedExpenseDisablesCorporateCardSelection()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        LinkedExpense: Record Expense;
        LibraryExpense: Codeunit "Library - Expense";
        ExpenseCard: TestPage Expense;
    begin
        // [SCENARIO] A feed-linked expense cannot change its corporate card selection.
        Initialize();

        // [GIVEN] An expense is linked to a transaction for its selected card.
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InsertExpense(LinkedExpense, CorpCard);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        LinkedExpense."Credit Card Feed No." := CorpCardTrans."Entry No.";
        LinkedExpense.Modify();

        // [WHEN] The expense is shown.
        ExpenseCard.OpenEdit();
        ExpenseCard.GoToRecord(LinkedExpense);

        // [THEN] Card selection is disabled.
        Assert.IsFalse(ExpenseCard.CorporateCard.Editable(), 'A feed-linked expense must not allow card selection.');
        ExpenseCard.Close();
    end;

    [Test]
    procedure EmployeePaidExpenseDoesNotRequireCorporateCard()
    var
        CorpCard: Record "EA Corp Card";
        EmployeePaidExpense: Record Expense;
        LibraryExpense: Codeunit "Library - Expense";
        ExpenseCard: TestPage Expense;
    begin
        // [SCENARIO] An employee-paid expense shows the card selector without allowing or requiring selection.
        Initialize();

        // [GIVEN] An expense is paid by the employee rather than by corporate card.
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InitializeExpense(EmployeePaidExpense, CorpCard);
        EmployeePaidExpense."Reimbursement Type" := EmployeePaidExpense."Reimbursement Type"::"Employee Paid";
        EmployeePaidExpense.Insert();

        // [WHEN] The expense is shown.
        ExpenseCard.OpenEdit();
        ExpenseCard.GoToRecord(EmployeePaidExpense);

        // [THEN] The selector remains visible but is neither editable nor mandatory.
        Assert.IsTrue(ExpenseCard.CorporateCard.Visible(), 'The card selector must remain visible so it can be enabled after choosing CARD.');
        Assert.IsFalse(ExpenseCard.CorporateCard.Editable(), 'Employee-paid expenses must not allow corporate card selection.');
        Assert.IsFalse(ExpenseCard.CorporateCard.ShowMandatory(), 'Employee-paid expenses must not require a corporate card.');
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
        // [SCENARIO] Choosing card payment immediately enables corporate card selection on a new expense.
        Initialize();

        // [GIVEN] A newly opened expense uses an employee-paid category and cannot select a card.
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        CorpCard.Get('CORPCARD-0001');
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCard.OpenNew();
        ExpenseCard."Expense User No.".SetValue(CorpCard."Expense User No.");
        ExpenseCard."Expense Category".SetValue(ExpenseCategory.Code);
        Assert.IsTrue(ExpenseCard.CorporateCard.Visible(), 'The card selector must be present on a newly created expense.');
        Assert.IsFalse(ExpenseCard.CorporateCard.Editable(), 'A non-credit-card payment method must not allow card selection.');
        Assert.IsFalse(ExpenseCard.CorporateCard.ShowMandatory(), 'A non-credit-card payment method must not require a corporate card.');

        // [WHEN] The payment method changes to CARD without reopening the expense.
        ExpenseCard."Payment Method Code".SetValue('CARD');

        // [THEN] Card selection is immediately visible, editable, and mandatory.
        Assert.IsTrue(ExpenseCard.CorporateCard.Visible(), 'Choosing CARD must not require reopening the expense to find the selector.');
        Assert.IsTrue(ExpenseCard.CorporateCard.Editable(), 'Choosing CARD must immediately enable card selection.');
        Assert.IsTrue(ExpenseCard.CorporateCard.ShowMandatory(), 'Choosing CARD must immediately indicate that a corporate card is required.');

        // [WHEN] The expense user's card is selected and the expense is saved.
        ExpenseCard.CorporateCard.Lookup();
        ExpenseCard.CorporateCard.AssertEquals(CorpCardSelectionMgt.GetCardDisplay(CorpCard."Card Id"));
        ExpenseCard.Close();

        // [THEN] The saved expense retains that user's card without feed provenance.
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
        // [SCENARIO] The expense user's corporate card list excludes unassigned cards and other users' cards.
        Initialize();

        // [GIVEN] An expense user owns a card and an additional card has no assigned user.
        CorpCard.Get('CORPCARD-0001');
        UnassignedCorpCard := CorpCard;
        UnassignedCorpCard."Card Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(UnassignedCorpCard."Card Id"));
        UnassignedCorpCard."Expense User No." := '';
        UnassignedCorpCard.Insert(true);
        ExpenseUser.Get(CorpCard."Expense User No.");
        ExpenseUserCard.OpenView();
        ExpenseUserCard.GoToRecord(ExpenseUser);
        CorporateCards.Trap();

        // [WHEN] The user opens their corporate card list.
        ExpenseUserCard.CorporateCards.Invoke();

        // [THEN] The nonempty list contains only cards assigned to that expense user.
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
        NewCardId: Code[50];
    begin
        // [SCENARIO] A corporate card created from an expense user defaults to that user.
        Initialize();

        // [GIVEN] The corporate card list is opened from an expense user.
        NewCardId := CopyStr(Format(CreateGuid()), 1, MaxStrLen(NewCardId));
        CorpCard.Get('CORPCARD-0001');
        ExpenseUser.Get(CorpCard."Expense User No.");
        ExpenseUserCard.OpenView();
        ExpenseUserCard.GoToRecord(ExpenseUser);
        CorporateCards.Trap();
        ExpenseUserCard.CorporateCards.Invoke();

        // [WHEN] A new card is started in the filtered list.
        CorporateCards.New();

        // [THEN] Its expense user is defaulted from the originating user.
        CorporateCards."Expense User No.".AssertEquals(ExpenseUser."No.");

        // [WHEN] The new card is completed and saved.
        CorporateCards."Card Id".SetValue(NewCardId);
        CorporateCards."Provider Code".SetValue(CorpCard."Provider Code");
        CorporateCards.Close();
        ExpenseUserCard.Close();

        // [THEN] The persisted card belongs to the originating expense user.
        CorpCard.Get(NewCardId);
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
        // [SCENARIO] An expense user without cards sees an empty corporate card list.
        Initialize();

        // [GIVEN] A newly created expense user has no cards.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUserCard.OpenView();
        ExpenseUserCard.GoToRecord(ExpenseUser);
        CorporateCards.Trap();

        // [WHEN] The user opens their corporate card list.
        ExpenseUserCard.CorporateCards.Invoke();

        // [THEN] Other users' cards are not displayed.
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
        // [SCENARIO] Card lookup and expense displays share the provider abbreviation and last four digits.
        Initialize();

        // [GIVEN] A card ends in 0001 and its provider abbreviation is AmEx.
        CorpCard.Get('CORPCARD-0001');
        CorpCardProvider.Get(CorpCard."Provider Code");
        CorpCardProvider."Short Name" := 'AmEx';
        CorpCardProvider.Modify();

        // [WHEN] The card is shown in the lookup.
        CardLookup.OpenView();
        CardLookup.GoToRecord(CorpCard);

        // [THEN] Both the lookup and expense display use the same compact card label.
        CardLookup.CorporateCard.AssertEquals('AmEx 0001');
        CardLookup.Close();
        Assert.AreEqual('AmEx 0001', CorpCardSelectionMgt.GetCardDisplay(CorpCard."Card Id"), 'Expense and report displays must use the same compact label as the lookup.');
    end;

    [Test]
    procedure CardListDisplayUpdatesWhenProviderChanges()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardProvider: Record "EA Corp Card Provider";
        CorporateCards: TestPage "EA Corp Card Cards";
    begin
        // [SCENARIO] Editing a card's provider refreshes its compact display.
        Initialize();

        // [GIVEN] A card is shown in the editable list and another provider has a different abbreviation.
        CorpCard.Get('CORPCARD-0001');
        CorpCardProvider.Get(CorpCard."Provider Code");
        CorpCardProvider."Short Name" := 'VISA';
        CorpCardProvider.Modify();
        CorpCardProvider.Get('CORPCARDXML');
        CorpCardProvider."Short Name" := 'AmEx';
        CorpCardProvider.Modify();
        CorporateCards.OpenEdit();
        CorporateCards.GoToRecord(CorpCard);
        CorporateCards.CorporateCard.AssertEquals('VISA 0001');

        // [WHEN] The card's provider is changed.
        CorporateCards."Provider Code".SetValue(CorpCardProvider.Code);

        // [THEN] The display uses the new provider abbreviation and the unchanged card suffix.
        CorporateCards.CorporateCard.AssertEquals('AmEx 0001');
        CorporateCards.Close();
    end;

    [Test]
    [HandlerFunctions('SelectExpenseUsersCardHandler')]
    procedure ReportLineCardErrorActionSelectsAndSavesCard()
    var
        ExpenseReportLine: Record "Expense Report Line";
        CorpCardSelectionMgt: Codeunit "EA Corp Card Selection Mgt";
        CardLookupError: ErrorInfo;
    begin
        // [SCENARIO] The recommended action selects a card for the report line that raised the error.
        Initialize();

        // [GIVEN] A saved manual report line has no selected card.
        CreateManualReportLine(ExpenseReportLine);
        Commit();
        CardLookupError := CorpCardSelectionMgt.GetReportLineCardLookupError(ExpenseReportLine);

        // [WHEN] The error's recovery action selects the expense user's card.
        CorpCardSelectionMgt.LookupReportLineCardFromError(CardLookupError);

        // [THEN] The selected card is saved without creating feed provenance.
        ExpenseReportLine.GetBySystemId(ExpenseReportLine.SystemId);
        ExpenseReportLine.TestField("Corporate Card Id", 'CORPCARD-0001');
        ExpenseReportLine.TestField("Credit Card Feed No.", 0);
    end;

    [Test]
    [HandlerFunctions('CancelCardLookupHandler')]
    procedure ReportLineCardErrorActionCancellationPreservesCard()
    var
        ExpenseReportLine: Record "Expense Report Line";
        CorpCardSelectionMgt: Codeunit "EA Corp Card Selection Mgt";
        CardLookupError: ErrorInfo;
    begin
        // [SCENARIO] Cancelling the error's lookup leaves the saved card unchanged.
        Initialize();

        // [GIVEN] A manual report line already has a card.
        CreateManualReportLine(ExpenseReportLine);
        ExpenseReportLine.Validate("Corporate Card Id", 'CORPCARD-0001');
        ExpenseReportLine.Modify(true);
        Commit();
        CardLookupError := CorpCardSelectionMgt.GetReportLineCardLookupError(ExpenseReportLine);

        // [WHEN] The recovery action is cancelled.
        CorpCardSelectionMgt.LookupReportLineCardFromError(CardLookupError);

        // [THEN] The previous card is retained.
        ExpenseReportLine.GetBySystemId(ExpenseReportLine.SystemId);
        ExpenseReportLine.TestField("Corporate Card Id", 'CORPCARD-0001');
    end;

    [Test]
    procedure UnsavedReportLineCardErrorHasNoPersistedTarget()
    var
        ExpenseReportLine: Record "Expense Report Line";
        CorpCardSelectionMgt: Codeunit "EA Corp Card Selection Mgt";
        CardLookupError: ErrorInfo;
    begin
        // [SCENARIO] An unsaved line does not offer recovery against a nonexistent persisted row.
        Initialize();

        // [GIVEN] A new report line has not been inserted.
        ExpenseReportLine."Document No." := 'NEW-REPORT';
        ExpenseReportLine."Line No." := 10000;

        // [WHEN] Its card lookup error is built.
        CardLookupError := CorpCardSelectionMgt.GetReportLineCardLookupError(ExpenseReportLine);

        // [THEN] The error has no persisted target.
        Assert.IsTrue(IsNullGuid(CardLookupError.SystemId), 'An unsaved line must not have a persisted recovery target.');
    end;

    [Test]
    procedure TemporaryReportLineCardErrorHasNoPersistedTarget()
    var
        ExpenseReportLine: Record "Expense Report Line";
        TempExpenseReportLine: Record "Expense Report Line" temporary;
        CorpCardSelectionMgt: Codeunit "EA Corp Card Selection Mgt";
        CardLookupError: ErrorInfo;
    begin
        // [SCENARIO] A temporary line does not offer recovery against its saved source.
        Initialize();

        // [GIVEN] A temporary copy has the system ID of a saved line.
        CreateManualReportLine(ExpenseReportLine);
        TempExpenseReportLine := ExpenseReportLine;

        // [WHEN] Its card lookup error is built.
        CardLookupError := CorpCardSelectionMgt.GetReportLineCardLookupError(TempExpenseReportLine);

        // [THEN] The error must not target the saved source line.
        Assert.IsTrue(IsNullGuid(CardLookupError.SystemId), 'A temporary line must not offer recovery against its saved source.');
    end;

    [Test]
    procedure ReportLineCorporateCardMandatoryFollowsReimbursementType()
    var
        CreditCardReportLine: Record "Expense Report Line";
        EmployeePaidReportLine: Record "Expense Report Line";
        ExpenseReportSubPage: TestPage "Expense Report SubPage";
    begin
        // [SCENARIO] Navigating between report lines updates whether a corporate card is mandatory.
        Initialize();

        // [GIVEN] A credit-card report line and an employee-paid report line.
        CreateManualReportLine(CreditCardReportLine);
        CreateManualReportLine(EmployeePaidReportLine);
        EmployeePaidReportLine."Reimbursement Type" := EmployeePaidReportLine."Reimbursement Type"::"Employee Paid";
        EmployeePaidReportLine.Modify();

        // [WHEN] The user opens the list and navigates between the two lines.
        ExpenseReportSubPage.OpenEdit();
        ExpenseReportSubPage.GoToRecord(CreditCardReportLine);

        // [THEN] The credit-card line indicates that a corporate card is required.
        Assert.IsTrue(ExpenseReportSubPage.CorporateCard.ShowMandatory(), 'Credit-card report lines must indicate that a corporate card is required.');

        ExpenseReportSubPage.GoToRecord(EmployeePaidReportLine);

        // [THEN] The employee-paid line does not require a corporate card.
        Assert.IsFalse(ExpenseReportSubPage.CorporateCard.ShowMandatory(), 'Employee-paid report lines must not require a corporate card.');
        ExpenseReportSubPage.Close();
    end;

    [Test]
    [HandlerFunctions('SelectExpenseUsersCardHandler')]
    procedure ReportCardDisplayUpdatesAfterSelectionAndListRefresh()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardProvider: Record "EA Corp Card Provider";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportSubPage: TestPage "Expense Report SubPage";
    begin
        // [SCENARIO] A selected card is shown immediately and a refreshed list reloads provider edits.
        Initialize();

        // [GIVEN] A saved report line has no selected card.
        CreateManualReportLine(ExpenseReportLine);
        ExpenseReportLine.Description := 'Card display refresh';
        ExpenseReportLine.Modify();
        CorpCard.Get('CORPCARD-0001');
        CorpCardProvider.Get(CorpCard."Provider Code");
        CorpCardProvider."Short Name" := 'VISA';
        CorpCardProvider.Modify();
        ExpenseReportSubPage.OpenEdit();
        ExpenseReportSubPage.GoToRecord(ExpenseReportLine);
        ExpenseReportSubPage.CorporateCard.AssertEquals('');

        // [WHEN] A card not yet in the report's batch is selected.
        ExpenseReportSubPage.CorporateCard.Lookup();

        // [THEN] The selected card is displayed immediately.
        ExpenseReportSubPage.CorporateCard.AssertEquals('VISA 0001');

        // [WHEN] The provider changes and a new list read is requested.
        CorpCardProvider."Short Name" := 'AMEX';
        CorpCardProvider.Modify();
        ExpenseReportSubPage.Filter.SetFilter(Description, ExpenseReportLine.Description);

        // [THEN] The batch does not retain the old provider display.
        ExpenseReportSubPage.CorporateCard.AssertEquals('AMEX 0001');
        ExpenseReportSubPage.Close();
    end;

    local procedure CreateManualReportLine(var ExpenseReportLine: Record "Expense Report Line")
    var
        CorpCard: Record "EA Corp Card";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        CorpCard.Get('CORPCARD-0001');
        ExpenseReportHeader."No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ExpenseReportHeader."No."));
        ExpenseReportHeader."Expense User No." := CorpCard."Expense User No.";
        ExpenseReportHeader.Insert();
        Clear(ExpenseReportLine);
        ExpenseReportLine."Document No." := ExpenseReportHeader."No.";
        ExpenseReportLine."Line No." := 10000;
        ExpenseReportLine."Expense User No." := CorpCard."Expense User No.";
        ExpenseReportLine."Reimbursement Type" := ExpenseReportLine."Reimbursement Type"::"Credit Card";
        ExpenseReportLine."Expense Date" := WorkDate();
        ExpenseReportLine.Insert();
    end;

    [ModalPageHandler]
    procedure CancelCardLookupHandler(var CardLookup: TestPage "EA Corp Card Lookup")
    begin
        CardLookup.Cancel().Invoke();
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
