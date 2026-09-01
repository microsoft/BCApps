// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Finance.Currency;
using Microsoft.Finance.SalesTax;
using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.TestLibraries.Utilities;

codeunit 139611 "Shpfy Order Refund Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        InitializeTest: Codeunit "Shpfy Initialize Test";
        LibraryAssert: Codeunit "Library Assert";
        Any: Codeunit Any;
        ShopifyIds: Dictionary of [Text, List of [BigInteger]];
        IsInitialized: Boolean;

    trigger OnRun()
    begin
        // [FEATURE] [Account Schedule] [Chart]
        IsInitialized := false;
    end;

    [Test]
    procedure UnitTestCreateCrMemoFromRefundWithFullyRefundedItem()
    var
        SalesHeader: Record "Sales Header";
        RefundHeader: Record "Shpfy Refund Header";
        RefundId: BigInteger;
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
        CanCreateDocument: Boolean;
        ErrorInfo: ErrorInfo;
    begin
        // [SCENARIO] Create a Credit Memo from a Shopify Refund where the item is totally refunded.
        Initialize();

        // [GIVEN] Set the process of the document: "Auto Create Credit Memo";
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        // [GIVEN] The document type Refund
        // [GIVEN] The RefundId of the refund for creating the credit Memo.
        RefundId := ShopifyIds.Get('Refund').Get(1);

        // [WHEN] Execute IReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, errorInfo)
        CanCreateDocument := IReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, errorInfo);
        // [THEN] CancreateDocument must be true
        LibraryAssert.IsTrue(CanCreateDocument, 'The result of IReturnRefundProcess.CanCreateSalesDocumentFor must be true');

        // [WHEN] Execute IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId)
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);
        // [THEN] SalesHeader."Document Type" = Enum::"Sales Document Type"::"Credit Memo"
        LibraryAssert.AreEqual(Enum::"Sales Document Type"::"Credit Memo", SalesHeader."Document Type", 'SalesHeader."Document Type" must be a Credit Memo');
        // [THEN] Test if SalesHeader."Amount Including VAT" is equal to RefundHeader."Total Refunded Amount"
        RefundHeader.Get(RefundId);
        SalesHeader.CalcFields("Amount Including VAT");
        LibraryAssert.AreEqual(RefundHeader."Total Refunded Amount", SalesHeader."Amount Including VAT", 'The SalesHeader."Amount Including VAT" must be equal to RefundHeader."Total Refunded Amount".');
        // Tear down
        ResetProcessOnRefund(RefundId);
    end;

    [Test]
    procedure UnitTestCrMemoInheritsTaxAreaAndTaxLiable()
    var
        SalesHeader: Record "Sales Header";
        RefundHeader: Record "Shpfy Refund Header";
        OrderHeader: Record "Shpfy Order Header";
        RefundId: BigInteger;
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
        CanCreateDocument: Boolean;
        ErrorInfo: ErrorInfo;
    begin
        // [SCENARIO] Credit memo from refund inherits Tax Area Code and Tax Liable from parent order
        Initialize();

        // [GIVEN] Set the process of the document: "Auto Create Credit Memo"
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        RefundId := ShopifyIds.Get('Refund').Get(1);

        // [GIVEN] Parent order has Tax Area Code and Tax Liable = true
        RefundHeader.Get(RefundId);
        OrderHeader.Get(RefundHeader."Order Id");
        EnsureTaxAreaExists('SHPFY-TEST');
        OrderHeader."Tax Area Code" := 'SHPFY-TEST';
        OrderHeader."Tax Liable" := true;
        OrderHeader.Modify();

        // [WHEN] Credit memo is created from refund
        CanCreateDocument := IReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, ErrorInfo);
        LibraryAssert.IsTrue(CanCreateDocument, 'Must be able to create credit memo');
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);

        // [THEN] Credit memo has Tax Area Code and Tax Liable from parent order
        LibraryAssert.AreEqual(OrderHeader."Tax Area Code", SalesHeader."Tax Area Code", 'Credit memo Tax Area Code must match parent order');
        LibraryAssert.IsTrue(SalesHeader."Tax Liable", 'Credit memo Tax Liable must be true when parent order is Tax Liable');

        // Tear down — restore order header and remove doc link
        OrderHeader."Tax Area Code" := '';
        OrderHeader."Tax Liable" := false;
        OrderHeader.Modify();
        ResetProcessOnRefund(RefundId);
    end;

    [Test]
    procedure UnitTestCreateCrMemoFromRefundForOnlyShipment()
    var
        SalesHeader: Record "Sales Header";
        RefundHeader: Record "Shpfy Refund Header";
        RefundId: BigInteger;
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
        CanCreateDocument: Boolean;
        ErrorInfo: ErrorInfo;
    begin
        // [SCENARIO] Create a Credit Memo from a Shopify Refund where only the shipment is refunded.
        Initialize();

        // [GIVEN] Set the process of the document: "Auto Create Credit Memo";
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        // [GIVEN] The document type Refund
        // [GIVEN] The RefundId of the refund for creating the credit Memo.
        RefundId := ShopifyIds.Get('Refund').Get(2);

        // [WHEN] Execute IReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, errorInfo)
        CanCreateDocument := IReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, errorInfo);
        // [THEN] CancreateDocument must be true
        LibraryAssert.IsTrue(CanCreateDocument, 'The result of IReturnRefundProcess.CanCreateSalesDocumentFor must be true');

        // [WHEN] Execute IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId)
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);
        // [THEN] SalesHeader."Document Type" = Enum::"Sales Document Type"::"Credit Memo"
        LibraryAssert.AreEqual(Enum::"Sales Document Type"::"Credit Memo", SalesHeader."Document Type", 'SalesHeader."Document Type" must be a Credit Memo');
        // [THEN] Test if SalesHeader."Amount Including VAT" is equal to RefundHeader."Total Refunded Amount"
        RefundHeader.Get(RefundId);
        SalesHeader.CalcFields("Amount Including VAT");
        LibraryAssert.AreNearlyEqual(RefundHeader."Total Refunded Amount", SalesHeader."Amount Including VAT", 0.5, 'The SalesHeader."Amount Including VAT" must be equal to RefundHeader."Total Refunded Amount".');
        // Tear down
        ResetProcessOnRefund(RefundId);
    end;

    [Test]
    procedure UnitTestCreateCrMemoFromRefundWithNotRefundedItem()
    var
        SalesHeader: Record "Sales Header";
        RefundHeader: Record "Shpfy Refund Header";
        RefundId: BigInteger;
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
        CanCreateDocument: Boolean;
        ErrorInfo: ErrorInfo;
    begin
        // [SCENARIO] Create a Credit Memo from a Shopify Refund where the item is not refunded.
        Initialize();

        // [GIVEN] Set the process of the document: "Auto Create Credit Memo";
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        // [GIVEN] The document type Refund
        // [GIVEN] The RefundId of the refund for creating the credit Memo.
        RefundId := ShopifyIds.Get('Refund').Get(1);

        // [WHEN] Execute IReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, errorInfo)
        CanCreateDocument := IReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, errorInfo);
        // [THEN] CancreateDocument must be true
        LibraryAssert.IsTrue(CanCreateDocument, 'The result of IReturnRefundProcess.CanCreateSalesDocumentFor must be true');

        // [WHEN] Execute IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId)
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);
        // [THEN] SalesHeader."Document Type" = Enum::"Sales Document Type"::"Credit Memo"
        LibraryAssert.AreEqual(Enum::"Sales Document Type"::"Credit Memo", SalesHeader."Document Type", 'SalesHeader."Document Type" must be a Credit Memo');
        // [THEN] Test if SalesHeader."Amount Including VAT" is equal to RefundHeader."Total Refunded Amount"
        RefundHeader.Get(RefundId);
        SalesHeader.CalcFields("Amount Including VAT");
        LibraryAssert.AreEqual(RefundHeader."Total Refunded Amount", SalesHeader."Amount Including VAT", 'The SalesHeader."Amount Including VAT" must be equal to RefundHeader."Total Refunded Amount".');

        // Tear down
        ResetProcessOnRefund(RefundId);
    end;

    [Test]
    procedure UnitTestCanCreateCreditMemo()
    var
        RefundsAPI: Codeunit "Shpfy Refunds API";
        RefundId1: BigInteger;
        RefundId2: BigInteger;
        RefundId3: BigInteger;
        RefundId4: BigInteger;
    begin
        // [SCENARIO] Can create credit memo check returns
        // Non-zero refund = true
        // Linked return refund = true
        // Zero and not linked refund = false
        Initialize();

        // [GIVEN] Non-zero refund
        RefundId1 := ShopifyIds.Get('Refund').Get(5);
        // [GIVEN] Linked return refund
        RefundId2 := ShopifyIds.Get('Refund').Get(4);
        // [GIVEN] Zero and not linked refund
        RefundId3 := ShopifyIds.Get('Refund').Get(6);
        // [GIVEN] Zero refund with restock type return
        RefundId4 := ShopifyIds.Get('Refund').Get(7);

        // [WHEN] Execute VerifyRefundCanCreateCreditMemo
        RefundsAPI.VerifyRefundCanCreateCreditMemo(RefundId1);
        RefundsAPI.VerifyRefundCanCreateCreditMemo(RefundId2);
        RefundsAPI.VerifyRefundCanCreateCreditMemo(RefundId3);
        asserterror RefundsAPI.VerifyRefundCanCreateCreditMemo(RefundId4);

        // [THEN] Only RefundId3 throws an error
        LibraryAssert.ExpectedError('This refund cannot be used to create a credit memo or return order because it has already been considered during order import and reduced the quantity and amounts of the order. Only refunds with a non-zero refunded amount and related to real item returns can be used to create credit memos or return orders.');
    end;

    [Test]
    procedure UnitTestFillInRefundLineWithLocation()
    var
        RefundLine: Record "Shpfy Refund Line";
        RefundsAPI: Codeunit "Shpfy Refunds API";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        RefundId: BigInteger;
        JRefundLine: JsonObject;
        ReturnLocations: Dictionary of [BigInteger, BigInteger];
        RefundLocationId: BigInteger;
        RefundLineId: BigInteger;
    begin
        // [SCENARIO] Import refund lines with location
        Initialize();

        // [GIVEN] Refund Header
        RefundId := OrderRefundsHelper.CreateRefundHeader();
        // [GIVEN] Refund Line  response
        RefundLocationId := Any.IntegerInRange(100000, 999999);
        RefundLineId := Any.IntegerInRange(100000, 999999);
        CreateRefundLineResponse(JRefundLine, RefundLineId, RefundLocationId);

        // [WHEN] Execute RefundsAPI.FillInRefundLine
        RefundsAPI.FillInRefundLine(RefundId, JRefundLine, false, ReturnLocations);

        // [THEN] Refund Line with location is created
        LibraryAssert.IsTrue(RefundLine.Get(RefundId, RefundLineId), 'Refund line not creatred');
        LibraryAssert.AreEqual(RefundLocationId, RefundLine."Location Id", 'Refund line location not set');
    end;

    [Test]
    procedure UnitTestFillInRefundLineWithReturnLocations()
    var
        RefundLine: Record "Shpfy Refund Line";
        RefundsAPI: Codeunit "Shpfy Refunds API";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        RefundId: BigInteger;
        JRefundLine: JsonObject;
        ReturnLocations: Dictionary of [BigInteger, BigInteger];
        RefundLineId: BigInteger;
        LineItemId: BigInteger;
        ReturnLocationId: BigInteger;
    begin
        // [SCENARIO] Import refund lines with locations
        Initialize();

        // [GIVEN] Refund Header
        RefundId := OrderRefundsHelper.CreateRefundHeader();
        // [GIVEN] Refund Line  response
        RefundLineId := Any.IntegerInRange(100000, 999999);
        LineItemId := Any.IntegerInRange(100000, 999999);
        CreateRefundLineResponse(JRefundLine, RefundLineId, LineItemId, 0);
        //[GIVEN] Return Locations
        ReturnLocationId := Any.IntegerInRange(100000, 999999);
        ReturnLocations.Add(LineItemId, ReturnLocationId);

        // [WHEN] Execute RefundsAPI.FillInRefundLine
        RefundsAPI.FillInRefundLine(RefundId, JRefundLine, false, ReturnLocations);

        // [THEN] Refund Line with location is created
        LibraryAssert.IsTrue(RefundLine.Get(RefundId, RefundLineId), 'Refund line not creatred');
        LibraryAssert.AreEqual(ReturnLocationId, RefundLine."Location Id", 'Refund line location not set');
    end;

    [Test]
    procedure UnitTestCreateSalesOrderLineFromRefundWithDefaultLocation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Shop: Record "Shpfy Shop";
        Location: Record Location;
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
        RefundId: BigInteger;
        OrderId, OrderLineId : BigInteger;
        ReturnId: BigInteger;
    begin
        // [SCENARIO] Create sales credit memo line from refund with default location
        Initialize();

        // [GIVEN] Location
        CreateLocation(Location);

        // [GIVEN] Shop with setup to use default return location
        Shop := InitializeTest.CreateShop();
        Shop."Return Location Priority" := Enum::"Shpfy Return Location Priority"::"Default Return Location";
        Shop."Return Location" := Location.Code;
        Shop.Modify(false);

        //[GIVEN] Processed Shopify Order
        CerateProcessedShopifyOrder(OrderId, OrderLineId);
        // [GIVEN] Shopify Return
        CreateShopifyReturn(ReturnId, OrderId);
        // [GIVEN] Refund Header
        RefundId := OrderRefundsHelper.CreateRefundHeader(OrderId, ReturnId, 156.38, Shop.Code);
        // [GIVEN] Refund line without location
        OrderRefundsHelper.CreateRefundLine(RefundId, OrderLineId, 0, "Shpfy Restock Type"::Return);

        // [WHEN] Execute create credit memo
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);

        // [THEN] Credit Memo Line with default location is created
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        LibraryAssert.AreEqual(Location.Code, SalesLine."Location Code", 'Sales line location not set');
    end;

    [Test]
    procedure UnitTestProcessRefundWithPresentmentCurrency()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Shop: Record "Shpfy Shop";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        LibraryERM: Codeunit "Library - ERM";
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
        RefundId: BigInteger;
        OrderId, OrderLineId : BigInteger;
        PresentmentCurrencyCode: Code[10];
        Amount: Decimal;
        PresentmentAmount: Decimal;
    begin
        // [SCENARIO] Create sales credit memo from refund with presentment currency
        Initialize();

        // [GIVEN] Shop with setup to use presentment currency handling in order processing
        Shop := InitializeTest.CreateShop();
        Shop."Currency Handling" := "Shpfy Currency Handling"::"Presentment Currency";
        Shop.Modify(false);
        // [GIVEN] Presentment currency
        PresentmentCurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        // [GIVEN] Amount and Presentment amount
        Amount := Any.DecimalInRange(999, 2);
        Currency.Get(PresentmentCurrencyCode);
        PresentmentAmount := Round(CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                WorkDate(),
                PresentmentCurrencyCode,
                Amount,
                CurrencyExchangeRate.ExchangeRate(WorkDate(), PresentmentCurrencyCode)),
            Currency."Amount Rounding Precision");
        //[GIVEN] Processed Shopify Order
        CreateProcessedShopifyOrderWithPresenmentCurrency(
            OrderId,
            OrderLineId,
            Amount,
            PresentmentCurrencyCode,
            PresentmentAmount
        );
        // [GIVEN] Refund Header with presentment currency and amount
        RefundId := OrderRefundsHelper.CreateRefundHeaderWithPresentmentCurrency(
            OrderId,
            Amount,
            Shop.Code,
            PresentmentCurrencyCode,
            PresentmentAmount);
        // [GIVEN] Refund line with presenment amount
        OrderRefundsHelper.CreateRefundLineWithPresentmentCurrency(RefundId, OrderLineId, Amount, PresentmentAmount);

        // [WHEN] Execute create credit memo
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);

        // [THEN] Sales header has presentment currency
        LibraryAssert.AreEqual(PresentmentCurrencyCode, SalesHeader."Currency Code", 'Sales header should have presentment currency.');
        // [THEN] Credit Memo Line with return location is created
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        LibraryAssert.AreEqual(PresentmentAmount, SalesLine.Amount, 'Sales line amount should match presenment amount.')
    end;

    [Test]
    procedure UnitTestCreateSalesCrMemoLineFromRefundWithReturnLocation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Shop: Record "Shpfy Shop";
        Location: Record Location;
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
        RefundId: BigInteger;
        OrderId, OrderLineId : BigInteger;
        ReturnId: BigInteger;
        LocationId: BigInteger;
    begin
        // [SCENARIO] Create sales credit memo line from refund with return location
        Initialize();

        // [GIVEN] Shop with setup to use original return location
        Shop := InitializeTest.CreateShop();
        Shop."Return Location Priority" := Enum::"Shpfy Return Location Priority"::"Original -> Default Location";
        Shop."Return Location" := '';
        Shop.Modify(false);
        // [GIVEN] Location
        CreateLocation(Location);
        // [GIVEN] Shop Location
        LocationId := CreateShopLocation(Shop.Code, Location.Code);
        //[GIVEN] Processed Shopify Order
        CerateProcessedShopifyOrder(OrderId, OrderLineId);
        // [GIVEN] Shopify Return
        CreateShopifyReturn(ReturnId, OrderId);
        // [GIVEN] Refund Header
        RefundId := OrderRefundsHelper.CreateRefundHeader(OrderId, ReturnId, 156.38, Shop.Code);
        // [GIVEN] Refund line without location
        OrderRefundsHelper.CreateRefundLine(RefundId, OrderLineId, LocationId, "Shpfy Restock Type"::Return);

        // [WHEN] Execute create credit memo
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);

        // [THEN] Credit Memo Line with return location is created
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        LibraryAssert.AreEqual(Location.Code, SalesLine."Location Code", 'Sales line location not set');
    end;

    [Test]
    procedure UnitTestCreateCrMemoWithOrderLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RefundHeader: Record "Shpfy Refund Header";
        Shop: Record "Shpfy Shop";
        RefundId: BigInteger;
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
        CanCreateDocument: Boolean;
        ErrorInfo: ErrorInfo;
        ShopifyOrderNoLbl: Label 'Shopify Order No.: %1', Comment = '%1 = Order No.';
    begin
        // [SCENARIO] Create a Credit Memo from a Shopify Refund where the item is totally refunded.
        Initialize();
        Shop := InitializeTest.CreateShop();
        Shop."Process Returns As" := "Sales Document Type"::"Credit Memo";
        Shop."Shopify Order No. on Doc. Line" := true;
        Shop.Modify(false);

        // [GIVEN] Set the process of the document: "Auto Create Credit Memo";
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        // [GIVEN] The document type Refund
        // [GIVEN] The RefundId of the refund for creating the credit Memo.
        RefundId := ShopifyIds.Get('Refund').Get(1);

        // [WHEN] Execute IReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, errorInfo)
        CanCreateDocument := IReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, errorInfo);
        // [THEN] CancreateDocument must be true
        LibraryAssert.IsTrue(CanCreateDocument, 'The result of IReturnRefundProcess.CanCreateSalesDocumentFor must be true');

        // [WHEN] Execute IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId)
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);
        // [THEN] SalesHeader."Document Type" = Enum::"Sales Document Type"::"Credit Memo"
        LibraryAssert.AreEqual(Enum::"Sales Document Type"::"Credit Memo", SalesHeader."Document Type", 'SalesHeader."Document Type" must be a Credit Memo');
        // [THEN] Test if a line with order info is created
        RefundHeader.Get(RefundId);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Description, StrSubstNo(ShopifyOrderNoLbl, RefundHeader."Shopify Order No."));
        LibraryAssert.RecordIsNotEmpty(SalesLine);
        // Tear down
        ResetProcessOnRefund(RefundId);
    end;

    [Test]
    procedure UnitTestCreateCrMemoFailsIfNoAccountSet()
    var
        Shop: Record "Shpfy Shop";
        SalesHeader: Record "Sales Header";
        RefundHeader: Record "Shpfy Refund Header";
        RefundId: BigInteger;
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";        
        CanCreateDocument: Boolean;
        ErrorInfo: ErrorInfo;
        RefundAccount: Code[20];
    begin
        // [SCENARIO] Create a Credit Memo from a Shopify Refund where only the shipment is refunded.
        Initialize();
        Shop := InitializeTest.CreateShop();
        Shop."Process Returns As" := "Sales Document Type"::"Credit Memo";
        RefundAccount := Shop."Refund Account";
        Shop."Refund Account" := '';
        Shop.Modify(false);

        // [GIVEN] Set the process of the document: "Auto Create Credit Memo";
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        // [GIVEN] The document type Refund
        // [GIVEN] The RefundId of the refund for creating the credit Memo.
        RefundId := ShopifyIds.Get('Refund').Get(2);

        // [WHEN] Execute IReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, errorInfo)
        CanCreateDocument := IReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, errorInfo);
        // [THEN] CancreateDocument must be true
        LibraryAssert.IsTrue(CanCreateDocument, 'The result of IReturnRefundProcess.CanCreateSalesDocumentFor must be true');

        // [WHEN] Execute IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId)
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);
        // [THEN] Sales header is empty
        LibraryAssert.AreEqual(SalesHeader."No.", '', 'SalesHeader."No." must be empty');
        RefundHeader.Get(RefundId);
        LibraryAssert.AreEqual(RefundHeader."Has Processing Error", true, 'RefundHeader."Has Processing Error" must be true');

        // Tear down
        ResetProcessOnRefund(RefundId);
        Shop."Refund Account" := RefundAccount;
        Shop.Modify(false);
    end;

    [Test]
    procedure UnitTestCreateReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        Shop: Record "Shpfy Shop";
        RefundId: BigInteger;
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
        CanCreateDocument: Boolean;
        ErrorInfo: ErrorInfo;
    begin
        // [SCENARIO] Create a Return Order from a Shopify Refund where only the shipment is refunded.
        Initialize();

        // [GIVEN] Shop configured to process returns as Return Order
        Shop := InitializeTest.CreateShop();
        Shop."Process Returns As" := "Sales Document Type"::"Return Order";
        Shop.Modify(false);

        // [GIVEN] Set the process of the document: "Auto Create Credit Memo";
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        // [GIVEN] The document type Refund
        // [GIVEN] The RefundId of the refund for creating the Return Order.
        RefundId := ShopifyIds.Get('Refund').Get(2);

        // [WHEN] Execute IReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, errorInfo)
        CanCreateDocument := IReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, errorInfo);
        // [THEN] CanCreateDocument must be true
        LibraryAssert.IsTrue(CanCreateDocument, 'The result of IReturnRefundProcess.CanCreateSalesDocumentFor must be true');

        // [WHEN] Execute IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId)
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);
        // [THEN] SalesHeader."Document Type" = Enum::"Sales Document Type"::"Return Order"
        LibraryAssert.AreEqual(Enum::"Sales Document Type"::"Return Order", SalesHeader."Document Type", 'SalesHeader."Document Type" must be a Return Order');
        // Tear down
        ResetProcessOnRefund(RefundId);
    end;

    [Test]
    procedure UnitTestConsiderRefundsSubtractsTaxFromTotalAmount()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderId: BigInteger;
        OrderLineId: BigInteger;
        RefundId: BigInteger;
        SubtotalAmount: Decimal;
        VATAmount: Decimal;
        RefundSubtotalAmount: Decimal;
        RefundTaxAmount: Decimal;
    begin
        // [SCENARIO] Total Amount is correctly reduced by both subtotal and tax when processing refunds.
        Initialize();

        // [GIVEN] Amounts for an order with tax
        SubtotalAmount := 1200;
        VATAmount := 300;
        RefundSubtotalAmount := 1000;
        RefundTaxAmount := 250;

        // [GIVEN] A processed Shopify order with Total Amount = Subtotal + VAT
        CreateProcessedShopifyOrderWithVAT(OrderId, OrderLineId, SubtotalAmount, VATAmount);

        // [GIVEN] Shop with "Return and Refund Process" set to "Import Only"
        Shop := InitializeTest.CreateShop();
        Shop."Return and Refund Process" := "Shpfy ReturnRefund ProcessType"::"Import Only";
        Shop.Modify(false);

        // [GIVEN] A refund with both subtotal and tax amounts
        OrderRefundsHelper.SetDefaultSeed();
        RefundId := OrderRefundsHelper.CreateRefundHeader(OrderId, 0, RefundSubtotalAmount + RefundTaxAmount, Shop.Code);
        OrderRefundsHelper.CreateRefundLineWithTaxAmount(RefundId, OrderLineId, RefundSubtotalAmount, RefundTaxAmount);

        // [WHEN] ConsiderRefundsInQuantityAndAmounts is executed
        OrderHeader.Get(OrderId);
        ImportOrder.SetShop(Shop.Code);
        ImportOrder.ConsiderRefundsInQuantityAndAmounts(OrderHeader);

        // [THEN] Total Amount = original total - (refund subtotal + refund tax)
        LibraryAssert.AreEqual(SubtotalAmount + VATAmount - RefundSubtotalAmount - RefundTaxAmount, OrderHeader."Total Amount", 'Total Amount must be reduced by refund subtotal and tax.');
        // [THEN] Presentment Total Amount is also correctly reduced
        LibraryAssert.AreEqual(SubtotalAmount + VATAmount - RefundSubtotalAmount - RefundTaxAmount, OrderHeader."Presentment Total Amount", 'Presentment Total Amount must be reduced by refund subtotal and tax.');
        // [THEN] VAT Amount is reduced by refund tax
        LibraryAssert.AreEqual(VATAmount - RefundTaxAmount, OrderHeader."VAT Amount", 'VAT Amount must be reduced by refund tax.');
        // [THEN] Subtotal Amount is reduced by refund subtotal
        LibraryAssert.AreEqual(SubtotalAmount - RefundSubtotalAmount, OrderHeader."Subtotal Amount", 'Subtotal Amount must be reduced by refund subtotal.');
    end;

    [Test]
    procedure UnitTestConsiderRefundsReducesLineDiscountForRefundedQuantity()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        Shop: Record "Shpfy Shop";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderId: BigInteger;
        OrderLineId: BigInteger;
        RefundId: BigInteger;
        UnitPrice: Decimal;
        PresentmentUnitPrice: Decimal;
        OriginalQuantity: Integer;
        OriginalDiscount: Decimal;
        PresentmentOriginalDiscount: Decimal;
        RefundQuantity: Integer;
        RefundSubtotal: Decimal;
        PresentmentRefundSubtotal: Decimal;
        ExpectedDiscount: Decimal;
        ExpectedPresentmentDiscount: Decimal;
    begin
        // [SCENARIO] When a refund removes part of a line's quantity, the line's discount amount is reduced by
        // the discount that was allocated to the removed quantity, so the remaining quantity is not over-discounted.
        Initialize();

        // [GIVEN] A line with shop unit price 48, quantity 2 and a 20% order-level discount of 19.20 (per unit 9.60)
        UnitPrice := 48;
        OriginalQuantity := 2;
        OriginalDiscount := 19.2;
        // [GIVEN] Distinct presentment values: unit price 60, discount 24.00 (20% of 120, per unit 12.00)
        PresentmentUnitPrice := 60;
        PresentmentOriginalDiscount := 24;
        // [GIVEN] A refund that removes one unit; discounted subtotals are 38.40 shop / 48.00 presentment
        RefundQuantity := 1;
        RefundSubtotal := 38.4;
        PresentmentRefundSubtotal := 48;
        // [GIVEN] The remaining unit must keep only its share of the discount: 9.60 shop / 12.00 presentment
        ExpectedDiscount := 9.6;
        ExpectedPresentmentDiscount := 12;

        // [GIVEN] A processed Shopify order with that discounted line
        CreateProcessedShopifyOrderWithDiscountedLine(OrderId, OrderLineId, UnitPrice, PresentmentUnitPrice, OriginalQuantity, OriginalDiscount, PresentmentOriginalDiscount);

        // [GIVEN] Shop with "Return and Refund Process" set to "Import Only"
        Shop := InitializeTest.CreateShop();
        Shop."Return and Refund Process" := "Shpfy ReturnRefund ProcessType"::"Import Only";
        Shop.Modify(false);

        // [GIVEN] A zero-amount (order edit) refund that removes one unit but keeps its discounted subtotal
        OrderRefundsHelper.SetDefaultSeed();
        RefundId := OrderRefundsHelper.CreateRefundHeader(OrderId, 0, 0, Shop.Code);
        OrderRefundsHelper.CreateRefundLineWithoutCreditMemo(RefundId, OrderLineId, RefundQuantity, UnitPrice, PresentmentUnitPrice, RefundSubtotal, PresentmentRefundSubtotal);

        // [WHEN] ConsiderRefundsInQuantityAndAmounts is executed
        OrderHeader.Get(OrderId);
        ImportOrder.SetShop(Shop.Code);
        ImportOrder.ConsiderRefundsInQuantityAndAmounts(OrderHeader);

        // [THEN] The line quantity is reduced by the refunded quantity
        OrderLine.Get(OrderId, OrderLineId);
        LibraryAssert.AreEqual(OriginalQuantity - RefundQuantity, OrderLine.Quantity, 'Quantity must be reduced by the refunded quantity.');
        // [THEN] The shop and presentment discounts are each reduced to the remaining quantity's share
        LibraryAssert.AreEqual(ExpectedDiscount, OrderLine."Discount Amount", 'Discount Amount must be reduced by the refunded quantity''s discount.');
        LibraryAssert.AreEqual(ExpectedPresentmentDiscount, OrderLine."Presentment Discount Amount", 'Presentment Discount Amount must be reduced by the refunded quantity''s presentment discount.');
    end;

    [Test]
    procedure UnitTestConsiderRefundsAggregatesMultipleRefundLinesForLineDiscount()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        Shop: Record "Shpfy Shop";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderId: BigInteger;
        OrderLineId: BigInteger;
        RefundId: BigInteger;
        UnitPrice: Decimal;
        PresentmentUnitPrice: Decimal;
    begin
        // [SCENARIO] Multiple refund lines against the same order line are aggregated (CalcSums) so the line discount
        // is reduced by the combined discount of all refunded quantities, not just a single refund line.
        Initialize();

        // [GIVEN] A line with shop unit price 48, quantity 5 and a 20% discount of 48.00 (per unit 9.60)
        // [GIVEN] Distinct presentment values: unit price 60, discount 60.00 (per unit 12.00)
        UnitPrice := 48;
        PresentmentUnitPrice := 60;
        CreateProcessedShopifyOrderWithDiscountedLine(OrderId, OrderLineId, UnitPrice, PresentmentUnitPrice, 5, 48, 60);

        // [GIVEN] Shop with "Return and Refund Process" set to "Import Only"
        Shop := InitializeTest.CreateShop();
        Shop."Return and Refund Process" := "Shpfy ReturnRefund ProcessType"::"Import Only";
        Shop.Modify(false);

        // [GIVEN] Two refund lines on the same order line: one removes 1 unit, the other removes 2 units
        OrderRefundsHelper.SetDefaultSeed();
        RefundId := OrderRefundsHelper.CreateRefundHeader(OrderId, 0, 0, Shop.Code);
        OrderRefundsHelper.CreateRefundLineWithoutCreditMemo(RefundId, OrderLineId, 1, UnitPrice, PresentmentUnitPrice, 38.4, 48);
        OrderRefundsHelper.CreateRefundLineWithoutCreditMemo(RefundId, OrderLineId, 2, UnitPrice, PresentmentUnitPrice, 76.8, 96);

        // [WHEN] ConsiderRefundsInQuantityAndAmounts is executed
        OrderHeader.Get(OrderId);
        ImportOrder.SetShop(Shop.Code);
        ImportOrder.ConsiderRefundsInQuantityAndAmounts(OrderHeader);

        // [THEN] The 3 refunded units are removed, leaving quantity 2
        OrderLine.Get(OrderId, OrderLineId);
        LibraryAssert.AreEqual(2, OrderLine.Quantity, 'Quantity must be reduced by the combined refunded quantity.');
        // [THEN] The discount is reduced by the combined discount of the 3 refunded units: 28.80 shop / 36.00 presentment
        LibraryAssert.AreEqual(19.2, OrderLine."Discount Amount", 'Discount Amount must be reduced by the combined refunded discount.');
        LibraryAssert.AreEqual(24, OrderLine."Presentment Discount Amount", 'Presentment Discount Amount must be reduced by the combined refunded presentment discount.');
    end;

    [Test]
    procedure UnitTestCreateCrMemoFromRefundWithExchangeItem()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        RefundHeader: Record "Shpfy Refund Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        OrderId: BigInteger;
        OriginalOrderLineId: BigInteger;
        ExchangeOrderLineId: BigInteger;
        ReturnId: BigInteger;
        RefundId: BigInteger;
        OriginalAmount: Decimal;
        ExchangeAmount: Decimal;
        RefundTotal: Decimal;
        ItemSalesLineCount: Integer;
        RefundAccountLineCount: Integer;
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
    begin
        // [SCENARIO] Create a Credit Memo from a Shopify refund that originates from a return with an exchange item.
        // [SCENARIO] The original item (returned) yields a positive-qty sales line; the exchange item (kept by customer)
        // [SCENARIO] yields a negative-qty sales line that offsets the credit memo total so it matches the Shopify refund
        // [SCENARIO] total without an extra balancing G/L Refund Account line.
        Initialize();
        Shop := InitializeTest.CreateShop();
        Shop."Process Returns As" := "Sales Document Type"::"Credit Memo";
        Shop."Currency Handling" := "Shpfy Currency Handling"::"Shop Currency";
        Shop.Modify(false);

        OriginalAmount := 1893;
        ExchangeAmount := 365;
        RefundTotal := OriginalAmount - ExchangeAmount; // 1,528

        // [GIVEN] A processed Shopify order with two lines: an original item and an exchange item flagged Is Exchange Item.
        OrderRefundsHelper.SetDefaultSeed();
        OrderId := OrderRefundsHelper.CreateShopifyOrder();
        OrderHeader.Get(OrderId);
        OrderHeader."Shop Code" := Shop.Code;
        OrderHeader."Total Amount" := OriginalAmount; // BC sales invoice value (exchange item excluded)
        OrderHeader."Subtotal Amount" := OriginalAmount;
        OrderHeader."VAT Amount" := 0;
        OrderHeader."Presentment Total Amount" := OriginalAmount;
        OrderHeader."Presentment Subtotal Amount" := OriginalAmount;
        OrderHeader."Shipping Charges Amount" := 0;
        OrderHeader.Processed := true;
        OrderHeader."Processed Currency Handling" := "Shpfy Currency Handling"::"Shop Currency";
        OrderHeader.Modify(false);
        OriginalOrderLineId := OrderRefundsHelper.CreateOrderLineWithUnitPrice(OrderId, 10000, Any.IntegerInRange(100000, 999999), Any.IntegerInRange(100000, 999999), OriginalAmount);
        ExchangeOrderLineId := OrderRefundsHelper.CreateOrderLineWithUnitPrice(OrderId, 20000, Any.IntegerInRange(100000, 999999), Any.IntegerInRange(100000, 999999), ExchangeAmount);
        OrderRefundsHelper.MarkOrderLineAsExchangeItem(OrderId, ExchangeOrderLineId);
        OrderRefundsHelper.ProcessShopifyOrder(OrderId);

        // [GIVEN] A return for the original item plus an exchange item, and a refund whose total reflects the net refund.
        ReturnId := OrderRefundsHelper.CreateReturn(OrderId);
        OrderRefundsHelper.CreateReturnLine(ReturnId, OriginalOrderLineId, 'DEFECTIVE');
        RefundId := OrderRefundsHelper.CreateRefundHeader(OrderId, ReturnId, RefundTotal, Shop.Code);
        OrderRefundsHelper.CreateRefundLineForReturnedItem(RefundId, OriginalOrderLineId, 1, OriginalAmount);
        OrderRefundsHelper.CreateExchangeRefundLine(RefundId, ExchangeOrderLineId, 1, ExchangeAmount);

        // [WHEN] CreateSalesDocument is invoked through the Auto Create Credit Memo process.
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);

        // [THEN] A Credit Memo was created.
        LibraryAssert.AreEqual(Enum::"Sales Document Type"::"Credit Memo", SalesHeader."Document Type", 'Sales Header must be a Credit Memo.');

        // [THEN] The credit memo amount equals RefundHeader.Total Refunded Amount.
        RefundHeader.Get(RefundId);
        SalesHeader.CalcFields("Amount Including VAT");
        LibraryAssert.AreNearlyEqual(RefundHeader."Total Refunded Amount", SalesHeader."Amount Including VAT", 0.5, 'Credit memo Amount Including VAT must equal RefundHeader."Total Refunded Amount" (no balancing G/L line should be needed).');

        // [THEN] No Sales Line of Type::"G/L Account" was added pointing at the Refund Account.
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        SalesLine.SetRange("No.", Shop."Refund Account");
        RefundAccountLineCount := SalesLine.Count();
        LibraryAssert.AreEqual(0, RefundAccountLineCount, 'No Sales Line of Type G/L Account pointing at Shop."Refund Account" must be created.');

        // [THEN] The credit memo contains two Type::Item lines (the original positive line and the exchange negative line).
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        ItemSalesLineCount := SalesLine.Count();
        LibraryAssert.AreEqual(2, ItemSalesLineCount, 'Credit memo must contain exactly two Type::Item lines (returned item +qty, exchange item -qty).');

        // [THEN] One item line carries a positive quantity, one a negative quantity, summing to the net refund.
        SalesLine.SetFilter(Quantity, '>%1', 0);
        LibraryAssert.IsFalse(SalesLine.IsEmpty(), 'Credit memo must contain a positive-qty Type::Item line for the returned item.');
        SalesLine.SetFilter(Quantity, '<%1', 0);
        LibraryAssert.IsFalse(SalesLine.IsEmpty(), 'Credit memo must contain a negative-qty Type::Item line for the exchange item.');

        // Tear down
        ResetProcessOnRefund(RefundId);
    end;

    [Test]
    procedure UnitTestCreateCrMemoFromRefundWithMoreExpensiveExchangeItem()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        RefundHeader: Record "Shpfy Refund Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        OrderId: BigInteger;
        OriginalOrderLineId: BigInteger;
        ExchangeOrderLineId: BigInteger;
        ReturnId: BigInteger;
        RefundId: BigInteger;
        OriginalAmount: Decimal;
        ExchangeAmount: Decimal;
        RefundTotal: Decimal;
        ItemSalesLineCount: Integer;
        RefundAccountLineCount: Integer;
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
    begin
        // [SCENARIO] Create a Credit Memo from a Shopify refund whose return exchanges the returned item for a MORE expensive one.
        // [SCENARIO] Shopify floors Total Refunded Amount at 0 (the customer pays the difference), so the returned item (+qty) and
        // [SCENARIO] the exchange item (-qty) net to a negative credit memo total. No balancing G/L Refund Account line must be
        // [SCENARIO] added to force the total back up to the (zero) refund amount.
        Initialize();
        Shop := InitializeTest.CreateShop();
        Shop."Process Returns As" := "Sales Document Type"::"Credit Memo";
        Shop."Currency Handling" := "Shpfy Currency Handling"::"Shop Currency";
        Shop.Modify(false);

        OriginalAmount := 100; // returned item
        ExchangeAmount := 250; // kept exchange item, more expensive
        RefundTotal := 0; // Shopify refunds nothing; the customer pays the 150 difference

        // [GIVEN] A processed Shopify order with the original item and an exchange item flagged Is Exchange Item.
        OrderRefundsHelper.SetDefaultSeed();
        OrderId := OrderRefundsHelper.CreateShopifyOrder();
        OrderHeader.Get(OrderId);
        OrderHeader."Shop Code" := Shop.Code;
        OrderHeader."Total Amount" := OriginalAmount;
        OrderHeader."Subtotal Amount" := OriginalAmount;
        OrderHeader."VAT Amount" := 0;
        OrderHeader."Presentment Total Amount" := OriginalAmount;
        OrderHeader."Presentment Subtotal Amount" := OriginalAmount;
        OrderHeader."Shipping Charges Amount" := 0;
        OrderHeader.Processed := true;
        OrderHeader."Processed Currency Handling" := "Shpfy Currency Handling"::"Shop Currency";
        OrderHeader.Modify(false);
        OriginalOrderLineId := OrderRefundsHelper.CreateOrderLineWithUnitPrice(OrderId, 10000, Any.IntegerInRange(100000, 999999), Any.IntegerInRange(100000, 999999), OriginalAmount);
        ExchangeOrderLineId := OrderRefundsHelper.CreateOrderLineWithUnitPrice(OrderId, 20000, Any.IntegerInRange(100000, 999999), Any.IntegerInRange(100000, 999999), ExchangeAmount);
        OrderRefundsHelper.MarkOrderLineAsExchangeItem(OrderId, ExchangeOrderLineId);
        OrderRefundsHelper.ProcessShopifyOrder(OrderId);

        // [GIVEN] A return for the original item and a refund whose total is 0 (kept item is more expensive).
        ReturnId := OrderRefundsHelper.CreateReturn(OrderId);
        OrderRefundsHelper.CreateReturnLine(ReturnId, OriginalOrderLineId, 'DEFECTIVE');
        RefundId := OrderRefundsHelper.CreateRefundHeader(OrderId, ReturnId, RefundTotal, Shop.Code);
        OrderRefundsHelper.CreateRefundLineForReturnedItem(RefundId, OriginalOrderLineId, 1, OriginalAmount);
        OrderRefundsHelper.CreateExchangeRefundLine(RefundId, ExchangeOrderLineId, 1, ExchangeAmount);

        // [WHEN] CreateSalesDocument is invoked through the Auto Create Credit Memo process.
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);

        // [THEN] A Credit Memo was created.
        LibraryAssert.AreEqual(Enum::"Sales Document Type"::"Credit Memo", SalesHeader."Document Type", 'Sales Header must be a Credit Memo.');

        // [THEN] No Sales Line of Type::"G/L Account" pointing at the Refund Account was added.
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        SalesLine.SetRange("No.", Shop."Refund Account");
        RefundAccountLineCount := SalesLine.Count();
        LibraryAssert.AreEqual(0, RefundAccountLineCount, 'No balancing G/L Refund Account line must be created when the exchange item is more expensive.');

        // [THEN] The credit memo contains exactly two Type::Item lines (returned +qty, exchange -qty).
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        ItemSalesLineCount := SalesLine.Count();
        LibraryAssert.AreEqual(2, ItemSalesLineCount, 'Credit memo must contain exactly two Type::Item lines (returned +qty, exchange -qty).');

        // [THEN] The credit memo total equals the net of the item lines (returned - exchange), not the floored refund amount.
        SalesHeader.CalcFields("Amount Including VAT");
        LibraryAssert.AreNearlyEqual(OriginalAmount - ExchangeAmount, SalesHeader."Amount Including VAT", 0.5, 'Credit memo total must equal returned minus exchange amount (negative), with no balancing line.');

        // [THEN] Precondition sanity: Shopify Total Refunded Amount is 0 for this scenario.
        RefundHeader.Get(RefundId);
        LibraryAssert.AreEqual(0, RefundHeader."Total Refunded Amount", 'Total Refunded Amount must be 0 for a more-expensive-exchange refund.');

        // Tear down
        ResetProcessOnRefund(RefundId);
    end;

    [Test]
    procedure UnitTestExchangeCreditMemoCarriesShopifyOrderIdentifiers()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        OrderId: BigInteger;
        OriginalOrderLineId: BigInteger;
        ExchangeOrderLineId: BigInteger;
        ReturnId: BigInteger;
        RefundId: BigInteger;
        OriginalAmount: Decimal;
        ExchangeAmount: Decimal;
        ShopifyOrderNo: Code[50];
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
    begin
        // [SCENARIO] A credit memo created from a return-with-exchange refund carries the Shopify order identifiers on the
        // [SCENARIO] header and on the exchange-item line, so the invoice moved out of it stays linked to the Shopify order.
        Initialize();
        Shop := InitializeTest.CreateShop();
        Shop."Process Returns As" := "Sales Document Type"::"Credit Memo";
        Shop."Currency Handling" := "Shpfy Currency Handling"::"Shop Currency";
        Shop.Modify(false);

        OriginalAmount := 200;
        ExchangeAmount := 50;
        ShopifyOrderNo := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(ShopifyOrderNo));

        // [GIVEN] A processed Shopify order (with a Shopify order number) with an original item and an exchange item.
        OrderRefundsHelper.SetDefaultSeed();
        OrderId := OrderRefundsHelper.CreateShopifyOrder();
        OrderHeader.Get(OrderId);
        OrderHeader."Shop Code" := Shop.Code;
        OrderHeader."Shopify Order No." := ShopifyOrderNo;
        OrderHeader."Total Amount" := OriginalAmount;
        OrderHeader."Subtotal Amount" := OriginalAmount;
        OrderHeader."VAT Amount" := 0;
        OrderHeader."Presentment Total Amount" := OriginalAmount;
        OrderHeader."Presentment Subtotal Amount" := OriginalAmount;
        OrderHeader."Shipping Charges Amount" := 0;
        OrderHeader.Processed := true;
        OrderHeader."Processed Currency Handling" := "Shpfy Currency Handling"::"Shop Currency";
        OrderHeader.Modify(false);
        OriginalOrderLineId := OrderRefundsHelper.CreateOrderLineWithUnitPrice(OrderId, 10000, Any.IntegerInRange(100000, 999999), Any.IntegerInRange(100000, 999999), OriginalAmount);
        ExchangeOrderLineId := OrderRefundsHelper.CreateOrderLineWithUnitPrice(OrderId, 20000, Any.IntegerInRange(100000, 999999), Any.IntegerInRange(100000, 999999), ExchangeAmount);
        OrderRefundsHelper.MarkOrderLineAsExchangeItem(OrderId, ExchangeOrderLineId);
        OrderRefundsHelper.ProcessShopifyOrder(OrderId);

        // [GIVEN] A return for the original item and a refund with a returned line and an exchange line.
        ReturnId := OrderRefundsHelper.CreateReturn(OrderId);
        OrderRefundsHelper.CreateReturnLine(ReturnId, OriginalOrderLineId, 'DEFECTIVE');
        RefundId := OrderRefundsHelper.CreateRefundHeader(OrderId, ReturnId, OriginalAmount - ExchangeAmount, Shop.Code);
        OrderRefundsHelper.CreateRefundLineForReturnedItem(RefundId, OriginalOrderLineId, 1, OriginalAmount);
        OrderRefundsHelper.CreateExchangeRefundLine(RefundId, ExchangeOrderLineId, 1, ExchangeAmount);

        // [WHEN] The credit memo is created through the Auto Create Credit Memo process.
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);

        // [THEN] The credit memo header carries the Shopify order identifiers.
        LibraryAssert.AreEqual(OrderHeader."Shopify Order Id", SalesHeader."Shpfy Order Id", 'Credit memo header must carry the Shopify Order Id.');
        LibraryAssert.AreEqual(ShopifyOrderNo, SalesHeader."Shpfy Order No.", 'Credit memo header must carry the Shopify Order No.');

        // [THEN] The exchange-item line (negative quantity) carries the Shopify order line identifiers.
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter(Quantity, '<%1', 0);
        LibraryAssert.IsTrue(SalesLine.FindFirst(), 'The exchange item must be a negative-qty item line.');
        LibraryAssert.AreEqual(ExchangeOrderLineId, SalesLine."Shpfy Order Line Id", 'Exchange line must carry the Shopify Order Line Id.');
        LibraryAssert.AreEqual(ShopifyOrderNo, SalesLine."Shpfy Order No.", 'Exchange line must carry the Shopify Order No.');

        // [THEN] The returned-item line (positive quantity) stays a pure credit line without order-line identifiers.
        SalesLine.SetRange(Quantity);
        SalesLine.SetFilter(Quantity, '>%1', 0);
        LibraryAssert.IsTrue(SalesLine.FindFirst(), 'The returned item must be a positive-qty item line.');
        LibraryAssert.IsTrue(SalesLine."Shpfy Order Line Id" = 0, 'Returned line must not carry a Shopify Order Line Id.');

        // Tear down
        ResetProcessOnRefund(RefundId);
    end;

    [Test]
    procedure UnitTestExchangeInvoiceFromCreditMemoKeepsShopifyLink()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        CreditMemoHeader: Record "Sales Header";
        InvoiceHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocLinkToBCDoc: Record "Shpfy Doc. Link To Doc.";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        OrderId: BigInteger;
        OriginalOrderLineId: BigInteger;
        ExchangeOrderLineId: BigInteger;
        ReturnId: BigInteger;
        RefundId: BigInteger;
        OriginalAmount: Decimal;
        ExchangeAmount: Decimal;
        ShopifyOrderNo: Code[50];
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
    begin
        // [SCENARIO] Moving the negative exchange-item line out of the refund credit memo produces a sales invoice that keeps
        // [SCENARIO] the Shopify order identifiers and is linked back to the originating Shopify order (Linked Documents).
        Initialize();
        Shop := InitializeTest.CreateShop();
        Shop."Process Returns As" := "Sales Document Type"::"Credit Memo";
        Shop."Currency Handling" := "Shpfy Currency Handling"::"Shop Currency";
        Shop.Modify(false);

        OriginalAmount := 200;
        ExchangeAmount := 50;
        ShopifyOrderNo := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(ShopifyOrderNo));

        // [GIVEN] A processed Shopify order and an exchange refund turned into a credit memo.
        OrderRefundsHelper.SetDefaultSeed();
        OrderId := OrderRefundsHelper.CreateShopifyOrder();
        OrderHeader.Get(OrderId);
        OrderHeader."Shop Code" := Shop.Code;
        OrderHeader."Shopify Order No." := ShopifyOrderNo;
        OrderHeader."Total Amount" := OriginalAmount;
        OrderHeader."Subtotal Amount" := OriginalAmount;
        OrderHeader."VAT Amount" := 0;
        OrderHeader."Presentment Total Amount" := OriginalAmount;
        OrderHeader."Presentment Subtotal Amount" := OriginalAmount;
        OrderHeader."Shipping Charges Amount" := 0;
        OrderHeader.Processed := true;
        OrderHeader."Processed Currency Handling" := "Shpfy Currency Handling"::"Shop Currency";
        OrderHeader.Modify(false);
        OriginalOrderLineId := OrderRefundsHelper.CreateOrderLineWithUnitPrice(OrderId, 10000, Any.IntegerInRange(100000, 999999), Any.IntegerInRange(100000, 999999), OriginalAmount);
        ExchangeOrderLineId := OrderRefundsHelper.CreateOrderLineWithUnitPrice(OrderId, 20000, Any.IntegerInRange(100000, 999999), Any.IntegerInRange(100000, 999999), ExchangeAmount);
        OrderRefundsHelper.MarkOrderLineAsExchangeItem(OrderId, ExchangeOrderLineId);
        OrderRefundsHelper.ProcessShopifyOrder(OrderId);
        ReturnId := OrderRefundsHelper.CreateReturn(OrderId);
        OrderRefundsHelper.CreateReturnLine(ReturnId, OriginalOrderLineId, 'DEFECTIVE');
        RefundId := OrderRefundsHelper.CreateRefundHeader(OrderId, ReturnId, OriginalAmount - ExchangeAmount, Shop.Code);
        OrderRefundsHelper.CreateRefundLineForReturnedItem(RefundId, OriginalOrderLineId, 1, OriginalAmount);
        OrderRefundsHelper.CreateExchangeRefundLine(RefundId, ExchangeOrderLineId, 1, ExchangeAmount);
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        CreditMemoHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);

        // [GIVEN] The credit memo is reopened so its negative line can be moved.
        ReleaseSalesDocument.Reopen(CreditMemoHeader);

        // [WHEN] The negative exchange line is moved to a new sales invoice (Move Negative Lines).
        CopyDocumentMgt.SetProperties(true, false, true, true, true, false, false);
        InvoiceHeader."Document Type" := InvoiceHeader."Document Type"::Invoice;
        CopyDocumentMgt.CopySalesDoc(Enum::"Sales Document Type From"::"Credit Memo", CreditMemoHeader."No.", InvoiceHeader);
        InvoiceHeader.Get(InvoiceHeader."Document Type"::Invoice, InvoiceHeader."No.");

        // [THEN] The created invoice keeps the Shopify order identifiers on the header.
        LibraryAssert.AreEqual(OrderHeader."Shopify Order Id", InvoiceHeader."Shpfy Order Id", 'Exchange invoice header must keep the Shopify Order Id.');
        LibraryAssert.AreEqual(ShopifyOrderNo, InvoiceHeader."Shpfy Order No.", 'Exchange invoice header must keep the Shopify Order No.');

        // [THEN] The exchange item line on the invoice keeps the Shopify order line identifiers.
        SalesLine.SetRange("Document Type", InvoiceHeader."Document Type");
        SalesLine.SetRange("Document No.", InvoiceHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        LibraryAssert.IsTrue(SalesLine.FindFirst(), 'The moved exchange item must be an item line on the invoice.');
        LibraryAssert.AreEqual(ExchangeOrderLineId, SalesLine."Shpfy Order Line Id", 'Exchange invoice line must keep the Shopify Order Line Id.');

        // [THEN] The invoice is linked to the Shopify order (visible in the order's Linked Documents).
        DocLinkToBCDoc.SetRange("Shopify Document Type", "Shpfy Shop Document Type"::"Shopify Shop Order");
        DocLinkToBCDoc.SetRange("Shopify Document Id", OrderHeader."Shopify Order Id");
        DocLinkToBCDoc.SetRange("Document Type", "Shpfy Document Type"::"Sales Invoice");
        DocLinkToBCDoc.SetRange("Document No.", InvoiceHeader."No.");
        LibraryAssert.IsFalse(DocLinkToBCDoc.IsEmpty(), 'The exchange invoice must be linked to the Shopify order.');

        // Tear down
        ResetProcessOnRefund(RefundId);
    end;

    [Test]
    procedure UnitTestExchangeLineDoesNotFlagProcessedOrderAsConflicting()
    var
        OrderHeader: Record "Shpfy Order Header";
        TempOrderLine: Record "Shpfy Order Line" temporary;
        Hash: Codeunit "Shpfy Hash";
        ImportOrder: Codeunit "Shpfy Import Order";
        JOrder: JsonObject;
        JShippingPrice: JsonObject;
        JShopMoney: JsonObject;
        ExchangeLineIds: List of [BigInteger];
        NoExchangeLineIds: List of [BigInteger];
        OriginalLineId: BigInteger;
        ExchangeLineId: BigInteger;
    begin
        // [SCENARIO] A processed order re-imported after a return-with-exchange (which adds an exchange line item to the Shopify
        // [SCENARIO] order) must not be flagged as conflicting, because the exchange line is handled through the refund flow.
        Initialize();

        OriginalLineId := 101;
        ExchangeLineId := 202;

        // [GIVEN] A processed order whose stored line-item redundancy and quantity reflect only the original (non-exchange) line.
        OrderHeader."Current Total Items Quantity" := 1;
        OrderHeader."Line Items Redundancy Code" := Hash.CalcHash('|' + Format(OriginalLineId));
        OrderHeader."Shipping Charges Amount" := 0;

        // [GIVEN] The re-imported order lines contain the original line plus a newly added exchange line.
        TempOrderLine.Init();
        TempOrderLine."Shopify Order Id" := 111111;
        TempOrderLine."Line Id" := OriginalLineId;
        TempOrderLine.Quantity := 1;
        TempOrderLine.Insert();
        TempOrderLine.Init();
        TempOrderLine."Shopify Order Id" := 111111;
        TempOrderLine."Line Id" := ExchangeLineId;
        TempOrderLine.Quantity := 1;
        TempOrderLine.Insert();

        // [GIVEN] The imported order JSON reports the current (post-return) quantity and unchanged shipping.
        JShopMoney.Add('amount', 0);
        JShippingPrice.Add('shopMoney', JShopMoney);
        JOrder.Add('totalShippingPriceSet', JShippingPrice);
        JOrder.Add('currentSubtotalLineItemsQuantity', 1);

        // [WHEN/THEN] With the exchange line recognized, the order is NOT flagged as conflicting.
        ExchangeLineIds.Add(ExchangeLineId);
        LibraryAssert.IsFalse(
            ImportOrder.IsImportedOrderConflictingExistingOrder(JOrder, OrderHeader, TempOrderLine, ExchangeLineIds),
            'A processed order re-imported with an added exchange line must not be treated as conflicting.');

        // [THEN] Control: without excluding the exchange line, the added line changes the redundancy hash and the order is
        // [THEN] (correctly) detected as changed - proving the exchange exclusion is what suppresses the false conflict.
        LibraryAssert.IsTrue(
            ImportOrder.IsImportedOrderConflictingExistingOrder(JOrder, OrderHeader, TempOrderLine, NoExchangeLineIds),
            'Control: the added line changes the redundancy hash, so without exchange exclusion the order is detected as changed.');
    end;

    [Test]
    procedure UnitTestDoesNotCreateCrMemoFromRefundWithPendingTransaction()
    var
        SalesHeader: Record "Sales Header";
        Shop: Record "Shpfy Shop";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
        RefundId: BigInteger;
        OrderId, OrderLineId : BigInteger;
        ReturnId: BigInteger;
    begin
        // [SCENARIO] A credit memo is not created from a refund while it still has a pending transaction (Bug 640432).
        Initialize();

        // [GIVEN] Shop configured to auto create credit memos
        Shop := InitializeTest.CreateShop();
        Shop."Process Returns As" := "Sales Document Type"::"Credit Memo";
        Shop.Modify(false);

        // [GIVEN] A processed Shopify order with a return and a refund that can create a credit memo
        CerateProcessedShopifyOrder(OrderId, OrderLineId);
        CreateShopifyReturn(ReturnId, OrderId);
        RefundId := OrderRefundsHelper.CreateRefundHeader(OrderId, ReturnId, 156.38, Shop.Code);
        OrderRefundsHelper.CreateRefundLine(RefundId, OrderLineId, "Shpfy Restock Type"::Return);
        // [GIVEN] The refund still has a pending transaction in Shopify
        OrderRefundsHelper.CreateRefundTransaction(OrderId, RefundId, 156.38, "Shpfy Transaction Status"::Pending);

        // [WHEN] Execute IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId)
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);

        // [THEN] No sales document is created (creation is skipped and retried on a later sync)
        LibraryAssert.AreEqual('', SalesHeader."No.", 'No credit memo must be created while the refund has a pending transaction.');
    end;

    [Test]
    procedure UnitTestCreatesCrMemoFromRefundWithSucceededTransaction()
    var
        SalesHeader: Record "Sales Header";
        Shop: Record "Shpfy Shop";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        IReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
        RefundId: BigInteger;
        OrderId, OrderLineId : BigInteger;
        ReturnId: BigInteger;
    begin
        // [SCENARIO] The pending-transaction guard only blocks pending transactions; a succeeded transaction still creates the credit memo (Bug 640432).
        Initialize();

        // [GIVEN] Shop configured to auto create credit memos
        Shop := InitializeTest.CreateShop();
        Shop."Process Returns As" := "Sales Document Type"::"Credit Memo";
        Shop.Modify(false);

        // [GIVEN] A processed Shopify order with a return and a refund that can create a credit memo
        CerateProcessedShopifyOrder(OrderId, OrderLineId);
        CreateShopifyReturn(ReturnId, OrderId);
        RefundId := OrderRefundsHelper.CreateRefundHeader(OrderId, ReturnId, 156.38, Shop.Code);
        OrderRefundsHelper.CreateRefundLine(RefundId, OrderLineId, "Shpfy Restock Type"::Return);
        // [GIVEN] The refund transaction has already succeeded
        OrderRefundsHelper.CreateRefundTransaction(OrderId, RefundId, 156.38, "Shpfy Transaction Status"::Success);

        // [WHEN] Execute IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId)
        IReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        SalesHeader := IReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId);

        // [THEN] A credit memo is created
        LibraryAssert.AreEqual(Enum::"Sales Document Type"::"Credit Memo", SalesHeader."Document Type", 'A credit memo must be created when the refund transaction has succeeded.');
        LibraryAssert.AreNotEqual('', SalesHeader."No.", 'The credit memo must have a number.');
    end;

    [Test]
    procedure UnitTestVerifyRefundCanCreateCreditMemoErrorsWithPendingTransaction()
    var
        Shop: Record "Shpfy Shop";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        RefundsAPI: Codeunit "Shpfy Refunds API";
        RefundId: BigInteger;
        OrderId, OrderLineId : BigInteger;
        ReturnId: BigInteger;
    begin
        // [SCENARIO] Manually verifying a refund that still has a pending transaction throws an error (Bug 640432).
        Initialize();
        Shop := InitializeTest.CreateShop();

        // [GIVEN] A refund that can create a credit memo but still has a pending transaction
        CerateProcessedShopifyOrder(OrderId, OrderLineId);
        CreateShopifyReturn(ReturnId, OrderId);
        RefundId := OrderRefundsHelper.CreateRefundHeader(OrderId, ReturnId, 156.38, Shop.Code);
        OrderRefundsHelper.CreateRefundLine(RefundId, OrderLineId, "Shpfy Restock Type"::Return);
        OrderRefundsHelper.CreateRefundTransaction(OrderId, RefundId, 156.38, "Shpfy Transaction Status"::Pending);

        // [WHEN] Execute RefundsAPI.VerifyRefundCanCreateCreditMemo
        asserterror RefundsAPI.VerifyRefundCanCreateCreditMemo(RefundId);

        // [THEN] It throws the pending-transactions error
        LibraryAssert.ExpectedError('This refund cannot be used to create a credit memo or return order yet because it has one or more pending transactions. The refunded amount is only final once the related transactions succeed. Retry after the transactions are no longer pending.');
    end;

    local procedure Initialize()
    var
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
    begin
        Any.SetDefaultSeed();

        if IsInitialized then
            exit;

        InitializeTest.Run();
        ShopifyIds := OrderRefundsHelper.CreateShopifyDocuments();

        IsInitialized := true;
        Commit();
    end;

    local procedure EnsureTaxAreaExists(TaxAreaCode: Code[20])
    var
        TaxArea: Record "Tax Area";
    begin
        if not TaxArea.Get(TaxAreaCode) then begin
            TaxArea.Code := TaxAreaCode;
            TaxArea.Insert();
        end;
    end;

    local procedure ResetProcessOnRefund(ReFundId: Integer)
    var
        ShpfyDocLinkToDoc: Record "Shpfy Doc. Link To Doc.";
    begin
        ShpfyDocLinkToDoc.SetRange("Shopify Document Type", ShpfyDocLinkToDoc."Shopify Document Type"::"Shopify Shop Refund");
        ShpfyDocLinkToDoc.SetRange("Shopify Document Id", ReFundId);
        ShpfyDocLinkToDoc.DeleteAll();
    end;

    local procedure CreateRefundLineResponse(var JRefundLine: JsonObject; RefundLineId: BigInteger; RefundLocationId: BigInteger)
    var
        LineItemId: BigInteger;
    begin
        LineItemId := Any.IntegerInRange(100000, 999999);
        CreateRefundLineResponse(JRefundLine, RefundLineId, LineItemId, RefundLocationId);
    end;

    local procedure CreateRefundLineResponse(var JRefundLine: JsonObject; RefundLineId: BigInteger; LineItemId: BigInteger; RefundLocationId: BigInteger)
    var
        RefundLineLbl: Label '{"id": "gid://shopify/RefundLineItem/%1", "lineItem": {"id": "gid://shopify/LineItem/%2"}, "quantity": 1, "restockType": "no_restock", "location": {"legacyResourceId": %3}}', Comment = '%1 = RefundLineId, %2 = LineItemId, %3 = RefundLocationId', Locked = true;
    begin
        JRefundLine.ReadFrom(StrSubstNo(RefundLineLbl, RefundLineId, LineItemId, RefundLocationId));
    end;

    local procedure CerateProcessedShopifyOrder(var OrderId: BigInteger; var OrderLineId: BigInteger)
    var
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
    begin
        OrderRefundsHelper.SetDefaultSeed();
        OrderId := OrderRefundsHelper.CreateShopifyOrder();
        OrderLineId := OrderRefundsHelper.CreateOrderLine(OrderId, 10000, Any.IntegerInRange(100000, 999999), Any.IntegerInRange(100000, 999999));
        OrderRefundsHelper.ProcessShopifyOrder(OrderId);
    end;

    local procedure CreateProcessedShopifyOrderWithPresenmentCurrency(var OrderId: BigInteger; var OrderLineId: BigInteger; Amount: Decimal; PresentmentCurrencyCode: Code[10]; PresentmentAmount: Decimal)
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
    begin
        OrderRefundsHelper.SetDefaultSeed();
        OrderId := OrderRefundsHelper.CreateShopifyOrder();
        OrderHeader.Get(OrderId);
        OrderHeader."Total Amount" := Amount;
        OrderHeader."Subtotal Amount" := Amount;
        OrderHeader."Presentment Currency Code" := PresentmentCurrencyCode;
        OrderHeader."Presentment Total Amount" := PresentmentAmount;
        OrderHeader."Presentment Subtotal Amount" := PresentmentAmount;
        OrderHeader."Shipping Charges Amount" := 0;
        OrderHeader."VAT Amount" := 0;
        OrderHeader.Processed := true;
        OrderHeader."Processed Currency Handling" := "Shpfy Currency Handling"::"Presentment Currency";
        OrderHeader.Modify(false);

        OrderLineId := OrderRefundsHelper.CreateOrderLine(OrderId, 10000, Any.IntegerInRange(100000, 999999), Any.IntegerInRange(100000, 999999));
        OrderLine.Get(OrderId, OrderLineId);
        OrderLine."Presentment Unit Price" := PresentmentAmount;
        OrderLine.Modify(false);
        OrderRefundsHelper.ProcessShopifyOrder(OrderId);
    end;

    local procedure CreateShopifyReturn(var ReturnId: BigInteger; OrderId: BigInteger)
    var
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
    begin
        OrderRefundsHelper.SetDefaultSeed();
        ReturnId := OrderRefundsHelper.CreateReturn(OrderId);
        OrderRefundsHelper.CreateReturnLine(ReturnId, OrderId, '');
        OrderRefundsHelper.CreateUnverifiedReturnLine(ReturnId, '');
    end;

    local procedure CreateProcessedShopifyOrderWithVAT(var OrderId: BigInteger; var OrderLineId: BigInteger; SubtotalAmount: Decimal; VATAmount: Decimal)
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
    begin
        OrderRefundsHelper.SetDefaultSeed();
        OrderId := OrderRefundsHelper.CreateShopifyOrder();
        OrderHeader.Get(OrderId);
        OrderHeader."Subtotal Amount" := SubtotalAmount;
        OrderHeader."Total Amount" := SubtotalAmount + VATAmount;
        OrderHeader."VAT Amount" := VATAmount;
        OrderHeader."Presentment Subtotal Amount" := SubtotalAmount;
        OrderHeader."Presentment Total Amount" := SubtotalAmount + VATAmount;
        OrderHeader."Presentment VAT Amount" := VATAmount;
        OrderHeader."Shipping Charges Amount" := 0;
        OrderHeader.Processed := true;
        OrderHeader.Modify(false);

        OrderLineId := OrderRefundsHelper.CreateOrderLine(OrderId, 10000, Any.IntegerInRange(100000, 999999), Any.IntegerInRange(100000, 999999));
        OrderRefundsHelper.ProcessShopifyOrder(OrderId);
    end;

    local procedure CreateProcessedShopifyOrderWithDiscountedLine(var OrderId: BigInteger; var OrderLineId: BigInteger; UnitPrice: Decimal; PresentmentUnitPrice: Decimal; Quantity: Integer; DiscountAmount: Decimal; PresentmentDiscountAmount: Decimal)
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
    begin
        OrderRefundsHelper.SetDefaultSeed();
        OrderId := OrderRefundsHelper.CreateShopifyOrder();
        OrderHeader.Get(OrderId);
        OrderHeader.Processed := true;
        OrderHeader.Modify(false);

        OrderLineId := OrderRefundsHelper.CreateDiscountedOrderLine(OrderId, 10000, Any.IntegerInRange(100000, 999999), Any.IntegerInRange(100000, 999999), UnitPrice, PresentmentUnitPrice, Quantity, DiscountAmount, PresentmentDiscountAmount);
        OrderRefundsHelper.ProcessShopifyOrder(OrderId);
    end;

    local procedure CreateLocation(var Location: Record Location)
    begin
        Location.Init();
        Location.Code := CopyStr(Any.AlphanumericText(10), 1, MaxStrLen(Location.Code));
        Location.Insert();
    end;

    local procedure CreateShopLocation(ShopCode: Code[20]; LocationCode: Code[10]): BigInteger
    var
        ShopLocation: Record "Shpfy Shop Location";
    begin
        ShopLocation.Init();
        ShopLocation."Shop Code" := ShopCode;
        ShopLocation.Id := Any.IntegerInRange(100000, 999999);
        ShopLocation."Default Location Code" := LocationCode;
        ShopLocation.Insert(false);
        exit(ShopLocation.Id);
    end;
}
