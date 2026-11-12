// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using System.TestLibraries.Upgrade;
using System.Upgrade;

// [FEATURE] [Expense Agent] [Corporate Card]
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
    procedure DefaultProviderSetupUsesVisaAndAmex()
    var
        CsvProvider: Record "EA Corp Card Provider";
        XmlProvider: Record "EA Corp Card Provider";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
    begin
        // [SCENARIO] Default setup initializes provider abbreviations with provider names.
        Initialize();

        // [GIVEN] Default providers have a generated CSV abbreviation and no XML abbreviation.
        InitializeDefaultBankAccount();
        CsvProvider.Get('CORPCARDCSV');
        CsvProvider."Short Name" := 'CORP';
        CsvProvider.Modify();
        XmlProvider.Get('CORPCARDXML');
        XmlProvider."Short Name" := '';
        XmlProvider.Modify();

        // [WHEN] Corporate card defaults are created.
        CreateCorpCardSetup.CreateDefaults();

        // [THEN] The generated and missing abbreviations are replaced with provider names.
        CsvProvider.Get(CsvProvider.Code);
        XmlProvider.Get(XmlProvider.Code);
        Assert.AreEqual('VISA', CsvProvider."Short Name", 'Setup must replace the generated CSV provider abbreviation.');
        Assert.AreEqual('AMEX', XmlProvider."Short Name", 'Setup must initialize the XML provider abbreviation.');
    end;

    [Test]
    procedure RepeatedDefaultProviderSetupPreservesCustomNames()
    var
        CsvProvider: Record "EA Corp Card Provider";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
    begin
        // [SCENARIO] Repeating default setup preserves a customized provider abbreviation.
        Initialize();

        // [GIVEN] Default setup has run and the CSV provider abbreviation is customized.
        InitializeDefaultBankAccount();
        CreateCorpCardSetup.CreateDefaults();
        CsvProvider.Get('CORPCARDCSV');
        CsvProvider."Short Name" := 'BANK';
        CsvProvider.Modify();

        // [WHEN] Corporate card defaults are created again.
        CreateCorpCardSetup.CreateDefaults();

        // [THEN] The custom abbreviation is retained.
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
        // [SCENARIO] Default card registration supports expenses incurred before the current year.
        Initialize();

        // [GIVEN] A default card belongs to the user of an expense dated one year ago.
        InitializeDefaultBankAccount();
        CreateCorpCardSetup.CreateDefaults();
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);
        Expense."Expense Date" := CalcDate('<-1Y>', WorkDate());

        // [WHEN] The default card is selected for the historical expense.
        Expense.Validate("Corporate Card Id", CorpCard."Card Id");

        // [THEN] The card selection is accepted.
        Assert.AreEqual(CorpCard."Card Id", Expense."Corporate Card Id", 'Registered demo cards must also support historical sample expenses.');
    end;

    [Test]
    procedure CardDisplayWithoutShortNameUsesAtMostFourProviderCodeCharacters()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardSelectionMgt: Codeunit "EA Corp Card Selection Mgt";
    begin
        // [SCENARIO] A provider without an abbreviation still has a compact card display.
        Initialize();

        // [GIVEN] The selected card's provider has no short name.
        CorpCard.Get('CORPCARD-0001');
        CorpCardProvider.Get(CorpCard."Provider Code");
        CorpCardProvider."Short Name" := '';
        CorpCardProvider.Modify();

        // [WHEN] The card display is generated.
        // [THEN] The fallback provider prefix is limited to four characters and followed by the card suffix.
        Assert.AreEqual(
            CopyStr(CorpCard."Provider Code", 1, 4) + ' 0001',
            CorpCardSelectionMgt.GetCardDisplay(CorpCard."Card Id"),
            'Existing providers without a short name must still have a compact card label.');
    end;

    [Test]
    procedure ReportCardDisplaysBatchLoadsBothReportStates()
    var
        CorpCard: Record "EA Corp Card";
        SecondCorpCard: Record "EA Corp Card";
        OtherCorpCard: Record "EA Corp Card";
        CorpCardProvider: Record "EA Corp Card Provider";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CorpCardSelectionMgt: Codeunit "EA Corp Card Selection Mgt";
        CardDisplays: Dictionary of [Code[50], Text[150]];
        LineNo: Integer;
    begin
        // [SCENARIO] Open and posted report displays load all referenced cards together without including other reports.
        Initialize();

        // [GIVEN] A report uses two cards, including a repeated card and a provider without a short name.
        CorpCard.Get('CORPCARD-0001');
        CorpCardProvider.Get(CorpCard."Provider Code");
        CorpCardProvider."Short Name" := 'VISA';
        CorpCardProvider.Modify();
        SecondCorpCard := CorpCard;
        SecondCorpCard."Card Id" := 'SECOND-CARD';
        SecondCorpCard."Provider Code" := 'CORPCARDXML';
        SecondCorpCard."Masked Card No." := '**** 0042';
        SecondCorpCard.Insert();
        CorpCardProvider.Get(SecondCorpCard."Provider Code");
        CorpCardProvider."Short Name" := '';
        CorpCardProvider.Modify();

        for LineNo := 1 to 3 do begin
            ExpenseReportLine.Init();
            ExpenseReportLine."Document No." := 'CARD-DISPLAY';
            ExpenseReportLine."Line No." := LineNo * 10000;
            ExpenseReportLine."Corporate Card Id" := CorpCard."Card Id";
            if LineNo = 2 then
                ExpenseReportLine."Corporate Card Id" := SecondCorpCard."Card Id";
            ExpenseReportLine.Insert();
            PostedExpenseReportLine.Init();
            PostedExpenseReportLine."Document No." := 'POSTED-CARD-DISPLAY';
            PostedExpenseReportLine."Line No." := ExpenseReportLine."Line No.";
            PostedExpenseReportLine."Corporate Card Id" := ExpenseReportLine."Corporate Card Id";
            PostedExpenseReportLine.Insert();
        end;

        OtherCorpCard := CorpCard;
        OtherCorpCard."Card Id" := 'OTHER-CARD';
        OtherCorpCard.Insert();
        ExpenseReportLine."Document No." := 'OTHER-REPORT';
        ExpenseReportLine."Corporate Card Id" := OtherCorpCard."Card Id";
        ExpenseReportLine.Insert();
        PostedExpenseReportLine."Document No." := 'OTHER-POSTED-REPORT';
        PostedExpenseReportLine."Corporate Card Id" := ExpenseReportLine."Corporate Card Id";
        PostedExpenseReportLine.Insert();

        // [WHEN] Card displays are loaded for the open report.
        CorpCardSelectionMgt.LoadReportCardDisplays('CARD-DISPLAY', CardDisplays);

        // [THEN] Each card retains its own display, including the provider-code fallback.
        Assert.AreEqual('VISA 0001', CardDisplays.Get(CorpCard."Card Id"), 'The batch must include the first card with its provider and suffix.');
        Assert.AreEqual('CORP 0042', CardDisplays.Get(SecondCorpCard."Card Id"), 'The batch must include the second card with the provider-code prefix.');
        Assert.IsFalse(CardDisplays.ContainsKey(OtherCorpCard."Card Id"), 'Cards belonging only to another report must not be loaded.');

        // [WHEN] Displays are loaded for the posted report, replacing a previous batch.
        CardDisplays.Add(OtherCorpCard."Card Id", 'Stale display');
        CorpCardSelectionMgt.LoadPostedReportCardDisplays('POSTED-CARD-DISPLAY', CardDisplays);

        // [THEN] Posted lines use the same formatting and report scope.
        Assert.AreEqual('VISA 0001', CardDisplays.Get(CorpCard."Card Id"), 'The posted batch must include the first card display.');
        Assert.AreEqual('CORP 0042', CardDisplays.Get(SecondCorpCard."Card Id"), 'The posted batch must include the second card display.');
        Assert.IsFalse(CardDisplays.ContainsKey(OtherCorpCard."Card Id"), 'The posted query must not load another report''s cards.');
    end;

    [Test]
    procedure CardSelectionRejectsAnotherExpenseUsersCard()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
    begin
        // [SCENARIO] Card ownership prevents one expense user from selecting another user's card.
        Initialize();

        // [GIVEN] The expense belongs to a user other than the card owner.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);
        Expense."Expense User No." := 'OTHER-USER';

        // [WHEN] The other user's card is selected.
        asserterror Expense.Validate("Corporate Card Id", CorpCard."Card Id");

        // [THEN] The ownership mismatch is reported.
        Assert.ExpectedError(Expense."Expense User No.");
    end;

    [Test]
    procedure CardSelectionRejectsBlockedCards()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
    begin
        // [SCENARIO] Blocking a card prevents new expense selections.
        Initialize();

        // [GIVEN] An expense user's card is blocked.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);
        CorpCard.Blocked := true;
        CorpCard.Modify();

        // [WHEN] The blocked card is selected.
        asserterror Expense.Validate("Corporate Card Id", CorpCard."Card Id");

        // [THEN] Card selection fails with the blocked-card error.
        Assert.ExpectedError(CorpCard.FieldCaption(Blocked));
    end;

    [Test]
    procedure CardSelectionRejectsExpiredCards()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
    begin
        // [SCENARIO] Card validity must cover the expense date.
        Initialize();

        // [GIVEN] The card expired before the expense date.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);
        CorpCard."Valid To" := WorkDate() - 1;
        CorpCard.Modify();

        // [WHEN] The expired card is selected.
        asserterror Expense.Validate("Corporate Card Id", CorpCard."Card Id");

        // [THEN] The invalid card date is reported.
        Assert.ExpectedError('is not valid');
    end;

    [Test]
    procedure CardCanBeSelectedForAnExpenseOnItsLastValidDay()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
    begin
        // [SCENARIO] The card's last valid day is included without creating feed provenance.
        Initialize();

        // [GIVEN] The expense date equals the card's last valid day.
        CorpCard.Get('CORPCARD-0001');
        CorpCard."Valid To" := WorkDate();
        CorpCard.Modify();
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);

        // [WHEN] The card is selected.
        Expense.Validate("Corporate Card Id", CorpCard."Card Id");

        // [THEN] Selection succeeds without linking a feed transaction.
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
        // [SCENARIO] A manual card expense can be drafted without a card, but release requires an owned card.
        Initialize();

        // [GIVEN] A saved corporate card expense draft has no selected card.
        CorpCard.Get('CORPCARD-0001');
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.CreateExpense(Expense, CorpCard."Expense User No.", 'AIRLINE', '', '', false, '', 20);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Validate("Corporate Card Id", '');
        Expense.Modify(true);
        CorpCardSelectionMgt.ValidateExpenseCard(Expense, false);
        Commit();

        // [WHEN] The draft is released without selecting a card.
        asserterror Expense.PerformManualRelease();

        // [THEN] The missing card is reported.
        Assert.ExpectedError(Expense.FieldCaption("Corporate Card Id"));

        // [WHEN] An owned card is selected and the draft is released again.
        Expense.Get(Expense."No.");
        Expense.Validate("Corporate Card Id", CorpCard."Card Id");
        Expense.Modify(true);
        Expense.PerformManualRelease();

        // [THEN] Release succeeds.
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
        // [SCENARIO] An expense linked to a feed must retain the feed's card identity.
        Initialize();

        // [GIVEN] An expense references a transaction from one of two owned cards.
        CorpCard.Get('CORPCARD-0001');
        CreateSecondCard(OtherCard, CorpCard);
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        Expense."Credit Card Feed No." := CorpCardTrans."Entry No.";
        Expense."Corporate Card Id" := CorpCard."Card Id";

        // [WHEN] The other card is selected for the linked expense.
        asserterror Expense.Validate("Corporate Card Id", OtherCard."Card Id");

        // [THEN] Changing the linked card identity is rejected.
        Assert.ExpectedError(Expense.FieldCaption("Corporate Card Id"));
    end;

    [Test]
    procedure FeedLinkedCardCannotBeClearedThroughDirectModification()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
    begin
        // [SCENARIO] Direct record modification cannot remove the card identity from a feed-linked expense.
        Initialize();

        // [GIVEN] A persisted expense has a selected card and a feed link.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        Expense."Credit Card Feed No." := CorpCardTrans."Entry No.";
        Expense.Modify(true);

        // [WHEN] The card is cleared and the expense is modified with table triggers.
        Expense."Corporate Card Id" := '';

        asserterror Expense.Modify(true);

        // [THEN] Removing the linked card identity is rejected.
        Assert.ExpectedError(Expense.FieldCaption("Corporate Card Id"));
    end;

    [Test]
    procedure FeedLinkedReportLineCardCannotBeClearedThroughDirectModification()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] Report lines retain their feed-linked card identity even when validation is bypassed.
        Initialize();

        // [GIVEN] A persisted report line references a card and its feed transaction.
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

        // [WHEN] The card is cleared and the report line is modified with table triggers.
        ExpenseReportLine."Corporate Card Id" := '';

        asserterror ExpenseReportLine.Modify(true);

        // [THEN] Removing the linked card identity is rejected.
        Assert.ExpectedError(ExpenseReportLine.FieldCaption("Corporate Card Id"));
    end;

    [Test]
    procedure BlockedCardDoesNotPreventExpenseDescriptionChanges()
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
    begin
        // [SCENARIO] Blocking a previously selected card does not prevent receipt-description corrections.
        Initialize();

        // [GIVEN] An expense already references a card that is subsequently blocked.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CorpCard.Blocked := true;
        CorpCard.Modify();

        // [WHEN] The expense description is updated.
        Expense.Description := 'Updated receipt details';

        Expense.Modify(true);

        // [THEN] The description change is saved.
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
        // [SCENARIO] Identical card suffixes do not make expenses paid with different cards interchangeable.
        Initialize();

        // [GIVEN] Two expenses use distinct cards with identical suffixes, and a feed arrives for the first card.
        CorpCard.Get('CORPCARD-0001');
        CreateSecondCard(OtherCard, CorpCard);
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CorpCardTestLib.InsertExpense(OtherExpense, OtherCard);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);

        // [WHEN] The feed is matched to an existing expense.
        Assert.IsTrue(CorpCardExpenseMatch.MatchExistingExpense(CorpCardTrans, ExpenseNo), 'The selected card should identify the expense.');

        // [THEN] The expense using the exact card identity is selected.
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
        // [SCENARIO] Multiple matching expenses require review rather than an arbitrary link.
        Initialize();

        // [GIVEN] Two expenses use the same card and match the incoming transaction.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CorpCardTestLib.InsertExpense(OtherExpense, CorpCard);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);

        // [WHEN] The feed is matched to an existing expense.
        asserterror CorpCardExpenseMatch.MatchExistingExpense(CorpCardTrans, ExpenseNo);

        // [THEN] The ambiguous match is reported.
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
        // [SCENARIO] A near amount match requires review before linking the feed.
        Initialize();

        // [GIVEN] An expense uses the incoming transaction's card but has a slightly different amount.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        Expense.Amount := 19;
        Expense.Modify();
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);

        // [WHEN] The feed is matched to an existing expense.
        asserterror CorpCardExpenseMatch.MatchExistingExpense(CorpCardTrans, ExpenseNo);

        // [THEN] The amount difference requires review instead of being treated as no match.
        Assert.ExpectedError('Review the amount before linking');
    end;

    [Test]
    procedure UpgradePreservesLegacyManualSource()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        LegacyExpense: Record Expense;
        ManualExpense: Record Expense;
        UpgradeExpenseAgentSetup: Codeunit "Upgrade Expense Agent Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        // [SCENARIO] Legacy feed links backfill card identity without changing manual provenance.
        Initialize();

        // [GIVEN] A legacy manual expense is linked to a feed, and another manual expense has no feed link.
        if UpgradeTag.HasUpgradeTag(UpgradeExpenseAgentSetup.GetCorporateCardIdentityUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(
                UpgradeExpenseAgentSetup.GetCorporateCardIdentityUpgradeTag(), CopyStr(CompanyName(), 1, 30));
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        CorpCardTestLib.InitializeExpense(LegacyExpense, CorpCard);
        LegacyExpense."Credit Card Feed No." := CorpCardTrans."Entry No.";
        LegacyExpense.Insert(false);
        CorpCardTrans."Expense No." := LegacyExpense."No.";
        CorpCardTrans.Status := CorpCardTrans.Status::Matched;
        CorpCardTrans.Modify(false);
        CorpCardTestLib.InitializeExpense(ManualExpense, CorpCard);
        ManualExpense.Insert(false);

        // [WHEN] The corporate card identity upgrade runs.
        UpgradeExpenseAgentSetup.UpgradeCorporateCardIdentity();

        // [THEN] Card identity is backfilled and the upgrade is marked complete, while both expenses remain manual.
        LegacyExpense.Get(LegacyExpense."No.");
        LegacyExpense.TestField("Corporate Card Id", CorpCard."Card Id");
        LegacyExpense.TestField(Source, LegacyExpense.Source::Manual);
        ManualExpense.Get(ManualExpense."No.");
        ManualExpense.TestField("Corporate Card Id", '');
        ManualExpense.TestField(Source, ManualExpense.Source::Manual);
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgradeExpenseAgentSetup.GetCorporateCardIdentityUpgradeTag()),
            'The corporate card identity upgrade must be marked complete.');
    end;

    [Test]
    procedure UpgradeCorporateCardIdentityPreservesMigrationBoundaries()
    var
        CorpCard: Record "EA Corp Card";
        OtherCorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        OtherCorpCardTrans: Record "EA Corp Card Trans";
        MissingCorpCardTrans: Record "EA Corp Card Trans";
        Expenses: array[6] of Record Expense;
        ExpenseReportLines: array[6] of Record "Expense Report Line";
        PostedExpenseReportLines: array[6] of Record "Posted Expense Report Line";
        UpgradeExpenseAgentSetup: Codeunit "Upgrade Expense Agent Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        ExpectedCardIds: array[6] of Code[50];
        FeedEntryNos: array[6] of Integer;
        ScenarioNo: Integer;
    begin
        // [SCENARIO] Bulk identity migration updates matching legacy rows without overwriting assigned cards or unmatched rows.
        Initialize();

        // [GIVEN] Two valid feeds and a deleted feed, with the identity upgrade not yet completed.
        if UpgradeTag.HasUpgradeTag(UpgradeExpenseAgentSetup.GetCorporateCardIdentityUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(
                UpgradeExpenseAgentSetup.GetCorporateCardIdentityUpgradeTag(), CopyStr(CompanyName(), 1, 30));
        CorpCard.Get('CORPCARD-0001');
        OtherCorpCard.Get('CORPCARD-0002');
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        CorpCardTestLib.CreateTransaction(OtherCorpCardTrans, OtherCorpCard);
        CorpCardTestLib.CreateTransaction(MissingCorpCardTrans, OtherCorpCard);
        MissingCorpCardTrans.Delete(false);
        FeedEntryNos[1] := CorpCardTrans."Entry No.";
        FeedEntryNos[2] := CorpCardTrans."Entry No.";
        FeedEntryNos[3] := MissingCorpCardTrans."Entry No.";
        FeedEntryNos[5] := CorpCardTrans."Entry No.";
        FeedEntryNos[6] := OtherCorpCardTrans."Entry No.";
        ExpectedCardIds[1] := CorpCard."Card Id";
        ExpectedCardIds[2] := OtherCorpCard."Card Id";
        ExpectedCardIds[5] := CorpCard."Card Id";
        ExpectedCardIds[6] := OtherCorpCard."Card Id";

        // [GIVEN] Each table has legacy, assigned, dangling, unlinked, repeated-feed, and second-card rows.
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

        // [THEN] Only matching legacy rows receive the feed card, and all existing sources are preserved.
        for ScenarioNo := 1 to ArrayLen(Expenses) do begin
            Expenses[ScenarioNo].Get(Expenses[ScenarioNo]."No.");
            Expenses[ScenarioNo].TestField("Corporate Card Id", ExpectedCardIds[ScenarioNo]);
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
        // [SCENARIO] Non-financial edits and unchanged financial values preserve a feed-created draft's provenance.
        // [GIVEN] A corporate card draft references its originating transaction.
        CreateCorporateCardDraft(Expense);
        CorpCardTrans.Get(Expense."Credit Card Feed No.");

        // [WHEN] Existing financial values are revalidated and receipt details are edited.
        Expense.Validate(Amount, Expense.Amount);
        Expense.Validate("Expense Date", Expense."Expense Date");
        Expense.Validate("Currency Code", Expense."Currency Code");
        Expense.Description := 'Receipt details';
        Expense.Modify(true);

        // [THEN] The draft retains its corporate card source, feed link, and description change.
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
        // [SCENARIO] A feed-created expense must retain the transaction's captured amount.
        // [GIVEN] A corporate card draft has been created from a transaction.
        CreateCorporateCardDraft(Expense);

        // [WHEN] The captured amount is changed through validation.
        asserterror Expense.Validate(Amount, Expense.Amount + 1);

        // [THEN] The amount change is rejected.
        Assert.ExpectedError(Expense.FieldCaption(Amount) + ' cannot be changed');
    end;

    [Test]
    procedure CorporateCardDraftRejectsExpenseDateChange()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] A feed-created expense must retain the transaction's captured date.
        // [GIVEN] A corporate card draft has been created from a transaction.
        CreateCorporateCardDraft(Expense);

        // [WHEN] The captured date is changed through validation.
        asserterror Expense.Validate("Expense Date", CalcDate('<1D>', Expense."Expense Date"));

        // [THEN] The date change is rejected.
        Assert.ExpectedError(Expense.FieldCaption("Expense Date") + ' cannot be changed');
    end;

    [Test]
    procedure CorporateCardDraftRejectsCurrencyValidation()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] A feed-created expense must retain the transaction's captured currency.
        // [GIVEN] A corporate card draft has been created from a transaction.
        CreateCorporateCardDraft(Expense);

        // [WHEN] A different currency is validated.
        asserterror Expense.Validate("Currency Code", 'EUR');

        // [THEN] The currency change is rejected.
        Assert.ExpectedError(Expense.FieldCaption("Currency Code") + ' cannot be changed');
    end;

    [Test]
    procedure CorporateCardDraftRejectsCurrencyAssignedWithoutValidation()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Direct assignment cannot bypass a feed-created draft's currency protection.
        // [GIVEN] A corporate card draft has been created from a transaction.
        CreateCorporateCardDraft(Expense);

        // [WHEN] A different currency is assigned and the expense is modified with table triggers.
        Expense."Currency Code" := 'EUR';

        asserterror Expense.Modify(true);

        // [THEN] The currency change is rejected.
        Assert.ExpectedError(Expense.FieldCaption("Currency Code") + ' cannot be changed');
    end;

    [Test]
    procedure LinkingBlankCardExpenseRejectsChangedAmount()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
    begin
        // [SCENARIO] Linking cannot assign a card or feed to a manual expense whose amount differs from the transaction.
        Initialize();

        // [GIVEN] An unlinked expense has no selected card and its amount differs from the incoming transaction.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);
        Expense.Insert();
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        Expense.Amount := CorpCardTrans.Amount + 1;
        Expense.Modify();

        // [WHEN] The transaction is linked to the expense.
        asserterror CorpCardExpenseMatch.LinkExpense(CorpCardTrans, Expense."No.");

        // [THEN] The amount mismatch is reported and neither card identity nor feed provenance is assigned.
        Assert.ExpectedError(Expense.FieldCaption(Amount));
        Expense.Get(Expense."No.");
        Expense.TestField("Corporate Card Id", '');
        Expense.TestField("Credit Card Feed No.", 0);
    end;

    [Test]
    procedure LinkingBlankCardExpenseRejectsChangedCurrency()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
    begin
        // [SCENARIO] Linking cannot assign a card or feed to a manual expense whose currency differs from the transaction.
        Initialize();

        // [GIVEN] An unlinked expense has no selected card and uses a different currency from the incoming transaction.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);
        Expense.Insert();
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        Expense."Currency Code" := 'EUR';
        Expense.Modify();

        // [WHEN] The transaction is linked to the expense.
        asserterror CorpCardExpenseMatch.LinkExpense(CorpCardTrans, Expense."No.");

        // [THEN] The currency mismatch is reported and neither card identity nor feed provenance is assigned.
        Assert.ExpectedError(Expense.FieldCaption("Currency Code"));
        Expense.Get(Expense."No.");
        Expense.TestField("Corporate Card Id", '');
        Expense.TestField("Credit Card Feed No.", 0);
    end;

    [Test]
    procedure LinkingBlankCardExpenseRejectsDateOutsideWindow()
    begin
        // [SCENARIO] A manual expense without a selected card cannot link outside the date matching window.
        // [GIVEN] An unlinked manual expense has no selected card.
        // [WHEN] Linking is attempted just before and just after the allowed date range.
        // [THEN] Both attempts fail without linking the expense or transaction.
        VerifyLinkRejectsDateOutsideWindow(false);
    end;

    [Test]
    procedure LinkingSelectedCardExpenseRejectsDateOutsideWindow()
    begin
        // [SCENARIO] Selecting a card does not bypass the date matching window when linking an expense.
        // [GIVEN] An unlinked manual expense has the transaction's card selected.
        // [WHEN] Linking is attempted just before and just after the allowed date range.
        // [THEN] Both attempts fail without linking the expense or transaction.
        VerifyLinkRejectsDateOutsideWindow(true);
    end;

    [Test]
    procedure LinkingBlankCardExpenseAcceptsDateWindowBoundaries()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
        Boundary: Integer;
    begin
        // [SCENARIO] The first and last dates in the matching window allow linking an expense without a selected card.
        Initialize();

        // [GIVEN] The corporate card date matching window is configured.
        CorpCard.Get('CORPCARD-0001');
        ExpenseAgentSetup.Get();
        for Boundary := 0 to 1 do begin
            // [GIVEN] An unlinked expense without a selected card falls exactly on one boundary of the window.
            CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
            CorpCardTestLib.InitializeExpense(Expense, CorpCard);
            Expense."Expense Date" := CorpCardTrans."Trans Date" + (2 * Boundary - 1) * ExpenseAgentSetup."Corp Card Date Match Window";
            Expense.Insert();

            // [WHEN] The transaction is linked to the expense.
            CorpCardExpenseMatch.LinkExpense(CorpCardTrans, Expense."No.");

            // [THEN] Both boundary dates allow assigning the card identity and feed provenance.
            Expense.Get(Expense."No.");
            Expense.TestField("Corporate Card Id", CorpCard."Card Id");
            Expense.TestField("Credit Card Feed No.", CorpCardTrans."Entry No.");
        end;
    end;

    local procedure VerifyLinkRejectsDateOutsideWindow(SelectCard: Boolean)
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
        Boundary: Integer;
    begin
        Initialize();

        // [GIVEN] An unlinked manual expense has the requested card-selection state and an incoming transaction.
        CorpCard.Get('CORPCARD-0001');
        ExpenseAgentSetup.Get();
        CorpCardTestLib.InitializeExpense(Expense, CorpCard);
        if SelectCard then
            Expense."Corporate Card Id" := CorpCard."Card Id";
        Expense.Insert();
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        for Boundary := 0 to 1 do begin
            Expense."Expense Date" := CorpCardTrans."Trans Date" + (2 * Boundary - 1) * (ExpenseAgentSetup."Corp Card Date Match Window" + 1);
            Expense.Modify();

            // [WHEN] The transaction is linked with an expense date just outside either boundary of the window.
            asserterror CorpCardExpenseMatch.LinkExpense(CorpCardTrans, Expense."No.");

            // [THEN] The date mismatch is reported and neither record receives a feed link.
            Assert.ExpectedError('outside the matching date window');
            Expense.Get(Expense."No.");
            Expense.TestField("Credit Card Feed No.", 0);
            CorpCardTrans.TestField("Expense No.", '');
        end;
    end;

    [Test]
    procedure MatchedManualExpenseRetainsFinancialEditing()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
    begin
        // [SCENARIO] Adding feed provenance does not restrict financial editing of a manually created expense.
        Initialize();

        // [GIVEN] A manual expense is linked to its matching card transaction.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        CorpCardExpenseMatch.LinkExpense(CorpCardTrans, Expense."No.");
        Expense.Get(Expense."No.");

        // [WHEN] The expense amount, date, and currency are updated.
        Expense.Validate(Amount, 21);
        Expense.Validate("Expense Date", CalcDate('<1D>', WorkDate()));
        Expense.Validate("Currency Code", 'EUR');
        Expense.Modify(true);

        // [THEN] The financial changes are saved without changing the manual source or feed link.
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
        // [SCENARIO] Automatic draft processing links an existing manual expense and remains idempotent on retry.
        Initialize();

        // [GIVEN] An imported statement transaction matches an existing manual card expense.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CorpCardTestLib.CreateStatement(CorpCardStatement, CorpCard."Provider Code", 'MANUAL-MATCH', 20, CorpCardStatement.Status::Imported);
        CorpCardStatement."Currency Code" := '';
        CorpCardStatement.Modify();
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        CorpCardTrans."Statement Entry No." := CorpCardStatement."Statement Entry No.";
        CorpCardTrans.Modify();
        ExpenseCount := Expense.Count();

        // [WHEN] Post-import processing runs twice for the statement.
        PostImportOrch.ProcessStatementPostImport(CorpCardStatement."Statement Entry No.", ExpenseWriter);
        PostImportOrch.ProcessStatementPostImport(CorpCardStatement."Statement Entry No.", ExpenseWriter);

        // [THEN] The transaction links the manual expense without creating a duplicate or changing its source.
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
        // [SCENARIO] A late feed adds provenance to a submitted expense without changing report amounts.
        Initialize();

        // [GIVEN] A manual card expense is already submitted on an existing report line.
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

        // [WHEN] The late feed is linked to the submitted expense.
        CorpCardExpenseMatch.LinkExpense(CorpCardTrans, Expense."No.");

        // [THEN] The existing report line retains its amount and receives the link without another draft.
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
        // [SCENARIO] Late feed matching preserves an expense's released status.
        Initialize();

        // [GIVEN] A manually created card expense is released before its feed arrives.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        Expense.Status := Expense.Status::Released;
        Expense.Modify();
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);

        // [WHEN] The feed is matched and linked to the released expense.
        Assert.IsTrue(CorpCardExpenseMatch.MatchExistingExpense(CorpCardTrans, ExpenseNo), 'Matching must include released expenses.');
        CorpCardExpenseMatch.LinkExpense(CorpCardTrans, ExpenseNo);

        // [THEN] The expense remains released and receives the transaction link.
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
        // [SCENARIO] A selected card remains protected from deletion even before a feed references it.
        Initialize();

        // [GIVEN] A manual expense references a card without an incoming feed.
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.InsertExpense(Expense, CorpCard);

        // [WHEN] The referenced card is deleted with table triggers.
        asserterror CorpCard.Delete(true);

        // [THEN] The existing expense reference prevents deletion.
        Assert.ExpectedError('referenced by an expense');
    end;

    local procedure InitializeDefaultBankAccount()
    var
        BankAccount: Record "Bank Account";
    begin
        if not BankAccount.Get('CORPCARD') then begin
            BankAccount.Init();
            BankAccount."No." := 'CORPCARD';
            BankAccount.Validate(IBAN, 'GB82WEST12345698765432');
            BankAccount.Insert(true);
        end else begin
            BankAccount.Validate(IBAN, 'GB82WEST12345698765432');
            BankAccount.Modify(true);
        end;
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
