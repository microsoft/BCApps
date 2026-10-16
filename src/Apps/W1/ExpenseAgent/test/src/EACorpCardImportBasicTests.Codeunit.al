// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Setup;

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
    procedure CsvImportCreatesCompletedStatementAndTransactions()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        ImportedTransCount: Integer;
    begin
        Initialize();

        CorpCardTestLib.RunImportAndGetLastStatement(CorpCardCsvProviderCodeTok, CorpCardStatement);
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

        CorpCardTestLib.RunImportAndGetLastStatement(CorpCardCsvProviderCodeTok, FirstStatement);
        Assert.IsTrue(FirstStatement.Imported > 0, 'First CSV import must import transactions before duplicate rerun is tested.');

        CorpCardTestLib.SetCsvProviderSourcePayload();
        CorpCardTestLib.RunImportAndGetLastStatement(CorpCardCsvProviderCodeTok, SecondStatement);

        Assert.IsTrue(SecondStatement.Duplicates > 0, 'Second CSV import must count the previously imported transactions as duplicates.');
        Assert.AreEqual(0, SecondStatement.Imported, 'Second CSV import must not import duplicate transactions.');
    end;

    [Test]
    procedure FuzzyMatchReusesCandidatesWithoutRematchingLinkedExpenses()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        EnhancedMatchMgt: Codeunit "EA Corp Card Enh. Match Mgt";
        MatchedExpenseNo: Code[20];
    begin
        Initialize();
        InitializeValidTransaction(CorpCardTrans);
        CorpCard.Get(CorpCardTrans."Card Id");
        CorpCardTrans."Merchant Norm" := 'Bluebird Cafe';
        CorpCardTrans.Amount := 1234;
        CorpCardTrans."Currency Code" := UsdCurrencyCodeTok;

        Expense.Init();
        Expense."No." := 'FUZZY-001';
        Expense."Expense User No." := CorpCard."Expense User No.";
        Expense.Status := Expense.Status::Open;
        Expense."Merchant Name" := CorpCardTrans."Merchant Norm";
        Expense.Insert(false);
        Expense."No." := 'FUZZY-002';
        Expense.Insert(false);

        EnhancedMatchMgt.InitializeCardCache();
        Assert.IsTrue(EnhancedMatchMgt.EnhancedMatchTransaction(CorpCardTrans, MatchedExpenseNo), 'A matching open expense must be found.');
        Assert.AreEqual('FUZZY-001', MatchedExpenseNo, 'The first matching expense must be selected.');

        Expense.Get(MatchedExpenseNo);
        Expense."Credit Card Feed No." := 1;
        Expense.Modify(false);
        EnhancedMatchMgt.RemoveCandidate(MatchedExpenseNo);

        Assert.IsTrue(EnhancedMatchMgt.EnhancedMatchTransaction(CorpCardTrans, MatchedExpenseNo), 'The next available expense must still match.');
        Assert.AreEqual('FUZZY-002', MatchedExpenseNo, 'An expense linked to a previous transaction must not match again.');
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
    begin
        Initialize();

        InitializeValidTransaction(CorpCardTrans);
        CorpCard.Get(CorpCardTrans."Card Id");
        CorpCard.Blocked := true;
        CorpCard.Modify(true);

        asserterror CorpCardValidateMgt.ValidateTrans(CorpCardTrans);
        Assert.ExpectedTestFieldError(CorpCard.FieldCaption(Blocked), Format(false));
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
