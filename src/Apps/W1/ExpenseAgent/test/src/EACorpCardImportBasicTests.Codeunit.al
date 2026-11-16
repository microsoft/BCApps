// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;

codeunit 148356 EACorpCardImportBasicTests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        RecordNotFoundForCardErr: Label '%1 not found for card %2.', Locked = true;
        ExpenseUserNotSpecifiedForCardErr: Label 'Specify %1 for corporate card %2 before creating expenses.', Locked = true;

    [Test]
    procedure DraftCreationWithMissingCardReportsCardNotFound()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseWriter: Codeunit "EA Corp Card Expense Writer";
        ExpenseNo: Code[20];
    begin
        CorpCardTrans."Card Id" := Format(CreateGuid());

        asserterror ExpenseWriter.CreateDraftFromTrans(CorpCardTrans, ExpenseNo);

        Assert.ExpectedError(StrSubstNo(RecordNotFoundForCardErr, CorpCard.TableCaption(), CorpCardTrans."Card Id"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DraftCreationWithUnassignedCardReportsMissingExpenseUser()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardErrorContext: Codeunit "EA Corp Card Error Context";
        ExpenseWriter: Codeunit "EA Corp Card Expense Writer";
        MissingExpenseUserErrorInfo: ErrorInfo;
        ExpenseNo: Code[20];
    begin
        CorpCard."Card Id" := Format(CreateGuid());
        CorpCard.Insert(true);
        CorpCardTrans."Card Id" := CorpCard."Card Id";
        CorpCardErrorContext.ClearErrorInfo();

        asserterror ExpenseWriter.CreateDraftFromTrans(CorpCardTrans, ExpenseNo);

        Assert.ExpectedError(
            StrSubstNo(ExpenseUserNotSpecifiedForCardErr, CorpCard.FieldCaption("Expense User No."), CorpCard."Card Id"));
        Assert.IsTrue(CorpCardErrorContext.TryGetErrorInfo(MissingExpenseUserErrorInfo), 'Missing expense user setup must retain structured error information.');
        Assert.AreEqual(
            StrSubstNo(ExpenseUserNotSpecifiedForCardErr, CorpCard.FieldCaption("Expense User No."), CorpCard."Card Id"),
            MissingExpenseUserErrorInfo.Message, 'The structured error must identify the missing expense user setup.');
        Assert.AreEqual(Page::"EA Corp Card Cards", MissingExpenseUserErrorInfo.PageNo, 'The recovery action must open corporate card setup.');
        Assert.AreEqual(CorpCard.RecordId, MissingExpenseUserErrorInfo.RecordId, 'The recovery action must target the card without an expense user.');
    end;

    [Test]
    procedure CsvFallbackHandlesQuotedCommasAndEscapedQuotes()
    var
        CorpCardDataExchProv: Codeunit "EA Corp Card Data Exch Prov";
        CsvFields: List of [Text];
    begin
        CsvFields := CorpCardDataExchProv.ParseCsvFields('TXN1,CARD1,2026-06-02,2026-06-03,19.63,USD,"Acme, ""Inc.""",4511,US');

        Assert.AreEqual(9, CsvFields.Count(), 'A comma within a quoted merchant must not create an additional column.');
        Assert.AreEqual('Acme, "Inc."', CsvFields.Get(7), 'The merchant must retain its comma and unescaped quotes.');
        Assert.AreEqual('4511', CsvFields.Get(8), 'The MCC must remain in its column.');
        Assert.AreEqual('US', CsvFields.Get(9), 'The country must remain in its column.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SourceInjectionIsScopedToBoundHelper()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        DataExch: Record "Data Exch.";
        CorpCardDataExchProv: Codeunit "EA Corp Card Data Exch Prov";
        UnboundCorpCardTestLib: Codeunit EACorpCardTestLib;
    begin
        Initialize();
        Assert.IsFalse(UnboundCorpCardTestLib.HasSourcePayload(CorpCardCsvProviderCodeTok), 'Source payloads must not be shared between helper instances.');
        CorpCardTestLib.CreateStatement(CorpCardStatement, CorpCardCsvProviderCodeTok, 'SUBSCRIPTION-TEST', 19.63, CorpCardStatement.Status::Importing);
        Commit();

        asserterror CorpCardDataExchProv.Download(CorpCardStatement);

        Assert.ExpectedError('Select a statement file using Import statement for provider');
        Assert.IsTrue(CorpCardTestLib.HasSourcePayload(CorpCardCsvProviderCodeTok), 'An unbound helper must not supply or consume source content.');
        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");

        BindSubscription(CorpCardTestLib);
        CorpCardDataExchProv.Download(CorpCardStatement);
        UnbindSubscription(CorpCardTestLib);

        Assert.IsFalse(CorpCardTestLib.HasSourcePayload(CorpCardCsvProviderCodeTok), 'The bound helper must supply its source content.');
        DataExch.Get(CorpCardStatement."Data Exch Entry No.");
        DataExch.Delete(true);
        CorpCardTestLib.AssertNoSourceFile(CorpCardStatement);
        CorpCardTestLib.SetCsvProviderSourcePayload();
        CorpCardTestLib.CreateStatement(CorpCardStatement, CorpCardCsvProviderCodeTok, 'AFTER-UNBIND', 19.63, CorpCardStatement.Status::Importing);
        Commit();

        asserterror CorpCardDataExchProv.Download(CorpCardStatement);

        Assert.ExpectedError('Select a statement file using Import statement for provider');
        Assert.IsTrue(CorpCardTestLib.HasSourcePayload(CorpCardCsvProviderCodeTok), 'Unbinding must stop source injection for later downloads.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CsvImportCreatesCompletedStatementAndTransactions()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        ImportedTransCount: Integer;
    begin
        Initialize();

        BindSubscription(CorpCardTestLib);
        CorpCardTestLib.RunImportAndGetLastStatement(CorpCardCsvProviderCodeTok, CorpCardStatement);
        UnbindSubscription(CorpCardTestLib);
        ImportedTransCount := CorpCardTestLib.CountTransForStatement(CorpCardStatement."Statement Entry No.", CorpCardCsvProviderCodeTok);

        Assert.AreEqual(CorpCardStatement.Status::Imported, CorpCardStatement.Status, 'CSV statement import must complete successfully.');
        Assert.AreEqual(60, CorpCardStatement.Imported, 'CSV sample import must create all sample transactions.');
        Assert.AreEqual(CorpCardStatement.Imported, ImportedTransCount, 'Imported counter must match staged transaction rows for the statement.');
        Assert.IsTrue(CorpCardStatement.Rejected >= CorpCardStatement.Exceptions, 'Rejected count must be greater than or equal to exception count.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CsvImportSecondRunCountsDuplicates()
    var
        FirstStatement: Record "EA Corp Card Statement";
        SecondStatement: Record "EA Corp Card Statement";
    begin
        Initialize();

        BindSubscription(CorpCardTestLib);
        CorpCardTestLib.RunImportAndGetLastStatement(CorpCardCsvProviderCodeTok, FirstStatement);
        UnbindSubscription(CorpCardTestLib);
        Assert.IsTrue(FirstStatement.Imported > 0, 'First CSV import must import transactions before duplicate rerun is tested.');

        CorpCardTestLib.SetCsvProviderSourcePayload();
        BindSubscription(CorpCardTestLib);
        CorpCardTestLib.RunImportAndGetLastStatement(CorpCardCsvProviderCodeTok, SecondStatement);
        UnbindSubscription(CorpCardTestLib);

        Assert.IsTrue(SecondStatement.Duplicates > 0, 'Second CSV import must count the previously imported transactions as duplicates.');
        Assert.AreEqual(0, SecondStatement.Imported, 'Second CSV import must not import duplicate transactions.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure StagingImportDoesNotCreateDrafts()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        CorpCardImportOrch: Codeunit "EA Corp Card Import Orch";
        ExpenseCount: Integer;
    begin
        Initialize();
        ExpenseCount := Expense.Count();
        CorpCardStatement.Init();
        CorpCardStatement."Provider Code" := CorpCardCsvProviderCodeTok;
        CorpCardStatement.Status := CorpCardStatement.Status::Importing;
        CorpCardStatement.Insert(true);
        Commit();

        BindSubscription(CorpCardTestLib);
        Assert.IsTrue(CorpCardImportOrch.Run(CorpCardStatement), 'Staging import must succeed without post-import processing.');
        UnbindSubscription(CorpCardTestLib);

        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        Assert.AreEqual(60, CorpCardTrans.Count(), 'Staging import must retain every parsed transaction.');
        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::Imported);
        Assert.AreEqual(60, CorpCardTrans.Count(), 'Staged transactions must remain available for post-import processing.');
        Assert.AreEqual(ExpenseCount, Expense.Count(), 'The import transaction must not create draft expenses.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DraftFailurePreservesImportAndCanBeRetried()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardException: Record "EA Corp Card Exception";
        Expense: Record Expense;
        PostImportOrch: Codeunit "EA Corp Card Post Import Orch";
        ExpenseWriter: Codeunit "EA Corp Card Expense Writer";
        ExpenseUserNo: Code[20];
        ExpenseCount: Integer;
        FailedTransactionCount: Integer;
    begin
        Initialize();
        CorpCard.SetRange("Provider Code", CorpCardCsvProviderCodeTok);
        CorpCard.FindFirst();
        ExpenseUserNo := CorpCard."Expense User No.";
        CorpCard."Expense User No." := '';
        CorpCard.Modify(true);
        ExpenseCount := Expense.Count();

        BindSubscription(CorpCardTestLib);
        CorpCardTestLib.RunImportAndGetLastStatement(CorpCardCsvProviderCodeTok, CorpCardStatement);
        UnbindSubscription(CorpCardTestLib);

        Assert.AreEqual(CorpCardStatement.Status::Imported, CorpCardStatement.Status, 'A draft failure must not fail the import.');
        Assert.AreEqual(60, CorpCardStatement.Imported, 'A draft failure must not roll back staged transactions.');
        Assert.AreEqual(0, CorpCardStatement.Rejected, 'Post-import failures must not count as rejected import rows.');
        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        Assert.AreEqual(60, CorpCardTrans.Count(), 'All staged rows must survive draft creation errors.');
        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::Exception);
        FailedTransactionCount := CorpCardTrans.Count();
        Assert.AreEqual(10, FailedTransactionCount, 'Only transactions for the card without an expense user must fail.');
        CorpCardTrans.FindFirst();
        CorpCardTrans.TestField("Expense No.", '');
        CorpCardTrans.TestField("Merchant Norm", '');
        Assert.IsTrue(CorpCardTrans."Reject Reason" <> '', 'A failed row must retain its processing error.');
        Assert.AreEqual(ExpenseCount + 50, Expense.Count(), 'Other rows must still create their draft expenses.');
        Assert.AreEqual(FailedTransactionCount, CorpCardStatement.Exceptions, 'Every failed row must be visible as an exception.');

        PostImportOrch.ProcessStatementPostImport(CorpCardStatement."Statement Entry No.", ExpenseWriter);
        CorpCardException.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardException.SetRange("Exception Type", CorpCardException."Exception Type"::PostImportProcessing);
        Assert.AreEqual(FailedTransactionCount, CorpCardException.Count(), 'Repeated failures must update existing exceptions, not add duplicates.');
        Assert.AreEqual(ExpenseCount + 50, Expense.Count(), 'A failed retry must not create partial or duplicate expenses.');

        CorpCard."Expense User No." := ExpenseUserNo;
        CorpCard.Modify(true);
        PostImportOrch.ProcessStatementPostImport(CorpCardStatement."Statement Entry No.", ExpenseWriter);

        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        Assert.AreEqual(0, CorpCardStatement.Exceptions, 'Successful retries must clear the unresolved statement exception count.');
        CorpCardException.SetRange(Resolved, false);
        Assert.IsTrue(CorpCardException.IsEmpty(), 'Successful retries must resolve their processing exceptions.');
        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::DraftCreated);
        Assert.AreEqual(60, CorpCardTrans.Count(), 'Every transaction must have a draft after the setup is corrected.');
        Assert.AreEqual(ExpenseCount + 60, Expense.Count(), 'Retries must create drafts only for previously failed transactions.');

        PostImportOrch.ProcessStatementPostImport(CorpCardStatement."Statement Entry No.", ExpenseWriter);
        Assert.AreEqual(ExpenseCount + 60, Expense.Count(), 'Processing a completed statement again must not create duplicate expenses.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MissingPaymentMethodPreservesAllImportedRows()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardException: Record "EA Corp Card Exception";
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        Expense: Record Expense;
        ExpenseCount: Integer;
    begin
        Initialize();
        ExpenseCount := Expense.Count();
        ExpenseCategory.ModifyAll("Default Payment Method", '');
        ExpensePaymentMethod.SetRange("Reimbursement Type", ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
        ExpensePaymentMethod.DeleteAll(false);

        BindSubscription(CorpCardTestLib);
        CorpCardTestLib.RunImportAndGetLastStatement(CorpCardCsvProviderCodeTok, CorpCardStatement);
        UnbindSubscription(CorpCardTestLib);

        Assert.AreEqual(CorpCardStatement.Status::Imported, CorpCardStatement.Status, 'Missing draft setup must not fail the import.');
        Assert.AreEqual(60, CorpCardStatement.Imported, 'Every transaction must be imported even if no draft can be created.');
        Assert.AreEqual(60, CorpCardStatement.Exceptions, 'Every draft failure must be recorded.');
        Assert.AreEqual(ExpenseCount, Expense.Count(), 'Failed draft creation must not leave partial expenses.');
        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::Exception);
        Assert.AreEqual(60, CorpCardTrans.Count(), 'Every imported row must remain available for retry.');
        CorpCardException.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardException.FindFirst();
        Assert.AreEqual(
            'An expense payment method with reimbursement type Credit Card must exist before corporate card expenses can be created.',
            CorpCardException.Message, 'The exception must retain the actionable setup error message.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailureAfterExpenseInsertRollsBackOnlyDrafts()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        FailureLibraryExpense: Codeunit "Library - Expense";
        PostImportOrch: Codeunit "EA Corp Card Post Import Orch";
        ExpenseWriter: Codeunit "EA Corp Card Expense Writer";
        ExpenseCount: Integer;
    begin
        Initialize();
        ExpenseCount := Expense.Count();
        FailureLibraryExpense.SetCorpCardDraftFailureEnabled(true);
        BindSubscription(FailureLibraryExpense);

        BindSubscription(CorpCardTestLib);
        CorpCardTestLib.RunImportAndGetLastStatement(CorpCardCsvProviderCodeTok, CorpCardStatement);
        UnbindSubscription(CorpCardTestLib);

        UnbindSubscription(FailureLibraryExpense);
        Assert.AreEqual(CorpCardStatement.Status::Imported, CorpCardStatement.Status, 'Errors after expense insertion must not fail the import.');
        Assert.AreEqual(60, CorpCardStatement.Imported, 'Expense insertion errors must preserve all staged rows.');
        Assert.AreEqual(60, CorpCardStatement.Exceptions, 'Each rolled-back draft must retain a processing exception.');
        Assert.AreEqual(ExpenseCount, Expense.Count(), 'An error after expense insertion must roll back the inserted expense.');
        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::Exception);
        Assert.AreEqual(60, CorpCardTrans.Count(), 'Failed rows must remain available for retry.');
        CorpCardTrans.SetFilter("Expense No.", '<>%1', '');
        Assert.IsTrue(CorpCardTrans.IsEmpty(), 'Rolled-back drafts must not leave expense links on their transactions.');

        PostImportOrch.ProcessStatementPostImport(CorpCardStatement."Statement Entry No.", ExpenseWriter);
        Assert.AreEqual(ExpenseCount + 60, Expense.Count(), 'A retry must create exactly one expense for each failed row.');
        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        Assert.AreEqual(0, CorpCardStatement.Exceptions, 'Successful retries must resolve processing exceptions.');
    end;

    [Test]
    procedure FuzzyMatchReusesCandidatesWithoutRematchingLinkedExpenses()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        FirstExpense: Record Expense;
        SecondExpense: Record Expense;
        EnhancedMatchMgt: Codeunit "EA Corp Card Enh. Match Mgt";
        MatchedExpenseNo: Code[20];
    begin
        Initialize();
        InitializeValidTransaction(CorpCardTrans);
        CorpCard.Get(CorpCardTrans."Card Id");
        CorpCardTrans."Merchant Norm" := 'Bluebird Cafe';
        CorpCardTrans.Amount := 1234;
        CorpCardTrans."Currency Code" := UsdCurrencyCodeTok;

        LibraryExpense.CreateExpense(FirstExpense, CorpCard."Expense User No.", 'AIRLINE', '', '', false, UsdCurrencyCodeTok, 1);
        FirstExpense.Validate("Merchant Name", CorpCardTrans."Merchant Norm");
        FirstExpense.Modify(true);
        LibraryExpense.CreateExpense(SecondExpense, CorpCard."Expense User No.", 'AIRLINE', '', '', false, UsdCurrencyCodeTok, 1);
        SecondExpense.Validate("Merchant Name", CorpCardTrans."Merchant Norm");
        SecondExpense.Modify(true);

        EnhancedMatchMgt.InitializeCardCache();
        Assert.IsTrue(EnhancedMatchMgt.EnhancedMatchTransaction(CorpCardTrans, MatchedExpenseNo), 'A matching open expense must be found.');
        Assert.AreEqual(FirstExpense."No.", MatchedExpenseNo, 'The first matching expense must be selected.');
        Assert.AreEqual(CorpCardTrans."Match Type"::Expense, CorpCardTrans."Match Type", 'The candidate must be selected by fuzzy merchant matching, not exact amount matching.');

        FirstExpense."Credit Card Feed No." := 1;
        FirstExpense.Modify(true);
        EnhancedMatchMgt.RemoveCandidate(MatchedExpenseNo);

        Assert.IsTrue(EnhancedMatchMgt.EnhancedMatchTransaction(CorpCardTrans, MatchedExpenseNo), 'The next available expense must still match.');
        Assert.AreEqual(SecondExpense."No.", MatchedExpenseNo, 'An expense linked to a previous transaction must not match again.');
    end;

    [Test]
    procedure ImportValidationNormalizesLcyCurrencyCode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardValidateMgt: Codeunit "EA Corp Card Validate Mgt";
    begin
        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := EuroCurrencyCodeTok;
        GeneralLedgerSetup.Modify(true);
        InitializeValidTransaction(CorpCardTrans);
        CorpCardTrans."Currency Code" := EuroCurrencyCodeTok;

        Assert.IsTrue(CorpCardValidateMgt.ValidateTrans(CorpCardTrans), 'The corporate card transaction must be valid.');

        Assert.AreEqual('', CorpCardTrans."Currency Code", 'An imported LCY currency code must be stored as blank.');
    end;

    [Test]
    procedure ImportValidationKeepsForeignCurrencyCode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardValidateMgt: Codeunit "EA Corp Card Validate Mgt";
    begin
        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := EuroCurrencyCodeTok;
        GeneralLedgerSetup.Modify(true);
        InitializeValidTransaction(CorpCardTrans);
        CorpCardTrans."Currency Code" := UsdCurrencyCodeTok;

        Assert.IsTrue(CorpCardValidateMgt.ValidateTrans(CorpCardTrans), 'The corporate card transaction must be valid.');

        Assert.AreEqual(UsdCurrencyCodeTok, CorpCardTrans."Currency Code", 'An imported foreign currency code must be preserved.');
    end;

    [Test]
    procedure ImportValidationRejectsBlockedCard()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardValidateMgt: Codeunit "EA Corp Card Validate Mgt";
        ValidationReason: Text[250];
    begin
        Initialize();

        InitializeValidTransaction(CorpCardTrans);
        CorpCard.Get(CorpCardTrans."Card Id");
        CorpCard.Blocked := true;
        CorpCard.Modify(true);

        Assert.IsFalse(CorpCardValidateMgt.ValidateTrans(CorpCardTrans, ValidationReason), 'A blocked card must produce a row validation failure rather than aborting the import.');
        Assert.AreEqual('The corporate card is blocked.', ValidationReason, 'The validation failure must identify the blocked card.');
    end;

    local procedure InitializeValidTransaction(var CorpCardTrans: Record "EA Corp Card Trans")
    var
        CorpCard: Record "EA Corp Card";
    begin
        CorpCard.SetRange("Provider Code", CorpCardCsvProviderCodeTok);
        CorpCard.FindFirst();

        CorpCardTrans.Init();
        CorpCardTrans."Provider Code" := CorpCardCsvProviderCodeTok;
        CorpCardTrans."Card Id" := CorpCard."Card Id";
        CorpCardTrans."Provider Trans Id" := 'TRANS-001';
        CorpCardTrans."Trans Date" := WorkDate();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::EACorpCardImportBasicTests);
        Clear(CorpCardTestLib);
        CorpCardTestLib.InitializeCorpCardData();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::EACorpCardImportBasicTests);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::EACorpCardImportBasicTests);
    end;

    var
        CorpCardCsvProviderCodeTok: Label 'CORPCARDCSV', Locked = true;
        EuroCurrencyCodeTok: Label 'EUR', Locked = true;
        UsdCurrencyCodeTok: Label 'USD', Locked = true;
}
