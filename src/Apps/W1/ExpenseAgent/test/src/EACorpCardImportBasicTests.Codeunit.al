// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 148340 EACorpCardImportBasicTests
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
    procedure CsvImportCreatesCompletedBatchAndTransactions()
    var
        CorpCardBatch: Record "EA Corp Card Batch";
        ImportedTransCount: Integer;
    begin
        Initialize();

        CorpCardTestLib.RunImportAndGetLastBatch(CorpCardCsvProviderCodeTok, CorpCardBatch);
        ImportedTransCount := CorpCardTestLib.CountTransForBatch(CorpCardBatch."Batch No.", CorpCardCsvProviderCodeTok);

        Assert.AreEqual(CorpCardBatch.Status::Completed, CorpCardBatch.Status, 'CSV import batch must complete successfully.');
        Assert.IsTrue(CorpCardBatch.Imported > 0, 'CSV sample import must create at least one transaction.');
        Assert.AreEqual(CorpCardBatch.Imported, ImportedTransCount, 'Imported counter must match staged transaction rows for the batch.');
        Assert.IsTrue(CorpCardBatch.Rejected >= CorpCardBatch.Exceptions, 'Rejected count must be greater than or equal to exception count.');
    end;

    [Test]
    procedure CsvImportSecondRunCountsDuplicates()
    var
        FirstBatch: Record "EA Corp Card Batch";
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
    begin
        Initialize();

        CorpCardTestLib.RunImportAndGetLastBatch(CorpCardCsvProviderCodeTok, FirstBatch);
        Assert.IsTrue(FirstBatch.Imported > 0, 'First CSV import must import transactions before duplicate rerun is tested.');

        asserterror CorpCardFeedMgt.RunImport(CorpCardCsvProviderCodeTok);
        Assert.ExpectedError(NoParsedLinesErr);
    end;

    [Test]
    procedure Camt054ImportNormalizesMappedFields()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := UsdCurrencyCodeTok;
        GeneralLedgerSetup.Modify(true);

        CorpCardTestLib.RunImportAndGetLastBatch(CorpCardCamt054ProviderCodeTok, CorpCardBatch);
        CorpCardTestLib.FindTransInBatchByProviderTransId(CorpCardBatch."Batch No.", CorpCardCamt054ProviderCodeTok, Camt054ProviderTransIdTok, CorpCardTrans);

        Assert.AreEqual(CorpCardBatch.Status::Completed, CorpCardBatch.Status, 'CAMT054 import batch must complete successfully.');
        Assert.AreEqual(Camt054MccTok, CorpCardTrans.MCC, 'CAMT054 import must remove the MCC tag before validating the transaction field.');
        Assert.AreEqual('', CorpCardTrans."Currency Code", 'CAMT054 import must map the LCY currency code to blank before validating the transaction field.');
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

    local procedure InitializeValidTransaction(var CorpCardTrans: Record "EA Corp Card Trans")
    begin
        CorpCardTrans.Init();
        CorpCardTrans."Provider Code" := CorpCardCsvProviderCodeTok;
        CorpCardTrans."Card Id" := 'CARD-001';
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
        CorpCardCamt054ProviderCodeTok: Label 'CORPCAMT054', Locked = true;
        Camt054ProviderTransIdTok: Label 'CAMT54TXN001', Locked = true;
        Camt054MccTok: Label '4511', Locked = true;
        EuroCurrencyCodeTok: Label 'EUR', Locked = true;
        UsdCurrencyCodeTok: Label 'USD', Locked = true;
        NoParsedLinesErr: Label 'No transaction lines were parsed from file', Locked = true;
}
