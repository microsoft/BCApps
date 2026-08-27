// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;

codeunit 148347 EACorpCardTestLib
{
    var
        Assert: Codeunit "Assert";
        LibraryExpense: Codeunit "Library - Expense";
        NoBatchCreatedForProviderTxt: Label 'No batch was created for provider %1.', Comment = '%1 = provider code', Locked = true;
        ProviderTransactionNotImportedTxt: Label 'Provider transaction %1 was not imported for provider %2.', Comment = '%1 = provider transaction ID, %2 = provider code', Locked = true;
        ProviderNotFoundTxt: Label 'Provider %1 was not found.', Comment = '%1 = provider code', Locked = true;

    internal procedure InitializeCorpCardData()
    var
        ExpenseUser: Record "Expense User";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
        CreateCorpCardL3Demo: Codeunit "EA Create Corp Card L3 Demo";
    begin
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();
        DeleteCorpCardTransactionalData();

        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CreateCorpCardSetup.CreateDefaults();
        CreateCorpCardL3Demo.CreateDefaults();
        EnsureCurrencyExchangeRate('USD');
        EnsureCurrencyExchangeRate('EUR');
    end;

    internal procedure DeleteCorpCardTransactionalData()
    var
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardBatch: Record "EA Corp Card Batch";
    begin
        CorpCardTransDetail.DeleteAll();
        CorpCardException.DeleteAll();
        CorpCardTrans.DeleteAll();
        CorpCardBatch.DeleteAll();
    end;

    internal procedure RunImportAndGetLastBatch(ProviderCode: Code[20]; var CorpCardBatch: Record "EA Corp Card Batch")
    var
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
    begin
        CorpCardFeedMgt.RunImport(ProviderCode);

        CorpCardBatch.Reset();
        CorpCardBatch.SetRange("Provider Code", ProviderCode);
        Assert.IsTrue(CorpCardBatch.FindLast(), StrSubstNo(NoBatchCreatedForProviderTxt, ProviderCode));
    end;

    internal procedure CountTransForBatch(BatchNo: Integer; ProviderCode: Code[20]): Integer
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        CorpCardTrans.SetRange("Batch No.", BatchNo);
        CorpCardTrans.SetRange("Provider Code", ProviderCode);
        exit(CorpCardTrans.Count());
    end;

    internal procedure CountTransDetailsForBatch(BatchNo: Integer; ProviderCode: Code[20]): Integer
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        DetailCount: Integer;
    begin
        CorpCardTrans.SetRange("Batch No.", BatchNo);
        CorpCardTrans.SetRange("Provider Code", ProviderCode);
        if not CorpCardTrans.FindSet() then
            exit(0);

        repeat
            CorpCardTransDetail.SetRange("Trans Entry No.", CorpCardTrans."Entry No.");
            DetailCount += CorpCardTransDetail.Count();
        until CorpCardTrans.Next() = 0;

        exit(DetailCount);
    end;

    internal procedure FindTransInBatchByProviderTransId(BatchNo: Integer; ProviderCode: Code[20]; ProviderTransId: Code[100]; var CorpCardTrans: Record "EA Corp Card Trans")
    begin
        CorpCardTrans.Reset();
        CorpCardTrans.SetRange("Batch No.", BatchNo);
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
        CorpCardProvider."Source File Name" := SourceFileName;
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
