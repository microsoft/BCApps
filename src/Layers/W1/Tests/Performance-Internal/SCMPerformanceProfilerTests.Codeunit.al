codeunit 139070 "SCM Performance Profiler Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Performance Profiler]
        TestsBuffer := 10;
        TestsBufferPercentage := 5;
        LibraryPerformanceProfiler.SetProfilerIdentification('139070 - SCM Performance Profiler Tests')
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryPerformanceProfiler: Codeunit "Library - Performance Profiler";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ItemTrackingHandlerAction: Option AssignSN;
        TraceDumpFilePath: Text;
        isInitialized: Boolean;
        TestsBuffer: Integer;
        TestsBufferPercentage: Integer;

    [Test]
    [HandlerFunctions('StringMenuHandler,ShipLinesMessageHandler')]
    [Scope('OnPrem')]
    procedure TestProcessedPurchRetOrderWarehouse()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        Vendor: Record Vendor;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        // Setup: Create setups, Item and Vendor with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error",
          WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateVendor(Vendor, Location.Code);

        // Create Purchase Return Order setup. Create Warehouse Shipment using Filters to get Source document.
        CreatePurchaseSetup(
          PurchaseHeader, PurchaseHeader2, PurchaseHeader."Document Type"::"Return Order", Item."No.", Location.Code, Vendor."No.");
        UseFiltersToGetSrcDocShipment(WarehouseShipmentHeader, '', Vendor."No.", Location.Code, '');

        // Exercise: Post Warehouse Shipment such that it generates the posting confirmation message.
        LibraryPerformanceProfiler.StartProfiler(true);
        LibraryWarehouse.PostWhseShptWithShipInvoiceMsg(WarehouseShipmentHeader."No.");
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestProcessedPurchRetOrderWarehouse',
            PerfProfilerEventsTest."Object Type"::Codeunit, Codeunit::"Whse.-Post Shipment (Yes/No)", true);

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SourceDocMessageHandler')]
    [Scope('OnPrem')]
    procedure TestProcessedSalesRetOrderWarehouse()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Customer: Record Customer;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        // Setup: Create setups, Item and Customer with Dimensions.
        Initialize();
        WarehouseSetup.Get();
        UpdateWarehouseSetup(
          WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed",
          WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        CreateItem(Item);
        CreateLocationSetup(Location, false, true, true);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateCustomer(Customer, Location.Code);

        // Create Sales Return Order setup. Create Warehouse Receipt using Filters to get Source document.
        CreateSalesSetup(
          SalesHeader, SalesHeader2, SalesHeader."Document Type"::"Return Order", Item."No.", Location.Code, Customer."No.");
        UseFiltersToGetSrcDocReceipt(WarehouseReceiptHeader, Customer."No.", '', Location.Code);

        // Exercise: Post Warehouse Receipt such that it generates the posting confirmation message.
        LibraryPerformanceProfiler.StartProfiler(true);
        LibraryWarehouse.PostWhseRcptWithConfirmMsg(WarehouseReceiptHeader."No.");
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestProcessedSalesRetOrderWarehouse',
            PerfProfilerEventsTest."Object Type"::Codeunit, Codeunit::"Whse.-Post Receipt (Yes/No)", true);

        // Teardown.
        UpdateWarehouseSetup(WarehouseSetup."Shipment Posting Policy", WarehouseSetup."Receipt Posting Policy");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler')]
    [Scope('OnPrem')]
    procedure AutoAssignSerialNoOnItemTrackingPage()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        ExistingReservedQty: Integer;
        Quantity: Integer;
    begin
        // Setup: Create Item with SN specific tracking
        Initialize();
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] There are 10000 Reservation entries in the system for the item. Performance of assigning SN is dependent on the existing entries in Reservation entries for an item.
        ExistingReservedQty := 10000;
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', ExistingReservedQty);
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignSN); //AssignSerialNoEnterQtyPageHandler required.
        ItemJournalLine.OpenItemTrackingLines(false); //ItemTrackingLinesPageHandler required.

        // Create item journal line with that item and quantity = 1000
        Quantity := 1000;
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Quantity);

        // Exercise: Open item tracking page and auto assign serial numbers.
        LibraryPerformanceProfiler.StartProfiler(true);
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignSN); //AssignSerialNoEnterQtyPageHandler required.
        ItemJournalLine.OpenItemTrackingLines(false); //ItemTrackingLinesPageHandler required.
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(PerfProfilerEventsTest, 'AutoAssignSerialNoOnItemTrackingPage', PerfProfilerEventsTest."Object Type"::Page, Page::"Item Tracking Lines", true);
    end;

    [Test]
    procedure CreatePickAtWMSLocationWithReservation()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemTrackingSetup: Record "Item Tracking Setup";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        CreatePick: Codeunit "Create Pick";
        LotNo: Code[50];
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO 454811] Optimize CalcReservedQtyOnInventory function in Create Pick codeunit - replace loops with queries.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with bins and required shipment and pick.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 5, false);

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);

        // [GIVEN] Post 100 item journal lines for each of two bins "B1" and "B2", quantity = 1.
        // [GIVEN] That will create 100 warehouse entries.
        //avd
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        for i := 1 to 2 do begin
            LibraryWarehouse.FindBin(Bin, Location.Code, '', i);
            for j := 1 to 100 do begin
                LibraryInventory.CreateItemJournalLine(
                  ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
                  ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
                ItemJournalLine.Validate("Location Code", Location.Code);
                ItemJournalLine.Validate("Bin Code", Bin.Code);
                ItemJournalLine.Modify(true);
                LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);
            end;
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order with 200 lines, quantity = 1.
        // [GIVEN] Reserve every line from the inventory.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);
        for i := 1 to 200 do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
            LibrarySales.AutoReserveSalesLine(SalesLine);
        end;

        // [WHEN] Enable the performance profiler and calculate reserved quantity on inventory.
        LibraryPerformanceProfiler.StartProfiler(true);
        ItemTrackingSetup."Lot No. Required" := true;
        ItemTrackingSetup."Lot No." := LotNo;
        CreatePick.CalcReservedQtyOnInventory(Item."No.", Location.Code, '', ItemTrackingSetup);
        TraceDumpFilePath :=
          LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'CreatePickAtWMSLocationWithReservation', PerfProfilerEventsTest."Object Type"::Codeunit,
            Codeunit::"Create Pick", true);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        ItemJournalSetup();
        isInitialized := true;
        Commit();
    end;

    local procedure NoSeriesSetup()
    var
        InventorySetup: Record "Inventory Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        Clear(ItemJournalTemplate);
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        Clear(ItemJournalBatch);
        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure UpdateWarehouseSetup(ShipmentPostingPolicy: Option; ReceiptPostingPolicy: Option)
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Shipment Posting Policy", ShipmentPostingPolicy);
        WarehouseSetup.Validate("Receipt Posting Policy", ReceiptPostingPolicy);
        WarehouseSetup.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        //CreateDefaultDimensionForItem(Item."No.");
    end;

    local procedure CreateLocationSetup(var Location: Record Location; UseAsInTransit: Boolean; RequireShipment: Boolean; RequireReceive: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        CreateLocation(Location, UseAsInTransit, RequireShipment, RequireReceive);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateLocation(var Location: Record Location; UseAsInTransit: Boolean; RequireShipment: Boolean; RequireReceive: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Use As In-Transit", UseAsInTransit);
        Location.Validate("Require Shipment", RequireShipment);
        Location.Validate("Require Receive", RequireReceive);
        Location.Modify(true);
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; LocationCode: Code[10])
    begin
        UpdateItemInventoryFixedQty(ItemNo, LocationCode, LibraryRandom.RandDec(10, 2) + 1000);
    end;

    local procedure UpdateItemInventoryFixedQty(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, LocationCode, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateCustomer(var Customer: Record Customer; LocationCode: Code[10])
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        //CreateDefaultDimensionCustomer(Customer."No.");
        Customer.Validate("Location Code", LocationCode);
        Customer.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; LocationCode: Code[10])
    var
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        //CreateDefaultDimensionVendor(Vendor."No.");
        Vendor.Validate("Location Code", LocationCode);
        Vendor.Modify(true);
    end;

    local procedure CreateSalesSetup(var SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; CustomerNo: Code[20])
    begin
        // Create and Release Sales Document with and without Dimensions.
        CreateAndReleaseSalesDocument(SalesHeader, DocumentType, ItemNo, LocationCode, CustomerNo, true);
        CreateAndReleaseSalesDocument(SalesHeader2, DocumentType, ItemNo, LocationCode, CustomerNo, false);
    end;

    local procedure CreateAndReleaseSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; CustomerNo: Code[20]; DimensionSetEntryRequired: Boolean)
    begin
        CreateSalesDocument(SalesHeader, DocumentType, ItemNo, LocationCode, CustomerNo, DimensionSetEntryRequired);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; CustomerNo: Code[20]; DimensionSetEntryRequired: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        UpdateSalesHeader(SalesHeader, DimensionSetEntryRequired);
        CreateSalesLine(SalesHeader, ItemNo, LocationCode);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesHeader(var SalesHeader: Record "Sales Header"; DimensionSetEntryRequired: Boolean)
    begin
        if not DimensionSetEntryRequired then begin
            SalesHeader.Validate("Dimension Set ID", 0);
            SalesHeader.Modify(true);
        end;
    end;

    local procedure CreatePurchaseSetup(var PurchaseHeader: Record "Purchase Header"; var PurchaseHeader2: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; VendorNo: Code[20])
    begin
        // Create and Release Purchase Document with and without Dimensions.
        CreateAndReleasePurchDocument(PurchaseHeader, DocumentType, ItemNo, LocationCode, VendorNo, true);
        CreateAndReleasePurchDocument(PurchaseHeader2, DocumentType, ItemNo, LocationCode, VendorNo, false);
    end;

    local procedure CreateAndReleasePurchDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; VendorNo: Code[20]; DimensionSetEntryRequired: Boolean)
    begin
        CreatePurchaseDocument(PurchaseHeader, DocumentType, ItemNo, LocationCode, VendorNo, DimensionSetEntryRequired);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; VendorNo: Code[20]; DimensionSetEntryRequired: Boolean)
    begin
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        UpdatePurchaseHeader(PurchaseHeader, DimensionSetEntryRequired);
        CreatePurchaseLine(PurchaseHeader, ItemNo, LocationCode);
    end;

    local procedure UpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DimensionSetEntryRequired: Boolean)
    begin
        if not DimensionSetEntryRequired then begin
            PurchaseHeader.Validate("Dimension Set ID", 0);
            PurchaseHeader.Modify(true);
        end;
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure UseFiltersToGetSrcDocShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SellToCustomerNo: Code[20]; BuyFromVendorNo: Code[20]; TransferFrom: Code[10]; TransferTo: Code[10])
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        CreateWarehouseShipmentHeader(WarehouseShipmentHeader, TransferFrom);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Outbound);
        UpdateSourceFilterSales(WarehouseSourceFilter, SellToCustomerNo);
        UpdateSourceFilterPurchase(WarehouseSourceFilter, BuyFromVendorNo);
        UpdateSourceFilterTransfer(WarehouseSourceFilter, TransferFrom, TransferTo);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, TransferFrom);
    end;

    local procedure CreateWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", LocationCode);
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure UpdateSourceFilterSales(var WarehouseSourceFilter: Record "Warehouse Source Filter"; SellToCustomerNoFilter: Code[20])
    begin
        WarehouseSourceFilter.Validate("Sell-to Customer No. Filter", SellToCustomerNoFilter);
        WarehouseSourceFilter.Modify(true);
    end;

    local procedure UpdateSourceFilterPurchase(var WarehouseSourceFilter: Record "Warehouse Source Filter"; BuyFromVendorNoFilter: Code[20])
    begin
        WarehouseSourceFilter.Validate("Buy-from Vendor No. Filter", BuyFromVendorNoFilter);
        WarehouseSourceFilter.Modify(true);
    end;

    local procedure UpdateSourceFilterTransfer(var WarehouseSourceFilter: Record "Warehouse Source Filter"; TransferFromCodeFilter: Code[10]; TransferToCodeFilter: Code[10])
    begin
        WarehouseSourceFilter.Validate("Transfer-from Code Filter", TransferFromCodeFilter);
        WarehouseSourceFilter.Validate("Transfer-to Code Filter", TransferToCodeFilter);
        WarehouseSourceFilter.Modify(true);
    end;

    local procedure UseFiltersToGetSrcDocReceipt(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SellToCustomerNo: Code[20]; BuyFromVendorNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        CreateWarehouseReceiptHeader(WarehouseReceiptHeader, LocationCode);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Inbound);
        UpdateSourceFilterPurchase(WarehouseSourceFilter, BuyFromVendorNo);
        UpdateSourceFilterSales(WarehouseSourceFilter, SellToCustomerNo);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, LocationCode);
    end;

    local procedure CreateWarehouseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        WarehouseReceiptHeader.Validate("Location Code", LocationCode);
        WarehouseReceiptHeader.Modify(true);
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ActionOption: Integer;
    begin
        ActionOption := LibraryVariableStorage.DequeueInteger();
        case ActionOption of
            ItemTrackingHandlerAction::AssignSN:
                ItemTrackingLines."Assign &Serial No.".Invoke(); // AssignSerialNoEnterQtyPageHandler required.
        end;
        ItemTrackingLines.Ok().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssignSerialNoEnterQtyPageHandler(var EnterQuantityPage: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityPage.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StringMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;  // Ship Only.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ShipLinesMessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SourceDocMessageHandler(Message: Text[1024])
    begin
    end;

}
