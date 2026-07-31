// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

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
        CorpCardBatch: Record EACorpCardBatch;
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
        FirstBatch: Record EACorpCardBatch;
        CorpCardFeedMgt: Codeunit EACorpCardFeedMgt;
    begin
        Initialize();

        CorpCardTestLib.RunImportAndGetLastBatch(CorpCardCsvProviderCodeTok, FirstBatch);
        Assert.IsTrue(FirstBatch.Imported > 0, 'First CSV import must import transactions before duplicate rerun is tested.');

        asserterror CorpCardFeedMgt.RunImport(CorpCardCsvProviderCodeTok);
        Assert.ExpectedError(NoParsedLinesErr);
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
        NoParsedLinesErr: Label 'No transaction lines were parsed from file', Locked = true;
}
