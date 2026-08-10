// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148339 EACorpCardSetupTests
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
    procedure CreateDefaultsIsIdempotentAndSeedsPayload()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
        ProviderCountBefore: Integer;
        ProviderCountAfter: Integer;
        CardCountBefore: Integer;
        CardCountAfter: Integer;
    begin
        Initialize();

        ProviderCountBefore := CountDefaultProviders();
        CardCountBefore := CountCardsForDefaultProviders();

        CreateCorpCardSetup.CreateDefaults();

        ProviderCountAfter := CountDefaultProviders();
        CardCountAfter := CountCardsForDefaultProviders();

        Assert.AreEqual(ProviderCountBefore, ProviderCountAfter, 'CreateDefaults must be idempotent for provider records.');
        Assert.AreEqual(CardCountBefore, CardCountAfter, 'CreateDefaults must not duplicate provider card links.');

        CorpCardProvider.Get(CorpCardCsvProviderCodeTok);
        CorpCardProvider.CalcFields("Source Payload");
        Assert.IsTrue(CorpCardProvider."Source Payload".HasValue(), 'CSV provider must have sample source payload.');
        Assert.AreEqual(CorpCardCsvSampleFileNameTok, CorpCardProvider."Source File Name", 'CSV provider must point to the default sample file name.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::EACorpCardSetupTests);
        CorpCardTestLib.InitializeCorpCardData();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::EACorpCardSetupTests);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::EACorpCardSetupTests);
    end;

    local procedure CountDefaultProviders(): Integer
    var
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        CorpCardProvider.SetFilter(Code, '%1|%2|%3|%4|%5', CorpCardCsvProviderCodeTok, CorpCardXmlProviderCodeTok, CorpCardIsoProviderCodeTok, CorpCardCamt053ProviderCodeTok, CorpCardCamt054ProviderCodeTok);
        exit(CorpCardProvider.Count());
    end;

    local procedure CountCardsForDefaultProviders(): Integer
    var
        CorpCard: Record "EA Corp Card";
    begin
        CorpCard.SetFilter("Provider Code", '%1|%2|%3|%4|%5', CorpCardCsvProviderCodeTok, CorpCardXmlProviderCodeTok, CorpCardIsoProviderCodeTok, CorpCardCamt053ProviderCodeTok, CorpCardCamt054ProviderCodeTok);
        exit(CorpCard.Count());
    end;

    var
        CorpCardCsvProviderCodeTok: Label 'CORPCARDCSV', Locked = true;
        CorpCardXmlProviderCodeTok: Label 'CORPCARDXML', Locked = true;
        CorpCardIsoProviderCodeTok: Label 'CORPCARDISO', Locked = true;
        CorpCardCamt053ProviderCodeTok: Label 'CORPCAMT053', Locked = true;
        CorpCardCamt054ProviderCodeTok: Label 'CORPCAMT054', Locked = true;
        CorpCardCsvSampleFileNameTok: Label 'CorpCard-Sample-60.csv', Locked = true;
}
