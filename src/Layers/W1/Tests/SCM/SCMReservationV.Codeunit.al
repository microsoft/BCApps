codeunit 137272 "SCM Reservation V"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reservation] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ReservationManagement: Codeunit "Reservation Management";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        isInitialized: Boolean;
        ExpectedMessage: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        WrongQuantityErr: Label 'Wrong Quantity in Purchase Line for Item %1.';
        ReservEntryExistenceErr: Label 'Reservation entry existence is wrong.';
        ReservEntryQtyErr: Label 'Wrong Quantity in Reservation Entry.';
        TrackingAction: Option "Assign Lot No.","Set Qty. to Handle","Set QTH with AtE";

    [Test]
    [HandlerFunctions('CreateReturnRelatedDocumentsReportHandler')]
    [Scope('OnPrem')]
    procedure PurchOrdCreatedFromSalesRetOrd()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Posted Purchase Order created from Sales Return Order.

        // Setup: Create Purchase Order from Sales Return Order.
        Initialize();
        CreateSalesRetOrderWithRetRelatedDocuments(LibrarySales.CreateCustomerNo(), SalesLine, false, true, false);

        // Exercise.
        CreateAndPostWhseReceipt(SalesLine);

        // Verify: Verify Purchase Receipt Line.
        VerifyPurchaseReceiptLine(SalesLine."No.", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('CreateReturnRelatedDocumentsReportHandler,ReservationPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure PurchRetOrdCreatedFromSalesRetOrd()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Verify Posted Purchase Return Order created from Sales Return Order.

        // Setup: Create Purchase Return Order from Sales Return Order, Release Purchase Return Order with Reserve, create And post Warehouse Receipt, create Warehouse Shipment with Pick.
        Initialize();
        CreateSalesRetOrderWithRetRelatedDocuments(LibrarySales.CreateCustomerNo(), SalesLine, true, false, false);
        ReleasePurchaseReturnOrderWithReserve(PurchaseHeader, SalesLine."Document Type", SalesLine."No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateAndPostWhseReceiptForSalesReturnOrder(SalesHeader, SalesLine."Location Code");
        RegisterWarehouseActivity(WarehouseActivityHeader.Type::"Put-away", SalesLine."Location Code");
        CreateWarehouseShipmentWithPick(PurchaseHeader, SalesLine."Location Code");

        // Excercise: Post Sales Return Order.

        PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.");

        // Verify: Verify Return Receipt Line.
        VerifyReturnReceiptLine(SalesLine."No.", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('CreateReturnRelatedDocumentsReportHandler,ReservationPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure SalesOrdCreatedFromSalesRetOrd()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Posted Sales Order created from Sales Return Order.

        // Setup: Create Sales Order from Sales Return Order, post Sales Return Order, release Sales Orders with Reserve, create and post Warehouse Receipt, create Warehouse Shipment with Pick.
        Initialize();
        CreateSalesRetOrderWithRetRelatedDocuments(LibrarySales.CreateCustomerNo(), SalesLine, false, false, true);
        PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.");

        // Excercise.
        CreateAndPostWhseShipmentWithPick(SalesLine."No.", SalesLine."Location Code");

        // Verify: Verify Sales Shipment Line.
        VerifySalesShipmentLine(SalesLine."No.", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,CreateReturnRelatedDocumentsReportHandler')]
    [Scope('OnPrem')]
    procedure PurchRetOrdCreatedWithItemTrkgFromSalesRetOrd()
    var
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
        LotNo: Code[10];
        CustomerNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify Posted Purchase Return Order created from Sales Return Order.

        // Setup: Create Purchase Return Order from Sales Return Order, Release Purchase Return Order with Reserve, create And post Warehouse Receipt, create Warehouse Shipment with Pick.
        Initialize();
        ItemNo := CreateItem();
        Quantity := CreatePurchaseForItemWithLotNo(ItemNo, LotNo);
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreatePostSalesOrder(SalesHeader, CustomerNo, ItemNo, LotNo, Quantity / 2, Quantity / 2, true, true);
        CreatePostSalesReturn(SalesHeader, CustomerNo, Quantity / 2, true, false);

        // Excercise: Create Purchase Return Order.
        CreateReturnRelatedDocuments(LibraryPurchase.CreateVendorNo(), SalesHeader, true, false, false);

        // Verify: Verify Return Order Line Quantity and Item Tracking.
        VerifyPurchaseLineExists(ItemNo, Quantity / 2);
        VerifyExistenceOfItemTracking(ItemNo, LotNo, true);
        VerifyItemTrackingQty(ItemNo, LotNo, Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,CreateReturnRelatedDocumentsReportHandler')]
    [Scope('OnPrem')]
    procedure PurchRetOrdCreatedWithItemTrkgFromSalesRetOrdPartPstd()
    var
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
        LotNo: Code[10];
        CustomerNo: Code[20];
        Quantity: Decimal;
        HalfShippedQty: Decimal;
    begin
        // Verify Posted Purchase Return Order created from Sales Return Order.

        // Setup: Create Purchase Return Order from Sales Return Order, Release Purchase Return Order with Reserve, create And post Warehouse Receipt, create Warehouse Shipment with Pick.
        Initialize();
        ItemNo := CreateItem();
        Quantity := CreatePurchaseForItemWithLotNo(ItemNo, LotNo);
        HalfShippedQty := Quantity / 4;
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreatePostSalesOrder(SalesHeader, CustomerNo, ItemNo, LotNo, Quantity / 2, Quantity / 2, true, true);
        CreatePostSalesReturn(SalesHeader, CustomerNo, HalfShippedQty, true, false);

        // Excercise: Create Purchase Return Order.
        CreateReturnRelatedDocuments(LibraryPurchase.CreateVendorNo(), SalesHeader, true, false, false);

        // Verify: Verify Return Order Line Quantity and Item Tracking.
        VerifyPurchaseLineExists(ItemNo, Quantity / 2);
        VerifyExistenceOfItemTracking(ItemNo, LotNo, true);
        VerifyItemTrackingQty(ItemNo, LotNo, HalfShippedQty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,CreateReturnRelatedDocumentsReportHandler')]
    [Scope('OnPrem')]
    procedure PurchRetOrdCreatedWithItemTrkgFromSalesRetOrdNotPstd()
    var
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
        LotNo: Code[10];
        CustomerNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify Posted Purchase Return Order created from Sales Return Order.

        // Setup: Create Purchase Return Order from Sales Return Order, Release Purchase Return Order with Reserve, create And post Warehouse Receipt, create Warehouse Shipment with Pick.
        Initialize();
        ItemNo := CreateItem();
        Quantity := CreatePurchaseForItemWithLotNo(ItemNo, LotNo);
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreatePostSalesOrder(SalesHeader, CustomerNo, ItemNo, LotNo, Quantity / 2, Quantity / 2, true, true);
        CreateSalesReturn(SalesHeader, CustomerNo, 0);

        // Excercise: Create Purchase Return Order.
        CreateReturnRelatedDocuments(LibraryPurchase.CreateVendorNo(), SalesHeader, true, false, false);

        // Verify: Verify Return Order Line Quantity and Item Tracking.
        VerifyPurchaseLineExists(ItemNo, Quantity / 2);
        VerifyExistenceOfItemTracking(ItemNo, LotNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositiveSurplusCreatedForTrackedItem()
    var
        Item: Record Item;
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 362340] Positive surpus entry created when tracked item is partially sold
        // [GIVEN] Item "I" with "Tracking Only" tracking policy
        CreateItemWithTrackingPolicy(Item);

        // [GIVEN] 3X psc. of item "I" are available on inventory
        Qty := LibraryRandom.RandDec(100, 2);
        PostInventoryAdjustment(Item."No.", Qty * 1.5);

        // [WHEN] Post a sales order of 2X psc
        CreatePostSalesOrderWithTwoLines(Item."No.", Qty);

        // [THEN] Positive surplus of "X" pcs. exists
        VerifySurplusQuantity(Item."No.", Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeSurplusCreatedForTrackedItem()
    var
        Item: Record Item;
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 362340] Negative surplus entry created when more than available quantity of a tracked item is sold
        // [GIVEN] Item "I" with "Tracking Only" tracking policy
        CreateItemWithTrackingPolicy(Item);

        // [GIVEN] 3X psc. of item "I" are available on inventory
        Qty := LibraryRandom.RandDec(100, 2);
        PostInventoryAdjustment(Item."No.", Qty * 1.5);

        // [WHEN] Post a sales order of 4X psc
        CreatePostSalesOrderWithTwoLines(Item."No.", Qty * 2);

        // [THEN] Negative surplus of "X" pcs. exists
        VerifySurplusQuantity(Item."No.", -Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupLineForReservedSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLines: TestPage "Sales Lines";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function "LookupLine" in codeunit "Reservation Management" opens correct sales line

        CreateSalesOrder(SalesHeader, SalesLine, '', '', 1, 1);

        SalesLines.Trap();
        ReservationManagement.LookupLine(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", '', 0, SalesLine."Line No.");
        SalesLines."No.".AssertEquals(SalesLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupLineForRequisitionLine()
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionLines: TestPage "Requisition Lines";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function "LookupLine" in codeunit "Reservation Management" opens correct requisition line
        RequisitionLine."Worksheet Template Name" := LibraryUtility.GenerateGUID();
        RequisitionLine."Journal Batch Name" := LibraryUtility.GenerateGUID();
        RequisitionLine.Type := RequisitionLine.Type::Item;
        RequisitionLine."No." := LibraryUtility.GenerateGUID();
        RequisitionLine.Insert();

        RequisitionLines.Trap();
        ReservationManagement.LookupLine(
          DATABASE::"Requisition Line", 0, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", 0, RequisitionLine."Line No.");

        RequisitionLines."No.".AssertEquals(RequisitionLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupLineForPurchaseLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLines: TestPage "Purchase Lines";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function "LookupLine" in codeunit "Reservation Management" opens correct purchase line

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 1);

        PurchaseLines.Trap();
        ReservationManagement.LookupLine(
          DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", '', 0, PurchaseLine."Line No.");
        PurchaseLines."No.".AssertEquals(PurchaseLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupLineForItemJournalLine()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLines: TestPage "Item Journal Lines";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function "LookupLine" in codeunit "Reservation Management" opens correct item journal line

        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", LibraryInventory.CreateItemNo(), 1);

        ItemJournalLines.Trap();
        ReservationManagement.LookupLine(
          DATABASE::"Item Journal Line", ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name",
          ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.");
        ItemJournalLines."Item No.".AssertEquals(ItemJournalLine."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupLineForItemLedgerEntry()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function "LookupLine" in codeunit "Reservation Management" opens correct item ledger entry
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Item No." := LibraryUtility.GenerateGUID();
        ItemLedgerEntry.Insert();

        ItemLedgerEntries.Trap();
        ReservationManagement.LookupLine(DATABASE::"Item Ledger Entry", 0, '', '', 0, ItemLedgerEntry."Entry No.");

        ItemLedgerEntries."Item No.".AssertEquals(ItemLedgerEntry."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupLineForProdOrderLine()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderLineList: TestPage "Prod. Order Line List";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function "LookupLine" in codeunit "Reservation Management" opens correct production order line
        ProdOrderLine.Status := ProdOrderLine.Status::Released;
        ProdOrderLine."Prod. Order No." := LibraryUtility.GenerateGUID();
        ProdOrderLine."Line No." := LibraryUtility.GetNewRecNo(ProdOrderLine, ProdOrderLine.FieldNo("Line No."));
        ProdOrderLine.Insert();

        ProdOrderLineList.Trap();
        ReservationManagement.LookupLine(DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0);

        ProdOrderLineList."Item No.".AssertEquals(ProdOrderLine."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupLineForProdOrderComponent()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderCompLineList: TestPage "Prod. Order Comp. Line List";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function "LookupLine" in codeunit "Reservation Management" opens correct production order component
        ProdOrderComponent.Status := ProdOrderComponent.Status::Released;
        ProdOrderComponent."Prod. Order No." := LibraryUtility.GenerateGUID();
        ProdOrderComponent."Prod. Order Line No." := 1;
        ProdOrderComponent."Line No." := LibraryUtility.GetNewRecNo(ProdOrderComponent, ProdOrderComponent.FieldNo("Line No."));
        ProdOrderComponent."Item No." := LibraryUtility.GenerateGUID();
        ProdOrderComponent.Insert();

        ProdOrderCompLineList.Trap();
        ReservationManagement.LookupLine(
          DATABASE::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.", '', ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.");

        ProdOrderCompLineList."Item No.".AssertEquals(ProdOrderComponent."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupLineForPlanningComponent()
    var
        PlanningComponent: Record "Planning Component";
        PlanningComponentList: TestPage "Planning Component List";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function "LookupLine" in codeunit "Reservation Management" opens correct planning component
        PlanningComponent."Worksheet Template Name" := LibraryUtility.GenerateGUID();
        PlanningComponent."Worksheet Batch Name" := LibraryUtility.GenerateGUID();
        PlanningComponent."Worksheet Line No." := LibraryUtility.GetNewRecNo(PlanningComponent, PlanningComponent.FieldNo("Worksheet Line No."));
        PlanningComponent.Description := LibraryUtility.GenerateGUID();
        PlanningComponent.Insert();

        PlanningComponentList.Trap();
        ReservationManagement.LookupLine(
          DATABASE::"Planning Component", 0, PlanningComponent."Worksheet Template Name", PlanningComponent."Worksheet Batch Name", PlanningComponent."Worksheet Line No.", PlanningComponent."Line No.");

        PlanningComponentList.Description.AssertEquals(PlanningComponent.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupLineForServiceLine()
    var
        ServiceLine: Record "Service Line";
        ServiceLineList: TestPage "Service Line List";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function "LookupLine" in codeunit "Reservation Management" opens correct service line
        ServiceLine."Document Type" := ServiceLine."Document Type"::Order;
        ServiceLine."Document No." := LibraryUtility.GenerateGUID();
        ServiceLine."Line No." := LibraryUtility.GetNewRecNo(ServiceLine, ServiceLine.FieldNo("Line No."));
        ServiceLine."No." := LibraryUtility.GenerateGUID();
        ServiceLine.Insert();

        ServiceLineList.Trap();
        ReservationManagement.LookupLine(DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", '', 0, ServiceLine."Line No.");

        ServiceLineList."No.".AssertEquals(ServiceLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupLineForJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function "LookupLine" in codeunit "Reservation Management" opens correct job planning line
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        if JobPlanningLine.FindLast() then
            JobPlanningLine."Job Contract Entry No." := JobPlanningLine."Job Contract Entry No." + 1
        else
            JobPlanningLine."Job Contract Entry No." := 1;

        JobPlanningLine."Line No." := LibraryUtility.GetNewRecNo(JobPlanningLine, JobPlanningLine.FieldNo("Line No."));
        JobPlanningLine."No." := LibraryUtility.GenerateGUID();
        JobPlanningLine.Insert();

        JobPlanningLines.Trap();
        ReservationManagement.LookupLine(DATABASE::"Job Planning Line", 0, '', '', 0, JobPlanningLine."Job Contract Entry No.");

        JobPlanningLines."No.".AssertEquals(JobPlanningLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupLineForAssemblyHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyOrders: TestPage "Assembly Orders";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function "LookupLine" in codeunit "Reservation Management" opens correct assembly header
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
        AssemblyHeader."No." := LibraryUtility.GenerateGUID();
        AssemblyHeader."No." := LibraryUtility.GenerateGUID();
        AssemblyHeader.Insert();

        AssemblyOrders.Trap();
        ReservationManagement.LookupLine(DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0);

        AssemblyOrders."No.".AssertEquals(AssemblyHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupLineForAssemblyLine()
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyLines: TestPage "Assembly Lines";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function "LookupLine" in codeunit "Reservation Management" opens correct assembly line
        AssemblyLine."Document Type" := AssemblyLine."Document Type"::Order;
        AssemblyLine."Document No." := LibraryUtility.GenerateGUID();
        AssemblyLine."Line No." := LibraryUtility.GetNewRecNo(AssemblyLine, AssemblyLine.FieldNo("Line No."));
        AssemblyLine."No." := LibraryUtility.GenerateGUID();
        AssemblyLine.Insert();

        AssemblyLines.Trap();
        ReservationManagement.LookupLine(DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", '', 0, AssemblyLine."Line No.");

        AssemblyLines."No.".AssertEquals(AssemblyLine."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmYesHandler,ItemTrackingListPageHandler,ReservationAvailHandler,AvailItemTrackingHandler')]
    [Scope('OnPrem')]
    procedure ReserveSpecificLotNoVerifyAvailTrackingLines()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Avail. - Item Tracking Lines]
        // [SCENARIO 155298] Specific lot no. can be reserved from "Avail. - Item Tracking Lines" page

        Initialize();

        // [GIVEN] Item "I" with lot tracking
        // [GIVEN] Create purchase order with item "I" and assign lot number "L"
        LibraryItemTracking.CreateLotItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(1);
        PurchaseLine.OpenItemTrackingLines();

        // [GIVEN] Create sales order with item "I" and assign the same lot number "L"
        CreateSalesOrder(SalesHeader, SalesLine, '', Item."No.", 1, 1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(1);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] From sales line, run "Reserve" action and choose to reserve specific lot no.
        // [WHEN] Run "Avail. - Item Tracking Lines" page
        // [THEN] Lot "L" is available to reserve
        LibraryVariableStorage.Enqueue(LotNo);
        SalesLine.ShowReservation();  // Lot No. is validated in AvailItemTrackingHandler
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,ReservationPageHandler,ConfirmYesHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSpecificSerialNoVerifyAvailTrackingLines()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        SN: array[2] of Code[20];
        I: Integer;
    begin
        // [FEATURE] [Item Tracking] [Avail. - Item Tracking Lines]
        // [SCENARIO 155298] Specific serial no. can be reserved from "Avail. - Item Tracking Lines" page when "SN Specific Tracking" is disabled

        Initialize();

        // [GIVEN] Item "I" with serial no. tracking. Track only purchase inbounds and sales outbounds, specific tracking is disabled
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("SN Purchase Inbound Tracking", true);
        ItemTrackingCode.Validate("SN Sales Outbound Tracking", true);
        ItemTrackingCode.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        // [GIVEN] Create purchase order with 2 pcs of item "I", assign 2 serial nos. "SN1" and "SN2"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 2);
        for I := 1 to 2 do
            SN[I] := LibraryUtility.GenerateGUID();
        OpenPurchaseItemTrackingLines(PurchaseLine, SN);

        // [GIVEN] Create sales order with 2 pcs of item "I", assign serial nos. "SN1" and "SN2"
        CreateSalesOrder(SalesHeader, SalesLine, '', Item."No.", 2, 2);
        OpenSalesItemTrackingLines(SalesLine, SN);

        // [WHEN] Run "Reserve" action and choose to reserve specific serial number "SN2"
        PurchaseLine.ShowReservation();

        // [THEN] Serial no. "SN2" is reserved
        ReservationEntry.SetRange("Serial No.", SN[2]);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        Assert.RecordIsNotEmpty(ReservationEntry);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingQtyToHandlePageHandler')]
    [Scope('OnPrem')]
    procedure QtyToHandleUpdatedInReservationEntryWithItemTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty: Decimal;
        LotNo: Code[10];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 377438] "Qty. to Handle" in reservation entry is updated when it is changed in "Item Tracking Lines" page, and tracked quantity is reserved

        // [GIVEN] Item "I" with lot tracking
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(TrackingAction::"Assign Lot No.");
        // [GIVEN] Post positive stock for item "I", quantity = "Q"
        Qty := CreatePurchaseForItemWithLotNo(Item."No.", LotNo);

        // [GIVEN] Create sales order for item "I", set quantity = "Q", assign lot no. and reserve
        CreateSalesOrder(SalesHeader, SalesLine, '', Item."No.", Qty, Qty);

        LibraryVariableStorage.Enqueue(TrackingAction::"Assign Lot No.");
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        SalesLine.OpenItemTrackingLines();
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Set "Qty. to Ship" in sales order = "Q" / 2
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandDec(Round(Qty / 2, 1), 2));
        SalesLine.Modify(true);

        // [WHEN] Open "Item Tracking Lines" page and set "Qty. to Handle" = "Q" / 2
        LibraryVariableStorage.Enqueue(TrackingAction::"Set Qty. to Handle");
        LibraryVariableStorage.Enqueue(SalesLine."Qty. to Ship");
        SalesLine.OpenItemTrackingLines();

        // [THEN] "Qty. to Handle" in reservation entry is "Q" / 2
        VerifyItemTrackingQtyToHandle(
          Item."No.", DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", -SalesLine."Qty. to Ship", 0);
    end;

    [Test]
    [HandlerFunctions('AutoReservePageHandler')]
    [Scope('OnPrem')]
    procedure TestPostShipSalesOrderReleasedWithLineReservation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        Item: Record Item;
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 205130] Posting of the Sales Order without errors when THE Sales Order has been released and after that the Sales Line was reserved.
        Initialize();

        // [GIVEN] Calc. Inv. Discount is TRUE at Sales & Receivables Setup
        UpdateCalcInvDiscountSetup(true);

        // [GIVEN] An item "ITEM" available to reserve and to ship.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', 1000, WorkDate(), 0);

        // [GIVEN] A Customer "CUST" with Invoice discounts for all items
        CustInvoiceDisc.Get(CreateCustomerInvDiscount(), '', 0);

        // [GIVEN] Sales Order "SO" created for "CUST" with an "ITEM" in the line.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustInvoiceDisc.Code, Item."No.");

        // [GIVEN] "SO" is released
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] "ITEM" is Auto Reserved by AutoReservePageHandler
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesLines.Reserve.Invoke();

        // [WHEN] "SO" Post invoked with "Shipped" selected
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] "SO" posted (shipped) without errors
        VerifySalesShptDocExists(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,CreateReturnRelatedDocumentsReportHandler')]
    [Scope('OnPrem')]
    procedure PurchRetOrdCreatedWithItemTrkgFromSalesRetOrdExactCostReversingMandatory()
    var
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        ItemNo: Code[20];
        LotNo: Code[10];
        CustomerNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Exact Cost Reversing Mandatory] [Item Tracking] [Purchase] [Return]
        // [SCENARIO 272483] The field "Appl.-to Item Entry" of "Reservation Entry" contains the "Entry No." of "Item Ledger Entry"
        // [SCENARIO] related with sales return for purchase return order when "Exact Cost Reversing Mandatory" is on in the "Purchases & Payables Setup"
        Initialize();

        // [GIVEN] "Exact Cost Reversing Mandatory" is on in the "Purchases & Payables Setup"
        LibraryPurchase.SetExactCostReversingMandatory(true);

        // [GIVEN] Item "I" is bought in some quantity "Q" with "Lot No." = "LN", sold and returned from customer
        ItemNo := CreateItem();
        Quantity := CreatePurchaseForItemWithLotNo(ItemNo, LotNo);
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreatePostSalesOrder(SalesHeader, CustomerNo, ItemNo, LotNo, Quantity, Quantity, true, true);
        CreatePostSalesReturn(SalesHeader, CustomerNo, Quantity, true, false);

        // [WHEN] Purchase return order is created through the report "Create Ret.-Related Documents"
        CreateReturnRelatedDocuments(LibraryPurchase.CreateVendorNo(), SalesHeader, true, false, false);

        // [THEN] The field "Appl.-to Item Entry" of "Reservation Entry" contains the "Entry No." of "Item Ledger Entry" related with sales return
        FindLastItemLedgerEntry(ItemLedgerEntry, ItemNo, ItemLedgerEntry."Document Type"::"Sales Return Receipt");
        FindReservationEntry(ReservationEntry, ItemNo);
        ReservationEntry.TestField("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoReserveSalesFromInboundTransferDoesNotDependOnTransferOrderStatus()
    var
        TransferHeader: Record "Transfer Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
        InTransitLocationCode: Code[10];
        ItemNo: Code[20];
        Qty: Integer;
    begin
        // [FEATURE] [Inbound] [Transfer] [Sales]
        // [SCENARIO 300018] Automatic Reservation in Sales Line from Transfer Line does not depend on Transfer Order status
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Item with Reserve = Always
        ItemNo := CreateItemWithReservationPolicyAlways();

        // [GIVEN] Released Transfer Order "T1" from BLUE to RED with Shipment Date = 28/1/2021 and 1 PCS of Item
        CreateTransferLocationCodes(FromLocationCode, ToLocationCode, InTransitLocationCode);
        CreateTransferOrderWithShipReceiveDates(
          TransferHeader, FromLocationCode, ToLocationCode, InTransitLocationCode, WorkDate(), ItemNo, Qty);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Opened Transfer Order "T2" from BLUE to RED with Shipment Date = 2/2/2021 and 1 PCS of Item
        CreateTransferOrderWithShipReceiveDates(
          TransferHeader, FromLocationCode, ToLocationCode, InTransitLocationCode, LibraryRandom.RandDate(10), ItemNo, Qty);

        // [GIVEN] Sales Order with Shipment Date = 15/2/2021 and Sales Line with 1 PCS of Item at Location RED
        CreateSalesOrderWithItemLocationAndShipmentDate(
          SalesHeader, SalesLine, ItemNo, Qty, ToLocationCode, LibraryRandom.RandDateFrom(TransferHeader."Shipment Date", 10));

        // [WHEN] Auto Reserve Sales Line
        SalesLine.AutoReserve();

        // [THEN] Transfer Line Reservation Entry for the Item has Source ID = "T2"
        VerifyReservationEntrySourceID(ItemNo, DATABASE::"Transfer Line", TransferHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoReservePurchFromOutboundTransferDoesNotDependOnTransferOrderStatus()
    var
        TransferHeader: Record "Transfer Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
        InTransitLocationCode: Code[10];
        ItemNo: Code[20];
        Qty: Integer;
    begin
        // [FEATURE] [Outbound] [Transfer] [Purchase]
        // [SCENARIO 300018] Automatic Reservation in Purchase Line from Transfer Line does not depend on Transfer Order status
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Item with Reserve = Always
        ItemNo := CreateItemWithReservationPolicyAlways();

        // [GIVEN] Opened Transfer Order "T1" from BLUE to RED with Receipt Date = 3/2/2021 and 1 PCS of Item
        CreateTransferLocationCodes(FromLocationCode, ToLocationCode, InTransitLocationCode);
        CreateTransferOrderWithShipReceiveDates(
          TransferHeader, FromLocationCode, ToLocationCode, InTransitLocationCode, LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20),
          ItemNo, Qty);

        // [GIVEN] Released Transfer Order "T2" from BLUE to RED with Receipt Date = 29/1/2021 and 1 PCS of Item
        CreateTransferOrderWithShipReceiveDates(
          TransferHeader, FromLocationCode, ToLocationCode, InTransitLocationCode, LibraryRandom.RandDate(9), ItemNo, Qty);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Purchase Order with Promised Receipt Date = 28/1/2021 and Purchase Line with 1 PCS of Item at Location BLUE
        CreatePurchaseOrderWithItemLocationAndReceiptDate(PurchaseHeader, PurchaseLine, ItemNo, Qty, FromLocationCode, WorkDate());

        // [WHEN] Auto Reserve Purchase Line
        AutoReservePurchaseLine(PurchaseLine);

        // [THEN] Transfer Line Reservation Entry for the Item has Source ID = "T2"
        VerifyReservationEntrySourceID(ItemNo, DATABASE::"Transfer Line", TransferHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InvtPickProdOrderWhenComponentsNotReserved()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        LocationCode: Code[10];
        ItemNo: Code[20];
        ComponentItemNo: array[3] of Code[20];
        Qty: array[3] of Integer;
        Index: Integer;
    begin
        // [SCENARIO 301469] Inventory Pick created from Production Order doesn't include non-stock components, when components are not reserved
        Initialize();
        for Index := 1 to ArrayLen(Qty) do
            Qty[Index] := 2 * LibraryRandom.RandInt(10);

        // [GIVEN] Items "I1", "I2" and "I3" with reservation policy Never and Manual Flushing Method
        CreateItemsWithFlushingMethodManualAndReservationPolicy(ComponentItemNo, 0);

        // [GIVEN] Item "I" with certified Production BOM having 3 Item Components: "I1" 2 PCS, "I2" 2 PCS and "I3" 2 PCS
        ItemNo := LibraryInventory.CreateItemNo();
        PrepareProductionBOMWithItemComponents(ItemNo, ComponentItemNo, Qty);

        // [GIVEN] Location had Require Pick = TRUE
        LocationCode := CreateLocation(false, false, true, false);

        // [GIVEN] Item "I1" had stock of 2 PCS and Item "I2" had stock of 1 PCS at Location
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ComponentItemNo[1], LocationCode, '', Qty[1]);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ComponentItemNo[2], LocationCode, '', Qty[2] / 2);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Purchase Order with 1 PCS of Item "I2" and 2 PCS of Item "I3" and Expected Receipt date = 1/1/2018, same Location
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchLineWithItemLocationAndExpectedReceiptDate(
          PurchaseHeader, ComponentItemNo[2], Qty[2] / 2, LocationCode, CalcDate('<-CM>', WorkDate()));
        CreatePurchLineWithItemLocationAndExpectedReceiptDate(
          PurchaseHeader, ComponentItemNo[3], Qty[3], LocationCode, CalcDate('<-CM>', WorkDate()));

        // [GIVEN] Released and refreshed Production Order with 2 PCS of Item "I" in same Location
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Create Inventory Pick from Released Production Order
        LibraryWarehouse.CreateInvtPutPickMovement(
            "Warehouse Activity Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // [THEN] Inventory Pick has 2 PCS of Item "I1" and 1 PCS of Item "I2"; no Warehouse Activity Lines for Item "I3"
        VerifyWarehouseActivityLine(ComponentItemNo[1], Qty[1]);
        VerifyWarehouseActivityLine(ComponentItemNo[2], Qty[2] / 2);
        VerifyWarehouseActivityLineNotPresent(ComponentItemNo[3]);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InvtPickProdOrderWhenComponentsReserved()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        LocationCode: Code[10];
        ItemNo: Code[20];
        ComponentItemNo: array[3] of Code[20];
        Qty: array[3] of Integer;
        Index: Integer;
    begin
        // [SCENARIO 301469] Inventory Pick created from Production Order doesn't include non-stock components, when components are reserved
        Initialize();
        for Index := 1 to ArrayLen(Qty) do
            Qty[Index] := 2 * LibraryRandom.RandInt(10);

        // [GIVEN] Items "I1", "I2" and "I3" with reservation policy Always and Manual Flushing Method
        CreateItemsWithFlushingMethodManualAndReservationPolicy(ComponentItemNo, 2);

        // [GIVEN] Item "I" with certified Production BOM having 3 Item Components: "I1" 2 PCS, "I2" 2 PCS and "I3" 2 PCS
        ItemNo := LibraryInventory.CreateItemNo();
        PrepareProductionBOMWithItemComponents(ItemNo, ComponentItemNo, Qty);

        // [GIVEN] Location had Require Pick = TRUE
        LocationCode := CreateLocation(false, false, true, false);

        // [GIVEN] Item "I1" had stock of 2 PCS and Item "I2" had stock of 1 PCS at Location
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ComponentItemNo[1], LocationCode, '', Qty[1]);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ComponentItemNo[2], LocationCode, '', Qty[2] / 2);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Purchase Order with 1 PCS of Item "I2" and 2 PCS of Item "I3" and Expected Receipt date = 1/1/2018, same Location
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchLineWithItemLocationAndExpectedReceiptDate(
          PurchaseHeader, ComponentItemNo[2], Qty[2] / 2, LocationCode, CalcDate('<-CM>', WorkDate()));
        CreatePurchLineWithItemLocationAndExpectedReceiptDate(
          PurchaseHeader, ComponentItemNo[3], Qty[3], LocationCode, CalcDate('<-CM>', WorkDate()));

        // [GIVEN] Released and refreshed Production Order with 2 PCS of Item "I" in same Location
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Create Inventory Pick from Released Production Order
        LibraryWarehouse.CreateInvtPutPickMovement(
            "Warehouse Activity Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // [THEN] Inventory Pick has 2 PCS of Item "I1" and 1 PCS of Item "I2"; no Warehouse Activity Lines for Item "I3"
        VerifyWarehouseActivityLine(ComponentItemNo[1], Qty[1]);
        VerifyWarehouseActivityLine(ComponentItemNo[2], Qty[2] / 2);
        VerifyWarehouseActivityLineNotPresent(ComponentItemNo[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateStatisticsForBlankEntrySummaryReturnsClearedRec()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        EntrySummary: Record "Entry Summary";
        ReservMgt: Codeunit "Reservation Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 314165] UpdateStatistics function run for blank entry summary returns does not initialize any fields.
        Initialize();

        ProdOrderComponent.Init();
        ProdOrderComponent.Insert();

        ReservMgt.SetReservSource(ProdOrderComponent);
        ReservMgt.UpdateStatistics(EntrySummary, WorkDate(), false);

        EntrySummary.TestField("Entry No.", 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingQtyToHandlePageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingLineQuantityExceedsILERemainingQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
        DocNo: Code[20];
        LotNo: Code[10];
        ItemEntryNo: Integer;
        Quantity: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Apply]
        // [SCENARIO 338145] Item Tracking Line can be applied to ILE with Remaining Quantity covering "Quantity (Base)" - "Qty. Handled (Base)"
        Initialize();

        // [GIVEN] Item "I" is bought with Quantity = 15 and "Lot No." = "LN"
        ItemNo := CreateItem();
        LibraryVariableStorage.Enqueue(TrackingAction::"Assign Lot No.");
        Quantity := CreatePurchaseForItemWithLotNo(ItemNo, LotNo);

        // [GIVEN] Item Ledger Entry "ILE01" created for the Item "I" purchase
        FindLastItemLedgerEntry(ItemLedgerEntry, ItemNo, ItemLedgerEntry."Document Type"::" ");
        ItemEntryNo := ItemLedgerEntry."Entry No.";

        // [GIVEN] Sales Order "SO01" for Item "I" and Quantity = 15, "Qty. to Ship" = 5
        CreateSalesOrder(SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), ItemNo, Quantity, Quantity / 3);

        // [GIVEN] Item Tracking Line for "SO01",10000: "Lot No." = "LN", "Quantity (Base)" = 5, "Quantity to Handle (Base)" = 5
        LibraryVariableStorage.Enqueue(TrackingAction::"Set QTH with AtE");
        EnqueueTrackingLineWithApplTo(
          LotNo, SalesLine."Qty. to Ship (Base)", SalesLine."Qty. to Ship (Base)", 0);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Sales Order "SO01" posted for shipment of 5 PCS of Item "I"
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesHeader.Find();
        SalesLine.Find();

        // [GIVEN] Item Tracking Line for "SO01",10000: "Lot No." = "LN", "Quantity (Base)" = 15, "Quantity to Handle (Base)" = 10
        // [WHEN] Set "Appl.-to Item Entry" to "ILE01" on Item Tracking Line
        LibraryVariableStorage.Enqueue(TrackingAction::"Set QTH with AtE");
        EnqueueTrackingLineWithApplTo(LotNo, SalesLine."Quantity (Base)", SalesLine."Qty. to Ship (Base)", ItemEntryNo);
        SalesLine.OpenItemTrackingLines();

        // [THEN] Item Tracking Line is applied succesfully
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        FindLastItemLedgerEntry(ItemLedgerEntry, ItemNo, ItemLedgerEntry."Document Type"::"Sales Shipment");
        ItemLedgerEntry.TestField("Lot No.", LotNo);
        ItemLedgerEntry.TestField("Applies-to Entry", ItemEntryNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ReservationAvailHandler,AvailableSalesLinesModalPageHandler')]
    procedure ReserveSalesLineFromPurchaseLineDoesNotAffectExistingReservation()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Sales]
        // [SCENARIO 414126] Reserving sales line from purchase line does not affect existing reservations for this sales line.
        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sales order for 8 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 8, '', WorkDate() + 10);

        // [GIVEN] Purchase order with two lines, each for 4 pcs.
        // [GIVEN] Reserve the second purchase line for the sales line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, PurchaseLine[1].Type::Item, Item."No.", 6);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::Item, Item."No.", 4);
        PurchaseLine[2].ShowReservation();

        // [WHEN] Reserve the first purchase line for the sales line.
        PurchaseLine[1].ShowReservation();

        // [THEN] Each of two purchase lines is reserved for 4 pcs.
        PurchaseLine[1].Find();
        PurchaseLine[1].CalcFields("Reserved Quantity");
        PurchaseLine[1].TestField("Reserved Quantity", 4);

        PurchaseLine[2].Find();
        PurchaseLine[2].CalcFields("Reserved Quantity");
        PurchaseLine[2].TestField("Reserved Quantity", 4);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmYesHandler,ReservationFromCurrentLine,ItemTrackingListPageHandler')]
    procedure VerifyTotalReservedQuantityInReservationPageForSalesOrderWhenLotIsConsumedFromRelProdOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNo: Code[50];
    begin
        // [SCENARIO 565347] Verify Total Reserved Quantity field in the Reservation Order page after you manually type in the Item Tracking of a Sales Line.
        Initialize();

        // [GIVEN] Generate Lot No.
        LotNo := LibraryRandom.RandText(50);

        // [GIVEN] Create Lot Item No.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Create production order.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item,
            Item."No.",
            LibraryRandom.RandIntInRange(200, 300));

        // [GIVEN] Create Production Order Line.
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', '', ProductionOrder.Quantity);

        // [GIVEN] Enqueue Lot No. and Quantity.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(ProdOrderLine.Quantity);

        // [GIVEN] Open Item Tracking Lines for Prod Order Line.
        ProdOrderLine.OpenItemTrackingLines();

        // [GIVEN] Create Sales Order with Lot item.
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandIntInRange(100, 150), '', WorkDate());

        // [GIVEN] Enqueue Lot No. and Quantity for Sales Line.
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);

        // [GIVEN] Open Item Tracking Lines for Sales Line.
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Enqueue Total Reserved Quantity and Total Available Quantity.
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        LibraryVariableStorage.Enqueue(ProdOrderLine.Quantity - SalesLine.Quantity);

        // [WHEN] Open Reservation page and Reserve from Current Line using ReservationFromCurrentLine Handler. 
        SalesLine.ShowReservation();

        // [THEN] Verify Total Reserved Quantity field in the Reservation Order page using ReservationFromCurrentLine Handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmYesHandler,ReservationFromCurrentLine,ItemTrackingListPageHandler')]
    procedure VerifyTotalReservedQuantityInReservationPageForSalesOrderWhenLotIsConsumedFromFirmPlannedProdOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNo: Code[50];
    begin
        // [SCENARIO 565347] Verify Total Reserved Quantity field in the Reservation Order page after you manually type in the Item Tracking of a Sales Line.
        Initialize();

        // [GIVEN] Generate Lot No.
        LotNo := LibraryRandom.RandText(50);

        // [GIVEN] Create Lot Item No.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Create production order.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::"Firm Planned",
            ProductionOrder."Source Type"::Item,
            Item."No.",
            LibraryRandom.RandIntInRange(200, 300));

        // [GIVEN] Create Production Order Line.
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', '', ProductionOrder.Quantity);

        // [GIVEN] Enqueue Lot No. and Quantity.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(ProdOrderLine.Quantity);

        // [GIVEN] Open Item Tracking Lines for Prod Order Line.
        ProdOrderLine.OpenItemTrackingLines();

        // [GIVEN] Create Sales Order with Lot item.
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandIntInRange(100, 150), '', WorkDate());

        // [GIVEN] Enqueue Lot No. and Quantity for Sales Line.
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);

        // [GIVEN] Open Item Tracking Lines for Sales Line.
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Enqueue Total Reserved Quantity and Total Available Quantity.
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        LibraryVariableStorage.Enqueue(ProdOrderLine.Quantity - SalesLine.Quantity);

        // [WHEN] Open Reservation page and Reserve from Current Line using ReservationFromCurrentLine Handler. 
        SalesLine.ShowReservation();

        // [THEN] Verify Total Reserved Quantity field in the Reservation Order page using ReservationFromCurrentLine Handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingTransferPageHandler,ConfirmYesHandler,AutoReservationFromCurrentLine,ItemTrackingListPageHandler')]
    procedure VerifyTotalReservedQuantityInReservationPageForSalesOrderWhenLotIsConsumedFromTransferOrder()
    var
        Item: Record Item;
        FromLocation, ToLocation, InTransitLocation : Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNo, LotNo1 : Code[50];
    begin
        // [SCENARIO 555111] Verify Total Reserved Quantity field in the Reservation Order page after you manually type in the Item Tracking of a Sales Line.
        Initialize();

        // [GIVEN] Create Lot Item No.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Create two Locations and 1 In-Transit Location
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);

        // [GIVEN] Create Positive Adjustment with two different Lot for Lot Item
        CreateAndPostInventoryAdjustmentWithLotNo(Item, FromLocation.Code, LotNo, 50);
        CreateAndPostInventoryAdjustmentWithLotNo(Item, FromLocation.Code, LotNo1, 50);

        // [GIVEN] Create Transfer Order
        LibraryInventory.CreateTransferOrder(TransferHeader, TransferLine, Item, FromLocation, ToLocation, InTransitLocation, '', 100, WorkDate(), WorkDate());

        // [GIVEN] Enqueue Lot No. and Quantity.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(50);
        LibraryVariableStorage.Enqueue(LotNo1);
        LibraryVariableStorage.Enqueue(50);

        // [GIVEN] Open Item Tracking Lines for Transfer Line.
        TransferLine.OpenItemTrackingLines(Enum::"Transfer Direction"::Outbound);

        // [GIVEN] Post Transfer Order with Shipment
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [GIVEN] Create Sales Order with Lot item.
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, ToLocation.Code, '', 30, WorkDate(), 0);

        // [GIVEN] Enqueue Lot No. and Quantity for Sales Line.
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);

        // [GIVEN] Open Item Tracking Lines for Sales Line.
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Enqueue Total Reserved Quantity and Total Available Quantity.
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(30);
        LibraryVariableStorage.Enqueue(20);

        // [WHEN] Open Reservation page and Reserve from Current Line using ReservationFromCurrentLine Handler. 
        SalesLine.ShowReservation();

        // [THEN] Verify Total Reserved Quantity field in the Reservation Order page using ReservationFromCurrentLine Handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingTransferPageHandler,ConfirmYesHandler,AutoReservationFromCurrentLine,ItemTrackingListPageHandler')]
    procedure VerifyTotalReservedQuantityInReservationPageForSecondSalesLineWhenLotIsConsumedFromTransferOrder()
    var
        Item: Record Item;
        FromLocation, ToLocation, InTransitLocation : Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        SalesHeader: Record "Sales Header";
        SalesLine, SalesLine1 : Record "Sales Line";
        LotNo, LotNo1 : Code[50];
    begin
        // [SCENARIO 555111] Verify Total Reserved Quantity field in the Reservation Order page after you manually type in the Item Tracking of a Sales Line.
        Initialize();

        // [GIVEN] Create Lot Item No.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Create two Locations and 1 In-Transit Location
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);

        // [GIVEN] Create Positive Adjustment with two different Lot for Lot Item
        CreateAndPostInventoryAdjustmentWithLotNo(Item, FromLocation.Code, LotNo, 50);
        CreateAndPostInventoryAdjustmentWithLotNo(Item, FromLocation.Code, LotNo1, 50);

        // [GIVEN] Create Transfer Order
        LibraryInventory.CreateTransferOrder(TransferHeader, TransferLine, Item, FromLocation, ToLocation, InTransitLocation, '', 100, WorkDate(), WorkDate());

        // [GIVEN] Enqueue Lot No. and Quantity.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(50);
        LibraryVariableStorage.Enqueue(LotNo1);
        LibraryVariableStorage.Enqueue(50);

        // [GIVEN] Open Item Tracking Lines for Transfer Line.
        TransferLine.OpenItemTrackingLines(Enum::"Transfer Direction"::Outbound);

        // [GIVEN] Post Transfer Order with Shipment
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [GIVEN] Create Sales Order with Lot item.
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, ToLocation.Code, '', 30, WorkDate(), 0);

        // [GIVEN] Enqueue Lot No. and Quantity for Sales Line.
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);

        // [GIVEN] Open Item Tracking Lines for Sales Line.
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Enqueue Total Reserved Quantity and Total Available Quantity.
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(30);
        LibraryVariableStorage.Enqueue(20);

        // [WHEN] Open Reservation page and Reserve from Current Line using ReservationFromCurrentLine Handler. 
        SalesLine.ShowReservation();

        // [GIVEN] Create new Sales Line with Same Item and second Lot No.
        LibrarySales.CreateSalesLine(SalesLine1, SalesHeader, SalesLine1.Type::Item, Item."No.", 50);
        SalesLine1.Validate("Location Code", ToLocation.Code);
        SalesLine1.Modify();

        // [GIVEN] Enqueue Lot No. and Quantity for Sales Line.
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(LotNo1);
        LibraryVariableStorage.Enqueue(SalesLine1.Quantity);

        // [GIVEN] Open Item Tracking Lines for Sales Line.
        SalesLine1.OpenItemTrackingLines();

        // [GIVEN] Enqueue Total Reserved Quantity and Total Available Quantity.
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(50);
        LibraryVariableStorage.Enqueue(0);

        // [WHEN] Open Reservation page and Reserve from Current Line using ReservationFromCurrentLine Handler. 
        SalesLine1.ShowReservation();

        // [THEN] Verify Total Reserved Quantity field in the Reservation Order page using ReservationFromCurrentLine Handler.
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Reservation V");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Reservation V");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Reservation V");
    end;

    local procedure CreatePurchLineWithItemLocationAndExpectedReceiptDate(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; ExpectedReceiptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerInvDiscount(): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CreateCustomer(), '', 0);  // Set Zero for Charge Amount.
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDecInRange(10, 20, 2));  // Take Random Discount.
        CustInvoiceDisc.Modify(true);
        exit(CustInvoiceDisc.Code);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(20, 2),
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostWhseReceiptForSalesReturnOrder(SalesHeader: Record "Sales Header"; LocationCode: Code[10])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        FindWhseRcptHdr(WarehouseReceiptHeader, LocationCode);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreateAndPostWhseReceipt(SalesLine: Record "Sales Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Release Purchase document, create and post Warehouse Receipt.
        FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order, SalesLine."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWhseRcptHdr(WarehouseReceiptHeader, SalesLine."Location Code");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreateAndPostWhseShipmentWithPick(No: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Release Sales document, create and post Warehouse Shipment.
        ReleaseSalesOrderWithReserve(SalesHeader, No);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWhseShptHdr(WarehouseShipmentHeader, LocationCode);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(WarehouseActivityHeader.Type::Pick, WarehouseShipmentHeader."Location Code");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 1));  // Using Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemsWithFlushingMethodManualAndReservationPolicy(var ItemNo: array[3] of Code[20]; ReservationPolicy: Integer)
    var
        Item: Record Item;
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(ItemNo) do begin
            ;
            LibraryInventory.CreateItem(Item);
            Item.Validate("Flushing Method", Item."Flushing Method"::"Pick + Manual");
            Item.Validate(Reserve, ReservationPolicy);
            Item.Modify(true);
            ItemNo[Index] := Item."No.";
        end;
    end;

    local procedure CreateItemWithReservationPolicyAlways(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithTrackingPolicy(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Order Tracking Policy" := Item."Order Tracking Policy"::"Tracking Only";
        Item.Modify(true);
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

    local procedure CreateLocation(RequireShipment: Boolean; RequireReceipt: Boolean; RequirePick: Boolean; RequirePutAway: Boolean): Code[10]
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        Location.Validate("Require Shipment", RequireShipment);
        Location.Validate("Require Receive", RequireReceipt);
        Location.Validate("Require Put-away", RequirePutAway);
        Location.Validate("Require Pick", RequirePick);
        if Location."Require Pick" then
            if Location."Require Shipment" then
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)"
            else
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";

        if Location."Require Put-away" then
            Location."Prod. Output Whse. Handling" := Location."Prod. Output Whse. Handling"::"Inventory Put-away";

        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateTransferOrderWithShipReceiveDates(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitLocationCode: Code[10]; ShipmentDate: Date; ItemNo: Code[20]; Qty: Integer)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocationCode);
        TransferHeader.Validate("Shipment Date", ShipmentDate);
        TransferHeader.Validate("Receipt Date", CalcDate('<1D>', ShipmentDate));
        TransferHeader.Modify(true);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
    end;

    local procedure CreateSalesRetOrderWithRetRelatedDocuments(CustomerNo: Code[20]; var SalesLine: Record "Sales Line"; CreatePurchRetOrder: Boolean; CreatePurchaseOrder: Boolean; CreateSalesOrder: Boolean)
    var
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Random value for Quantity.
        SalesLine.Validate("Location Code", CreateLocation(true, true, true, true));
        SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity);
        SalesLine.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        CreateReturnRelatedDocuments(Vendor."No.", SalesHeader, CreatePurchRetOrder, CreatePurchaseOrder, CreateSalesOrder);

        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateWarehouseShipmentWithPick(PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
        FindWhseShptHdr(WarehouseShipmentHeader, LocationCode);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePurchaseForItemWithLotNo(ItemNo: Code[20]; var LotNo: Code[10]) Quantity: Decimal
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        Item.Get(ItemNo);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify();
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();
        Quantity := 3 * LibraryRandom.RandIntInRange(10, 100);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Purchase, ItemNo, Quantity);
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(ItemJournalLine."Quantity (Base)");
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreatePurchaseOrderWithItemLocationAndReceiptDate(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Qty: Integer; LocationCode: Code[10]; ReceiptDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Promised Receipt Date", ReceiptDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePostSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; LotNo: Code[10]; Quantity: Decimal; QtyToShip: Decimal; Ship: Boolean; Invoice: Boolean): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, CustomerNo, ItemNo, Quantity, QtyToShip);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SalesLine."Quantity (Base)");
        SalesLine.OpenItemTrackingLines();
        exit(LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice));
    end;

    local procedure CreatePostSalesOrderWithTwoLines(ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateSalesOrderWithItemLocationAndShipmentDate(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Qty: Integer; LocationCode: Code[10]; ShipmentDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; QtyToShip: Decimal)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        InventorySetup.Get();
        SalesHeader.Validate("Shipment Date", CalcDate(InventorySetup."Default Safety Lead Time", SalesHeader."Shipment Date"));
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesReturn(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; QtyToReceive: Decimal)
    var
        SalesLine: Record "Sales Line";
        FromSalesShptLine: Record "Sales Shipment Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);

        FromSalesShptLine.SetRange("Sell-to Customer No.", CustomerNo);
        CopyDocMgt.SetProperties(false, false, false, false, true, true, true);
        CopyDocMgt.CopySalesShptLinesToDoc(SalesHeader, FromSalesShptLine, LinesNotCopied, MissingExCostRevLink);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
        SalesLine.Validate("Return Qty. to Receive", QtyToReceive);
        SalesLine.Modify();
    end;

    local procedure CreatePostSalesReturn(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; QtyToReceive: Decimal; Receive: Boolean; Invoice: Boolean)
    begin
        CreateSalesReturn(SalesHeader, CustomerNo, QtyToReceive);
        LibrarySales.PostSalesDocument(SalesHeader, Receive, Invoice);
    end;

    local procedure CreateReturnRelatedDocuments(VendorNo: Code[20]; SalesHeader: Record "Sales Header"; CreatePurchRetOrder: Boolean; CreatePurchaseOrder: Boolean; CreateSalesOrder: Boolean)
    begin
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(CreatePurchRetOrder);
        LibraryVariableStorage.Enqueue(CreatePurchaseOrder);
        LibraryVariableStorage.Enqueue(CreateSalesOrder);

        RunCreateReturnRelatedDocumentsReport(SalesHeader);
    end;

    local procedure PrepareProductionBOMWithItemComponents(ItemNo: Code[20]; ComponentItemNo: array[3] of Code[20]; Qty: array[3] of Integer)
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Index: Integer;
    begin
        Item.Get(ItemNo);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        for Index := 1 to ArrayLen(ComponentItemNo) do
            LibraryManufacturing.CreateProductionBOMLine(
              ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItemNo[Index], Qty[Index]);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateAndPostInventoryAdjustmentWithLotNo(Item: Record Item; LocationCode: Code[10]; var LotNo: Code[50]; Quantity: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
    begin
        if LotNo = '' then
            LotNo := NoSeries.GetNextNo(Item."Lot Nos.", WorkDate(), true);

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", Quantity, LocationCode);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', LotNo, Quantity);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);
    end;

    local procedure AutoReservePurchaseLine(PurchaseLine: Record "Purchase Line")
    var
        ReservationManagement: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        ReservationManagement.SetReservSource(PurchaseLine);
        ReservationManagement.AutoReserve(
            FullAutoReservation, PurchaseLine.Description, PurchaseLine."Promised Receipt Date",
            PurchaseLine.Quantity, PurchaseLine."Quantity (Base)");
    end;

    local procedure EnqueueTrackingNumbers(SN: array[2] of Code[20])
    var
        I: Integer;
    begin
        LibraryVariableStorage.Enqueue(ArrayLen(SN));
        for I := 1 to 2 do
            LibraryVariableStorage.Enqueue(SN[I]);
    end;

    local procedure EnqueueTrackingLineWithApplTo(LotNo: Code[10]; Quantity: Decimal; QtyToHandle: Decimal; ApplToItemEntry: Integer)
    begin
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(QtyToHandle);
        LibraryVariableStorage.Enqueue(ApplToItemEntry);
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) then;
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure FindWhseShptHdr(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
    end;

    local procedure FindWhseRcptHdr(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    begin
        WarehouseReceiptHeader.SetRange("Location Code", LocationCode);
        WarehouseReceiptHeader.FindFirst();
    end;

    local procedure FindLastItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; DocumentType: Enum "Item Ledger Document Type")
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        ItemLedgerEntry.FindLast();
    end;

    local procedure FindReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20])
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
    end;

    local procedure OpenPurchaseItemTrackingLines(PurchaseLine: Record "Purchase Line"; TrackingNo: array[2] of Code[20])
    begin
        EnqueueTrackingNumbers(TrackingNo);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure OpenSalesItemTrackingLines(SalesLine: Record "Sales Line"; TrackingNo: array[2] of Code[20])
    begin
        EnqueueTrackingNumbers(TrackingNo);
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure PostInventoryAdjustment(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJnlLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJnlLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJnlTemplate.Name, ItemJnlBatch.Name);
    end;

    local procedure PostSalesDocument(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        ExecuteUIHandler();
        SalesHeader.Get(DocumentType, DocumentNo);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure RegisterWarehouseActivity(Type: Enum "Warehouse Activity Type"; LocationCode: Code[10])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange(Type, Type);
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure ReleasePurchaseReturnOrderWithReserve(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; No: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, DocumentType, No);
        PurchaseLine.ShowReservation();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure ReleaseSalesOrderWithReserve(var SalesHeader: Record "Sales Header"; No: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
        SalesLine.ShowReservation();
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure RunCreateReturnRelatedDocumentsReport(SalesHeader: Record "Sales Header")
    var
        CreateRetRelatedDocuments: Report "Create Ret.-Related Documents";
    begin
        Commit();  // Commit required before running this Report.
        Clear(CreateRetRelatedDocuments);
        CreateRetRelatedDocuments.SetSalesHeader(SalesHeader);
        CreateRetRelatedDocuments.UseRequestPage(true);
        CreateRetRelatedDocuments.Run();
    end;

    local procedure UpdateCalcInvDiscountSetup(NewCalcInvDiscount: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", NewCalcInvDiscount);
        SalesReceivablesSetup.Modify();
    end;

    local procedure VerifyWarehouseActivityLine(ItemNo: Code[20]; Qty: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, Qty);
    end;

    local procedure VerifyWarehouseActivityLineNotPresent(ItemNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        Assert.RecordIsEmpty(WarehouseActivityLine);
    end;

    local procedure VerifyReservationEntrySourceID(ItemNo: Code[20]; SourceType: Integer; SourceID: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Source ID", SourceID);
    end;

    local procedure VerifyPurchaseReceiptLine(No: Code[20]; Quantity: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("No.", No);
        PurchRcptLine.FindFirst();
        PurchRcptLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReturnReceiptLine(No: Code[20]; Quantity: Decimal)
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptLine.SetRange("No.", No);
        ReturnReceiptLine.FindFirst();
        ReturnReceiptLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifySalesShipmentLine(No: Code[20]; Quantity: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("No.", No);
        SalesShipmentLine.FindFirst();
        SalesShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPurchaseLineExists(No: Code[20]; ExpectedQty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
        Assert.AreEqual(ExpectedQty, PurchaseLine.Quantity, StrSubstNo(WrongQuantityErr, No));
    end;

    local procedure VerifyExistenceOfItemTracking(ItemNo: Code[20]; LotNo: Code[10]; ExpectedExistence: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
        ReservationEntry.SetRange("Source Subtype", ReservationEntry."Source Subtype"::"5");
        // Purchase Return Order
        Assert.AreNotEqual(ExpectedExistence, ReservationEntry.IsEmpty, ReservEntryExistenceErr);
    end;

    local procedure VerifyItemTrackingQty(ItemNo: Code[20]; LotNo: Code[10]; ExpectedQty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        TotalQty: Decimal;
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
        ReservationEntry.SetRange("Source Subtype", ReservationEntry."Source Subtype"::"5");
        // Purchase Return Order
        ReservationEntry.FindSet();
        repeat
            TotalQty -= ReservationEntry.Quantity;
        until ReservationEntry.Next() = 0;
        Assert.AreEqual(ExpectedQty, TotalQty, ReservEntryQtyErr);
    end;

    local procedure VerifyItemTrackingQtyToHandle(ItemNo: Code[20]; SourceType: Option; DocumentType: Option; DocumentNo: Code[20]; ExpectedQty: Decimal; ApplToItemEntry: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source Subtype", DocumentType);
        ReservationEntry.SetRange("Source ID", DocumentNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Qty. to Handle (Base)", ExpectedQty);
        ReservationEntry.TestField("Appl.-to Item Entry", ApplToItemEntry);
    end;

    local procedure VerifySurplusQuantity(ItemNo: Code[20]; ExpectedQty: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetRange("Item No.", ItemNo);
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Surplus);
        ReservEntry.CalcSums(Quantity);
        Assert.AreEqual(ExpectedQty, ReservEntry.Quantity, ReservEntryQtyErr);
    end;

    local procedure VerifySalesShptDocExists(OrderNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        Assert.RecordIsNotEmpty(SalesShipmentHeader);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateReturnRelatedDocumentsReportHandler(var CreateRetRelatedDocuments: TestRequestPage "Create Ret.-Related Documents")
    var
        CreatePurchRetOrder: Variant;
        CreatePurchaseOrder: Variant;
        CreateSalesOrder: Variant;
        VendorNo: Variant;
    begin
        // Dequeue variable.
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(CreatePurchRetOrder);
        LibraryVariableStorage.Dequeue(CreatePurchaseOrder);
        LibraryVariableStorage.Dequeue(CreateSalesOrder);

        CreateRetRelatedDocuments.VendorNo.SetValue(VendorNo);
        CreateRetRelatedDocuments.CreatePurchRetOrder.SetValue(CreatePurchRetOrder);
        CreateRetRelatedDocuments.CreatePurchaseOrder.SetValue(CreatePurchaseOrder);
        CreateRetRelatedDocuments.CreateSalesOrder.SetValue(CreateSalesOrder);
        CreateRetRelatedDocuments.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationAvailHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.AvailableToReserve.Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingLines."Lot No.".SetValue(DequeueVariable);

        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingLines."Quantity (Base)".SetValue(DequeueVariable);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingTransferPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingLines."Lot No.".SetValue(DequeueVariable);

        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingLines."Quantity (Base)".SetValue(DequeueVariable);

        if ItemTrackingLines.CurrentSourceCaption.Value = 'Transfer Line' then begin
            ItemTrackingLines.Next();
            LibraryVariableStorage.Dequeue(DequeueVariable);
            ItemTrackingLines."Lot No.".SetValue(DequeueVariable);

            LibraryVariableStorage.Dequeue(DequeueVariable);
            ItemTrackingLines."Quantity (Base)".SetValue(DequeueVariable);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSerialNoPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        I: Integer;
    begin
        for I := 1 to LibraryVariableStorage.DequeueInteger() do begin
            ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."Quantity (Base)".SetValue(1);
            ItemTrackingLines.Next();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingListPageHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList.Last();
        ItemTrackingList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailItemTrackingHandler(var AvailItemTrackingLines: TestPage "Avail. - Item Tracking Lines")
    begin
        AvailItemTrackingLines."Lot No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingQtyToHandlePageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            TrackingAction::"Assign Lot No.":
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            TrackingAction::"Set Qty. to Handle":
                ItemTrackingLines."Qty. to Handle (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
            TrackingAction::"Set QTH with AtE":
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines."Appl.-to Item Entry".SetValue(LibraryVariableStorage.DequeueInteger());
                end;
        end;

        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AutoReservePageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
    end;

    [ModalPageHandler]
    procedure AvailableSalesLinesModalPageHandler(var AvailableSalesLines: TestPage "Available - Sales Lines")
    begin
        AvailableSalesLines.Reserve.Invoke();
    end;

    [ModalPageHandler]
    procedure ReservationFromCurrentLine(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.TotalReservedQuantity.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Reservation.TotalAvailableQuantity.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AutoReservationFromCurrentLine(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
        Reservation.TotalReservedQuantity.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Reservation.TotalAvailableQuantity.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Reservation.OK().Invoke();
    end;
}

