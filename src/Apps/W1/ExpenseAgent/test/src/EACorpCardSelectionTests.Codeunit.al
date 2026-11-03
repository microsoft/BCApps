// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;

codeunit 148364 EACorpCardSelectionTests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

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
        InsertExpense(ManualExpense, CorpCard);
        InsertExpense(ReleasedExpense, CorpCard);
        ReleasedExpense.Status := ReleasedExpense.Status::Released;
        ReleasedExpense.Modify();
        InsertExpense(LinkedExpense, CorpCard);
        CreateTransaction(CorpCardTrans, CorpCard);
        LinkedExpense."Credit Card Feed No." := CorpCardTrans."Entry No.";
        LinkedExpense.Modify();
        InitializeExpense(EmployeePaidExpense, CorpCard);
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

        Assert.IsTrue(CorporateCards.First(), 'The expense user must have corporate cards in the filtered list.');
        repeat
            CorporateCards."Expense User No.".AssertEquals(ExpenseUser."No.");
        until not CorporateCards.Next();
        CorporateCards.Close();
        ExpenseUserCard.Close();
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
    procedure DefaultProviderSetupUsesVisaAndAmexWithoutOverwritingCustomNames()
    var
        CsvProvider: Record "EA Corp Card Provider";
        XmlProvider: Record "EA Corp Card Provider";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
    begin
        Initialize();
        CsvProvider.Get('CORPCARDCSV');
        CsvProvider."Short Name" := 'CORP';
        CsvProvider.Modify();
        XmlProvider.Get('CORPCARDXML');
        XmlProvider."Short Name" := '';
        XmlProvider.Modify();

        CreateCorpCardSetup.CreateDefaults();

        CsvProvider.Get(CsvProvider.Code);
        XmlProvider.Get(XmlProvider.Code);
        Assert.AreEqual('VISA', CsvProvider."Short Name", 'Setup must replace the generated CSV provider abbreviation.');
        Assert.AreEqual('AMEX', XmlProvider."Short Name", 'Setup must initialize the XML provider abbreviation.');

        CsvProvider."Short Name" := 'BANK';
        CsvProvider.Modify();
        CreateCorpCardSetup.CreateDefaults();
        CsvProvider.Get(CsvProvider.Code);
        Assert.AreEqual('BANK', CsvProvider."Short Name", 'Repeating setup must preserve a custom provider short name.');
    end;

    [Test]
    procedure DefaultCardsCanBeSelectedForHistoricalExpenses()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
    begin
        Initialize();
        CreateCorpCardSetup.CreateDefaults();
        CorpCard.Get('CORPCARD-0001');
        InitializeExpense(Expense, CorpCard);
        Expense."Expense Date" := CalcDate('<-1Y>', WorkDate());

        Expense.Validate("Corporate Card Id", CorpCard."Card Id");

        Assert.AreEqual(CorpCard."Card Id", Expense."Corporate Card Id", 'Registered demo cards must also support historical sample expenses.');
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

    [Test]
    procedure CardDisplayWithoutShortNameUsesAtMostFourProviderCodeCharacters()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardSelectionMgt: Codeunit "EA Corp Card Selection Mgt";
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        CorpCardProvider.Get(CorpCard."Provider Code");
        CorpCardProvider."Short Name" := '';
        CorpCardProvider.Modify();

        Assert.AreEqual(
            CopyStr(CorpCard."Provider Code", 1, 4) + ' 0001',
            CorpCardSelectionMgt.GetCardDisplay(CorpCard."Card Id"),
            'Existing providers without a short name must still have a compact card label.');
    end;

    [Test]
    procedure CardSelectionRejectsAnotherExpenseUsersCard()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        InitializeExpense(Expense, CorpCard);
        Expense."Expense User No." := 'OTHER-USER';

        asserterror Expense.Validate("Corporate Card Id", CorpCard."Card Id");

        Assert.ExpectedError(Expense."Expense User No.");
    end;

    [Test]
    procedure CardSelectionRejectsBlockedAndExpiredCards()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        InitializeExpense(Expense, CorpCard);
        CorpCard.Blocked := true;
        CorpCard.Modify();
        asserterror Expense.Validate("Corporate Card Id", CorpCard."Card Id");
        Assert.ExpectedError(CorpCard.FieldCaption(Blocked));

        CorpCard.Blocked := false;
        CorpCard."Valid To" := WorkDate() - 1;
        CorpCard.Modify();
        asserterror Expense.Validate("Corporate Card Id", CorpCard."Card Id");
        Assert.ExpectedError('is not valid');
    end;

    [Test]
    procedure CardCanBeSelectedForAnExpenseOnItsLastValidDay()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        CorpCard."Valid To" := WorkDate();
        CorpCard.Modify();
        InitializeExpense(Expense, CorpCard);

        Expense.Validate("Corporate Card Id", CorpCard."Card Id");

        Assert.AreEqual(CorpCard."Card Id", Expense."Corporate Card Id", 'Card validity includes the last valid day.');
        Assert.AreEqual(0, Expense."Credit Card Feed No.", 'Selecting a card must not create a transaction link.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DraftMayOmitCardButReleaseRequiresSelection()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
        ExpensePaymentMethod: Record "Expense Payment Method";
        LibraryExpense: Codeunit "Library - Expense";
        CorpCardSelectionMgt: Codeunit "EA Corp Card Selection Mgt";
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.CreateExpense(Expense, CorpCard."Expense User No.", 'AIRLINE', '', '', false, '', 20);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Validate("Corporate Card Id", '');
        Expense.Modify(true);
        CorpCardSelectionMgt.ValidateExpenseCard(Expense, false);

        asserterror Expense.PerformManualRelease();

        Assert.ExpectedError(Expense.FieldCaption("Corporate Card Id"));
        Expense.Validate("Corporate Card Id", CorpCard."Card Id");
        Expense.Modify(true);
        Expense.PerformManualRelease();
        Assert.AreEqual(Expense.Status::Released, Expense.Status, 'Selecting an owned card must allow release.');
    end;

    [Test]
    procedure FeedLinkedExpenseCannotSelectAnotherCard()
    var
        CorpCard: Record "EA Corp Card";
        OtherCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        CreateSecondCard(OtherCard, CorpCard);
        InitializeExpense(Expense, CorpCard);
        CreateTransaction(CorpCardTrans, CorpCard);
        Expense."Credit Card Feed No." := CorpCardTrans."Entry No.";
        Expense."Corporate Card Id" := CorpCard."Card Id";

        asserterror Expense.Validate("Corporate Card Id", OtherCard."Card Id");

        Assert.ExpectedError(Expense.FieldCaption("Corporate Card Id"));
    end;

    [Test]
    procedure FeedLinkedCardCannotBeClearedThroughDirectModification()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        InsertExpense(Expense, CorpCard);
        CreateTransaction(CorpCardTrans, CorpCard);
        Expense."Credit Card Feed No." := CorpCardTrans."Entry No.";
        Expense.Modify(true);
        Expense."Corporate Card Id" := '';

        asserterror Expense.Modify(true);

        Assert.ExpectedError(Expense.FieldCaption("Corporate Card Id"));
    end;

    [Test]
    procedure MatchingUsesCardIdentityRatherThanLastFourDigits()
    var
        CorpCard: Record "EA Corp Card";
        OtherCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        OtherExpense: Record Expense;
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
        ExpenseNo: Code[20];
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        CreateSecondCard(OtherCard, CorpCard);
        InsertExpense(Expense, CorpCard);
        InsertExpense(OtherExpense, OtherCard);
        CreateTransaction(CorpCardTrans, CorpCard);

        Assert.IsTrue(CorpCardExpenseMatch.MatchExistingExpense(CorpCardTrans, ExpenseNo), 'The selected card should identify the expense.');

        Assert.AreEqual(Expense."No.", ExpenseNo, 'An expense paid with another card must not match, even when both suffixes are identical.');
    end;

    [Test]
    procedure AmbiguousSelectedCardExpensesRequireReview()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        OtherExpense: Record Expense;
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
        ExpenseNo: Code[20];
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        InsertExpense(Expense, CorpCard);
        InsertExpense(OtherExpense, CorpCard);
        CreateTransaction(CorpCardTrans, CorpCard);

        asserterror CorpCardExpenseMatch.MatchExistingExpense(CorpCardTrans, ExpenseNo);

        Assert.ExpectedError('More than one expense');
    end;

    [Test]
    procedure NearAmountMatchRequiresReviewInsteadOfAnotherExpense()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
        ExpenseNo: Code[20];
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        InsertExpense(Expense, CorpCard);
        Expense.Amount := 19;
        Expense.Modify();
        CreateTransaction(CorpCardTrans, CorpCard);

        asserterror CorpCardExpenseMatch.MatchExistingExpense(CorpCardTrans, ExpenseNo);

        Assert.ExpectedError('Review the amount before linking');
    end;

    [Test]
    procedure CardTransactionDraftRetainsCorporateCardSource()
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
    begin
        CreateCorporateCardDraft(Expense);
        CorpCardTrans.Get(Expense."Credit Card Feed No.");

        Expense.Validate(Amount, Expense.Amount);
        Expense.Validate("Expense Date", Expense."Expense Date");
        Expense.Validate("Currency Code", Expense."Currency Code");
        Expense.Description := 'Receipt details';
        Expense.Modify(true);

        Expense.Get(Expense."No.");
        Expense.TestField(Source, Expense.Source::CorporateCard);
        Expense.TestField("Credit Card Feed No.", CorpCardTrans."Entry No.");
        Expense.TestField(Description, 'Receipt details');
    end;

    [Test]
    procedure CorporateCardDraftRejectsAmountChange()
    var
        Expense: Record Expense;
    begin
        CreateCorporateCardDraft(Expense);

        asserterror Expense.Validate(Amount, Expense.Amount + 1);

        Assert.ExpectedError(Expense.FieldCaption(Amount) + ' cannot be changed');
    end;

    [Test]
    procedure CorporateCardDraftRejectsExpenseDateChange()
    var
        Expense: Record Expense;
    begin
        CreateCorporateCardDraft(Expense);

        asserterror Expense.Validate("Expense Date", CalcDate('<1D>', Expense."Expense Date"));

        Assert.ExpectedError(Expense.FieldCaption("Expense Date") + ' cannot be changed');
    end;

    [Test]
    procedure CorporateCardDraftRejectsCurrencyValidation()
    var
        Expense: Record Expense;
    begin
        CreateCorporateCardDraft(Expense);

        asserterror Expense.Validate("Currency Code", 'EUR');

        Assert.ExpectedError(Expense.FieldCaption("Currency Code") + ' cannot be changed');
    end;

    [Test]
    procedure CorporateCardDraftRejectsCurrencyAssignedWithoutValidation()
    var
        Expense: Record Expense;
    begin
        CreateCorporateCardDraft(Expense);
        Expense."Currency Code" := 'EUR';

        asserterror Expense.Modify(true);

        Assert.ExpectedError(Expense.FieldCaption("Currency Code") + ' cannot be changed');
    end;

    [Test]
    procedure MatchedManualExpenseRetainsFinancialEditing()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        InsertExpense(Expense, CorpCard);
        CreateTransaction(CorpCardTrans, CorpCard);
        CorpCardExpenseMatch.LinkExpense(CorpCardTrans, Expense."No.");
        Expense.Get(Expense."No.");

        Expense.Validate(Amount, 21);
        Expense.Validate("Expense Date", CalcDate('<1D>', WorkDate()));
        Expense.Validate("Currency Code", 'EUR');
        Expense.Modify(true);

        Expense.Get(Expense."No.");
        Expense.TestField(Source, Expense.Source::Manual);
        Expense.TestField(Amount, 21);
        Expense.TestField("Expense Date", CalcDate('<1D>', WorkDate()));
        Expense.TestField("Currency Code", 'EUR');
        Expense.TestField("Credit Card Feed No.", CorpCardTrans."Entry No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AutoDraftLinksExistingManualExpenseAndRetryDoesNotDuplicateIt()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        PostImportOrch: Codeunit "EA Corp Card Post Import Orch";
        ExpenseWriter: Codeunit "EA Corp Card Expense Writer";
        ExpenseCount: Integer;
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        InsertExpense(Expense, CorpCard);
        CorpCardTestLib.CreateStatement(CorpCardStatement, CorpCard."Provider Code", 'MANUAL-MATCH', 20, CorpCardStatement.Status::Imported);
        CorpCardStatement."Currency Code" := '';
        CorpCardStatement.Modify();
        CreateTransaction(CorpCardTrans, CorpCard);
        CorpCardTrans."Statement Entry No." := CorpCardStatement."Statement Entry No.";
        CorpCardTrans.Modify();
        ExpenseCount := Expense.Count();

        PostImportOrch.ProcessStatementPostImport(CorpCardStatement."Statement Entry No.", ExpenseWriter);
        PostImportOrch.ProcessStatementPostImport(CorpCardStatement."Statement Entry No.", ExpenseWriter);

        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        Assert.AreEqual(CorpCardTrans.Status::Matched, CorpCardTrans.Status, 'AutoDraft must match the existing selected-card expense first.');
        Assert.AreEqual(Expense."No.", CorpCardTrans."Expense No.", 'The transaction must link the manually created expense.');
        Expense.Get(CorpCardTrans."Expense No.");
        Expense.TestField(Source, Expense.Source::Manual);
        Assert.AreEqual(ExpenseCount, Expense.Count(), 'Initial processing and retries must not create another expense.');
    end;

    [Test]
    procedure LateFeedUpdatesExistingReportLineWithoutChangingAmounts()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        InsertExpense(Expense, CorpCard);
        Expense.Status := Expense.Status::Submitted;
        Expense."Expense Report No." := 'MANUAL-REPORT';
        Expense.Modify();
        ExpenseReportLine."Document No." := Expense."Expense Report No.";
        ExpenseReportLine."Line No." := 10000;
        ExpenseReportLine."Expense No." := Expense."No.";
        ExpenseReportLine."Corporate Card Id" := CorpCard."Card Id";
        ExpenseReportLine.Amount := Expense.Amount;
        ExpenseReportLine.Insert();
        CreateTransaction(CorpCardTrans, CorpCard);

        CorpCardExpenseMatch.LinkExpense(CorpCardTrans, Expense."No.");

        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(CorpCardTrans."Entry No.", ExpenseReportLine."Credit Card Feed No.", 'The existing report line must retain the late feed link.');
        Assert.AreEqual(20, ExpenseReportLine.Amount, 'Linking provenance must not change the report amount.');
        Assert.AreEqual(CorpCardTrans.Status::Submitted, CorpCardTrans.Status, 'An expense already in a report must not create another draft.');
    end;

    [Test]
    procedure LateFeedLinksPostedExpenseWithoutPostingAgain()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
        ExpenseNo: Code[20];
        GLEntryCount: Integer;
        VATEntryCount: Integer;
        ExpenseCount: Integer;
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        InsertExpense(Expense, CorpCard);
        PostedExpenseReportHeader."No." := 'MANUAL-POSTED';
        PostedExpenseReportHeader.Insert();
        PostedExpenseReportLine."Document No." := PostedExpenseReportHeader."No.";
        PostedExpenseReportLine."Line No." := 10000;
        PostedExpenseReportLine."Expense No." := Expense."No.";
        PostedExpenseReportLine."Corporate Card Id" := CorpCard."Card Id";
        PostedExpenseReportLine.Insert();
        Expense.Status := Expense.Status::Submitted;
        Expense."Posted Expense Report No." := PostedExpenseReportHeader."No.";
        Expense.Modify();
        CreateTransaction(CorpCardTrans, CorpCard);
        ExpenseCount := Expense.Count();
        GLEntryCount := GLEntry.Count();
        VATEntryCount := VATEntry.Count();

        Assert.IsTrue(CorpCardExpenseMatch.MatchExistingExpense(CorpCardTrans, ExpenseNo), 'Matching must include posted expenses.');
        CorpCardExpenseMatch.LinkExpense(CorpCardTrans, ExpenseNo);

        PostedExpenseReportLine.Get(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.");
        Expense.Get(Expense."No.");
        Assert.AreEqual(CorpCardTrans."Entry No.", PostedExpenseReportLine."Credit Card Feed No.", 'The posted line must retain the late feed link.');
        Assert.AreEqual(CorpCardTrans.Status::Posted, CorpCardTrans.Status, 'A late link must not submit the expense for posting again.');
        Assert.AreEqual(PostedExpenseReportHeader."No.", CorpCardTrans."Posted Expense Report No.", 'The existing posted report must be linked.');
        Assert.AreEqual(Expense.Status::Submitted, Expense.Status, 'Matching must not reopen an expense.');
        Assert.AreEqual(ExpenseCount, Expense.Count(), 'Matching must not create another expense.');
        Assert.AreEqual(GLEntryCount, GLEntry.Count(), 'Matching must not post G/L entries.');
        Assert.AreEqual(VATEntryCount, VATEntry.Count(), 'Matching must not post VAT entries.');
    end;

    [Test]
    procedure FeedLinksReleasedExpenseWithoutReopeningIt()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
        ExpenseNo: Code[20];
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        InsertExpense(Expense, CorpCard);
        Expense.Status := Expense.Status::Released;
        Expense.Modify();
        CreateTransaction(CorpCardTrans, CorpCard);

        Assert.IsTrue(CorpCardExpenseMatch.MatchExistingExpense(CorpCardTrans, ExpenseNo), 'Matching must include released expenses.');
        CorpCardExpenseMatch.LinkExpense(CorpCardTrans, ExpenseNo);

        Expense.Get(ExpenseNo);
        Assert.AreEqual(Expense.Status::Released, Expense.Status, 'Linking provenance must not change document status.');
        Assert.AreEqual(CorpCardTrans."Entry No.", Expense."Credit Card Feed No.", 'The released expense must reference the transaction.');
    end;

    [Test]
    procedure ReferencedManualCardCannotBeDeletedBeforeFeedArrives()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        InsertExpense(Expense, CorpCard);

        asserterror CorpCard.Delete(true);

        Assert.ExpectedError('referenced by an expense');
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

    local procedure InitializeExpense(var Expense: Record Expense; CorpCard: Record "EA Corp Card")
    begin
        Expense.Init();
        Expense."No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(Expense."No."));
        Expense."Expense User No." := CorpCard."Expense User No.";
        Expense."Reimbursement Type" := Expense."Reimbursement Type"::"Credit Card";
        Expense."Expense Date" := WorkDate();
        Expense.Amount := 20;
    end;

    local procedure CreateCorporateCardDraft(var Expense: Record Expense)
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        LibraryExpense: Codeunit "Library - Expense";
        ExpenseWriter: Codeunit "EA Corp Card Expense Writer";
        ExpenseNo: Code[20];
    begin
        Initialize();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        CorpCard.Get('CORPCARD-0001');
        CreateTransaction(CorpCardTrans, CorpCard);
        ExpenseWriter.CreateDraftFromTrans(CorpCardTrans, ExpenseNo);
        Expense.Get(ExpenseNo);
    end;

    local procedure InsertExpense(var Expense: Record Expense; CorpCard: Record "EA Corp Card")
    begin
        InitializeExpense(Expense, CorpCard);
        Expense."Corporate Card Id" := CorpCard."Card Id";
        Expense.Insert();
    end;

    local procedure CreateTransaction(var CorpCardTrans: Record "EA Corp Card Trans"; CorpCard: Record "EA Corp Card")
    begin
        CorpCardTrans.Init();
        CorpCardTrans."Provider Code" := CorpCard."Provider Code";
        CorpCardTrans."Card Id" := CorpCard."Card Id";
        CorpCardTrans."Provider Trans Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));
        CorpCardTrans."Trans Date" := WorkDate();
        CorpCardTrans.Amount := 20;
        CorpCardTrans.Insert(true);
    end;

    local procedure CreateSecondCard(var OtherCard: Record "EA Corp Card"; CorpCard: Record "EA Corp Card")
    begin
        OtherCard := CorpCard;
        OtherCard."Card Id" := 'SECOND-CARD';
        OtherCard.Insert(true);
    end;
}
