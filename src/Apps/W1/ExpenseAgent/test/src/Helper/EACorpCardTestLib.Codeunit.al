// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148338 EACorpCardTestLib
{
    var
        Assert: Codeunit "Assert";
        LibraryExpense: Codeunit "Library - Expense";

    internal procedure InitializeCorpCardData()
    var
        ExpenseUser: Record "Expense User";
        CreateCorpCardSetup: Codeunit EACreateCorpCardSetup;
        CreateCorpCardL3Demo: Codeunit EACreateCorpCardL3Demo;
    begin
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();
        DeleteCorpCardTransactionalData();

        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CreateCorpCardSetup.CreateDefaults();
        CreateCorpCardL3Demo.CreateDefaults();
    end;

    internal procedure DeleteCorpCardTransactionalData()
    var
        CorpCardTransDetail: Record EACorpCardTransDetail;
        CorpCardException: Record EACorpCardException;
        CorpCardTrans: Record EACorpCardTrans;
        CorpCardBatch: Record EACorpCardBatch;
    begin
        CorpCardTransDetail.DeleteAll();
        CorpCardException.DeleteAll();
        CorpCardTrans.DeleteAll();
        CorpCardBatch.DeleteAll();
    end;

    internal procedure RunImportAndGetLastBatch(ProviderCode: Code[20]; var CorpCardBatch: Record EACorpCardBatch)
    var
        CorpCardFeedMgt: Codeunit EACorpCardFeedMgt;
    begin
        CorpCardFeedMgt.RunImport(ProviderCode);

        CorpCardBatch.Reset();
        CorpCardBatch.SetRange("Provider Code", ProviderCode);
        Assert.IsTrue(CorpCardBatch.FindLast(), StrSubstNo('No batch was created for provider %1.', ProviderCode));
    end;

    internal procedure CountTransForBatch(BatchNo: Integer; ProviderCode: Code[20]): Integer
    var
        CorpCardTrans: Record EACorpCardTrans;
    begin
        CorpCardTrans.SetRange("Batch No.", BatchNo);
        CorpCardTrans.SetRange("Provider Code", ProviderCode);
        exit(CorpCardTrans.Count());
    end;

    internal procedure CountTransDetailsForBatch(BatchNo: Integer; ProviderCode: Code[20]): Integer
    var
        CorpCardTrans: Record EACorpCardTrans;
        CorpCardTransDetail: Record EACorpCardTransDetail;
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

    internal procedure FindTransInBatchByProviderTransId(BatchNo: Integer; ProviderCode: Code[20]; ProviderTransId: Code[100]; var CorpCardTrans: Record EACorpCardTrans)
    begin
        CorpCardTrans.Reset();
        CorpCardTrans.SetRange("Batch No.", BatchNo);
        CorpCardTrans.SetRange("Provider Code", ProviderCode);
        CorpCardTrans.SetRange("Provider Trans Id", ProviderTransId);
        Assert.IsTrue(CorpCardTrans.FindFirst(), StrSubstNo('Provider transaction %1 was not imported for provider %2.', ProviderTransId, ProviderCode));
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
        CorpCardProvider: Record EACorpCardProvider;
        PayloadOutStream: OutStream;
    begin
        Assert.IsTrue(CorpCardProvider.Get(ProviderCode), StrSubstNo('Provider %1 was not found.', ProviderCode));

        Clear(CorpCardProvider."Source Payload");
        CorpCardProvider."Source Payload".CreateOutStream(PayloadOutStream, TextEncoding::UTF8);
        PayloadOutStream.WriteText(SourcePayload);
        CorpCardProvider."Source File Name" := SourceFileName;
        CorpCardProvider.Modify(true);
    end;
}
