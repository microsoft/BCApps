// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148355 EACorpCardL3VATTests
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
        CorpCardBatch: Record "EA Corp Card Batch";
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
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseVATSpecification: Record "Expense VAT Specification";
        CorpCardExpWriter: Codeunit "EA Corp Card Expense Writer";
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
    procedure BlockedCardCannotMatchTransaction()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardMatchMgt: Codeunit "EA Corp Card Match Mgt";
        ExpenseNo: Code[20];
    begin
        Initialize();

        EACorpCardTestLib.RunImportAndGetLastBatch(CorpCardL3ProviderCodeTok, CorpCardBatch);
        EACorpCardTestLib.FindTransInBatchByProviderTransId(CorpCardBatch."Batch No.", CorpCardL3ProviderCodeTok, ProviderTransIdOneTok, CorpCardTrans);
        BlockCard(CorpCardTrans."Card Id");

        asserterror CorpCardMatchMgt.MatchTransaction(CorpCardTrans, ExpenseNo);
        Assert.ExpectedTestFieldError(CorpCard.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    procedure BlockedCardCannotUseEnhancedMatching()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardEnhMatchMgt: Codeunit "EA Corp Card Enh. Match Mgt";
        ExpenseNo: Code[20];
    begin
        Initialize();

        EACorpCardTestLib.RunImportAndGetLastBatch(CorpCardL3ProviderCodeTok, CorpCardBatch);
        EACorpCardTestLib.FindTransInBatchByProviderTransId(CorpCardBatch."Batch No.", CorpCardL3ProviderCodeTok, ProviderTransIdOneTok, CorpCardTrans);
        BlockCard(CorpCardTrans."Card Id");

        asserterror CorpCardEnhMatchMgt.EnhancedMatchTransaction(CorpCardTrans, ExpenseNo);
        Assert.ExpectedTestFieldError(CorpCard.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    procedure BlockedCardCannotCreateDraft()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardExpWriter: Codeunit "EA Corp Card Expense Writer";
        ExpenseNo: Code[20];
    begin
        Initialize();

        EACorpCardTestLib.RunImportAndGetLastBatch(CorpCardL3ProviderCodeTok, CorpCardBatch);
        EACorpCardTestLib.FindTransInBatchByProviderTransId(CorpCardBatch."Batch No.", CorpCardL3ProviderCodeTok, ProviderTransIdOneTok, CorpCardTrans);
        BlockCard(CorpCardTrans."Card Id");

        asserterror CorpCardExpWriter.CreateDraftFromTrans(CorpCardTrans, ExpenseNo);
        Assert.ExpectedTestFieldError(CorpCard.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    procedure BlockedMCCMappingCannotCategorizeDraft()
    var
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardMCCMap: Record "EA Corp Card MCC Map";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardExpWriter: Codeunit "EA Corp Card Expense Writer";
        ExpenseNo: Code[20];
    begin
        Initialize();

        EACorpCardTestLib.RunImportAndGetLastBatch(CorpCardL3ProviderCodeTok, CorpCardBatch);
        EACorpCardTestLib.FindTransInBatchByProviderTransId(CorpCardBatch."Batch No.", CorpCardL3ProviderCodeTok, ProviderTransIdOneTok, CorpCardTrans);
        CorpCardMCCMap.Get(CorpCardTrans.MCC);
        CorpCardMCCMap.Blocked := true;
        CorpCardMCCMap.Modify(true);

        asserterror CorpCardExpWriter.CreateDraftFromTrans(CorpCardTrans, ExpenseNo);
        Assert.ExpectedTestFieldError(CorpCardMCCMap.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    procedure EnhancedMatchingSupportsZeroAmountTolerance()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CorpCardEnhMatchMgt: Codeunit "EA Corp Card Enh. Match Mgt";
        ExpenseNo: Code[20];
    begin
        Initialize();

        EACorpCardTestLib.RunImportAndGetLastBatch(CorpCardL3ProviderCodeTok, CorpCardBatch);
        EACorpCardTestLib.FindTransInBatchByProviderTransId(CorpCardBatch."Batch No.", CorpCardL3ProviderCodeTok, ProviderTransIdOneTok, CorpCardTrans);
        CorpCard.Get(CorpCardTrans."Card Id");
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Corp Card Amount Tolerance" := 0;
        ExpenseAgentSetup.Modify(true);

        Expense.Init();
        Expense."Expense User No." := CorpCard."Expense User No.";
        Expense.Status := Expense.Status::Open;
        Expense."Expense Date" := CorpCardTrans."Trans Date";
        Expense.Amount := CorpCardTrans.Amount;
        Expense."Currency Code" := CorpCardTrans."Currency Code";
        Expense.Insert(true);

        Assert.IsTrue(CorpCardEnhMatchMgt.EnhancedMatchTransaction(CorpCardTrans, ExpenseNo), 'An exact amount must match when the amount tolerance is zero.');
        Assert.AreEqual(Expense."No.", ExpenseNo, 'Enhanced matching must return the exact matching expense.');
        Assert.AreEqual(100, CorpCardTrans."Match Score", 'An exact amount and date must receive a perfect match score.');
    end;

    [Test]
    procedure MerchantRuleCategoryDoesNotClearMCC()
    var
        CorpCardMerchantRule: Record "EA Corp Card Merchant Rule";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardMerchantNorm: Codeunit "EA Corp Card Merchant Norm";
    begin
        Initialize();

        CorpCardMerchantRule.Pattern := '*MCC preservation merchant*';
        CorpCardMerchantRule."Normalized Name" := 'Normalized Merchant';
        CorpCardMerchantRule."Expense Category" := 'MEALS';
        CorpCardMerchantRule.Priority := 0;
        CorpCardMerchantRule.Active := true;
        CorpCardMerchantRule.Insert(true);

        CorpCardTrans."Merchant Raw" := 'MCC Preservation Merchant';
        CorpCardTrans.MCC := '5812';
        CorpCardMerchantNorm.NormalizeTransaction(CorpCardTrans);

        Assert.AreEqual('Normalized Merchant', CorpCardTrans."Merchant Norm", 'The matching rule must normalize the merchant name.');
        Assert.AreEqual('5812', CorpCardTrans.MCC, 'A merchant rule category must not discard the transaction MCC.');
    end;

    [Test]
    procedure CorpCardReportExcludesManualExpenses()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardExpense: Record Expense;
        CorpCardTrans: Record "EA Corp Card Trans";
        ManualExpense: Record Expense;
        CorpCardExpWriter: Codeunit "EA Corp Card Expense Writer";
        CorpCardReportMgt: Codeunit "EA Corp Card Report Mgt";
        CorpCardExpenseNo: Code[20];
        ReportNo: Code[20];
    begin
        Initialize();

        EACorpCardTestLib.RunImportAndGetLastBatch(CorpCardL3ProviderCodeTok, CorpCardBatch);
        EACorpCardTestLib.FindTransInBatchByProviderTransId(CorpCardBatch."Batch No.", CorpCardL3ProviderCodeTok, ProviderTransIdOneTok, CorpCardTrans);
        CorpCardExpWriter.CreateDraftFromTrans(CorpCardTrans, CorpCardExpenseNo);
        CorpCard.Get(CorpCardTrans."Card Id");

        ManualExpense.Init();
        ManualExpense."Expense User No." := CorpCard."Expense User No.";
        ManualExpense.Status := ManualExpense.Status::Open;
        ManualExpense.Insert(true);

        ReportNo := CorpCardReportMgt.CreateReportFromCorpCardExpenses(CorpCard."Expense User No.");

        CorpCardExpense.Get(CorpCardExpenseNo);
        ManualExpense.Get(ManualExpense."No.");
        Assert.AreEqual(ReportNo, CorpCardExpense."Expense Report No.", 'The corporate card expense must be assigned to the new report.');
        Assert.AreEqual('', ManualExpense."Expense Report No.", 'A manual expense must not be assigned to a corporate card report.');
    end;

    [Test]
    procedure Level3ImportWithoutTaxLinesErrors()
    var
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
    begin
        Initialize();
        EACorpCardTestLib.SetProviderSourcePayload(CorpCardL3ProviderCodeTok, GetL3PayloadWithoutDetails(), L3SourceFileNameTok);

        asserterror CorpCardFeedMgt.RunImport(CorpCardL3ProviderCodeTok);
        Assert.ExpectedError(MissingLevel3LineErr);
    end;

    [Test]
    procedure Level3ImportWithMissingCardIdAddsException()
    var
        CorpCardBatch: Record "EA Corp Card Batch";
    begin
        Initialize();
        EACorpCardTestLib.SetProviderSourcePayload(CorpCardL3ProviderCodeTok, GetL3PayloadMissingCardId(), L3SourceFileNameTok);

        EACorpCardTestLib.RunImportAndGetLastBatch(CorpCardL3ProviderCodeTok, CorpCardBatch);

        Assert.AreEqual(CorpCardBatch.Status::Completed, CorpCardBatch.Status, 'Batch should complete even when strict validation rejects the row.');
        Assert.AreEqual(0, CorpCardBatch.Imported, 'Invalid strict L3 row should not be imported.');
        Assert.AreEqual(1, CorpCardBatch.Exceptions, 'Invalid strict L3 row should produce one exception.');
        Assert.AreEqual(1, CorpCardBatch.Rejected, 'Invalid strict L3 row should be counted as rejected.');
    end;

    local procedure BlockCard(CardId: Code[50])
    var
        CorpCard: Record "EA Corp Card";
    begin
        CorpCard.Get(CardId);
        CorpCard.Blocked := true;
        CorpCard.Modify(true);
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
