// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148341 EACorpCardL3VATTests
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
    procedure Level3ImportCreatesDetailLines()
    var
        CorpCardBatch: Record EACorpCardBatch;
        DetailCount: Integer;
    begin
        Initialize();

        EACorpCardTestLib.RunImportAndGetLastBatch(CorpCardL3ProviderCodeTok, CorpCardBatch);
        DetailCount := EACorpCardTestLib.CountTransDetailsForBatch(CorpCardBatch."Batch No.", CorpCardL3ProviderCodeTok);

        Assert.AreEqual(CorpCardBatch.Status::Completed, CorpCardBatch.Status, 'L3 import batch must complete successfully.');
        Assert.AreEqual(2, CorpCardBatch.Imported, 'L3 demo payload should import two header transactions.');
        Assert.AreEqual(3, DetailCount, 'L3 demo payload should import three tax detail rows.');
    end;

    [Test]
    procedure CreateDraftFromLevel3TransCreatesExpenseVatSpecs()
    var
        CorpCardBatch: Record EACorpCardBatch;
        CorpCardTrans: Record EACorpCardTrans;
        ExpenseVATSpecification: Record "Expense VAT Specification";
        CorpCardExpWriter: Codeunit EACorpCardExpWriter;
        ExpenseNo: Code[20];
        VatSpecCount: Integer;
        VatSpecAmountTotal: Decimal;
    begin
        Initialize();

        EACorpCardTestLib.RunImportAndGetLastBatch(CorpCardL3ProviderCodeTok, CorpCardBatch);
        EACorpCardTestLib.FindTransInBatchByProviderTransId(CorpCardBatch."Batch No.", CorpCardL3ProviderCodeTok, ProviderTransIdOneTok, CorpCardTrans);

        CorpCardExpWriter.CreateDraftFromTrans(CorpCardTrans, ExpenseNo);

        ExpenseVATSpecification.SetRange("Expense No.", ExpenseNo);
        VatSpecCount := ExpenseVATSpecification.Count();
        VatSpecAmountTotal := EACorpCardTestLib.SumExpenseVatSpecAmounts(ExpenseNo);

        Assert.AreEqual(2, VatSpecCount, 'First L3 transaction should create two VAT specification lines.');
        Assert.AreEqual(245, VatSpecAmountTotal, 'VAT specification total must match the first L3 transaction amount.');
    end;

    [Test]
    procedure Level3ImportWithoutTaxLinesErrors()
    var
        CorpCardFeedMgt: Codeunit EACorpCardFeedMgt;
    begin
        Initialize();
        EACorpCardTestLib.SetProviderSourcePayload(CorpCardL3ProviderCodeTok, GetL3PayloadWithoutDetails(), L3SourceFileNameTok);

        asserterror CorpCardFeedMgt.RunImport(CorpCardL3ProviderCodeTok);
        Assert.ExpectedError(MissingLevel3LineErr);
    end;

    [Test]
    procedure Level3ImportWithMissingCardIdAddsException()
    var
        CorpCardBatch: Record EACorpCardBatch;
    begin
        Initialize();
        EACorpCardTestLib.SetProviderSourcePayload(CorpCardL3ProviderCodeTok, GetL3PayloadMissingCardId(), L3SourceFileNameTok);

        EACorpCardTestLib.RunImportAndGetLastBatch(CorpCardL3ProviderCodeTok, CorpCardBatch);

        Assert.AreEqual(CorpCardBatch.Status::Completed, CorpCardBatch.Status, 'Batch should complete even when strict validation rejects the row.');
        Assert.AreEqual(0, CorpCardBatch.Imported, 'Invalid strict L3 row should not be imported.');
        Assert.AreEqual(1, CorpCardBatch.Exceptions, 'Invalid strict L3 row should produce one exception.');
        Assert.AreEqual(1, CorpCardBatch.Rejected, 'Invalid strict L3 row should be counted as rejected.');
    end;

    local procedure GetL3PayloadWithoutDetails(): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<Transactions>' +
                '<Transaction>' +
                    '<ProviderTransId>L3NEG0001</ProviderTransId>' +
                    '<CardId>CRDL3-0001</CardId>' +
                    '<TransDate>2026-07-01</TransDate>' +
                    '<PostingDate>2026-07-01</PostingDate>' +
                    '<Amount>10.00</Amount>' +
                    '<CurrencyCode>EUR</CurrencyCode>' +
                    '<MerchantRaw>Contoso Store</MerchantRaw>' +
                    '<MCC>5812</MCC>' +
                    '<Country>DE</Country>' +
                '</Transaction>' +
            '</Transactions>');
    end;

    local procedure GetL3PayloadMissingCardId(): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<Transactions>' +
                '<Transaction>' +
                    '<ProviderTransId>L3NEG0002</ProviderTransId>' +
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

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::EACorpCardL3VATTests);
        EACorpCardTestLib.InitializeCorpCardData();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::EACorpCardL3VATTests);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateVATBusinessPostingGroupInAgentSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::EACorpCardL3VATTests);
    end;

    var
        CorpCardL3ProviderCodeTok: Label 'CORPCARDL3', Locked = true;
        ProviderTransIdOneTok: Label 'L3TXN0001', Locked = true;
        L3SourceFileNameTok: Label 'CorpCard-Level3-Negative.xml', Locked = true;
        MissingLevel3LineErr: Label 'no parsed rows for detail line', Locked = true;
}
