// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Auto Post Trans. Test (ID 139415).
/// </summary>
codeunit 139415 "Shpfy Auto Post Trans. Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Customer: Record Customer;
        Item: Record Item;
        Shop: Record "Shpfy Shop";
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        LibraryAssert: Codeunit "Library Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        IsInitialized: Boolean;

    [Test]
    procedure UnitTestAutoPostJnlBatchValidateWithBalAccountNo()
    var
        PaymentMethodMappingUnderTest: Record "Shpfy Payment Method Mapping";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO] Auto-Post Jnl. Batch field validates successfully when the journal batch has a balancing account number

        // [GIVEN] A Gen. Journal Batch with a balancing account number
        CreateJournalBatch(GenJournalBatch);
        PaymentMethodMappingUnderTest."Auto-Post Jnl. Template" := GenJournalBatch."Journal Template Name";

        // [WHEN] Auto-Post Jnl. Batch is validated
        PaymentMethodMappingUnderTest.Validate("Auto-Post Jnl. Batch", GenJournalBatch.Name);

        // [THEN] Validation passes without error
        LibraryAssert.AreEqual(GenJournalBatch.Name, PaymentMethodMappingUnderTest."Auto-Post Jnl. Batch", 'Auto-Post Jnl. Batch should be set');
    end;

    [Test]
    procedure UnitTestAutoPostJnlBatchValidateWithoutBalAccountNo()
    var
        PaymentMethodMappingUnderTest: Record "Shpfy Payment Method Mapping";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO] Auto-Post Jnl. Batch field validation fails when the journal batch does not have a balancing account number

        // [GIVEN] A Gen. Journal Batch without a balancing account number
        CreateJournalBatch(GenJournalBatch);
        GenJournalBatch."Bal. Account No." := '';
        GenJournalBatch.Modify();
        PaymentMethodMappingUnderTest."Auto-Post Jnl. Template" := GenJournalBatch."Journal Template Name";

        // [WHEN] Auto-Post Jnl. Batch is validated
        // [THEN] Validation fails with the missing balancing-account error
        asserterror PaymentMethodMappingUnderTest.Validate("Auto-Post Jnl. Batch", GenJournalBatch.Name);
        LibraryAssert.ExpectedTestFieldError(GenJournalBatch.FieldCaption("Bal. Account No."), '');
    end;

    [Test]
    procedure UnitTestAutoPostJnlBatchValidateWithEmptyValue()
    var
        PaymentMethodMappingUnderTest: Record "Shpfy Payment Method Mapping";
    begin
        // [SCENARIO] Auto-Post Jnl. Batch field can be set to empty without a validation error

        // [WHEN] Auto-Post Jnl. Batch is set to empty
        PaymentMethodMappingUnderTest.Validate("Auto-Post Jnl. Batch", '');

        // [THEN] Validation passes without error
        LibraryAssert.AreEqual('', PaymentMethodMappingUnderTest."Auto-Post Jnl. Batch", 'Auto-Post Jnl. Batch should be empty');
    end;

    [Test]
    procedure UnitTestAutoPostRequiresJournalSetup()
    var
        PaymentMethodMappingUnderTest: Record "Shpfy Payment Method Mapping";
    begin
        // [SCENARIO] Automatic posting cannot be enabled without a configured journal template and batch

        // [WHEN] Post Automatically is enabled without journal setup
        // [THEN] Validation fails on the missing journal template
        asserterror PaymentMethodMappingUnderTest.Validate("Post Automatically", true);
        LibraryAssert.ExpectedTestFieldError(PaymentMethodMappingUnderTest.FieldCaption("Auto-Post Jnl. Template"), '');
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
    procedure UnitTestPostSalesOrderWithAutoPostCaptureTransaction()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] A successful capture transaction is automatically posted with its invoice
        Initialize();

        OrderId := LibraryRandom.RandIntInRange(13000000, 13999999);
        TransactionId := LibraryRandom.RandIntInRange(13000000, 13999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Capture, Item."Unit Price");
        EnablePaymentMethodMappingAutoPost(true);
        CreateSalesOrder(SalesHeader, OrderId);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsFalse(CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should be created for the capture transaction');
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
    procedure UnitTestRefundAutoPostAppliesOnlyToMatchingRefund()
    var
        OtherSalesCrMemoHeader: Record "Sales Header";
        TargetSalesCrMemoHeader: Record "Sales Header";
        PostedSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OrderId: BigInteger;
        OtherRefundId: BigInteger;
        TargetRefundId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] A refund transaction only applies to the credit memo for the same Shopify refund

        // [GIVEN] Two refunds for the same Shopify order
        Initialize();
        OrderId := LibraryRandom.RandIntInRange(17000000, 17999999);
        OtherRefundId := LibraryRandom.RandIntInRange(17000000, 17499999);
        TargetRefundId := OtherRefundId + 500000;
        TransactionId := LibraryRandom.RandIntInRange(17000000, 17999999);
        CreateShopifyOrder(OrderId);
        CreateRefund(OtherRefundId, OrderId);
        CreateRefund(TargetRefundId, OrderId);

        // [GIVEN] The other refund's credit memo is posted while automatic posting is disabled
        EnablePaymentMethodMappingAutoPost(false);
        CreateCreditMemo(OtherSalesCrMemoHeader, OtherRefundId);
        LibrarySales.PostSalesDocument(OtherSalesCrMemoHeader, true, true);

        // [GIVEN] A transaction matching the localized total of the target refund's credit memo
        CreateCreditMemo(TargetSalesCrMemoHeader, TargetRefundId);
        TargetSalesCrMemoHeader.CalcFields("Amount Including VAT");
        CreateOrderTransaction(TransactionId, OrderId, TargetRefundId, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Refund, TargetSalesCrMemoHeader."Amount Including VAT");
        EnablePaymentMethodMappingAutoPost(true);

        // [WHEN] The target refund's credit memo is posted with automatic posting enabled
        LibrarySales.PostSalesDocument(TargetSalesCrMemoHeader, true, true);

        // [THEN] Only the target refund's credit memo is paid
        PostedSalesCrMemoHeader.SetAutoCalcFields(Paid);
        PostedSalesCrMemoHeader.SetRange("Shpfy Refund Id", OtherRefundId);
        LibraryAssert.IsTrue(PostedSalesCrMemoHeader.FindFirst(), 'The other refund credit memo should exist');
        LibraryAssert.IsFalse(PostedSalesCrMemoHeader.Paid, 'A refund transaction must not be applied to a different refund credit memo');
        PostedSalesCrMemoHeader.SetRange("Shpfy Refund Id", TargetRefundId);
        LibraryAssert.IsTrue(PostedSalesCrMemoHeader.FindFirst(), 'The target refund credit memo should exist');
        LibraryAssert.IsTrue(PostedSalesCrMemoHeader.Paid, 'The refund transaction should be applied to the matching refund credit memo');
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

    [Test]
    procedure UnitTestAutoPostDoesNotPostUnrelatedBatchLines()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        UnrelatedDocNo: Code[20];
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] An unrelated line parked in the configured auto-post batch is not posted when a Shopify invoice auto-posts

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] An unrelated manual journal line sitting in the configured auto-post batch
        UnrelatedDocNo := CreateUnrelatedJournalLine();

        // [GIVEN] A Shopify order with an auto-post-enabled transaction
        OrderId := LibraryRandom.RandIntInRange(9000000, 9499999);
        TransactionId := LibraryRandom.RandIntInRange(9000000, 9499999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price");
        EnablePaymentMethodMappingAutoPost(true);

        // [GIVEN] A sales invoice with a Shopify Order Id
        CreateSalesOrder(SalesHeader, OrderId);

        // [WHEN] The sales invoice is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Shopify transaction is auto-posted
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsFalse(CustLedgerEntry.IsEmpty(), 'Cust. Ledger Entry should be created for the auto-posted transaction');

        // [THEN] The unrelated journal line is untouched (still present, not posted)
        LibraryAssert.IsTrue(UnrelatedJournalLineExists(UnrelatedDocNo), 'The unrelated journal line in the configured batch must not be posted');
    end;

    [Test]
    procedure UnitTestAutoPostAfterDocumentLinkCreation()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] Document-link writes are committed before the isolated automatic-posting operation runs
        Initialize();

        OrderId := LibraryRandom.RandIntInRange(14000000, 14999999);
        TransactionId := LibraryRandom.RandIntInRange(14000000, 14999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price");
        EnablePaymentMethodMappingAutoPost(true);
        CreateSalesOrderDocument(SalesHeader, OrderId);
        CreateShopifyOrderDocumentLink(SalesHeader, OrderId);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsFalse(CustLedgerEntry.IsEmpty(), 'Document-link creation must not prevent the transaction from being auto-posted');
    end;

    [Test]
    procedure UnitTestAutoPostDefersWhilePartialInvoiceOpen()
    var
        SalesHeaderToPost: Record "Sales Header";
        SalesHeaderOpen: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] The order transaction is not consumed while another, not-yet-posted invoice exists for the same order

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A Shopify order with an auto-post-enabled transaction that covers both invoices
        OrderId := LibraryRandom.RandIntInRange(9500000, 9999999);
        TransactionId := LibraryRandom.RandIntInRange(9500000, 9999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, 2 * Item."Unit Price");
        EnablePaymentMethodMappingAutoPost(true);

        // [GIVEN] Two sales invoices for the same Shopify order
        CreateSalesOrder(SalesHeaderOpen, OrderId);
        CreateSalesOrder(SalesHeaderToPost, OrderId);

        // [WHEN] The first invoice is posted while the second is still open
        LibrarySales.PostSalesDocument(SalesHeaderToPost, true, true);

        // [THEN] Auto-posting is deferred - the transaction is not consumed yet
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsTrue(CustLedgerEntry.IsEmpty(), 'Transaction should not be auto-posted while another invoice for the order is still open');

        // [WHEN] The remaining invoice is posted
        LibrarySales.PostSalesDocument(SalesHeaderOpen, true, true);

        // [THEN] The transaction is now auto-posted
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsFalse(CustLedgerEntry.IsEmpty(), 'Transaction should be auto-posted once no open invoice remains for the order.');
    end;

    [Test]
    procedure UnitTestSetJournalParametersPropagatesToGeneratedLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        OrderTransaction: Record "Shpfy Order Transaction";
        SalesHeader: Record "Sales Header";
        SuggestPayments: Report "Shpfy Suggest Payments";
        PostedInvoiceNo: Code[20];
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] SetJournalParameters carries the mapped template, batch, and posting date onto the generated journal line

        // [GIVEN] Initialized test environment with a posted Shopify invoice and transaction
        Initialize();
        // Auto-post must stay off here so the transaction is left for the manual suggest-payments call below.
        EnablePaymentMethodMappingAutoPost(false);
        OrderId := LibraryRandom.RandIntInRange(10000000, 10999999);
        TransactionId := LibraryRandom.RandIntInRange(10000000, 10999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price");
        CreateSalesOrder(SalesHeader, OrderId);
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] The suggest-payments report generates lines with explicit journal parameters
        OrderTransaction.Get(TransactionId);
        SuggestPayments.SetJournalParameters(PaymentMethodMapping."Auto-Post Jnl. Template", PaymentMethodMapping."Auto-Post Jnl. Batch", WorkDate());
        SuggestPayments.GetOrderTransactions(OrderTransaction);
        SuggestPayments.CreateGeneralJournalLines();

        // [THEN] The generated line uses the mapped template, batch, and posting date
        GenJournalLine.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsTrue(GenJournalLine.FindFirst(), 'A general journal line should be generated for the transaction');
        LibraryAssert.AreEqual(PaymentMethodMapping."Auto-Post Jnl. Template", GenJournalLine."Journal Template Name", 'Journal template should match the mapping');
        LibraryAssert.AreEqual(PaymentMethodMapping."Auto-Post Jnl. Batch", GenJournalLine."Journal Batch Name", 'Journal batch should match the mapping');
        LibraryAssert.AreEqual(WorkDate(), GenJournalLine."Posting Date", 'Posting date should match the value passed to SetJournalParameters');
        LibraryAssert.AreEqual(PostedInvoiceNo, GenJournalLine."Applies-to Doc. No.", 'Generated payment line should apply to the posted invoice');

        // Clean up the unposted lines so they don't leak into other tests.
        GenJournalLine.SetRange("Shpfy Transaction Id", TransactionId);
        GenJournalLine.DeleteAll(true);
    end;

    [Test]
    procedure UnitTestAutoPostWithFuturePostingDateIsHeadless()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostingDate: Date;
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] Automatic posting pre-confirms the journal posting-date prompt
        Initialize();

        PostingDate := CalcDate('<1D>', WorkDate());
        OrderId := LibraryRandom.RandIntInRange(15000000, 15999999);
        TransactionId := LibraryRandom.RandIntInRange(15000000, 15999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price");
        EnablePaymentMethodMappingAutoPost(true);
        CreateSalesOrderWithPostingDate(SalesHeader, OrderId, PostingDate);
        EnablePostingAfterWorkingDateConfirmation();

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsFalse(CustLedgerEntry.IsEmpty(), 'The transaction should be auto-posted without a confirmation dialog');
        DisablePostingAfterWorkingDateConfirmation();
    end;

    [Test]
    procedure UnitTestAutoPostSkippedWhenCommitSuppressed()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SkippedRecord: Record "Shpfy Skipped Record";
        SalesPost: Codeunit "Sales-Post";
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] Auto-posting is skipped when the caller suppresses commit and owns the transaction

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A Shopify order with an auto-post-enabled transaction and a matching sales invoice
        OrderId := LibraryRandom.RandIntInRange(11000000, 11999999);
        TransactionId := LibraryRandom.RandIntInRange(11000000, 11999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, Item."Unit Price");
        EnablePaymentMethodMappingAutoPost(true);
        CreateSalesOrder(SalesHeader, OrderId);

        ResetSalesPostingNoSeriesDateUsage();

        // [WHEN] The sales invoice is posted with commit suppressed (the caller owns the transaction)
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        SalesHeader.Modify();
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);

        // [THEN] Auto-posting did not run: no ledger entry and no skipped record for the transaction
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsTrue(CustLedgerEntry.IsEmpty(), 'Auto-posting must not run when commit is suppressed');
        SkippedRecord.SetRange("Shopify Id", TransactionId);
        LibraryAssert.IsTrue(SkippedRecord.IsEmpty(), 'No skipped record should be logged when auto-posting is skipped');
    end;

    [Test]
    procedure UnitTestAutoPostDefersWhilePartialCreditMemoOpen()
    var
        SalesHeaderToPost: Record "Sales Header";
        SalesHeaderOpen: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OrderId: BigInteger;
        RefundId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] The refund transaction is not consumed while another, not-yet-posted credit memo exists for the same refund

        // [GIVEN] Initialized test environment
        Initialize();

        // [GIVEN] A Shopify refund with an auto-post-enabled transaction that covers both credit memos
        OrderId := LibraryRandom.RandIntInRange(12000000, 12999999);
        RefundId := LibraryRandom.RandIntInRange(12000000, 12999999);
        TransactionId := LibraryRandom.RandIntInRange(12000000, 12999999);
        CreateShopifyOrder(OrderId);
        CreateRefund(RefundId, OrderId);
        CreateOrderTransaction(TransactionId, OrderId, RefundId, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Refund, 2 * Item."Unit Price");
        EnablePaymentMethodMappingAutoPost(true);

        // [GIVEN] Two credit memos for the same Shopify refund
        CreateCreditMemo(SalesHeaderOpen, RefundId);
        CreateCreditMemo(SalesHeaderToPost, RefundId);

        // [WHEN] The first credit memo is posted while the second is still open
        LibrarySales.PostSalesDocument(SalesHeaderToPost, true, true);

        // [THEN] Auto-posting is deferred - the transaction is not consumed yet
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsTrue(CustLedgerEntry.IsEmpty(), 'Refund transaction should not be auto-posted while another credit memo for the refund is still open');

        // [WHEN] The remaining credit memo is posted
        LibrarySales.PostSalesDocument(SalesHeaderOpen, true, true);

        // [THEN] The transaction is now auto-posted
        CustLedgerEntry.SetRange("Shpfy Transaction Id", TransactionId);
        LibraryAssert.IsFalse(CustLedgerEntry.IsEmpty(), 'Refund transaction should be auto-posted once no open credit memo remains for the refund.');
    end;

    [Test]
    procedure UnitTestPostableEligibilityExcludesOpenSalesDocument()
    var
        SalesHeaderOpen: Record "Sales Header";
        SalesHeaderToPost: Record "Sales Header";
        OrderTransaction: Record "Shpfy Order Transaction";
        PaymentMethodMappingForEligibility: Record "Shpfy Payment Method Mapping";
        AutoPostEligibility: Codeunit "Shpfy Auto Post Eligibility";
        OrderId: BigInteger;
        TransactionId: BigInteger;
    begin
        // [SCENARIO] The postable-transactions predicate matches automatic posting's partial-invoice deferral
        Initialize();

        OrderId := LibraryRandom.RandIntInRange(16000000, 16999999);
        TransactionId := LibraryRandom.RandIntInRange(16000000, 16999999);
        CreateShopifyOrder(OrderId);
        CreateOrderTransaction(TransactionId, OrderId, 0, PaymentMethodMapping.Gateway, Enum::"Shpfy Transaction Type"::Sale, 2 * Item."Unit Price");
        EnablePaymentMethodMappingAutoPost(false);
        CreateSalesOrder(SalesHeaderOpen, OrderId);
        CreateSalesOrder(SalesHeaderToPost, OrderId);
        ResetSalesPostingNoSeriesDateUsage();
        LibrarySales.PostSalesDocument(SalesHeaderToPost, true, true);
        EnablePaymentMethodMappingAutoPost(true);
        OrderTransaction.SetAutoCalcFields(Used);
        OrderTransaction.Get(TransactionId);

        LibraryAssert.IsFalse(
            AutoPostEligibility.IsReadyToPost(OrderTransaction, PaymentMethodMappingForEligibility),
            'A transaction must not be shown as postable while another sales document for its order is open');

        SalesHeaderOpen."Shpfy Order Id" := 0;
        SalesHeaderOpen.Modify();
        LibraryAssert.IsTrue(
            AutoPostEligibility.IsReadyToPost(OrderTransaction, PaymentMethodMappingForEligibility),
            'A transaction should be postable once no related open sales document remains for the order');
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
        OrderHeader: Record "Shpfy Order Header";
    begin
        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := OrderId;
        OrderHeader.Processed := true;
        OrderHeader.Insert();
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

    local procedure CreateSalesOrderWithPostingDate(var SalesHeader: Record "Sales Header"; OrderId: BigInteger; PostingDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader."Shpfy Order Id" := OrderId;
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreateSalesOrderDocument(var SalesHeader: Record "Sales Header"; OrderId: BigInteger)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader."Shpfy Order Id" := OrderId;
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreateShopifyOrderDocumentLink(SalesHeader: Record "Sales Header"; OrderId: BigInteger)
    var
        DocLinkToBCDoc: Record "Shpfy Doc. Link To Doc.";
    begin
        DocLinkToBCDoc."Shopify Document Type" := DocLinkToBCDoc."Shopify Document Type"::"Shopify Shop Order";
        DocLinkToBCDoc."Shopify Document Id" := OrderId;
        DocLinkToBCDoc."Document Type" := DocLinkToBCDoc."Document Type"::"Sales Order";
        DocLinkToBCDoc."Document No." := SalesHeader."No.";
        DocLinkToBCDoc.Insert();
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
        GenJournalBatch: Record "Gen. Journal Batch";
        FailingGateway: Text[30];
    begin
        // A batch with a balancing account but without a number series: journal lines get no document number
        // and posting therefore fails, which is used to exercise the best-effort failure handling.
        CreateJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", '');
        GenJournalBatch.Modify(true);

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
        SourceCode: Record "Source Code";
    begin
        LibraryERM.CreateSourceCode(SourceCode);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.Validate("Source Code", SourceCode.Code);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", CreateGLAccount());
        GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure EnablePostingAfterWorkingDateConfirmation()
    var
        AccountingPeriod: Record "Accounting Period";
        MyNotifications: Record "My Notifications";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if AccountingPeriod.IsEmpty() then begin
            AccountingPeriod."Starting Date" := WorkDate();
            AccountingPeriod.Insert();
        end;
        MyNotifications.InsertDefault(
            InstructionMgt.GetPostingAfterWorkingDateNotificationId(),
            InstructionMgt.PostingAfterWorkingDateNotAllowedCode(),
            '', true);
    end;

    local procedure DisablePostingAfterWorkingDateConfirmation()
    var
        MyNotifications: Record "My Notifications";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if MyNotifications.Get(UserId(), InstructionMgt.GetPostingAfterWorkingDateNotificationId()) then
            MyNotifications.Delete();
    end;

    local procedure ResetSalesPostingNoSeriesDateUsage()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeriesLine: Record "No. Series Line";
    begin
        SalesReceivablesSetup.Get();
        NoSeriesLine.SetFilter(
            "Series Code", '%1|%2',
            SalesReceivablesSetup."Posted Shipment Nos.", SalesReceivablesSetup."Posted Invoice Nos.");
        NoSeriesLine.ModifyAll("Last Date Used", 0D);
    end;

    local procedure NoJournalLineExistsForTransaction(TransactionId: BigInteger): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Shpfy Transaction Id", TransactionId);
        exit(GenJournalLine.IsEmpty());
    end;

    local procedure CreateUnrelatedJournalLine(): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeries: Codeunit "No. Series";
        DocNo: Code[20];
        LastLineNo: Integer;
    begin
        // A self-balancing line parked in the configured batch; it would post if the whole batch posted.
        GenJournalBatch.Get(PaymentMethodMapping."Auto-Post Jnl. Template", PaymentMethodMapping."Auto-Post Jnl. Batch");
        DocNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series", WorkDate());

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if GenJournalLine.FindLast() then
            LastLineNo := GenJournalLine."Line No.";

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := LastLineNo + 10000;
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine."Document No." := DocNo;
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", CreateGLAccount());
        GenJournalLine.Validate(Amount, LibraryRandom.RandDecInRange(100, 1000, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccount());
        GenJournalLine.Insert(true);
        exit(DocNo);
    end;

    local procedure UnrelatedJournalLineExists(DocNo: Code[20]): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", PaymentMethodMapping."Auto-Post Jnl. Template");
        GenJournalLine.SetRange("Journal Batch Name", PaymentMethodMapping."Auto-Post Jnl. Batch");
        GenJournalLine.SetRange("Document No.", DocNo);
        exit(not GenJournalLine.IsEmpty());
    end;
}
