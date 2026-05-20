codeunit 137930 "SCM Item Charge Blocked Item"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item] [Item Charge]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePostItemChargeAssignedToReceiptWhenItemPurchaseBlocked()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Receipt] [Purchase Blocked]
        // [SCENARIO 300597] Item Charge can be posted for Purchase Receipt with Purchase Blocked Item
        Initialize();
        ModifyPurchasesPayablesSetupReceiptOnInvoice(true);

        // [GIVEN] Purchase Receipt for Item was posted and then Item was Purchase Blocked
        ItemNo := LibraryInventory.CreateItemNo();
        PostSimplePurchaseDocWithItem(PurchaseHeader."Document Type"::Invoice, ItemNo);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Purchase Receipt", ItemNo);
        BlockItem(ItemNo, false, false, true);

        // [GIVEN] Purchase Invoice with Item Charge assigned to Receipt had Amount Including VAT = 1000
        CreatePurchaseInvoiceWithItemChargeAssignment(PurchaseHeader, ItemLedgerEntry, "Purchase Applies-to Document Type"::Receipt);

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase Receipt Item Ledger Entry has Cost Amount (Actual) = 1000
        VerifyItemLedgerEntryAmounts(
          ItemNo, ItemLedgerEntry."Document Type"::"Purchase Receipt", true, PurchaseHeader."Amount Including VAT", 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePostItemChargeAssignedToTransferReceiptWhenItemPurchaseBlocked()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
        InTransitLocationCode: Code[10];
    begin
        // [FEATURE] [Purchase] [Transfer] [Purchase Blocked]
        // [SCENARIO 300597] Item Charge can be posted for Transfer Receipt with Purchase Blocked Item
        Initialize();

        // [GIVEN] Item was Purchase Blocked
        ItemNo := CreateBlockedItem(false, false, true);
        CreateTransferLocationCodes(FromLocationCode, ToLocationCode, InTransitLocationCode);
        MakeItemStockAtLocation(ItemNo, FromLocationCode);

        // [GIVEN] Posted Transfer Order from BLUE to RED with the Item
        PostTransferOrderWithItem(ItemNo, FromLocationCode, ToLocationCode, InTransitLocationCode);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Transfer Receipt", ItemNo);

        // [GIVEN] Purchase Invoice with Item Charge assigned to Transfer Receipt had Amount Including VAT = 1000
        CreatePurchaseInvoiceWithItemChargeAssignment(
          PurchaseHeader, ItemLedgerEntry, "Purchase Applies-to Document Type"::"Transfer Receipt");

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Positive Transfer Receipt Item Ledger Entry has Cost Amount (Actual) = 1000
        VerifyItemLedgerEntryAmounts(
          ItemNo, ItemLedgerEntry."Document Type"::"Transfer Receipt", true, PurchaseHeader."Amount Including VAT", 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePostItemChargeAssignedToReturnReceiptWhenItemPurchaseBlocked()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Return Receipt] [Purchase Blocked]
        // [SCENARIO 300597] Item Charge can be posted for Sales Return Receipt with Purchase Blocked Item
        Initialize();

        // [GIVEN] Item was Purchase Blocked
        ItemNo := CreateBlockedItem(false, false, true);

        // [GIVEN] Sales Return Receipt for the Item was posted
        PostSimpleSalesDocWithItem("Sales Document Type"::"Return Order", ItemNo);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Sales Return Receipt", ItemNo);

        // [GIVEN] Purchase Invoice with Item Charge assigned to Sales Return Receipt had Amount Including VAT = 1000
        CreatePurchaseInvoiceWithItemChargeAssignment(
          PurchaseHeader, ItemLedgerEntry, "Purchase Applies-to Document Type"::"Return Receipt");

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Sales Return Receipt Item Ledger Entry has Cost Amount (Actual) = 1000
        VerifyItemLedgerEntryAmounts(
          ItemNo, ItemLedgerEntry."Document Type"::"Sales Return Receipt", true, PurchaseHeader."Amount Including VAT", 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePostItemChargeAssignedToSalesShipmentWhenItemPurchaseBlocked()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Sales Shipment] [Purchase Blocked]
        // [SCENARIO 300597] Item Charge can be posted for Sales Shipment with Purchase Blocked Item
        Initialize();
        ModifySalesReceivablesSetupShipmentOnInvoice(true);

        // [GIVEN] Item was Purchase Blocked
        ItemNo := CreateBlockedItem(false, false, true);

        // [GIVEN] Sales Shipment for the Item was posted
        PostSimpleSalesDocWithItem("Sales Document Type"::Invoice, ItemNo);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Sales Shipment", ItemNo);

        // [GIVEN] Purchase Invoice with Item Charge assigned to Sales Shipment had Amount Including VAT = 1000
        CreatePurchaseInvoiceWithItemChargeAssignment(
          PurchaseHeader, ItemLedgerEntry, "Purchase Applies-to Document Type"::"Sales Shipment");

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Sales Shipment Item Ledger Entry has Cost Amount (Non-Invtbl.) = -1000
        VerifyItemLedgerEntryAmounts(
          ItemNo, ItemLedgerEntry."Document Type"::"Sales Shipment", false, 0, -PurchaseHeader."Amount Including VAT", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePostItemChargeAssignedToReturnShipmentWhenItemPurchaseBlocked()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Return Shipment] [Purchase Blocked]
        // [SCENARIO 300597] Item Charge can be posted for Purchase Return Shipment with Purchase Blocked Item
        Initialize();

        // [GIVEN] Purchase Return Shipment for Item was posted and then Item was Purchase Blocked
        ItemNo := LibraryInventory.CreateItemNo();
        PostSimplePurchaseDocWithItem(PurchaseHeader."Document Type"::"Return Order", ItemNo);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Purchase Return Shipment", ItemNo);
        BlockItem(ItemNo, false, false, true);

        // [GIVEN] Purchase Invoice with Item Charge assigned to Return Shipment had Amount Including VAT = 1000
        CreatePurchaseInvoiceWithItemChargeAssignment(
          PurchaseHeader, ItemLedgerEntry, "Purchase Applies-to Document Type"::"Return Shipment");

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase Return Shipment Item Ledger Entry has Cost Amount (Non-Invtbl.) = 1000
        VerifyItemLedgerEntryAmounts(
          ItemNo, ItemLedgerEntry."Document Type"::"Purchase Return Shipment", false, 0, PurchaseHeader."Amount Including VAT", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPostItemChargeAssignedToShipmentWhenItemSalesBlocked()
    var
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Shipment] [Sales Blocked]
        // [SCENARIO 300597] Item Charge can be posted for Sales Shipment with Sales Blocked Item
        Initialize();
        ModifySalesReceivablesSetupShipmentOnInvoice(true);

        // [GIVEN] Sales Shipment for Item was posted and then Item was Sales Blocked
        ItemNo := LibraryInventory.CreateItemNo();
        PostSimpleSalesDocWithItem("Sales Document Type"::Invoice, ItemNo);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Sales Shipment", ItemNo);
        BlockItem(ItemNo, false, true, false);

        // [GIVEN] Sales Invoice with Item Charge assigned to Shipment had Amount Including VAT = 1000
        CreateSalesInvoiceWithItemChargeAssignment(SalesHeader, ItemLedgerEntry, "Sales Applies-to Document Type"::Shipment);

        // [WHEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Shipment Item Ledger Entry has Sales Amount (Actual) = 1000
        VerifyItemLedgerEntryAmounts(
          ItemNo, ItemLedgerEntry."Document Type"::"Sales Shipment", false, 0, 0, SalesHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPostItemChargeAssignedToReturnReceiptWhenItemSalesBlocked()
    var
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Return Receipt] [Sales Blocked]
        // [SCENARIO 300597] Item Charge can be posted for Sales Return Receipt with Sales Blocked Item
        Initialize();

        // [GIVEN] Sales Return Receipt for the Item was posted and then Item was Sales Blocked
        ItemNo := LibraryInventory.CreateItemNo();
        PostSimpleSalesDocWithItem("Sales Document Type"::"Return Order", ItemNo);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Sales Return Receipt", ItemNo);
        BlockItem(ItemNo, false, true, false);

        // [GIVEN] Sales Invoice with Item Charge assigned to Sales Return Receipt had Amount Including VAT = 1000
        CreateSalesInvoiceWithItemChargeAssignment(
          SalesHeader, ItemLedgerEntry, "Sales Applies-to Document Type"::"Return Receipt");

        // [WHEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Return Receipt Item Ledger Entry has Sales Amount (Actual) = 1000
        VerifyItemLedgerEntryAmounts(
          ItemNo, ItemLedgerEntry."Document Type"::"Sales Return Receipt", true, 0, 0, SalesHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePostItemChargeAssignedToReceiptWhenItemBlocked()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Receipt] [Blocked]
        // [SCENARIO 300597] Item Charge cannot be posted for Purchase Receipt with Blocked Item
        Initialize();
        ModifyPurchasesPayablesSetupReceiptOnInvoice(true);

        // [GIVEN] Purchase Receipt for Item "I" was posted
        ItemNo := LibraryInventory.CreateItemNo();
        PostSimplePurchaseDocWithItem(PurchaseHeader."Document Type"::Invoice, ItemNo);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Purchase Receipt", ItemNo);

        // [GIVEN] Purchase Invoice with Item Charge assigned to Receipt had Amount Including VAT = 1000
        CreatePurchaseInvoiceWithItemChargeAssignment(PurchaseHeader, ItemLedgerEntry, "Purchase Applies-to Document Type"::Receipt);

        // [GIVEN] Item was Blocked
        BlockItem(ItemNo, true, false, false);

        // [WHEN] Post Purchase Invoice
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Error 'Blocked must be equal to 'No'  in Item: No.="I"'
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePostItemChargeAssignedToTransferReceiptWhenItemBlocked()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemNo: Code[20];
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
        InTransitLocationCode: Code[10];
    begin
        // [FEATURE] [Purchase] [Transfer] [Blocked]
        // [SCENARIO 300597] Item Charge cannot be posted for Transfer Receipt with Blocked Item
        Initialize();

        // [GIVEN] Posted Transfer Order from BLUE to RED with the Item
        ItemNo := LibraryInventory.CreateItemNo();
        CreateTransferLocationCodes(FromLocationCode, ToLocationCode, InTransitLocationCode);
        MakeItemStockAtLocation(ItemNo, FromLocationCode);
        PostTransferOrderWithItem(ItemNo, FromLocationCode, ToLocationCode, InTransitLocationCode);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Transfer Receipt", ItemNo);

        // [GIVEN] Purchase Invoice with Item Charge assigned to Transfer Receipt had Amount Including VAT = 1000
        CreatePurchaseInvoiceWithItemChargeAssignment(
          PurchaseHeader, ItemLedgerEntry, "Purchase Applies-to Document Type"::"Transfer Receipt");

        // [GIVEN] Item was Blocked
        BlockItem(ItemNo, true, false, false);

        // [WHEN] Post Purchase Invoice
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Error 'Blocked must be equal to 'No'  in Item: No.="I"'
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePostItemChargeAssignedToReturnReceiptWhenItemBlocked()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Return Receipt] [Blocked]
        // [SCENARIO 300597] Item Charge cannot be posted for Sales Return Receipt with Blocked Item
        Initialize();

        // [GIVEN] Sales Return Receipt for the Item was posted
        ItemNo := LibraryInventory.CreateItemNo();
        PostSimpleSalesDocWithItem("Sales Document Type"::"Return Order", ItemNo);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Sales Return Receipt", ItemNo);

        // [GIVEN] Purchase Invoice with Item Charge assigned to Sales Return Receipt had Amount Including VAT = 1000
        CreatePurchaseInvoiceWithItemChargeAssignment(
          PurchaseHeader, ItemLedgerEntry, "Purchase Applies-to Document Type"::"Return Receipt");

        // [GIVEN] Item was Blocked
        BlockItem(ItemNo, true, false, false);

        // [WHEN] Post Purchase Invoice
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Error 'Blocked must be equal to 'No'  in Item: No.="I"'
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePostItemChargeAssignedToSalesShipmentWhenItemBlocked()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Sales Shipment] [Blocked]
        // [SCENARIO 300597] Item Charge cannot be posted for Sales Shipment with Blocked Item
        Initialize();
        ModifySalesReceivablesSetupShipmentOnInvoice(true);

        // [GIVEN] Sales Shipment for the Item was posted
        ItemNo := LibraryInventory.CreateItemNo();
        PostSimpleSalesDocWithItem("Sales Document Type"::Invoice, ItemNo);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Sales Shipment", ItemNo);

        // [GIVEN] Purchase Invoice with Item Charge assigned to Sales Shipment had Amount Including VAT = 1000
        CreatePurchaseInvoiceWithItemChargeAssignment(
          PurchaseHeader, ItemLedgerEntry, "Purchase Applies-to Document Type"::"Sales Shipment");

        // [GIVEN] Item was Blocked
        BlockItem(ItemNo, true, false, false);

        // [WHEN] Post Purchase Invoice
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Error 'Blocked must be equal to 'No'  in Item: No.="I"'
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePostItemChargeAssignedToReturnShipmentWhenItemBlocked()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Return Shipment] [Blocked]
        // [SCENARIO 300597] Item Charge cannot be posted for Purchase Return Shipment with Blocked Item
        Initialize();

        // [GIVEN] Purchase Return Shipment for Item was posted and then Item was Purchase Blocked
        ItemNo := LibraryInventory.CreateItemNo();
        PostSimplePurchaseDocWithItem(PurchaseHeader."Document Type"::"Return Order", ItemNo);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Purchase Return Shipment", ItemNo);
        BlockItem(ItemNo, false, false, true);

        // [GIVEN] Purchase Invoice with Item Charge assigned to Return Shipment had Amount Including VAT = 1000
        CreatePurchaseInvoiceWithItemChargeAssignment(
          PurchaseHeader, ItemLedgerEntry, "Purchase Applies-to Document Type"::"Return Shipment");

        // [GIVEN] Item was Blocked
        BlockItem(ItemNo, true, false, false);

        // [WHEN] Post Purchase Invoice
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Error 'Blocked must be equal to 'No'  in Item: No.="I"'
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPostItemChargeAssignedToShipmentWhenItemBlocked()
    var
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Shipment] [Blocked]
        // [SCENARIO 300597] Item Charge cannot be posted for Sales Shipment with Blocked Item
        Initialize();
        ModifySalesReceivablesSetupShipmentOnInvoice(true);

        // [GIVEN] Sales Shipment for Item "I" was posted
        ItemNo := LibraryInventory.CreateItemNo();
        PostSimpleSalesDocWithItem("Sales Document Type"::Invoice, ItemNo);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Sales Shipment", ItemNo);

        // [GIVEN] Sales Invoice with Item Charge assigned to Shipment had Amount Including VAT = 1000
        CreateSalesInvoiceWithItemChargeAssignment(SalesHeader, ItemLedgerEntry, "Sales Applies-to Document Type"::Shipment);

        // [GIVEN] Item was Blocked
        BlockItem(ItemNo, true, false, false);

        // [WHEN] Post Sales Invoice
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Error 'Blocked must be equal to 'No'  in Item: No.="I"'
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPostItemChargeAssignedToReturnReceiptWhenItemBlocked()
    var
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Return Receipt] [Blocked]
        // [SCENARIO 300597] Item Charge can be posted for Sales Return Receipt with Blocked Item
        Initialize();

        // [GIVEN] Sales Return Receipt for the Item was posted
        ItemNo := LibraryInventory.CreateItemNo();
        PostSimpleSalesDocWithItem("Sales Document Type"::"Return Order", ItemNo);
        FindItemLedgerEntryByDocTypeAndItemNo(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Sales Return Receipt", ItemNo);

        // [GIVEN] Sales Invoice with Item Charge assigned to Sales Return Receipt had Amount Including VAT = 1000
        CreateSalesInvoiceWithItemChargeAssignment(
          SalesHeader, ItemLedgerEntry, "Sales Applies-to Document Type"::"Return Receipt");

        // [GIVEN] Item was Blocked
        BlockItem(ItemNo, true, false, false);

        // [WHEN] Post Sales Invoice
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Error 'Blocked must be equal to 'No'  in Item: No.="I"'
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Item Charge Blocked Item");

        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        IsInitialized := true;
    end;

    local procedure ModifyPurchasesPayablesSetupReceiptOnInvoice(ReceiptOnInvoice: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Receipt on Invoice", ReceiptOnInvoice);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ModifySalesReceivablesSetupShipmentOnInvoice(ShipmentOnInvoice: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Shipment on Invoice", ShipmentOnInvoice);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateBlockedItem(Blocked: Boolean; SalesBlocked: Boolean; PurchaseBlocked: Boolean): Code[20]
    var
        ItemNo: Code[20];
    begin
        ItemNo := LibraryInventory.CreateItemNo();
        BlockItem(ItemNo, Blocked, SalesBlocked, PurchaseBlocked);
        exit(ItemNo);
    end;

    local procedure BlockItem(ItemNo: Code[20]; Blocked: Boolean; SalesBlocked: Boolean; PurchaseBlocked: Boolean)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate(Blocked, Blocked);
        Item.Validate("Sales Blocked", SalesBlocked);
        Item.Validate("Purchasing Blocked", PurchaseBlocked);
        Item.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceWithItemChargeAssignment(var PurchaseHeader: Record "Purchase Header"; ItemLedgerEntry: Record "Item Ledger Entry"; ItemChargeAssignPurchApplToDocType: Enum "Purchase Applies-to Document Type")
    var
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(),
          LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);

        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignPurchApplToDocType, ItemLedgerEntry."Document No.",
          ItemLedgerEntry."Document Line No.", ItemLedgerEntry."Item No.");
        PurchaseHeader.CalcFields("Amount Including VAT");
    end;

    local procedure CreateSalesInvoiceWithItemChargeAssignment(var SalesHeader: Record "Sales Header"; ItemLedgerEntry: Record "Item Ledger Entry"; ItemChargeAssignSalesApplToDocType: Enum "Sales Applies-to Document Type")
    var
        SalesLine: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(),
          LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);

        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine, ItemChargeAssignSalesApplToDocType, ItemLedgerEntry."Document No.",
          ItemLedgerEntry."Document Line No.", ItemLedgerEntry."Item No.");
        SalesHeader.CalcFields("Amount Including VAT");
    end;

    local procedure CreateTransferLocationCodes(var FromLocationCode: Code[10]; var ToLocationCode: Code[10]; var InTransitLocationCode: Code[10])
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
    begin
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);
        FromLocationCode := FromLocation.Code;
        ToLocationCode := ToLocation.Code;
        InTransitLocationCode := InTransitLocation.Code;
    end;

    local procedure PostTransferOrderWithItem(ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitLocationCode: Code[10])
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocationCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, LibraryRandom.RandInt(10));
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
    end;

    local procedure PostSimplePurchaseDocWithItem(DocType: Enum "Purchase Document Type"; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostSimpleSalesDocWithItem(DocType: Enum "Sales Document Type"; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure MakeItemStockAtLocation(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, ItemNo, LocationCode, '', LibraryRandom.RandDecInRange(10, 20, 2));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure FindItemLedgerEntryByDocTypeAndItemNo(var ItemLedgerEntry: Record "Item Ledger Entry"; DocType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document Type", DocType);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure VerifyItemLedgerEntryAmounts(ItemNo: Code[20]; DocType: Enum "Item Ledger Document Type"; Positive: Boolean; CostAmountActual: Decimal; CostAmountNonInvtbl: Decimal; SalesAmountActual: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document Type", DocType);
        ItemLedgerEntry.SetRange(Positive, Positive);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)", "Sales Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", CostAmountActual);
        ItemLedgerEntry.TestField("Cost Amount (Non-Invtbl.)", CostAmountNonInvtbl);
        ItemLedgerEntry.TestField("Sales Amount (Actual)", SalesAmountActual);
    end;
}

