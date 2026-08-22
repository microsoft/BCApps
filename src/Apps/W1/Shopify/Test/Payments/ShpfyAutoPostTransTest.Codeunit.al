// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Auto Post Trans. Test (ID 139627).
/// </summary>
codeunit 139627 "Shpfy Auto Post Trans. Test"
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
        // [SCENARIO] Auto-Post Jnl. Batch field validates successfully when the journal batch has a balancing account number

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
        // [SCENARIO] Auto-Post Jnl. Batch field validation fails when the journal batch does not have a balancing account number

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
        // [SCENARIO] Auto-Post Jnl. Batch field can be set to empty without a validation error

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
        // [SCENARIO] When an invoice with a Shopify Order Id is posted and Post Automatically is true, the transaction is auto-posted

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A Shopify order with a transaction
        OrderId := LibraryRandom.RandIntInRange(1000000, 1999999);
        TransactionId := LibraryRandom.RandIntInRange(1000000, 1999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price");

        // [GIVEN] Payment method mapping with auto-post enabled
        EnablePaymentMethodMappingAutoPost(true);

        // [GIVEN] A sales invoice with a Shopify Order Id
        CreateSalesOrder(SalesHeader, OrderId);

        // [WHEN] The sales invoice is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] A Cust. Ledger Entry is created for the transaction
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsFalse(CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should be created for the auto-posted transaction');
    end;

    [Test]
    procedure UnitTestPostSalesOrderWithoutAutoPostTransaction()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] When an invoice with a Shopify Order Id is posted and Post Automatically is false, the transaction is not auto-posted

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A Shopify order with a transaction
        OrderId := LibraryRandom.RandIntInRange(2000000, 2999999);
        TransactionId := LibraryRandom.RandIntInRange(2000000, 2999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price");

        // [GIVEN] Payment method mapping with auto-post disabled
        EnablePaymentMethodMappingAutoPost(false);

        // [GIVEN] A sales invoice with a Shopify Order Id
        CreateSalesOrder(SalesHeader, OrderId);

        // [WHEN] The sales invoice is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] A Cust. Ledger Entry is not created for the transaction
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
        // [SCENARIO] When an invoice with a Shopify Order Id is posted and Post Automatically is true, multiple transactions are auto-posted

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

        // [GIVEN] A sales invoice with a Shopify Order Id
        CreateSalesOrder(SalesHeader, OrderId);

        // [WHEN] The sales invoice is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] A Cust. Ledger Entry is created for each transaction
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId1);
        LibraryAssert.IsFalse(CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should be created for the first auto-posted transaction');
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId2);
        LibraryAssert.IsFalse(CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should be created for the second auto-posted transaction');
    end;

    [Test]
    procedure UnitTestPostSalesOrderWithMixedTransactions()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TransactionId1: BigInteger;
        TransactionId2: BigInteger;
        OrderId: BigInteger;
    begin
        // [SCENARIO] Only transactions linked to an auto-post Payment Method Mapping are auto-posted

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A Shopify order
        OrderId := LibraryRandom.RandIntInRange(4000000, 4999999);
        CreateShopifyOrder(OrderId);

        // [GIVEN] Payment method mapping with auto-post enabled
        EnablePaymentMethodMappingAutoPost(true);

        // [GIVEN] Transaction linked to an auto-post Payment Method Mapping
        TransactionId1 := LibraryRandom.RandIntInRange(4000000, 4499999);
        CreateOrderTransaction(TransactionId1, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price" / 2);

        // [GIVEN] Transaction not linked to any Payment Method Mapping
        TransactionId2 := LibraryRandom.RandIntInRange(4500000, 4999999);
        CreateOrderTransaction(TransactionId2, OrderId, 0, 'auto post disabled', Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price" / 2);

        // [GIVEN] A sales invoice with a Shopify Order Id
        CreateSalesOrder(SalesHeader, OrderId);

        // [WHEN] The sales invoice is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Only the linked transaction is auto-posted
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId1);
        LibraryAssert.IsFalse(CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should be created for the auto-posted transaction');
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId2);
        LibraryAssert.IsTrue(CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should not be created for the non-linked transaction');
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
        // [SCENARIO] When a credit memo with a Shopify Refund Id is posted and Post Automatically is true, the refund transaction is auto-posted

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A refund with a transaction
        RefundId := LibraryRandom.RandIntInRange(5000000, 5999999);
        OrderId := LibraryRandom.RandIntInRange(5000000, 5999999);
        CreateShopifyOrder(OrderId);
        CreateRefund(RefundId, OrderId);
        TransactionId := LibraryRandom.RandIntInRange(5000000, 5999999);
        CreateOrderTransaction(TransactionId, OrderId, RefundId, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Refund, Item."Unit Price");

        // [GIVEN] Payment method mapping with auto-post enabled
        EnablePaymentMethodMappingAutoPost(true);

        // [GIVEN] A sales credit memo with a Shopify Refund Id
        CreateCreditMemo(SalesHeader, RefundId);

        // [WHEN] The credit memo is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] A Cust. Ledger Entry is created for the refund transaction
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsFalse(CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should be created for the auto-posted refund transaction');
    end;

    [Test]
    procedure UnitTestAutoPostWorksWithPostWithJobQueueEnabled()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OrderId: BigInteger;
        TransactionId: BigInteger;
        OriginalPostWithJobQueue: Boolean;
    begin
        // [SCENARIO] Automatic posting is synchronous and works even when "Post with Job Queue" is enabled in the General Ledger Setup

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] Post with Job Queue is enabled
        GeneralLedgerSetup.Get();
        OriginalPostWithJobQueue := GeneralLedgerSetup."Post with Job Queue";
        GeneralLedgerSetup."Post with Job Queue" := true;
        GeneralLedgerSetup.Modify();

        // [GIVEN] A Shopify order with a transaction linked to an auto-post mapping
        OrderId := LibraryRandom.RandIntInRange(7000000, 7999999);
        TransactionId := LibraryRandom.RandIntInRange(7000000, 7999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price");
        EnablePaymentMethodMappingAutoPost(true);

        // [GIVEN] A sales invoice with a Shopify Order Id
        CreateSalesOrder(SalesHeader, OrderId);

        // [WHEN] The sales invoice is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The transaction is posted synchronously (Cust. Ledger Entry exists), it is not scheduled to the job queue
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsFalse(CustLedgerEntry.IsEmpty(), 'Transaction should be posted synchronously even with Post with Job Queue enabled');

        // Restore the setup (harmless either way, as automatic posting never uses the job queue).
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Post with Job Queue" := OriginalPostWithJobQueue;
        GeneralLedgerSetup.Modify();
    end;

    [Test]
    procedure UnitTestPostSalesOrderFailedTransactionIsBestEffort()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SkippedRecord: Record "Shpfy Skipped Record";
        OrderTransaction: Record "Shpfy Order Transaction";
        FailingGateway: Text[30];
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] When automatic posting of a transaction fails, the document posting still succeeds and the failure is logged

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A payment method mapping whose journal batch cannot post (no number series)
        FailingGateway := CreateFailingPaymentMethodMapping();

        // [GIVEN] A Shopify order with a transaction using the failing mapping
        OrderId := LibraryRandom.RandIntInRange(6000000, 6999999);
        TransactionId := LibraryRandom.RandIntInRange(6000000, 6999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, FailingGateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price");

        // [GIVEN] A sales invoice with a Shopify Order Id
        CreateSalesOrder(SalesHeader, OrderId);

        // [WHEN] The sales invoice is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The sales invoice is posted (document posting is not blocked by the payment failure)
        SalesInvoiceHeader.SetRange("Shpfy Order Id", OrderId);
        LibraryAssert.IsFalse(SalesInvoiceHeader.IsEmpty(), 'Posted sales invoice should exist');

        // [THEN] No Cust. Ledger Entry is created for the failed transaction
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsTrue(CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should not be created for the failed transaction');

        // [THEN] No orphaned general journal line is left behind
        LibraryAssert.IsTrue(NoJournalLineExistsForTransaction(TransactionId), 'No general journal line should be left behind for the failed transaction');

        // [THEN] The failure is logged as a skipped record
        OrderTransaction.Get(TransactionId);
        SkippedRecord.SetRange("Record ID", OrderTransaction.RecordId);
        LibraryAssert.IsFalse(SkippedRecord.IsEmpty(), 'A skipped record should be logged for the failed transaction');
    end;

    [Test]
    procedure UnitTestPreviewSalesOrderDoesNotAutoPost()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLPostingPreview: TestPage "G/L Posting Preview";
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] Previewing the posting of an invoice does not automatically post the transaction and does not break the preview

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A Shopify order with a transaction linked to an auto-post mapping
        OrderId := LibraryRandom.RandIntInRange(8000000, 8999999);
        TransactionId := LibraryRandom.RandIntInRange(8000000, 8999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price");
        EnablePaymentMethodMappingAutoPost(true);

        // [GIVEN] A sales invoice with a Shopify Order Id
        CreateSalesOrder(SalesHeader, OrderId);
        Commit();

        // [WHEN] The posting of the sales invoice is previewed
        GLPostingPreview.Trap();
        asserterror LibrarySales.PreviewPostSalesDocument(SalesHeader);

        // [THEN] The preview completes without a real error (auto-posting did not run and did not break the preview)
        LibraryAssert.AreEqual('', GetLastErrorText(), 'Posting preview should not raise a real error');
        GLPostingPreview.Close();

        // [THEN] Nothing was actually posted
        SalesInvoiceHeader.SetRange("Shpfy Order Id", OrderId);
        LibraryAssert.IsTrue(SalesInvoiceHeader.IsEmpty(), 'Preview should not post the sales invoice');
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
        Shop."Logging Mode" := Shop."Logging Mode"::"Error Only";
        Shop.Modify();

        CreatePaymentMethodMapping();

        IsInitialized := true;
    end;

    local procedure CreateItem()
    var
        LibraryInventory: Codeunit "Library - Inventory";
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandIntInRange(10000, 99999);
        // A service item is used so posting the sales invoice does not require Inventory Posting Setup;
        // the feature only depends on the resulting customer ledger entry, not on inventory posting.
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Service);
        Item.Validate("Unit Price", Amount);
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

    local procedure CreateFailingPaymentMethodMapping(): Text[30]
    var
        FailingMapping: Record "Shpfy Payment Method Mapping";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        FailingGateway: Text[30];
    begin
        // A batch with a balancing account but without a number series: journal lines get no document number
        // and posting therefore fails, which is used to exercise the best-effort failure handling.
        GenJournalTemplate.Name := CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(GenJournalTemplate.Name));
        GenJournalTemplate.Type := GenJournalTemplate.Type::"Cash Receipts";
        GenJournalTemplate.Insert();

        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(GenJournalBatch.Name));
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch."Bal. Account No." := CreateGLAccount();
        GenJournalBatch.Insert();

        FailingGateway := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(FailingMapping.Gateway));
        FailingMapping."Shop Code" := Shop.Code;
        FailingMapping.Gateway := FailingGateway;
        FailingMapping."Post Automatically" := true;
        FailingMapping."Auto-Post Jnl. Template" := GenJournalBatch."Journal Template Name";
        FailingMapping."Auto-Post Jnl. Batch" := GenJournalBatch.Name;
        FailingMapping.Insert();
        exit(FailingGateway);
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
        LibraryERM: Codeunit "Library - ERM";
    begin
        // A plain direct-posting G/L account is used as the journal batch balancing account, mirroring a
        // cash/bank account used for payments (no VAT or general posting groups are required).
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateNoSeries(NoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if not NoSeries.Get(NoSeriesCode) then begin
            NoSeries.Code := NoSeriesCode;
            NoSeries."Default Nos." := true;
            NoSeries.Insert();
            NoSeriesLine."Series Code" := NoSeriesCode;
            NoSeriesLine."Starting No." := Format(LibraryRandom.RandIntInRange(10000, 39999));
            NoSeriesLine."Increment-by No." := 1;
            NoSeriesLine."Ending No." := Format(LibraryRandom.RandIntInRange(50000, 99999));
            NoSeriesLine.Open := true;
            NoSeriesLine.Insert();
        end;
    end;

    local procedure NoJournalLineExistsForTransaction(TransactionId: BigInteger): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Shpfy Transaction Id", TransactionId);
        exit(GenJournalLine.IsEmpty());
    end;
}
