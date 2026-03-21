// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Auto Post Transaction Test (ID 139614).
/// </summary>
codeunit 139614 "Shpfy Auto Post Trans. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Customer: Record Customer;
        Item: Record Item;
        Shop: Record "Shpfy Shop";
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        LibraryAssert: Codeunit "Library Assert";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        IsInitialized: Boolean;

    [Test]
    procedure UnitTestAutoPostJnlBatchValidateWithBalAccountNo()
    var
        ShpfyPaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO] Auto-Post Jnl. Batch field validates successfully when journal batch has a balancing account number

        // [GIVEN] A Gen. Journal Batch with a balancing account number
        CreateJournalBatch(GenJournalBatch);
        ShpfyPaymentMethodMapping."Auto-Post Jnl. Template" := GenJournalBatch."Journal Template Name";

        // [WHEN] Auto-Post Jnl. Batch is validated
        ShpfyPaymentMethodMapping.Validate("Auto-Post Jnl. Batch", GenJournalBatch.Name);

        // [THEN] Validation passes without error
        LibraryAssert.AreEqual(GenJournalBatch.Name, ShpfyPaymentMethodMapping."Auto-Post Jnl. Batch", 'Auto-Post Jnl. Batch should be set');
    end;

    [Test]
    procedure UnitTestAutoPostJnlBatchValidateWithoutBalAccountNo()
    var
        ShpfyPaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO] Auto-Post Jnl. Batch field validation fails when journal batch does not have a balancing account number

        // [GIVEN] A Gen. Journal Batch without a balancing account number
        CreateJournalBatch(GenJournalBatch);
        GenJournalBatch."Bal. Account No." := '';
        GenJournalBatch.Modify();
        ShpfyPaymentMethodMapping."Auto-Post Jnl. Template" := GenJournalBatch."Journal Template Name";

        // [WHEN] Auto-Post Jnl. Batch is validated
        // [THEN] Validation fails with error
        asserterror ShpfyPaymentMethodMapping.Validate("Auto-Post Jnl. Batch", GenJournalBatch.Name);
    end;

    [Test]
    procedure UnitTestAutoPostJnlBatchValidateWithEmptyValue()
    var
        ShpfyPaymentMethodMapping: Record "Shpfy Payment Method Mapping";
    begin
        // [SCENARIO] Auto-Post Jnl. Batch field can be set to empty without validation error

        // [WHEN] Auto-Post Jnl. Batch is set to empty
        ShpfyPaymentMethodMapping.Validate("Auto-Post Jnl. Batch", '');

        // [THEN] Validation passes without error
        LibraryAssert.AreEqual('', ShpfyPaymentMethodMapping."Auto-Post Jnl. Batch", 'Auto-Post Jnl. Batch should be empty');
    end;

    [Test]
    procedure UnitTestPostSalesOrderWithAutoPostTransaction()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] When a sales order with Shopify Order Id is posted and Post Automatically is true, transaction is auto-posted

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A Shopify order with transaction
        OrderId := LibraryRandom.RandIntInRange(1000000, 1999999);
        TransactionId := LibraryRandom.RandIntInRange(1000000, 1999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price");

        // [GIVEN] Payment method mapping with auto-post enabled
        EnablePaymentMethodMappingAutoPost(true);

        // [GIVEN] A sales order with Shopify Order Id
        CreateSalesOrder(SalesHeader, OrderId);

        // [WHEN] The sales order is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] A Cust. Ledger Entry is created
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsTrue(not CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should be created for the auto-posted transaction');
    end;

    [Test]
    procedure UnitTestPostSalesOrderWithoutAutoPostTransaction()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] When a sales order with Shopify Order Id is posted and Post Automatically is false, transaction is not auto-posted

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A Shopify order with transaction
        OrderId := LibraryRandom.RandIntInRange(2000000, 2999999);
        TransactionId := LibraryRandom.RandIntInRange(2000000, 2999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price");

        // [GIVEN] Payment method mapping with auto-post disabled
        EnablePaymentMethodMappingAutoPost(false);

        // [GIVEN] A sales order with Shopify Order Id
        CreateSalesOrder(SalesHeader, OrderId);

        // [WHEN] The sales order is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] A Cust. Ledger Entry is not created
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsTrue(CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should not be created for the non-auto-posted transaction');
    end;

    [Test]
    procedure UnitTestPostSalesOrderWithAutoPostMultipleTransaction()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TransactionId1: BigInteger;
        TransactionId2: BigInteger;
        OrderId: BigInteger;
    begin
        // [SCENARIO] When a sales order with Shopify Order Id is posted and Post Automatically is true, multiple transactions are auto-posted

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A Shopify order with multiple transactions
        OrderId := LibraryRandom.RandIntInRange(3000000, 3999999);
        CreateShopifyOrder(OrderId);
        TransactionId1 := LibraryRandom.RandIntInRange(3000000, 3499999);
        TransactionId2 := LibraryRandom.RandIntInRange(3500000, 3999999);
        CreateOrderTransaction(TransactionId1, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price" / 2);
        CreateOrderTransaction(TransactionId2, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price" / 2);

        // [GIVEN] Payment method mapping with auto-post enabled
        EnablePaymentMethodMappingAutoPost(true);

        // [GIVEN] A sales order with Shopify Order Id
        CreateSalesOrder(SalesHeader, OrderId);

        // [WHEN] The sales order is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] A Cust. Ledger Entry is created
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId1);
        LibraryAssert.IsTrue(not CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should be created for the auto-posted transaction');
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId2);
        LibraryAssert.IsTrue(not CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should be created for the auto-posted transaction');
    end;

    [Test]
    procedure UnitTestPostSalesOrderWithMultipleTransaction()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TransactionId1: BigInteger;
        TransactionId2: BigInteger;
        OrderId: BigInteger;
    begin
        // [SCENARIO] When a sales order with Shopify Order Id is posted and Post Automatically is true, only transactions linked to auto post Payment Method Mapping are auto-posted

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A Shopify order
        OrderId := LibraryRandom.RandIntInRange(4000000, 4999999);
        CreateShopifyOrder(OrderId);

        // [GIVEN] Payment method mapping with auto-post enabled
        EnablePaymentMethodMappingAutoPost(true);

        // [GIVEN] Transaction linked to auto post Payment Method Mapping
        TransactionId1 := LibraryRandom.RandIntInRange(4000000, 4499999);
        CreateOrderTransaction(TransactionId1, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price" / 2);

        // [GIVEN] Transaction not linked to auto post Payment Method Mapping
        TransactionId2 := LibraryRandom.RandIntInRange(4500000, 4999999);
        CreateOrderTransaction(TransactionId2, OrderId, 0, 'auto post disabled', Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price" / 2);

        // [GIVEN] A sales order with Shopify Order Id
        CreateSalesOrder(SalesHeader, OrderId);

        // [WHEN] The sales order is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] A Cust. Ledger Entry is created
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId1);
        LibraryAssert.IsTrue(not CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should be created for the auto-posted transaction');
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId2);
        LibraryAssert.IsTrue(CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should not be created for the non-auto-posted transaction');
    end;

    [Test]
    procedure UnitTestPostCreditMemoWithAutoPostTransaction()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TransactionId: BigInteger;
        RefundId: BigInteger;
        OrderId: BigInteger;
    begin
        // [SCENARIO] When a credit memo with Shopify Refund Id is posted and Post Automatically is true, refund transaction is auto-posted

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A refund with transaction
        RefundId := LibraryRandom.RandIntInRange(5000000, 5999999);
        OrderId := LibraryRandom.RandIntInRange(5000000, 5999999);
        CreateShopifyOrder(OrderId);
        CreateRefund(RefundId, OrderId);
        TransactionId := LibraryRandom.RandIntInRange(5000000, 5999999);
        CreateOrderTransaction(TransactionId, OrderId, RefundId, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Refund, Item."Unit Price");

        // [GIVEN] Payment method mapping with auto-post enabled
        EnablePaymentMethodMappingAutoPost(true);

        // [GIVEN] A sales credit memo with Shopify Refund Id
        CreateCreditMemo(SalesHeader, RefundId);

        // [WHEN] The credit memo is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] A Cust. Ledger Entry is created
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsTrue(not CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should be created for the auto-posted refund transaction');
    end;

    [Test]
    procedure UnitTestPostSalesOrderWithUnsuccessfulTransactionPost()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] When a sales order with Shopify Order Id is posted and Post Automatically is true, transaction post is unsuccessful, but sales order posting is completed

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A Shopify order with transaction
        OrderId := LibraryRandom.RandIntInRange(6000000, 6999999);
        TransactionId := LibraryRandom.RandIntInRange(6000000, 6999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price");

        // [GIVEN] Payment method mapping with auto-post enabled
        EnablePaymentMethodMappingAutoPost(true);

        // [GIVEN] A sales order with Shopify Order Id
        CreateSalesOrder(SalesHeader, OrderId);

        // [GIVEN] Transaction auto post No. Series is closed
        OpenNoSeriesLine(false);

        // [WHEN] The sales order is posted
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales order posting is completed
        SalesInvoiceHeader.SetRange("Shpfy Order Id", OrderId);
        LibraryAssert.IsTrue(not SalesInvoiceHeader.IsEmpty(), 'Posted sales invoice should exist');

        // [THEN] A Cust. Ledger Entry is not created
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsTrue(CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should not be created for the auto-posted transaction');

        OpenNoSeriesLine(true);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
    begin
        if IsInitialized then
            exit;

        Codeunit.Run(Codeunit::"Shpfy Initialize Test");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        CreateItem();
        LibrarySales.CreateCustomer(Customer);

        Shop := CommunicationMgt.GetShopRecord();

        CreatePaymentMethodMapping();

        DisablePostWithJobQueue();

        IsInitialized := true;
    end;

    local procedure DisablePostWithJobQueue()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Post with Job Queue" := false;
        GeneralLedgerSetup.Modify();
    end;

    local procedure CreateItem()
    var
        LibraryInventory: Codeunit "Library - Inventory";
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandIntInRange(10000, 99999);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", Amount);
        Item.Validate("Last Direct Cost", Amount);
        Item.Modify(true);
    end;

    local procedure CreateShopifyOrder(OrderId: BigInteger)
    var
        ShpfyOrderHeader: Record "Shpfy Order Header";
    begin
        ShpfyOrderHeader.Init();
        ShpfyOrderHeader."Shopify Order Id" := OrderId;
        ShpfyOrderHeader.Processed := true;
        ShpfyOrderHeader.Insert();
    end;

    local procedure CreateOrderTransaction(TransactionId: BigInteger; OrderId: BigInteger; RefundId: BigInteger; Gateway: Text[30]; TransactionType: Enum "Shpfy Transaction Type"; Amount: Decimal)
    var
        OrderTransaction: Record "Shpfy Order Transaction";
    begin
        OrderTransaction.Init();
        OrderTransaction."Shopify Transaction Id" := TransactionId;
        OrderTransaction."Shopify Order Id" := OrderId;
        OrderTransaction."Refund Id" := RefundId;
        OrderTransaction.Shop := Shop.Code;
        OrderTransaction.Gateway := Gateway;
        OrderTransaction.Type := TransactionType;
        OrderTransaction.Status := OrderTransaction.Status::Success;
        OrderTransaction.Amount := Amount;
        OrderTransaction.Used := false;
        OrderTransaction.Insert();
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; OrderId: BigInteger)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader."Shpfy Order Id" := OrderId;
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreateCreditMemo(var SalesHeader: Record "Sales Header"; RefundId: BigInteger)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesHeader."Shpfy Refund Id" := RefundId;
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreateRefund(RefundId: BigInteger; OrderId: BigInteger)
    var
        RefundHeader: Record "Shpfy Refund Header";
    begin
        RefundHeader.Init();
        RefundHeader."Refund Id" := RefundId;
        RefundHeader."Order Id" := OrderId;
        RefundHeader.Insert();
    end;

    local procedure EnablePaymentMethodMappingAutoPost(AutoPost: Boolean)
    begin
        PaymentMethodMapping."Post Automatically" := AutoPost;
        PaymentMethodMapping.Modify();
    end;

    local procedure CreatePaymentMethodMapping()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        PaymentMethodMapping.Init();
        PaymentMethodMapping."Shop Code" := Shop.Code;
        PaymentMethodMapping.Gateway := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(PaymentMethodMapping.Gateway));
        PaymentMethodMapping."Post Automatically" := true;
        CreateJournalBatch(GenJournalBatch);
        PaymentMethodMapping."Auto-Post Jnl. Template" := GenJournalBatch."Journal Template Name";
        PaymentMethodMapping."Auto-Post Jnl. Batch" := GenJournalBatch.Name;
        PaymentMethodMapping.Insert();
    end;

    local procedure CreateJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(GenJournalTemplate.Name));
        GenJournalTemplate.Type := GenJournalTemplate.Type::"Cash Receipts";
        GenJournalTemplate.Insert();

        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(GenJournalBatch.Name));
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch."Bal. Account No." := CreateGLAccount();
        GenJournalBatch."No. Series" := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(GenJournalBatch."No. Series"));
        CreateNoSeries(GenJournalBatch."No. Series");
        GenJournalBatch.Insert();
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
        ShpfyInitializeTest: Codeunit "Shpfy Initialize Test";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInDecimalRange(10, 25, 0));
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, Enum::"General Posting Type"::Sale));
        GLAccount."Direct Posting" := true;

        ShpfyInitializeTest.CreateVATPostingSetup(Shop."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");

        GLAccount.Modify(false);
        exit(GLAccount."No.");
    end;

    local procedure CreateNoSeries(Code: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if not NoSeries.Get(Code) then begin
            NoSeries.Code := Code;
            NoSeries."Default Nos." := true;
            NoSeries.Insert();
            NoSeriesLine."Series Code" := Code;
            NoSeriesLine."Starting No." := Format(LibraryRandom.RandIntInRange(10000, 39999));
            NoSeriesLine."Increment-by No." := 1;
            NoSeriesLine."Ending No." := Format(LibraryRandom.RandIntInRange(50000, 99999));
            NoSeriesLine.Open := true;
            NoSeriesLine.Insert();
        end;
    end;

    local procedure OpenNoSeriesLine(Open: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeriesLine: Record "No. Series Line";
    begin
        GenJournalBatch.Get(PaymentMethodMapping."Auto-Post Jnl. Template", PaymentMethodMapping."Auto-Post Jnl. Batch");
        NoSeriesLine.SetRange("Series Code", GenJournalBatch."No. Series");
        if NoSeriesLine.FindFirst() then begin
            NoSeriesLine.Open := Open;
            NoSeriesLine.Modify();
        end;
    end;
}
