// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.ExpenseAgent;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;

codeunit 148363 EACorpCardLiabilityTests
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
        BankAccountNo: Code[20];
        EmployeePostingGroupCode: Code[20];
        ExpenseAccountNo: Code[20];
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TransferUsesOriginalAccountWithoutRepostingExpenseOrVAT()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        LiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
        EmployeeEntryCount: Integer;
        ExpenseEntryCount: Integer;
        VATEntryCount: Integer;
        ExpenseGLAmount: Decimal;
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Liability]
        // [SCENARIO] Transfer uses the original payable account and dimensions without reposting expense or VAT.
        Initialize();

        // [GIVEN] A posted manual expense whose payable account setup has since changed and whose original account has VAT setup.
        PostManualExpenseAndLinkFeed(CorpCardTrans, PostedExpenseReportLine, '', '');
        EmployeePostingGroup.Get(EmployeePostingGroupCode);
        EmployeePostingGroup.Validate("Expense Payable Card Paid Acc.", LibraryERM.CreateGLAccountNo());
        EmployeePostingGroup.Modify(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Get(PostedExpenseReportLine."Card Payable Account No.");
        GLAccount."Gen. Posting Type" := GLAccount."Gen. Posting Type"::Purchase;
        GLAccount."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        GLAccount."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GLAccount.Modify(true);
        EmployeeEntryCount := EmployeeLedgerEntry.Count();
        ExpenseEntryCount := ExpenseLedgerEntry.Count();
        VATEntryCount := VATEntry.Count();
        GLEntry.SetRange("G/L Account No.", ExpenseAccountNo);
        GLEntry.CalcSums(Amount);
        ExpenseGLAmount := GLEntry.Amount;

        // [WHEN] The original liability is transferred to the provider bank.
        LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate());

        // [THEN] Only the original payable and bank accounts are posted, preserving dimensions and existing ledger totals.
        BankAccountLedgerEntry.Get(CorpCardTrans."Liability Bank Entry No.");
        Assert.AreEqual(BankAccountNo, BankAccountLedgerEntry."Bank Account No.", 'Transfer must credit the provider bank.');
        Assert.AreEqual(-2000, BankAccountLedgerEntry.Amount, 'The purchase must credit the bank.');
        Assert.AreEqual(BankAccountLedgerEntry."Transaction No.", CorpCardTrans."Liability Transaction No.", 'Persist the exact posted transaction.');
        Assert.AreEqual(PostedExpenseReportLine."Dimension Set ID", BankAccountLedgerEntry."Dimension Set ID", 'Preserve the expense dimensions.');
        GLEntry.Reset();
        GLEntry.SetRange("Transaction No.", CorpCardTrans."Liability Transaction No.");
        Assert.AreEqual(2, GLEntry.Count(), 'Transfer must post only the two liability accounts.');
        GLEntry.SetRange("G/L Account No.", PostedExpenseReportLine."Card Payable Account No.");
        GLEntry.FindFirst();
        Assert.AreEqual(2000, GLEntry.Amount, 'Clear the original payable, not the current employee posting setup.');
        Assert.AreEqual(PostedExpenseReportLine."Dimension Set ID", GLEntry."Dimension Set ID", 'Preserve dimensions on the original payable.');
        GLEntry.Reset();
        GLEntry.SetRange("G/L Account No.", ExpenseAccountNo);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(ExpenseGLAmount, GLEntry.Amount, 'Do not repost expense cost.');
        Assert.AreEqual(EmployeeEntryCount, EmployeeLedgerEntry.Count(), 'Do not create employee entries.');
        Assert.AreEqual(ExpenseEntryCount, ExpenseLedgerEntry.Count(), 'Do not create expense entries.');
        Assert.AreEqual(VATEntryCount, VATEntry.Count(), 'Do not create VAT entries.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DuplicateTransferIsRejectedWithoutNewEntries()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        LiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
        BankEntryCount: Integer;
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Liability]
        // [SCENARIO] A liability cannot be transferred twice.
        Initialize();

        // [GIVEN] A posted manual expense whose liability transfer is already committed.
        PostManualExpenseAndLinkFeed(CorpCardTrans, PostedExpenseReportLine, '', '');
        LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate());
        BankEntryCount := BankAccountLedgerEntry.Count();
        Commit();

        // [WHEN] The same liability is transferred again.
        asserterror LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate());

        // [THEN] The duplicate transfer is rejected without new bank entries.
        Assert.ExpectedError('already been transferred');
        Assert.AreEqual(BankEntryCount, BankAccountLedgerEntry.Count(), 'A repeated transfer must not post anything.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ExistingActiveBankEntryPreventsTransferWithoutAuditReferences()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        GenJournalLine: Record "Gen. Journal Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        LiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
        BankEntryCount: Integer;
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Liability]
        // [SCENARIO] An existing bank posting prevents duplicate liability transfer even without transfer audit references.
        Initialize();

        // [GIVEN] A linked manual expense with a committed active bank entry posted through another path.
        PostManualExpenseAndLinkFeed(CorpCardTrans, PostedExpenseReportLine, '', '');
        GenJournalLine.Init();
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Document No.", PostedExpenseReportLine."Document No.");
        GenJournalLine.Validate("Source Code", LibraryERM.FindGeneralJournalSourceCode());
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.Validate("Account No.", BankAccountNo);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate(Amount, -2000);
        GenJournalLine."EA Corp Card Trans Entry No." := CorpCardTrans."Entry No.";
        GenJnlPostLine.SetIgnoreJournalTemplNameMandatoryCheck();
        GenJnlPostLine.RunWithCheck(GenJournalLine);
        BankEntryCount := BankAccountLedgerEntry.Count();
        Commit();

        // [WHEN] A liability transfer is requested for the same feed transaction.
        asserterror LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate());

        // [THEN] The active bank entry is detected and no duplicate is posted.
        Assert.ExpectedError('already has an active bank account ledger entry');
        Assert.AreEqual(BankEntryCount, BankAccountLedgerEntry.Count(), 'Do not duplicate a liability posted by another path.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReversalUsesPersistedTransactionAndInvalidatesClosedStatement()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCard: Record "EA Corp Card";
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        GLEntry: Record "G/L Entry";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        VATEntry: Record "VAT Entry";
        LiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
        BankEntryCount: Integer;
        ExpenseEntryCount: Integer;
        OriginalBankEntryNo: Integer;
        OriginalTransactionNo: Integer;
        VATEntryCount: Integer;
        ClosedAt: DateTime;
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Liability]
        // [SCENARIO] Reversal uses persisted posting references despite changed card setup and invalidates statement closure.
        Initialize();

        // [GIVEN] A transferred liability on a closed statement, with the card blocked and the provider bank cleared.
        PostManualExpenseAndLinkFeed(CorpCardTrans, PostedExpenseReportLine, '', '');
        LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate());
        OriginalBankEntryNo := CorpCardTrans."Liability Bank Entry No.";
        OriginalTransactionNo := CorpCardTrans."Liability Transaction No.";
        ExpenseEntryCount := ExpenseLedgerEntry.Count();
        VATEntryCount := VATEntry.Count();
        CorpCard.Get(CorpCardTrans."Card Id");
        CorpCard.Blocked := true;
        CorpCard.Modify(true);
        CorpCardProvider.Get(CorpCardTrans."Provider Code");
        CorpCardProvider."Corp Card Bank Account No." := '';
        CorpCardProvider.Modify(true);
        CorpCardStatement.Get(CorpCardTrans."Statement Entry No.");
        ClosedAt := CurrentDateTime();
        CorpCardStatement.Status := CorpCardStatement.Status::Closed;
        CorpCardStatement."Closed At" := ClosedAt;
        CorpCardStatement."Reconciled Transactions" := 1;
        CorpCardStatement."Reconciled Amount" := 2000;
        CorpCardStatement.Modify();

        // [WHEN] The transferred liability is reversed.
        LiabilityMgt.ReverseLiability(CorpCardTrans);

        // [THEN] The original posting is reversed, reconciliation is invalidated, and expense, VAT, and audit history are preserved.
        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        Assert.AreEqual(CorpCardStatement.Status::ReconciliationRequired, CorpCardStatement.Status, 'Reverse must invalidate closure before modifying the transaction.');
        Assert.AreEqual(ClosedAt, CorpCardStatement."Previous Closed At", 'Preserve prior reconciliation history.');
        Assert.AreEqual(OriginalBankEntryNo, CorpCardTrans."Liability Bank Entry No.", 'Keep the original bank reference.');
        Assert.AreEqual(OriginalTransactionNo, CorpCardTrans."Liability Transaction No.", 'Keep the original transaction reference.');
        BankAccountLedgerEntry.Get(OriginalBankEntryNo);
        Assert.IsTrue(BankAccountLedgerEntry.Reversed, 'The transfer bank entry must be reversed.');
        BankAccountLedgerEntry.Get(BankAccountLedgerEntry."Reversed by Entry No.");
        Assert.AreEqual(2000, BankAccountLedgerEntry.Amount, 'The reversal must debit the original bank.');
        Assert.AreEqual(BankAccountLedgerEntry."Transaction No.", CorpCardTrans."Liability Reversal Trans. No.", 'Persist the actual reversal transaction.');
        GLEntry.SetRange("G/L Account No.", PostedExpenseReportLine."Card Payable Account No.");
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(-2000, GLEntry.Amount, 'Reversal must restore the original payable liability.');
        Assert.AreEqual(ExpenseEntryCount, ExpenseLedgerEntry.Count(), 'Transfer reversal must not reverse the original expense.');
        Assert.AreEqual(VATEntryCount, VATEntry.Count(), 'Transfer reversal must not reverse original VAT.');
        BankEntryCount := BankAccountLedgerEntry.Count();

        // [WHEN] Reversal is requested again.
        LiabilityMgt.ReverseLiability(CorpCardTrans);

        // [THEN] The repeated reversal posts nothing.
        Assert.AreEqual(BankEntryCount, BankAccountLedgerEntry.Count(), 'Repeating reversal must be a validated no-op.');

        // [WHEN] A new transfer is requested after reversal.
        asserterror LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate());

        // [THEN] The transfer is rejected to preserve the original audit references.
        Assert.ExpectedError('original audit references must be preserved');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReverseWithoutTransferDoesNotPost()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        LiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
        BankEntryCount: Integer;
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Liability]
        // [SCENARIO] Reversing a liability that was never transferred posts nothing.
        Initialize();

        // [GIVEN] A linked manual expense without a liability transfer.
        PostManualExpenseAndLinkFeed(CorpCardTrans, PostedExpenseReportLine, '', '');
        BankEntryCount := BankAccountLedgerEntry.Count();

        // [WHEN] Liability reversal is requested.
        LiabilityMgt.ReverseLiability(CorpCardTrans);

        // [THEN] No bank entries are created.
        Assert.AreEqual(BankEntryCount, BankAccountLedgerEntry.Count(), 'A manual expense with no transfer has nothing to reverse.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CancellationReversesExpenseBeforeReversingTransferredLiability()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        GLEntry: Record "G/L Entry";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CancelPostedExpenseReport: Codeunit "Cancel Posted Expense Report";
        LiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
        OriginalExpenseTransactionNo: Integer;
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Liability]
        // [SCENARIO] Report cancellation reverses the original expense and its transferred liability without residual balances.
        Initialize();

        // [GIVEN] A posted manual expense with an unreversed original posting and a transferred bank liability.
        PostManualExpenseAndLinkFeed(CorpCardTrans, PostedExpenseReportLine, '', '');
        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportLine."Document No.");
        ExpenseLedgerEntry.SetRange("Document Line No.", PostedExpenseReportLine."Line No.");
        ExpenseLedgerEntry.SetRange(Reversed, false);
        ExpenseLedgerEntry.FindFirst();
        OriginalExpenseTransactionNo := ExpenseLedgerEntry."Transaction No.";
        LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate());
        PostedExpenseReportHeader.Get(PostedExpenseReportLine."Document No.");

        // [WHEN] The posted expense report is canceled.
        CancelPostedExpenseReport.Run(PostedExpenseReportHeader);

        // [THEN] The report is canceled, both postings are reversed, and no active bank liability or original payable remains.
        PostedExpenseReportHeader.Get(PostedExpenseReportHeader."No.");
        Assert.IsTrue(PostedExpenseReportHeader.Canceled, 'Cancellation must succeed when original expense reversal precedes liability reversal.');
        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        Assert.AreNotEqual(0, CorpCardTrans."Liability Reversal Trans. No.", 'Cancellation must persist the liability reversal transaction.');
        Assert.AreEqual('', CorpCardTrans."Posted Expense Report No.", 'Cancellation must clear the posting link only after reversal.');
        BankAccountLedgerEntry.Get(CorpCardTrans."Liability Bank Entry No.");
        Assert.IsTrue(BankAccountLedgerEntry.Reversed, 'The transferred bank liability must be reversed.');
        BankAccountLedgerEntry.SetRange("EA Corp Card Trans Entry No.", CorpCardTrans."Entry No.");
        BankAccountLedgerEntry.SetRange(Reversed, false);
        Assert.IsTrue(BankAccountLedgerEntry.IsEmpty(), 'Cancellation must leave no active bank liability for the feed.');
        GLEntry.SetRange("Transaction No.", OriginalExpenseTransactionNo);
        GLEntry.SetRange(Reversed, false);
        Assert.IsTrue(GLEntry.IsEmpty(), 'The real original expense transaction must already have been reversed.');
        GLEntry.Reset();
        GLEntry.SetRange("G/L Account No.", PostedExpenseReportLine."Card Payable Account No.");
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(0, GLEntry.Amount, 'Both reversals must leave no original card payable.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ChangedSourceCardCannotTransferPostedLiability()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        LiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
        BankEntryCount: Integer;
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Liability]
        // [SCENARIO] Transfer is rejected when the source expense card no longer matches the posted feed.
        Initialize();

        // [GIVEN] A posted manual expense whose source corporate card was cleared after linking.
        PostManualExpenseAndLinkFeed(CorpCardTrans, PostedExpenseReportLine, '', '');
        Expense.Get(CorpCardTrans."Expense No.");
        Expense."Corporate Card Id" := '';
        Expense.Modify(false);
        BankEntryCount := BankAccountLedgerEntry.Count();

        // [WHEN] The liability transfer is requested.
        asserterror LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate());

        // [THEN] The card mismatch is reported without new bank entries.
        Assert.ExpectedError(Expense.FieldCaption("Corporate Card Id"));
        Assert.AreEqual(BankEntryCount, BankAccountLedgerEntry.Count(), 'The source and posted cards must both match the feed before transfer.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure UnmatchedAmountCannotTransferLiability()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        LiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
        BankEntryCount: Integer;
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Liability]
        // [SCENARIO] Transfer requires an exact match to the original liability amount.
        Initialize();

        // [GIVEN] A linked feed amount that differs from the original posted manual expense.
        PostManualExpenseAndLinkFeed(CorpCardTrans, PostedExpenseReportLine, '', '');
        CorpCardTrans.Amount := 1999;
        CorpCardTrans.Modify(true);
        BankEntryCount := BankAccountLedgerEntry.Count();

        // [WHEN] The liability transfer is requested.
        asserterror LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate());

        // [THEN] The amount mismatch is reported without new bank entries.
        Assert.ExpectedError('original liability amounts do not match');
        Assert.AreEqual(BankEntryCount, BankAccountLedgerEntry.Count(), 'Matching tolerance must not permit an arbitrary liability transfer.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReversedOriginalPostingCannotTransferLiability()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ReversalEntry: Record "Reversal Entry";
        LiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
        BankEntryCount: Integer;
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Liability]
        // [SCENARIO] An already reversed original expense posting cannot be used for liability transfer.
        Initialize();

        // [GIVEN] A linked manual expense whose original transaction has been reversed.
        PostManualExpenseAndLinkFeed(CorpCardTrans, PostedExpenseReportLine, '', '');
        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportLine."Document No.");
        ExpenseLedgerEntry.SetRange("Document Line No.", PostedExpenseReportLine."Line No.");
        ExpenseLedgerEntry.SetRange(Reversed, false);
        ExpenseLedgerEntry.FindFirst();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.SetHideWarningDialogs();
        ReversalEntry.ReverseTransaction(ExpenseLedgerEntry."Transaction No.");
        BankEntryCount := BankAccountLedgerEntry.Count();

        // [WHEN] The liability transfer is requested.
        asserterror LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate());

        // [THEN] The missing unreversed posting is reported without new bank entries.
        Assert.ExpectedError('original unreversed expense posting');
        Assert.AreEqual(BankEntryCount, BankAccountLedgerEntry.Count(), 'The real original G/L posting must still exist unreversed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ForeignBankRejectsDifferentOriginalLiabilityCurrency()
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        LiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Liability]
        // [SCENARIO] An LCY liability cannot be transferred to a foreign-currency bank.
        Initialize();

        // [GIVEN] A posted LCY manual expense linked to a provider bank denominated in USD.
        PostManualExpenseAndLinkFeed(CorpCardTrans, PostedExpenseReportLine, '', 'USD');

        // [WHEN] The liability transfer is requested.
        asserterror LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate());

        // [THEN] The unsupported cross-currency transfer is rejected.
        Assert.ExpectedError('Cross-currency liability transfers are not supported');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ForeignBankUsesOriginalLcyDespiteNewExchangeRate()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        LiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Liability]
        // [SCENARIO] A foreign-currency bank transfer preserves original LCY despite a later exchange-rate change.
        Initialize();

        // [GIVEN] A USD liability and USD provider bank with a different exchange rate on the next day.
        PostManualExpenseAndLinkFeed(CorpCardTrans, PostedExpenseReportLine, 'USD', 'USD');
        LibraryERM.CreateExchangeRate('USD', WorkDate() + 1, 2, 1);

        // [WHEN] The liability is transferred on the next day.
        LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate() + 1);

        // [THEN] The bank entry preserves both the original foreign-currency amount and historical LCY liability.
        BankAccountLedgerEntry.Get(CorpCardTrans."Liability Bank Entry No.");
        Assert.AreEqual(-2000, BankAccountLedgerEntry.Amount, 'Preserve the foreign-currency bank liability.');
        Assert.AreEqual(PostedExpenseReportLine."Card Liability Amount (LCY)", BankAccountLedgerEntry."Amount (LCY)", 'Clear original LCY, not the new exchange-rate amount.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure LocalBankAcceptsForeignLiabilityAtOriginalLcy()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        LiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Liability]
        // [SCENARIO] A foreign-currency liability can be transferred to an LCY bank using its historical LCY amount.
        Initialize();

        // [GIVEN] A posted USD manual expense linked to an LCY provider bank.
        PostManualExpenseAndLinkFeed(CorpCardTrans, PostedExpenseReportLine, 'USD', '');

        // [WHEN] The liability transfer is requested.
        LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate());

        // [THEN] The bank is posted in LCY for the historical liability amount.
        BankAccountLedgerEntry.Get(CorpCardTrans."Liability Bank Entry No.");
        Assert.AreEqual('', BankAccountLedgerEntry."Currency Code", 'An LCY bank must be posted in LCY.');
        Assert.AreEqual(PostedExpenseReportLine."Card Liability Amount (LCY)", BankAccountLedgerEntry.Amount, 'Clear the historical liability in LCY.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure LocalBankRejectsFeedLcyDifferentFromOriginalLiability()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        LiabilityMgt: Codeunit "EA Corp Card Liability Mgt";
        BankEntryCount: Integer;
    begin
        // [FEATURE] [Expense Agent] [Corporate Card] [Liability]
        // [SCENARIO] An LCY bank transfer rejects a feed LCY amount that differs from the original liability.
        Initialize();

        // [GIVEN] A USD liability and LCY provider bank with a mismatched feed LCY amount.
        PostManualExpenseAndLinkFeed(CorpCardTrans, PostedExpenseReportLine, 'USD', '');
        CorpCardTrans."Amount (LCY)" := -PostedExpenseReportLine."Card Liability Amount (LCY)" + 1;
        CorpCardTrans.Modify(true);
        BankEntryCount := BankAccountLedgerEntry.Count();

        // [WHEN] The liability transfer is requested.
        asserterror LiabilityMgt.TransferLiability(CorpCardTrans, WorkDate());

        // [THEN] The amount mismatch is reported without new bank entries.
        Assert.ExpectedError('original liability amounts do not match');
        Assert.AreEqual(BankEntryCount, BankAccountLedgerEntry.Count(), 'Do not post a bank amount that cannot both clear original LCY and satisfy statement reconciliation.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        CorpCardTestLib.InitializeCorpCardData();
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

    local procedure PostManualExpenseAndLinkFeed(var CorpCardTrans: Record "EA Corp Card Trans"; var PostedExpenseReportLine: Record "Posted Expense Report Line"; LiabilityCurrencyCode: Code[10]; BankCurrencyCode: Code[10])
    var
        BankAccount: Record "Bank Account";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCard: Record "EA Corp Card";
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardStatement: Record "EA Corp Card Statement";
        Employee: Record Employee;
        EmployeePostingGroup: Record "Employee Posting Group";
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        CorpCard.FindFirst();
        ExpenseUser.Get(CorpCard."Expense User No.");
        Employee.Get(ExpenseUser."Employee No.");
        EmployeePostingGroupCode := Employee."Employee Posting Group";
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(EmployeePostingGroupCode);
        EmployeePostingGroup.Get(EmployeePostingGroupCode);
        EmployeePostingGroup.Validate("Expense Payable Card Paid Acc.", LibraryERM.CreateGLAccountNo());
        EmployeePostingGroup.Modify(true);
        LibraryERM.CreateBankAccount(BankAccount);
        CorpCardTestLib.EnsureBankAccountPostingGroupAccount(BankAccount);
        BankAccount.Validate("Currency Code", BankCurrencyCode);
        BankAccount.Modify(true);
        BankAccountNo := BankAccount."No.";
        CorpCardProvider.Get(CorpCard."Provider Code");
        CorpCardProvider.Validate("Corp Card Bank Account No.", BankAccountNo);
        CorpCardProvider.Modify(true);

        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Credit Card", ExpenseCategory."Expense Detail Required"::" ", ExpensePaymentMethod.Code);
        ExpenseAccountNo := LibraryERM.CreateGLAccountNo();
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", ExpenseAccountNo);
        ExpensePostingGroup.Modify(true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, LiabilityCurrencyCode, 2000);
        Expense.Validate("Corporate Card Id", CorpCard."Card Id");
        Expense.Modify(true);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", LiabilityCurrencyCode, '');
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, ExpensePaymentMethod.Code, true, LiabilityCurrencyCode, 2000);
        ExpenseReportLine."Expense No." := Expense."No.";
        ExpenseReportLine.Validate("Corporate Card Id", CorpCard."Card Id");
        ExpenseReportLine.Validate("Dimension Set ID", CreateDimensionSet());
        ExpenseReportLine.Modify(true);
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        PostedExpenseReportLine.SetRange("Expense No.", Expense."No.");
        PostedExpenseReportLine.FindFirst();
        PostedExpenseReportLine.TestField("Card Payable Account No.", EmployeePostingGroup."Expense Payable Card Paid Acc.");
        PostedExpenseReportLine.TestField("Card Liability Amount", -2000);
        PostedExpenseReportLine.TestField("Card Liability Currency Code", LiabilityCurrencyCode);
        BankAccountLedgerEntry.SetRange("Document No.", PostedExpenseReportLine."Document No.");
        Assert.IsTrue(BankAccountLedgerEntry.IsEmpty(), 'The real manual expense posting must use the original GL, without a bank entry.');

        CorpCardTestLib.CreateStatement(CorpCardStatement, CorpCard."Provider Code", 'LIABILITY-TEST', 2000, CorpCardStatement.Status::Validated);
        CorpCardStatement."Currency Code" := LiabilityCurrencyCode;
        CorpCardStatement.Modify(true);
        CorpCardTestLib.CreatePostedTransaction(CorpCardTrans, CorpCardStatement, 2000);
        CorpCardTrans."Card Id" := CorpCard."Card Id";
        CorpCardTrans."Expense No." := Expense."No.";
        CorpCardTrans."Posted Expense Report No." := PostedExpenseReportLine."Document No.";
        CorpCardTrans."Amount (LCY)" := -PostedExpenseReportLine."Card Liability Amount (LCY)";
        CorpCardTrans.Modify(true);
        // Simulate the separately owned late-feed matching; never fabricate the original posting or its snapshots.
        Expense.Get(Expense."No.");
        Expense."Credit Card Feed No." := CorpCardTrans."Entry No.";
        Expense.Modify(false);
        PostedExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";
        PostedExpenseReportLine.Modify(false);
    end;

    local procedure CreateDimensionSet(): Integer
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionValue: Record "Dimension Value";
        DimensionManagement: Codeunit DimensionManagement;
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        TempDimensionSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        TempDimensionSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimensionSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimensionSetEntry.Insert();
        exit(DimensionManagement.GetDimensionSetID(TempDimensionSetEntry));
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
