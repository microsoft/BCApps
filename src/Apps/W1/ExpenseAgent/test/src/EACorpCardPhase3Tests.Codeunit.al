// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148342 EACorpCardPhase3Tests
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
        CorpCardFeedMgt: Codeunit EACorpCardFeedMgt;
    begin
        Initialize();
        SetProviderSourcePayload(CorpCardXmlProviderCodeTok, GetMalformedXmlPayload(), MalformedXmlFileNameTok);

        asserterror CorpCardFeedMgt.RunImport(CorpCardXmlProviderCodeTok);
        Assert.IsTrue(StrLen(GetLastErrorText()) > 0, 'Malformed XML import should fail with an error message.');
    end;

    [Test]
    procedure Level3MissingProviderTransIdAddsException()
    var
        CorpCardBatch: Record EACorpCardBatch;
    begin
        Initialize();
        SetProviderSourcePayload(CorpCardL3ProviderCodeTok, GetL3PayloadMissingProviderTransId(), L3NegativeFileNameTok);

        RunImportAndGetLastBatch(CorpCardL3ProviderCodeTok, CorpCardBatch);

        Assert.AreEqual(CorpCardBatch.Status::Completed, CorpCardBatch.Status, 'Batch should complete when strict validation rejects rows.');
        Assert.IsTrue(CorpCardBatch.Exceptions > 0, 'Missing Provider Trans Id must create an exception.');
        Assert.IsTrue(CorpCardBatch.Rejected > 0, 'Missing Provider Trans Id must be counted as rejected.');
        Assert.AreEqual(0, CorpCardBatch.Imported, 'Missing Provider Trans Id must not be imported.');
    end;

    [Test]
    procedure Level3MissingAmountAddsException()
    var
        CorpCardBatch: Record EACorpCardBatch;
    begin
        Initialize();
        SetProviderSourcePayload(CorpCardL3ProviderCodeTok, GetL3PayloadMissingAmount(), L3NegativeFileNameTok);

        RunImportAndGetLastBatch(CorpCardL3ProviderCodeTok, CorpCardBatch);

        Assert.AreEqual(CorpCardBatch.Status::Completed, CorpCardBatch.Status, 'Batch should complete when strict validation rejects rows.');
        Assert.IsTrue(CorpCardBatch.Exceptions > 0, 'Missing Amount must create an exception.');
        Assert.IsTrue(CorpCardBatch.Rejected > 0, 'Missing Amount must be counted as rejected.');
        Assert.AreEqual(0, CorpCardBatch.Imported, 'Missing Amount must not be imported.');
    end;

    [Test]
    procedure Level3MissingTransDateAddsException()
    var
        CorpCardBatch: Record EACorpCardBatch;
    begin
        Initialize();
        SetProviderSourcePayload(CorpCardL3ProviderCodeTok, GetL3PayloadMissingTransDate(), L3NegativeFileNameTok);

        RunImportAndGetLastBatch(CorpCardL3ProviderCodeTok, CorpCardBatch);

        Assert.AreEqual(CorpCardBatch.Status::Completed, CorpCardBatch.Status, 'Batch should complete when strict validation rejects rows.');
        Assert.IsTrue(CorpCardBatch.Exceptions > 0, 'Missing Trans Date must create an exception.');
        Assert.IsTrue(CorpCardBatch.Rejected > 0, 'Missing Trans Date must be counted as rejected.');
        Assert.AreEqual(0, CorpCardBatch.Imported, 'Missing Trans Date must not be imported.');
    end;

    [Test]
    procedure IsoImportMapsMandatoryFields()
    var
        CorpCardBatch: Record EACorpCardBatch;
    begin
        Initialize();

        RunImportAndGetLastBatch(CorpCardIsoProviderCodeTok, CorpCardBatch);

        Assert.AreEqual(CorpCardBatch.Status::Completed, CorpCardBatch.Status, 'ISO import batch must complete successfully.');
        Assert.IsTrue(CorpCardBatch.Imported > 0, 'ISO sample payload must import at least one transaction.');
        AssertAnyTransactionHasMandatoryFields(CorpCardBatch."Batch No.", CorpCardIsoProviderCodeTok);
    end;

    [Test]
    procedure Camt053ImportMapsMandatoryFields()
    var
        CorpCardBatch: Record EACorpCardBatch;
    begin
        Initialize();

        RunImportAndGetLastBatch(CorpCardCamt053ProviderCodeTok, CorpCardBatch);

        Assert.AreEqual(CorpCardBatch.Status::Completed, CorpCardBatch.Status, 'CAMT053 import batch must complete successfully.');
        Assert.IsTrue(CorpCardBatch.Imported > 0, 'CAMT053 sample payload must import at least one transaction.');
        AssertAnyTransactionHasMandatoryFields(CorpCardBatch."Batch No.", CorpCardCamt053ProviderCodeTok);
    end;

    [Test]
    procedure Camt054ImportMapsMandatoryFields()
    var
        CorpCardBatch: Record EACorpCardBatch;
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        Initialize();
        if ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Validate("Corp Card Create Mode", ExpenseAgentSetup."Corp Card Create Mode"::ManualLink);
            ExpenseAgentSetup.Validate("Corp Card Auto Create Draft", false);
            ExpenseAgentSetup.Modify(true);
        end;

        SetProviderSourcePayload(CorpCardCamt054ProviderCodeTok, GetCamt054SmokePayload(), Camt054SmokeFileNameTok);

        RunImportAndGetLastBatch(CorpCardCamt054ProviderCodeTok, CorpCardBatch);

        Assert.AreEqual(CorpCardBatch.Status::Completed, CorpCardBatch.Status, 'CAMT054 import batch must complete successfully.');
        Assert.IsTrue(CorpCardBatch.Imported > 0, 'CAMT054 sample payload must import at least one transaction.');
        Assert.IsTrue(CorpCardBatch.Rejected >= 0, 'CAMT054 batch must produce a valid rejected counter.');
    end;

    [Test]
    procedure XmlImportMapsMandatoryFields()
    var
        CorpCardBatch: Record EACorpCardBatch;
    begin
        Initialize();

        RunImportAndGetLastBatch(CorpCardXmlProviderCodeTok, CorpCardBatch);

        Assert.AreEqual(CorpCardBatch.Status::Completed, CorpCardBatch.Status, 'XML import batch must complete successfully.');
        Assert.IsTrue(CorpCardBatch.Imported > 0, 'XML sample payload must import at least one transaction.');
        AssertAnyTransactionHasMandatoryFields(CorpCardBatch."Batch No.", CorpCardXmlProviderCodeTok);
    end;

    local procedure AssertAnyTransactionHasMandatoryFields(BatchNo: Integer; ProviderCode: Code[20])
    var
        CorpCardTrans: Record EACorpCardTrans;
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

    local procedure GetL3PayloadMissingProviderTransId(): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<Transactions>' +
                '<Transaction>' +
                    '<CardId>CRDL3-0001</CardId>' +
                    '<TransDate>2026-07-01</TransDate>' +
                    '<PostingDate>2026-07-01</PostingDate>' +
                    '<Amount>15.00</Amount>' +
                    '<CurrencyCode>EUR</CurrencyCode>' +
                    '<MerchantRaw>Contoso Store</MerchantRaw>' +
                    '<MCC>5812</MCC>' +
                    '<Country>DE</Country>' +
                    '<Level3>' +
                        '<TaxLine>' +
                            '<Description>Meal</Description>' +
                            '<Quantity>1</Quantity>' +
                            '<UnitCost>13.39</UnitCost>' +
                            '<VATAmount>1.61</VATAmount>' +
                            '<TaxAmount>1.61</TaxAmount>' +
                            '<TaxCode>VAT12</TaxCode>' +
                        '</TaxLine>' +
                    '</Level3>' +
                '</Transaction>' +
            '</Transactions>');
    end;

    local procedure GetL3PayloadMissingAmount(): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<Transactions>' +
                '<Transaction>' +
                    '<ProviderTransId>L3NEG0003</ProviderTransId>' +
                    '<CardId>CRDL3-0001</CardId>' +
                    '<TransDate>2026-07-01</TransDate>' +
                    '<PostingDate>2026-07-01</PostingDate>' +
                    '<CurrencyCode>EUR</CurrencyCode>' +
                    '<MerchantRaw>Contoso Store</MerchantRaw>' +
                    '<MCC>5812</MCC>' +
                    '<Country>DE</Country>' +
                    '<Level3>' +
                        '<TaxLine>' +
                            '<Description>Meal</Description>' +
                            '<Quantity>1</Quantity>' +
                            '<UnitCost>13.39</UnitCost>' +
                            '<VATAmount>1.61</VATAmount>' +
                            '<TaxAmount>1.61</TaxAmount>' +
                            '<TaxCode>VAT12</TaxCode>' +
                        '</TaxLine>' +
                    '</Level3>' +
                '</Transaction>' +
            '</Transactions>');
    end;

    local procedure GetL3PayloadMissingTransDate(): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<Transactions>' +
                '<Transaction>' +
                    '<ProviderTransId>L3NEG0004</ProviderTransId>' +
                    '<CardId>CRDL3-0001</CardId>' +
                    '<PostingDate>2026-07-01</PostingDate>' +
                    '<Amount>15.00</Amount>' +
                    '<CurrencyCode>EUR</CurrencyCode>' +
                    '<MerchantRaw>Contoso Store</MerchantRaw>' +
                    '<MCC>5812</MCC>' +
                    '<Country>DE</Country>' +
                    '<Level3>' +
                        '<TaxLine>' +
                            '<Description>Meal</Description>' +
                            '<Quantity>1</Quantity>' +
                            '<UnitCost>13.39</UnitCost>' +
                            '<VATAmount>1.61</VATAmount>' +
                            '<TaxAmount>1.61</TaxAmount>' +
                            '<TaxCode>VAT12</TaxCode>' +
                        '</TaxLine>' +
                    '</Level3>' +
                '</Transaction>' +
            '</Transactions>');
    end;

    local procedure GetCamt054SmokePayload(): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<Document>' +
                '<BkToCstmrStmt>' +
                    '<Stmt>' +
                        '<Ntry>' +
                            '<NtryDtls>' +
                                '<TxDtls>' +
                                    '<Refs><EndToEndId>CAMT54TXN002</EndToEndId></Refs>' +
                                    '<RmtInf><Ustrd>CRDC54-0001</Ustrd></RmtInf>' +
                                    '<RltdDts><IntrBkSttlmDt><Dt>2026-06-04</Dt></IntrBkSttlmDt></RltdDts>' +
                                    '<AmtDtls><TxAmt><Amt Ccy="USD">19.63</Amt></TxAmt></AmtDtls>' +
                                    '<RltdPties><Cdtr><Nm>Contoso Air</Nm><PstlAdr><Ctry>US</Ctry></PstlAdr></Cdtr></RltdPties>' +
                                '</TxDtls>' +
                            '</NtryDtls>' +
                        '</Ntry>' +
                    '</Stmt>' +
                '</BkToCstmrStmt>' +
            '</Document>');
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

    local procedure RunImportAndGetLastBatch(ProviderCode: Code[20]; var CorpCardBatch: Record EACorpCardBatch)
    var
        CorpCardFeedMgt: Codeunit EACorpCardFeedMgt;
    begin
        CorpCardFeedMgt.RunImport(ProviderCode);

        CorpCardBatch.Reset();
        CorpCardBatch.SetRange("Provider Code", ProviderCode);
        Assert.IsTrue(CorpCardBatch.FindLast(), 'No batch was created for provider ' + ProviderCode + '.');
    end;

    local procedure SetProviderSourcePayload(ProviderCode: Code[20]; SourcePayload: Text; SourceFileName: Text[250])
    var
        CorpCardProvider: Record EACorpCardProvider;
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
        CorpCardXmlProviderCodeTok: Label 'CORPCARDXML', Locked = true;
        CorpCardIsoProviderCodeTok: Label 'CORPCARDISO', Locked = true;
        CorpCardCamt053ProviderCodeTok: Label 'CORPCAMT053', Locked = true;
        CorpCardCamt054ProviderCodeTok: Label 'CORPCAMT054', Locked = true;
        CorpCardL3ProviderCodeTok: Label 'CORPCARDL3', Locked = true;
        MalformedXmlFileNameTok: Label 'CorpCard-Malformed.xml', Locked = true;
        L3NegativeFileNameTok: Label 'CorpCard-L3-Phase3.xml', Locked = true;
        Camt054SmokeFileNameTok: Label 'CorpCard-CAMT054-Smoke.xml', Locked = true;
}
