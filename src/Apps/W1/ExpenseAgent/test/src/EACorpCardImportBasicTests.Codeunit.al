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
    procedure CsvImportSecondRunCountsDuplicates()
    var
        FirstStatement: Record "EA Corp Card Statement";
        SecondStatement: Record "EA Corp Card Statement";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
    begin
        Initialize();

        CorpCardTestLib.RunImportAndGetLastStatement(CorpCardCsvProviderCodeTok, FirstStatement);
        Assert.IsTrue(FirstStatement.Imported > 0, 'First CSV import must import transactions before duplicate rerun is tested.');

        CreateCorpCardSetup.CreateDefaults();
        CorpCardTestLib.RunImportAndGetLastStatement(CorpCardCsvProviderCodeTok, SecondStatement);

        Assert.IsTrue(SecondStatement.Duplicates > 0, 'Second CSV import must count the previously imported transactions as duplicates.');
        Assert.AreEqual(0, SecondStatement.Imported, 'Second CSV import must not import duplicate transactions.');
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
