// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Integration.Shopify;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.TestLibraries.Utilities;

codeunit 139587 "Shpfy Order Totals FB Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryAssert: Codeunit "Library Assert";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        Any: Codeunit Any;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
    end;

    [Test]
    [HandlerFunctions('SalesOrderPageHandler')]
    procedure TestOpenSalesOrderResolvedAndNavigated()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        OrderTotalsFactBox: TestPage "Shpfy Order Totals FactBox";
    begin
        // [SCENARIO] The Order Totals factbox resolves and opens the linked open sales order.
        Initialize();

        // [GIVEN] A Shopify order linked to an open sales order
        CreateShopifyOrderHeader(OrderHeader);
        LibrarySales.CreateSalesOrder(SalesHeader);
        OrderHeader."Sales Order No." := SalesHeader."No.";
        OrderHeader.Modify();
        CreateDocumentLink(OrderHeader."Shopify Order Id", "Shpfy Document Type"::"Sales Order", SalesHeader."No.");

        // [WHEN] Opening the Order Totals factbox for the Shopify order
        OrderTotalsFactBox.OpenView();
        OrderTotalsFactBox.GoToRecord(OrderHeader);

        // [THEN] The whole Sales Document section resolves from the open sales order
        VerifyOpenSalesDocumentSection(OrderTotalsFactBox, SalesHeader);

        // [WHEN] Drilling down on the sales document number
        OrderTotalsFactBox.SalesDocumentNo.Drilldown();

        // [THEN] The open sales order page opens for the exact linked document
        LibraryAssert.AreEqual(Format(SalesHeader."No."), LibraryVariableStorage.DequeueText(), 'The linked open sales order must open.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesInvoicePageHandler')]
    procedure TestOpenSalesInvoiceResolvedAndNavigated()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        OrderTotalsFactBox: TestPage "Shpfy Order Totals FactBox";
    begin
        // [SCENARIO] The Order Totals factbox resolves and opens the linked open sales invoice.
        Initialize();

        // [GIVEN] A Shopify order linked to an open sales invoice
        CreateShopifyOrderHeader(OrderHeader);
        LibrarySales.CreateSalesInvoice(SalesHeader);
        OrderHeader."Sales Invoice No." := SalesHeader."No.";
        OrderHeader.Modify();
        CreateDocumentLink(OrderHeader."Shopify Order Id", "Shpfy Document Type"::"Sales Invoice", SalesHeader."No.");

        // [WHEN] Opening the Order Totals factbox for the Shopify order
        OrderTotalsFactBox.OpenView();
        OrderTotalsFactBox.GoToRecord(OrderHeader);

        // [THEN] The whole Sales Document section resolves from the open sales invoice
        VerifyOpenSalesDocumentSection(OrderTotalsFactBox, SalesHeader);

        // [WHEN] Drilling down on the sales document number
        OrderTotalsFactBox.SalesDocumentNo.Drilldown();

        // [THEN] The open sales invoice page opens for the exact linked document
        LibraryAssert.AreEqual(Format(SalesHeader."No."), LibraryVariableStorage.DequeueText(), 'The linked open sales invoice must open.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoicePageHandler')]
    procedure TestPostedSalesInvoiceResolvedAndNavigated()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocLinkToBCDoc: Record "Shpfy Doc. Link To Doc.";
        OrderTotalsFactBox: TestPage "Shpfy Order Totals FactBox";
        OpenInvoiceNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO] After posting, the Order Totals factbox resolves and opens the posted sales invoice.
        Initialize();

        // [GIVEN] A Shopify order linked to an open sales invoice that is then posted
        CreateShopifyOrderHeader(OrderHeader);
        LibrarySales.CreateSalesInvoice(SalesHeader);
        OpenInvoiceNo := SalesHeader."No.";
        OrderHeader."Sales Invoice No." := OpenInvoiceNo;
        OrderHeader.Modify();
        CreateDocumentLink(OrderHeader."Shopify Order Id", "Shpfy Document Type"::"Sales Invoice", OpenInvoiceNo);

        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        SalesInvoiceHeader.Get(PostedInvoiceNo);

        // [GIVEN] Posting created a posted-sales-invoice document link
        DocLinkToBCDoc.SetRange("Shopify Document Type", "Shpfy Shop Document Type"::"Shopify Shop Order");
        DocLinkToBCDoc.SetRange("Shopify Document Id", OrderHeader."Shopify Order Id");
        DocLinkToBCDoc.SetRange("Document Type", "Shpfy Document Type"::"Posted Sales Invoice");
        LibraryAssert.IsTrue(DocLinkToBCDoc.FindFirst(), 'A posted sales invoice link should exist after posting.');
        LibraryAssert.AreEqual(PostedInvoiceNo, DocLinkToBCDoc."Document No.", 'The posted sales invoice link must point to the posted invoice.');

        // [WHEN] Opening the Order Totals factbox for the Shopify order
        OrderTotalsFactBox.OpenView();
        OrderTotalsFactBox.GoToRecord(OrderHeader);

        // [THEN] The whole Sales Document section resolves from the posted sales invoice, not the stale open invoice
        VerifyPostedSalesInvoiceSection(OrderTotalsFactBox, SalesInvoiceHeader);

        // [WHEN] Drilling down on the sales document number
        OrderTotalsFactBox.SalesDocumentNo.Drilldown();

        // [THEN] The posted sales invoice page opens for the exact linked document
        LibraryAssert.AreEqual(Format(PostedInvoiceNo), LibraryVariableStorage.DequeueText(), 'The linked posted sales invoice must open.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TestUnresolvableDocumentClearsStaleValues()
    var
        LinkedOrderHeader: Record "Shpfy Order Header";
        UnlinkedOrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        OrderTotalsFactBox: TestPage "Shpfy Order Totals FactBox";
    begin
        // [SCENARIO] Selecting an order without a resolvable sales document clears the previously shown values.
        Initialize();

        // [GIVEN] A Shopify order linked to an open sales invoice
        CreateShopifyOrderHeader(LinkedOrderHeader);
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LinkedOrderHeader."Sales Invoice No." := SalesHeader."No.";
        LinkedOrderHeader.Modify();
        CreateDocumentLink(LinkedOrderHeader."Shopify Order Id", "Shpfy Document Type"::"Sales Invoice", SalesHeader."No.");

        // [GIVEN] A Shopify order with a stale sales invoice number but no resolvable document
        CreateShopifyOrderHeader(UnlinkedOrderHeader);
        UnlinkedOrderHeader."Sales Invoice No." := 'NONEXISTENT-INV';
        UnlinkedOrderHeader.Modify();

        // [WHEN] Showing the resolvable order in the factbox
        OrderTotalsFactBox.OpenView();
        OrderTotalsFactBox.GoToRecord(LinkedOrderHeader);

        // [THEN] The factbox shows the linked document values
        LibraryAssert.AreEqual(Format(SalesHeader."No."), OrderTotalsFactBox.SalesDocumentNo.Value, 'The resolvable order must show its sales document.');
        LibraryAssert.AreNotEqual(0, OrderTotalsFactBox."Total Amount Incl. VAT".AsDecimal(), 'The resolvable order must show non-zero totals.');

        // [WHEN] Switching to the order without a resolvable document
        OrderTotalsFactBox.GoToRecord(UnlinkedOrderHeader);

        // [THEN] The factbox clears the document number and totals instead of retaining stale values
        LibraryAssert.AreEqual('', OrderTotalsFactBox.SalesDocumentNo.Value, 'Sales Document No. must be cleared when no document resolves.');
        LibraryAssert.AreEqual(0, OrderTotalsFactBox.TotalAmountExclVAT.AsDecimal(), 'Total Amount Excl. VAT must be cleared when no document resolves.');
        LibraryAssert.AreEqual(0, OrderTotalsFactBox."Total VAT Amount".AsDecimal(), 'Total VAT must be cleared when no document resolves.');
        LibraryAssert.AreEqual(0, OrderTotalsFactBox."Total Amount Incl. VAT".AsDecimal(), 'Total Amount Incl. VAT must be cleared when no document resolves.');
        LibraryAssert.AreEqual(0, OrderTotalsFactBox.NumberOfLines.AsInteger(), 'Number of Lines must be cleared when no document resolves.');
    end;

    [Test]
    [HandlerFunctions('SalesLinesPageHandler')]
    procedure TestNumberOfLinesDrillDownOpenDocument()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        OrderTotalsFactBox: TestPage "Shpfy Order Totals FactBox";
    begin
        // [SCENARIO] The Number of Lines drill-down opens the open document's sales lines.
        Initialize();

        // [GIVEN] A Shopify order linked to an open sales order
        CreateShopifyOrderHeader(OrderHeader);
        LibrarySales.CreateSalesOrder(SalesHeader);
        OrderHeader."Sales Order No." := SalesHeader."No.";
        OrderHeader.Modify();
        CreateDocumentLink(OrderHeader."Shopify Order Id", "Shpfy Document Type"::"Sales Order", SalesHeader."No.");

        OrderTotalsFactBox.OpenView();
        OrderTotalsFactBox.GoToRecord(OrderHeader);

        // [WHEN] Drilling down on the number of lines
        OrderTotalsFactBox.NumberOfLines.Drilldown();

        // [THEN] The sales lines list opens filtered to the open sales order
        LibraryAssert.AreEqual(Format(SalesHeader."No."), LibraryVariableStorage.DequeueText(), 'Sales Lines must be filtered to the open sales order.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceLinesPageHandler')]
    procedure TestNumberOfLinesDrillDownPostedInvoice()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        OrderTotalsFactBox: TestPage "Shpfy Order Totals FactBox";
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO] The Number of Lines drill-down opens the posted invoice's lines after posting.
        Initialize();

        // [GIVEN] A Shopify order whose sales invoice has been posted
        CreateShopifyOrderHeader(OrderHeader);
        LibrarySales.CreateSalesInvoice(SalesHeader);
        OrderHeader."Sales Invoice No." := SalesHeader."No.";
        OrderHeader.Modify();
        CreateDocumentLink(OrderHeader."Shopify Order Id", "Shpfy Document Type"::"Sales Invoice", SalesHeader."No.");
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        OrderTotalsFactBox.OpenView();
        OrderTotalsFactBox.GoToRecord(OrderHeader);

        // [WHEN] Drilling down on the number of lines
        OrderTotalsFactBox.NumberOfLines.Drilldown();

        // [THEN] The posted sales invoice lines list opens filtered to the posted invoice
        LibraryAssert.AreEqual(Format(PostedInvoiceNo), LibraryVariableStorage.DequeueText(), 'Posted Sales Invoice Lines must be filtered to the posted invoice.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ShpfyOrderPageHandler')]
    procedure TestShopifyOrderNoDrillDownOpensShopifyOrder()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTotalsFactBox: TestPage "Shpfy Order Totals FactBox";
        ShopifyOrderNo: Code[50];
    begin
        // [SCENARIO] The Shopify Order No. drill-down opens the Shopify order card.
        Initialize();

        // [GIVEN] A Shopify order with a known Shopify order number
        CreateShopifyOrderHeader(OrderHeader);
        ShopifyOrderNo := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(ShopifyOrderNo));
        OrderHeader."Shopify Order No." := ShopifyOrderNo;
        OrderHeader.Modify();

        OrderTotalsFactBox.OpenView();
        OrderTotalsFactBox.GoToRecord(OrderHeader);

        // [WHEN] Drilling down on the Shopify order number
        OrderTotalsFactBox."Shopify Order No.".Drilldown();

        // [THEN] The Shopify order card opens for the same order
        LibraryAssert.AreEqual(Format(ShopifyOrderNo), LibraryVariableStorage.DequeueText(), 'The Shopify order card must open for the same order.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TestShopifyTotalsSectionShowsShopValues()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTotalsFactBox: TestPage "Shpfy Order Totals FactBox";
    begin
        // [SCENARIO] For a shop-currency order the Shopify totals section is shown with the shop amounts.
        Initialize();

        // [GIVEN] A shop-currency Shopify order with Shopify totals
        CreateShopifyOrderHeader(OrderHeader);
        OrderHeader."Processed Currency Handling" := "Shpfy Currency Handling"::"Shop Currency";
        OrderHeader."Subtotal Amount" := 100;
        OrderHeader."Shipping Charges Amount" := 15;
        OrderHeader."VAT Amount" := 25;
        OrderHeader."Payment Rounding Amount" := 2;
        OrderHeader."Total Amount" := 142;
        OrderHeader.Modify();

        // [WHEN] Opening the Order Totals factbox
        OrderTotalsFactBox.OpenView();
        OrderTotalsFactBox.GoToRecord(OrderHeader);

        // [THEN] The Shopify totals section is visible and shows the shop amounts
        LibraryAssert.IsTrue(OrderTotalsFactBox."Total Amount".Visible(), 'Shopify totals must be visible for a shop-currency order.');
        LibraryAssert.IsFalse(OrderTotalsFactBox."Presentment Total Amount".Visible(), 'Presentment totals must be hidden for a shop-currency order.');
        LibraryAssert.AreEqual(100, OrderTotalsFactBox."Subtotal Amount".AsDecimal(), 'Subtotal Amount must be shown.');
        LibraryAssert.AreEqual(15, OrderTotalsFactBox."Shipping Charges Amount".AsDecimal(), 'Shipping Charges Amount must be shown.');
        LibraryAssert.AreEqual(25, OrderTotalsFactBox.VATAmount.AsDecimal(), 'VAT Amount must be shown.');
        LibraryAssert.AreEqual(2, OrderTotalsFactBox.RoundingAmount.AsDecimal(), 'Payment Rounding Amount must be shown.');
        LibraryAssert.AreEqual(142, OrderTotalsFactBox."Total Amount".AsDecimal(), 'Total Amount must be shown.');
    end;

    [Test]
    procedure TestPresentmentTotalsSectionShownForPresentmentOrder()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTotalsFactBox: TestPage "Shpfy Order Totals FactBox";
    begin
        // [SCENARIO] For a presentment-currency order the presentment totals section is shown instead of the shop totals.
        Initialize();

        // [GIVEN] A presentment-currency Shopify order with presentment totals
        CreateShopifyOrderHeader(OrderHeader);
        OrderHeader."Processed Currency Handling" := "Shpfy Currency Handling"::"Presentment Currency";
        OrderHeader."Presentment Subtotal Amount" := 200;
        OrderHeader."Pres. Shipping Charges Amount" := 30;
        OrderHeader."Presentment VAT Amount" := 50;
        OrderHeader."Pres. Payment Rounding Amount" := 4;
        OrderHeader."Presentment Total Amount" := 284;
        OrderHeader.Modify();

        // [WHEN] Opening the Order Totals factbox
        OrderTotalsFactBox.OpenView();
        OrderTotalsFactBox.GoToRecord(OrderHeader);

        // [THEN] The presentment totals section is visible and shows the presentment amounts
        LibraryAssert.IsTrue(OrderTotalsFactBox."Presentment Total Amount".Visible(), 'Presentment totals must be visible for a presentment-currency order.');
        LibraryAssert.IsFalse(OrderTotalsFactBox."Total Amount".Visible(), 'Shopify totals must be hidden for a presentment-currency order.');
        LibraryAssert.AreEqual(200, OrderTotalsFactBox."Presentment Subtotal Amount".AsDecimal(), 'Presentment Subtotal Amount must be shown.');
        LibraryAssert.AreEqual(30, OrderTotalsFactBox."Presentment Shipping Charges Amount".AsDecimal(), 'Presentment Shipping Charges Amount must be shown.');
        LibraryAssert.AreEqual(50, OrderTotalsFactBox."Presentment VAT Amount".AsDecimal(), 'Presentment VAT Amount must be shown.');
        LibraryAssert.AreEqual(4, OrderTotalsFactBox."Presentment Payment Rounding Amount".AsDecimal(), 'Presentment Payment Rounding Amount must be shown.');
        LibraryAssert.AreEqual(284, OrderTotalsFactBox."Presentment Total Amount".AsDecimal(), 'Presentment Total Amount must be shown.');
    end;

    [Test]
    procedure TestShopifyTotalsExcludeExchangeItemShopCurrency()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTotalsFactBox: TestPage "Shpfy Order Totals FactBox";
    begin
        // [SCENARIO] For a shop-currency order with an exchange item, the Shopify totals exclude the exchange item's
        // [SCENARIO] contribution, so they reconcile with the BC sales document (which also excludes the exchange item).
        Initialize();

        // [GIVEN] A shop-currency Shopify order whose totals include an exchange item (subtotal 50, tax 5).
        CreateShopifyOrderHeader(OrderHeader);
        OrderHeader."Processed Currency Handling" := "Shpfy Currency Handling"::"Shop Currency";
        OrderHeader."Subtotal Amount" := 250; // 200 kept + 50 exchange
        OrderHeader."VAT Amount" := 25;        // 20 kept + 5 exchange
        OrderHeader."Total Amount" := 275;     // 220 kept + 55 exchange
        OrderHeader."Shipping Charges Amount" := 0;
        OrderHeader.Modify();

        // [GIVEN] The order has an exchange item line (unit price 50) with its own tax line (5).
        CreateExchangeItemWithTax(OrderHeader."Shopify Order Id", 50, 0, 5, 0);

        // [WHEN] Opening the Order Totals factbox
        OrderTotalsFactBox.OpenView();
        OrderTotalsFactBox.GoToRecord(OrderHeader);

        // [THEN] The shown Shopify totals exclude the exchange item.
        LibraryAssert.AreEqual(200, OrderTotalsFactBox."Subtotal Amount".AsDecimal(), 'Subtotal must exclude the exchange item.');
        LibraryAssert.AreEqual(20, OrderTotalsFactBox.VATAmount.AsDecimal(), 'VAT must exclude the exchange item tax.');
        LibraryAssert.AreEqual(220, OrderTotalsFactBox."Total Amount".AsDecimal(), 'Total must exclude the exchange item subtotal and tax.');
    end;

    [Test]
    procedure TestShopifyTotalsExcludeExchangeItemPresentmentCurrency()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTotalsFactBox: TestPage "Shpfy Order Totals FactBox";
    begin
        // [SCENARIO] For a presentment-currency order with an exchange item, the presentment totals exclude the exchange
        // [SCENARIO] item's contribution.
        Initialize();

        // [GIVEN] A presentment-currency Shopify order whose presentment totals include an exchange item (subtotal 100, tax 10).
        CreateShopifyOrderHeader(OrderHeader);
        OrderHeader."Processed Currency Handling" := "Shpfy Currency Handling"::"Presentment Currency";
        OrderHeader."Presentment Subtotal Amount" := 500; // 400 kept + 100 exchange
        OrderHeader."Presentment VAT Amount" := 50;        // 40 kept + 10 exchange
        OrderHeader."Presentment Total Amount" := 550;     // 440 kept + 110 exchange
        OrderHeader."Pres. Shipping Charges Amount" := 0;
        OrderHeader.Modify();

        // [GIVEN] The order has an exchange item line (presentment unit price 100) with its own tax line (presentment 10).
        CreateExchangeItemWithTax(OrderHeader."Shopify Order Id", 0, 100, 0, 10);

        // [WHEN] Opening the Order Totals factbox
        OrderTotalsFactBox.OpenView();
        OrderTotalsFactBox.GoToRecord(OrderHeader);

        // [THEN] The shown presentment totals exclude the exchange item.
        LibraryAssert.AreEqual(400, OrderTotalsFactBox."Presentment Subtotal Amount".AsDecimal(), 'Presentment Subtotal must exclude the exchange item.');
        LibraryAssert.AreEqual(40, OrderTotalsFactBox."Presentment VAT Amount".AsDecimal(), 'Presentment VAT must exclude the exchange item tax.');
        LibraryAssert.AreEqual(440, OrderTotalsFactBox."Presentment Total Amount".AsDecimal(), 'Presentment Total must exclude the exchange item subtotal and tax.');
    end;

    local procedure CreateExchangeItemWithTax(ShopifyOrderId: BigInteger; UnitPrice: Decimal; PresentmentUnitPrice: Decimal; TaxAmount: Decimal; PresentmentTaxAmount: Decimal)
    var
        OrderLine: Record "Shpfy Order Line";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        LineId: BigInteger;
    begin
        LineId := Any.IntegerInRange(1000000, 2147483647);
        OrderLine.Init();
        OrderLine."Shopify Order Id" := ShopifyOrderId;
        OrderLine."Line Id" := LineId;
        OrderLine.Quantity := 1;
        OrderLine."Unit Price" := UnitPrice;
        OrderLine."Presentment Unit Price" := PresentmentUnitPrice;
        OrderLine."Is Exchange Item" := true;
        OrderLine.Insert();

        OrderTaxLine.Init();
        OrderTaxLine."Parent Id" := LineId;
        OrderTaxLine.Amount := TaxAmount;
        OrderTaxLine."Presentment Amount" := PresentmentTaxAmount;
        OrderTaxLine.Insert(true);
    end;

    local procedure VerifyOpenSalesDocumentSection(var OrderTotalsFactBox: TestPage "Shpfy Order Totals FactBox"; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        ExpectedExclVAT: Decimal;
        ExpectedInclVAT: Decimal;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.CalcSums(Amount, "Amount Including VAT");
        ExpectedExclVAT := SalesLine.Amount;
        ExpectedInclVAT := SalesLine."Amount Including VAT";

        LibraryAssert.AreEqual(Format(SalesHeader."No."), OrderTotalsFactBox.SalesDocumentNo.Value, 'Sales Document No. must be the linked open document.');
        LibraryAssert.AreEqual(ExpectedExclVAT, OrderTotalsFactBox.TotalAmountExclVAT.AsDecimal(), 'Total Amount Excl. VAT must match the open document.');
        LibraryAssert.AreEqual(ExpectedInclVAT - ExpectedExclVAT, OrderTotalsFactBox."Total VAT Amount".AsDecimal(), 'Total VAT must match the open document.');
        LibraryAssert.AreEqual(ExpectedInclVAT, OrderTotalsFactBox."Total Amount Incl. VAT".AsDecimal(), 'Total Amount Incl. VAT must match the open document.');
        LibraryAssert.AreEqual(SalesLine.Count(), OrderTotalsFactBox.NumberOfLines.AsInteger(), 'Number of Lines must match the open document.');
        LibraryAssert.AreEqual(SalesHeader."Prices Including VAT", OrderTotalsFactBox.PricesIncludingVAT.AsBoolean(), 'Prices Including VAT must match the open document.');
        LibraryAssert.AreEqual(Format(GetDocumentCurrencyCode(SalesHeader."Currency Code")), OrderTotalsFactBox.CurrencyCode.Value, 'Currency Code must match the open document.');
    end;

    local procedure VerifyPostedSalesInvoiceSection(var OrderTotalsFactBox: TestPage "Shpfy Order Totals FactBox"; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");

        LibraryAssert.AreEqual(Format(SalesInvoiceHeader."No."), OrderTotalsFactBox.SalesDocumentNo.Value, 'Sales Document No. must be the posted sales invoice.');
        LibraryAssert.AreEqual(SalesInvoiceHeader.Amount, OrderTotalsFactBox.TotalAmountExclVAT.AsDecimal(), 'Total Amount Excl. VAT must match the posted sales invoice.');
        LibraryAssert.AreEqual(SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount, OrderTotalsFactBox."Total VAT Amount".AsDecimal(), 'Total VAT must match the posted sales invoice.');
        LibraryAssert.AreEqual(SalesInvoiceHeader."Amount Including VAT", OrderTotalsFactBox."Total Amount Incl. VAT".AsDecimal(), 'Total Amount Incl. VAT must match the posted sales invoice.');
        LibraryAssert.AreEqual(SalesInvoiceLine.Count(), OrderTotalsFactBox.NumberOfLines.AsInteger(), 'Number of Lines must match the posted sales invoice.');
        LibraryAssert.AreEqual(SalesInvoiceHeader."Prices Including VAT", OrderTotalsFactBox.PricesIncludingVAT.AsBoolean(), 'Prices Including VAT must match the posted sales invoice.');
        LibraryAssert.AreEqual(Format(GetDocumentCurrencyCode(SalesInvoiceHeader."Currency Code")), OrderTotalsFactBox.CurrencyCode.Value, 'Currency Code must match the posted sales invoice.');
    end;

    local procedure GetDocumentCurrencyCode(DocumentCurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if DocumentCurrencyCode <> '' then
            exit(DocumentCurrencyCode);
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."LCY Code");
    end;

    local procedure CreateShopifyOrderHeader(var OrderHeader: Record "Shpfy Order Header")
    begin
        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := GetUnusedShopifyOrderId();
        OrderHeader.Processed := true;
        OrderHeader.Insert();
    end;

    local procedure GetUnusedShopifyOrderId(): BigInteger
    var
        ExistingOrderHeader: Record "Shpfy Order Header";
        DocLinkToBCDoc: Record "Shpfy Doc. Link To Doc.";
        CandidateId: BigInteger;
    begin
        // The shared database can contain leftover order headers and document links from other tests,
        // so pick an id that is not used by any existing header or document link.
        repeat
            CandidateId := Any.IntegerInRange(1000000, 2147483647);
            ExistingOrderHeader.SetRange("Shopify Order Id", CandidateId);
            DocLinkToBCDoc.SetRange("Shopify Document Id", CandidateId);
        until ExistingOrderHeader.IsEmpty() and DocLinkToBCDoc.IsEmpty();
        exit(CandidateId);
    end;

    local procedure CreateDocumentLink(ShopifyOrderId: BigInteger; DocumentType: Enum "Shpfy Document Type"; DocumentNo: Code[20])
    var
        DocLinkToBCDoc: Record "Shpfy Doc. Link To Doc.";
    begin
        DocLinkToBCDoc.Init();
        DocLinkToBCDoc."Shopify Document Type" := "Shpfy Shop Document Type"::"Shopify Shop Order";
        DocLinkToBCDoc."Shopify Document Id" := ShopifyOrderId;
        DocLinkToBCDoc."Document Type" := DocumentType;
        DocLinkToBCDoc."Document No." := DocumentNo;
        DocLinkToBCDoc.Insert();
    end;

    [PageHandler]
    procedure SalesOrderPageHandler(var SalesOrder: TestPage "Sales Order")
    begin
        LibraryVariableStorage.Enqueue(SalesOrder."No.".Value);
    end;

    [PageHandler]
    procedure SalesInvoicePageHandler(var SalesInvoice: TestPage "Sales Invoice")
    begin
        LibraryVariableStorage.Enqueue(SalesInvoice."No.".Value);
    end;

    [PageHandler]
    procedure PostedSalesInvoicePageHandler(var PostedSalesInvoice: TestPage "Posted Sales Invoice")
    begin
        LibraryVariableStorage.Enqueue(PostedSalesInvoice."No.".Value);
    end;

    [PageHandler]
    procedure SalesLinesPageHandler(var SalesLines: TestPage "Sales Lines")
    begin
        SalesLines.First();
        LibraryVariableStorage.Enqueue(SalesLines."Document No.".Value);
    end;

    [PageHandler]
    procedure PostedSalesInvoiceLinesPageHandler(var PostedSalesInvoiceLines: TestPage "Posted Sales Invoice Lines")
    begin
        PostedSalesInvoiceLines.First();
        LibraryVariableStorage.Enqueue(PostedSalesInvoiceLines."Document No.".Value);
    end;

    [PageHandler]
    procedure ShpfyOrderPageHandler(var ShpfyOrder: TestPage "Shpfy Order")
    begin
        LibraryVariableStorage.Enqueue(ShpfyOrder.ShopifyOrderNo.Value);
    end;
}
