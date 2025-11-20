codeunit 137081 "SCM Warehouse Documents UI"
{
    // [FEATURE] [Warehouse] [UI]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        UserIsNotWhseEmployeeAtWMSLocationErr: Label 'You must first set up user %1 as a warehouse employee at a location with the Bin Mandatory setting.', Comment = '%1: USERID';
        DefaultLocationNotDirectedPutawayPickErr: Label 'You must set up a default location with the Directed Put-away and Pick setting and assign it to user %1.', Comment = '%1: USERID';

    [Test]
    procedure ViewWhsePutAwayFromPurchOrder()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        PurchOrderListPage: TestPage "Purchase Order List";
        PurchaseOrderPage: TestPage "Purchase Order";
        WhseActivityLines: TestPage "Warehouse Activity Lines";
    begin
        // [FEATURE] [Purchase Order] [Put-away]
        // [SCWNARIO] View related warehouse put-aways from the Purchase Order List and Purchase Order pages
        Initialize();
        WarehouseEmployee.DeleteAll();

        // [GIVEN] Location "L" with warehouse receipt and put-away required
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create a purchase order "PO" on the location "L" and release the order
        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, LibraryPurchase.CreateVendorNo(), Location.Code);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create a warehouse receipt from "PO"
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWhseReceiptHeader(WhseReceiptHeader, Location.Code, Enum::"Warehouse Activity Source Document"::"Purchase Order", PurchaseHeader."No.");

        // [GIVEN] Post the warehosue receipt - warehouse put-away "P01" is created
        FindWhseActivityHeader(
            WhseActivityHeader, Location.Code, Enum::"Warehouse Activity Document Type"::Receipt, PostWhseReceipt(WhseReceiptHeader));

        // [GIVEN] Open the Purchase Order List page and select the order "PO"
        PurchOrderListPage.OpenView();
        PurchOrderListPage.GoToRecord(PurchaseHeader);
        WhseActivityLines.Trap();

        // [WHEN] Push the "Whse. Put-away Lines" action button
        PurchOrderListPage."Whse. Put-away Lines".Invoke();

        // [THEN] Page "Warehouse Activity Lines" opens and displays the put-away "P01"
        WhseActivityLines."No.".AssertEquals(WhseActivityHeader."No.");
        WhseActivityLines.Close();

        // [GIVEN] Close the "Warehouse Put-away Lines" and open the Purchase Order page
        PurchaseOrderPage.Trap();
        PurchOrderListPage.View().Invoke();
        WhseActivityLines.Trap();

        // [WHEN] Push the "Whse. Put-away Lines" action button
        PurchaseOrderPage."Whse. Put-away Lines".Invoke();

        // [THEN] Page "Warehouse Activity Lines" opens and displays the put-away "P01"
        WhseActivityLines."No.".AssertEquals(WhseActivityHeader."No.");
    end;

    [Test]
    procedure ViewWhsePickFromSalesOrder()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        SalesOrderListPage: TestPage "Sales Order List";
        SalesOrderPage: TestPage "Sales Order";
        WhseActivityLines: TestPage "Warehouse Activity Lines";
    begin
        // [FEATURE] [Sales Order] [Pick]
        // [SCWNARIO] View related warehouse picks from the Sales Order List and Sales Order pages
        Initialize();
        WarehouseEmployee.DeleteAll();

        // [GIVEN] Location "L" with warehouse shipment and pick required
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Item "I" with stock on location "L"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', '', 100, WorkDate(), 0);

        // [GIVEN] Create a sales order "SO" on the location "L" and release the order
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, LibrarySales.CreateCustomerNo(), Location.Code);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create a warehouse shipment from "SO"
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWhseShipmentHeader(WhseShipmentHeader, Location.Code, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.");

        // [GIVEN] Create a warehouse pick from the shipment ("P01")
        LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
        FindWhseActivityHeader(WhseActivityHeader, Location.Code, Enum::"Warehouse Activity Document Type"::Shipment, WhseShipmentHeader."No.");

        // [GIVEN] Open the Sales Order List page and select the order "SO"
        SalesOrderListPage.OpenView();
        SalesOrderListPage.GoToRecord(SalesHeader);
        WhseActivityLines.Trap();

        // [WHEN] Push the "Whse. Pick Lines" action button
        SalesOrderListPage."Whse. Pick Lines".Invoke();

        // [THEN] Page "Warehouse Activity Lines" opens and displays the pick "P01"
        WhseActivityLines."No.".AssertEquals(WhseActivityHeader."No.");

        // [GIVEN] Close the "Warehouse Pick Lines" and open the Sales Order page
        WhseActivityLines.Close();

        SalesOrderPage.Trap();
        SalesOrderListPage.View().Invoke();
        WhseActivityLines.Trap();

        // [WHEN] Push the "Whse. Pick Lines" action button
        SalesOrderPage."Whse. Pick Lines".Invoke();

        // [THEN] Page "Warehouse Activity Lines" opens and displays the pick "P01"
        WhseActivityLines."No.".AssertEquals(WhseActivityHeader."No.");
    end;

    [Test]
    procedure ViewWhsePutAwaysAndPickFromTransferOrder()
    var
        Locations: array[3] of Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        TransferOrdersPage: TestPage "Transfer Orders";
        TransferOrderPage: TestPage "Transfer Order";
        WhseActivityLines: TestPage "Warehouse Activity Lines";
    begin
        // [FEATURE] [Transfer Order] [Pick]
        // [SCWNARIO] View related warehouse picks from the Transfer Orders and Transfer Order pages
        Initialize();
        WarehouseEmployee.DeleteAll();

        // [GIVEN] Locations "L1" with warehouse shipment and pick enabled, and "L2" setup for warehouse receipt and put-away
        LibraryWarehouse.CreateLocationWMS(Locations[1], false, false, true, false, true);
        LibraryWarehouse.CreateLocationWMS(Locations[2], false, true, true, true, true);
        LibraryWarehouse.CreateInTransitLocation(Locations[3]);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Locations[1].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Locations[2].Code, false);

        // [GIVEN] Item "I" with stock on location "L1"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.PostPositiveAdjustment(Item, Locations[1].Code, '', '', 100, WorkDate(), 0);

        // [GIVEN] Create transfer order "TO" moving the item "I" from location "L1" to location "L2", and release the order
        LibraryInventory.CreateTransferHeader(TransferHeader, Locations[1].Code, Locations[2].Code, Locations[3].Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(100));
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [GIVEN] Create a warehouse shipment from the transfer order
        FindWhseShipmentHeader(WhseShipmentHeader, Locations[1].Code, Enum::"Warehouse Activity Source Document"::"Outbound Transfer", TransferHeader."No.");

        // [GIVEN] Create warehouse pick "P01" from the shipment
        LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
        FindWhseActivityHeader(WhseActivityHeader, Locations[1].Code, Enum::"Warehouse Activity Document Type"::Shipment, WhseShipmentHeader."No.");

        // [GIVEN] Open the Transfer Orders page and select the order "TO"
        TransferOrdersPage.OpenView();
        TransferOrdersPage.GoToRecord(TransferHeader);
        WhseActivityLines.Trap();

        // [WHEN] Push the "Whse. Put-away/Pick Lines" action button
        TransferOrdersPage."Whse. Put-away/Pick Lines".Invoke();

        // [THEN] Page "Warehouse Activity Lines" opens and displays the pick "P01"
        WhseActivityLines."No.".AssertEquals(WhseActivityHeader."No.");
        WhseActivityLines.Close();

        // [GIVEN] Close warehouse activity lines and open the Transfer Order page
        TransferOrderPage.Trap();
        TransferOrdersPage.View().Invoke();

        // [WHEN] Push the "Whse. Put-away/Pick Lines" action button
        WhseActivityLines.Trap();
        TransferOrderPage."Whse. Put-away/Pick Lines".Invoke();

        // [THEN] Page "Warehouse Activity Lines" opens and displays the pick "P01"
        WhseActivityLines."No.".AssertEquals(WhseActivityHeader."No.");
    end;

    [Test]
    procedure ViewWhsePickFromServiceOrder()
    var
        Location: Record Location;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        ServiceOrdersPage: TestPage "Service Orders";
        ServiceOrderPage: TestPage "Service Order";
        WhseActivityLines: TestPage "Warehouse Activity Lines";
    begin
        // [FEATURE] [Service Order] [Pick]
        // [SCWNARIO] View related warehouse picks from the Service Orders and Service Order pages
        Initialize();
        WarehouseEmployee.DeleteAll();

        // [GIVEN] Location "L" with warehouse shipment and pick required
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Service order "SO" with a service line for item "I" on location "L"
        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Order);
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.Validate("Location Code", Location.Code);
        ServiceLine.Modify();

        // [GIVEN] Release the service order
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        Item.Get(ServiceLine."No.");
        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', '', 1, WorkDate(), 0);

        // [GIVEN] Create a warehouse shipment from the service order
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);
        FindWhseShipmentHeader(WhseShipmentHeader, Location.Code, Enum::"Warehouse Activity Source Document"::"Service Order", ServiceHeader."No.");

        // [GIVEN] Create a warehouse pick "P01" from the shipment
        LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
        FindWhseActivityHeader(WhseActivityHeader, Location.Code, Enum::"Warehouse Activity Document Type"::Shipment, WhseShipmentHeader."No.");

        // [GIVEN] Open the Service Orders page and select the order "SO"
        ServiceOrdersPage.OpenView();
        ServiceOrdersPage.GoToRecord(ServiceHeader);
        WhseActivityLines.Trap();

        // [WHEN] Push the "Whse. Pick Lines" action button
        ServiceOrdersPage."Whse. Pick Lines".Invoke();

        // [THEN] Page "Warehouse Activity Lines" opens and displays the pick "P01"
        WhseActivityLines."No.".AssertEquals(WhseActivityHeader."No.");
        WhseActivityLines.Close();

        ServiceOrderPage.Trap();
        ServiceOrdersPage.View().Invoke();
        WhseActivityLines.Trap();

        // [WHEN] Push the "Whse. Pick Lines" action button
        ServiceOrderPage."Whse. Pick Lines".Invoke();

        // [THEN] Page "Warehouse Activity Lines" opens and displays the pick "P01"
        WhseActivityLines."No.".AssertEquals(WhseActivityHeader."No.");
    end;

    [Test]
    procedure ViewWhsePickFromPurchReturnOrder()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        PurchRetOrderListPage: TestPage "Purchase Return Order List";
        PurchReturnOrderPage: TestPage "Purchase Return Order";
        WhseActivityLines: TestPage "Warehouse Activity Lines";
    begin
        // [FEATURE] [Purchase Return Order] [Pick]
        // [SCWNARIO] View related warehouse picks from the Purchase Return Order List and Purchase Return Order pages
        Initialize();
        WarehouseEmployee.DeleteAll();

        // [GIVEN] location "L" with warehouse shipments and picks enabled
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create a purchase order on the location L and post the purchase receipt
        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, LibraryPurchase.CreateVendorNo(), Location.Code);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create a purchase return order "PRO" and release
        LibraryPurchase.CreatePurchaseReturnOrderWithLocation(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.", Location.Code);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLine."No.", PurchaseLine.Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create a warehouse shipment from the purchase return order
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
        FindWhseShipmentHeader(WhseShipmentHeader, Location.Code, Enum::"Warehouse Activity Source Document"::"Purchase Return Order", PurchaseHeader."No.");

        // [GIVEN] Create a warehouse pick "P01" from the shipment
        LibraryWarehouse.ReleaseWarehouseShipment(WhseShipmentHeader);
        LibraryWarehouse.CreatePick(WhseShipmentHeader);
        FindWhseActivityHeader(WhseActivityHeader, Location.Code, Enum::"Warehouse Activity Document Type"::Shipment, WhseShipmentHeader."No.");

        // [GIVEN] Open the Purchase Return Order List and select the order "PRO"
        PurchRetOrderListPage.OpenView();
        PurchRetOrderListPage.GoToRecord(PurchaseHeader);
        WhseActivityLines.Trap();

        // [WHEN] Push the "Whse. Pick Lines" action button
        PurchRetOrderListPage."Whse. Pick Lines".Invoke();

        // [THEN] Page "Warehouse Activity Lines" opens and displays the pick "P01"
        WhseActivityLines."No.".AssertEquals(WhseActivityHeader."No.");
        WhseActivityLines.Close();

        PurchReturnOrderPage.Trap();
        PurchRetOrderListPage.View().Invoke();
        WhseActivityLines.Trap();

        // [WHEN] Push the "Whse. Pick Lines" action button
        PurchReturnOrderPage."Whse. Pick Lines".Invoke();

        // [THEN] Page "Warehouse Activity Lines" opens and displays the pick "P01"
        WhseActivityLines."No.".AssertEquals(WhseActivityHeader."No.");
    end;

    [Test]
    procedure ViewWhsePutAwayFromSalesReturnOrder()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        SalesRetOrderListPage: TestPage "Sales Return Order List";
        SalesRetOrderPage: TestPage "Sales Return Order";
        WhseActivityLinesPage: TestPage "Warehouse Activity Lines";
    begin
        // [FEATURE] [Sales Return Order] [Put-away]
        // [SCWNARIO] View related warehouse put-aways from the Sales Return Order List and Sales Return Order pages
        Initialize();
        WarehouseEmployee.DeleteAll();

        // [GIVEN] Location "L" with warehouse receipt and put-away required
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Item "I" with stock on location "L"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', '', 100, WorkDate(), 0);

        // [GIVEN] Create a sales order on location "L" and post shipment
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, LibrarySales.CreateCustomerNo(), Location.Code);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Create a sales return order "SRO" on the location "L" and release it
        LibrarySales.CreateSalesReturnOrderWithLocation(SalesHeader, SalesHeader."Sell-to Customer No.", Location.Code);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", SalesLine.Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create and post a warehouse receipt. New warehouse put-away "P01" is created.
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        FindWhseReceiptHeader(WhseReceiptHeader, Location.Code, Enum::"Warehouse Activity Source Document"::"Sales Return Order", SalesHeader."No.");

        FindWhseActivityHeader(
            WhseActivityHeader, Location.Code, Enum::"Warehouse Activity Document Type"::Receipt, PostWhseReceipt(WhseReceiptHeader));

        // [GIVEN] Open the Sales Return Order List page and select the order "SRO"
        SalesRetOrderListPage.OpenView();
        SalesRetOrderListPage.GoToRecord(SalesHeader);
        WhseActivityLinesPage.Trap();

        // [WHEN] Push the "Whse. Put-away Lines" action button
        SalesRetOrderListPage."Whse. Put-away Lines".Invoke();

        // [THEN] Page "Warehouse Activity Lines" opens and displays the put-away "P01"
        WhseActivityLinesPage."No.".AssertEquals(WhseActivityHeader."No.");

        // [GIVEN] Close warehouse put-away lines and open the Sales Return Order page
        WhseActivityLinesPage.Close();
        SalesRetOrderPage.Trap();
        SalesRetOrderListPage.View().Invoke();
        WhseActivityLinesPage.Trap();

        // [WHEN] Push the "Whse. Put-away Lines" action button
        SalesRetOrderPage."Whse. Put-away Lines".Invoke();

        // [THEN] Page "Warehouse Activity Lines" opens and displays the put-away "P01"
        WhseActivityLinesPage."No.".AssertEquals(WhseActivityHeader."No.");
    end;

    [Test]
    procedure RegisteredWhseActivityListPageShowsAllowedLocations()
    var
        Location: array[2] of Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RegisteredWhseActivityList: TestPage "Registered Whse. Activity List";
        i: Integer;
    begin
        // [FEATURE] [Warehouse Employee]
        // [SCENARIO 462898] Show registered warehouse activities only for locations where Stan is set up as warehouse employee.
        Initialize();
        WarehouseEmployee.DeleteAll();

        for i := 1 to ArrayLen(Location) do begin
            LibraryWarehouse.CreateLocation(Location[i]);
            RegisteredWhseActivityHdr.Init();
            RegisteredWhseActivityHdr.Type := RegisteredWhseActivityHdr.Type::Pick;
            RegisteredWhseActivityHdr."No." := LibraryUtility.GenerateGUID();
            RegisteredWhseActivityHdr."Location Code" := Location[i].Code;
            RegisteredWhseActivityHdr.Insert();
        end;

        RegisteredWhseActivityList.OpenView();
        Assert.IsFalse(RegisteredWhseActivityList.First(), '');
        RegisteredWhseActivityList.Close();

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[2].Code, true);

        RegisteredWhseActivityList.OpenView();
        RegisteredWhseActivityList.Last();
        RegisteredWhseActivityList."Location Code".AssertEquals(Location[2].Code);
        Assert.IsFalse(RegisteredWhseActivityList.Previous(), '');
        RegisteredWhseActivityList.Close();
    end;

    [Test]
    procedure RegisteredWhseMovementsPageShowsAllowedLocations()
    var
        Location: array[2] of Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RegisteredWhseMovements: TestPage "Registered Whse. Movements";
        i: Integer;
    begin
        // [FEATURE] [Warehouse Employee]
        // [SCENARIO 462898] Show registered warehouse movements only for locations where Stan is set up as warehouse employee.
        Initialize();
        WarehouseEmployee.DeleteAll();

        for i := 1 to ArrayLen(Location) do begin
            LibraryWarehouse.CreateLocation(Location[i]);
            RegisteredWhseActivityHdr.Init();
            RegisteredWhseActivityHdr.Type := RegisteredWhseActivityHdr.Type::Movement;
            RegisteredWhseActivityHdr."No." := LibraryUtility.GenerateGUID();
            RegisteredWhseActivityHdr."Location Code" := Location[i].Code;
            RegisteredWhseActivityHdr.Insert();
        end;

        RegisteredWhseMovements.OpenView();
        Assert.IsFalse(RegisteredWhseMovements.First(), '');
        RegisteredWhseMovements.Close();

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[2].Code, true);

        RegisteredWhseMovements.OpenView();
        RegisteredWhseMovements.Last();
        RegisteredWhseMovements."Location Code".AssertEquals(Location[2].Code);
        Assert.IsFalse(RegisteredWhseMovements.Previous(), '');
        RegisteredWhseMovements.Close();
    end;

    [Test]
    procedure RegisteredWhsePicksPageShowsAllowedLocations()
    var
        Location: array[2] of Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RegisteredWhsePicks: TestPage "Registered Whse. Picks";
        i: Integer;
    begin
        // [FEATURE] [Warehouse Employee]
        // [SCENARIO 462898] Show registered warehouse picks only for locations where Stan is set up as warehouse employee.
        Initialize();
        WarehouseEmployee.DeleteAll();

        for i := 1 to ArrayLen(Location) do begin
            LibraryWarehouse.CreateLocation(Location[i]);
            RegisteredWhseActivityHdr.Init();
            RegisteredWhseActivityHdr.Type := RegisteredWhseActivityHdr.Type::Pick;
            RegisteredWhseActivityHdr."No." := LibraryUtility.GenerateGUID();
            RegisteredWhseActivityHdr."Location Code" := Location[i].Code;
            RegisteredWhseActivityHdr.Insert();
        end;

        RegisteredWhsePicks.OpenView();
        Assert.IsFalse(RegisteredWhsePicks.First(), '');
        RegisteredWhsePicks.Close();

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[2].Code, true);

        RegisteredWhsePicks.OpenView();
        RegisteredWhsePicks.Last();
        RegisteredWhsePicks."Location Code".AssertEquals(Location[2].Code);
        Assert.IsFalse(RegisteredWhsePicks.Previous(), '');
        RegisteredWhsePicks.Close();
    end;

    [Test]
    procedure RegisteredWhsePutawaysPageShowsAllowedLocations()
    var
        Location: array[2] of Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RegisteredWhsePutaways: TestPage "Registered Whse. Put-aways";
        i: Integer;
    begin
        // [FEATURE] [Warehouse Employee]
        // [SCENARIO 462898] Show registered warehouse picks only for locations where Stan is set up as warehouse employee.
        Initialize();
        WarehouseEmployee.DeleteAll();

        for i := 1 to ArrayLen(Location) do begin
            LibraryWarehouse.CreateLocation(Location[i]);
            RegisteredWhseActivityHdr.Init();
            RegisteredWhseActivityHdr.Type := RegisteredWhseActivityHdr.Type::"Put-away";
            RegisteredWhseActivityHdr."No." := LibraryUtility.GenerateGUID();
            RegisteredWhseActivityHdr."Location Code" := Location[i].Code;
            RegisteredWhseActivityHdr.Insert();
        end;

        RegisteredWhsePutaways.OpenView();
        Assert.IsFalse(RegisteredWhsePutaways.First(), '');
        RegisteredWhsePutaways.Close();

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[2].Code, true);

        RegisteredWhsePutaways.OpenView();
        RegisteredWhsePutaways.Last();
        RegisteredWhsePutaways."Location Code".AssertEquals(Location[2].Code);
        Assert.IsFalse(RegisteredWhsePutaways.Previous(), '');
        RegisteredWhsePutaways.Close();
    end;

    [Test]
    procedure WhseInternalPickListPageShowsAllowedLocations()
    var
        Location: array[2] of Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPickList: TestPage "Whse. Internal Pick List";
        i: Integer;
    begin
        // [FEATURE] [Warehouse Employee]
        // [SCENARIO 462898] Show registered warehouse picks only for locations where Stan is set up as warehouse employee.
        Initialize();
        WarehouseEmployee.DeleteAll();

        for i := 1 to ArrayLen(Location) do begin
            LibraryWarehouse.CreateLocation(Location[i]);
            WhseInternalPickHeader.Init();
            WhseInternalPickHeader."No." := LibraryUtility.GenerateGUID();
            WhseInternalPickHeader."Location Code" := Location[i].Code;
            WhseInternalPickHeader.Insert();
        end;

        WhseInternalPickList.OpenView();
        Assert.IsFalse(WhseInternalPickList.First(), '');
        WhseInternalPickList.Close();

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[2].Code, true);

        WhseInternalPickList.OpenView();
        WhseInternalPickList.Last();
        WhseInternalPickList."Location Code".AssertEquals(Location[2].Code);
        Assert.IsFalse(WhseInternalPickList.Previous(), '');
        WhseInternalPickList.Close();
    end;

    [Test]
    procedure WhseInternalPutawayListPageShowsAllowedLocations()
    var
        Location: array[2] of Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WhseInternalPutawayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutawayList: TestPage "Whse. Internal Put-away List";
        i: Integer;
    begin
        // [FEATURE] [Warehouse Employee]
        // [SCENARIO 462898] Show registered warehouse put-aways only for locations where Stan is set up as warehouse employee.
        Initialize();
        WarehouseEmployee.DeleteAll();

        for i := 1 to ArrayLen(Location) do begin
            LibraryWarehouse.CreateLocation(Location[i]);
            WhseInternalPutawayHeader.Init();
            WhseInternalPutawayHeader."No." := LibraryUtility.GenerateGUID();
            WhseInternalPutawayHeader."Location Code" := Location[i].Code;
            WhseInternalPutawayHeader.Insert();
        end;

        WhseInternalPutawayList.OpenView();
        Assert.IsFalse(WhseInternalPutawayList.First(), '');
        WhseInternalPutawayList.Close();

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[2].Code, true);

        WhseInternalPutawayList.OpenView();
        WhseInternalPutawayList.Last();
        WhseInternalPutawayList."Location Code".AssertEquals(Location[2].Code);
        Assert.IsFalse(WhseInternalPutawayList.Previous(), '');
        WhseInternalPutawayList.Close();
    end;

    [Test]
    procedure LocationsWithWarehouseListPageShowsAllowedLocations()
    var
        Location: array[2] of Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        LocationsWithWarehouseList: TestPage "Locations with Warehouse List";
        i: Integer;
    begin
        // [FEATURE] [Warehouse Employee]
        // [SCENARIO 462898] Locations with Warehouse List page displays only locations where Stan is set up as warehouse employee.
        Initialize();
        WarehouseEmployee.DeleteAll();

        for i := 1 to ArrayLen(Location) do
            LibraryWarehouse.CreateLocation(Location[i]);

        LocationsWithWarehouseList.OpenView();
        Assert.IsFalse(LocationsWithWarehouseList.First(), '');
        LocationsWithWarehouseList.Close();

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[2].Code, true);

        LocationsWithWarehouseList.OpenView();
        LocationsWithWarehouseList.Last();
        LocationsWithWarehouseList.Code.AssertEquals(Location[2].Code);
        Assert.IsFalse(LocationsWithWarehouseList.Previous(), '');
        LocationsWithWarehouseList.Close();
    end;

    [Test]
    procedure WarehouseEmployeeForWMSLocationExists()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WMSManagement: Codeunit "WMS Management";
        CurrentLocationCode: Code[10];
    begin
        // [FEATURE] [Warehouse Employee]
        // [SCENARIO 445825] The user has been set up as a warehouse employee at location with bin mandatory.
        Initialize();
        WarehouseEmployee.DeleteAll();

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        WMSManagement.GetWMSLocation(CurrentLocationCode);

        Assert.AreEqual(Location.Code, CurrentLocationCode, '');
    end;

    [Test]
    [HandlerFunctions('WarehouseEmployeesAddMeModalPageHandler,LocationListModalPageHandler,ConfirmHandlerYes')]
    procedure WarehouseEmployeeForWMSLocationShowConfirmYesAddMe()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WMSManagement: Codeunit "WMS Management";
        CurrentLocationCode: Code[10];
    begin
        // [FEATURE] [Warehouse Employee]
        // [SCENARIO 445825] The user is not a warehouse employee at location with bin mandatory, they receive confirm message, set themselves up properly, and continue transaction.
        Initialize();
        WarehouseEmployee.DeleteAll();

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryVariableStorage.Enqueue(Location.Code);
        WMSManagement.GetWMSLocation(CurrentLocationCode);

        Assert.AreEqual(Location.Code, CurrentLocationCode, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WarehouseEmployeesAddMeModalPageHandler,LocationListModalPageHandler,ConfirmHandlerYes')]
    procedure WarehouseEmployeeForWMSLocationShowConfirmYesDoNotAdd()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WMSManagement: Codeunit "WMS Management";
        CurrentLocationCode: Code[10];
    begin
        // [FEATURE] [Warehouse Employee]
        // [SCENARIO 445825] The user is not a warehouse employee at location with bin mandatory, they receive confirm message, set themselves up at location with no bins, and get error.
        Initialize();
        WarehouseEmployee.DeleteAll();

        LibraryWarehouse.CreateLocation(Location);

        LibraryVariableStorage.Enqueue(Location.Code);
        asserterror WMSManagement.GetWMSLocation(CurrentLocationCode);

        Assert.ExpectedError(StrSubstNo(UserIsNotWhseEmployeeAtWMSLocationErr, UserId()));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure WarehouseEmployeeForWMSLocationShowConfirmNo()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        WMSManagement: Codeunit "WMS Management";
        CurrentLocationCode: Code[10];
    begin
        // [FEATURE] [Warehouse Employee]
        // [SCENARIO 445825] The user is not a warehouse employee at location with bin mandatory, they receive confirm message, respond No, and get error.
        Initialize();
        WarehouseEmployee.DeleteAll();

        asserterror WMSManagement.GetWMSLocation(CurrentLocationCode);

        Assert.ExpectedError(StrSubstNo(UserIsNotWhseEmployeeAtWMSLocationErr, UserId()));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WarehouseEmployeesDefaultModalPageHandler,ConfirmHandlerYes')]
    procedure WarehouseEmployeeForDPnPLocationShowConfirmYesAddMe()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WMSManagement: Codeunit "WMS Management";
        CurrentLocationCode: Code[10];
    begin
        // [FEATURE] [Warehouse Employee]
        // [SCENARIO 445825] The user is not a warehouse employee at directed put-away and pick location, they receive confirm message, set themselves up properly, and continue transaction.
        Initialize();
        WarehouseEmployee.DeleteAll();

        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        Location."Directed Put-away and Pick" := true;
        Location.Modify();

        LibraryVariableStorage.Enqueue(Location.Code);
        CurrentLocationCode := WMSManagement.GetDefaultDirectedPutawayAndPickLocation();

        Assert.AreEqual(Location.Code, CurrentLocationCode, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WarehouseEmployeesDefaultModalPageHandler,ConfirmHandlerYes')]
    procedure WarehouseEmployeeForDPnPLocationShowConfirmYesDoNotAdd()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WMSManagement: Codeunit "WMS Management";
    begin
        // [FEATURE] [Warehouse Employee]
        // [SCENARIO 445825] The user is not a warehouse employee at directed put-away and pick (DPnP) location, they receive confirm message, set themselves up at non-DPnP location, and get error.
        Initialize();
        WarehouseEmployee.DeleteAll();

        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);

        LibraryVariableStorage.Enqueue(Location.Code);
        asserterror WMSManagement.GetDefaultDirectedPutawayAndPickLocation();

        Assert.ExpectedError(StrSubstNo(DefaultLocationNotDirectedPutawayPickErr, UserId()));

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        WarehouseSetup: Record "Warehouse Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryService: Codeunit "Library - Service";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Warehouse Documents UI");

        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Warehouse Documents UI");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibraryService.SetupServiceMgtNoSeries();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Warehouse Documents UI");
    end;

    local procedure FindWhseReceiptHeader(
        var WhseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10]; SourceDocType: Enum "Warehouse Activity Source Document";
        SourceDocNo: Code[20])
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WhseReceiptLine.SetRange("Location Code", LocationCode);
        WhseReceiptLine.SetRange("Source Document", SourceDocType);
        WhseReceiptLine.SetRange("Source No.", SourceDocNo);
        WhseReceiptLine.FindFirst();
        WhseReceiptHeader.Get(WhseReceiptLine."No.");
    end;

    local procedure FindWhseShipmentHeader(
        var WhseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10]; SourceDocType: Enum "Warehouse Activity Source Document";
        SourceDocNo: Code[20])
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WhseShipmentLine.SetRange("Location Code", LocationCode);
        WhseShipmentLine.SetRange("Source Document", SourceDocType);
        WhseShipmentLine.SetRange("Source No.", SourceDocNo);
        WhseShipmentLine.FindFirst();
        WhseShipmentHeader.Get(WhseShipmentLine."No.");
    end;

    local procedure FindWhseActivityHeader(
        var WhseActivityHeader: Record "Warehouse Activity Header"; LocationCode: Code[10]; WhseDocType: Enum "Warehouse Activity Document Type"; WhseDocNo: Code[20])
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.SetRange("Location Code", LocationCode);
        WhseActivityLine.SetRange("Whse. Document Type", WhseDocType);
        WhseActivityLine.SetRange("Whse. Document No.", WhseDocNo);
        WhseActivityLine.FindFirst();
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
    end;

    local procedure PostWhseReceipt(WhseReceiptHeader: Record "Warehouse Receipt Header"): Code[20]
    var
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
    begin
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);
        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WhseReceiptHeader."No.");
        PostedWhseReceiptHeader.FindFirst();
        exit(PostedWhseReceiptHeader."No.");
    end;

    [ModalPageHandler]
    procedure WarehouseEmployeesAddMeModalPageHandler(var WarehouseEmployees: TestPage "Warehouse Employees")
    begin
        WarehouseEmployees."Add Me".Invoke();
        WarehouseEmployees.OK().Invoke();
    end;


    [ModalPageHandler]
    procedure WarehouseEmployeesDefaultModalPageHandler(var WarehouseEmployees: TestPage "Warehouse Employees")
    begin
        WarehouseEmployees.New();
        WarehouseEmployees."User ID".SetValue(UserId());
        WarehouseEmployees."Location Code".SetValue(LibraryVariableStorage.DequeueText());
        WarehouseEmployees.Default.SetValue(true);
        WarehouseEmployees.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LocationListModalPageHandler(var LocationList: TestPage "Location List")
    begin
        LocationList.Filter.SetFilter(Code, LibraryVariableStorage.DequeueText());
        LocationList.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}