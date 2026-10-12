// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;

codeunit 148357 EACorpCardTestLib
{
    var
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryExpense: Codeunit "Library - Expense";
        NoStatementCreatedForProviderTxt: Label 'No statement was created for provider %1.', Comment = '%1 = provider code', Locked = true;
        ProviderTransactionNotImportedTxt: Label 'Provider transaction %1 was not imported for provider %2.', Comment = '%1 = provider transaction ID, %2 = provider code', Locked = true;
        ProviderNotFoundTxt: Label 'Provider %1 was not found.', Comment = '%1 = provider code', Locked = true;
        CorpCardCsvProviderCodeTok: Label 'CORPCARDCSV', Locked = true;
        CorpCardXmlProviderCodeTok: Label 'CORPCARDXML', Locked = true;
        CorpCardCsvSampleFileNameTok: Label 'CorpCard-Sample-60.csv', Locked = true;
        CorpCardXmlSampleFileNameTok: Label 'CorpCard-Sample-60.xml', Locked = true;

    internal procedure InitializeCorpCardData()
    var
        CorpCard: Record "EA Corp Card";
        ExpenseUser: Record "Expense User";
        ExpenseUserNo: Integer;
    begin
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();
        LibraryExpense.InitializeExpenseSourceCode();
        DeleteCorpCardTransactionalData();
        CorpCard.DeleteAll();

        for ExpenseUserNo := 1 to 8 do
            LibraryExpense.CreateExpenseUser(ExpenseUser);
        InitializeCorpCardSetup();
        InitializeCorpCardProviders();
        InitializeCorpCards();
        EnsureCurrencyExchangeRate('USD');
        EnsureCurrencyExchangeRate('EUR');
    end;

    local procedure InitializeCorpCardSetup()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CorpCardMCCMgt: Codeunit "EA Corp Card MCC Mgt";
        CreateExpenseAgentSetup: Codeunit "Create Expense Agent Setup";
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        CreateExpenseAgentSetup.CreateDefaultPaymentMethods();
        CreateExpenseCategories.InsertAccountingDefaults();
        CorpCardMCCMgt.InitializeDefaultMCCMappings();
        InitializeCorpCardExpenseCategoryPostingGroups();

        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert(true);
        end;
        ExpenseAgentSetup."Corp Card Create Mode" := ExpenseAgentSetup."Corp Card Create Mode"::AutoDraft;
        ExpenseAgentSetup."Corp Card Auto Create Draft" := true;
        ExpenseAgentSetup."Corp Card Date Match Window" := 7;
        ExpenseAgentSetup."Corp Card Amount Tolerance" := 5;
        ExpenseAgentSetup."Corp Card Default Provider" := CorpCardCsvProviderCodeTok;
        ExpenseAgentSetup.Modify(true);
    end;

    local procedure InitializeCorpCardExpenseCategoryPostingGroups()
    var
        CorpCardMCCMap: Record "EA Corp Card MCC Map";
        ExpenseCategory: Record "Expense Category";
        TempExpenseCategory: Record "Expense Category" temporary;
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        CreateExpenseCategories.BuildCategorySeeds(TempExpenseCategory);
        if CorpCardMCCMap.FindSet() then
            repeat
                if ExpenseCategory.Get(CorpCardMCCMap."Expense Category") and
                   (ExpenseCategory."Posting Group" = '') and
                   TempExpenseCategory.Get(ExpenseCategory.Code)
                then begin
                    ExpenseCategory.Validate("Posting Group", TempExpenseCategory."Posting Group");
                    ExpenseCategory.Modify(true);
                end;
            until CorpCardMCCMap.Next() = 0;
    end;

    local procedure InitializeCorpCardProviders()
    begin
        InitializeCorpCardProvider(CorpCardCsvProviderCodeTok, Enum::"EA Corp Card Feed Type"::CSV);
        InitializeCorpCardProvider(CorpCardXmlProviderCodeTok, Enum::"EA Corp Card Feed Type"::XML);
        SetCsvProviderSourcePayload();
        SetProviderSourcePayload(CorpCardXmlProviderCodeTok, GetXmlProviderSourcePayload(), CorpCardXmlSampleFileNameTok);
    end;

    local procedure InitializeCorpCardProvider(ProviderCode: Code[20]; FeedType: Enum "EA Corp Card Feed Type")
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
    begin
        EnsureCorpCardProvider(ProviderCode);
        CorpCardProvider.Get(ProviderCode);
        CorpCardProvider.Enabled := true;
        CorpCardProvider."Feed Type" := FeedType;
        CorpCardProvider.Modify(true);
        CreateCorpCardSetup.EnsureDataExchangeForProvider(CorpCardProvider);
    end;

    local procedure InitializeCorpCards()
    var
        CorpCard: Record "EA Corp Card";
        ExpenseUser: Record "Expense User";
        CardSequenceNo: Integer;
    begin
        ExpenseUser.FindSet();
        repeat
            CardSequenceNo += 1;
            CorpCard.Init();
            CorpCard."Card Id" := GetCorpCardId(CardSequenceNo);
            CorpCard."Provider Code" := CorpCardCsvProviderCodeTok;
            CorpCard."Expense User No." := ExpenseUser."No.";
            CorpCard.Insert(true);
        until (ExpenseUser.Next() = 0) or (CardSequenceNo = GetCorpCardCount());
    end;

    internal procedure SetCsvProviderSourcePayload()
    begin
        SetProviderSourcePayload(CorpCardCsvProviderCodeTok, GetCsvProviderSourcePayload(), CorpCardCsvSampleFileNameTok);
    end;

    local procedure GetCsvProviderSourcePayload(): Text
    var
        CsvPayloadBuilder: TextBuilder;
        TransactionNo: Integer;
    begin
        CsvPayloadBuilder.AppendLine('ProviderTransId,CardId,TransDate,PostingDate,Amount,CurrencyCode,MerchantRaw,MCC,Country,Notes');
        for TransactionNo := 1 to GetCorpCardTransactionCount() do
            CsvPayloadBuilder.AppendLine(
#pragma warning disable AA0217
                StrSubstNo(
                    'TXN%1,%2,2026-06-02,2026-06-03,19.63,USD,Contoso Air,4511,US,Test transaction %1',
                    PadNumberLeft(TransactionNo, 5), GetCorpCardId(((TransactionNo - 1) mod GetCorpCardCount()) + 1)));
#pragma warning restore AA0217
        exit(CsvPayloadBuilder.ToText());
    end;

    local procedure GetXmlProviderSourcePayload(): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<CorporateCardTransactions>' +
                '<Transaction>' +
                    '<ProviderTransId>XMLTXN0001</ProviderTransId>' +
                    '<CardId>' + GetCorpCardId(1) + '</CardId>' +
                    '<TransDate>2026-06-02</TransDate>' +
                    '<PostingDate>2026-06-03</PostingDate>' +
                    '<Amount>19.63</Amount>' +
                    '<CurrencyCode>USD</CurrencyCode>' +
                    '<MerchantRaw>Contoso Air</MerchantRaw>' +
                    '<MCC>4511</MCC>' +
                    '<Country>US</Country>' +
                    '<Notes>Test transaction</Notes>' +
                '</Transaction>' +
            '</CorporateCardTransactions>');
    end;

    local procedure GetCorpCardId(CardSequenceNo: Integer): Code[50]
    begin
#pragma warning disable AA0217
        exit(CopyStr(StrSubstNo('CORPCARD-%1', PadNumberLeft(CardSequenceNo, 4)), 1, 50));
#pragma warning restore AA0217
    end;

    local procedure GetCorpCardCount(): Integer
    begin
        exit(6);
    end;

    local procedure GetCorpCardTransactionCount(): Integer
    begin
        exit(60);
    end;

    local procedure PadNumberLeft(Value: Integer; TotalLength: Integer): Text
    var
        ValueTxt: Text;
    begin
        ValueTxt := Format(Value);
        while StrLen(ValueTxt) < TotalLength do
            ValueTxt := '0' + ValueTxt;

        exit(ValueTxt);
    end;

    internal procedure DeleteCorpCardTransactionalData()
    var
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardSettlementLine: Record "EA Corp Card Settlement Line";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        CorpCardTransDetail.DeleteAll();
        CorpCardException.DeleteAll();
        CorpCardSettlementLine.DeleteAll();
        CorpCardSettlement.DeleteAll();
        CorpCardTrans.DeleteAll();
        CorpCardStatement.DeleteAll();
    end;

    internal procedure RunImportAndGetLastStatement(ProviderCode: Code[20]; var CorpCardStatement: Record "EA Corp Card Statement")
    var
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
    begin
        CorpCardFeedMgt.RunImport(ProviderCode);

        CorpCardStatement.Reset();
        CorpCardStatement.SetRange("Provider Code", ProviderCode);
        Assert.IsTrue(CorpCardStatement.FindLast(), StrSubstNo(NoStatementCreatedForProviderTxt, ProviderCode));
    end;

    internal procedure EnsureCorpCardProvider(ProviderCode: Code[20])
    var
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        if CorpCardProvider.Get(ProviderCode) then
            exit;

        CorpCardProvider.Init();
        CorpCardProvider.Code := ProviderCode;
        CorpCardProvider.Description := ProviderCode;
        CorpCardProvider.Insert(true);
    end;

    internal procedure EnsureBankAccountPostingGroupAccount(BankAccount: Record "Bank Account")
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        GLAccount: Record "G/L Account";
    begin
        BankAccount.TestField("Bank Acc. Posting Group");
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
        if BankAccountPostingGroup."G/L Account No." <> '' then
            exit;

        LibraryERM.CreateGLAccount(GLAccount);
        BankAccountPostingGroup.Validate("G/L Account No.", GLAccount."No.");
        BankAccountPostingGroup.Modify(true);
    end;

    internal procedure CountTransForStatement(StatementEntryNo: Integer; ProviderCode: Code[20]): Integer
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        CorpCardTrans.SetRange("Statement Entry No.", StatementEntryNo);
        CorpCardTrans.SetRange("Provider Code", ProviderCode);
        exit(CorpCardTrans.Count());
    end;

    internal procedure CountTransDetailsForStatement(StatementEntryNo: Integer; ProviderCode: Code[20]): Integer
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        DetailCount: Integer;
    begin
        CorpCardTrans.SetRange("Statement Entry No.", StatementEntryNo);
        CorpCardTrans.SetRange("Provider Code", ProviderCode);
        if not CorpCardTrans.FindSet() then
            exit(0);

        repeat
            CorpCardTransDetail.SetRange("Trans Entry No.", CorpCardTrans."Entry No.");
            DetailCount += CorpCardTransDetail.Count();
        until CorpCardTrans.Next() = 0;

        exit(DetailCount);
    end;

    internal procedure FindTransInStatementByProviderTransId(StatementEntryNo: Integer; ProviderCode: Code[20]; ProviderTransId: Code[100]; var CorpCardTrans: Record "EA Corp Card Trans")
    begin
        CorpCardTrans.Reset();
        CorpCardTrans.SetRange("Statement Entry No.", StatementEntryNo);
        CorpCardTrans.SetRange("Provider Code", ProviderCode);
        CorpCardTrans.SetRange("Provider Trans Id", ProviderTransId);
        Assert.IsTrue(CorpCardTrans.FindFirst(), StrSubstNo(ProviderTransactionNotImportedTxt, ProviderTransId, ProviderCode));
    end;

    internal procedure SumExpenseVatSpecAmounts(ExpenseNo: Code[20]): Decimal
    var
        ExpenseVATSpecification: Record "Expense VAT Specification";
    begin
        ExpenseVATSpecification.SetRange("Expense No.", ExpenseNo);
        ExpenseVATSpecification.CalcSums(Amount);
        exit(ExpenseVATSpecification.Amount);
    end;

    internal procedure SetProviderSourcePayload(ProviderCode: Code[20]; SourcePayload: Text; SourceFileName: Text[250])
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        PayloadOutStream: OutStream;
    begin
        Assert.IsTrue(CorpCardProvider.Get(ProviderCode), StrSubstNo(ProviderNotFoundTxt, ProviderCode));

        Clear(CorpCardProvider."Source Payload");
        CorpCardProvider."Source Payload".CreateOutStream(PayloadOutStream, TextEncoding::UTF8);
        PayloadOutStream.WriteText(SourcePayload);
        Clear(PayloadOutStream);
        CorpCardProvider."Source File Name" := SourceFileName;
        CorpCardProvider.UpdateSourcePayloadRecordCount();
        CorpCardProvider.Modify(true);
    end;

    local procedure EnsureCurrencyExchangeRate(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if not Currency.Get(CurrencyCode) then begin
            Currency.Init();
            Currency.Validate(Code, CurrencyCode);
            Currency.Insert(true);
        end;

        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.DeleteAll();

        CurrencyExchangeRate.Init();
        CurrencyExchangeRate.Validate("Currency Code", CurrencyCode);
        CurrencyExchangeRate.Validate("Starting Date", DMY2Date(1, 1, 2000));
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Currency Code", '');
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", 1);
        CurrencyExchangeRate.Insert(true);
    end;
}
