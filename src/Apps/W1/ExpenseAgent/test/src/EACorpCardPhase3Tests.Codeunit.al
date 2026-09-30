// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.IO;

codeunit 148353 EACorpCardPhase3Tests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        EACorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    procedure XmlImportWithMalformedPayloadFailsBatch()
    var
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
    begin
        Initialize();
        SetProviderSourcePayload(CorpCardXmlProviderCodeTok, GetMalformedXmlPayload(), MalformedXmlFileNameTok);

        asserterror CorpCardFeedMgt.RunImport(CorpCardXmlProviderCodeTok);
        Assert.ExpectedError(MalformedXmlRootElementTok);

        CorpCardProvider.Get(CorpCardXmlProviderCodeTok);
        CorpCardProvider.CalcFields("Source Payload");
        Assert.IsFalse(CorpCardProvider."Source Payload".HasValue(), 'Failed imports must clear the source payload.');
        Assert.AreEqual(0, CorpCardProvider."Source Payload Record Count", 'Failed imports must clear the source payload record count.');

        CorpCardBatch.SetRange("Provider Code", CorpCardXmlProviderCodeTok);
        Assert.IsTrue(CorpCardBatch.FindLast(), 'Failed import must create a batch.');
        Assert.AreEqual(CorpCardBatch.Status::Failed, CorpCardBatch.Status, 'Failed imports must finalize the batch as failed.');
        Assert.IsTrue(CorpCardBatch."Ended DT" <> 0DT, 'Failed imports must record the batch end date and time.');
        Assert.AreEqual(CorpCardBatch."Batch No.", CorpCardProvider."Last Batch No.", 'Failed imports must update the provider with the failed batch number.');
    end;

    [Test]
    procedure ImportClearsSourcePayloadAndRetainsMetadata()
    var
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        Initialize();

        RunImportAndGetLastBatch(CorpCardCsvProviderCodeTok, CorpCardBatch);

        CorpCardProvider.Get(CorpCardCsvProviderCodeTok);
        CorpCardProvider.CalcFields("Source Payload");
        Assert.IsFalse(CorpCardProvider."Source Payload".HasValue(), 'Successful imports must clear the source payload.');
        Assert.AreEqual(0, CorpCardProvider."Source Payload Record Count", 'Successful imports must clear the source payload record count.');
        Assert.AreEqual(CorpCardCsvSampleFileNameTok, CorpCardProvider."Source File Name", 'Successful imports must retain the source file name.');
        Assert.AreEqual(CorpCardCsvSampleFileNameTok, CorpCardBatch."Source File Name", 'The batch must retain the source file name.');
        Assert.IsTrue(CorpCardBatch."Source Payload Hash" <> '', 'The batch must retain the source payload hash.');
        Assert.AreEqual(0, CorpCardBatch."Data Exch Entry No.", 'Successful imports must remove the temporary data exchange record.');
    end;

    [Test]
    procedure ResolvingExceptionStampsAuditFields()
    var
        CorpCardException: Record "EA Corp Card Exception";
        ResolvedBy: Code[50];
        ResolvedDT: DateTime;
    begin
        Initialize();

        CorpCardException.Init();
        CorpCardException.Insert(true);
        CorpCardException.Resolved := true;
        CorpCardException.Modify(true);

        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(CorpCardException."Resolved By")), CorpCardException."Resolved By", 'Resolving an exception must record the current user.');
        Assert.IsTrue(CorpCardException."Resolved DT" <> 0DT, 'Resolving an exception must record the resolution date and time.');
        ResolvedBy := CorpCardException."Resolved By";
        ResolvedDT := CorpCardException."Resolved DT";

        CorpCardException."Resolved By" := 'MANUAL';
        Clear(CorpCardException."Resolved DT");
        CorpCardException.Modify(true);

        Assert.AreEqual(ResolvedBy, CorpCardException."Resolved By", 'Resolution user must not be overwritten after the exception is resolved.');
        Assert.AreEqual(ResolvedDT, CorpCardException."Resolved DT", 'Resolution date and time must not be overwritten after the exception is resolved.');

        CorpCardException.Resolved := false;
        CorpCardException.Modify(true);

        Assert.AreEqual('', CorpCardException."Resolved By", 'Reopening an exception must clear the resolution user.');
        Assert.AreEqual(0DT, CorpCardException."Resolved DT", 'Reopening an exception must clear the resolution date and time.');
    end;

    [Test]
    procedure DeletingTransactionDeletesOwnedDetailsAndExceptions()
    var
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
    begin
        Initialize();
        CreateCleanupTestRecords(CorpCardBatch, CorpCardTrans, CorpCardTransDetail, CorpCardException);

        CorpCardTrans.Delete(true);

        CorpCardTransDetail.SetRange("Trans Entry No.", CorpCardTrans."Entry No.");
        Assert.IsTrue(CorpCardTransDetail.IsEmpty(), 'Deleting a transaction must delete its detail lines.');
        CorpCardException.SetRange("Trans Entry No.", CorpCardTrans."Entry No.");
        Assert.IsTrue(CorpCardException.IsEmpty(), 'Deleting a transaction must delete its exceptions.');
    end;

    [Test]
    procedure DeletingBatchDeletesOwnedTransactionsDetailsAndExceptions()
    var
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        TransEntryNo: Integer;
    begin
        Initialize();
        CreateCleanupTestRecords(CorpCardBatch, CorpCardTrans, CorpCardTransDetail, CorpCardException);
        TransEntryNo := CorpCardTrans."Entry No.";

        CorpCardBatch.Delete(true);

        CorpCardTrans.SetRange("Batch No.", CorpCardBatch."Batch No.");
        Assert.IsTrue(CorpCardTrans.IsEmpty(), 'Deleting a batch must delete its transactions.');
        CorpCardTransDetail.SetRange("Trans Entry No.", TransEntryNo);
        Assert.IsTrue(CorpCardTransDetail.IsEmpty(), 'Deleting a batch must delete transaction detail lines.');
        CorpCardException.SetRange("Batch No.", CorpCardBatch."Batch No.");
        Assert.IsTrue(CorpCardException.IsEmpty(), 'Deleting a batch must delete its exceptions.');
    end;

    [Test]
    procedure DeletingProviderDoesNotDeleteSharedDataExchangeDefinition()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        SharedCorpCardProvider: Record "EA Corp Card Provider";
        DataExchDef: Record "Data Exch. Def";
        SharedDataExchDefCode: Code[20];
    begin
        Initialize();

        SharedCorpCardProvider.Get(CorpCardXmlProviderCodeTok);
        SharedDataExchDefCode := SharedCorpCardProvider."Data Exch Def Code";
        DataExchDef.Get(SharedDataExchDefCode);

        CorpCardProvider.Init();
        CorpCardProvider.Code := SharedDefinitionTestProviderCodeTok;
        CorpCardProvider.Description := 'Shared definition deletion test';
        CorpCardProvider."Data Exch Def Code" := SharedDataExchDefCode;
        CorpCardProvider.Insert(true);

        CorpCardProvider.Delete(true);

        Assert.IsTrue(DataExchDef.Get(SharedDataExchDefCode), 'Deleting a provider must not delete a shared Data Exchange definition.');
        Assert.IsTrue(SharedCorpCardProvider.Get(CorpCardXmlProviderCodeTok), 'Deleting a provider must not affect another provider that uses the shared definition.');
    end;

    [Test]
    procedure XmlImportMapsMandatoryFields()
    var
        CorpCardBatch: Record "EA Corp Card Batch";
    begin
        Initialize();

        RunImportAndGetLastBatch(CorpCardXmlProviderCodeTok, CorpCardBatch);

        Assert.AreEqual(CorpCardBatch.Status::Completed, CorpCardBatch.Status, 'XML import batch must complete successfully.');
        Assert.IsTrue(CorpCardBatch.Imported > 0, 'XML sample payload must import at least one transaction.');
        AssertAnyTransactionHasMandatoryFields(CorpCardBatch."Batch No.", CorpCardXmlProviderCodeTok);
    end;

    local procedure AssertAnyTransactionHasMandatoryFields(BatchNo: Integer; ProviderCode: Code[20])
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        FoundMapped: Boolean;
    begin
        CorpCardTrans.SetRange("Batch No.", BatchNo);
        CorpCardTrans.SetRange("Provider Code", ProviderCode);
        if CorpCardTrans.FindSet() then
            repeat
                if (CorpCardTrans."Provider Trans Id" <> '') and
                   (CorpCardTrans."Card Id" <> '') and
                         (CorpCardTrans."Trans Date" <> 0D)
                then begin
                    FoundMapped := true;
                    break;
                end;
            until CorpCardTrans.Next() = 0;

        Assert.IsTrue(FoundMapped, 'No transaction with mandatory mapped fields found for provider ' + ProviderCode + ' in batch ' + Format(BatchNo) + '.');
    end;

    local procedure GetMalformedXmlPayload(): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<CorporateCardTransactions>' +
                '<Transaction>' +
                    '<ProviderTransId>XMLNEG0001</ProviderTransId>' +
                    '<CardId>CRDXML-0001</CardId>' +
                    '<TransDate>2026-07-01</TransDate>' +
                    '<PostingDate>2026-07-01</PostingDate>' +
                    '<Amount>19.63</Amount>' +
                    '<CurrencyCode>USD</CurrencyCode>' +
                    '<MerchantRaw>Broken XML Merchant</MerchantRaw>' +
                    '<MCC>4511</MCC>' +
                    '<Country>US</Country>' +
                '</Transaction>');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::EACorpCardPhase3Tests);
        EACorpCardTestLib.InitializeCorpCardData();
        DeleteCorpCardTransactionalData();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::EACorpCardPhase3Tests);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::EACorpCardPhase3Tests);
    end;

    local procedure DeleteCorpCardTransactionalData()
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

    local procedure CreateCleanupTestRecords(var CorpCardBatch: Record "EA Corp Card Batch"; var CorpCardTrans: Record "EA Corp Card Trans"; var CorpCardTransDetail: Record "EA Corp Card Trans Detail"; var CorpCardException: Record "EA Corp Card Exception")
    begin
        CorpCardBatch.Init();
        CorpCardBatch."Provider Code" := CorpCardXmlProviderCodeTok;
        CorpCardBatch.Insert(true);

        CorpCardTrans.Init();
        CorpCardTrans."Batch No." := CorpCardBatch."Batch No.";
        CorpCardTrans."Provider Code" := CorpCardBatch."Provider Code";
        CorpCardTrans."Provider Trans Id" := 'DELETE-TEST';
        CorpCardTrans."Card Id" := 'DELETE-TEST';
        CorpCardTrans."Trans Date" := Today();
        CorpCardTrans.Insert(true);

        CorpCardTransDetail.Init();
        CorpCardTransDetail."Trans Entry No." := CorpCardTrans."Entry No.";
        CorpCardTransDetail."Line No." := 10000;
        CorpCardTransDetail.Insert(true);

        CorpCardException.Init();
        CorpCardException."Batch No." := CorpCardBatch."Batch No.";
        CorpCardException."Trans Entry No." := CorpCardTrans."Entry No.";
        CorpCardException.Insert(true);
    end;

    local procedure RunImportAndGetLastBatch(ProviderCode: Code[20]; var CorpCardBatch: Record "EA Corp Card Batch")
    var
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
    begin
        CorpCardFeedMgt.RunImport(ProviderCode);

        CorpCardBatch.Reset();
        CorpCardBatch.SetRange("Provider Code", ProviderCode);
        Assert.IsTrue(CorpCardBatch.FindLast(), 'No batch was created for provider ' + ProviderCode + '.');
    end;

    local procedure SetProviderSourcePayload(ProviderCode: Code[20]; SourcePayload: Text; SourceFileName: Text[250])
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        PayloadOutStream: OutStream;
    begin
        Assert.IsTrue(CorpCardProvider.Get(ProviderCode), 'Provider ' + ProviderCode + ' was not found.');

        Clear(CorpCardProvider."Source Payload");
        CorpCardProvider."Source Payload".CreateOutStream(PayloadOutStream, TextEncoding::UTF8);
        PayloadOutStream.WriteText(SourcePayload);
        CorpCardProvider."Source File Name" := SourceFileName;
        CorpCardProvider.Modify(true);
    end;

    var
        CorpCardCsvProviderCodeTok: Label 'CORPCARDCSV', Locked = true;
        CorpCardXmlProviderCodeTok: Label 'CORPCARDXML', Locked = true;
        SharedDefinitionTestProviderCodeTok: Label 'SHAREDDEFTEST', Locked = true;
        CorpCardCsvSampleFileNameTok: Label 'CorpCard-Sample-60.csv', Locked = true;
        MalformedXmlRootElementTok: Label 'CorporateCardTransactions', Locked = true;
        MalformedXmlFileNameTok: Label 'CorpCard-Malformed.xml', Locked = true;
}
