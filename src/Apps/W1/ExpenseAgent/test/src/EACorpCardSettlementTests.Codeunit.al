// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 148360 EACorpCardSettlementTests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryERM: Codeunit "Library - ERM";
        CorpCardBankAccountNo: Code[20];
        PaymentBankAccountNo: Code[20];

    [Test]
    procedure ProviderAccountsAreSnapshottedOnSettlement()
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
    begin
        Initialize();

        CreateSettlement(CorpCardSettlement, 2000);

        Assert.AreEqual(CorpCardBankAccountNo, CorpCardSettlement."Corp Card Bank Account No.", 'The corporate card bank account must be copied from the provider.');
        Assert.AreEqual(PaymentBankAccountNo, CorpCardSettlement."Payment Bank Account No.", 'The payment bank account must be copied from the provider.');
    end;

    [Test]
    procedure ReadyToPostAcceptsValidatedStatementsWithoutPosting()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        GenJournalLine: Record "Gen. Journal Line";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
        BankLedgerCount: Integer;
        JournalLineCount: Integer;
    begin
        Initialize();
        BankLedgerCount := BankAccountLedgerEntry.Count();
        JournalLineCount := GenJournalLine.Count();
        CreateSettlement(CorpCardSettlement, 3000);
        CreateStatement(CorpCardStatement, 'STMT-A', 1000, CorpCardStatement.Status::Validated);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);
        CreateStatement(CorpCardStatement, 'STMT-B', 2000, CorpCardStatement.Status::Validated);
        AddStatement(CorpCardSettlement, CorpCardStatement, 20000);

        CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);

        CorpCardSettlement.Get(CorpCardSettlement."Settlement Entry No.");
        CorpCardSettlement.CalcFields("Statement Total", "Statement Count");
        Assert.AreEqual(CorpCardSettlement.Status::ReadyToPost, CorpCardSettlement.Status, 'A valid settlement must be ready to post.');
        Assert.AreEqual(3000, CorpCardSettlement."Statement Total", 'The statement total must be calculated from the settlement lines.');
        Assert.AreEqual(2, CorpCardSettlement."Statement Count", 'The statement count must be calculated from the settlement lines.');
        Assert.AreEqual(BankLedgerCount, BankAccountLedgerEntry.Count(), 'Preparing a settlement must not create bank account ledger entries.');
        Assert.AreEqual(JournalLineCount, GenJournalLine.Count(), 'Preparing a settlement must not create journal lines.');
    end;

    [Test]
    procedure ReadyToPostUsesTransactionLcyAmountForLcySettlement()
    var
        CorpCardBankAccount: Record "Bank Account";
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardSettlementLine: Record "EA Corp Card Settlement Line";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        PaymentBankAccount: Record "Bank Account";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
    begin
        Initialize();
        CreateBankAccount(CorpCardBankAccount, '');
        CreateBankAccount(PaymentBankAccount, '');
        CorpCardBankAccountNo := CorpCardBankAccount."No.";
        PaymentBankAccountNo := PaymentBankAccount."No.";
        ConfigureProviderAccounts();
        CreateStatement(CorpCardStatement, 'STMT-LCY', 2000, CorpCardStatement.Status::Validated);
        CreatePostedTransaction(CorpCardTrans, CorpCardStatement, 2000);
        CorpCardTrans."Amount (LCY)" := 1800;
        CorpCardTrans.Modify(true);

        CorpCardSettlement.Init();
        CorpCardSettlement.Validate("Provider Code", 'TEST');
        CorpCardSettlement."Settlement No." := 'SETTLEMENT-LCY';
        CorpCardSettlement."Settlement Date" := WorkDate();
        CorpCardSettlement."Currency Code" := '';
        CorpCardSettlement."Settlement Amount" := 1800;
        CorpCardSettlement.Insert(true);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);

        CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);

        CorpCardSettlementLine.Get(CorpCardSettlement."Settlement Entry No.", 10000);
        Assert.AreEqual('', CorpCardSettlementLine."Currency Code", 'The settlement statement line must use local currency.');
        Assert.AreEqual(1800, CorpCardSettlementLine."Statement Amount", 'The settlement statement line must use the transaction LCY amount.');
    end;

    [Test]
    procedure ProviderRejectsSameSettlementAccounts()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        Initialize();
        CorpCardProvider.Get('TEST');
        CorpCardProvider.Validate("Corp Card Bank Account No.", CorpCardBankAccountNo);

        asserterror CorpCardProvider.Validate("Payment Bank Account No.", CorpCardBankAccountNo);

        Assert.ExpectedError('must be different');
    end;

    [Test]
    procedure ReadyToPostRejectsUnvalidatedStatement()
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
    begin
        Initialize();
        CreateSettlement(CorpCardSettlement, 2000);
        CreateStatement(CorpCardStatement, 'STMT-OPEN', 2000, CorpCardStatement.Status::Validated);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);
        CorpCardStatement.Status := CorpCardStatement.Status::Imported;
        CorpCardStatement.Modify();

        asserterror CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);

        Assert.ExpectedError('must be validated');
    end;

    [Test]
    procedure SettlementRejectsDuplicateStatement()
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        Initialize();
        CreateSettlement(CorpCardSettlement, 2000);
        CreateStatement(CorpCardStatement, 'STMT-DUP', 2000, CorpCardStatement.Status::Validated);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);

        asserterror AddStatement(CorpCardSettlement, CorpCardStatement, 20000);

        Assert.ExpectedError('already included in settlement');
    end;

    [Test]
    procedure ReadyToPostRejectsAmountMismatch()
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
    begin
        Initialize();
        CreateSettlement(CorpCardSettlement, 2100);
        CreateStatement(CorpCardStatement, 'STMT-AMOUNT', 2000, CorpCardStatement.Status::Validated);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);

        asserterror CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);

        Assert.ExpectedError('does not equal the included statement total');
    end;

    [Test]
    procedure PostSettlementCreatesBalancedBankEntriesAndTraceability()
    var
        CorpCardBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        PaymentBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
    begin
        Initialize();
        CreateSettlement(CorpCardSettlement, 3000);
        CreateStatement(CorpCardStatement, 'STMT-POST', 3000, CorpCardStatement.Status::Validated);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);
        CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);

        CorpCardSettlementMgt.PostSettlement(CorpCardSettlement);

        CorpCardSettlement.Get(CorpCardSettlement."Settlement Entry No.");
        Assert.AreEqual(CorpCardSettlement.Status::Posted, CorpCardSettlement.Status, 'The settlement must be posted.');
        Assert.AreEqual(CorpCardSettlement."Settlement Date", CorpCardSettlement."Posted Date", 'The posted date must equal the settlement date.');
        Assert.AreNotEqual(0, CorpCardSettlement."G/L Register No.", 'Settlement posting must store the G/L register number.');
        CorpCardBankAccountLedgerEntry.Get(CorpCardSettlement."Corp Card Bank Acc. Entry No.");
        PaymentBankAccountLedgerEntry.Get(CorpCardSettlement."Payment Bank Acc. Entry No.");
        Assert.AreEqual(CorpCardBankAccountNo, CorpCardBankAccountLedgerEntry."Bank Account No.", 'The debit must be posted to the corporate card bank account.');
        Assert.AreEqual(3000, CorpCardBankAccountLedgerEntry.Amount, 'The corporate card bank account must be debited by the settlement amount.');
        Assert.AreEqual(PaymentBankAccountNo, PaymentBankAccountLedgerEntry."Bank Account No.", 'The credit must be posted to the payment bank account.');
        Assert.AreEqual(-3000, PaymentBankAccountLedgerEntry.Amount, 'The payment bank account must be credited by the settlement amount.');
        Assert.AreEqual(CorpCardBankAccountLedgerEntry."Transaction No.", PaymentBankAccountLedgerEntry."Transaction No.", 'Both bank entries must belong to the same transaction.');
        Assert.AreEqual(CorpCardSettlement."Settlement Entry No.", CorpCardBankAccountLedgerEntry."EA Corp Card Settle Entry No.", 'The corporate card bank entry must reference the settlement.');
        Assert.AreEqual(CorpCardSettlement."Settlement Entry No.", PaymentBankAccountLedgerEntry."EA Corp Card Settle Entry No.", 'The payment bank entry must reference the settlement.');
    end;

    [Test]
    procedure PostSettlementRejectsRepostingWithoutCreatingEntries()
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
    begin
        Initialize();
        CreateSettlement(CorpCardSettlement, 3000);
        CreateStatement(CorpCardStatement, 'STMT-REPOST', 3000, CorpCardStatement.Status::Validated);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);
        CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);
        CorpCardSettlementMgt.PostSettlement(CorpCardSettlement);
        asserterror CorpCardSettlementMgt.PostSettlement(CorpCardSettlement);

        Assert.ExpectedError('must be ready to post');
    end;

    [Test]
    procedure PostSettlementRevalidatesStatementsBeforePosting()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
        BankEntryCount: Integer;
    begin
        Initialize();
        CreateSettlement(CorpCardSettlement, 3000);
        CreateStatement(CorpCardStatement, 'STMT-CHANGED', 3000, CorpCardStatement.Status::Validated);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);
        CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);
        CorpCardStatement."Statement Total" := 3100;
        CorpCardStatement.Modify();
        BankEntryCount := BankAccountLedgerEntry.Count();

        asserterror CorpCardSettlementMgt.PostSettlement(CorpCardSettlement);

        Assert.ExpectedError('has changed since it was added');
        Assert.AreEqual(BankEntryCount, BankAccountLedgerEntry.Count(), 'Failed revalidation must not create bank account ledger entries.');
    end;

    [Test]
    procedure CloseStatementReconcilesTransactionsAndZeroesPeriodLiability()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        Initialize();
        CreateStatement(CorpCardStatement, 'STMT-CLOSE', 3000, CorpCardStatement.Status::Validated);
        CreatePostedTransaction(CorpCardTrans, CorpCardStatement, 3000);
        PostCorpCardExpenseBankEntry(CorpCardTrans, -3000);
        CreateSettlement(CorpCardSettlement, 3000);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);
        CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);
        CorpCardSettlementMgt.PostSettlement(CorpCardSettlement);

        CorpCardStatementMgt.CloseStatement(CorpCardStatement);

        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        Assert.AreEqual(CorpCardStatement.Status::Closed, CorpCardStatement.Status, 'A fully reconciled statement must be closed.');
        Assert.AreEqual(1, CorpCardStatement."Reconciled Transactions", 'The reconciled transaction count must be captured.');
        Assert.AreEqual(3000, CorpCardStatement."Reconciled Amount", 'The reconciled amount must be captured.');
        Assert.AreNotEqual(0DT, CorpCardStatement."Closed At", 'The statement closure date-time must be captured.');
        BankAccountLedgerEntry.SetRange("Bank Account No.", CorpCardBankAccountNo);
        BankAccountLedgerEntry.CalcSums(Amount);
        Assert.AreEqual(0, BankAccountLedgerEntry.Amount, 'The statement expense and settlement share must clear the corporate card liability for the period.');
    end;

    [Test]
    procedure CloseStatementRejectsMissingExpenseBankEntry()
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        Initialize();
        CreateStatement(CorpCardStatement, 'STMT-MISSING', 3000, CorpCardStatement.Status::Validated);
        CreatePostedTransaction(CorpCardTrans, CorpCardStatement, 3000);
        CreateSettlement(CorpCardSettlement, 3000);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);
        CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);
        CorpCardSettlementMgt.PostSettlement(CorpCardSettlement);

        asserterror CorpCardStatementMgt.CloseStatement(CorpCardStatement);

        Assert.ExpectedError('has no corporate card bank account ledger entry');
    end;

    [Test]
    procedure CloseStatementRejectsDuplicateExpenseBankEntries()
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        Initialize();
        CreateStatement(CorpCardStatement, 'STMT-DUP-ENTRY', 3000, CorpCardStatement.Status::Validated);
        CreatePostedTransaction(CorpCardTrans, CorpCardStatement, 3000);
        PostCorpCardExpenseBankEntry(CorpCardTrans, -1500);
        PostCorpCardExpenseBankEntry(CorpCardTrans, -1500);
        CreateSettlement(CorpCardSettlement, 3000);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);
        CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);
        CorpCardSettlementMgt.PostSettlement(CorpCardSettlement);

        asserterror CorpCardStatementMgt.CloseStatement(CorpCardStatement);

        Assert.ExpectedError('exactly one is required');
    end;

    [Test]
    procedure CloseStatementRejectsExpenseBankEntryAmountMismatch()
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        Initialize();
        CreateStatement(CorpCardStatement, 'STMT-WRONG-AMT', 3000, CorpCardStatement.Status::Validated);
        CreatePostedTransaction(CorpCardTrans, CorpCardStatement, 3000);
        PostCorpCardExpenseBankEntry(CorpCardTrans, -2900);
        CreateSettlement(CorpCardSettlement, 3000);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);
        CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);
        CorpCardSettlementMgt.PostSettlement(CorpCardSettlement);

        asserterror CorpCardStatementMgt.CloseStatement(CorpCardStatement);

        Assert.ExpectedError('bank account ledger amount');
    end;

    [Test]
    procedure ClosedStatementTransactionsAreImmutable()
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        Initialize();
        CreateStatement(CorpCardStatement, 'STMT-LOCKED', 3000, CorpCardStatement.Status::Validated);
        CreatePostedTransaction(CorpCardTrans, CorpCardStatement, 3000);
        PostCorpCardExpenseBankEntry(CorpCardTrans, -3000);
        CreateSettlement(CorpCardSettlement, 3000);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);
        CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);
        CorpCardSettlementMgt.PostSettlement(CorpCardSettlement);
        CorpCardStatementMgt.CloseStatement(CorpCardStatement);

        CorpCardTrans."Merchant Norm" := 'Changed';
        asserterror CorpCardTrans.Modify(true);

        Assert.ExpectedError('is closed');
    end;

    [Test]
    procedure ReverseSettlementCreatesAuditEntriesAndInvalidatesClosure()
    var
        CorpCardBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardReversalBankEntry: Record "Bank Account Ledger Entry";
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        PaymentBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        PaymentReversalBankEntry: Record "Bank Account Ledger Entry";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
        OriginalClosedAt: DateTime;
    begin
        Initialize();
        CreatePostedClosedSettlement(CorpCardSettlement, CorpCardStatement, CorpCardTrans);
        OriginalClosedAt := CorpCardStatement."Closed At";
        CorpCardSettlement.Validate("Reversal Reason", 'Provider corrected the settlement.');
        CorpCardSettlement.Modify(true);

        CorpCardSettlementMgt.ReverseSettlement(CorpCardSettlement);

        CorpCardSettlement.Get(CorpCardSettlement."Settlement Entry No.");
        Assert.AreEqual(CorpCardSettlement.Status::Reversed, CorpCardSettlement.Status, 'The settlement must be reversed.');
        Assert.AreNotEqual(0, CorpCardSettlement."Reversal Transaction No.", 'The reversal transaction number must be stored.');
        Assert.AreNotEqual(0, CorpCardSettlement."Reversal G/L Register No.", 'The reversal G/L register number must be stored.');
        CorpCardBankAccountLedgerEntry.Get(CorpCardSettlement."Corp Card Bank Acc. Entry No.");
        PaymentBankAccountLedgerEntry.Get(CorpCardSettlement."Payment Bank Acc. Entry No.");
        CorpCardReversalBankEntry.Get(CorpCardSettlement."Corp Card Reversal Entry No.");
        PaymentReversalBankEntry.Get(CorpCardSettlement."Payment Reversal Entry No.");
        Assert.IsTrue(CorpCardBankAccountLedgerEntry.Reversed, 'The original corporate card bank entry must be reversed.');
        Assert.IsTrue(PaymentBankAccountLedgerEntry.Reversed, 'The original payment bank entry must be reversed.');
        Assert.AreEqual(-CorpCardBankAccountLedgerEntry.Amount, CorpCardReversalBankEntry.Amount, 'The corporate card reversal amount must offset the original entry.');
        Assert.AreEqual(-PaymentBankAccountLedgerEntry.Amount, PaymentReversalBankEntry.Amount, 'The payment reversal amount must offset the original entry.');
        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        CorpCardStatement.CalcFields("Settlement Entry No.");
        Assert.AreEqual(CorpCardStatement.Status::ReconciliationRequired, CorpCardStatement.Status, 'Reversing a settlement must invalidate the closed statement.');
        Assert.AreEqual(0, CorpCardStatement."Settlement Entry No.", 'The reversed settlement must no longer be the active statement settlement.');
        Assert.AreEqual(OriginalClosedAt, CorpCardStatement."Previous Closed At", 'The previous closure date-time must be preserved.');
        Assert.AreEqual(3000, CorpCardStatement."Prev. Reconciled Amount", 'The previous reconciled amount must be preserved.');
        Assert.AreNotEqual(0DT, CorpCardStatement."Reconciliation Invalidated At", 'The invalidation date-time must be captured.');
        Assert.IsTrue(StrPos(CorpCardStatement."Recon. Invalidation Reason", 'Provider corrected the settlement.') > 0, 'The settlement reversal reason must be retained on the statement.');
    end;

    [Test]
    procedure ReversedStatementCanBeSettledAndClosedAgain()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        ReplacementSettlement: Record "EA Corp Card Settlement";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        Initialize();
        CreatePostedClosedSettlement(CorpCardSettlement, CorpCardStatement, CorpCardTrans);
        CorpCardSettlement.Validate("Reversal Reason", 'Incorrect withdrawal date.');
        CorpCardSettlement.Modify(true);
        CorpCardSettlementMgt.ReverseSettlement(CorpCardSettlement);
        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");

        CreateSettlement(ReplacementSettlement, 3000);
        ReplacementSettlement."Settlement No." := 'SETTLEMENT-002';
        ReplacementSettlement.Modify(true);
        AddStatement(ReplacementSettlement, CorpCardStatement, 10000);
        CorpCardSettlementMgt.SetReadyToPost(ReplacementSettlement);
        CorpCardSettlementMgt.PostSettlement(ReplacementSettlement);
        CorpCardStatementMgt.CloseStatement(CorpCardStatement);

        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        Assert.AreEqual(CorpCardStatement.Status::Closed, CorpCardStatement.Status, 'The replacement settlement must allow the statement to be closed again.');
        Assert.AreNotEqual(0DT, CorpCardStatement."Previous Closed At", 'The previous closure audit must remain available.');
        BankAccountLedgerEntry.SetRange("Bank Account No.", CorpCardBankAccountNo);
        BankAccountLedgerEntry.CalcSums(Amount);
        Assert.AreEqual(0, BankAccountLedgerEntry.Amount, 'The replacement settlement must clear the corporate card liability after reversal.');
    end;

    [Test]
    procedure ReversedSettlementCannotBeReversedAgain()
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
    begin
        Initialize();
        CreatePostedClosedSettlement(CorpCardSettlement, CorpCardStatement, CorpCardTrans);
        CorpCardSettlement.Validate("Reversal Reason", 'Duplicate withdrawal.');
        CorpCardSettlement.Modify(true);
        CorpCardSettlementMgt.ReverseSettlement(CorpCardSettlement);

        asserterror CorpCardSettlementMgt.ReverseSettlement(CorpCardSettlement);

        Assert.ExpectedError('must be posted before it can be reversed');
    end;

    local procedure Initialize()
    var
        CorpCardBankAccount: Record "Bank Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentBankAccount: Record "Bank Account";
    begin
        CorpCardTestLib.InitializeCorpCardData();
        CorpCardTestLib.EnsureCorpCardProvider('TEST');
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := '';
        GeneralLedgerSetup.Modify();
        CreateBankAccount(CorpCardBankAccount, 'USD');
        CreateBankAccount(PaymentBankAccount, 'USD');
        CorpCardBankAccountNo := CorpCardBankAccount."No.";
        PaymentBankAccountNo := PaymentBankAccount."No.";
        ConfigureProviderAccounts();
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
    end;

    local procedure ConfigureProviderAccounts()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        CorpCardProvider.Get('TEST');
        CorpCardProvider.Validate("Corp Card Bank Account No.", CorpCardBankAccountNo);
        CorpCardProvider.Validate("Payment Bank Account No.", PaymentBankAccountNo);
        CorpCardProvider.Modify(true);
    end;

    local procedure CreateSettlement(var CorpCardSettlement: Record "EA Corp Card Settlement"; SettlementAmount: Decimal)
    begin
        CorpCardSettlement.Init();
        CorpCardSettlement.Validate("Provider Code", 'TEST');
        CorpCardSettlement."Settlement No." := 'SETTLEMENT-001';
        CorpCardSettlement."Settlement Date" := WorkDate();
        CorpCardSettlement."Currency Code" := 'USD';
        CorpCardSettlement."Settlement Amount" := SettlementAmount;
        CorpCardSettlement.Insert(true);
    end;

    local procedure CreateStatement(var CorpCardStatement: Record "EA Corp Card Statement"; StatementNo: Code[50]; StatementAmount: Decimal; Status: Enum "EA Corp Card Stmt Status")
    begin
        Clear(CorpCardStatement);
        CorpCardStatement.Init();
        CorpCardStatement."Provider Code" := 'TEST';
        CorpCardStatement."Statement No." := StatementNo;
        CorpCardStatement."Statement Date" := WorkDate();
        CorpCardStatement."Currency Code" := 'USD';
        CorpCardStatement."Statement Total" := StatementAmount;
        CorpCardStatement.Status := Status;
        CorpCardStatement.Insert(true);
    end;

    local procedure AddStatement(CorpCardSettlement: Record "EA Corp Card Settlement"; CorpCardStatement: Record "EA Corp Card Statement"; LineNo: Integer)
    var
        CorpCardSettlementLine: Record "EA Corp Card Settlement Line";
    begin
        CorpCardSettlementLine.Init();
        CorpCardSettlementLine."Settlement Entry No." := CorpCardSettlement."Settlement Entry No.";
        CorpCardSettlementLine."Line No." := LineNo;
        CorpCardSettlementLine.Validate("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardSettlementLine.Insert(true);
    end;

    local procedure CreatePostedTransaction(var CorpCardTrans: Record "EA Corp Card Trans"; CorpCardStatement: Record "EA Corp Card Statement"; TransactionAmount: Decimal)
    begin
        CorpCardTrans.Init();
        CorpCardTrans."Statement Entry No." := CorpCardStatement."Statement Entry No.";
        CorpCardTrans."Provider Code" := CorpCardStatement."Provider Code";
        CorpCardTrans."Provider Trans Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));
        CorpCardTrans."Card Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Card Id"));
        CorpCardTrans."Trans Date" := WorkDate();
        CorpCardTrans.Amount := TransactionAmount;
        CorpCardTrans."Currency Code" := CorpCardStatement."Currency Code";
        CorpCardTrans."Expense No." := 'EXP-POSTED';
        CorpCardTrans."Posted Expense Report No." := 'PER-POSTED';
        CorpCardTrans.Status := CorpCardTrans.Status::Posted;
        CorpCardTrans.Insert(true);
    end;

    local procedure PostCorpCardExpenseBankEntry(CorpCardTrans: Record "EA Corp Card Trans"; EntryAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalLine.Init();
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Document No.", CopyStr(Format(CreateGuid()), 1, MaxStrLen(GenJournalLine."Document No.")));
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.Validate("Account No.", CorpCardBankAccountNo);
        GenJournalLine.Validate("Currency Code", CorpCardTrans."Currency Code");
        GenJournalLine.Validate(Amount, EntryAmount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine."EA Corp Card Trans Entry No." := CorpCardTrans."Entry No.";
        GenJournalLine."System-Created Entry" := true;
        GenJnlPostLine.SetIgnoreJournalTemplNameMandatoryCheck();
        GenJnlPostLine.RunWithCheck(GenJournalLine);
    end;

    local procedure CreatePostedClosedSettlement(var CorpCardSettlement: Record "EA Corp Card Settlement"; var CorpCardStatement: Record "EA Corp Card Statement"; var CorpCardTrans: Record "EA Corp Card Trans")
    var
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        CreateStatement(CorpCardStatement, 'STMT-REVERSAL', 3000, CorpCardStatement.Status::Validated);
        CreatePostedTransaction(CorpCardTrans, CorpCardStatement, 3000);
        PostCorpCardExpenseBankEntry(CorpCardTrans, -3000);
        CreateSettlement(CorpCardSettlement, 3000);
        AddStatement(CorpCardSettlement, CorpCardStatement, 10000);
        CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);
        CorpCardSettlementMgt.PostSettlement(CorpCardSettlement);
        CorpCardStatementMgt.CloseStatement(CorpCardStatement);
    end;
}
