codeunit 137014 "SCM Fulfillment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Fulfillment]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryJob: Codeunit "Library - Job";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        ReservationFromStockErr: Label 'Reservation from Stock must be %1 in %2.', Comment = '%1= Field Value, %2 =Table Caption.';

    [Test]
    procedure ReservedQtyFromInventoryForAssemblyLine()
    var
        Item, HeaderItem : Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        // [FEATURE] [Reservation] [Assembly]
        // [SCENARIO 471183] Calculate quantity that is fully reserved from inventory for assembly line.
        Initialize();

        // [GIVEN] Item in inventory
        CreateAlwaysReserveItem(Item);
        PostItemToInventory(Item."No.", '', '', 5);
        LibraryInventory.CreateItem(HeaderItem);

        // [GIVEN] Assembly Order for Item
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate() + 10, HeaderItem."No.", '', 10, '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", 10, 0, '');
        AssemblyHeader.Validate("Quantity to Assemble", 2);
        AssemblyHeader.Modify(true);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [WHEN] Reserving Item
        AssemblyLine.Find();
        AssemblyLine.AutoReserve();

        // [THEN] Item is reserved
        Assert.AreEqual(
            3, AssemblyLineReserve.GetReservedQtyFromInventory(AssemblyLine),
            'Reserved from stock quantity for assembly line is wrong.');
    end;

    [Test]
    procedure ReservedQtyFromInventoryForAssemblyHeader()
    var
        Item, HeaderItem : Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        // [FEATURE] [Reservation] [Assembly]
        // [SCENARIO 471183] Calculate quantity that is fully reserved from inventory for assembly header.
        Initialize();

        // [GIVEN] Item in inventory
        CreateAlwaysReserveItem(Item);
        PostItemToInventory(Item."No.", '', '', 15);
        LibraryInventory.CreateItem(HeaderItem);

        // [GIVEN] Assembly Order for Item
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate() + 10, HeaderItem."No.", '', 10, '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", '', 10, 0, '');
        AssemblyLine.AutoReserve();

        Assert.AreEqual(
          10, AssemblyLineReserve.GetReservedQtyFromInventory(AssemblyHeader),
          'Reserved from stock quantity for assembly header is wrong.');
    end;

    [Test]
    procedure ReservedFromStockStatesOnAssemblyLine()
    var
        Item, HeaderItem : Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyInfoPaneManagement: Codeunit "Assembly Info-Pane Management";
        ReservationFromStock: Enum "Reservation From Stock";
        AllowedValues: List of [Integer];
        i: Integer;
    begin
        // [FEATURE] [Reservation] [Assembly]
        // [SCENARIO 471189] Show what part of assembly line is reserved from stock.
        Initialize();

        // [GIVEN] Item in inventory
        CreateAlwaysReserveItem(Item);
        PostItemToInventory(Item."No.", '', '', 15);
        LibraryInventory.CreateItem(HeaderItem);

        AllowedValues.Add(ReservationFromStock::Full.AsInteger());
        AllowedValues.Add(ReservationFromStock::Partial.AsInteger());
        AllowedValues.Add(ReservationFromStock::None.AsInteger());

        // [GIVEN] Assembly Order for Item
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate() + 10, HeaderItem."No.", '', 10, '');

        foreach i in AllowedValues do begin
            LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", '', 10, 0, '');

            // [WHEN] Item is reserved
            AssemblyLine.AutoReserve();

            // [THEN] Reservation status is correct
            Assert.AreEqual(
              i, AssemblyInfoPaneManagement.GetQtyReservedFromStockState(AssemblyLine).AsInteger(),
              'Wrong reserved from stock state of assembly line.');
        end;
    end;

    [Test]
    procedure ReservedFromStockStatesOnAssemblyHeader()
    var
        Item, HeaderItem : Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReservationFromStock: Enum "Reservation From Stock";
        AllowedValues: List of [Integer];
        i: Integer;
    begin
        // [FEATURE] [Reservation] [Assembly]
        // [SCENARIO 471189] Show what part of assembly header is reserved from stock.
        Initialize();

        // [GIVEN] Item in inventory
        CreateAlwaysReserveItem(Item);
        PostItemToInventory(Item."No.", '', '', 15);
        LibraryInventory.CreateItem(HeaderItem);

        AllowedValues.Add(ReservationFromStock::Full.AsInteger());
        AllowedValues.Add(ReservationFromStock::Partial.AsInteger());
        AllowedValues.Add(ReservationFromStock::None.AsInteger());

        foreach i in AllowedValues do begin
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate() + 10, HeaderItem."No.", '', 10, '');
            LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", '', 10, 0, '');

            // [WHEN] Item is reserved
            AssemblyLine.AutoReserve();

            // [THEN] Reservation status is correct
            Assert.AreEqual(
              i, AssemblyHeader.GetQtyReservedFromStockState().AsInteger(),
              'Wrong reserved from stock state of assembly header.');
        end;
    end;

    [Test]
    procedure ReservedQtyFromInventoryForTransferLine()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        FromLocation, ToLocation, TransitLocation : Record Location;
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
    begin
        // [FEATURE] [Reservation] [Transfer]
        // [SCENARIO 471183] Calculate quantity that is fully reserved from inventory for transfer line.
        Initialize();

        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, TransitLocation);

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", FromLocation.Code, '', 5);

        // [GIVEN] Transfer order for Item
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, TransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        TransferLine.Validate("Qty. to Ship", 2);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Reserving Item
        TransferLine.Find();
        AutoReserveTransferLine(TransferLine);

        // [THEN] Item is reserved
        Assert.AreEqual(
            3, TransferLineReserve.GetReservedQtyFromInventory(TransferLine),
            'Reserved from stock quantity for transfer line is wrong.');
    end;

    [Test]
    procedure ReservedQtyFromInventoryForTransferHeader()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        FromLocation, ToLocation, TransitLocation : Record Location;
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
    begin
        // [FEATURE] [Reservation] [Transfer]
        // [SCENARIO 471183] Calculate quantity that is fully reserved from inventory for transfer header.
        Initialize();

        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, TransitLocation);

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", FromLocation.Code, '', 15);

        // [GIVEN] Transfer order for Item
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, TransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);

        // [WHEN] Reserving Item
        AutoReserveTransferLine(TransferLine);

        // [THEN] Item is reserved
        Assert.AreEqual(
          10, TransferLineReserve.GetReservedQtyFromInventory(TransferHeader),
          'Reserved from stock quantity for transfer header is wrong.');
    end;

    [Test]
    procedure ReservedFromStockStatesOnTransferHeader()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        FromLocation, ToLocation, TransitLocation : Record Location;
        ReservationFromStock: Enum "Reservation From Stock";
        AllowedValues: List of [Integer];
        i: Integer;
    begin
        // [FEATURE] [Reservation] [Transfer]
        // [SCENARIO 471189] Show what part of transfer header is reserved from stock.
        Initialize();

        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, TransitLocation);

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", FromLocation.Code, '', 15);

        AllowedValues.Add(ReservationFromStock::Full.AsInteger());
        AllowedValues.Add(ReservationFromStock::Partial.AsInteger());
        AllowedValues.Add(ReservationFromStock::None.AsInteger());

        foreach i in AllowedValues do begin
            LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, TransitLocation.Code);
            LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);

            // [WHEN] Reserving Item
            AutoReserveTransferLine(TransferLine);

            // [THEN] Reservation status is correct
            Assert.AreEqual(
              i, TransferHeader.GetQtyReservedFromStockState().AsInteger(),
              'Wrong reserved from stock state of transfer header.');
        end;
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutAwayPickRequestPageHandler,MessageHandler')]
    procedure CreateInvtPickOnlyForReservedFromStockTransferLines()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        FromLocation, ToLocation, TransitLocation : Record Location;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Reservation] [Transfer] [Inventory Pick]
        // [SCENARIO 471183] Respect "Reserved from Stock" = "Full" setting in Create Invt. Put-away/Pick/Movement report.
        Initialize();

        CreateWMSLocation(FromLocation, false, false, true, false, false);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryWarehouse.CreateLocation(ToLocation);

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", FromLocation.Code, '', 15);

        // [GIVEN] Reserving Item on Transfer Order's lines
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, TransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        AutoReserveTransferLine(TransferLine);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        AutoReserveTransferLine(TransferLine);

        PostItemToInventory(Item."No.", FromLocation.Code, '', 15);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);

        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        Commit();

        // [WHEN] Creating Invt. Put-away/Pick/Movement report with setting "Reserved from Stock" = "Full"
        TransferHeader.CreateInvtPutAwayPick();

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();

        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        WarehouseActivityLine.TestField("Source Type", Database::"Transfer Line");
        WarehouseActivityLine.TestField("Source No.", TransferLine."Document No.");
        WarehouseActivityLine.TestField("Source Line No.", TransferLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, TransferLine.Quantity);
    end;

    [Test]
    procedure ReservedFromStockFullInCreateWarehouseShipmentReportFromTransfer()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        FromLocation, ToLocation, TransitLocation : Record Location;
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Create Warehouse Shipment] [Reservation] [Transfer]
        // [SCENARIO 471183] Respect "Reserved From Stock" = Full in Create Warehouse Shipment report.
        Initialize();

        CreateWMSLocation(FromLocation, false, false, false, false, true);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryWarehouse.CreateLocation(ToLocation);

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", FromLocation.Code, '', 15);

        // [WHEN] Reserving Item on Transfer Order's lines
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, TransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        AutoReserveTransferLine(TransferLine);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        AutoReserveTransferLine(TransferLine);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Creating Warehouse Shipment report with setting "Reserved from Stock" = "Full"
        RunCreateWarehouseShipmentReportForTransferOrder(TransferHeader."No.", "Reservation From Stock"::Full);

        // [THEN] Setting is respected
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        FindWhseShipment(
          WarehouseShipmentLine, Database::"Transfer Line", 0, TransferHeader."No.", FromLocation.Code);
        Assert.RecordCount(WarehouseShipmentLine, 1);
        WarehouseShipmentLine.TestField("Source Line No.", TransferLine."Line No.");
    end;

    [Test]
    procedure ReservedQtyFromInventoryForPurchaseReturnLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
    begin
        // [FEATURE] [Reservation] [Purchase] [Return Order]
        // [SCENARIO 471183] Calculate quantity that is fully reserved from inventory for purchase return line.
        Initialize();

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", '', '', 5);

        // [GIVEN] Purchase Return Order for Item
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', Item."No.", 10, '', WorkDate());
        PurchaseLine.Validate("Return Qty. to Ship", 2);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Reserving Item
        AutoReservePurchaseLine(PurchaseLine);

        // [THEN] Item is reserved
        Assert.AreEqual(
            3, PurchLineReserve.GetReservedQtyFromInventory(PurchaseLine),
            'Reserved from stock quantity for purchase line is wrong.');
    end;

    [Test]
    procedure ReservedQtyFromInventoryForPurchaseReturnHeader()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
    begin
        // [FEATURE] [Reservation] [Purchase] [Return Order]
        // [SCENARIO 471183] Calculate quantity that is fully reserved from inventory for purchase return order.
        Initialize();

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", '', '', 15);

        // [GIVEN] Purchase Order for Item
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', Item."No.", 10, '', WorkDate());

        // [WHEN] Reserving Item
        AutoReservePurchaseLine(PurchaseLine);

        // [THEN] Item is reserved
        Assert.AreEqual(
          10, PurchLineReserve.GetReservedQtyFromInventory(PurchaseHeader),
          'Reserved from stock quantity for purchase header is wrong.');
    end;

    [Test]
    procedure ReservedFromStockStatesOnPurchaseReturnHeader()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationFromStock: Enum "Reservation From Stock";
        AllowedValues: List of [Integer];
        i: Integer;
    begin
        // [FEATURE] [Reservation] [Purchase] [Return Order]
        // [SCENARIO 471189] Show what part of purchase return order is reserved from stock.
        Initialize();

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", '', '', 15);

        AllowedValues.Add(ReservationFromStock::Full.AsInteger());
        AllowedValues.Add(ReservationFromStock::Partial.AsInteger());
        AllowedValues.Add(ReservationFromStock::None.AsInteger());

        foreach i in AllowedValues do begin
            LibraryPurchase.CreatePurchaseDocumentWithItem(
                PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', Item."No.", 10, '', WorkDate());

            // [WHEN] Reserving Item
            AutoReservePurchaseLine(PurchaseLine);

            // [THEN] Reservation status is correct
            Assert.AreEqual(
              i, PurchaseHeader.GetQtyReservedFromStockState().AsInteger(),
              'Wrong reserved from stock state of purchase header.');
        end;
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutAwayPickRequestPageHandler,MessageHandler')]
    procedure CreateInvtPickOnlyForReservedFromStockPurchaseReturnLines()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Reservation] [Purchase] [Return Order] [Inventory Pick]
        // [SCENARIO 471183] Respect "Reserved from Stock" = "Full" setting in Create Invt. Put-away/Pick/Movement report.
        Initialize();

        // [GIVEN] Location for Invt. Put-away/Pick/Movement report
        CreateWMSLocation(Location, false, false, true, false, false);

        LibraryInventory.CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '');
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);

        // [GIVEN] Item in inventory
        PostItemToInventory(Item."No.", Location.Code, '', 15);

        // [WHEN] Reserving Item on Purchase Return Order's lines
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        AutoReservePurchaseLine(PurchaseLine);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        AutoReservePurchaseLine(PurchaseLine);

        PostItemToInventory(Item."No.", Location.Code, '', 15);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        Commit();

        PurchaseHeader.CreateInvtPutAwayPick();

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();

        // [THEN] Setting is respected
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        WarehouseActivityLine.TestField("Source Type", Database::"Purchase Line");
        WarehouseActivityLine.TestField("Source No.", PurchaseLine."Document No.");
        WarehouseActivityLine.TestField("Source Line No.", PurchaseLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, PurchaseLine.Quantity);
    end;

    [Test]
    procedure ReservedFromStockFullInCreateWarehouseShipmentReportFromPurchReturnOrder()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Create Warehouse Shipment] [Reservation] [Purchase] [Return Order]
        // [SCENARIO 471183] Respect "Reserved From Stock" = Full in Create Warehouse Shipment report.
        Initialize();

        // [GIVEN] Item in inventory
        CreateWMSLocation(Location, false, false, false, false, true);

        LibraryInventory.CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '');
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);

        PostItemToInventory(Item."No.", Location.Code, '', 15);

        // [WHEN] Reserving Item on Transfer Order's lines
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        AutoReservePurchaseLine(PurchaseLine);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        AutoReservePurchaseLine(PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Creating Warehouse Shipment report with setting "Reserved from Stock" = "Full"
        RunCreateWarehouseShipmentReportForPurchaseReturnOrder(PurchaseHeader."No.", "Reservation From Stock"::Full);

        // [THEN] Setting is respected
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        FindWhseShipment(
          WarehouseShipmentLine, Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", Location.Code);
        Assert.RecordCount(WarehouseShipmentLine, 1);
        WarehouseShipmentLine.TestField("Source Line No.", PurchaseLine."Line No.");
    end;

    [Test]
    procedure ReservedFromStockStatesOnProdOrderComponent()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ReservationFromStock: Enum "Reservation From Stock";
        AllowedValues: List of [Integer];
        i: Integer;
    begin
        // [FEATURE] [Reservation] [Production]
        // [SCENARIO 471189] Show what part of production order component is reserved from stock.
        Initialize();

        // [GIVEN] Item in inventory
        CreateAlwaysReserveItem(Item);
        PostItemToInventory(Item."No.", '', '', 15);

        AllowedValues.Add(ReservationFromStock::Full.AsInteger());
        AllowedValues.Add(ReservationFromStock::Partial.AsInteger());
        AllowedValues.Add(ReservationFromStock::None.AsInteger());

        foreach i in AllowedValues do begin
            LibraryManufacturing.CreateAndRefreshProductionOrder(
              ProductionOrder, ProductionOrder.Status::Released,
              ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), 1);
            ProdOrderLine.SetRange(Status, ProductionOrder.Status);
            ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderLine.FindFirst();
            CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, Item."No.", 10);

            // [WHEN] Reserving Item
            ProdOrderComponent.AutoReserve();

            // [THEN] Reservation status is correct
            Assert.AreEqual(
              i, ProductionOrder.GetQtyReservedFromStockState().AsInteger(),
              'Wrong reserved from stock state of production order component.');
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ReservedQtyFromInventoryForServiceLine()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
    begin
        // [FEATURE] [Reservation] [Service]
        // [SCENARIO 471183] Calculate quantity that is fully reserved from inventory for service line.
        Initialize();

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", '', '', 5);

        // [GIVEN] Service Order for Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, Enum::"Service Line Type"::Item, Item."No.", 10);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Qty. to Ship", 2);
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [WHEN] Reserving Item
        LibraryService.AutoReserveServiceLine(ServiceLine);

        // [THEN] Item is reserved
        Assert.AreEqual(
          3, ServiceLineReserve.GetReservedQtyFromInventory(ServiceLine),
          'Reserved from stock quantity for service line is wrong.');
    end;

    [Test]
    procedure ReservedQtyFromInventoryForServiceHeader()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
    begin
        // [FEATURE] [Reservation] [Service]
        // [SCENARIO 471183] Calculate quantity that is fully reserved from inventory for sales header.
        Initialize();

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", '', '', 15);

        // [GIVEN] Service Order for Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, Enum::"Service Line Type"::Item, Item."No.", 10);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
        LibraryService.AutoReserveServiceLine(ServiceLine);

        // [THEN] Item is reserved
        Assert.AreEqual(
          10, ServiceLineReserve.GetReservedQtyFromInventory(ServiceHeader),
          'Reserved from stock quantity for service header is wrong.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ReservedFromStockStatesOnServiceHeader()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ReservationFromStock: Enum "Reservation From Stock";
        AllowedValues: List of [Integer];
        i: Integer;
    begin
        // [FEATURE] [Reservation] [Service]
        // [SCENARIO 471189] Show what part of service header is reserved from stock.
        Initialize();

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", '', '', 15);

        AllowedValues.Add(ReservationFromStock::Full.AsInteger());
        AllowedValues.Add(ReservationFromStock::Partial.AsInteger());
        AllowedValues.Add(ReservationFromStock::None.AsInteger());

        foreach i in AllowedValues do begin
            Clear(ServiceHeader);
            Clear(ServiceItem);
            Clear(ServiceItemLine);
            Clear(ServiceLine);
            LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
            LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
            LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, Enum::"Service Line Type"::Item, Item."No.", 10);
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Modify(true);

            // [WHEN] Reserving Item
            LibraryService.AutoReserveServiceLine(ServiceLine);

            // [THEN] Reservation status is correct
            Assert.AreEqual(
              i, ServiceHeader.GetQtyReservedFromStockState().AsInteger(),
              'Wrong reserved from stock state of service header.');
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ReservedFromStockFullInCreateWarehouseShipmentReportFromService()
    var
        Location: Record Location;
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Create Warehouse Shipment] [Service] [Sales]
        // [SCENARIO 471183] Respect "Reserved From Stock" = Full in Create Warehouse Shipment report.
        Initialize();

        CreateWMSLocation(Location, false, false, false, false, true);

        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", Location.Code, '', 15);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        ServiceHeader.Validate("Location Code", Location.Code);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, Enum::"Service Line Type"::Item, Item."No.", 10);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
        LibraryService.AutoReserveServiceLine(ServiceLine);

        ServiceHeader.Find();
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, Enum::"Service Line Type"::Item, Item."No.", 10);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
        LibraryService.AutoReserveServiceLine(ServiceLine);

        ServiceHeader.Find();
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        RunCreateWarehouseShipmentReportForSalesOrderForServiceOrder(ServiceHeader."No.", "Reservation From Stock"::Full);

        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        FindWhseShipment(
          WarehouseShipmentLine, Database::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", Location.Code);
        Assert.RecordCount(WarehouseShipmentLine, 1);
        WarehouseShipmentLine.TestField("Source Line No.", ServiceLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('JobTransferJobPlanningLinePageHandler,ConfirmYesHandler,MessageHandler')]
    procedure ReservedQtyFromInventoryForJobPlanningLine()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [FEATURE] [Reservation] [Job]
        // [SCENARIO 471183] Calculate quantity that is fully reserved from inventory for sales line.
        Initialize();

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", '', '', 5);

        // [GIVEN] Job Planning Line for Item
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate(Quantity, 5);
        JobPlanningLine.Validate("Qty. to Transfer to Journal", 2);
        JobPlanningLine.Modify(true);

        LibraryJob.GetJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);

        JobPlanningLines.OpenEdit();
        JobPlanningLines.Filter.SetFilter("Job No.", JobPlanningLine."Job No.");
        LibraryVariableStorage.Enqueue(JobJournalTemplate.Name);
        LibraryVariableStorage.Enqueue(JobJournalBatch.Name);
        JobPlanningLines.CreateJobJournalLines.Invoke();

        JobJournalLine.SetRange("Job No.", JobPlanningLine."Job No.");
        JobJournalLine.FindFirst();
        LibraryJob.PostJobJournal(JobJournalLine);

        // [WHEN] Reserving Item
        JobPlanningLine.Find();
        JobPlanningLine.AutoReserve();

        // [THEN] Item is reserved
        Assert.AreEqual(
          3, JobPlanningLineReserve.GetReservedQtyFromInventory(JobPlanningLine),
          'Reserved from stock quantity for job planning line is wrong.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ReservedQtyFromInventoryForJob()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
    begin
        // [FEATURE] [Reservation] [Job]
        // [SCENARIO 471183] Calculate quantity that is fully reserved from inventory for sales header.
        Initialize();

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", '', '', 15);

        // [GIVEN] Job Planning Line for Item
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate(Quantity, 10);
        JobPlanningLine.Modify(true);
        JobPlanningLine.AutoReserve();

        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate(Quantity, 10);
        JobPlanningLine.Modify(true);

        // [WHEN] Reserving Item
        JobPlanningLine.AutoReserve();

        // [THEN] Item is reserved
        Assert.AreEqual(
          15, JobPlanningLineReserve.GetReservedQtyFromInventory(Job),
          'Reserved from stock quantity for job is wrong.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ReservedFromStockStatesOnJob()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ReservationFromStock: Enum "Reservation From Stock";
        AllowedValues: List of [Integer];
        i: Integer;
    begin
        // [FEATURE] [Reservation] [Job]
        // [SCENARIO 471189] Show what part of job is reserved from stock.
        Initialize();

        // [GIVEN] Item in inventory
        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", '', '', 15);

        AllowedValues.Add(ReservationFromStock::Full.AsInteger());
        AllowedValues.Add(ReservationFromStock::Partial.AsInteger());
        AllowedValues.Add(ReservationFromStock::None.AsInteger());

        foreach i in AllowedValues do begin
            LibraryJob.CreateJob(Job);
            LibraryJob.CreateJobTask(Job, JobTask);

            LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
            JobPlanningLine.Validate("No.", Item."No.");
            JobPlanningLine.Validate(Quantity, 5);
            JobPlanningLine.Modify(true);
            JobPlanningLine.AutoReserve();

            LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
            JobPlanningLine.Validate("No.", Item."No.");
            JobPlanningLine.Validate(Quantity, 5);
            JobPlanningLine.Modify(true);

            // [WHEN] Reserving Item
            JobPlanningLine.AutoReserve();

            // [THEN] Reservation status is correct
            Assert.AreEqual(
              i, Job.GetQtyReservedFromStockState().AsInteger(),
              'Wrong reserved from stock state of job.');
        end;
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutAwayPickRequestPageHandler,ConfirmNoHandler,MessageHandler')]
    procedure CreateInvtPickOnlyForReservedFromStockJobPlanningLines()
    var
        Location: Record Location;
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Reservation] [Job] [Inventory Pick]
        // [SCENARIO 471183] Respect "Reserved from Stock" = "Full" setting in Create Invt. Put-away/Pick/Movement report.
        Initialize();

        CreateWMSLocation(Location, false, false, true, false, false);

        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", Location.Code, '', 15);

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate("Location Code", Location.Code);
        JobPlanningLine.Validate(Quantity, 10);
        JobPlanningLine.Modify(true);
        JobPlanningLine.AutoReserve();

        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate("Location Code", Location.Code);
        JobPlanningLine.Validate(Quantity, 10);
        JobPlanningLine.Modify(true);
        JobPlanningLine.AutoReserve();

        PostItemToInventory(Item."No.", Location.Code, '', 15);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate("Location Code", Location.Code);
        JobPlanningLine.Validate(Quantity, 10);
        JobPlanningLine.Modify(true);

        Commit();
        Job.CreateInvtPutAwayPick();

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);

        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.FindFirst();
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Source Type", Database::Job);
        WarehouseActivityLine.TestField("Source No.", Job."No.");
        WarehouseActivityLine.TestField("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLine.TestField(Quantity, JobPlanningLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ReservedQtyFromInventoryForSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        // [FEATURE] [Reservation] [Sales]
        // [SCENARIO 471183] Calculate quantity that is fully reserved from inventory for sales line.
        Initialize();

        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", '', '', 5);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, '', WorkDate());
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        LibrarySales.AutoReserveSalesLine(SalesLine);

        Assert.AreEqual(
          3, SalesLineReserve.GetReservedQtyFromInventory(SalesLine),
          'Reserved from stock quantity for sales line is wrong.');
    end;

    [Test]
    procedure ReservedQtyFromInventoryForSalesLineDoNotTakeOtherSources()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        // [FEATURE] [Reservation] [Sales]
        // [SCENARIO 471183] Do not include reservation from purchase in calculation of quantity that is fully reserved from inventory for sales line.
        Initialize();

        LibraryInventory.CreateItem(Item);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", 10, '', WorkDate());

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, '', WorkDate());

        LibrarySales.AutoReserveSalesLine(SalesLine);

        SalesLine.CalcFields("Reserved Qty. (Base)");
        SalesLine.TestField("Reserved Qty. (Base)", 10);

        Assert.AreEqual(
          0, SalesLineReserve.GetReservedQtyFromInventory(SalesLine),
          'Reserved from stock quantity for sales line is wrong.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ReservedQtyFromInventoryForSalesHeader()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        // [FEATURE] [Reservation] [Sales]
        // [SCENARIO 471183] Calculate quantity that is fully reserved from inventory for sales header.
        Initialize();

        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", '', '', 15);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, '', WorkDate());
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        Assert.AreEqual(
          15, SalesLineReserve.GetReservedQtyFromInventory(SalesHeader),
          'Reserved from stock quantity for sales header is wrong.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ReservedFromStockStatesOnSalesHeader()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationFromStock: Enum "Reservation From Stock";
        AllowedValues: List of [Integer];
        i: Integer;
    begin
        // [FEATURE] [Reservation] [Sales]
        // [SCENARIO 471189] Show what part of sales header is reserved from stock.
        Initialize();

        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", '', '', 15);

        AllowedValues.Add(ReservationFromStock::Full.AsInteger());
        AllowedValues.Add(ReservationFromStock::Partial.AsInteger());
        AllowedValues.Add(ReservationFromStock::None.AsInteger());

        foreach i in AllowedValues do begin
            LibrarySales.CreateSalesDocumentWithItem(
              SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 5, '', WorkDate());
            LibrarySales.AutoReserveSalesLine(SalesLine);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 5);
            LibrarySales.AutoReserveSalesLine(SalesLine);
            Assert.AreEqual(
              i, SalesHeader.GetQtyReservedFromStockState().AsInteger(),
              'Wrong reserved from stock state of sales header.');
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ReservedFromStockStatesOnSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInfoPaneManagement: Codeunit "Sales Info-Pane Management";
        ReservationFromStock: Enum "Reservation From Stock";
        AllowedValues: List of [Integer];
        i: Integer;
    begin
        // [FEATURE] [Reservation] [Sales]
        // [SCENARIO 471189] Show what part of sales line is reserved from stock.
        Initialize();

        LibraryInventory.CreateItem(Item);
        PostItemToInventory(Item."No.", '', '', 15);

        AllowedValues.Add(ReservationFromStock::Full.AsInteger());
        AllowedValues.Add(ReservationFromStock::Partial.AsInteger());
        AllowedValues.Add(ReservationFromStock::None.AsInteger());

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        foreach i in AllowedValues do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
            LibrarySales.AutoReserveSalesLine(SalesLine);
            Assert.AreEqual(
              i, SalesInfoPaneManagement.GetQtyReservedFromStockState(SalesLine).AsInteger(),
              'Wrong reserved from stock state of sales line.');
        end;
    end;

    [Test]
    procedure ReservedQtyFromInventoryForProdOrderComponent()
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
    begin
        // [FEATURE] [Reservation] [Production] [Component]
        // [SCENARIO 471183] Calculate quantity that is fully reserved from inventory for prod. order component.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        PostItemToInventory(Item."No.", '', '', 5);

        CreateProductionOrderWithComponent(ProdOrderComponent, Item."No.", 10);
        ProdOrderComponent.AutoReserve();

        Assert.AreEqual(
          5, ProdOrderCompReserve.GetReservedQtyFromInventory(ProdOrderComponent),
          'Reserved from stock quantity for prod. order component is wrong.');
    end;

    [Test]
    [HandlerFunctions('CalcConsumptionRequestPageHandler')]
    procedure FullyReservedQtyFromStockInCalcConsumptionReport()
    var
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ConsumptionJournalLine: Record "Item Journal Line";
        ConsumptionJournal: TestPage "Consumption Journal";
    begin
        // [FEATURE] [Reservation] [Production] [Component] [Calc. Consumption]
        // [SCENARIO 471183] Respect "Reserved from Stock" = "Full" setting in Calc. Consumption report.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        PostItemToInventory(Item."No.", '', '', 15);

        CreateProductionOrderWithComponent(ProdOrderComponent, Item."No.", 10);
        ProdOrderComponent.AutoReserve();
        ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, Item."No.", 1);
        ProdOrderComponent.AutoReserve();

        Commit();

        LibraryVariableStorage.Enqueue("Reservation From Stock"::Full.AsInteger());
        LibraryVariableStorage.Enqueue(ProdOrderComponent."Prod. Order No.");
        ConsumptionJournal.OpenEdit();
        ConsumptionJournal."Calc. Co&nsumption".Invoke();

        ConsumptionJournalLine.SetRange("Entry Type", ConsumptionJournalLine."Entry Type"::Consumption);
        ConsumptionJournalLine.SetRange("Order No.", ProdOrderComponent."Prod. Order No.");
        ConsumptionJournalLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(ConsumptionJournalLine, 1);
        ConsumptionJournalLine.FindFirst();
        ConsumptionJournalLine.TestField(Quantity, 10);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcConsumptionRequestPageHandler')]
    procedure PartiallyReservedQtyFromStockInCalcConsumptionReport()
    var
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ConsumptionJournalLine: Record "Item Journal Line";
        ConsumptionJournal: TestPage "Consumption Journal";
    begin
        // [FEATURE] [Reservation] [Production] [Component] [Calc. Consumption]
        // [SCENARIO 471183] Respect "Reserved from Stock" = "Full and Partial" setting in Calc. Consumption report.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        PostItemToInventory(Item."No.", '', '', 15);

        CreateProductionOrderWithComponent(ProdOrderComponent, Item."No.", 10);
        ProdOrderComponent.AutoReserve();
        ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, Item."No.", 1);
        ProdOrderComponent.AutoReserve();
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, Item."No.", 1);

        Commit();

        LibraryVariableStorage.Enqueue("Reservation From Stock"::"Full and Partial".AsInteger());
        LibraryVariableStorage.Enqueue(ProdOrderComponent."Prod. Order No.");
        ConsumptionJournal.OpenEdit();
        ConsumptionJournal."Calc. Co&nsumption".Invoke();

        ConsumptionJournalLine.SetRange("Entry Type", ConsumptionJournalLine."Entry Type"::Consumption);
        ConsumptionJournalLine.SetRange("Order No.", ProdOrderComponent."Prod. Order No.");
        ConsumptionJournalLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(ConsumptionJournalLine, 2);
        ConsumptionJournalLine.CalcSums(Quantity);
        ConsumptionJournalLine.TestField(Quantity, 20);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutAwayPickRequestPageHandler,ConfirmNoHandler,MessageHandler')]
    procedure CreateInvtPickOnlyForReservedFromStockSalesLines()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Reservation] [Sales] [Inventory Pick]
        // [SCENARIO 471183] Respect "Reserved from Stock" = "Full" setting in Create Invt. Put-away/Pick/Movement report.
        Initialize();

        CreateWMSLocation(Location, false, false, true, false, false);

        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);

        PostItemToInventory(Item."No.", Location.Code, '', 15);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        PostItemToInventory(Item."No.", Location.Code, '', 15);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);

        Commit();

        SalesHeader.CreateInvtPutAwayPick();

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Source Type", Database::"Sales Line");
        WarehouseActivityLine.TestField("Source No.", SalesLine."Document No.");
        WarehouseActivityLine.TestField("Source Line No.", SalesLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutAwayPickPartialReservRPH,ConfirmNoHandler,MessageHandler')]
    procedure CreateInvtPickOnlyForPartiallyReservedFromStockSalesLines()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Reservation] [Sales] [Inventory Pick]
        // [SCENARIO 471183] Respect "Reserved from Stock" = "Full and Partial" setting in Create Invt. Put-away/Pick/Movement report.
        Initialize();

        CreateWMSLocation(Location, false, false, true, false, false);

        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);

        PostItemToInventory(Item."No.", Location.Code, '', 15);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        PostItemToInventory(Item."No.", Location.Code, '', 15);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);

        Commit();

        SalesHeader.CreateInvtPutAwayPick();

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(WarehouseActivityLine, 2);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Source Type", Database::"Sales Line");
        WarehouseActivityLine.TestField("Source No.", SalesLine."Document No.");
        WarehouseActivityLine.TestField("Source Line No.", SalesLine."Line No.");
        WarehouseActivityLine.CalcSums(Quantity);
        WarehouseActivityLine.TestField(Quantity, 20);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ReservedFromStockInWarehouseSourceFilter()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        // [FEATURE] [Reservation] [Sales] [Warehouse Shipment] [Warehouse Source Filter]
        // [SCENARIO 471183] Respect "Reserved from Stock" = "Full" setting in Warehouse Source Filter. 
        Initialize();

        CreateWMSLocation(Location, false, false, false, false, true);

        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);

        PostItemToInventory(Item."No.", Location.Code, '', 15);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        PostItemToInventory(Item."No.", Location.Code, '', 15);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);

        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", Location.Code);
        WarehouseShipmentHeader.Modify(true);

        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Outbound);
        WarehouseSourceFilter.Validate("Sales Orders", true);
        WarehouseSourceFilter.Validate("Source No. Filter", SalesHeader."No.");
        WarehouseSourceFilter.Validate("Reserved From Stock", WarehouseSourceFilter."Reserved From Stock"::Full);
        WarehouseSourceFilter.Modify(true);

        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, Location.Code);

        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        Assert.RecordCount(WarehouseShipmentLine, 1);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField("Source Type", Database::"Sales Line");
        WarehouseShipmentLine.TestField("Source No.", SalesLine."Document No.");
        WarehouseShipmentLine.TestField("Source Line No.", SalesLine."Line No.");
        WarehouseShipmentLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,WarehouseEmployeesModalPageHandler,MessageHandler')]
    procedure CreateWarehouseShipmentNotWarehouseEmployee()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        WarehouseShipment: TestPage "Warehouse Shipment";
    begin
        // [FEATURE] [Create Warehouse Shipment] [Warehouse Employee]
        Initialize();

        // [GIVEN] WHS Location, Item
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Released Sales Order
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create Warehouse Shipment from Sales Order page
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");

        WarehouseShipment.Trap();
        LibraryVariableStorage.Enqueue(Location.Code);
        SalesOrder."Create &Warehouse Shipment".Invoke();  //WarehouseEmployeesModalPageHandler will be triggered here

        // [THEN] Warehouse Shipment is created and opened
        Assert.AreEqual(WarehouseShipment."No.".Value, LibraryWarehouse.FindWhseShipmentNoBySourceDoc(Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."), 'Warehouse Shipment not created');
        WarehouseShipment.Close();
    end;

    [Test]
    procedure CreateWarehouseShipmentReportOneSalesDoc()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Create Warehouse Shipment] [Sales]
        // [SCENARIO 471183] "Create Warehouse Shipment" report for one sales document with one location.
        Initialize();

        CreateWMSLocation(Location, false, false, false, false, true);

        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        RunCreateWarehouseShipmentReportForSalesOrder(SalesHeader."No.", "Reservation From Stock"::" ");

        LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
          Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
    end;

    [Test]
    procedure CreateWarehouseShipmentReportOneSalesDocTwoLocations()
    var
        Location: array[2] of Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Create Warehouse Shipment] [Sales]
        // [SCENARIO 471183] "Create Warehouse Shipment" report for one sales document with two locations.
        Initialize();

        CreateWMSLocation(Location[1], false, false, false, false, true);
        CreateWMSLocation(Location[2], false, false, false, false, true);

        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, Location[1].Code, WorkDate());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        SalesLine.Validate("Location Code", Location[2].Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        RunCreateWarehouseShipmentReportForSalesOrder(SalesHeader."No.", "Reservation From Stock"::" ");

        FindWhseShipment(
          WarehouseShipmentLine, Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", Location[1].Code);
        FindWhseShipment(
          WarehouseShipmentLine, Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", Location[2].Code);
    end;

    [Test]
    procedure CreateWarehouseShipmentReportTwoSalesDoc()
    var
        Location: array[2] of Record Location;
        Item: Record Item;
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        i: Integer;
    begin
        // [FEATURE] [Create Warehouse Shipment] [Sales]
        // [SCENARIO 471183] "Create Warehouse Shipment" report for two sales documents.
        Initialize();

        LibraryInventory.CreateItem(Item);

        for i := 1 to 2 do begin
            CreateWMSLocation(Location[i], false, false, false, false, true);
            LibrarySales.CreateSalesDocumentWithItem(
              SalesHeader[i], SalesLine, SalesHeader[i]."Document Type"::Order, '', Item."No.", 10, Location[i].Code, WorkDate());
            LibrarySales.ReleaseSalesDocument(SalesHeader[i]);
        end;

        RunCreateWarehouseShipmentReportForSalesOrder(StrSubstNo('%1|%2', SalesHeader[1]."No.", SalesHeader[2]."No."), "Reservation From Stock"::" ");

        for i := 1 to 2 do
            FindWhseShipment(
              WarehouseShipmentLine, Database::"Sales Line", SalesHeader[i]."Document Type".AsInteger(), SalesHeader[i]."No.", Location[i].Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ReservedFromStockFullInCreateWarehouseShipmentReport()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Create Warehouse Shipment] [Reservation] [Sales]
        // [SCENARIO 471183] Respect "Reserved From Stock" = Full in Create Warehouse Shipment report.
        Initialize();

        CreateWMSLocation(Location, false, false, false, false, true);

        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);

        PostItemToInventory(Item."No.", Location.Code, '', 15);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);

        RunCreateWarehouseShipmentReportForSalesOrder(SalesHeader."No.", "Reservation From Stock"::Full);

        FindWhseShipment(
          WarehouseShipmentLine, Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", Location.Code);
        Assert.RecordCount(WarehouseShipmentLine, 1);
        WarehouseShipmentLine.TestField("Source Line No.", SalesLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ReservedFromStockPartialInCreateWarehouseShipmentReport()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Create Warehouse Shipment] [Reservation] [Sales]
        // [SCENARIO 471183] Respect "Reserved From Stock" = Partial in Create Warehouse Shipment report.
        Initialize();

        CreateWMSLocation(Location, false, false, false, false, true);

        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);

        PostItemToInventory(Item."No.", Location.Code, '', 15);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);

        RunCreateWarehouseShipmentReportForSalesOrder(SalesHeader."No.", "Reservation From Stock"::"Full and Partial");

        FindWhseShipment(
          WarehouseShipmentLine, Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", Location.Code);
        Assert.RecordCount(WarehouseShipmentLine, 2);
        WarehouseShipmentLine.TestField("Source Line No.", SalesLine."Line No.");
    end;

    [Test]
    procedure CannotCreateWarehouseShipmentShippingAdviceCompleteAndTwoLocations()
    var
        Location: array[2] of Record Location;
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Create Warehouse Shipment] [Sales] [Shipping Advice]
        // [SCENARIO 471183] "Create Warehouse Shipment" report does not create shipment for sales order with multiple locations and Shipping Advice = Complete.
        Initialize();

        CreateWMSLocation(Location[1], false, false, false, false, true);
        CreateWMSLocation(Location[2], false, false, false, false, true);

        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipping Advice", Customer."Shipping Advice"::Complete);
        Customer.Modify(true);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", Item."No.", 10, Location[1].Code, WorkDate());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        SalesLine.Validate("Location Code", Location[2].Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        RunCreateWarehouseShipmentReportForSalesOrder(SalesHeader."No.", "Reservation From Stock"::Full);

        asserterror FindWhseShipment(
          WarehouseShipmentLine, Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", Location[1].Code);
        asserterror FindWhseShipment(
          WarehouseShipmentLine, Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", Location[2].Code);
    end;

    [Test]
    procedure CreateWarehouseShipmentReportOneSalesDocTwice()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderPage: TestPage "Sales Order";

    begin
        // [FEATURE] [Create Warehouse Shipment] [Sales] [Take me there]
        // [GIVEN] One sales document with one location and ready to be Shipped.
        Initialize();

        CreateWMSLocation(Location, false, false, false, false, true);

        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        RunCreateWarehouseShipmentReportForSalesOrder(SalesHeader."No.", "Reservation From Stock"::" ");

        SalesOrderPage.OpenEdit();
        SalesOrderPage.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrderPage.GotoRecord(SalesHeader);
        // [WHEN] Repeat Create Shipment
        asserterror SalesOrderPage."Create &Warehouse Shipment_Promoted".Invoke();

        // [THEN] Error message is shown
        assert.ExpectedError('This usually happens');

        LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
          Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentRequestPageHandler,MessageHandler')]
    procedure CreatingWhsePickOnlyForReservedProdOrderComponent()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Reservation] [Production] [Component] [Warehouse Pick]
        // [SCENARIO 471183] Creating warehouse pick only for reserved prod. order component.
        Initialize();

        // [GIVEN] Always reserve item.
        CreateAlwaysReserveItem(Item);

        // [GIVEN] Location set up for production consumption pick.
        CreateWMSLocation(Location, false, false, false, false, false);
        Location.Validate("Prod. Consump. Whse. Handling", "Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");
        Location.Modify(true);

        // [GIVEN] Post inventory at the location.
        PostItemToInventory(Item."No.", Location.Code, '', 15);

        // [GIVEN] Production Order with 2 component lines - 1 reserved, 1 not reserved.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), 10);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, Item."No.", 1);
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Modify(true);
        ProdOrderComponent.AutoReserve();
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, Item."No.", 1);
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Modify(true);

        // [WHEN] Create warehouse pick with "Reserved from Stock" = "Full".
        ProductionOrder.CreatePick(UserId(), 0, false, false, false);

        // [THEN] Warehouse pick is created only for the reserved component line.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Source Type", Database::"Prod. Order Component");
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        Assert.RecordCount(WarehouseActivityLine, 1);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentRequestPageHandler,MessageHandler')]
    procedure CreatingWhsePickOnlyForReservedAssemblyLine()
    var
        Item: Record Item;
        Location: Record Location;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Reservation] [Assembly] [Component] [Warehouse Pick]
        // [SCENARIO 471183] Creating warehouse pick only for reserved assembly line.
        Initialize();

        // [GIVEN] Always reserve item.
        CreateAlwaysReserveItem(Item);

        // [GIVEN] Location set up for assembly consumption pick.
        CreateWMSLocation(Location, false, false, false, false, false);
        Location.Validate("Asm. Consump. Whse. Handling", "Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)");
        Location.Modify(true);

        // [GIVEN] Post inventory at the location.
        PostItemToInventory(Item."No.", Location.Code, '', 15);

        // [GIVEN] Assembly Order with 2 component lines - 1 reserved, 1 not reserved.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate() + 10, LibraryInventory.CreateItemNo(), Location.Code, 10, '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", 10, 0, '');
        AssemblyLine.AutoReserve();
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", 10, 0, '');
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        // [WHEN] Create warehouse pick with "Reserved from Stock" = "Full".
        AssemblyHeader.CreatePick(true, UserId(), 0, false, false, false);

        // [THEN] Warehouse pick is created only for the reserved assembly line.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Source Type", Database::"Assembly Line");
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        Assert.RecordCount(WarehouseActivityLine, 1);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentRequestPageHandler,MessageHandler')]
    procedure CreatingWhsePickOnlyForReservedJobPlanningLine()
    var
        Item: Record Item;
        Location: Record Location;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Reservation] [Job] [Warehouse Pick]
        // [SCENARIO 471183] Creating warehouse pick only for reserved job planning line.
        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location set up for job consumption pick.
        CreateWMSLocation(Location, false, false, false, false, false);
        Location.Validate("Job Consump. Whse. Handling", "Job Consump. Whse. Handling"::"Warehouse Pick (optional)");
        Location.Modify(true);

        // [GIVEN] Post inventory at the location.
        PostItemToInventory(Item."No.", Location.Code, '', 15);

        // [GIVEN] Job with 2 planning lines - 1 reserved, 1 not reserved.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate("Location Code", Location.Code);
        JobPlanningLine.Validate(Quantity, 10);
        JobPlanningLine.Modify(true);
        JobPlanningLine.AutoReserve();

        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate("Location Code", Location.Code);
        JobPlanningLine.Validate(Quantity, 10);
        JobPlanningLine.Modify(true);

        // [WHEN] Create warehouse pick with "Reserved from Stock" = "Full".
        Job.CreateWarehousePick();

        // [THEN] Warehouse pick is created only for the reserved assembly line.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Source Type", Database::Job);
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        Assert.RecordCount(WarehouseActivityLine, 1);
    end;

    [Test]
    [HandlerFunctions('JobCalcRemainingUsageHandler,MessageHandler')]
    procedure JobCalcRemainingUsageForReservedJobPlanningLine()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLine: Record "Job Journal Line";
    begin
        // [FEATURE] [Reservation] [Job] [Job Journal] [Job Calc. Remaining Usage]
        // [SCENARIO 485096] "Reserved from Stock" filter in Job Calc. Remaining Usage report.
        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Post 15 pcs to inventory.
        PostItemToInventory(Item."No.", '', '', 15);

        // [GIVEN] Job with 2 planning lines for 10 pcs each - 1 reserved, 1 not reserved.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate(Quantity, 10);
        JobPlanningLine.Modify(true);
        JobPlanningLine.AutoReserve();

        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate(Quantity, 10);
        JobPlanningLine.Modify(true);

        // [WHEN] Open job journal and run Job Calc. Remaining Usage with "Reserved from Stock" = "Full".
        LibraryVariableStorage.Enqueue("Reservation From Stock"::Full.AsInteger());
        CreateJobJournalBatch(JobJournalBatch);
        RunJobCalcRemainingUsage(JobJournalBatch, JobTask);

        // [THEN] Job Journal for 10 pcs is created.
        JobJournalLine.SetRange("Journal Template Name", JobJournalBatch."Journal Template Name");
        JobJournalLine.SetRange("Journal Batch Name", JobJournalBatch.Name);
        JobJournalLine.SetRange("No.", Item."No.");
        JobJournalLine.FindFirst();
        JobJournalLine.TestField(Quantity, 10);
    end;
    
    [Test]
    procedure ReservedQtyFromInventoryAndNonInventoryItemForServiceOrder()
    var
        Item: array[2] of Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ReservationFromStock: Enum "Reservation From Stock";
    begin
        // [SCENARIO 563164] Reserved from Stock has "Full" status on Statistics page of Service Order when there is non-inventory item is in the Service Lines.
        Initialize();

        // [GIVEN] Create Item in inventory.
        LibraryInventory.CreateItem(Item[1]);

        // [GIVEN] Post Item to Inventory.
        PostItemToInventory(Item[1]."No.", '', '', LibraryRandom.RandIntInRange(15, 20));

        // [GIVEN] Create Non Inventory Item.
        LibraryInventory.CreateNonInventoryTypeItem(Item[2]);

        // [GIVEN] Create a Service Header.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');

        // [GIVEN] Create a Service Item.
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");

        // [GIVEN] Create Service Item Line.
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Create Service Line with Quantity and Validate Service Item Line No.
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, Enum::"Service Line Type"::Item, Item[1]."No.", 10);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);

        // [GIVEN] Reserve Service Line.
        LibraryService.AutoReserveServiceLine(ServiceLine);

        // [WHEN] Create Service Line with Quantity.
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, Enum::"Service Line Type"::Item, Item[2]."No.", 10);

        // [THEN] Reservation from stock must be Full.
        Assert.AreEqual(
            ReservationFromStock::Full,
            ServiceHeader.GetQtyReservedFromStockState(),
            StrSubstNo(
                ReservationFromStockErr,
                ReservationFromStock::Full,
                ServiceHeader.TableCaption()));
    end;
    
    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Fulfillment");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Fulfillment");

        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Fulfillment");
    end;

    local procedure CreateAlwaysReserveItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
    end;

    local procedure CreateWMSLocation(var Location: Record Location; WithBin: Boolean; WithPutAway: Boolean; WithPick: Boolean; WithReceipt: Boolean; WithShipment: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, WithBin, WithPutAway, WithPick, WithReceipt, WithShipment);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateProductionOrderWithComponent(var ProdOrderComponent: Record "Prod. Order Component"; ItemNo: Code[20]; Qty: Decimal)
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), Qty);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, ItemNo, 1);
    end;

    local procedure CreateProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; QtyPer: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", QtyPer);
        ProdOrderComponent.Modify(true);
    end;

    local procedure AutoReserveTransferLine(TransferLine: Record "Transfer Line")
    var
        ReservationManagement: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        ReservationManagement.SetReservSource(TransferLine, Enum::"Transfer Direction"::Outbound);
        ReservationManagement.AutoReserve(
          FullAutoReservation, TransferLine.Description, WorkDate(), TransferLine.Quantity, TransferLine."Quantity (Base)");
    end;

    local procedure AutoReservePurchaseLine(PurchaseLine: Record "Purchase Line")
    var
        ReservationManagement: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        ReservationManagement.SetReservSource(PurchaseLine);
        ReservationManagement.AutoReserve(FullAutoReservation, '', WorkDate(), PurchaseLine.Quantity, PurchaseLine."Quantity (Base)");
    end;

    local procedure PostItemToInventory(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure FindWhseShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceType: Option; SourceSubtype: Option; SourceNo: Code[20]; LocationCode: Code[10])
    begin
        WarehouseShipmentLine.SetRange("Source Type", SourceType);
        WarehouseShipmentLine.SetRange("Source Subtype", SourceSubtype);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.SetRange("Location Code", LocationCode);
        WarehouseShipmentLine.FindSet();
    end;

    local procedure CreateJobJournalBatch(var JobJournalBatch: Record "Job Journal Batch")
    var
        JobJournalTemplate: Record "Job Journal Template";
    begin
        LibraryJob.GetJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
    end;

    local procedure RunJobCalcRemainingUsage(JobJournalBatch: Record "Job Journal Batch"; JobTask: Record "Job Task")
    var
        JobCalcRemainingUsage: Report "Job Calc. Remaining Usage";
        NoSeries: Codeunit "No. Series";
    begin
        JobTask.SetRecFilter();
        Commit();
        JobCalcRemainingUsage.SetBatch(JobJournalBatch."Journal Template Name", JobJournalBatch.Name);
        JobCalcRemainingUsage.SetDocNo(NoSeries.PeekNextNo(JobJournalBatch."No. Series"));
        JobCalcRemainingUsage.SetTableView(JobTask);
        JobCalcRemainingUsage.Run();
    end;

    local procedure RunCreateWarehouseShipmentReportForSalesOrder(SourceNoFilter: Text; ReservedFromStock: Enum "Reservation From Stock")
    var
        WarehouseRequest: Record "Warehouse Request";
        CreateWarehouseShipment: Report "Create Warehouse Shipment";
    begin
        Commit();
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Sales Order");
        WarehouseRequest.SetFilter("Source No.", SourceNoFilter);
        CreateWarehouseShipment.InitializeRequest(false, ReservedFromStock);
        CreateWarehouseShipment.SetTableView(WarehouseRequest);
        CreateWarehouseShipment.UseRequestPage(false);
        CreateWarehouseShipment.RunModal();
    end;

    local procedure RunCreateWarehouseShipmentReportForTransferOrder(SourceNoFilter: Text; ReservedFromStock: Enum "Reservation From Stock")
    var
        WarehouseRequest: Record "Warehouse Request";
        CreateWarehouseShipment: Report "Create Warehouse Shipment";
    begin
        Commit();
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Outbound Transfer");
        WarehouseRequest.SetFilter("Source No.", SourceNoFilter);
        CreateWarehouseShipment.InitializeRequest(false, ReservedFromStock);
        CreateWarehouseShipment.SetTableView(WarehouseRequest);
        CreateWarehouseShipment.UseRequestPage(false);
        CreateWarehouseShipment.RunModal();
    end;

    local procedure RunCreateWarehouseShipmentReportForPurchaseReturnOrder(SourceNoFilter: Text; ReservedFromStock: Enum "Reservation From Stock")
    var
        WarehouseRequest: Record "Warehouse Request";
        CreateWarehouseShipment: Report "Create Warehouse Shipment";
    begin
        Commit();
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Return Order");
        WarehouseRequest.SetFilter("Source No.", SourceNoFilter);
        CreateWarehouseShipment.InitializeRequest(false, ReservedFromStock);
        CreateWarehouseShipment.SetTableView(WarehouseRequest);
        CreateWarehouseShipment.UseRequestPage(false);
        CreateWarehouseShipment.RunModal();
    end;

    local procedure RunCreateWarehouseShipmentReportForSalesOrderForServiceOrder(SourceNoFilter: Text; ReservedFromStock: Enum "Reservation From Stock")
    var
        WarehouseRequest: Record "Warehouse Request";
        CreateWarehouseShipment: Report "Create Warehouse Shipment";
    begin
        Commit();
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Service Order");
        WarehouseRequest.SetFilter("Source No.", SourceNoFilter);
        CreateWarehouseShipment.InitializeRequest(false, ReservedFromStock);
        CreateWarehouseShipment.SetTableView(WarehouseRequest);
        CreateWarehouseShipment.UseRequestPage(false);
        CreateWarehouseShipment.RunModal();
    end;

    [RequestPageHandler]
    procedure CalcConsumptionRequestPageHandler(var CalcConsumption: TestRequestPage "Calc. Consumption")
    var
        CalcBasedOn: Option "Actual Output","Expected Output";
    begin
        CalcConsumption.CalcBasedOn.SetValue(CalcBasedOn::"Expected Output");
        CalcConsumption."Reserved From Stock".SetValue(LibraryVariableStorage.DequeueInteger());
        CalcConsumption."Production Order".SetFilter("No.", LibraryVariableStorage.DequeueText());
        CalcConsumption.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreateInvtPutAwayPickRequestPageHandler(var CreateInvtPutAwayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutAwayPickMvmt.CInvtPick.SetValue(true);
        CreateInvtPutAwayPickMvmt."Reserved From Stock".SetValue("Reservation From Stock"::Full);
        CreateInvtPutAwayPickMvmt.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreateInvtPutAwayPickPartialReservRPH(var CreateInvtPutAwayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutAwayPickMvmt.CInvtPick.SetValue(true);
        CreateInvtPutAwayPickMvmt."Reserved From Stock".SetValue("Reservation From Stock"::"Full and Partial");
        CreateInvtPutAwayPickMvmt.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreateInvtMovementRequestPageHandler(var CreateInvtPutAwayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutAwayPickMvmt.CInvtMvmt.SetValue(true);
        CreateInvtPutAwayPickMvmt."Reserved From Stock".SetValue("Reservation From Stock"::Full);
        CreateInvtPutAwayPickMvmt.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure JobCalcRemainingUsageHandler(var JobCalcRemainingUsage: TestRequestPage "Job Calc. Remaining Usage")
    begin
        JobCalcRemainingUsage.PostingDate.SetValue(Format(WorkDate()));
        JobCalcRemainingUsage."Reserved From Stock".SetValue(LibraryVariableStorage.DequeueInteger());
        JobCalcRemainingUsage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure JobTransferJobPlanningLinePageHandler(var JobTransferJobPlanningLine: TestPage "Job Transfer Job Planning Line")
    begin
        JobTransferJobPlanningLine.JobJournalTemplateName.SetValue(LibraryVariableStorage.DequeueText());
        JobTransferJobPlanningLine.JobJournalBatchName.SetValue(LibraryVariableStorage.DequeueText());
        JobTransferJobPlanningLine.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure WarehouseEmployeesModalPageHandler(var WarehouseEmployees: TestPage "Warehouse Employees")
    begin
        WarehouseEmployees.New();
        WarehouseEmployees."User ID".SetValue(UserId());
        WarehouseEmployees."Location Code".SetValue(LibraryVariableStorage.DequeueText());
        WarehouseEmployees.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure WhseSourceCreateDocumentRequestPageHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument."Reserved From Stock".SetValue("Reservation From Stock"::Full);
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [StrMenuHandler]
    procedure StrMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Option);
        Choice := 1;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

