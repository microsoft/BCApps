codeunit 134372 "ERM Order Invoicing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        WrongInvoiceNoErr: Label 'Incorrect invoice No. returned';
        WrongReturnOrderNoErr: Label 'Return Order No. in the posted document is incorrect.';
        PostedServiceShipmentLineErr: Label 'No. in Posted Service Shipment Line must be visible.';

    [Test]
    [HandlerFunctions('GetReturnReceiptLinesPageHandler')]
    procedure GetSalesRetRcptLinesPostCreditMemoVerifyOrderNo()
    var
        SalesHeaderReturnOrder: Record "Sales Header";
        SalesHeaderCrMemo: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ReturnReceiptNo, CreditMemoNo : Code[20];
    begin
        // [SCENARIO] "Order No." is assigned to sales credit memo lines created via "Get Return Receipt Lines"

        Initialize();

        // [GIVEN] Sales return order "SRO1", received, not invoiced
        LibrarySales.CreateSalesReturnOrder(SalesHeaderReturnOrder);
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeaderReturnOrder, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        ReturnReceiptNo := LibrarySales.PostSalesDocument(SalesHeaderReturnOrder, true, false);

        // [GIVEN] Create a sales credit memo and run "Get Return Receipt Lines" to fill the credit memo lines
        CreateSalesCrMemoGetReturnRcptLines(SalesHeaderCrMemo, SalesHeaderReturnOrder."Sell-to Customer No.", ReturnReceiptNo);

        // [WHEN] Post the credit memo
        CreditMemoNo := LibrarySales.PostSalesDocument(SalesHeaderCrMemo, true, true);

        // [THEN] "Order No." in the posted credit memo line is "SRO1"
        SalesCrMemoLine.SetRange("Document No.", CreditMemoNo);
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        SalesCrMemoLine.FindFirst();
        Assert.AreEqual(SalesHeaderReturnOrder."No.", SalesCrMemoLine."Order No.", WrongReturnOrderNoErr);
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentLinesPageHandler')]
    procedure GetPurchRetShptLinesPostCreditMemoVerifyOrderNo()
    var
        PurchaseHeaderReturnOrder: Record "Purchase Header";
        PurchaseHeaderCrMemo: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        ReturnShipmentNo, CreditMemoNo : Code[20];
    begin
        // [SCENARIO] "Order No." is assigned to purchase credit memo lines created via "Get Return Shipment Lines"

        Initialize();

        // [GIVEN] Purchase return order "PRO1", shipped, not invoiced
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeaderReturnOrder);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeaderReturnOrder, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        ReturnShipmentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderReturnOrder, true, false);

        // [GIVEN] Create a purchase credit memo and run "Get Return Shipment Lines" to fill the credit memo lines
        CreatePurchCrMemoGetReturnShpmtLines(PurchaseHeaderCrMemo, PurchaseHeaderReturnOrder."Buy-from Vendor No.", ReturnShipmentNo);

        // [WHEN] Post the credit memo
        CreditMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderCrMemo, true, true);

        // [THEN] "Order No." in the posted credit memo line is "PRO1"
        PurchCrMemoLine.SetRange("Document No.", CreditMemoNo);
        PurchCrMemoLine.SetFilter(Type, '<>%1', PurchCrMemoLine.Type::" ");
        PurchCrMemoLine.FindFirst();
        Assert.AreEqual(PurchaseHeaderReturnOrder."No.", PurchCrMemoLine."Order No.", WrongReturnOrderNoErr);
    end;

    [Test]
    procedure PostServiceInvoiceVerifyOrderNo()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        // [SCENARIO] "Order No." is filled in service invoice lines when a service order is invoiced

        Initialize();

        // [GIVEN] Create a service order "SO01" with one service line
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateServiceLine(ServiceLine, ServiceHeader, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity / 2);
        ServiceLine.Modify(true);

        // [WHEN] Post the service order as shipped and invoiced
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] "Order No." in the service invoice line is "SO01"
        ServiceInvoiceLine.SetRange("Document No.", ServiceHeader."Last Posting No.");
        ServiceInvoiceLine.SetFilter(Type, '<>%1', ServiceInvoiceLine.Type::" ");
        ServiceInvoiceLine.FindFirst();
        Assert.AreEqual(ServiceHeader."No.", ServiceInvoiceLine."Order No.", WrongReturnOrderNoErr);
    end;

    [Test]
    procedure PostServiceOrderWithServiceLineWithItemTypeServiceAndLocationBinMandatory()
    var
        Item: Record Item;
        Location: Record Location;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] When Item is with Type = Service and Location Mandatory = true, the service could be posted without Bin Code
        Initialize();

        // [GIVEN] Location with Bin Mandatory = true
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Item with Type = Service
        LibraryInventory.CreateServiceTypeItem(Item);

        // [GIVEN] Created service item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a service order with one service line
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Modify(true);

        // [WHEN] [THEN]  Post the service order as shipped and invoiced should be successful
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    [Test]
    [HandlerFunctions('GetServiceShipmentLinesPageHandler')]
    procedure GetServiceShipmentLinesPostInvoiceVerifyOrderNo()
    var
        ServiceHeaderOrder: Record "Service Header";
        ServiceHeaderInvoice: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ShipmentNo, InvoiceNo : Code[20];
    begin
        // [SCENARIO] "Order No." is filled in service invoice lines when the lines are created via "Get Shipment Lines" function

        Initialize();

        // [GIVEN] Create a service order "SO01" with one service line
        LibraryService.CreateServiceHeader(ServiceHeaderOrder, ServiceHeaderOrder."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateServiceLine(ServiceLine, ServiceHeaderOrder, LibraryRandom.RandInt(100));

        // [GIVEN] Post the order as shipped
        LibraryService.PostServiceOrder(ServiceHeaderOrder, true, false, false);
        ShipmentNo := ServiceHeaderOrder."Last Shipping No.";

        // [GIVEN] Create a service invoice and run "Get Shipment Lines" to create the invoice lines
        CreateServiceInvoiceGetShipmentLines(ServiceHeaderInvoice, ServiceHeaderOrder."Customer No.", ShipmentNo);

        // [WHEN] Post the invoice
        InvoiceNo := PostServiceInvoice(ServiceHeaderInvoice);

        // [THEN] "Order No." in the posted service invoice line is "SO01"
        ServiceInvoiceLine.SetRange("Document No.", InvoiceNo);
        ServiceInvoiceLine.SetFilter(Type, '<>%1', ServiceInvoiceLine.Type::" ");
        ServiceInvoiceLine.FindFirst();
        Assert.AreEqual(ServiceHeaderOrder."No.", ServiceInvoiceLine."Order No.", WrongReturnOrderNoErr);
    end;

    [Test]
    procedure GetSalesOrderInvoicesMultipleLinesInOneInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        TempSalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales Order] [Sales Shipment] [Sales Invoice]
        // [SCENARIO] Partially invoice sales order, get invoices 

        Initialize();

        // [GIVEN] Sales order "SO" with 3 lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        CreateSalesLines(SalesHeader, SalesLine);

        // [GIVEN] Post a shipment for all lines
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Set quantity to invoice = Quantity / 2 on each line
        UpdateQtyToInvoiceOnSalesLines(SalesLine);

        // [GIVEN] Post the order as invocied, posted invoice No. = "SI01"
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [WHEN] Get invoices for the order "SO"
        SalesGetShipment.GetSalesOrderInvoices(TempSalesInvoiceHeader, SalesHeader."No.");

        // [THEN] One invoice "SI01" is returned
        Assert.RecordCount(TempSalesInvoiceHeader, 1);
        TempSalesInvoiceHeader.FindFirst();
        Assert.AreEqual(InvoiceNo, TempSalesInvoiceHeader."No.", WrongInvoiceNoErr);
    end;

    [Test]
    procedure GetSalesOrderInvoicesNoInvoicesPosted()
    var
        SalesHeader: Record "Sales Header";
        TempSalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        // [FEATURE] [Sales Order] [Sales Invoice]
        // [SCENARIO] Get invoices for unposted sales order returns empty set

        Initialize();

        // [GIVEN] Create a sales order "SO"
        LibrarySales.CreateSalesOrder(SalesHeader);

        // [WHEN] Get invoices for the order "SO"
        SalesGetShipment.GetSalesOrderInvoices(TempSalesInvoiceHeader, SalesHeader."No.");

        // [THEN] Retuned recordset is empty
        Assert.RecordIsEmpty(TempSalesInvoiceHeader);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesPageHandler')]
    procedure GetShipmentLinesPostAndGetSOInvoices()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        TempSalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        ShipmentNo: Code[20];
        InvoiceNos: List of [Code[20]];
    begin
        // [FEATURE] [Sales Order] [Sales Shipment] [Sales Invoice] [Get Shipment Lines]
        // [SCENARIO] Get invoices for a partially posted shipment order with invoices linked via "Get Shipment Lines"

        Initialize();

        // [GIVEN] A sales order
        LibrarySales.CreateSalesHeader(SalesHeaderOrder, SalesHeaderOrder."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Create a sales line and partially ship
        ShipmentNo := CreateSalesLinePostPartialShpmtOrRcpt(SalesHeaderOrder);

        // [GIVEN] Create a sales invoice, use "Get Shipment Lines" to add lines from the posted shipment, and post the invoice
        // [GIVEN] Posted sales invoice "SI001" is created
        CreateSalesInvoiceGetShipmentLines(SalesHeaderInvoice, SalesHeaderOrder."Sell-to Customer No.", ShipmentNo);
        InvoiceNos.Add(LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, true));

        // [GIVEN] Create another SO line and partially ship
        // [GIVEN] Create sales invoice, use "Get Shipment Lines" to add lines from the posted shipment, and post the invoice
        // [GIVEN] Posted sales invoice "SI002" is created
        SalesHeaderOrder.Find();
        ShipmentNo := CreateSalesLinePostPartialShpmtOrRcpt(SalesHeaderOrder);
        CreateSalesInvoiceGetShipmentLines(SalesHeaderInvoice, SalesHeaderOrder."Sell-to Customer No.", ShipmentNo);
        InvoiceNos.Add(LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, true));

        // [GIVEN] Create a third sales order line, partially ship, and post from the order without creating separate invoice document
        // [GIVEN] Posted sales invoice "SI003" is created
        CreateSalesLinePostPartialShpmtOrRcpt(SalesHeaderOrder);
        InvoiceNos.Add(LibrarySales.PostSalesDocument(SalesHeaderOrder, false, true));

        // [WHEN] Get invoices for the sales order
        SalesGetShipment.GetSalesOrderInvoices(TempSalesInvoiceHeader, SalesHeaderOrder."No.");

        // [THEN] 3 invoices are received: "SI001", "SI002", "SI003"
        VerifySalsInvoices(InvoiceNos, TempSalesInvoiceHeader);
    end;

    [Test]
    procedure GetSalesReturnOrderCrMemosMultipleLinesInOneCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        TempSalesCrMemoHeader: Record "Sales Cr.Memo Header" temporary;
        SalesGetReturnReceipt: Codeunit "Sales-Get Return Receipts";
        CreditMemoNo: Code[20];
    begin
        // [FEATURE] [Sales Return Order] [Sales Return Receipt] [Sales Credit Memo]
        // [SCENARIO] Partially invoice sales return order, get credit memos 

        Initialize();

        // [GIVEN] Sales return order "SRO" with 3 lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo());

        CreateSalesLines(SalesHeader, SalesLine);

        // [GIVEN] Post shipment receipt for all lines
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Set quantity to invoice = Quantity / 2 on each line
        UpdateQtyToInvoiceOnSalesLines(SalesLine);

        // [GIVEN] Post the order as invocied, posted credit memo No. = "SCM01"
        CreditMemoNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [WHEN] Get credit memos for the order "SRO"
        SalesGetReturnReceipt.GetSalesRetOrderCrMemos(TempSalesCrMemoHeader, SalesHeader."No.");

        // [THEN] One credit memo "SCM01" is returned
        Assert.RecordCount(TempSalesCrMemoHeader, 1);
        TempSalesCrMemoHeader.FindFirst();
        Assert.AreEqual(CreditMemoNo, TempSalesCrMemoHeader."No.", WrongInvoiceNoErr);
    end;

    [Test]
    procedure GetSalesReturnOrderCrMemosNoCreditMemosPosted()
    var
        SalesHeader: Record "Sales Header";
        TempSalesCrMemoHeader: Record "Sales Cr.Memo Header" temporary;
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
    begin
        // [FEATURE] [Sales Return Order] [Sales Credit Memo]
        // [SCENARIO] Get credit memos for unposted sales return order returns empty set

        Initialize();

        // [GIVEN] Create a sales return order "SO"
        LibrarySales.CreateSalesReturnOrder(SalesHeader);

        // [WHEN] Get credit memos for the order "SO"
        SalesGetReturnReceipts.GetSalesRetOrderCrMemos(TempSalesCrMemoHeader, SalesHeader."No.");

        // [THEN] Retuned recordset is empty
        Assert.RecordIsEmpty(TempSalesCrMemoHeader);
    end;

    [Test]
    [HandlerFunctions('GetReturnReceiptLinesPageHandler')]
    procedure GetReturnReceiptLinesPostAndGetSalesRetOrderCrMemos()
    var
        SalesHeaderRetOrder: Record "Sales Header";
        SalesHeaderCrMemo: Record "Sales Header";
        TempSalesCrMemoHeader: Record "Sales Cr.Memo Header" temporary;
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
        ReturnReceptNo: Code[20];
        CrMemoNos: List of [Code[20]];
    begin
        // [FEATURE] [Sales Return Order] [Sales Return Receipt] [Sales Credit Memo] [Get Return Receipt Lines]
        // [SCENARIO] Get credit memos for a partially posted sales return order with credit memos linked via "Get Return Receipt Lines"

        Initialize();

        // [GIVEN] A sales return order
        LibrarySales.CreateSalesHeader(SalesHeaderRetOrder, SalesHeaderRetOrder."Document Type"::"Return Order", LibrarySales.CreateCustomerNo());

        // [GIVEN] Create a sales line and partially receive
        ReturnReceptNo := CreateSalesLinePostPartialShpmtOrRcpt(SalesHeaderRetOrder);

        // [GIVEN] Create a sales credit memo, use "Get Return Receipt Lines" to add lines from the posted receipt, and post the credit memo
        // [GIVEN] Posted sales credit memo "SCM001" is created
        CreateSalesCrMemoGetReturnRcptLines(SalesHeaderCrMemo, SalesHeaderRetOrder."Sell-to Customer No.", ReturnReceptNo);
        CrMemoNos.Add(LibrarySales.PostSalesDocument(SalesHeaderCrMemo, false, true));

        // [GIVEN] Create another sales return order line and partially receive
        // [GIVEN] Create sales credit memo, use "Get Return Receipt Lines" to add lines from the posted receipt, and post the credit memo
        // [GIVEN] Posted sales credit memo "SCM002" is created
        SalesHeaderRetOrder.Find();
        ReturnReceptNo := CreateSalesLinePostPartialShpmtOrRcpt(SalesHeaderRetOrder);
        CreateSalesCrMemoGetReturnRcptLines(SalesHeaderCrMemo, SalesHeaderRetOrder."Sell-to Customer No.", ReturnReceptNo);
        CrMemoNos.Add(LibrarySales.PostSalesDocument(SalesHeaderCrMemo, false, true));

        // [GIVEN] Create a third sales return order line, partially receive, and post from the order without creating separate credit memo document
        // [GIVEN] Posted sales credi memo "SCM003" is created
        CreateSalesLinePostPartialShpmtOrRcpt(SalesHeaderRetOrder);
        CrMemoNos.Add(LibrarySales.PostSalesDocument(SalesHeaderRetOrder, false, true));

        // [WHEN] Get credit memos for the sales return order
        SalesGetReturnReceipts.GetSalesRetOrderCrMemos(TempSalesCrMemoHeader, SalesHeaderRetOrder."No.");

        // [THEN] 3 credit memos are received: "SCM001", "SCM002", "SCM003"
        VerifySalesCreditMemos(CrMemoNos, TempSalesCrMemoHeader);
    end;

    [Test]
    procedure GetPurchOrderInvoicesMultipleLinesInOneInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[3] of Record "Purchase Line";
        TempPurchInvHeader: Record "Purch. Inv. Header" temporary;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase Order] [Purchase Receipt] [Purchase Invoice]
        // [SCENARIO] Partially invoice purchase order, get invoices 

        Initialize();

        // [GIVEN] Purchase order "PO" with 3 lines
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        CreatePurchaseLines(PurchaseHeader, PurchaseLine);

        // [GIVEN] Post a receipt for all lines
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Set quantity to invoice = Quantity / 2 on each line
        UpdateQtyToInvoiceOnPurchLines(PurchaseLine);

        // [GIVEN] Post the order as invocied, posted invoice No. = "PI01"
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [WHEN] Get invoices for the order "PO"
        PurchGetReceipt.GetPurchOrderInvoices(TempPurchInvHeader, PurchaseHeader."No.");

        // [THEN] One invoice "PI01" is returned
        Assert.RecordCount(TempPurchInvHeader, 1);
        TempPurchInvHeader.FindFirst();
        Assert.AreEqual(InvoiceNo, TempPurchInvHeader."No.", WrongInvoiceNoErr);
    end;

    [Test]
    procedure GetPurchOrderInvoicesNoInvoicesPosted()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchInvHeader: Record "Purch. Inv. Header" temporary;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        // [FEATURE] [Purchase Order] [Purchase Invoice]
        // [SCENARIO] Get invoices for unposted purchase order returns empty set

        Initialize();

        // [GIVEN] Create a purchase order "PO"
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // [WHEN] Get invoices for the order "PO"
        PurchGetReceipt.GetPurchOrderInvoices(TempPurchInvHeader, PurchaseHeader."No.");

        // [THEN] Retuned recordset is empty
        Assert.RecordIsEmpty(TempPurchInvHeader);
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesPageHandler')]
    procedure GetReceiptLinesPostAndGetPOInvoices()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        TempPurchInvHeader: Record "Purch. Inv. Header" temporary;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        ReceiptNo: Code[20];
        InvoiceNos: List of [Code[20]];
    begin
        // [FEATURE] [Purchase Order] [Purchase Shipment] [Purchase Invoice] [Get Receipt Lines]
        // [SCENARIO] Get invoices for a partially posted purchase order with invoices linked via "Get Receipt Lines"

        Initialize();

        // [GIVEN] A purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Create a purchase line and partially receive
        ReceiptNo := CreatePurchaseLinePostPartialReceiptOrShpmt(PurchaseHeaderOrder);

        // [GIVEN] Create a purchase invoice, use "Get Receipt Lines" to add lines from the posted receipt, and post the invoice
        // [GIVEN] Posted purchase invoice "PI001" is created
        CreatePurchInvoiceGetReceiptLines(PurchaseHeaderInvoice, PurchaseHeaderOrder."Buy-from Vendor No.", ReceiptNo);
        InvoiceNos.Add(LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true));

        // [GIVEN] Create another PO line and partially receive
        // [GIVEN] Create purchase invoice, use "Get Receipt Lines" to add lines from the posted receipt, and post the invoice
        // [GIVEN] Posted purchase invoice "PI002" is created
        ReceiptNo := CreatePurchaseLinePostPartialReceiptOrShpmt(PurchaseHeaderOrder);
        CreatePurchInvoiceGetReceiptLines(PurchaseHeaderInvoice, PurchaseHeaderOrder."Buy-from Vendor No.", ReceiptNo);
        InvoiceNos.Add(LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true));

        // [GIVEN] Create a third purchase order line, partially receive, and post from the order without creating separate invoice document
        // [GIVEN] Posted purchase invoice "PI003" is created
        CreatePurchaseLinePostPartialReceiptOrShpmt(PurchaseHeaderOrder);
        InvoiceNos.Add(LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, false, true));

        // [WHEN] Get invoices for the purchase order
        PurchGetReceipt.GetPurchOrderInvoices(TempPurchInvHeader, PurchaseHeaderOrder."No.");

        // [THEN] 3 invoices are received: "PI001", "PI002", "PI003"
        VerifyPurchaseInvoices(InvoiceNos, TempPurchInvHeader);
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesPageHandler')]
    procedure GetReceiptLinesCopiesDescFromReceipt()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseOrderLine: Record "Purchase Line";
        PurchaseInvoiceLine: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        ReceiptNo: Code[20];
        DescriptionFromReceipt: Text[100];
        Description2FromReceipt: Text[50];
    begin
        // [FEATURE] [Purchase Order] [Purchase Receipt] [Purchase Invoice] [Get Receipt Lines]
        // [SCENARIO] Get Receipt Lines action on Purchase Invoice copies item desription from the receipt lines and not from the Purchase Order Line"

        Initialize();

        // [GIVEN] A purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Create a purchase line and partially receive
        ReceiptNo := CreatePurchaseLinePostPartialReceiptOrShpmt(PurchaseHeaderOrder, PurchaseOrderLine);
        PurchaseOrderLine.Find();
        DescriptionFromReceipt := PurchaseOrderLine.Description;
        Description2FromReceipt := PurchaseOrderLine."Description 2";

        // [GIVEN] Change the Description and Description 2 on Purchase Order Line
        PurchaseOrderLine.Description := CopyStr(LibraryRandom.RandText(100), 1, 100);
        PurchaseOrderLine."Description 2" := CopyStr(LibraryRandom.RandText(50), 1, 50);
        PurchaseOrderLine.Modify(true);

        // [WHEN] Create a purchase invoice, use "Get Receipt Lines" to add lines from the posted receipt
        CreatePurchInvoiceGetReceiptLines(PurchaseHeaderInvoice, PurchaseHeaderOrder."Buy-from Vendor No.", ReceiptNo);

        // [THEN] The purchase invoice line descriptions are copied from the receipt lines and not from current order line
        PurchaseInvoiceLine.SetRange("Document No.", PurchaseHeaderInvoice."No.");
        PurchaseInvoiceLine.SetRange("Document Type", PurchaseHeaderInvoice."Document Type");
        PurchaseInvoiceLine.SetRange(Type, PurchaseInvoiceLine.Type::"G/L Account");
        PurchaseInvoiceLine.FindFirst();
        PurchaseInvoiceLine.TestField(Description, DescriptionFromReceipt);
        PurchaseInvoiceLine.TestField("Description 2", Description2FromReceipt);
    end;

    [Test]
    procedure GetPurchRetOrderCrMemosMultipleLinesInOneCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[3] of Record "Purchase Line";
        TempPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr." temporary;
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
        CreditMemoNo: Code[20];
    begin
        // [FEATURE] [Purchase Return Order] [Purchase Return Shipment] [Purchase Credit Memo]
        // [SCENARIO] Partially invoice purchase return order, get credit memos 

        Initialize();

        // [GIVEN] Purchase return order "PRO" with 3 lines
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());
        CreatePurchaseLines(PurchaseHeader, PurchaseLine);

        // [GIVEN] Post a return shipment for all lines
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Set quantity to invoice = Quantity / 2 on each line
        UpdateQtyToInvoiceOnPurchLines(PurchaseLine);

        // [GIVEN] Post the order as invocied, posted credit memo No. = "PCM01"
        CreditMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [WHEN] Get credit memos for the return order "PRO"
        PurchGetReturnShipments.GetPurchRetOrderCrMemos(TempPurchCrMemoHdr, PurchaseHeader."No.");

        // [THEN] One credit memo "PCM01" is returned
        Assert.RecordCount(TempPurchCrMemoHdr, 1);
        TempPurchCrMemoHdr.FindFirst();
        Assert.AreEqual(CreditMemoNo, TempPurchCrMemoHdr."No.", WrongInvoiceNoErr);
    end;

    [Test]
    procedure GetPurchReturnOrderCrMemosNoCreditMemoPosted()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr." temporary;
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        // [FEATURE] [Purchase Return Order] [Purchase Credit Memo]
        // [SCENARIO] Get credit memos for unposted purchase return order returns empty set

        Initialize();

        // [GIVEN] Create a purchase return order "PRO"
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);

        // [WHEN] Get credit memos for the order "PRO"
        PurchGetReturnShipments.GetPurchRetOrderCrMemos(TempPurchCrMemoHdr, PurchaseHeader."No.");

        // [THEN] Retuned recordset is empty
        Assert.RecordIsEmpty(TempPurchCrMemoHdr);
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentLinesPageHandler')]
    procedure GetReturnShipmentLinesPostAndGetPurchRetOrderCreditMemos()
    var
        PurchHeaderReturnOrder: Record "Purchase Header";
        PurchaseHeaderCrMemo: Record "Purchase Header";
        TempPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr." temporary;
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
        ReturnShipmentNo: Code[20];
        CreditMemoNos: List of [Code[20]];
    begin
        // [FEATURE] [Purchase Return Order] [Purchase Return Shipment] [Purchase Credit Memo] [Get Return Shipment Lines]
        // [SCENARIO] Get credit memos for a partially posted purchase return order with credit memos linked via "Get Return Shipment Lines"

        Initialize();

        // [GIVEN] A purchase return order
        LibraryPurchase.CreatePurchHeader(PurchHeaderReturnOrder, PurchHeaderReturnOrder."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());

        // [GIVEN] Create a purchase line and partially ship
        ReturnShipmentNo := CreatePurchaseLinePostPartialReceiptOrShpmt(PurchHeaderReturnOrder);

        // [GIVEN] Create a purchase credit memo, use "Get Return Shipment Lines" to add lines from the posted shipment, and post the credit memo
        // [GIVEN] Posted purchase credi memo "PCM001" is created
        CreatePurchCrMemoGetReturnShpmtLines(PurchaseHeaderCrMemo, PurchHeaderReturnOrder."Buy-from Vendor No.", ReturnShipmentNo);
        CreditMemoNos.Add(LibraryPurchase.PostPurchaseDocument(PurchaseHeaderCrMemo, false, true));

        // [GIVEN] Create another return order line and partially ship
        // [GIVEN] Create purchase credit memo, use "Get Return Shipment Lines" to add lines from the posted shipment, and post the credit memo
        // [GIVEN] Posted purchase invoice "PI002" is created
        ReturnShipmentNo := CreatePurchaseLinePostPartialReceiptOrShpmt(PurchHeaderReturnOrder);
        CreatePurchCrMemoGetReturnShpmtLines(PurchaseHeaderCrMemo, PurchHeaderReturnOrder."Buy-from Vendor No.", ReturnShipmentNo);
        CreditMemoNos.Add(LibraryPurchase.PostPurchaseDocument(PurchaseHeaderCrMemo, false, true));

        // [GIVEN] Create a third purchase return order line, partially ship, and invoice from the order without creating separate credit memo document
        // [GIVEN] Posted purchase credit memo "PCM003" is created
        CreatePurchaseLinePostPartialReceiptOrShpmt(PurchHeaderReturnOrder);
        CreditMemoNos.Add(LibraryPurchase.PostPurchaseDocument(PurchHeaderReturnOrder, false, true));

        // [WHEN] Get credit memos for the purchase return order
        PurchGetReturnShipments.GetPurchRetOrderCrMemos(TempPurchCrMemoHdr, PurchHeaderReturnOrder."No.");

        // [THEN] 3 credit memos are received: "PCM001", "PCM002", "PCM003"
        VerifyPurchaseCreditMemos(CreditMemoNos, TempPurchCrMemoHdr);
    end;

    [Test]
    procedure GetServiceOrderInvoicesMultipleLinesInOneInvoice()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: array[3] of Record "Service Line";
        TempServiceInvoiceHeader: Record "Service Invoice Header" temporary;
        ServiceGetShipment: Codeunit "Service-Get Shipment";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Service Order] [Service Shipment] [Service Invoice]
        // [SCENARIO] Partially invoice service order, get invoices

        Initialize();

        // [GIVEN] Service order "SO" with 3 lines
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateServiceLines(ServiceHeader, ServiceLine);

        // [GIVEN] Post a shipment for all lines
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [GIVEN] Set quantity to invoice = Quantity / 2 on each line
        UpdateQtyToInvoiceOnServiceLines(ServiceLine);

        // [GIVEN] Post the order as invocied, posted invoice No. = "SI01"
        InvoiceNo := PostServiceOrderInvoiced(ServiceHeader);

        // [WHEN] Get invoices for the order "SO"
        ServiceGetShipment.GetServiceOrderInvoices(TempServiceInvoiceHeader, ServiceHeader."No.");

        // [THEN] One invoice "SI01" is returned
        Assert.RecordCount(TempServiceInvoiceHeader, 1);
        TempServiceInvoiceHeader.FindFirst();
        Assert.AreEqual(InvoiceNo, TempServiceInvoiceHeader."No.", WrongInvoiceNoErr);
    end;

    [Test]
    procedure GetServiceOrderInvoiceNoInvoicesPosted()
    var
        ServiceHeader: Record "Service Header";
        TempServiceInvoiceHeader: Record "Service Invoice Header" temporary;
        ServiceGetShipment: Codeunit "Service-Get Shipment";
    begin
        // [FEATURE] [Service Order] [Service Invoice]
        // [SCENARIO] Get invoices for unposted service order returns empty set

        Initialize();

        // [GIVEN] Create a service order "SO"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Get invoices for the order "SO"
        ServiceGetShipment.GetServiceOrderInvoices(TempServiceInvoiceHeader, ServiceHeader."No.");

        // [THEN] Retuned recordset is empty
        Assert.RecordIsEmpty(TempServiceInvoiceHeader);
    end;

    [Test]
    [HandlerFunctions('GetServiceShipmentLinesPageHandler')]
    procedure GetServiceShipmentLinesPostAndGetServiceOrderInvoices()
    var
        ServiceHeaderOrder: Record "Service Header";
        ServiceHeaderInvoice: Record "Service Header";
        TempServiceInvoiceHeader: Record "Service Invoice Header" temporary;
        ServiceGetShipment: Codeunit "Service-Get Shipment";
        ShipmentNo: Code[20];
        InvoiceNos: List of [Code[20]];
    begin
        // [FEATURE] [Service Order] [Service Shipment] [Service Invoice] [Get Shipment Lines]
        // [SCENARIO] Get invoices for a partially posted service order with invoices linked via "Get Shipment Lines"

        Initialize();

        // [GIVEN] A service order
        LibraryService.CreateServiceHeader(ServiceHeaderOrder, ServiceHeaderOrder."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Create a service line and partially ship
        ShipmentNo := CreateServiceLinePostPartialShipment(ServiceHeaderOrder);

        // [GIVEN] Create a service invoice, use "Get Shipment Lines" to add lines from the posted shipment, and post the invoice
        // [GIVEN] Posted service invoice "SI001" is created
        CreateServiceInvoiceGetShipmentLines(ServiceHeaderInvoice, ServiceHeaderOrder."Customer No.", ShipmentNo);
        InvoiceNos.Add(PostServiceInvoice(ServiceHeaderInvoice));

        // [GIVEN] Create another service order line and partially ship
        // [GIVEN] Create service invoice, use "Get Shipment Lines" to add lines from the posted shipment, and post the invoice
        // [GIVEN] Posted service invoice "SI002" is created
        ShipmentNo := CreateServiceLinePostPartialShipment(ServiceHeaderOrder);
        CreateServiceInvoiceGetShipmentLines(ServiceHeaderInvoice, ServiceHeaderOrder."Customer No.", ShipmentNo);
        InvoiceNos.Add(PostServiceInvoice(ServiceHeaderInvoice));

        // [GIVEN] Create a third service order line, partially ship and invoice from the order without creating separate invoice document
        // [GIVEN] Posted service invoice "SI003" is created
        CreateServiceLinePostPartialShipment(ServiceHeaderOrder);
        InvoiceNos.Add(PostServiceOrderInvoiced(ServiceHeaderOrder));

        // [WHEN] Get invoices for the service order
        ServiceGetShipment.GetServiceOrderInvoices(TempServiceInvoiceHeader, ServiceHeaderOrder."No.");

        // [THEN] 3 invoices are received: "SI001", "SI002", "SI003"
        VerifyServiceInvoices(InvoiceNos, TempServiceInvoiceHeader);
    end;

    [Test]
    procedure PostServiceShipmentAndCheckServiceShipmentLineNoVisible()
    var
        UserSetup: Record "User Setup";
        ResponsibilityCenter: Record "Responsibility Center";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        PostedServiceShipmentLines: TestPage "Posted Service Shipment Lines";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 534726] Users with Responsibility Center Filter on User Setup Can View Service Shipment Lines on Posted Shipments for their Responsibility Center.
        Initialize();

        // [GIVEN] Create Responsibility Center
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);

        // [GIVEN] Create User Setup for current User.
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);

        // [GIVEN] Validate Service Resp Center Filter.
        UserSetup.Validate("Service Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Modify(true);

        // [GIVEN] Create a Service Header.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Create GL Account With Sales Setup.
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();

        // [GIVEN] Create a Service Line and Validate Quantity.
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccountNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(5));
        ServiceLine.Modify(true);

        // [GIVEN] Post Service Order to Sales Shipment.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] No. in Posted Service Shipment Lines must be visible.
        PostedServiceShipmentLines.OpenEdit();
        PostedServiceShipmentLines.Filter.SetFilter("Document No.", ServiceHeader."Last Shipping No.");
        PostedServiceShipmentLines.Filter.SetFilter("No.", GLAccountNo);
        Assert.IsTrue(PostedServiceShipmentLines."No.".Visible(), PostedServiceShipmentLineErr);
    end;

    local procedure Initialize()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Order Invoicing");
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Order Invoicing");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryService.SetupServiceMgtNoSeries();
        ServiceMgtSetup.Get();
        ServiceMgtSetup."Posted Service Invoice Nos." := LibraryERM.CreateNoSeriesCode();
        ServiceMgtSetup.Modify(true);

        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Order Invoicing");
    end;

    local procedure CreatePurchCrMemoGetReturnShpmtLines(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; ReturnShipmentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";

        Commit();
        LibraryVariableStorage.Enqueue(ReturnShipmentNo);
        LibraryPurchase.GetPurchaseReturnShipmentLine(PurchaseLine);
    end;

    local procedure CreatePurchInvoiceGetReceiptLines(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; PurchReceiptNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";

        Commit();
        LibraryVariableStorage.Enqueue(PurchReceiptNo);
        LibraryPurchase.GetPurchaseReceiptLine(PurchaseLine);
    end;

    local procedure CreatePurchaseLinePostPartialReceiptOrShpmt(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        exit(CreatePurchaseLinePostPartialReceiptOrShpmt(PurchaseHeader, PurchaseLine));
    end;

    local procedure CreatePurchaseLinePostPartialReceiptOrShpmt(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"): Code[20]
    begin
        if PurchaseHeader.Status <> PurchaseHeader.Status::Open then
            LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
            LibraryRandom.RandIntInRange(10, 20));

        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Return Order" then
            PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine.Quantity / 2)
        else
            PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);

        PurchaseLine.Modify(true);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure CreatePurchaseLines(PurchaseHeader: Record "Purchase Header"; var PurchaseLines: array[3] of Record "Purchase Line")
    var
        I: Integer;
    begin
        for I := 1 to ArrayLen(PurchaseLines) do
            LibraryPurchase.CreatePurchaseLine(
                PurchaseLines[I], PurchaseHeader, PurchaseLines[I].Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
                LibraryRandom.RandIntInRange(10, 20));
    end;

    local procedure CreateSalesCrMemoGetReturnRcptLines(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ReturnReceiptNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";

        Commit();
        LibraryVariableStorage.Enqueue(ReturnReceiptNo);
        LibrarySales.GetReturnReceiptLines(SalesLine);
    end;

    local procedure CreateSalesInvoiceGetShipmentLines(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; SalesShipmentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";

        Commit();
        LibraryVariableStorage.Enqueue(SalesShipmentNo);
        LibrarySales.GetShipmentLines(SalesLine);
    end;

    local procedure CreateSalesLinePostPartialShpmtOrRcpt(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        if SalesHeader.Status <> SalesHeader.Status::Open then
            LibrarySales.ReopenSalesDocument(SalesHeader);

        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(),
            LibraryRandom.RandIntInRange(10, 20));

        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Return Order" then
            SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity / 2)
        else
            SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateSalesLines(SalesHeader: Record "Sales Header"; var SalesLines: array[3] of Record "Sales Line")
    var
        I: Integer;
    begin
        for I := 1 to ArrayLen(SalesLines) do
            LibrarySales.CreateSalesLine(
                SalesLines[I], SalesHeader, SalesLines[I].Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(),
                LibraryRandom.RandIntInRange(10, 20));
    end;

    local procedure CreateServiceInvoiceGetShipmentLines(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; ShipmentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceLine."Document Type" := ServiceHeader."Document Type";
        ServiceLine."Document No." := ServiceHeader."No.";

        Commit();
        LibraryVariableStorage.Enqueue(ShipmentNo);
        LibraryService.GetShipmentLines(ServiceLine);
    end;

    local procedure CreateServiceLine(
        var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; Qty: Integer)
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        ServiceLine.Validate(Quantity, Qty);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLinePostPartialShipment(var ServiceHeader: Record "Service Header"): Code[20]
    var
        ServiceLine: Record "Service Line";
    begin
        CreateServiceLine(ServiceLine, ServiceHeader, LibraryRandom.RandIntInRange(10, 20));
        ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity / 2);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        ServiceLine.Modify(true);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        exit(ServiceHeader."Last Shipping No.");
    end;

    local procedure CreateServiceLines(ServiceHeader: Record "Service Header"; var ServiceLines: array[3] of Record "Service Line")
    var
        I: Integer;
    begin
        for I := 1 to ArrayLen(ServiceLines) do
            CreateServiceLine(ServiceLines[I], ServiceHeader, LibraryRandom.RandIntInRange(10, 20));
    end;

    local procedure PostServiceInvoice(var ServiceHeader: Record "Service Header"): Code[20]
    begin
        // "Invoice" parameter must be false when posting a service invoice via PostServiceOrder, otherwise posting fails
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
        exit(ServiceHeader."Last Posting No.");
    end;

    local procedure PostServiceOrderInvoiced(var ServiceHeader: Record "Service Header"): Code[20]
    begin
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
        exit(ServiceHeader."Last Posting No.");
    end;

    local procedure UpdateQtyToInvoiceOnPurchLines(var PurchaseLines: array[3] of Record "Purchase Line")
    var
        I: Integer;
    begin
        for I := 1 to ArrayLen(PurchaseLines) do begin
            PurchaseLines[I].GetBySystemId(PurchaseLines[I].SystemId);
            PurchaseLines[I].Validate("Qty. to Invoice", PurchaseLines[I].Quantity / 2);
            PurchaseLines[I].Modify(true);
        end;
    end;

    local procedure UpdateQtyToInvoiceOnSalesLines(var SalesLines: array[3] of Record "Sales Line")
    var
        I: Integer;
    begin
        for I := 1 to ArrayLen(SalesLines) do begin
            SalesLines[I].GetBySystemId(SalesLines[I].SystemId);
            SalesLines[I].Validate("Qty. to Invoice", SalesLines[I].Quantity / 2);
            SalesLines[I].Modify(true);
        end;
    end;

    local procedure UpdateQtyToInvoiceOnServiceLines(var ServiceLines: array[3] of Record "Service Line")
    var
        I: Integer;
    begin
        for I := 1 to ArrayLen(ServiceLines) do begin
            ServiceLines[I].GetBySystemId(ServiceLines[I].SystemId);
            ServiceLines[I].Validate("Qty. to Invoice", ServiceLines[I].Quantity / 2);
            ServiceLines[I].Modify(true);
        end;
    end;

    local procedure VerifyPurchaseInvoices(ExpectedDocumentNos: List of [Code[20]]; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        I: Integer;
    begin
        PurchInvHeader.FindSet();
        repeat
            I += 1;
            Assert.AreEqual(ExpectedDocumentNos.Get(I), PurchInvHeader."No.", WrongInvoiceNoErr);
        until PurchInvHeader.Next() = 0;
    end;

    local procedure VerifyPurchaseCreditMemos(ExpectedDocumentNos: List of [Code[20]]; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        I: Integer;
    begin
        PurchCrMemoHdr.FindSet();
        repeat
            I += 1;
            Assert.AreEqual(ExpectedDocumentNos.Get(I), PurchCrMemoHdr."No.", WrongInvoiceNoErr);
        until PurchCrMemoHdr.Next() = 0;
    end;

    local procedure VerifySalsInvoices(ExpectedDocumentNos: List of [Code[20]]; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        I: Integer;
    begin
        SalesInvoiceHeader.FindSet();
        repeat
            I += 1;
            Assert.AreEqual(ExpectedDocumentNos.Get(I), SalesInvoiceHeader."No.", WrongInvoiceNoErr);
        until SalesInvoiceHeader.Next() = 0;
    end;

    local procedure VerifySalesCreditMemos(ExpectedDocumentNos: List of [Code[20]]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        I: Integer;
    begin
        SalesCrMemoHeader.FindSet();
        repeat
            I += 1;
            Assert.AreEqual(ExpectedDocumentNos.Get(I), SalesCrMemoHeader."No.", WrongInvoiceNoErr);
        until SalesCrMemoHeader.Next() = 0;
    end;

    local procedure VerifyServiceInvoices(ExpectedDocumentNos: List of [Code[20]]; var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        I: Integer;
    begin
        ServiceInvoiceHeader.FindSet();
        repeat
            I += 1;
            Assert.AreEqual(ExpectedDocumentNos.Get(I), ServiceInvoiceHeader."No.", WrongInvoiceNoErr);
        until ServiceInvoiceHeader.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", LibraryVariableStorage.DequeueText());
        PurchRcptLine.FindFirst();
        GetReceiptLines.GoToRecord(PurchRcptLine);
        GetReceiptLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnReceiptLinesPageHandler(var GetReturnReceiptLines: TestPage "Get Return Receipt Lines")
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptLine.SetRange("Document No.", LibraryVariableStorage.DequeueText());
        ReturnReceiptLine.FindFirst();
        GetReturnReceiptLines.GoToRecord(ReturnReceiptLine);
        GetReturnReceiptLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnShipmentLinesPageHandler(var GetReturnShipmentLines: TestPage "Get Return Shipment Lines")
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ReturnShipmentLine.SetRange("Document No.", LibraryVariableStorage.DequeueText());
        ReturnShipmentLine.FindFirst();
        GetReturnShipmentLines.GoToRecord(ReturnShipmentLine);
        GetReturnShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", LibraryVariableStorage.DequeueText());
        SalesShipmentLine.FindFirst();
        GetShipmentLines.GoToRecord(SalesShipmentLine);
        GetShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetServiceShipmentLinesPageHandler(var GetServiceShipmentLines: TestPage "Get Service Shipment Lines")
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Document No.", LibraryVariableStorage.DequeueText());
        ServiceShipmentLine.FindFirst();
        GetServiceShipmentLines.GoToRecord(ServiceShipmentLine);
        GetServiceShipmentLines.OK().Invoke();
    end;
}
