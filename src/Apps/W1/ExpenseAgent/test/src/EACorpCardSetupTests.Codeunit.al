// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;

codeunit 148354 EACorpCardSetupTests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryERM: Codeunit "Library - ERM";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    procedure CreateDefaultsIsIdempotentAndSeedsPayload()
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        CorpCardProvider: Record "EA Corp Card Provider";
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
        GLAccount: Record "G/L Account";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
        ProviderCountBefore: Integer;
        ProviderCountAfter: Integer;
        CardCountBefore: Integer;
        CardCountAfter: Integer;
    begin
        Initialize();

        ProviderCountBefore := CountDefaultProviders();
        CardCountBefore := CountCardsForDefaultProviders();

        ExpenseCategory.Get(AirlineExpenseCategoryCodeTok);
        ExpenseCategory."Posting Group" := '';
        ExpenseCategory.Modify(true);

        CreateCorpCardSetup.CreateDefaults();

        ProviderCountAfter := CountDefaultProviders();
        CardCountAfter := CountCardsForDefaultProviders();

        Assert.AreEqual(ProviderCountBefore, ProviderCountAfter, 'CreateDefaults must be idempotent for provider records.');
        Assert.AreEqual(CardCountBefore, CardCountAfter, 'CreateDefaults must not duplicate provider card links.');
        Assert.AreEqual(8, CardCountAfter, 'CreateDefaults must create one corporate card for each of the first eight expense users.');

        ExpenseCategory.Get(AirlineExpenseCategoryCodeTok);
        Assert.AreNotEqual('', ExpenseCategory."Posting Group", 'CreateDefaults must assign the posting group on corporate card expense categories.');
        Assert.IsTrue(ExpensePostingGroup.Get(ExpenseCategory."Posting Group"), 'The assigned expense posting group must exist.');

        Assert.IsTrue(BankAccount.Get(CorpCardAccountTok), 'CreateDefaults must create the corporate card bank account.');
        Assert.AreEqual(CorpCardAccountTok, BankAccount."Bank Acc. Posting Group", 'The corporate card bank account must use its dedicated posting group.');
        Assert.IsTrue(BankAccountPostingGroup.Get(CorpCardAccountTok), 'CreateDefaults must create the corporate card bank account posting group.');
        Assert.AreEqual(CorpCardAccountTok, BankAccountPostingGroup."G/L Account No.", 'The corporate card posting group must use its dedicated G/L account.');
        Assert.IsTrue(GLAccount.Get(CorpCardAccountTok), 'CreateDefaults must create the corporate card G/L account.');

        CorpCardProvider.Get(CorpCardCsvProviderCodeTok);
        CorpCardProvider.CalcFields("Source Payload");
        Assert.IsTrue(CorpCardProvider."Source Payload".HasValue(), 'CSV provider must have sample source payload.');
        Assert.AreEqual(CorpCardCsvSampleFileNameTok, CorpCardProvider."Source File Name", 'CSV provider must point to the default sample file name.');
        Assert.AreEqual(60, CorpCardProvider."Source Payload Record Count", 'CSV provider must persist all sample payload records.');
    end;

    [Test]
    procedure CsvSampleScenarioCreatesTwoSettlementsForThreeEmployeesEach()
    var
        PaymentBankAccount: Record "Bank Account";
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
        SettlementCount: Integer;
    begin
        Initialize();

        LibraryERM.CreateBankAccount(PaymentBankAccount);
        PaymentBankAccount.Validate("Bank Acc. Posting Group", LcyBankAccountPostingGroupTok);
        PaymentBankAccount.Modify(true);

        CreateCorpCardSetup.CreateCsvSampleScenario(PaymentBankAccount."No.");

        CorpCardSettlement.SetRange("Provider Code", CorpCardCsvProviderCodeTok);
        CorpCardSettlement.SetFilter("Settlement No.", CorpCardCsvSampleSettlementFilterTok);
        Assert.IsTrue(CorpCardSettlement.FindSet(), 'The CSV sample scenario must create settlements.');
        repeat
            SettlementCount += 1;
            Assert.AreEqual(
                CorpCardSettlement.Status::Posted, CorpCardSettlement.Status,
                'Each CSV sample settlement must be posted.');
            AssertCsvSampleSettlementContainsThreeEmployees(CorpCardSettlement);
        until CorpCardSettlement.Next() = 0;

        Assert.AreEqual(2, SettlementCount, 'The CSV sample scenario must create two settlements.');
    end;

    local procedure AssertCsvSampleSettlementContainsThreeEmployees(CorpCardSettlement: Record "EA Corp Card Settlement")
    var
        CorpCard: Record "EA Corp Card";
        CorpCardSettlementLine: Record "EA Corp Card Settlement Line";
        CorpCardTrans: Record "EA Corp Card Trans";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExpenseUserNos: Dictionary of [Code[20], Boolean];
    begin
        CorpCardSettlementLine.SetRange("Settlement Entry No.", CorpCardSettlement."Settlement Entry No.");
        CorpCardSettlementLine.SetRange(Inactive, false);
        Assert.AreEqual(1, CorpCardSettlementLine.Count(), 'Each CSV sample settlement must contain one statement.');
        CorpCardSettlementLine.FindFirst();

        CorpCardTrans.SetRange("Statement Entry No.", CorpCardSettlementLine."Statement Entry No.");
        Assert.AreEqual(30, CorpCardTrans.Count(), 'Each CSV sample statement must contain 30 transactions.');
        CorpCardTrans.FindSet();
        repeat
            CurrencyExchangeRate.SetRange("Currency Code", CorpCardTrans."Currency Code");
            CurrencyExchangeRate.SetFilter("Starting Date", '..%1', CorpCardTrans."Trans Date");
            Assert.IsFalse(
                CurrencyExchangeRate.IsEmpty(),
                'Each CSV sample transaction must have an exchange rate effective on or before its transaction date.');
            CorpCard.Get(CorpCardTrans."Card Id");
            if not ExpenseUserNos.ContainsKey(CorpCard."Expense User No.") then
                ExpenseUserNos.Add(CorpCard."Expense User No.", true);
        until CorpCardTrans.Next() = 0;

        Assert.AreEqual(3, ExpenseUserNos.Count(), 'Each CSV sample settlement must cover three employees.');
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
        CorpCardProvider.SetFilter(Code, '%1|%2', CorpCardCsvProviderCodeTok, CorpCardXmlProviderCodeTok);
        exit(CorpCardProvider.Count());
    end;

    local procedure CountCardsForDefaultProviders(): Integer
    var
        CorpCard: Record "EA Corp Card";
    begin
        CorpCard.SetFilter("Provider Code", '%1|%2', CorpCardCsvProviderCodeTok, CorpCardXmlProviderCodeTok);
        exit(CorpCard.Count());
    end;

    var
        CorpCardCsvProviderCodeTok: Label 'CORPCARDCSV', Locked = true;
        CorpCardXmlProviderCodeTok: Label 'CORPCARDXML', Locked = true;
        CorpCardCsvSampleFileNameTok: Label 'CorpCard-Sample-60.csv', Locked = true;
        CorpCardCsvSampleSettlementFilterTok: Label 'CSV-SAMPLE-SETTLEMENT-*', Locked = true;
        CorpCardAccountTok: Label 'CORPCARD', Locked = true;
        LcyBankAccountPostingGroupTok: Label 'LCY', Locked = true;
        AirlineExpenseCategoryCodeTok: Label 'AIRLINE', Locked = true;
}
