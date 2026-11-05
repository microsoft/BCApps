// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using System.TestLibraries.Upgrade;
using System.Upgrade;

codeunit 148364 EACorpCardSelectionTests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Assert: Codeunit Assert;
        CorpCardTestLib: Codeunit EACorpCardTestLib;

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
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);
        Expense."Expense Date" := CalcDate('<-1Y>', WorkDate());

        Expense.Validate("Corporate Card Id", CorpCard."Card Id");

        Assert.AreEqual(CorpCard."Card Id", Expense."Corporate Card Id", 'Registered demo cards must also support historical sample expenses.');
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
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);
        Expense."Expense User No." := 'OTHER-USER';

        asserterror Expense.Validate("Corporate Card Id", CorpCard."Card Id");

        Assert.ExpectedError(Expense."Expense User No.");
    end;

    [Test]
    procedure CardSelectionRejectsBlockedCards()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);
        CorpCard.Blocked := true;
        CorpCard.Modify();
        asserterror Expense.Validate("Corporate Card Id", CorpCard."Card Id");
        Assert.ExpectedError(CorpCard.FieldCaption(Blocked));
    end;

    [Test]
    procedure CardSelectionRejectsExpiredCards()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);
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
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);

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
        Commit();

        asserterror Expense.PerformManualRelease();

        Assert.ExpectedError(Expense.FieldCaption("Corporate Card Id"));
        Expense.Get(Expense."No.");
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
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
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
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        Expense."Credit Card Feed No." := CorpCardTrans."Entry No.";
        Expense.Modify(true);
        Expense."Corporate Card Id" := '';

        asserterror Expense.Modify(true);

        Assert.ExpectedError(Expense.FieldCaption("Corporate Card Id"));
    end;

    [Test]
    procedure FeedLinkedReportLineCardCannotBeClearedThroughDirectModification()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        ExpenseReportLine."Document No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ExpenseReportLine."Document No."));
        ExpenseReportLine."Line No." := 10000;
        ExpenseReportLine."Expense User No." := CorpCard."Expense User No.";
        ExpenseReportLine."Reimbursement Type" := ExpenseReportLine."Reimbursement Type"::"Credit Card";
        ExpenseReportLine."Expense Date" := WorkDate();
        ExpenseReportLine."Corporate Card Id" := CorpCard."Card Id";
        ExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";
        ExpenseReportLine.Insert();
        ExpenseReportLine."Corporate Card Id" := '';

        asserterror ExpenseReportLine.Modify(true);

        Assert.ExpectedError(ExpenseReportLine.FieldCaption("Corporate Card Id"));
    end;

    [Test]
    procedure BlockedCardDoesNotPreventExpenseDescriptionChanges()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CorpCard.Blocked := true;
        CorpCard.Modify();
        Expense.Description := 'Updated receipt details';

        Expense.Modify(true);

        Expense.Get(Expense."No.");
        Expense.TestField(Description, 'Updated receipt details');
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
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CorpCardTestLib.InsertExpense(OtherExpense, OtherCard);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);

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
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CorpCardTestLib.InsertExpense(OtherExpense, CorpCard);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);

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
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        Expense.Amount := 19;
        Expense.Modify();
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);

        asserterror CorpCardExpenseMatch.MatchExistingExpense(CorpCardTrans, ExpenseNo);

        Assert.ExpectedError('Review the amount before linking');
    end;

    [Test]
    procedure UpgradeInitializesLegacyCorporateCardSource()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        LegacyExpense: Record Expense;
        ManualExpense: Record Expense;
        UpgradeExpenseAgentSetup: Codeunit "Upgrade Expense Agent Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Upgrade]
        // [SCENARIO] Legacy feed-created expenses receive corporate card protections while manual expenses remain unchanged.
        Initialize();

        // [GIVEN] An unmigrated feed-created expense and a manual expense without a feed link.
        if UpgradeTag.HasUpgradeTag(UpgradeExpenseAgentSetup.GetCorporateCardIdentityUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(
                UpgradeExpenseAgentSetup.GetCorporateCardIdentityUpgradeTag(), CopyStr(CompanyName(), 1, 30));
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        CorpCardTestLib.InitializeExpense(LegacyExpense, CorpCard);
        LegacyExpense."Credit Card Feed No." := CorpCardTrans."Entry No.";
        LegacyExpense.Insert(false);
        CorpCardTestLib.InitializeExpense(ManualExpense, CorpCard);
        ManualExpense.Insert(false);

        // [WHEN] The corporate card identity upgrade runs.
        UpgradeExpenseAgentSetup.UpgradeCorporateCardIdentity();

        // [THEN] Card identity and source are backfilled before the upgrade is marked complete, without changing manual expenses.
        LegacyExpense.Get(LegacyExpense."No.");
        LegacyExpense.TestField("Corporate Card Id", CorpCard."Card Id");
        LegacyExpense.TestField(Source, LegacyExpense.Source::CorporateCard);
        ManualExpense.Get(ManualExpense."No.");
        ManualExpense.TestField("Corporate Card Id", '');
        ManualExpense.TestField(Source, ManualExpense.Source::Manual);
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgradeExpenseAgentSetup.GetCorporateCardIdentityUpgradeTag()),
            'The corporate card identity upgrade must be marked complete.');

        // [WHEN] The amount of the upgraded feed-created expense is changed.
        asserterror LegacyExpense.Validate(Amount, LegacyExpense.Amount + 1);

        // [THEN] The corporate card source protection rejects the change.
        Assert.ExpectedError(LegacyExpense.FieldCaption(Amount) + ' cannot be changed');
    end;

    [Test]
    procedure UpgradeCorporateCardIdentityPreservesMigrationBoundaries()
    var
        CorpCard: Record "EA Corp Card";
        OtherCorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        MissingCorpCardTrans: Record "EA Corp Card Trans";
        Expenses: array[4] of Record Expense;
        ExpenseReportLines: array[4] of Record "Expense Report Line";
        PostedExpenseReportLines: array[4] of Record "Posted Expense Report Line";
        UpgradeExpenseAgentSetup: Codeunit "Upgrade Expense Agent Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        ExpectedCardIds: array[4] of Code[50];
        FeedEntryNos: array[4] of Integer;
        ScenarioNo: Integer;
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Upgrade]
        // [SCENARIO] Bulk identity migration updates matching legacy rows without overwriting assigned cards or unmatched rows.
        Initialize();

        // [GIVEN] A valid feed and a deleted feed, with the identity upgrade not yet completed.
        if UpgradeTag.HasUpgradeTag(UpgradeExpenseAgentSetup.GetCorporateCardIdentityUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(
                UpgradeExpenseAgentSetup.GetCorporateCardIdentityUpgradeTag(), CopyStr(CompanyName(), 1, 30));
        CorpCard.Get('CORPCARD-0001');
        OtherCorpCard.Get('CORPCARD-0002');
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        CorpCardTestLib.CreateTransaction(MissingCorpCardTrans, OtherCorpCard);
        MissingCorpCardTrans.Delete(false);
        FeedEntryNos[1] := CorpCardTrans."Entry No.";
        FeedEntryNos[2] := CorpCardTrans."Entry No.";
        FeedEntryNos[3] := MissingCorpCardTrans."Entry No.";
        ExpectedCardIds[1] := CorpCard."Card Id";
        ExpectedCardIds[2] := OtherCorpCard."Card Id";

        // [GIVEN] Each destination table has a legacy row, an assigned row, a dangling feed link, and an unlinked row.
        for ScenarioNo := 1 to ArrayLen(Expenses) do begin
            CorpCardTestLib.InitializeExpense(Expenses[ScenarioNo], CorpCard);
            Expenses[ScenarioNo]."Credit Card Feed No." := FeedEntryNos[ScenarioNo];
            if ScenarioNo = 2 then
                Expenses[ScenarioNo]."Corporate Card Id" := OtherCorpCard."Card Id";
            Expenses[ScenarioNo].Insert(false);

            ExpenseReportLines[ScenarioNo].Init();
            ExpenseReportLines[ScenarioNo]."Document No." := Expenses[ScenarioNo]."No.";
            ExpenseReportLines[ScenarioNo]."Line No." := 10000;
            ExpenseReportLines[ScenarioNo]."Credit Card Feed No." := FeedEntryNos[ScenarioNo];
            ExpenseReportLines[ScenarioNo]."Corporate Card Id" := Expenses[ScenarioNo]."Corporate Card Id";
            ExpenseReportLines[ScenarioNo].Insert(false);

            PostedExpenseReportLines[ScenarioNo].Init();
            PostedExpenseReportLines[ScenarioNo]."Document No." := Expenses[ScenarioNo]."No.";
            PostedExpenseReportLines[ScenarioNo]."Line No." := 10000;
            PostedExpenseReportLines[ScenarioNo]."Credit Card Feed No." := FeedEntryNos[ScenarioNo];
            PostedExpenseReportLines[ScenarioNo]."Corporate Card Id" := Expenses[ScenarioNo]."Corporate Card Id";
            PostedExpenseReportLines[ScenarioNo].Insert(false);
        end;

        // [WHEN] The corporate card identity upgrade runs.
        UpgradeExpenseAgentSetup.UpgradeCorporateCardIdentity();

        // [THEN] Only matching legacy rows receive the feed card, and only the migrated expense changes source.
        for ScenarioNo := 1 to ArrayLen(Expenses) do begin
            Expenses[ScenarioNo].Get(Expenses[ScenarioNo]."No.");
            Expenses[ScenarioNo].TestField("Corporate Card Id", ExpectedCardIds[ScenarioNo]);
            if ScenarioNo = 1 then
                Expenses[ScenarioNo].TestField(Source, Expenses[ScenarioNo].Source::CorporateCard)
            else
                Expenses[ScenarioNo].TestField(Source, Expenses[ScenarioNo].Source::Manual);
            ExpenseReportLines[ScenarioNo].Get(ExpenseReportLines[ScenarioNo]."Document No.", ExpenseReportLines[ScenarioNo]."Line No.");
            ExpenseReportLines[ScenarioNo].TestField("Corporate Card Id", ExpectedCardIds[ScenarioNo]);
            PostedExpenseReportLines[ScenarioNo].Get(PostedExpenseReportLines[ScenarioNo]."Document No.", PostedExpenseReportLines[ScenarioNo]."Line No.");
            PostedExpenseReportLines[ScenarioNo].TestField("Corporate Card Id", ExpectedCardIds[ScenarioNo]);
        end;
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
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
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
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CorpCardTestLib.CreateStatement(CorpCardStatement, CorpCard."Provider Code", 'MANUAL-MATCH', 20, CorpCardStatement.Status::Imported);
        CorpCardStatement."Currency Code" := '';
        CorpCardStatement.Modify();
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
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
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        Expense.Status := Expense.Status::Submitted;
        Expense."Expense Report No." := 'MANUAL-REPORT';
        Expense.Modify();
        ExpenseReportLine."Document No." := Expense."Expense Report No.";
        ExpenseReportLine."Line No." := 10000;
        ExpenseReportLine."Expense No." := Expense."No.";
        ExpenseReportLine."Corporate Card Id" := CorpCard."Card Id";
        ExpenseReportLine.Amount := Expense.Amount;
        ExpenseReportLine.Insert();
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);

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
        // [FEATURE] [Expense Agent] [Corporate Card] [Matching]
        // [SCENARIO] A late feed links a genuinely posted manual expense without posting it again.
        Initialize();

        // [GIVEN] A manual card expense submitted and posted through the normal report lifecycle before its feed arrives.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.PostManualExpense(Expense, PostedExpenseReportLine, CorpCard);
        PostedExpenseReportHeader.Get(PostedExpenseReportLine."Document No.");
        Expense.TestField(Status, Expense.Status::Submitted);
        Expense.TestField("Credit Card Feed No.", 0);
        PostedExpenseReportLine.TestField("Credit Card Feed No.", 0);
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.IsFalse(GLEntry.IsEmpty(), 'The fixture must create real G/L entries for the original expense report.');
        GLEntry.SetRange("Document No.");
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        ExpenseCount := Expense.Count();
        GLEntryCount := GLEntry.Count();
        VATEntryCount := VATEntry.Count();

        // [WHEN] The late feed is matched and linked to the posted expense.
        Assert.IsTrue(CorpCardExpenseMatch.MatchExistingExpense(CorpCardTrans, ExpenseNo), 'Matching must include posted expenses.');
        CorpCardExpenseMatch.LinkExpense(CorpCardTrans, ExpenseNo);

        // [THEN] The existing posted report is linked without reopening the expense or creating expense, G/L, or VAT entries.
        PostedExpenseReportLine.Get(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.");
        Expense.Get(Expense."No.");
        Expense.TestField("Credit Card Feed No.", CorpCardTrans."Entry No.");
        Expense.TestField(Source, Expense.Source::Manual);
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
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        Expense.Status := Expense.Status::Released;
        Expense.Modify();
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);

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
        CorpCardTestLib.InsertExpense(Expense, CorpCard);

        asserterror CorpCard.Delete(true);

        Assert.ExpectedError('referenced by an expense');
    end;

    local procedure Initialize()
    begin
        CorpCardTestLib.InitializeCorpCardData();
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
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        ExpenseWriter.CreateDraftFromTrans(CorpCardTrans, ExpenseNo);
        Expense.Get(ExpenseNo);
    end;

    local procedure CreateSecondCard(var OtherCard: Record "EA Corp Card"; CorpCard: Record "EA Corp Card")
    begin
        OtherCard := CorpCard;
        OtherCard."Card Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(OtherCard."Card Id"));
        OtherCard.Insert(true);
    end;
}
