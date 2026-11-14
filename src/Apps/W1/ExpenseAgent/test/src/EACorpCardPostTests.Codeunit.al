// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Reconciliation;
using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.HumanResources.Employee;

codeunit 148358 EACorpCardPostTests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryERM: Codeunit "Library - ERM";
        LibraryExpense: Codeunit "Library - Expense";
        IsInitialized: Boolean;

    [Test]
    procedure LinkPostedExpenseMarksTransactionPostedWithoutCreatingBankingRecords()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CorpCard: Record "EA Corp Card";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CorpCardPostMgt: Codeunit "EA Corp Card Post Mgt";
        BankAccountLedgerEntryCount: Integer;
        BankAccReconciliationCount: Integer;
        BankAccReconciliationLineCount: Integer;
    begin
        Initialize();
        CorpCard.FindFirst();
        CorpCardTestLib.CreateStatement(CorpCardStatement, CorpCard."Provider Code", 'STMT-LINK-POSTED', 2000, CorpCardStatement.Status::Validated);
        CorpCardTestLib.CreatePostedTransaction(CorpCardTrans, CorpCardStatement, 2000);
        CorpCardTrans."Card Id" := CorpCard."Card Id";
        CorpCardTrans."Posted Expense Report No." := '';
        CorpCardTrans.Status := CorpCardTrans.Status::Submitted;
        CorpCardTrans.Modify(true);

        BankAccountLedgerEntryCount := BankAccountLedgerEntry.Count();
        BankAccReconciliationCount := BankAccReconciliation.Count();
        BankAccReconciliationLineCount := BankAccReconciliationLine.Count();

        PostedExpenseReportHeader."No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(PostedExpenseReportHeader."No."));
        PostedExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";

        CorpCardPostMgt.LinkPostedExpense(PostedExpenseReportLine, PostedExpenseReportHeader);

        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        Assert.AreEqual(CorpCardTrans.Status::Posted, CorpCardTrans.Status, 'Posting the expense report must mark the corporate card transaction as posted.');
        Assert.AreEqual(PostedExpenseReportHeader."No.", CorpCardTrans."Posted Expense Report No.", 'The corporate card transaction must reference the posted expense report.');
        Assert.AreEqual(BankAccountLedgerEntryCount, BankAccountLedgerEntry.Count(), 'Posting an expense report must not create a bank account ledger entry.');
        Assert.AreEqual(BankAccReconciliationCount, BankAccReconciliation.Count(), 'Posting an expense report must not create a bank account reconciliation.');
        Assert.AreEqual(BankAccReconciliationLineCount, BankAccReconciliationLine.Count(), 'Posting an expense report must not create a bank account reconciliation line.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CreditCardExpensePostsLiabilityToProviderBankAccount()
    var
        BankAccount: Record "Bank Account";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        Initialize();
        CreateLinkedCardExpenseReport(ExpenseReportHeader, ExpenseReportLine, CorpCardTrans, BankAccount);
        ExpenseReportHeader.PerformManualRelease();

        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        BankAccountLedgerEntry.SetRange("EA Corp Card Trans Entry No.", CorpCardTrans."Entry No.");
        Assert.IsTrue(BankAccountLedgerEntry.FindFirst(), 'Posting a linked credit-card expense must create a bank account ledger entry.');
        Assert.AreEqual(BankAccount."No.", BankAccountLedgerEntry."Bank Account No.", 'The expense liability must be posted to the provider corporate card bank account.');
        Assert.AreEqual(-2000, BankAccountLedgerEntry.Amount, 'The corporate card bank account must be credited by the expense amount.');
        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        Assert.AreEqual(CorpCardTrans.Status::Posted, CorpCardTrans.Status, 'The linked corporate card transaction must be marked as posted.');
    end;

    [Test]
    procedure LinkedReportLineChangedAmountBlocksRelease()
    var
        BankAccount: Record "Bank Account";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] A linked report line cannot be released after its amount is edited away from the feed amount.
        Initialize();

        // [GIVEN] A matched manual report line has a different amount, with mandatory card selection disabled.
        CreateLinkedCardExpenseReport(ExpenseReportHeader, ExpenseReportLine, CorpCardTrans, BankAccount);
        ExpenseReportLine.Validate(Amount, CorpCardTrans.Amount + 10);
        ExpenseReportLine.Modify(true);
        Commit();

        // [WHEN] The report is released.
        asserterror ExpenseReportHeader.PerformManualRelease();

        // [THEN] Release reports the feed amount mismatch.
        Assert.ExpectedError(ExpenseReportLine.FieldCaption(Amount));
    end;

    [Test]
    procedure LinkedReportLineChangedCurrencyBlocksRelease()
    var
        BankAccount: Record "Bank Account";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] A linked report line cannot be released after its expense currency is edited away from the feed currency.
        Initialize();

        // [GIVEN] A matched manual report line has a different expense currency, with mandatory card selection disabled.
        CreateLinkedCardExpenseReport(ExpenseReportHeader, ExpenseReportLine, CorpCardTrans, BankAccount);
        ExpenseReportLine.Validate("Expense Currency Code", 'EUR');
        ExpenseReportLine.Modify(true);
        Commit();

        // [WHEN] The report is released.
        asserterror ExpenseReportHeader.PerformManualRelease();

        // [THEN] Release reports the feed currency mismatch.
        Assert.ExpectedError(ExpenseReportLine.FieldCaption("Expense Currency Code"));
    end;

    [Test]
    procedure LinkedReportLineChangedAmountBlocksPosting()
    var
        BankAccount: Record "Bank Account";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO] Posting rechecks linked amounts even when the report has already been released.
        Initialize();

        // [GIVEN] A previously released linked line has a stored amount that no longer matches the feed.
        CreateLinkedCardExpenseReport(ExpenseReportHeader, ExpenseReportLine, CorpCardTrans, BankAccount);
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportLine.Amount := CorpCardTrans.Amount + 10;
        ExpenseReportLine.Modify(false);
        Commit();

        // [WHEN] The released report is posted without rerunning release.
        asserterror ExpenseReportPost.RunWithCheck(ExpenseReportHeader);

        // [THEN] Posting reports the mismatch before creating a provider bank entry.
        Assert.ExpectedError(ExpenseReportLine.FieldCaption(Amount));
        BankAccountLedgerEntry.SetRange("EA Corp Card Trans Entry No.", CorpCardTrans."Entry No.");
        Assert.IsTrue(BankAccountLedgerEntry.IsEmpty(), 'A mismatched report amount must not credit the provider bank account.');
    end;

    [Test]
    procedure LinkedReportLineChangedCurrencyBlocksPosting()
    var
        BankAccount: Record "Bank Account";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO] Posting rechecks linked expense currencies even when the report has already been released.
        Initialize();

        // [GIVEN] A previously released linked line has a stored expense currency that no longer matches the feed.
        CreateLinkedCardExpenseReport(ExpenseReportHeader, ExpenseReportLine, CorpCardTrans, BankAccount);
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportLine."Expense Currency Code" := 'EUR';
        ExpenseReportLine.Modify(false);
        Commit();

        // [WHEN] The released report is posted without rerunning release.
        asserterror ExpenseReportPost.RunWithCheck(ExpenseReportHeader);

        // [THEN] Posting reports the mismatch before creating a provider bank entry.
        Assert.ExpectedError(ExpenseReportLine.FieldCaption("Expense Currency Code"));
        BankAccountLedgerEntry.SetRange("EA Corp Card Trans Entry No.", CorpCardTrans."Entry No.");
        Assert.IsTrue(BankAccountLedgerEntry.IsEmpty(), 'A mismatched report currency must not credit the provider bank account.');
    end;

    [Test]
    procedure SelectedCardBlockedAfterLinkingBlocksReportRelease()
    var
        BankAccount: Record "Bank Account";
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] Blocking an already-selected card prevents report release even when card selection is optional.
        Initialize();

        // [GIVEN] A linked report line references a card that is subsequently blocked.
        CreateLinkedCardExpenseReport(ExpenseReportHeader, ExpenseReportLine, CorpCardTrans, BankAccount);
        CorpCard.Get(ExpenseReportLine."Corporate Card Id");
        CorpCard.Validate(Blocked, true);
        CorpCard.Modify(true);
        Commit();

        // [WHEN] The report is released.
        asserterror ExpenseReportHeader.PerformManualRelease();

        // [THEN] Release rejects the blocked card.
        Assert.ExpectedError(CorpCard.FieldCaption(Blocked));
    end;

    [Test]
    procedure SelectedCardBlockedAfterReleaseBlocksReportPosting()
    var
        BankAccount: Record "Bank Account";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO] Blocking an already-selected card prevents posting of a previously released report.
        Initialize();

        // [GIVEN] A linked report was released before its selected card was blocked.
        CreateLinkedCardExpenseReport(ExpenseReportHeader, ExpenseReportLine, CorpCardTrans, BankAccount);
        ExpenseReportHeader.PerformManualRelease();
        CorpCard.Get(ExpenseReportLine."Corporate Card Id");
        CorpCard.Validate(Blocked, true);
        CorpCard.Modify(true);
        Commit();

        // [WHEN] The released report is posted without rerunning release.
        asserterror ExpenseReportPost.RunWithCheck(ExpenseReportHeader);

        // [THEN] Posting rejects the blocked card before creating a provider bank entry.
        Assert.ExpectedError(CorpCard.FieldCaption(Blocked));
        BankAccountLedgerEntry.SetRange("EA Corp Card Trans Entry No.", CorpCardTrans."Entry No.");
        Assert.IsTrue(BankAccountLedgerEntry.IsEmpty(), 'A blocked card must prevent posting the report liability.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CardExpenseReleasesAndPostsWithoutRegisteredCards()
    var
        CorpCard: Record "EA Corp Card";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO] CARD expenses can be released and posted without registering corporate cards when selection is optional.
        Initialize();

        // [GIVEN] A card-free company has released a CARD expense and added it to an open report.
        CreateCardlessExpenseReport(ExpenseReportHeader, ExpenseReportLine, false);

        // [WHEN] The report is released and posted.
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] The expense is posted without assigning or registering a corporate card.
        PostedExpenseReportLine.Get(ExpenseReportHeader."Last Posting No.", ExpenseReportLine."Line No.");
        PostedExpenseReportLine.TestField("Expense No.", ExpenseReportLine."Expense No.");
        PostedExpenseReportLine.TestField("Corporate Card Id", '');
        PostedExpenseReportLine.TestField("Credit Card Feed No.", 0);
        PostedExpenseReportLine.TestField("Reimbursement Type", PostedExpenseReportLine."Reimbursement Type"::"Credit Card");
        Assert.IsTrue(CorpCard.IsEmpty(), 'Posting a legacy CARD expense must not register corporate cards.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure StandaloneCardReportReleasesAndPostsWithoutRegisteredCards()
    var
        CorpCard: Record "EA Corp Card";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO] Standalone CARD report lines remain postable without registered corporate cards when selection is optional.
        Initialize();

        // [GIVEN] A card-free company has an open report with a manual CARD line and no source expense.
        CreateCardlessExpenseReport(ExpenseReportHeader, ExpenseReportLine, true);

        // [WHEN] The report is released and posted.
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] The standalone line is posted without a corporate card or feed transaction.
        PostedExpenseReportLine.Get(ExpenseReportHeader."Last Posting No.", ExpenseReportLine."Line No.");
        PostedExpenseReportLine.TestField("Expense No.", '');
        PostedExpenseReportLine.TestField("Corporate Card Id", '');
        PostedExpenseReportLine.TestField("Credit Card Feed No.", 0);
        PostedExpenseReportLine.TestField("Reimbursement Type", PostedExpenseReportLine."Reimbursement Type"::"Credit Card");
        Assert.IsTrue(CorpCard.IsEmpty(), 'Posting a manual CARD report line must not register corporate cards.');
    end;

    [Test]
    procedure RequiredCardBlocksCardlessReportRelease()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] Opting into mandatory selection also applies to an existing open CARD report.
        Initialize();

        // [GIVEN] An open cardless report exists before mandatory selection is enabled.
        CreateCardlessExpenseReport(ExpenseReportHeader, ExpenseReportLine, true);
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Require Corporate Card", true);
        ExpenseAgentSetup.Modify(true);
        Commit();

        // [WHEN] The existing report is released.
        asserterror ExpenseReportHeader.PerformManualRelease();

        // [THEN] Release requires a corporate card on the manual line.
        Assert.ExpectedError(ExpenseReportLine.FieldCaption("Corporate Card Id"));
    end;

    [Test]
    procedure RequiredCardBlocksPreviouslyReleasedCardlessReportPosting()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO] Opting into mandatory selection also validates previously released CARD reports at posting.
        Initialize();

        // [GIVEN] A cardless report was released before mandatory selection was enabled.
        CreateCardlessExpenseReport(ExpenseReportHeader, ExpenseReportLine, true);
        ExpenseReportHeader.PerformManualRelease();
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Require Corporate Card", true);
        ExpenseAgentSetup.Modify(true);
        Commit();

        // [WHEN] The previously released report is posted without rerunning release.
        asserterror ExpenseReportPost.RunWithCheck(ExpenseReportHeader);

        // [THEN] Posting requires a corporate card on the manual line.
        Assert.ExpectedError(ExpenseReportLine.FieldCaption("Corporate Card Id"));
    end;

    [Test]
    procedure CancelingPostedExpenseInvalidatesClosedStatement()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CorpCardPostMgt: Codeunit "EA Corp Card Post Mgt";
        OriginalClosedAt: DateTime;
    begin
        Initialize();
        OriginalClosedAt := CurrentDateTime();
        CorpCardStatement.Init();
        CorpCardStatement."Provider Code" := 'TEST';
        CorpCardStatement."Statement No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardStatement."Statement No."));
        CorpCardStatement."Statement Date" := WorkDate();
        CorpCardStatement."Statement Total" := 2000;
        CorpCardStatement."Reconciled Transactions" := 1;
        CorpCardStatement."Reconciled Amount" := 2000;
        CorpCardStatement."Closed At" := OriginalClosedAt;
        CorpCardStatement."Closed By User ID" := CopyStr(UserId(), 1, MaxStrLen(CorpCardStatement."Closed By User ID"));
        CorpCardStatement.Status := CorpCardStatement.Status::Closed;
        CorpCardStatement.Insert(true);

        CorpCardTrans.Init();
        CorpCardTrans."Statement Entry No." := CorpCardStatement."Statement Entry No.";
        CorpCardTrans."Provider Code" := CorpCardStatement."Provider Code";
        CorpCardTrans."Card Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Card Id"));
        CorpCardTrans."Provider Trans Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));
        CorpCardTrans."Trans Date" := WorkDate();
        CorpCardTrans.Amount := 2000;
        CorpCardTrans."Expense No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Expense No."));
        CorpCardTrans."Posted Expense Report No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Posted Expense Report No."));
        CorpCardTrans.Status := CorpCardTrans.Status::Posted;
        CorpCardTrans.Insert(true);

        PostedExpenseReportHeader."No." := CorpCardTrans."Posted Expense Report No.";
        PostedExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";

        CorpCardPostMgt.HandleCanceledPostedExpense(PostedExpenseReportLine, PostedExpenseReportHeader);

        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        Assert.AreEqual(CorpCardStatement.Status::ReconciliationRequired, CorpCardStatement.Status, 'Canceling the posted expense must invalidate statement closure.');
        Assert.AreEqual(OriginalClosedAt, CorpCardStatement."Previous Closed At", 'The previous statement closure must be preserved.');
        Assert.IsTrue(StrPos(CorpCardStatement."Recon. Invalidation Reason", PostedExpenseReportHeader."No.") > 0, 'The cancellation reason must identify the posted expense report.');
        Assert.AreEqual(CorpCardTrans.Status::Matched, CorpCardTrans.Status, 'The corporate card transaction must return to matched status.');
        Assert.AreEqual('', CorpCardTrans."Posted Expense Report No.", 'The canceled posted report reference must be cleared.');
    end;

    [Test]
    procedure PostedReportCardQueryIncludesOnlyActiveReportLinks()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: array[3] of Record "EA Corp Card Trans";
        CorpCardPostMgt: Codeunit "EA Corp Card Post Mgt";
        PostedReportCardTrans: Query "EA Posted Report Card Trans";
        ExpectedStatementNos: Dictionary of [Integer, Integer];
        ActualFeedNos: List of [Integer];
        PostedReportNo: Code[20];
        OtherPostedReportNo: Code[20];
        TransactionIndex: Integer;
    begin
        // [SCENARIO] Discovery batches active feed links, including duplicate links and transactions without a statement.
        Initialize();

        // [GIVEN] Three transactions on two statements, with the first transaction linked twice.
        PostedReportNo := CopyStr(Format(CreateGuid()), 1, MaxStrLen(PostedReportNo));
        OtherPostedReportNo := CopyStr(Format(CreateGuid()), 1, MaxStrLen(OtherPostedReportNo));
        for TransactionIndex := 1 to ArrayLen(CorpCardTrans) do begin
            if TransactionIndex <= 2 then
                CorpCardTestLib.CreateStatement(
                    CorpCardStatement, 'TEST', CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardStatement."Statement No.")), 100, CorpCardStatement.Status::Validated);
            CorpCardTestLib.CreatePostedTransaction(CorpCardTrans[TransactionIndex], CorpCardStatement, 100);
            if TransactionIndex = 3 then begin
                CorpCardTrans[TransactionIndex]."Statement Entry No." := 0;
                CorpCardTrans[TransactionIndex].Modify();
            end;
            ExpectedStatementNos.Add(CorpCardTrans[TransactionIndex]."Entry No.", CorpCardTrans[TransactionIndex]."Statement Entry No.");
            CreatePostedReportCardLink(PostedReportNo, TransactionIndex * 10000, CorpCardTrans[TransactionIndex]."Entry No.", false);
        end;
        CreatePostedReportCardLink(PostedReportNo, 40000, CorpCardTrans[1]."Entry No.", false);

        // [GIVEN] Canceled and other-report links point to missing transactions, and a manual line has no feed link.
        CreatePostedReportCardLink(PostedReportNo, 50000, -1, true);
        CreatePostedReportCardLink(OtherPostedReportNo, 10000, -1, false);
        CreatePostedReportCardLink(PostedReportNo, 60000, 0, false);

        // [WHEN] The active report links are read in one query.
        PostedReportCardTrans.SetRange(PostedReportNo, PostedReportNo);
        PostedReportCardTrans.Open();
        while PostedReportCardTrans.Read() do begin
            Assert.AreEqual(PostedReportCardTrans.CreditCardFeedNo, PostedReportCardTrans.TransactionEntryNo, 'Each feed link must resolve to its transaction.');
            Assert.IsTrue(ExpectedStatementNos.ContainsKey(PostedReportCardTrans.TransactionEntryNo), 'Only linked report transactions must be returned.');
            Assert.AreEqual(
                ExpectedStatementNos.Get(PostedReportCardTrans.TransactionEntryNo), PostedReportCardTrans.StatementEntryNo,
                'Each transaction must retain its statement for the subsequent ordered lock pass.');
            ActualFeedNos.Add(PostedReportCardTrans.CreditCardFeedNo);
        end;
        PostedReportCardTrans.Close();

        // [THEN] All four active links are present, including the duplicate.
        Assert.AreEqual(4, ActualFeedNos.Count(), 'Canceled, manual, and other-report lines must be excluded.');
        for TransactionIndex := 1 to ArrayLen(CorpCardTrans) do
            Assert.IsTrue(ActualFeedNos.Remove(CorpCardTrans[TransactionIndex]."Entry No."), 'Each linked transaction must be included.');
        Assert.AreEqual(CorpCardTrans[1]."Entry No.", ActualFeedNos.Get(1), 'The duplicate link must be preserved.');

        // [THEN] Lock preparation tolerates duplicate links and transactions without statements.
        CorpCardPostMgt.LockPostedReportTransactions(PostedReportNo);
    end;

    [Test]
    procedure LockPostedReportTransactionsRejectsMissingFeedTransaction()
    var
        CorpCardPostMgt: Codeunit "EA Corp Card Post Mgt";
        PostedReportNo: Code[20];
    begin
        // [SCENARIO] A left join must not silently discard a broken active feed link.
        Initialize();

        // [GIVEN] An active report line refers to a missing transaction.
        PostedReportNo := CopyStr(Format(CreateGuid()), 1, MaxStrLen(PostedReportNo));
        CreatePostedReportCardLink(PostedReportNo, 10000, -1, false);

        // [WHEN] Cancellation prepares the report's transaction locks.
        asserterror CorpCardPostMgt.LockPostedReportTransactions(PostedReportNo);

        // [THEN] Cancellation fails explicitly instead of proceeding without the transaction.
        Assert.ExpectedError('Corporate card links changed while preparing cancellation.');
    end;

    local procedure CreateLinkedCardExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; var ExpenseReportLine: Record "Expense Report Line"; var CorpCardTrans: Record "EA Corp Card Trans"; var BankAccount: Record "Bank Account")
    var
        CorpCard: Record "EA Corp Card";
        CorpCardProvider: Record "EA Corp Card Provider";
        Employee: Record Employee;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseUser: Record "Expense User";
        GLAccount: Record "G/L Account";
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Require Corporate Card", false);
        ExpenseAgentSetup.Modify(true);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateBankAccount(BankAccount, GLAccount);
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Credit Card", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", LibraryERM.CreateGLAccountNo());
        ExpensePostingGroup.Modify(true);

        CorpCardProvider.Get('TEST');
        CorpCardProvider.Validate("Corp Card Bank Account No.", BankAccount."No.");
        CorpCardProvider.Modify(true);
        CorpCard.Init();
        CorpCard."Card Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCard."Card Id"));
        CorpCard."Provider Code" := CorpCardProvider.Code;
        CorpCard."Expense User No." := ExpenseUser."No.";
        CorpCard.Insert(true);
        CorpCardTrans.Init();
        CorpCardTrans."Entry No." := 0;
        CorpCardTrans."Provider Code" := CorpCardProvider.Code;
        CorpCardTrans."Card Id" := CorpCard."Card Id";
        CorpCardTrans."Provider Trans Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));
        CorpCardTrans."Trans Date" := WorkDate();
        CorpCardTrans.Amount := 2000;
        CorpCardTrans.Status := CorpCardTrans.Status::Matched;
        CorpCardTrans.Insert(true);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code,
            ExpensePaymentMethod.Code, true, '', CorpCardTrans.Amount);
        ExpenseReportLine.Validate("Corporate Card Id", CorpCard."Card Id");
        ExpenseReportLine.Modify(true);
        CorpCardExpenseMatch.LinkExpense(CorpCardTrans, ExpenseReportLine.RecordId());
        CorpCardTrans.Modify(true);
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
    end;

    local procedure CreateCardlessExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; var ExpenseReportLine: Record "Expense Report Line"; StandaloneReportLine: Boolean)
    var
        CorpCard: Record "EA Corp Card";
        Employee: Record Employee;
        EmployeePostingGroup: Record "Employee Posting Group";
        Expense: Record Expense;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseUser: Record "Expense User";
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        CorpCard.DeleteAll();
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Require Corporate Card", false);
        ExpenseAgentSetup.Validate("Allow VAT Reclaim", false);
        ExpenseAgentSetup.Validate("Use Rules", false);
        ExpenseAgentSetup.Modify(true);
        LibraryExpense.UpdateEnableAgentInAgentSetup(false);
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
        EmployeePostingGroup.Get(Employee."Employee Posting Group");
        EmployeePostingGroup.Validate("Expense Payable Card Paid Acc.", LibraryERM.CreateGLAccountNo());
        EmployeePostingGroup.Modify(true);
        ExpensePaymentMethod.Get('CARD');
        ExpensePaymentMethod.TestField("Reimbursement Type", ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Credit Card", ExpenseCategory."Expense Detail Required"::" ", ExpensePaymentMethod.Code);
        LibraryExpense.CreateExpensePostingGroup(ExpensePostingGroup);
        ExpenseCategory.Validate("Posting Group", ExpensePostingGroup.Code);
        ExpenseCategory.Modify(true);

        if StandaloneReportLine then begin
            LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
            ExpenseReportLine.Init();
            ExpenseReportLine.Validate("Document No.", ExpenseReportHeader."No.");
            ExpenseReportLine."Line No." := 10000;
            ExpenseReportLine.Validate(Description, 'Manual CARD expense');
            ExpenseReportLine.Validate("Expense Ext. Doc. No.", CopyStr(Format(CreateGuid()), 1, MaxStrLen(ExpenseReportLine."Expense Ext. Doc. No.")));
            ExpenseReportLine.Validate("Merchant Name", 'Test merchant');
            ExpenseReportLine.Validate("Expense User No.", ExpenseUser."No.");
            ExpenseReportLine.Validate("Expense Category", ExpenseCategory.Code);
            ExpenseReportLine.Validate("Payment Method Code", ExpensePaymentMethod.Code);
            ExpenseReportLine.Validate("Expense Date", WorkDate());
            ExpenseReportLine.Validate(Refundable, true);
            ExpenseReportLine.Validate(Amount, 20);
            ExpenseReportLine.Insert(true);
        end else begin
            Expense.Init();
            Expense.Validate(Description, 'Manual CARD expense');
            Expense.Validate("Expense Ext. Doc. No.", CopyStr(Format(CreateGuid()), 1, MaxStrLen(Expense."Expense Ext. Doc. No.")));
            Expense.Validate("Merchant Name", 'Test merchant');
            Expense.Validate("Expense User No.", ExpenseUser."No.");
            Expense.Validate("Expense Category", ExpenseCategory.Code);
            Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
            Expense.Validate("Expense Date", WorkDate());
            Expense.Insert(true);
            Expense.Validate(Amount, 20);
            Expense.Validate(Refundable, true);
            Expense.Modify(true);
            Expense.PerformManualRelease();
            LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
            ExpenseReportLine := CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);
        end;

        Assert.IsTrue(CorpCard.IsEmpty(), 'The compatibility fixture must not register corporate cards.');
        ExpenseReportLine.TestField("Corporate Card Id", '');
        ExpenseReportLine.TestField("Credit Card Feed No.", 0);
    end;

    local procedure CreatePostedReportCardLink(PostedReportNo: Code[20]; LineNo: Integer; FeedEntryNo: Integer; IsCanceled: Boolean)
    var
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        PostedExpenseReportLine."Document No." := PostedReportNo;
        PostedExpenseReportLine."Line No." := LineNo;
        PostedExpenseReportLine."Credit Card Feed No." := FeedEntryNo;
        PostedExpenseReportLine."Is Canceled" := IsCanceled;
        PostedExpenseReportLine.Insert();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        CorpCardTestLib.InitializeCorpCardData();
        CorpCardTestLib.EnsureCorpCardProvider('TEST');
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        IsInitialized := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
