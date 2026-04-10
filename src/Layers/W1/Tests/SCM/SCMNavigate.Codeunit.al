codeunit 137078 "SCM Navigate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Navigate] [SCM]
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        PostedSalesShipmentDocumentTypeTxt: Label 'Posted Sales Shipment';
        PostedSalesInvoiceDocumentTypeTxt: Label 'Posted Sales Invoice';
        PostedReturnReceiptDocumentTypeTxt: Label 'Posted Return Receipt';
        PostedSalesCreditMemoDocumentTypeTxt: Label 'Posted Sales Credit Memo';
        PostedPurchaseReceiptDocumentTypeTxt: Label 'Posted Purchase Receipt';
        PostedPurchaseInvoiceDocumentTypeTxt: Label 'Posted Purchase Invoice';
        PostedReturnShipmentDocumentTypeTxt: Label 'Posted Return Shipment';
        PostedPurchaseCreditMemoDocumentTypeTxt: Label 'Posted Purchase Credit Memo';
        PostedServiceShipmentDocumentTypeTxt: Label 'Posted Service Shipment';
        PostedServiceInvoiceDocumentTypeTxt: Label 'Posted Service Invoice';
        PostedServiceCreditMemoDocumentTypeTxt: Label 'Posted Service Credit Memo';
        NoOfLinesErr: Label 'No. Of Lines must be the same.';

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedSalesShipment()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        Navigate: TestPage Navigate;
        DocumentNo: Code[20];
    begin
        // Setup: Create Item and Sales Order. Post Sales Order with Shipment.
        Initialize();
        LibraryInventory.CreateItem(Item);
        DocumentNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Item."No.", false);  // Invoice as FALSE.
        SalesShipmentHeader.Get(DocumentNo);

        // Exercise: Open Navigate Page from Posted Sales Shipment.
        NavigateFromPostedSalesShipment(Navigate, SalesShipmentHeader);

        // Verify: Navigate Page from Posted Sales Shipment.
        VerifyNavigatePage(
          Navigate, SalesShipmentHeader."No.", SalesShipmentHeader."Posting Date", PostedSalesShipmentDocumentTypeTxt, Customer.TableCaption(),
          SalesShipmentHeader."Sell-to Customer No.", 3);  // No. of Line value required on Navigate Page.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedSalesInvoice()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Navigate: TestPage Navigate;
    begin
        // Setup: Create Item and Sales Order. Post Sales Order with Shipment and Invoice.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Item."No.", true);  // Invoice as TRUE.
        FindPostedSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader."No.");

        // Exercise: Open Navigate Page from Posted Sales Invoice.
        NavigateFromPostedSalesInvoice(Navigate, SalesInvoiceHeader);

        // Verify: Navigate Page from Posted Sales Invoice.
        VerifyNavigatePage(
          Navigate, SalesInvoiceHeader."No.", SalesInvoiceHeader."Posting Date", PostedSalesInvoiceDocumentTypeTxt, Customer.TableCaption(),
          SalesInvoiceHeader."Sell-to Customer No.", 6);  // No. of Line value required on Navigate Page.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedSalesReturnReceipt()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        Navigate: TestPage Navigate;
        DocumentNo: Code[20];
    begin
        // Setup: Create Item and Sales Return Order. Post Sales Return Order with Shipment.
        Initialize();
        LibraryInventory.CreateItem(Item);
        DocumentNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", Item."No.", false);  // Invoice as FALSE.
        ReturnReceiptHeader.Get(DocumentNo);

        // Exercise: Open Navigate Page from Posted Return Receipt.
        NavigateFromPostedReturnReceipt(Navigate, ReturnReceiptHeader);

        // Verify: Navigate Page from Posted Return Receipt.
        VerifyNavigatePage(
          Navigate, ReturnReceiptHeader."No.", ReturnReceiptHeader."Posting Date", PostedReturnReceiptDocumentTypeTxt, Customer.TableCaption(),
          ReturnReceiptHeader."Sell-to Customer No.", 3);  // No. of Line value required on Navigate Page.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedSalesCreditMemo()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Navigate: TestPage Navigate;
    begin
        // Setup: Create Item and Sales Return Order. Post Sales Return Order with Shipment and Invoice.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", Item."No.", true);  // Invoice as TRUE.
        FindPostedSalesCreditMemoHeader(SalesCrMemoHeader, SalesHeader."No.");

        // Exercise: Open Navigate Page from Posted Sales Credit Memo.
        NavigateFromPostedSalesCreditMemo(Navigate, SalesCrMemoHeader);

        // Verify: Navigate Page from Posted Sales Credit Memo.
        VerifyNavigatePage(
          Navigate, SalesCrMemoHeader."No.", SalesCrMemoHeader."Posting Date", PostedSalesCreditMemoDocumentTypeTxt, Customer.TableCaption(),
          SalesCrMemoHeader."Sell-to Customer No.", 6);  // No. of Line value required on Navigate Page.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedPurchaseReceipt()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        Navigate: TestPage Navigate;
        DocumentNo: Code[20];
    begin
        // Setup: Create Item and Purchase Order. Post Purchase Order as Receive.
        Initialize();
        LibraryInventory.CreateItem(Item);
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Item."No.", false);  // Invoice as FALSE.
        PurchRcptHeader.Get(DocumentNo);

        // Exercise: Open Navigate Page from Posted Purchase Receipt.
        NavigateFromPostedPurchaseReceipt(Navigate, PurchRcptHeader);

        // Verify: Navigate Page from Posted Purchase Receipt.
        VerifyNavigatePage(
          Navigate, PurchRcptHeader."No.", PurchRcptHeader."Posting Date", PostedPurchaseReceiptDocumentTypeTxt, Vendor.TableCaption(),
          PurchRcptHeader."Buy-from Vendor No.", 3);  // No. of Line value required on Navigate Page.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedPurchaseInvoice()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        Navigate: TestPage Navigate;
    begin
        // Setup: Create Item and Purchase Order. Post Purchase Order as Receive and Invoice.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Item."No.", true);  // Invoice as TRUE.
        FindPostedPurchaseInvoiceHeader(PurchInvHeader, PurchaseHeader."No.");

        // Exercise: Open Navigate Page from Posted Purchase Invoice.
        NavigateFromPostedPurchaseInvoice(Navigate, PurchInvHeader);

        // Verify: Navigate Page from Posted Purchase Invoice.
        VerifyNavigatePage(
          Navigate, PurchInvHeader."No.", PurchInvHeader."Posting Date", PostedPurchaseInvoiceDocumentTypeTxt, Vendor.TableCaption(),
          PurchInvHeader."Buy-from Vendor No.", 6);  // No. of Line value required on Navigate Page.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedPurchaseReturnShipment()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        Navigate: TestPage Navigate;
        DocumentNo: Code[20];
    begin
        // Setup: Create Item and Purchase Return Order. Post Purchase Return Order as Receive.
        Initialize();
        LibraryInventory.CreateItem(Item);
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Item."No.", false);  // Invoice as FALSE.
        ReturnShipmentHeader.Get(DocumentNo);

        // Exercise: Open Navigate Page from Posted Return Shipment.
        NavigateFromPostedReturnShipment(Navigate, ReturnShipmentHeader);

        // Verify: Navigate Page from Posted Return Shipment.
        VerifyNavigatePage(
          Navigate, ReturnShipmentHeader."No.", ReturnShipmentHeader."Posting Date", PostedReturnShipmentDocumentTypeTxt,
          Vendor.TableCaption(), ReturnShipmentHeader."Buy-from Vendor No.", 3);  // No. of Line value required on Navigate Page.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedPurchaseCreditMemo()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Navigate: TestPage Navigate;
    begin
        // Setup: Create Item and Purchase Return Order. Post Purchase Return Order as Receive and Invoice.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Item."No.", true);  // Invoice as TRUE.
        FindPostedPurchaseCreditMemoHeader(PurchCrMemoHdr, PurchaseHeader."No.");

        // Exercise: Open Navigate Page from Posted Purchase Credit Memo.
        NavigateFromPostedPurchaseCreditMemo(Navigate, PurchCrMemoHdr);

        // Verify: Navigate Page from Posted Purchase Credit Memo.
        VerifyNavigatePage(
          Navigate, PurchCrMemoHdr."No.", PurchCrMemoHdr."Posting Date", PostedPurchaseCreditMemoDocumentTypeTxt, Vendor.TableCaption(),
          PurchCrMemoHdr."Buy-from Vendor No.", 6);  // No. of Line value required on Navigate Page.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedServiceShipment()
    var
        Item: Record Item;
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Navigate: TestPage Navigate;
        OldCreditWarnings: Integer;
    begin
        // [FEATURE] [Shipment] [Service]
        // [SCENARIO] Check that Navigate Page is opened for correct source and contains correct number of lines, for Posted Service Shipment.

        // Setup: Create Item, Service Item and Service Order. Post Service Order as Ship.
        Initialize();
        OldCreditWarnings := UpdateSalesAndReceivablesSetup(SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateItemAndServiceItem(Item, ServiceItem);
        CreateAndPostServiceOrder(ServiceHeader, ServiceItem."Customer No.", ServiceItem."No.", Item."No.", true, false);  // Ship as TRUE and Invoice as FALSE.
        FindPostedServiceShipmentHeader(ServiceShipmentHeader, ServiceHeader."No.");

        // Exercise: Open Navigate Page from Posted Service Shipment.
        NavigateFromPostedServiceShipment(Navigate, ServiceShipmentHeader);

        // Verify: Navigate Page from Posted Service Shipment.
        VerifyNavigatePage(
          Navigate, ServiceShipmentHeader."No.", ServiceShipmentHeader."Posting Date", PostedServiceShipmentDocumentTypeTxt,
          Customer.TableCaption(), ServiceShipmentHeader."Customer No.", 4);  // No. of Line value required on Navigate Page.

        // Tear Down.
        UpdateSalesAndReceivablesSetup(OldCreditWarnings);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedServiceInvoice()
    var
        Item: Record Item;
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Navigate: TestPage Navigate;
        OldCreditWarnings: Integer;
    begin
        // [FEATURE] [Invoice] [Service]
        // [SCENARIO] Check that Navigate Page is opened for correct source and contains correct number of lines, for Posted Service Invoice.

        // Setup: Create Item, Service Item and Service Order. Post Service Order as Ship and Invoice.
        Initialize();
        OldCreditWarnings := UpdateSalesAndReceivablesSetup(SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateItemAndServiceItem(Item, ServiceItem);
        CreateAndPostServiceOrder(ServiceHeader, ServiceItem."Customer No.", ServiceItem."No.", Item."No.", true, true);  // Ship as TRUE and Invoice as TRUE.
        FindPostedServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");

        // Exercise: Open Navigate Page from Posted Service Invoice.
        NavigateFromPostedServiceInvoice(Navigate, ServiceInvoiceHeader);

        // Verify: Navigate Page from Posted Service Invoice.
        VerifyNavigatePage(
          Navigate, ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Posting Date", PostedServiceInvoiceDocumentTypeTxt,
          Customer.TableCaption(), ServiceInvoiceHeader."Customer No.", 7);  // Using 7 as No. of Line on Navigate Page.

        // Tear Down.
        UpdateSalesAndReceivablesSetup(OldCreditWarnings);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedServiceCreditMemo()
    var
        Item: Record Item;
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        Navigate: TestPage Navigate;
    begin
        // [FEATURE] [Credit Memo] [Service]
        // [SCENARIO] Check that Navigate Page is opened for correct source and contains correct number of lines, for Posted Service Credit Memo.

        // Setup: Create Item, Service Item and Service Credit Memo. Post Service Credit Memo.
        Initialize();
        CreateItemAndServiceItem(Item, ServiceItem);
        CreateAndPostServiceCreditMemo(ServiceHeader, ServiceItem."Customer No.", Item."No.");
        FindPostedServiceCreditMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");

        // Exercise: Open Navigate Page from Posted Service Credit Memo.
        NavigateFromPostedServiceCreditMemo(Navigate, ServiceCrMemoHeader);

        // Verify:  Navigate Page from  Posted Service Credit Memo.
        VerifyNavigatePage(
          Navigate, ServiceCrMemoHeader."No.", ServiceCrMemoHeader."Posting Date", PostedServiceCreditMemoDocumentTypeTxt,
          Customer.TableCaption(), ServiceCrMemoHeader."Customer No.", 8);  // Using 8 as No. of Line on Navigate Page.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedTransferShipment()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        Navigate: TestPage Navigate;
        DocumentNo: Code[20];
    begin
        // Setup: Create Item and Transfer Order. Post Transfer Order with Shipment.
        Initialize();
        LibraryInventory.CreateItem(Item);
        DocumentNo := CreateTransferOrder(TransferHeader, Item, false);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        TransferShipmentHeader.SetRange("Transfer-from Code", TransferHeader."Transfer-from Code");
        TransferShipmentHeader.SetRange("Transfer-to Code", TransferHeader."Transfer-to Code");
        TransferShipmentHeader.SetRange("Posting Date", TransferHeader."Posting Date");
        TransferShipmentHeader.FindFirst();

        // Exercise: Open Navigate Page from Posted Transfer Shipment.
        NavigateFromPostedTransferShipment(Navigate, TransferShipmentHeader);

        // Verify: Navigate Page from Posted Transfer Shipment.
        VerifyNavigatePage(
          Navigate, TransferShipmentHeader."No.", TransferShipmentHeader."Posting Date", '', '', '', 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedDirectTransfer()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        DirectTransHeader: Record "Direct Trans. Header";
        Navigate: TestPage Navigate;
        TransferOrderPostTransfer: Codeunit "TransferOrder-Post Transfer";
        DocumentNo: Code[20];
    begin
        // Setup: Create Item and Transfer Order. Post Direct Transfer.
        Initialize();
        LibraryInventory.CreateItem(Item);
        DocumentNo := CreateTransferOrder(TransferHeader, Item, true);
        TransferOrderPostTransfer.SetHideValidationDialog(true);
        TransferOrderPostTransfer.Run(TransferHeader);
        DirectTransHeader.SetRange("Transfer-from Code", TransferHeader."Transfer-from Code");
        DirectTransHeader.SetRange("Transfer-to Code", TransferHeader."Transfer-to Code");
        DirectTransHeader.SetRange("Posting Date", TransferHeader."Posting Date");
        DirectTransHeader.FindFirst();

        // Exercise: Open Navigate Page from Posted Direct Transfer.
        NavigateFromPostedDirectTransfer(Navigate, DirectTransHeader);

        // Verify: Navigate Page from Posted Direct Transfer.
        VerifyNavigatePage(
          Navigate, DirectTransHeader."No.", DirectTransHeader."Posting Date", '', '', '', 3);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Navigate");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Navigate");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryApplicationArea.EnableEssentialSetup();
        NoSeriesSetup();
        Commit();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Navigate");
    end;

    local procedure NoSeriesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Return Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Credit Memo Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Return Shpt. Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Credit Memo Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Service Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ServiceMgtSetup.Validate("Service Item Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ServiceMgtSetup.Validate("Service Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ServiceMgtSetup.Validate("Service Credit Memo Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ServiceMgtSetup.Validate("Posted Serv. Credit Memo Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ServiceMgtSetup.Validate("Posted Service Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ServiceMgtSetup.Validate("Posted Service Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ServiceMgtSetup.Modify(true);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; Invoice: Boolean): Code[20]
    begin
        CreatePurchaseDocument(PurchaseHeader, DocumentType, ItemNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice));  // Receive as TRUE.
    end;

    local procedure CreateAndPostServiceCreditMemo(var ServiceHeader: Record "Service Header"; ServiceItemCustomerNo: Code[20]; ItemNo: Code[20])
    begin
        CreateServiceCreditMemo(ServiceHeader, ServiceItemCustomerNo, ItemNo);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);  // Ship, Consume, and Invoice as FALSE for Posting of Credit Memo.
    end;

    local procedure CreateAndPostSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; Invoice: Boolean): Code[20]
    begin
        CreateSalesDocument(SalesHeader, DocumentType, ItemNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));  // Ship as TRUE.
    end;

    local procedure CreateAndPostServiceOrder(var ServiceHeader: Record "Service Header"; ServiceItemCustomerNo: Code[20]; ServiceItemNo: Code[20]; ItemNo: Code[20]; Ship: Boolean; Invoice: Boolean)
    begin
        CreateServiceOrder(ServiceHeader, ServiceItemCustomerNo, ServiceItemNo, ItemNo);
        LibraryService.PostServiceOrder(ServiceHeader, Ship, false, Invoice);  // Consume as FALSE.
    end;

    local procedure CreateItemAndServiceItem(var Item: Record Item; var ServiceItem: Record "Service Item")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceItem(ServiceItem, '');
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateServiceCreditMemo(var ServiceHeader: Record "Service Header"; ServiceItemCustomerNo: Code[20]; ItemNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceItemCustomerNo);
        CreateServiceLine(ServiceLine, ServiceHeader, ItemNo);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; ItemNo: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; ServiceItemCustomerNo: Code[20]; ServiceItemNo: Code[20]; ItemNo: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItemCustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);
        CreateServiceLine(ServiceLine, ServiceHeader, ItemNo);
        UpdateServiceItemLineNo(ServiceLine, ServiceItemLine."Line No.");
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; Item: Record Item; Direct: Boolean): Code[20]
    var
        TransferLine: Record "Transfer Line";
        ItemJournalLine: Record "Item Journal Line";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
    begin
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        if not Direct then
            LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        if Direct then begin
            TransferHeader."Direct Transfer" := true;
            TransferHeader.Modify();
        end;
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);

        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, LocationFrom.Code, Item."Inventory Posting Group");
        InventoryPostingSetup.Validate("Inventory Account", LibraryERM.CreateGLAccountNo());
        InventoryPostingSetup.Modify();

        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, LocationTo.Code, Item."Inventory Posting Group");
        InventoryPostingSetup.Validate("Inventory Account", LibraryERM.CreateGLAccountNo());
        InventoryPostingSetup.Modify();

        LibraryInventory.CreateItemJnlLine(
            ItemJournalLine, "Item Ledger Entry Type"::"Positive Adjmt.", WOrkDate(), Item."No.", 1, LocationFrom.Code);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJournalLine);

        exit(TransferHeader."No.");
    end;

    local procedure FindPostedPurchaseCreditMemoHeader(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; ReturnOrderNo: Code[20])
    begin
        PurchCrMemoHdr.SetRange("Return Order No.", ReturnOrderNo);
        PurchCrMemoHdr.FindFirst();
    end;

    local procedure FindPostedPurchaseInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header"; OrderNo: Code[20])
    begin
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindFirst();
    end;

    local procedure FindPostedSalesCreditMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; ReturnOrderNo: Code[20])
    begin
        SalesCrMemoHeader.SetRange("Return Order No.", ReturnOrderNo);
        SalesCrMemoHeader.FindFirst();
    end;

    local procedure FindPostedSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; OrderNo: Code[20])
    begin
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.FindFirst();
    end;

    local procedure FindPostedServiceCreditMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; PreAssignedNo: Code[20])
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
    end;

    local procedure FindPostedServiceInvoiceHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; OrderNo: Code[20])
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure FindPostedServiceShipmentHeader(var ServiceShipmentHeader: Record "Service Shipment Header"; OrderNo: Code[20])
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
    end;

    local procedure NavigateFromPostedPurchaseCreditMemo(var Navigate: TestPage Navigate; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        // Open Navigate Page from Posted Purchase Credit Memo.
        Navigate.Trap();
        PurchCrMemoHdr.Navigate();
    end;

    local procedure NavigateFromPostedPurchaseInvoice(var Navigate: TestPage Navigate; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        // Open Navigate Page from Posted Purchase Invoice.
        Navigate.Trap();
        PurchInvHeader.Navigate();
    end;

    local procedure NavigateFromPostedPurchaseReceipt(var Navigate: TestPage Navigate; PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
        // Open Navigate Page from Posted Purchase Receipt.
        Navigate.Trap();
        PurchRcptHeader.Navigate();
    end;

    local procedure NavigateFromPostedReturnReceipt(var Navigate: TestPage Navigate; ReturnReceiptHeader: Record "Return Receipt Header")
    begin
        // Open Navigate Page from Posted Return Receipt.
        Navigate.Trap();
        ReturnReceiptHeader.Navigate();
    end;

    local procedure NavigateFromPostedReturnShipment(var Navigate: TestPage Navigate; ReturnShipmentHeader: Record "Return Shipment Header")
    begin
        // Open Navigate Page from Posted Return Shipment.
        Navigate.Trap();
        ReturnShipmentHeader.Navigate();
    end;

    local procedure NavigateFromPostedSalesCreditMemo(var Navigate: TestPage Navigate; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        // Open Navigate Page from Posted Sales Credit Memo.
        Navigate.Trap();
        SalesCrMemoHeader.Navigate();
    end;

    local procedure NavigateFromPostedSalesInvoice(var Navigate: TestPage Navigate; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        // Open Navigate Page from Posted Sales Invoice.
        Navigate.Trap();
        SalesInvoiceHeader.Navigate();
    end;

    local procedure NavigateFromPostedSalesShipment(var Navigate: TestPage Navigate; SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        // Open Navigate Page from Posted Sales Shipment.
        Navigate.Trap();
        SalesShipmentHeader.Navigate();
    end;

    local procedure NavigateFromPostedServiceCreditMemo(var Navigate: TestPage Navigate; ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        // Open Navigate Page from Posted Service Credit Memo.
        Navigate.Trap();
        ServiceCrMemoHeader.Navigate();
    end;

    local procedure NavigateFromPostedServiceInvoice(var Navigate: TestPage Navigate; ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        // Open Navigate Page from Posted Service Invoice.
        Navigate.Trap();
        ServiceInvoiceHeader.Navigate();
    end;

    local procedure NavigateFromPostedServiceShipment(var Navigate: TestPage Navigate; ServiceShipmentHeader: Record "Service Shipment Header")
    begin
        // Open Navigate Page from Posted Service Shipment.
        Navigate.Trap();
        ServiceShipmentHeader.Navigate();
    end;

    local procedure NavigateFromPostedTransferShipment(var Navigate: TestPage Navigate; TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        // Open Navigate Page from Posted Transfer Shipment.
        Navigate.Trap();
        TransferShipmentHeader.Navigate();
    end;

    local procedure NavigateFromPostedDirectTransfer(var Navigate: TestPage Navigate; DirectTransHeader: Record "Direct Trans. Header")
    begin
        // Open Navigate Page from Direct Transfer Header.
        Navigate.Trap();
        DirectTransHeader.Navigate();
    end;

    local procedure UpdateSalesAndReceivablesSetup(CreditWarnings: Option) OldCreditWarnings: Integer
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldCreditWarnings := SalesReceivablesSetup."Credit Warnings";
        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateServiceItemLineNo(var ServiceLine: Record "Service Line"; ServiceItemLineLineNo: Integer)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineLineNo);
        ServiceLine.Modify(true);
    end;

    local procedure VerifyNavigatePage(Navigate: TestPage Navigate; DocumentNo: Code[20]; PostingDate: Date; DocumentType: Text[50]; SourceType: Text[30]; SourceNo: Code[20]; ExpectedNoOfLines: Integer)
    begin
        // Verify Navigate Page Header.
        Navigate.DocNoFilter.AssertEquals(DocumentNo);
        Navigate.PostingDateFilter.AssertEquals(PostingDate);
        Navigate.DocType.AssertEquals(DocumentType);
        Navigate.SourceType.AssertEquals(SourceType);
        Navigate.SourceNo.AssertEquals(SourceNo);

        // Verify Navigate Page Line.
        VerifyNoOfLinesOnNavigatePage(Navigate, ExpectedNoOfLines);
    end;

    local procedure VerifyNoOfLinesOnNavigatePage(Navigate: TestPage Navigate; ExpectedNoOfLines: Integer)
    var
        ActualLineCount: Integer;
    begin
        // Verify Navigate Line on Navigate Page.
        Navigate.First();
        repeat
            ActualLineCount += 1;
        until not Navigate.Next();
        Assert.AreEqual(ExpectedNoOfLines, ActualLineCount, NoOfLinesErr);
    end;
}

