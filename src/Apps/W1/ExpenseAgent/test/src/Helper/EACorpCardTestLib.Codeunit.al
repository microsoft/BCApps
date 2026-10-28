// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using System.IO;
using System.Utilities;

codeunit 148357 EACorpCardTestLib
{
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryExpense: Codeunit "Library - Expense";
        SourcePayloads: Dictionary of [Code[20], Text];
        SourceFileNames: Dictionary of [Code[20], Text[250]];
        SourceDataExchEntryNos: Dictionary of [Integer, Integer];
        NoStatementCreatedForProviderTxt: Label 'No statement was created for provider %1.', Comment = '%1 = provider code', Locked = true;
        ProviderTransactionNotImportedTxt: Label 'Provider transaction %1 was not imported for provider %2.', Comment = '%1 = provider transaction ID, %2 = provider code', Locked = true;
        ProviderNotFoundTxt: Label 'Provider %1 was not found.', Comment = '%1 = provider code', Locked = true;
        CorpCardCsvProviderCodeTok: Label 'CORPCARDCSV', Locked = true;
        CorpCardXmlProviderCodeTok: Label 'CORPCARDXML', Locked = true;
        CorpCardXmlSampleCardIdTok: Label 'XML-CARD-SAMPLE', Locked = true;
        CorpCardCsvSampleFileNameTok: Label 'CorpCard-Sample-60.csv', Locked = true;
        CorpCardXmlSampleFileNameTok: Label 'CorpCard-Sample-60.xml', Locked = true;

    internal procedure InitializeCorpCardData()
    var
        CorpCard: Record "EA Corp Card";
        ExpenseUser: Record "Expense User";
        ExpenseUserNo: Integer;
    begin
        Clear(SourcePayloads);
        Clear(SourceFileNames);
        Clear(SourceDataExchEntryNos);
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
            CorpCard."Masked Card No." := CopyStr('****' + PadNumberLeft(CardSequenceNo, 4), 1, MaxStrLen(CorpCard."Masked Card No."));
            CorpCard.Insert(true);
        until (ExpenseUser.Next() = 0) or (CardSequenceNo = GetCorpCardCount());

        CorpCard.Init();
        CorpCard."Card Id" := CorpCardXmlSampleCardIdTok;
        CorpCard."Provider Code" := CorpCardXmlProviderCodeTok;
        CorpCard."Expense User No." := ExpenseUser."No.";
        CorpCard."Masked Card No." := '****9001';
        CorpCard.Insert(true);
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
        CsvPayloadBuilder.AppendLine('ProviderTransId,CardLast4,TransDate,PostingDate,Amount,CurrencyCode,MerchantRaw,MCC,Country,Notes');
        for TransactionNo := 1 to GetCorpCardTransactionCount() do
            CsvPayloadBuilder.AppendLine(
#pragma warning disable AA0217
                StrSubstNo(
                    'TXN%1,%2,2026-06-02,2026-06-03,19.63,USD,Contoso Air,4511,US,Test transaction %1',
                    PadNumberLeft(TransactionNo, 5), PadNumberLeft(((TransactionNo - 1) mod GetCorpCardCount()) + 1, 4)));
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
                    '<CardLast4>9001</CardLast4>' +
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
    begin
        RunFileImport(ProviderCode);

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
    begin
        Assert.IsTrue(CorpCardProvider.Get(ProviderCode), StrSubstNo(ProviderNotFoundTxt, ProviderCode));
        SourcePayloads.Set(ProviderCode, SourcePayload);
        SourceFileNames.Set(ProviderCode, SourceFileName);
    end;

    internal procedure RunFileImport(ProviderCode: Code[20])
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardImportOrch: Codeunit "EA Corp Card Import Orch";
        TempBlob: Codeunit "Temp Blob";
        SourceInStream: InStream;
        SourceFileName: Text[250];
    begin
        CorpCardProvider.Get(ProviderCode);
        WriteSourceFile(ProviderCode, TempBlob, SourceFileName);
        TempBlob.CreateInStream(SourceInStream);
        CorpCardImportOrch.RunFileImport(CorpCardProvider, SourceInStream, SourceFileName);
    end;

    internal procedure HasSourcePayload(ProviderCode: Code[20]): Boolean
    begin
        exit(SourcePayloads.ContainsKey(ProviderCode));
    end;

    internal procedure AssertNoSourceFile(CorpCardStatement: Record "EA Corp Card Statement")
    var
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        SourceDataExchEntryNo: Integer;
    begin
        Assert.IsTrue(
            SourceDataExchEntryNos.Get(CorpCardStatement."Statement Entry No.", SourceDataExchEntryNo),
            'The import must identify its source data exchange record before parsing.');
        Assert.IsFalse(DataExch.Get(SourceDataExchEntryNo), 'Import finalization must delete the source data exchange record.');
        DataExchField.SetRange("Data Exch. No.", SourceDataExchEntryNo);
        Assert.IsTrue(DataExchField.IsEmpty(), 'Import finalization must delete the parsed source fields.');
    end;

    local procedure WriteSourceFile(ProviderCode: Code[20]; var TempBlob: Codeunit "Temp Blob"; var SourceFileName: Text[250])
    var
        PayloadOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(PayloadOutStream, TextEncoding::UTF8);
        PayloadOutStream.WriteText(SourcePayloads.Get(ProviderCode));
        Clear(PayloadOutStream);
        SourceFileName := SourceFileNames.Get(ProviderCode);
        SourcePayloads.Remove(ProviderCode);
        SourceFileNames.Remove(ProviderCode);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EA Corp Card Data Exch Prov", 'OnBeforeInjectSourceContent', '', false, false)]
    local procedure OnBeforeInjectSourceContent(CorpCardProvider: Record "EA Corp Card Provider"; CorpCardStatement: Record "EA Corp Card Statement"; var TempBlob: Codeunit "Temp Blob"; var SourceFileName: Text[250]; var Handled: Boolean)
    begin
        if Handled or not HasSourcePayload(CorpCardProvider.Code) then
            exit;
        WriteSourceFile(CorpCardProvider.Code, TempBlob, SourceFileName);
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EA Corp Card Data Exch Prov", 'OnAfterDownload', '', false, false)]
    local procedure OnAfterDownload(CorpCardProvider: Record "EA Corp Card Provider"; var CorpCardStatement: Record "EA Corp Card Statement"; var DataExch: Record "Data Exch.")
    begin
        SourceDataExchEntryNos.Set(CorpCardStatement."Statement Entry No.", DataExch."Entry No.");
    end;

    internal procedure CreateSettlement(var CorpCardSettlement: Record "EA Corp Card Settlement"; ProviderCode: Code[20]; SettlementNo: Code[50]; CurrencyCode: Code[10]; SettlementAmount: Decimal)
    begin
        CorpCardSettlement.Init();
        CorpCardSettlement.Validate("Provider Code", ProviderCode);
        CorpCardSettlement."Settlement No." := SettlementNo;
        CorpCardSettlement."Settlement Date" := WorkDate();
        CorpCardSettlement."Currency Code" := CurrencyCode;
        CorpCardSettlement."Settlement Amount" := SettlementAmount;
        CorpCardSettlement.Insert(true);
    end;

    internal procedure CreateStatement(var CorpCardStatement: Record "EA Corp Card Statement"; ProviderCode: Code[20]; StatementNo: Code[50]; StatementAmount: Decimal; Status: Enum "EA Corp Card Stmt Status")
    begin
        Clear(CorpCardStatement);
        CorpCardStatement.Init();
        CorpCardStatement."Provider Code" := ProviderCode;
        CorpCardStatement."Statement No." := StatementNo;
        CorpCardStatement."Statement Date" := WorkDate();
        CorpCardStatement."Currency Code" := 'USD';
        CorpCardStatement."Statement Total" := StatementAmount;
        CorpCardStatement.Status := Status;
        CorpCardStatement.Insert(true);
    end;

    internal procedure AddStatementToSettlement(CorpCardSettlement: Record "EA Corp Card Settlement"; CorpCardStatement: Record "EA Corp Card Statement"; LineNo: Integer)
    var
        CorpCardSettlementLine: Record "EA Corp Card Settlement Line";
    begin
        CorpCardSettlementLine.Init();
        CorpCardSettlementLine."Settlement Entry No." := CorpCardSettlement."Settlement Entry No.";
        CorpCardSettlementLine."Line No." := LineNo;
        CorpCardSettlementLine.Validate("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardSettlementLine.Insert(true);
    end;

    internal procedure CreatePostedTransaction(var CorpCardTrans: Record "EA Corp Card Trans"; CorpCardStatement: Record "EA Corp Card Statement"; TransactionAmount: Decimal)
    begin
        CorpCardTrans.Init();
        CorpCardTrans."Statement Entry No." := CorpCardStatement."Statement Entry No.";
        CorpCardTrans."Provider Code" := CorpCardStatement."Provider Code";
        CorpCardTrans."Provider Trans Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));
        CorpCardTrans."Card Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Card Id"));
        CorpCardTrans."Trans Date" := WorkDate();
        CorpCardTrans.Amount := TransactionAmount;
        CorpCardTrans."Currency Code" := CorpCardStatement."Currency Code";
        CorpCardTrans."Expense No." := 'EXP-POSTED';
        CorpCardTrans."Posted Expense Report No." := 'PER-POSTED';
        CorpCardTrans.Status := CorpCardTrans.Status::Posted;
        CorpCardTrans.Insert(true);
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

        LibraryERM.CreateExchangeRate(CurrencyCode, DMY2Date(1, 1, 2000), 1, 1);
    end;
}
